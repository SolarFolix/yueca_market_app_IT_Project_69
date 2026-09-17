import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper around FirebaseAuth so screens never touch the Firebase
/// SDK directly. Swap the implementation here if you ever change backend.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  /// True once Firebase.initializeApp() has actually succeeded (i.e. after
  /// `flutterfire configure` has replaced firebase_options.dart with real
  /// values). Screens can check this before calling anything below.
  bool get isAvailable => Firebase.apps.isNotEmpty;

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Stream the app listens to on splash / route guards.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => isAvailable ? _auth.currentUser : null;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    _assertAvailable();
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<UserCredential> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    _assertAvailable();
    // Only this call determines success/failure. The account is created
    // (and the user is signed in) the moment this line completes — a
    // problem in either follow-up step below must NOT bubble up and make
    // the signup screen report failure, or you get exactly the bug where
    // the account exists in Firebase but the app shows an error.
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Save the display name on the auth profile. Non-fatal if it fails.
    try {
      await credential.user?.updateDisplayName(username);
      await credential.user?.reload();
    } catch (e) {
      // ignore — cosmetic only, doesn't block the user from proceeding
    }

    // Claim the username in a dedicated collection (see updateUsername's
    // doc comment for why) plus the matching Firestore user document.
    // Non-fatal if either fails — the most common cause here is Firestore
    // security rules rejecting the write (see README: "Common setup
    // issues"). Swallow so a rules problem never blocks a real, successful
    // signup — worst case the username uniqueness check just isn't backed
    // by a claim yet.
    try {
      await _db.collection('usernames').doc(username.trim().toLowerCase()).set({'uid': credential.user!.uid});
    } catch (e) {
      // ignore — see note above
    }
    try {
      await _db.collection('users').doc(credential.user!.uid).set({
        'username': username,
        'usernameLower': username.trim().toLowerCase(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore — see note above
    }

    return credential;
  }

  Future<void> sendPasswordResetEmail(String email) {
    _assertAvailable();
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Checks a dedicated `usernames/{usernameLower}` collection rather than
  /// querying other users' `users/{uid}` docs directly — the security
  /// rules only let each user read their own profile doc, so a cross-user
  /// query would be denied. This "reserved username" doc pattern is the
  /// standard, rules-friendly way to enforce uniqueness in Firestore.
  Future<bool> isUsernameAvailable(String username) async {
    _assertAvailable();
    final normalized = username.trim().toLowerCase();
    final doc = await _db.collection('usernames').doc(normalized).get();
    if (!doc.exists) return true;
    return doc.data()?['uid'] == currentUser?.uid;
  }

  Future<void> updateUsername(String newUsername) async {
    _assertAvailable();
    final user = currentUser;
    if (user == null) throw StateError('Not signed in');

    final normalized = newUsername.trim().toLowerCase();
    final oldNormalized = (user.displayName ?? '').trim().toLowerCase();

    await _db.runTransaction((tx) async {
      final newRef = _db.collection('usernames').doc(normalized);
      final newDoc = await tx.get(newRef);
      if (newDoc.exists && newDoc.data()?['uid'] != user.uid) {
        throw FirebaseAuthException(code: 'username-taken', message: 'That username is already taken.');
      }
      tx.set(newRef, {'uid': user.uid});
      if (oldNormalized.isNotEmpty && oldNormalized != normalized) {
        tx.delete(_db.collection('usernames').doc(oldNormalized));
      }
      tx.set(_db.collection('users').doc(user.uid), {
        'username': newUsername.trim(),
        'usernameLower': normalized,
      }, SetOptions(merge: true));
    });

    await user.updateDisplayName(newUsername.trim());
    await user.reload();
  }

  /// Re-enters the user's current password to satisfy Firebase's
  /// "recent login" requirement before sensitive changes (email, password,
  /// account deletion).
  Future<void> _reauthenticate(String currentPassword) async {
    final user = currentUser;
    if (user == null || user.email == null) throw StateError('Not signed in');
    final credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> updateEmailAddress({required String newEmail, required String currentPassword}) async {
    _assertAvailable();
    await _reauthenticate(currentPassword);
    final user = currentUser;
    if (user == null) throw StateError('Not signed in');
    // Sends a confirmation link to the new address rather than switching
    // immediately — the recommended, more secure flow in current Firebase
    // Auth versions (avoids someone else's typo locking you out).
    await user.verifyBeforeUpdateEmail(newEmail.trim());
    await _db.collection('users').doc(user.uid).set({'pendingEmail': newEmail.trim()}, SetOptions(merge: true));
  }

  Future<void> updateUserPassword({required String currentPassword, required String newPassword}) async {
    _assertAvailable();
    await _reauthenticate(currentPassword);
    final user = currentUser;
    if (user == null) throw StateError('Not signed in');
    await user.updatePassword(newPassword);
  }

  Future<void> deleteAccount(String currentPassword) async {
    _assertAvailable();
    await _reauthenticate(currentPassword);
    final user = currentUser;
    if (user == null) throw StateError('Not signed in');
    final usernameLower = (user.displayName ?? '').trim().toLowerCase();
    try {
      await _db.collection('users').doc(user.uid).delete();
    } catch (_) {
      // Non-fatal — proceed with deleting the auth account regardless.
    }
    if (usernameLower.isNotEmpty) {
      try {
        await _db.collection('usernames').doc(usernameLower).delete();
      } catch (_) {
        // Non-fatal, but leaves the username orphaned/unreleased if it fails —
        // acceptable trade-off vs. blocking account deletion on this write.
      }
    }
    await user.delete();
  }

  Future<void> signOut() {
    if (!isAvailable) return Future.value();
    return _auth.signOut();
  }

  void _assertAvailable() {
    if (!isAvailable) {
      throw StateError(
        'firebase-not-configured: run `flutterfire configure` and replace '
        'lib/firebase_options.dart before calling AuthService.',
      );
    }
  }

  /// Turns Firebase's error codes into copy you can show directly in a
  /// SnackBar without leaking implementation details to the user.
  String messageForError(Object error) {
    if (error is StateError && error.message.startsWith('firebase-not-configured')) {
      return "Backend isn't connected yet — this is a frontend preview. "
          'Use "Continue as Guest" to explore the app.';
    }
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found for that email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'That email is already registered — try logging in instead.';
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
        case 'network-request-failed':
          return 'No internet connection. Please check your network.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'requires-recent-login':
          return 'For security, please log out and back in, then try again.';
        case 'username-taken':
          return 'That username is already taken — try another one.';
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}

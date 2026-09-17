import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper around FirebaseAuth so screens never touch the Firebase
/// SDK directly. Swap the implementation here if you ever change backend.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream the app listens to on splash / route guards.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<UserCredential> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
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

    // Matching Firestore user document for anything else you want to
    // store (phone, bookings, favorites, etc). Non-fatal if it fails —
    // the most common cause here is Firestore security rules rejecting
    // the write (see README: "Common setup issues"). Swallow so a rules
    // problem never blocks a real, successful signup.
    try {
      await _db.collection('users').doc(credential.user!.uid).set({
        'username': username,
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore — see note above
    }

    return credential;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  /// Turns Firebase's error codes into copy you can show directly in a
  /// SnackBar without leaking implementation details to the user.
  String messageForError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found for that email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
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
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}

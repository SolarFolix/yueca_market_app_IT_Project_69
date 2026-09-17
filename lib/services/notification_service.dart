import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import '../models/notification_model.dart';

/// A user's own notification inbox, stored as a subcollection at
/// users/{uid}/notifications/{id} — see firestore.rules. Other services
/// (MarketService, AnalyticsService, etc.) call [create] to raise a
/// notification as a side effect of something happening, e.g. a booking
/// being confirmed.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>? _inbox() {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('notifications');
  }

  Stream<List<NotificationModel>> watchNotifications() {
    final inbox = _inbox();
    if (inbox == null) return Stream.value([]);
    return inbox.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map(NotificationModel.fromDoc).toList(),
        );
  }

  /// Raises a new notification for the *currently signed-in* user. Safe to
  /// call speculatively from other services — silently does nothing if
  /// nobody is signed in or Firebase isn't configured, since a
  /// notification failing to write should never block the action that
  /// triggered it (e.g. a booking still succeeds even if this fails).
  Future<void> create({required String iconKey, required String title, required String subtitle}) async {
    final inbox = _inbox();
    if (inbox == null) return;
    try {
      await inbox.add({
        'iconKey': iconKey,
        'title': title,
        'subtitle': subtitle,
        'unread': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Non-fatal — see doc comment above.
    }
  }

  Future<void> markRead(String id) async {
    final inbox = _inbox();
    if (inbox == null) return;
    await inbox.doc(id).update({'unread': false});
  }

  Future<void> markAllRead(List<String> ids) async {
    final inbox = _inbox();
    if (inbox == null || ids.isEmpty) return;
    final batch = _db.batch();
    for (final id in ids) {
      batch.update(inbox.doc(id), {'unread': false});
    }
    await batch.commit();
  }

  Future<void> dismiss(String id) async {
    final inbox = _inbox();
    if (inbox == null) return;
    await inbox.doc(id).delete();
  }

  Future<void> clearAll(List<String> ids) async {
    final inbox = _inbox();
    if (inbox == null || ids.isEmpty) return;
    final batch = _db.batch();
    for (final id in ids) {
      batch.delete(inbox.doc(id));
    }
    await batch.commit();
  }
}

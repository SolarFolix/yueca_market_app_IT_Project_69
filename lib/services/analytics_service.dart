import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import '../models/sales_log_model.dart';

/// A vendor's own analytics data: sales logs (top-level `salesLogs`
/// collection, scoped by `uid`) and a small summary — customers count and
/// self-reported performance — stored directly on their `users/{uid}` doc
/// since that's already owner-read/write per firestore.rules, no new rule
/// needed. Screens should check `AuthService.instance.isAvailable` and
/// fall back to in-memory demo data when Firebase isn't configured yet.
class AnalyticsService {
  AnalyticsService._internal();
  static final AnalyticsService instance = AnalyticsService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ---------------------------------------------------------------------
  // Sales logs
  // ---------------------------------------------------------------------

  Stream<List<SalesLogModel>> watchLogs() {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('salesLogs')
        .where('uid', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SalesLogModel.fromDoc).toList());
  }

  Future<void> addLog({required DateTime date, required double revenue, required int orders, String note = ''}) {
    final user = AuthService.instance.currentUser;
    if (user == null) throw StateError('Sign in to save a log.');
    return _db.collection('salesLogs').add({
      'uid': user.uid,
      'date': Timestamp.fromDate(date),
      'revenue': revenue,
      'orders': orders,
      'note': note,
    });
  }

  Future<void> updateLog(String id, {required DateTime date, required double revenue, required int orders, String note = ''}) {
    return _db.collection('salesLogs').doc(id).update({
      'date': Timestamp.fromDate(date),
      'revenue': revenue,
      'orders': orders,
      'note': note,
    });
  }

  Future<void> deleteLog(String id) {
    return _db.collection('salesLogs').doc(id).delete();
  }

  // ---------------------------------------------------------------------
  // Summary — customers + self-reported performance
  // ---------------------------------------------------------------------

  /// Streams `{customers: int, performance: {Sales: 0.75, ...}}` from the
  /// user's own profile doc. Missing fields fall back to sensible demo
  /// defaults so first-time users see something populated rather than
  /// zeros everywhere.
  Stream<Map<String, dynamic>> watchSummary() {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return Stream.value(_defaultSummary());
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null || data['customers'] == null) return _defaultSummary();
      final rawPerf = Map<String, dynamic>.from(data['performance'] ?? {});
      return {
        'customers': (data['customers'] as num).toInt(),
        'performance': {
          'Sales': (rawPerf['Sales'] as num?)?.toDouble() ?? 0.75,
          'Marketing': (rawPerf['Marketing'] as num?)?.toDouble() ?? 0.5,
          'Support': (rawPerf['Support'] as num?)?.toDouble() ?? 0.9,
        },
      };
    });
  }

  Map<String, dynamic> _defaultSummary() => {
        'customers': 184,
        'performance': {'Sales': 0.75, 'Marketing': 0.5, 'Support': 0.9},
      };

  Future<void> updateCustomers(int customers) {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to save changes.');
    return _db.collection('users').doc(uid).set({'customers': customers}, SetOptions(merge: true));
  }

  Future<void> updatePerformance(Map<String, double> performance) {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to save changes.');
    return _db.collection('users').doc(uid).set({'performance': performance}, SetOptions(merge: true));
  }
}

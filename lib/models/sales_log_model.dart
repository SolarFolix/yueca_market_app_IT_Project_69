import 'package:cloud_firestore/cloud_firestore.dart';

/// One day's self-reported sales entry. Top-level `salesLogs` collection,
/// scoped by `uid` field (matches the `bookings` collection's pattern) —
/// see firestore.rules for the matching security rule.
class SalesLogModel {
  final String id;
  final String uid;
  final DateTime date;
  final double revenue;
  final int orders;
  final String note;

  const SalesLogModel({
    required this.id,
    required this.uid,
    required this.date,
    required this.revenue,
    required this.orders,
    this.note = '',
  });

  factory SalesLogModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SalesLogModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      revenue: (data['revenue'] as num?)?.toDouble() ?? 0,
      orders: (data['orders'] as num?)?.toInt() ?? 0,
      note: data['note'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'date': Timestamp.fromDate(date),
        'revenue': revenue,
        'orders': orders,
        'note': note,
      };
}

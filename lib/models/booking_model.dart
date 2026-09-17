import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, confirmed, cancelled }

BookingStatus bookingStatusFromString(String? value) {
  switch (value) {
    case 'confirmed':
      return BookingStatus.confirmed;
    case 'cancelled':
      return BookingStatus.cancelled;
    default:
      return BookingStatus.pending;
  }
}

/// A user's reservation of one stall. Created inside the same transaction
/// that marks the stall as booked (see MarketService.bookStall), so a
/// booking document only ever exists if the stall was actually free at
/// the moment it was claimed.
class BookingModel {
  final String id;
  final String uid;
  final String stallCode;
  final String storeName;
  final DateTime date;
  final double feeAmount;
  final BookingStatus status;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.uid,
    required this.stallCode,
    required this.storeName,
    required this.date,
    required this.feeAmount,
    required this.status,
    required this.createdAt,
  });

  factory BookingModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BookingModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      stallCode: data['stallCode'] ?? '',
      storeName: data['storeName'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      feeAmount: (data['feeAmount'] as num?)?.toDouble() ?? 0,
      status: bookingStatusFromString(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get statusLabel {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.pending:
        return 'Pending';
    }
  }
}

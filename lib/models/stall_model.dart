import 'package:cloud_firestore/cloud_firestore.dart';

/// One physical plot in the market grid (e.g. "A2"). This is the single
/// source of truth for whether a plot is free — MarketSelectionScreen and
/// LocationMapScreen both read from the same `stalls` collection so they
/// can never disagree about what's booked.
class StallModel {
  final String code; // e.g. "A2" — also the Firestore doc id
  final bool booked;
  final String? bookedByUid;
  final String? storeName;

  const StallModel({
    required this.code,
    required this.booked,
    this.bookedByUid,
    this.storeName,
  });

  factory StallModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return StallModel(
      code: doc.id,
      booked: data['booked'] == true,
      bookedByUid: data['bookedByUid'],
      storeName: data['storeName'],
    );
  }

  /// A stall that hasn't been created in Firestore yet — used as a
  /// display fallback so the grid still renders "available" for plots
  /// that simply don't have a doc (e.g. before seeding finishes).
  factory StallModel.emptyAvailable(String code) => StallModel(code: code, booked: false);
}

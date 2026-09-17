import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'payment_screen.dart';

class BookingDetailsScreen extends StatelessWidget {
  // All optional — when omitted (reached via the named '/booking-details'
  // route with no arguments, e.g. guest/demo mode), this falls back to the
  // original static demo content instead of crashing.
  final String? bookingId;
  final String? stallCode;
  final String? storeName;
  final double? feeAmount;
  final DateTime? date;

  const BookingDetailsScreen({
    super.key,
    this.bookingId,
    this.stallCode,
    this.storeName,
    this.feeAmount,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedDate = date ?? DateTime(2026, 7, 29);
    final resolvedFee = feeAmount ?? 250;
    final resolvedStall = stallCode ?? 'A2';
    final resolvedStore = storeName ?? 'Store 1';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Store', resolvedStore),
            _detailRow('Stall', resolvedStall),
            _detailRow('Day/Month/Year', '${resolvedDate.day.toString().padLeft(2, '0')}/${resolvedDate.month.toString().padLeft(2, '0')}/${resolvedDate.year}'),
            _detailRow('Dates', '15:00 - 20:30'),
            _detailRow('Telephone', '02-XXX-XXXX'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Slot fee :', style: TextStyle(fontWeight: FontWeight.w700)),
                Text('${resolvedFee.toStringAsFixed(0)}.-', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PaymentScreen(
                    bookingId: bookingId,
                    stallCode: stallCode,
                    storeName: storeName,
                    feeAmount: feeAmount,
                  ),
                ),
              ),
              child: const Text('Rent'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const Divider(height: 20),
        ],
      ),
    );
  }
}

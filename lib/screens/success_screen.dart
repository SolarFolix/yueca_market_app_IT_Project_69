import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/auth_service.dart';
import '../services/market_service.dart';
import '../theme/app_theme.dart';

class SuccessScreen extends StatelessWidget {
  final String? bookingId;
  const SuccessScreen({super.key, this.bookingId});

  @override
  Widget build(BuildContext context) {
    if (bookingId != null && AuthService.instance.isAvailable) {
      return FutureBuilder<BookingModel?>(
        future: MarketService.instance.getBooking(bookingId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return _buildContent(context, booking: snapshot.data);
        },
      );
    }
    return _buildContent(context, booking: null);
  }

  Widget _buildContent(BuildContext context, {BookingModel? booking}) {
    final user = AuthService.instance.currentUser;
    final bookedBy = (user?.displayName?.isNotEmpty ?? false) ? user!.displayName! : 'Guest';
    final stallLabel = booking != null ? '${booking.storeName} · ${booking.stallCode}' : null;
    final dateLabel = booking != null ? _formatDate(booking.date) : '29th June, Wednesday';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.of(context).pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              height: 74,
              width: 74,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Reservation Confirmed!', style: AppTextStyles.heading, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Your booking has been successful', style: AppTextStyles.subheading, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stallLabel != null) ...[
                    Text('Stall: $stallLabel', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                  ],
                  Text('Seat Booked by: $bookedBy', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Phone Number: ${user?.phoneNumber ?? '02-XXX-XXXX'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(dateLabel, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false),
                child: const Text('Return'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${d.day}${_ordinal(d.day)} ${months[d.month - 1]}, ${weekdays[d.weekday - 1]}';
  }

  String _ordinal(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

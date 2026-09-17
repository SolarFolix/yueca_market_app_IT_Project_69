import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/booking_model.dart';
import '../services/auth_service.dart';
import '../services/market_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedDay ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Calendar')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('Choose any date — no restrictions', style: AppTextStyles.subheading),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: TableCalendar(
              // Freely browsable — any date roughly ±2 years from today,
              // not locked to a single hardcoded week.
              firstDay: DateTime.now().subtract(const Duration(days: 730)),
              lastDay: DateTime.now().add(const Duration(days: 730)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textSecondary),
                rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                weekendStyle: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: const TextStyle(fontSize: 12.5),
                weekendTextStyle: TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                todayDecoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 1.4),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Available Slots — ${_formatDate(selected)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                _slotCard(context, 'Market Zone A', '09:00 - 20:00', available: true),
                const SizedBox(height: 10),
                _slotCard(context, 'Market Zone B', '09:00 - 20:00', available: false),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('My Bookings', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _myBookingsSection(),
          ),
          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget _myBookingsSection() {
    if (!AuthService.instance.isAvailable) {
      return Column(
        children: [
          _bookingCard('Fresh Produce · A2', '29 Jul 2026', 'Confirmed', AppColors.success),
          const SizedBox(height: 10),
          _bookingCard('Street Food Hub · B4', '3 Aug 2026', 'Pending', const Color(0xFFC98A1F)),
        ],
      );
    }
    return StreamBuilder<List<BookingModel>>(
      stream: MarketService.instance.myBookingsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final bookings = snapshot.data ?? const [];
        if (bookings.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Text('No bookings yet — rent a stall from Home to see it here.', style: AppTextStyles.subheading, textAlign: TextAlign.center),
          );
        }
        return Column(
          children: [
            for (int i = 0; i < bookings.length; i++) ...[
              _bookingCard(
                '${bookings[i].storeName} · ${bookings[i].stallCode}',
                _shortDate(bookings[i].date),
                bookings[i].statusLabel,
                _statusColor(bookings[i].status),
              ),
              if (i != bookings.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return AppColors.success;
      case BookingStatus.pending:
        return const Color(0xFFC98A1F);
      case BookingStatus.cancelled:
        return AppColors.danger;
    }
  }

  String _shortDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget _bookingCard(String title, String date, String status, Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                Text(date, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: statusColor)),
          ),
        ],
      ),
    );
  }

  Widget _slotCard(BuildContext context, String title, String time, {required bool available}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(height: 54, width: 54, color: AppColors.primaryLight.withOpacity(0.3), child: const Icon(Icons.storefront_rounded, color: AppColors.primaryDark)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(available ? 'Available' : 'Unavailable', style: TextStyle(fontSize: 11, color: available ? AppColors.success : AppColors.danger)),
              ],
            ),
          ),
          TextButton(
            onPressed: available ? () => Navigator.of(context).pushNamed('/market-selection') : null,
            child: const Text('Details'),
          ),
        ],
      ),
    );
  }
}

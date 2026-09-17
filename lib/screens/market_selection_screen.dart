import 'package:flutter/material.dart';
import '../models/stall_model.dart';
import '../services/auth_service.dart';
import '../services/market_service.dart';
import '../theme/app_theme.dart';
import 'booking_details_screen.dart';

class MarketSelectionScreen extends StatefulWidget {
  final String storeName;
  const MarketSelectionScreen({super.key, this.storeName = 'Store 1'});

  @override
  State<MarketSelectionScreen> createState() => _MarketSelectionScreenState();
}

class _MarketSelectionScreenState extends State<MarketSelectionScreen> {
  static const rows = MarketService.stallRows;
  static const cols = MarketService.stallCols;

  String? selected;
  bool _isBooking = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, StallModel>>(
      stream: MarketService.instance.stallsStreamWithFallback(),
      builder: (context, snapshot) {
        final stalls = {
          for (final code in MarketService.allStallCodes())
            code: snapshot.data?[code] ?? StallModel.emptyAvailable(code),
        };
        return _buildScaffold(context, stalls);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, Map<String, StallModel> stalls) {
    final bookedCount = stalls.values.where((s) => s.booked).length;
    final availableCount = stalls.length - bookedCount;
    final selectedStall = selected != null ? stalls[selected] : null;
    final canBook = selected != null && selectedStall != null && !selectedStall.booked;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.of(context).pop()),
        title: Text(widget.storeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text('$availableCount available', style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Text('•  $bookedCount booked', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  children: rows.map((r) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: cols.map((c) {
                          final label = '$r$c';
                          final stall = stalls[label] ?? StallModel.emptyAvailable(label);
                          final isBooked = stall.booked;
                          final isSelected = selected == label;
                          return GestureDetector(
                            onTap: isBooked ? null : () => setState(() => selected = label),
                            child: Container(
                              height: 26,
                              width: 26,
                              alignment: Alignment.center,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : isBooked
                                        ? AppColors.textSecondary.withOpacity(0.35)
                                        : AppColors.success.withOpacity(0.15),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : (isBooked ? AppColors.border : AppColors.success.withOpacity(0.5)),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: isBooked
                                  ? const Icon(Icons.lock_rounded, size: 10, color: Colors.white)
                                  : Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 7,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white : AppColors.success,
                                      ),
                                    ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(AppColors.success.withOpacity(0.15), AppColors.success, 'Available'),
                const SizedBox(width: 18),
                _legendDot(AppColors.textSecondary.withOpacity(0.35), AppColors.border, 'Booked'),
                const SizedBox(width: 18),
                _legendDot(AppColors.primary, AppColors.primary, 'Selected'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected == null ? AppColors.border : AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    selected ?? '--',
                    style: TextStyle(color: selected == null ? AppColors.textSecondary : Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.storeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      Text(
                        selected == null ? 'Tap an available stall to select it' : 'Slot fee: ฿250 · Fri–Sun',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(90, 40)),
                  onPressed: (canBook && !_isBooking) ? () => _handleRent(context) : null,
                  child: _isBooking
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Rent'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRent(BuildContext context) async {
    final code = selected!;

    if (!AuthService.instance.isAvailable) {
      // Demo mode — no backend to reserve against, just walk through the
      // flow with placeholder details so the UI stays fully clickable.
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingDetailsScreen(stallCode: code, storeName: widget.storeName, feeAmount: 250),
        ),
      );
      return;
    }

    setState(() => _isBooking = true);
    try {
      final bookingId = await MarketService.instance.bookStall(
        code: code,
        storeName: widget.storeName,
        date: DateTime.now(),
        feeAmount: 250,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingDetailsScreen(
            bookingId: bookingId,
            stallCode: code,
            storeName: widget.storeName,
            feeAmount: 250,
            date: DateTime.now(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is StateError && e.message == 'stall-already-booked'
          ? 'That stall was just taken by someone else — pick another.'
          : (e is StateError ? e.message : 'Could not book that stall. Please try again.');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.danger));
      setState(() => selected = null);
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  Widget _legendDot(Color fill, Color border, String label) {
    return Row(
      children: [
        Container(
          height: 14,
          width: 14,
          decoration: BoxDecoration(color: fill, border: Border.all(color: border), borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import '../services/market_service.dart';
import '../theme/app_theme.dart';
import 'success_screen.dart';

class PaymentScreen extends StatefulWidget {
  // Optional — see booking_details_screen.dart's doc comment. Without
  // these (guest/demo mode, or the named '/payment' route with no
  // arguments), Confirm/Cancel just navigate without touching Firestore.
  final String? bookingId;
  final String? stallCode;
  final String? storeName;
  final double? feeAmount;

  const PaymentScreen({super.key, this.bookingId, this.stallCode, this.storeName, this.feeAmount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _slipUploaded = false;
  bool _isSubmitting = false;

  bool get _isRealBooking => widget.bookingId != null && AuthService.instance.isAvailable;

  // Demo-only in-memory "upload" — no file_picker dependency yet, so this
  // simulates picking a file. Swap the body of this method for a real
  // file_picker + Firebase Storage upload once you're ready to store
  // actual payment slips.
  Future<void> _handleUpload() async {
    if (_slipUploaded) {
      setState(() => _slipUploaded = false);
      return;
    }
    setState(() => _slipUploaded = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Slip uploaded (demo) — tap again to remove')),
    );
  }

  Future<void> _handleCancel() async {
    if (!_isRealBooking) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await MarketService.instance.cancelBooking(widget.bookingId!, widget.stallCode!);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled — stall released')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not cancel. Please try again.'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _handleConfirm() async {
    if (!_isRealBooking) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SuccessScreen()));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await MarketService.instance.confirmBooking(widget.bookingId!);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SuccessScreen(bookingId: widget.bookingId)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not confirm. Please try again.'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fee = widget.feeAmount ?? 250;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(
                data: 'yuea-market-place://payment/booking/${widget.stallCode ?? 'A2'}/${fee.toStringAsFixed(0)}THB',
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _handleUpload,
              icon: Icon(_slipUploaded ? Icons.check_circle_rounded : Icons.upload_rounded, size: 18),
              label: Text(_slipUploaded ? 'Slip Uploaded' : 'Upload'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: Colors.white,
                backgroundColor: _slipUploaded ? AppColors.success : AppColors.primary,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                onPressed: _isSubmitting ? null : _handleCancel,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                onPressed: (_slipUploaded && !_isSubmitting) ? _handleConfirm : null,
                child: _isSubmitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm'),
              ),
            ),
            if (!_slipUploaded) ...[
              const SizedBox(height: 8),
              Text('Upload your payment slip to confirm', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

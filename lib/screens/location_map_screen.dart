import 'package:flutter/material.dart';
import '../models/stall_model.dart';
import '../services/auth_service.dart';
import '../services/market_service.dart';
import '../theme/app_theme.dart';

class LocationMapScreen extends StatelessWidget {
  const LocationMapScreen({super.key});

  static const rows = MarketService.stallRows;
  static const cols = MarketService.stallCols;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, StallModel>>(
      stream: MarketService.instance.stallsStreamWithFallback(),
      builder: (context, snapshot) {
        final stalls = {
          for (final code in MarketService.allStallCodes())
            code: snapshot.data?[code] ?? StallModel.emptyAvailable(code),
        };
        final uid = AuthService.instance.currentUser?.uid;
        String? myCode;
        String? myStore;
        for (final entry in stalls.entries) {
          if (uid != null && entry.value.bookedByUid == uid) {
            myCode = entry.key;
            myStore = entry.value.storeName;
            break;
          }
        }
        return _buildScaffold(context, stalls, myUid: uid, myStallCode: myCode, myStoreName: myStore);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, Map<String, StallModel> stalls, {String? myUid, String? myStallCode, String? myStoreName}) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Market Map', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
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
                          final isMine = label == myStallCode;
                          return _plot(label, stall.booked, isMine);
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(AppColors.success.withOpacity(0.15), AppColors.success, 'Available'),
                const SizedBox(width: 16),
                _legendDot(AppColors.textSecondary.withOpacity(0.35), AppColors.border, 'Booked'),
                const SizedBox(width: 16),
                _legendDot(AppColors.primaryDark, AppColors.primaryDark, 'Your stall'),
              ],
            ),
          ),
          if (myStallCode != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(10)),
                    child: Text(myStallCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(myStoreName ?? 'Your store', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        Text('Your rented stall', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text("You don't have a rented stall yet", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }

  Widget _plot(String label, bool booked, bool mine) {
    return Container(
      height: 26,
      width: 26,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: mine
            ? AppColors.primaryDark
            : booked
                ? AppColors.textSecondary.withOpacity(0.35)
                : AppColors.success.withOpacity(0.15),
        border: Border.all(color: mine ? AppColors.primaryDark : (booked ? AppColors.border : AppColors.success.withOpacity(0.5))),
        borderRadius: BorderRadius.circular(4),
      ),
      child: (booked && !mine)
          ? const Icon(Icons.lock_rounded, size: 10, color: Colors.white)
          : Text(label, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w600, color: mine ? Colors.white : AppColors.success)),
    );
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

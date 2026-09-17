import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pure loading state — shown by AuthGate while Firebase resolves the
/// current session. No navigation logic lives here anymore; main.dart's
/// AuthGate decides where to go once auth state is known.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.change_history_rounded, color: AppColors.primaryDark, size: 90),
            SizedBox(height: 12),
            Text(
              'Yuea Market Place',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 28),
            SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_asset_image.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top market photo area with rounded bottom corners. Expanded
            // (instead of a fixed height) so this scales with the actual
            // screen height instead of overflowing on shorter devices.
            Expanded(
              flex: 3,
              child: SizedBox(
                width: double.infinity,
                // Drop your market photo in as assets/images/welcome_banner.jpg
                // and it replaces this placeholder automatically.
                child: AppAssetImage(
                  assetPath: 'assets/images/welcome_page.jpg',
                  fallbackIcon: Icons.storefront_rounded,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome !', style: AppTextStyles.heading),
                  const SizedBox(height: 6),
                  Text(
                    'Hello there, sign in to continue.',
                    style: AppTextStyles.subheading,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/login'),
                      child: const Text('Next'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamedAndRemoveUntil('/home', (route) => false),
                      child: Text(
                        'Continue as Guest',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

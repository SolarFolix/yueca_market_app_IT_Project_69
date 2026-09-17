import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/location_map_screen.dart';
import 'screens/market_selection_screen.dart';
import 'screens/success_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Expected until you run `flutterfire configure` and firebase_options.dart
    // has real values. AuthGate below checks AuthService.instance.isAvailable
    // and falls back to the Welcome screen (with a working Guest Mode) so the
    // whole frontend stays fully clickable while the backend isn't wired up yet.
    debugPrint('Firebase init skipped/failed: $e');
  }

  await ThemeController.load();

  runApp(const YueaMarketApp());
}

class YueaMarketApp extends StatelessWidget {
  const YueaMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Yuea Market Place',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          // AuthGate decides splash -> welcome (logged out) or splash -> home (logged in).
          home: const AuthGate(),
          routes: {
            '/welcome': (context) => const WelcomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/home': (context) => const HomeScreen(),
            '/analytics': (context) => const AnalyticsScreen(),
            '/calendar': (context) => const CalendarScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            '/location': (context) => const LocationMapScreen(),
            '/market-selection': (context) => const MarketSelectionScreen(),
            '/success': (context) => const SuccessScreen(),
            // BookingDetailsScreen and PaymentScreen both require a real
            // bookingId from MarketService.bookStall(), so they're only
            // ever reached via MaterialPageRoute pushes from
            // market_selection_screen.dart / booking_details_screen.dart —
            // not registered here as named routes.
          },
        );
      },
    );
  }
}

/// Shows the splash animation, then routes based on real Firebase auth
/// state — logged-in users skip straight to Home, everyone else sees
/// the Welcome/Login flow. If Firebase isn't configured yet, it skips
/// straight to Welcome (which has a Guest Mode button) instead of
/// crashing on a missing Firebase app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AuthService.instance.isAvailable) {
      return const WelcomeScreen();
    }
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const WelcomeScreen();
      },
    );
  }
}

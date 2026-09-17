import 'package:flutter/material.dart';
import 'theme_controller.dart';

/// Central color + text style palette so every screen stays visually
/// consistent. Brand colors (primary, success, danger, unread) stay fixed
/// across light/dark. Background/card/border/text colors flip based on
/// ThemeController.mode — that's why they're getters, not const fields:
/// a value that must change at runtime can't be a compile-time constant,
/// which is also why call sites that used to write `const Widget(...)`
/// around these had that `const` removed.
class AppColors {
  AppColors._();

  // Brand colors — identical across light and dark.
  static const Color primaryDark = Color(0xFF0E2A6E);
  static const Color primary = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B6FE0);
  static const Color success = Color(0xFF1FAA59);
  static const Color danger = Color(0xFFE0473E);
  static const Color unread = Color(0xFF1D4ED8);

  static bool get _isDark {
    final mode = ThemeController.mode.value;
    if (mode == ThemeMode.dark) return true;
    if (mode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  static Color get background =>
      _isDark ? const Color(0xFF0E1117) : const Color(0xFFF7F8FA);
  static Color get card => _isDark ? const Color(0xFF1A1E28) : Colors.white;
  static Color get border =>
      _isDark ? const Color(0xFF2B303C) : const Color(0xFFE3E6EC);
  static Color get textPrimary =>
      _isDark ? const Color(0xFFF2F3F7) : const Color(0xFF13214A);
  static Color get textSecondary =>
      _isDark ? const Color(0xFF9AA1B4) : const Color(0xFF8A93A6);
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get heading => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryDark,
      );

  static TextStyle get subheading => TextStyle(
        fontSize: 13,
        color: AppColors.textSecondary,
      );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static TextStyle get body => TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
      );
}

class AppTheme {
  AppTheme._();

  // Once you've added .ttf files to assets/fonts and uncommented the
  // `fonts:` block in pubspec.yaml, change this to your family name
  // (e.g. 'Poppins') and every screen picks it up automatically.
  static const String fontFamily = 'Roboto';

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF0E1117) : const Color(0xFFF7F8FA);
    final border = isDark ? const Color(0xFF2B303C) : const Color(0xFFE3E6EC);
    final card = isDark ? const Color(0xFF1A1E28) : Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: AppColors.primary,
      fontFamily: fontFamily,
      splashFactory: InkRipple.splashFactory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: AppColors.primary,
        surface: card,
      ),
      cardColor: card,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppColors.primaryDark,
        ),
        titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.primaryDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          minimumSize: const Size.fromHeight(50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        errorStyle: const TextStyle(color: AppColors.danger, fontSize: 11),
        enabledBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: border)),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.danger, width: 1.2),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.danger, width: 1.4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: isDark
          ? Typography.material2021(platform: TargetPlatform.android).white
          : Typography.material2021(platform: TargetPlatform.android).black,
    );
  }
}

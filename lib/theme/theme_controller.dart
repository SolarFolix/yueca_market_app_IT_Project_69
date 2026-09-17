import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global light/dark/system theme state. A single ValueNotifier is enough
/// for an app this size — MaterialApp listens to it in main.dart, and
/// Settings writes to it. Persisted locally so the choice survives restarts.
class ThemeController {
  ThemeController._();

  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static const _prefsKey = 'theme_mode';

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      switch (saved) {
        case 'light':
          mode.value = ThemeMode.light;
          break;
        case 'dark':
          mode.value = ThemeMode.dark;
          break;
        default:
          mode.value = ThemeMode.system;
      }
    } catch (_) {
      // shared_preferences unavailable (e.g. some test environments) —
      // fall back to system default, nothing breaks.
    }
  }

  static Future<void> set(ThemeMode newMode) async {
    mode.value = newMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, newMode.name);
    } catch (_) {
      // Non-fatal — the in-memory value above still applies this session.
    }
  }
}

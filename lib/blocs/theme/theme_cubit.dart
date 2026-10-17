import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages application-wide theme mode (System Default, Dark Slate, Light Pearl).
/// Automatically defaults to [ThemeMode.system] and persists the user preference.
class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themePrefKey = 'user_theme_mode_v2';
  static const String _legacyKey = 'user_theme_mode';

  ThemeCubit() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString(_themePrefKey);
      if (modeString != null) {
        switch (modeString) {
          case 'light':
            emit(ThemeMode.light);
            return;
          case 'dark':
            emit(ThemeMode.dark);
            return;
          case 'system':
          default:
            emit(ThemeMode.system);
            return;
        }
      }

      // Check legacy boolean preference if v2 key does not exist
      if (prefs.containsKey(_legacyKey)) {
        final isLight = prefs.getBool(_legacyKey) ?? false;
        emit(isLight ? ThemeMode.light : ThemeMode.dark);
        return;
      }

      // Default is always system mode
      emit(ThemeMode.system);
    } catch (_) {
      emit(ThemeMode.system);
    }
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setTheme(newMode);
  }

  Future<void> setTheme(ThemeMode mode) async {
    emit(mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await prefs.setString(_themePrefKey, modeStr);
    } catch (_) {}
  }
}

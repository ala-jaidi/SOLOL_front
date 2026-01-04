import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// Manages global app settings like theme mode and locale.
class AppSettings extends ChangeNotifier {
  static const _kThemeModeKey = 'app.themeMode';
  static const _kLocaleKey = 'app.locale';

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale; // null => system

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  bool get isDark => _themeMode == ThemeMode.dark;

  AppSettings() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeStr = prefs.getString(_kThemeModeKey);
      switch (themeStr) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }

      final localeStr = prefs.getString(_kLocaleKey);
      if (localeStr == null || localeStr == 'system') {
        _locale = null;
        Intl.defaultLocale = null;
      } else {
        _locale = Locale(localeStr);
        Intl.defaultLocale = localeStr;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('AppSettings load error: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await prefs.setString(_kThemeModeKey, value);
    } catch (e) {
      debugPrint('AppSettings setThemeMode error: $e');
    }
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    Intl.defaultLocale = locale?.languageCode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLocaleKey, locale?.languageCode ?? 'system');
    } catch (e) {
      debugPrint('AppSettings setLocale error: $e');
    }
  }

  Future<void> toggleDark(bool enabled) => setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
}

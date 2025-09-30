// File: lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A `ChangeNotifier` to manage and persist the app's theme mode.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;
  static const String themeKey = 'isDarkMode';

  /// Initializes the theme with a a provided preference.
  ThemeProvider({bool initialIsDark = false})
      : _themeMode = initialIsDark ? ThemeMode.dark : ThemeMode.light;

  /// Gets the current `ThemeMode` (`light` or `dark`).
  ThemeMode get themeMode => _themeMode;

  /// Returns `true` if the current theme mode is dark.
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Toggles the theme mode and persists the change to `SharedPreferences`.
  Future<void> toggleTheme(bool isOn) async {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(themeKey, isOn);
  }

  /// Statically loads the theme preference from `SharedPreferences`.
  static Future<bool> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(themeKey) ?? false;
  }
}
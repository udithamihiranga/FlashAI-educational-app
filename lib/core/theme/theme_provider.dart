import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Detects the system's current brightness preference and sets the theme
  /// mode accordingly. Call this during app initialization.
  void detectSystemBrightness() {
    final platformBrightness = WidgetsBinding.instance.platformDispatcher;
    final brightness = platformBrightness.platformBrightness;
    final newMode =
        brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode != newMode) {
      _themeMode = newMode;
      notifyListeners();
    }
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  void toggleTheme(bool isDark) {
    setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  /// Returns true if dark mode is currently active.
  bool get isDarkMode => _themeMode == ThemeMode.dark;
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme Service for managing app theme (light/dark/system)
///
/// Provides:
/// - Theme mode persistence via SharedPreferences
/// - Dynamic theme switching
/// - Notifies listeners when theme changes
class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeModeKey = 'theme_mode';

  // ValueNotifier to notify listeners when theme changes
  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier(ThemeMode.system);

  /// Initialize the service and load saved theme preference
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeModeKey);

    if (savedTheme != null) {
      themeModeNotifier.value = _stringToThemeMode(savedTheme);
    } else {
      // Default to system theme if no preference saved
      themeModeNotifier.value = ThemeMode.system;
    }
  }

  /// Get current theme mode
  ThemeMode get themeMode => themeModeNotifier.value;

  /// Set theme mode and persist to SharedPreferences
  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeToString(mode));
  }

  /// Check if dark mode is currently active
  /// (either explicitly set to dark, or system is in dark mode)
  bool get isDarkMode {
    if (themeModeNotifier.value == ThemeMode.dark) return true;
    if (themeModeNotifier.value == ThemeMode.light) return false;

    // For system mode, we'd need the platform brightness
    // This will be handled by the MaterialApp's themeMode
    return false;
  }

  /// Convert ThemeMode enum to string for storage
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Convert string to ThemeMode enum
  ThemeMode _stringToThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Dispose resources
  void dispose() {
    themeModeNotifier.dispose();
  }
}

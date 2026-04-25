import 'package:flutter/material.dart';

/// App-wide color constants for light & dark themes.
class AppColors {
  // ─── Light Mode ───
  static const Color lightBackground = Colors.white;
  static const Color lightSurface = Color(0xFFF1F6FF);
  static const Color lightTitleText = Color(0xFF0D286F);
  static const Color lightSubtitleText = Color(0xFF607D8B); // blueGrey
  static const Color lightAccentButton = Color(0xFF1A4DBE);
  static const Color lightAccentButtonText = Colors.white;
  static const Color lightInputFill = Color(0xFFE8EAF6); // indigo[50]
  static const Color lightCardSurface = Color(0xFFF5F5F5);
  static const Color lightDotActive = Color(0xFF1A4DBE);
  static const Color lightDotInactive = Color(0xFFE0E0E0);
  static const Color lightSkipText = Colors.grey;

  // ─── Dark Mode ───
  static const Color darkBackground = Color(0xFF0A1628);
  static const Color darkSurface = Color(0xFF1A2540);
  static const Color darkTitleText = Colors.white;
  static const Color darkSubtitleText = Color(0xFF9E9E9E); // grey[500]
  static const Color darkAccentButton = Color(0xFFE5C94B); // gold/yellow
  static const Color darkAccentButtonText = Color(0xFF1A1A1A);
  static const Color darkInputFill = Color(0xFF1A2540);
  static const Color darkCardSurface = Color(0xFF1A2540);
  static const Color darkDotActive = Color(0xFF0D286F);
  static const Color darkDotInactive = Color(0xFF616161);
  static const Color darkSkipText = Color(0xFF9E9E9E);

  // ─── Shared ───
  static const Color primaryBlue = Color(0xFF1A4DBE);
  static const Color brandYellow = Color(0xFFE5C94B);
  static const Color vibrantBlue = Color(0xFF2962FF);
  static const Color emergencyRed = Color(0xFFFF4B2B);
}

/// Global theme notifier — drives light / dark switching app-wide.
final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.system);

/// Toggle between light and dark (ignores system after first tap).
void toggleTheme() {
  themeNotifier.value =
      themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}

/// Helper to check if current context is in dark mode.
bool isDarkMode(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

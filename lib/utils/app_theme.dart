import 'package:flutter/material.dart';

// Original app color constants — kept for any reference that survived the refactor.
class AppColors {
  AppColors._();
  static const Color navBar = Color(0xFF37393F); // AppBar background
  static const Color bodyBg = Color(0xFFD8DBE2); // Scaffold body background
  static const Color buttonDark = Color(0xFF101418); // Dark Save/action button
  // Legacy aliases
  static const Color background = navBar;
  static const Color bodyBackground = bodyBg;
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    // All inputs default to outlined style (matching the original design).
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    // Floating dark snackbar — nicer than the plain white default.
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.navBar,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

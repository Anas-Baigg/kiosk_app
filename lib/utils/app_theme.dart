import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dark amber design system — extracted from the Stitch barbershop reference.
class AppColors {
  AppColors._();

  // Surfaces — dark layered system
  static const Color background = Color(0xFF131313);
  static const Color surface = Color(0xFF201F1F);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color surfaceHighest = Color(0xFF353534);
  static const Color surfaceBright = Color(0xFF393939);

  // Primary accent — amber
  static const Color primary = Color(0xFFFFBA38);
  static const Color primaryContainer = Color(0xFFFFB300);
  static const Color onPrimary = Color(0xFF432C00);

  // Text
  static const Color onSurface = Color(0xFFE5E2E1);
  static const Color onSurfaceVariant = Color(0xFFD6C4AC);
  static const Color outline = Color(0xFF9E8E78);
  static const Color outlineVariant = Color(0xFF514532);

  // Semantic
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFBA38);

  // Legacy aliases — keep so nothing breaks
  static const Color background2 = surface;
  static const Color bodyBackground = surface;
  static const Color buttonDark = surfaceHigh;
}

/// Typography — Hanken Grotesk (display/body) + JetBrains Mono (labels/amounts).
class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayLg() => GoogleFonts.hankenGrotesk(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.02 * 48,
    color: AppColors.onSurface,
  );

  static TextStyle headlineLg() => GoogleFonts.hankenGrotesk(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
  );

  static TextStyle titleMd() => GoogleFonts.hankenGrotesk(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static TextStyle bodyLg() => GoogleFonts.hankenGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  static TextStyle bodySm() => GoogleFonts.hankenGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle labelCaps() => GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1 * 12,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle price() => GoogleFonts.jetBrainsMono(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      error: AppColors.error,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.titleMd(),
      surfaceTintColor: Colors.transparent,
      shape: const Border(
        bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outlineVariant, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: AppTextStyles.labelCaps(),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      hintStyle: AppTextStyles.bodySm(),
      labelStyle: AppTextStyles.bodySm(),
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceHighest,
      contentTextStyle: AppTextStyles.bodySm(),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

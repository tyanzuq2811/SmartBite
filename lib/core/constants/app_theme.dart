import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fresh Tech (Emerald & Royal Blue) color scheme extracted from Stitch design.
/// App: "SmartBite - AI Culinary Assistant & Diet Tracker"
class AppColors {
  // ─── Light Theme ───
  static const primary = Color(0xFF006C49);
  static const primaryContainer = Color(0xFF10B981); // Emerald Green
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF00422B);

  static const secondary = Color(0xFF0058BE); // Royal Blue
  static const secondaryContainer = Color(0xFF2170E4);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFFFEFCFF);

  static const tertiary = Color(0xFF494BD6); // Indigo
  static const tertiaryContainer = Color(0xFF9699FF);

  static const surface = Color(0xFFF8F9FF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFEFF4FF);
  static const surfaceContainer = Color(0xFFE5EEFF);
  static const surfaceContainerHigh = Color(0xFFDCE9FF);
  static const surfaceContainerHighest = Color(0xFFD3E4FE);
  static const surfaceDim = Color(0xFFCBDBF5);

  static const onSurface = Color(0xFF0B1C30);
  static const onSurfaceVariant = Color(0xFF3C4A42);
  static const outline = Color(0xFF6C7A71);
  static const outlineVariant = Color(0xFFBBCABF);

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onError = Color(0xFFFFFFFF);
  static const onErrorContainer = Color(0xFF93000A);

  static const inverseSurface = Color(0xFF213145);
  static const inverseOnSurface = Color(0xFFEAF1FF);
  static const inversePrimary = Color(0xFF4EDEA3);

  // ─── Dark Theme ───
  static const primaryDark = Color(0xFF4EDEA3);
  static const primaryContainerDark = Color(0xFF005236);
  static const onPrimaryDark = Color(0xFF002113);
  static const onPrimaryContainerDark = Color(0xFF6FFBCE);

  static const secondaryDark = Color(0xFFADC6FF);
  static const secondaryContainerDark = Color(0xFF004395);
  static const onSecondaryDark = Color(0xFF001A42);
  static const onSecondaryContainerDark = Color(0xFFD8E2FF);

  static const surfaceDark = Color(0xFF0F172A);
  static const surfaceContainerLowestDark = Color(0xFF020617);
  static const surfaceContainerLowDark = Color(0xFF1E293B);
  static const surfaceContainerDark = Color(0xFF334155);
  static const surfaceContainerHighDark = Color(0xFF475569);
  static const surfaceContainerHighestDark = Color(0xFF64748B);

  static const onSurfaceDark = Color(0xFFF8FAFC);
  static const onSurfaceVariantDark = Color(0xFF94A3B8);
  static const outlineDark = Color(0xFF64748B);
  static const outlineVariantDark = Color(0xFF334155);

  static const errorDark = Color(0xFFFFB4AB);
  static const errorContainerDark = Color(0xFF93000A);
}

class AppTheme {
  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseColor = brightness == Brightness.light
        ? AppColors.onSurface
        : AppColors.onSurfaceDark;
    final secondaryColor = brightness == Brightness.light
        ? AppColors.onSurfaceVariant
        : AppColors.onSurfaceVariantDark;

    return TextTheme(
      displaySmall: GoogleFonts.outfit(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 30,
        height: 38 / 30,
        color: baseColor,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01 * 24,
        height: 32 / 24,
        color: baseColor,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: baseColor,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 24 / 18,
        color: baseColor,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 24 / 16,
        color: baseColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: baseColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: secondaryColor,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05 * 12,
        height: 16 / 12,
        color: baseColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 16 / 11,
        color: secondaryColor,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        onPrimary: AppColors.onPrimary,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondary: AppColors.onSecondary,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
        onError: AppColors.onError,
        onErrorContainer: AppColors.onErrorContainer,
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.inverseOnSurface,
        inversePrimary: AppColors.inversePrimary,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        surfaceDim: AppColors.surfaceDim,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: _buildTextTheme(Brightness.light),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x1F6C7A71)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        indicatorColor: AppColors.surfaceContainerLow,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
          letterSpacing: -0.24,
        ),
        iconTheme: const IconThemeData(color: AppColors.onSurfaceVariant),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x3D6C7A71)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x3D6C7A71)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimaryContainer,
        elevation: 2,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDark,
        primaryContainer: AppColors.primaryContainerDark,
        onPrimary: AppColors.onPrimaryDark,
        onPrimaryContainer: AppColors.onPrimaryContainerDark,
        secondary: AppColors.secondaryDark,
        secondaryContainer: AppColors.secondaryContainerDark,
        onSecondary: AppColors.onSecondaryDark,
        onSecondaryContainer: AppColors.onSecondaryContainerDark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.onSurfaceDark,
        onSurfaceVariant: AppColors.onSurfaceVariantDark,
        outline: AppColors.outlineDark,
        outlineVariant: AppColors.outlineVariantDark,
        error: AppColors.errorDark,
        errorContainer: AppColors.errorContainerDark,
        surfaceContainerLowest: AppColors.surfaceContainerLowestDark,
        surfaceContainerLow: AppColors.surfaceContainerLowDark,
        surfaceContainer: AppColors.surfaceContainerDark,
        surfaceContainerHigh: AppColors.surfaceContainerHighDark,
        surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
      ),
      scaffoldBackgroundColor: AppColors.surfaceDark,
      textTheme: _buildTextTheme(Brightness.dark),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x2BFFFFFF)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowestDark,
        indicatorColor: AppColors.surfaceContainerLowDark,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceDark,
          letterSpacing: -0.24,
        ),
        iconTheme: const IconThemeData(color: AppColors.onSurfaceVariantDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x2BFFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x2BFFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorDark, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.onPrimaryDark,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryContainerDark,
        foregroundColor: AppColors.onPrimaryContainerDark,
        elevation: 2,
      ),
    );
  }
}

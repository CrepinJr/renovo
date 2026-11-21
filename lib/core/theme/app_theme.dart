import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App color palette and Material 3 theme configurations for Renovo,
/// calibrated exactly against the Stitch "Sacred Minimalism" design system.
class AppTheme {
  AppTheme._();

  // --- Brand Accents ---
  static const Color liturgicalIndigo = Color(0xFF2C3E6B);
  static const Color onLiturgicalIndigo = Color(0xFFFFFFFF);

  static const Color sageEmerald = Color(0xFF2E7D5B);
  static const Color onSageEmerald = Color(0xFFFFFFFF);
  static const Color sageTint = Color(0xFFE8F3EE);
  static const Color onSageTint = Color(0xFF003824);

  static const Color antiqueGold = Color(0xFFD49A3A);
  static const Color onAntiqueGold = Color(0xFF281800);
  static const Color goldTint = Color(0xFFFFEEDB);
  static const Color onGoldTint = Color(0xFF442C00);

  // --- Neutrals ---
  static const Color alabaster = Color(0xFFFAF8F5);
  static const Color obsidian = Color(0xFF121316);
  static const Color slateCharcoal = Color(0xFF1C1E24);

  // --- Light Palette ---
  static const Color lightPrimary = Color(0xFF2C3E6B);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFDAE2FF);
  static const Color lightOnPrimaryContainer = Color(0xFF021945);
  static const Color lightSurface = Color(0xFFFAF8F5);
  static const Color lightSurfaceContainer = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerLow = Color(0xFFF2F0ED);
  static const Color lightOnSurface = Color(0xFF1C1B18);
  static const Color lightOnSurfaceVariant = Color(0xFF5E5E5C);
  static const Color lightOutline = Color(0xFFEAE5DC);
  static const Color lightOutlineVariant = Color(0xFFE4E2DF);

  // --- Dark Palette ---
  static const Color darkPrimary = Color(0xFFB4C5FB);
  static const Color darkOnPrimary = Color(0xFF021945);
  static const Color darkPrimaryContainer = Color(0xFF1C2F5B);
  static const Color darkOnPrimaryContainer = Color(0xFFDAE2FF);
  static const Color darkSurface = Color(0xFF121316);
  static const Color darkSurfaceContainer = Color(0xFF1C1E24);
  static const Color darkSurfaceContainerLow = Color(0xFF191B23);
  static const Color darkOnSurface = Color(0xFFF3F1ED);
  static const Color darkOnSurfaceVariant = Color(0xFFACABA8);
  static const Color darkOutline = Color(0xFF2A2D35);
  static const Color darkOutlineVariant = Color(0xFF2E3038);

  // Status Marker aliases for backwards compatibility and clarity
  static const Color effectiveMarker = sageEmerald;
  static const Color effectiveMarkerLight = sageTint;
  static const Color predictionMarker = antiqueGold;
  static const Color predictionMarkerLight = goldTint;

  /// Light Theme
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: lightPrimary,
      onPrimary: lightOnPrimary,
      primaryContainer: lightPrimaryContainer,
      onPrimaryContainer: lightOnPrimaryContainer,
      surface: lightSurface,
      onSurface: lightOnSurface,
      onSurfaceVariant: lightOnSurfaceVariant,
      outline: lightOutline,
      outlineVariant: lightOutlineVariant,
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightSurface,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.lora(
          fontSize: 32,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.25,
          color: lightOnSurface,
        ),
        headlineLarge: GoogleFonts.lora(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          color: lightOnSurface,
        ),
        headlineMedium: GoogleFonts.lora(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.15,
          color: lightOnSurface,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: lightOnSurface,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: lightOnSurface,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: lightOnSurface,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: lightOnSurfaceVariant,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: lightOnSurface,
        ),
        labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          color: lightOnSurface,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          color: lightOnSurfaceVariant,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: lightSurface,
        foregroundColor: lightOnSurface,
        titleTextStyle: GoogleFonts.lora(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          color: lightOnSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightOutline, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: lightPrimary,
          foregroundColor: lightOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightOnSurface,
          side: const BorderSide(color: lightOutline, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightOutline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightOutline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightPrimary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: lightOnSurfaceVariant,
        ),
      ),
    );
  }

  /// Dark Theme
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: darkPrimary,
      onPrimary: darkOnPrimary,
      primaryContainer: darkPrimaryContainer,
      onPrimaryContainer: darkOnPrimaryContainer,
      surface: darkSurface,
      onSurface: darkOnSurface,
      onSurfaceVariant: darkOnSurfaceVariant,
      outline: darkOutline,
      outlineVariant: darkOutlineVariant,
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkSurface,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.lora(
          fontSize: 32,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.25,
          color: darkOnSurface,
        ),
        headlineLarge: GoogleFonts.lora(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          color: darkOnSurface,
        ),
        headlineMedium: GoogleFonts.lora(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.15,
          color: darkOnSurface,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: darkOnSurface,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkOnSurface,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: darkOnSurfaceVariant,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: darkOnSurface,
        ),
        labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          color: darkOnSurface,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          color: darkOnSurfaceVariant,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: darkSurface,
        foregroundColor: darkOnSurface,
        titleTextStyle: GoogleFonts.lora(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          color: darkOnSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkOutline, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: darkPrimary,
          foregroundColor: darkOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkOnSurface,
          side: const BorderSide(color: darkOutline, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkOutline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkOutline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkPrimary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: darkOnSurfaceVariant,
        ),
      ),
    );
  }
}

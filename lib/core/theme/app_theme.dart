import 'package:flutter/material.dart';

/// FoodBridge Design System Theme
/// Features: Warm green palette, accessible WCAG AA contrast, and minimum 48x48dp touch targets.
class AppTheme {
  // Brand Color Palette
  static const Color primaryGreen = Color(0xFF1E6F5C);
  static const Color primaryGreenLight = Color(0xFF289672);
  static const Color primaryContainer = Color(0xFFD4ECE3);
  static const Color onPrimaryContainer = Color(0xFF0A3328);

  static const Color secondaryAmber = Color(0xFFE08E45);
  static const Color secondaryContainer = Color(0xFFFDE8D7);
  static const Color onSecondaryContainer = Color(0xFF4A2A0C);

  static const Color alertRed = Color(0xFFC62828);
  static const Color alertContainer = Color(0xFFFFEBEE);

  static const Color neutralSlate = Color(0xFF2F4858);
  static const Color surfaceLight = Color(0xFFFBFDFB);
  static const Color surfaceCardLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF4F8F5);

  static const Color surfaceDark = Color(0xFF121B17);
  static const Color surfaceCardDark = Color(0xFF1B2822);
  static const Color backgroundDark = Color(0xFF0B120F);

  // Minimum touch target dimension (accessible standard)
  static const double minTouchTargetSize = 48.0;

  /// Light Theme Definition
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: primaryGreen,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondaryAmber,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      surface: surfaceLight,
      onSurface: const Color(0xFF1A221E),
      error: alertRed,
      onError: Colors.white,
      errorContainer: alertContainer,
      onErrorContainer: const Color(0xFF5C0E0E),
      outline: const Color(0xFFB0C4BA),
      surfaceContainerHighest: const Color(0xFFEBF2EE),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: surfaceLight,
        foregroundColor: Color(0xFF1A221E),
        iconTheme: IconThemeData(color: primaryGreen, size: 24),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A221E),
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCardLight,
        elevation: 1.5,
        shadowColor: primaryGreen.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2EBE5), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(minTouchTargetSize, minTouchTargetSize),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          minimumSize: const Size(minTouchTargetSize, minTouchTargetSize),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: primaryGreen, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          minimumSize: const Size(minTouchTargetSize, minTouchTargetSize),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCCD9D1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCCD9D1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: alertRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: alertRed, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF4A5D54)),
        floatingLabelStyle: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w600),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryContainer.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2EBE5),
        thickness: 1,
        space: 24,
      ),
    );
  }

  /// Dark Theme Definition
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: primaryGreenLight,
      onPrimary: const Color(0xFF042118),
      primaryContainer: const Color(0xFF134E3E),
      onPrimaryContainer: primaryContainer,
      secondary: secondaryAmber,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF4D2B09),
      onSecondaryContainer: secondaryContainer,
      surface: surfaceDark,
      onSurface: const Color(0xFFE5EDE8),
      error: const Color(0xFFEF5350),
      onError: Colors.white,
      outline: const Color(0xFF3B5247),
      surfaceContainerHighest: const Color(0xFF22332A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundDark,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: surfaceDark,
        foregroundColor: Color(0xFFE5EDE8),
        iconTheme: IconThemeData(color: primaryGreenLight, size: 24),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE5EDE8),
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF293B32), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreenLight,
          foregroundColor: const Color(0xFF042118),
          minimumSize: const Size(minTouchTargetSize, minTouchTargetSize),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF19251F),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E4338)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E4338)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreenLight, width: 2),
        ),
      ),
    );
  }
}

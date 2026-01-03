import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors - Apple Style Monochrome
  static const Color primaryColor = Color(0xFF000000); 
  static const Color secondaryColor = Color(0xFF1D1D1F); // Dark Apple Text
  static const Color backgroundColor = Color(0xFFF5F5F7); // Apple White/Grey
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFFF3B30); // Apple Red
  static const Color successColor = Color(0xFF34C759); // Apple Green
  static const Color greyColor = Color(0xFF86868B); // Secondary Apple Text

  // Text Styles - Inter
  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: secondaryColor,
    letterSpacing: -1.0,
  );

  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: secondaryColor,
    letterSpacing: -0.7,
  );

  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: secondaryColor,
    letterSpacing: -0.4,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: secondaryColor,
    letterSpacing: -0.2,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: greyColor,
  );

  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        background: backgroundColor,
        surface: surfaceColor,
        error: errorColor,
        onSurface: secondaryColor,
      ),
      
      // Typography
      textTheme: TextTheme(
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        titleLarge: titleLarge,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        labelLarge: labelLarge,
      ),

      // Card Theme - Smooth & Subtle
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.black.withOpacity(0.04)),
        ),
        margin: const EdgeInsets.only(bottom: 16),
      ),

      // Input Decoration Theme - Minimalist & Smooth
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor),
        ),
        hintStyle: TextStyle(color: greyColor.withOpacity(0.6)),
      ),

      // Button Theme - Pill Shaped & High Contrast
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), // Pill
          textStyle: labelLarge.copyWith(fontWeight: FontWeight.bold),
        ),
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor.withOpacity(0.8),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: titleLarge,
        iconTheme: const IconThemeData(color: secondaryColor),
        scrolledUnderElevation: 0,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        thickness: 1,
        color: Colors.black.withOpacity(0.05),
      ),
    );
  }
}

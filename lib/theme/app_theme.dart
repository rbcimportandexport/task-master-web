import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Vibrant Premium Accents
  static const Color primaryBlue = Color(0xFF4F46E5); // Indigo 600
  static const Color accentBlue = Color(0xFF8B5CF6);  // Violet 500
  static const Color darkBlue = Color(0xFF312E81);    // Indigo 900
  static const Color brandText = Color(0xFF4338CA);   // Indigo 700
  static const Color fabBlue = Color(0xFF6366F1);     // Indigo 500

  // Modern Backgrounds
  static const Color background = Color(0xFFF8FAFC);  // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceCard = Color(0xFFFFFFFF);  // Pure White
  
  static const Color chipInactiveBg = Color(0xFFF1F5F9); // Slate 100
  static const Color chipInactiveText = Color(0xFF64748B); // Slate 500
  static const Color chipActiveBg = Color(0xFFEEF2FF);   // Indigo 50
  
  // Premium Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8);   // Slate 400

  static const Color tooltipYellow = Color(0xFFFBBF24); // Amber 400
  static const Color tooltipText = Color(0xFF451A03);   // Warm Dark

  static const Color proGold = Color(0xFFF59E0B);     // Amber 500

  static ThemeData dynamicTheme(Color primary) {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: accentBlue,
        surface: surfaceLight,
        background: background,
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: primaryBlue,
        headerForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        dayStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
        weekdayStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: textSecondary),
        yearStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500),
        cancelButtonStyle: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(textSecondary),
          textStyle: WidgetStateProperty.all(GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
        ),
        confirmButtonStyle: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(primaryBlue),
          textStyle: WidgetStateProperty.all(GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ),
      fontFamily: GoogleFonts.outfit().fontFamily,
    );
  }

  static ThemeData get lightTheme => dynamicTheme(primaryBlue);
}

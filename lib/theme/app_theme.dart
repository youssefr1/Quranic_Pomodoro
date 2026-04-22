import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color palette
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color darkGreen = Color(0xFF0D3B13);
  static const Color lightGreen = Color(0xFF2E7D32);
  static const Color accentGold = Color(0xFFD4A843);
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color cardBackground = Color(0xFFF5F5F0);

  // Mushaf page colors
  static const Color mushafBackground = Color(0xFFFFF8E7);
  static const Color mushafText = Color(0xFF1A1A1A);
  static const Color mushafBorder = Color(0xFFD4A843);
  static const Color ayahMarker = Color(0xFF1B5E20);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        onPrimary: Colors.white,
        surface: backgroundLight,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: primaryGreen,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.cairo(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.cairo(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.cairo(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.cairo(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primaryGreen,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: backgroundWhite,
        indicatorColor: primaryGreen.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: primaryGreen,
            );
          }
          return GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
      ),
    );
  }

  /// Text style for Quran mushaf text
  static TextStyle get mushafTextStyle => GoogleFonts.amiri(
        fontSize: 22,
        height: 2.0,
        color: mushafText,
        fontWeight: FontWeight.w400,
      );

  /// Text style for verse end markers
  static TextStyle get ayahEndStyle => GoogleFonts.amiri(
        fontSize: 18,
        color: ayahMarker,
        fontWeight: FontWeight.w400,
      );
}

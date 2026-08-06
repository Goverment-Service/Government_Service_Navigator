import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // iOS-style color palette
  static const Color primary       = Color(0xFF007AFF); // iOS system blue
  static const Color success       = Color(0xFF34C759); // iOS green
  static const Color warning       = Color(0xFFFF9500); // iOS orange
  static const Color danger        = Color(0xFFFF3B30); // iOS red
  static const Color label         = Color(0xFF000000); // primary label
  static const Color secondaryLabel = Color(0xFF8E8E93); // secondary label
  static const Color systemGray6   = Color(0xFFF2F2F7); // iOS systemGray6
  static const Color systemGray5   = Color(0xFFE5E5EA); // dividers
  static const Color cardBg        = Color(0xFFFFFFFF); // white cards
  static const Color screenBg      = Color(0xFFF2F2F7); // iOS grouped bg

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: screenBg,
        onPrimary: Colors.white,
        onSurface: label,
      ),
      scaffoldBackgroundColor: screenBg,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      // Typography — SF-like feel via Inter
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge:  GoogleFonts.inter(color: label,          fontWeight: FontWeight.w700, fontSize: 34, letterSpacing: -0.5),
        displayMedium: GoogleFonts.inter(color: label,          fontWeight: FontWeight.w700, fontSize: 28, letterSpacing: -0.4),
        titleLarge:    GoogleFonts.inter(color: label,          fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.3),
        titleMedium:   GoogleFonts.inter(color: label,          fontWeight: FontWeight.w600, fontSize: 17),
        bodyLarge:     GoogleFonts.inter(color: label,          fontWeight: FontWeight.w400, fontSize: 17),
        bodyMedium:    GoogleFonts.inter(color: secondaryLabel, fontWeight: FontWeight.w400, fontSize: 15),
        bodySmall:     GoogleFonts.inter(color: secondaryLabel, fontWeight: FontWeight.w400, fontSize: 13),
        labelLarge:    GoogleFonts.inter(color: primary,        fontWeight: FontWeight.w600, fontSize: 17),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cardBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primary),
        titleTextStyle: GoogleFonts.inter(
          color: label,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      // iOS-style cards — no elevation, clean white with radius
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      // iOS-style elevated buttons — fully rounded pill shape
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
      // iOS-style text fields — filled, rounded, no hard border
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger),
        ),
        hintStyle: GoogleFonts.inter(color: secondaryLabel, fontSize: 17),
      ),
      dividerColor: systemGray5,
      listTileTheme: const ListTileThemeData(
        tileColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
    );
  }
}

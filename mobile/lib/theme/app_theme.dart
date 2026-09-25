import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App-wide light theme: soft grey background, white cards, one official navy accent.
class AppTheme {
  AppTheme._();

  static const Color primary        = AppColors.primary;
  static const Color success        = AppColors.success;
  static const Color warning        = AppColors.warning;
  static const Color danger         = AppColors.danger;
  static const Color label          = AppColors.dark;
  static const Color secondaryLabel = AppColors.secondaryLabel;
  static const Color cardBg         = AppColors.cardBg;
  static const Color screenBg       = AppColors.background;

  static ThemeData get theme {
    final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
    final shape14 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: AppColors.accent,
        surface: cardBg,
        onPrimary: Colors.white,
        onSurface: label,
        error: danger,
      ),
      scaffoldBackgroundColor: screenBg,
      canvasColor: screenBg,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      dividerColor: AppColors.divider,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
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
        backgroundColor: screenBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: label,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primary),
        titleTextStyle: GoogleFonts.inter(color: label, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.2),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.divider,
          disabledForegroundColor: secondaryLabel,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          shape: shape14,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 17),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: AppColors.divider),
          shape: shape14,
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: primary)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger),
        ),
        labelStyle: GoogleFonts.inter(color: secondaryLabel),
        hintStyle: GoogleFonts.inter(color: secondaryLabel, fontSize: 16),
        prefixIconColor: secondaryLabel,
        suffixIconColor: secondaryLabel,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: primary,
        textColor: label,
        shape: shape14,
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: secondaryLabel, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primary : Colors.transparent),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.divider),
        ),
        titleTextStyle: GoogleFonts.inter(color: label, fontSize: 19, fontWeight: FontWeight.w700),
        contentTextStyle: GoogleFonts.inter(color: secondaryLabel, fontSize: 15),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: cardBg,
        showDragHandle: true,
        dragHandleColor: AppColors.divider,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: label,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: shape14,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: cardBg,
        selectedColor: primary.withValues(alpha: 0.12),
        side: const BorderSide(color: AppColors.divider),
        labelStyle: GoogleFonts.inter(color: label, fontSize: 13),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(backgroundColor: WidgetStatePropertyAll(cardBg)),
      ),
      popupMenuTheme: const PopupMenuThemeData(color: cardBg, surfaceTintColor: Colors.transparent),
      datePickerTheme: const DatePickerThemeData(backgroundColor: cardBg, surfaceTintColor: Colors.transparent),
      drawerTheme: const DrawerThemeData(backgroundColor: screenBg, surfaceTintColor: Colors.transparent),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBg,
        selectedItemColor: primary,
        unselectedItemColor: secondaryLabel,
      ),
      cupertinoOverrideTheme: const NoDefaultCupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: primary,
        barBackgroundColor: cardBg,
        scaffoldBackgroundColor: screenBg,
      ),
    );
  }
}

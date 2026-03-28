import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kBackground = Color(0xFF051424);
const kSurface = Color(0xFF0A1929);
const kPrimary = Color(0xFFFF3B30);
const kSecondary = Color(0xFF26A69A);
const kTextPrimary = Color(0xFFD5E4FA);
const kTextMuted = Color(0xFF7A9BC2);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kBackground,
    colorScheme: const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: kPrimary,
      secondary: kSecondary,
      surface: kSurface,
      error: kPrimary,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: kTextPrimary,
      onError: Colors.white,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.manrope(
        color: kTextPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 32,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.manrope(
        color: kTextPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 28,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.manrope(
        color: kTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 24,
      ),
      headlineMedium: GoogleFonts.manrope(
        color: kTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      headlineSmall: GoogleFonts.manrope(
        color: kTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleLarge: GoogleFonts.manrope(
        color: kTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleMedium: GoogleFonts.manrope(
        color: kTextPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      titleSmall: GoogleFonts.manrope(
        color: kTextPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      bodyLarge: GoogleFonts.inter(
        color: kTextPrimary,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        color: kTextPrimary,
        fontSize: 14,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        color: kTextMuted,
        fontSize: 13,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.inter(
        color: kTextPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: GoogleFonts.inter(
        color: kTextMuted,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.inter(
        color: kTextMuted,
        fontSize: 11,
        letterSpacing: 0.5,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: kSurface.withOpacity(0.95),
      foregroundColor: kTextPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.manrope(
        color: kTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: kTextMuted.withOpacity(0.1),
          width: 1,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kTextPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        side: BorderSide(
          color: kTextMuted.withOpacity(0.3),
          width: 1,
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: kTextMuted.withOpacity(0.2),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: kSecondary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: kPrimary,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: kPrimary,
          width: 2,
        ),
      ),
      labelStyle: GoogleFonts.inter(
        color: kTextMuted,
        fontSize: 14,
      ),
      hintStyle: GoogleFonts.inter(
        color: kTextMuted.withOpacity(0.5),
        fontSize: 14,
      ),
      errorStyle: GoogleFonts.inter(
        color: kPrimary,
        fontSize: 12,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kSurface,
      contentTextStyle: GoogleFonts.inter(
        color: kTextPrimary,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: GoogleFonts.manrope(
        color: kTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: GoogleFonts.inter(
        color: kTextMuted,
        fontSize: 14,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: kTextMuted.withOpacity(0.15),
      thickness: 1,
    ),
    iconTheme: const IconThemeData(
      color: kTextMuted,
      size: 24,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: kPrimary,
      linearTrackColor: kSurface,
      circularTrackColor: kSurface,
    ),
  );
}

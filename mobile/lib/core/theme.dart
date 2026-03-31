import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Liquid Glass Palette ──────────────────────────────────────────────────────
const kBackground = Color(0xFF051424);
const kSurface = Color(0xFF0A1929);
const kPrimary = Color(0xFFFF3B30);        // Emergency Red
const kSecondary = Color(0xFF26A69A);       // Safe Green
const kBrandBlue = Color(0xFF0084FF);       // Primary Brand
const kBrandBlueSoft = Color(0x800084FF);   // rgba(0,132,255,0.5)
const kTextPrimary = Color(0xFFD5E4FA);
const kTextMuted = Color(0xFF7A9BC2);
const kGlowBlueLight = Color(0xFF60B1FF);
const kGlowBlueDeep = Color(0xFF319AFF);

// Glass Surface Recipe
BoxDecoration glassSurfaceDecoration = BoxDecoration(
  color: const Color(0x0FFFFFFF), // rgba(255,255,255,0.06)
  borderRadius: BorderRadius.circular(20),
  border: Border.all(
    color: const Color(0x1AFFFFFF), // rgba(255,255,255,0.10)
    width: 1,
  ),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
    const BoxShadow(
      color: Color(0x14FFFFFF), // rgba(255,255,255,0.08)
      blurRadius: 4,
      offset: Offset(0, 4),
      spreadRadius: -4,
    ),
  ],
);

// Glass surface with backdrop blur simulation (Flutter doesn't support backdrop-filter directly)
BoxDecoration glassSurfaceBlurredDecoration = BoxDecoration(
  color: const Color(0xB30A1929), // rgba(10,25,41,0.7)
  borderRadius: BorderRadius.circular(20),
  border: Border.all(
    color: const Color(0x1AFFFFFF),
    width: 1,
  ),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
  ],
);

// Background Glow Recipe
Widget buildBackgroundGlow({Alignment alignment = Alignment.topLeft}) {
  return Positioned.fill(
    child: Align(
      alignment: alignment,
      child: Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              kGlowBlueDeep.withValues(alpha: 0.35),
              kGlowBlueLight.withValues(alpha: 0.25),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
            radius: 0.6,
          ),
        ),
      ),
    ),
  );
}

// Glass button inner highlight
BoxDecoration glassButtonDecoration = BoxDecoration(
  gradient: LinearGradient(
    colors: [
      kBrandBlue.withValues(alpha: 0.8),
      kBrandBlue.withValues(alpha: 0.9),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: kBrandBlue.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    const BoxShadow(
      color: Color(0x59FFFFFF), // rgba(255,255,255,0.35)
      blurRadius: 4,
      offset: Offset(0, 4),
      spreadRadius: -4,
    ),
  ],
);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
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
      displayLarge: GoogleFonts.fustat(
        color: kTextPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 32,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.fustat(
        color: kTextPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 28,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.fustat(
        color: kTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 24,
      ),
      headlineMedium: GoogleFonts.fustat(
        color: kTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      headlineSmall: GoogleFonts.fustat(
        color: kTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleLarge: GoogleFonts.inter(
        color: kTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleMedium: GoogleFonts.inter(
        color: kTextPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      titleSmall: GoogleFonts.inter(
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
      backgroundColor: Colors.transparent,
      foregroundColor: kTextPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.fustat(
        color: kTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(
        color: kTextPrimary,
        size: 24,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0x0FFFFFFF),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0x1AFFFFFF),
          width: 1,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kBrandBlue.withValues(alpha: 0.8),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kTextPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: const BorderSide(
          color: Color(0x4DFFFFFF),
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
      fillColor: const Color(0x0FFFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0x33FFFFFF),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: kSecondary,
          width: 1.5,
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
        color: kTextMuted.withValues(alpha: 0.5),
        fontSize: 14,
      ),
      errorStyle: GoogleFonts.inter(
        color: kPrimary,
        fontSize: 12,
      ),
      prefixIconColor: kTextMuted,
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
      titleTextStyle: GoogleFonts.fustat(
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
    dividerTheme: const DividerThemeData(
      color: Color(0x26FFFFFF),
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
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0x0FFFFFFF),
      labelStyle: GoogleFonts.inter(
        color: kTextPrimary,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0x1AFFFFFF),
          width: 1,
        ),
      ),
    ),
  );
}

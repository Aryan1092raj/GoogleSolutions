// dashboard/lib/core/dashboard_theme.dart
// Liquid Glass Design System for ResQLink Dashboard

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Liquid Glass Palette ──────────────────────────────────────────────────────
const kDashBg = Color(0xFF051424);        // Dark Background
const kDashSurface = Color(0x800A1929);   // Surface with transparency
const kDashSurface2 = Color(0x0FFFFFFF);  // Glass surface
const kDashBorder = Color(0x1AFFFFFF);    // rgba(255,255,255,0.10)
const kDashAccent = Color(0xFF0084FF);    // Primary Brand Blue
const kDashDanger = Color(0xFFFF3B30);    // Emergency Red
const kDashWarning = Color(0xFFFFCC00);   // Amber
const kDashInfo = Color(0xFF3B82F6);      // Blue
const kDashText = Color(0xFFD5E4FA);      // Primary text
const kDashTextSub = Color(0xFF7A9BC2);   // Secondary text
const kDashTextMut = Color(0xFF3D5269);   // Muted
const kDashGreen = Color(0xFF26A69A);     // Safe Green
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
      color: Color(0x14FFFFFF),
      blurRadius: 4,
      offset: Offset(0, 4),
      spreadRadius: -4,
    ),
  ],
);

// Background Glow Widget
Widget buildBackgroundGlow({Alignment alignment = Alignment.topLeft}) {
  return Positioned.fill(
    child: Align(
      alignment: alignment,
      child: Container(
        width: 500,
        height: 500,
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

// Severity helpers
Color severityColor(String s) {
  switch (s.toUpperCase()) {
    case 'CRITICAL':
      return kDashDanger;
    case 'HIGH':
      return const Color(0xFFFF6B35);
    case 'MEDIUM':
      return kDashWarning;
    default:
      return kDashGreen;
  }
}

Color statusColor(String s) {
  switch (s.toUpperCase()) {
    case 'ACTIVE':
      return kDashDanger;
    case 'ACKNOWLEDGED':
      return kDashInfo;
    case 'RESOLVED':
      return kDashGreen;
    default:
      return kDashTextMut;
  }
}

ThemeData buildDashboardTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: kDashBg,
    colorScheme: const ColorScheme.dark(
      surface: kDashSurface,
      primary: kDashAccent,
      secondary: kDashInfo,
      error: kDashDanger,
      onSurface: kDashText,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.fustat(
        color: kDashText,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
      iconTheme: const IconThemeData(color: kDashText),
    ),
    cardTheme: CardThemeData(
      color: const Color(0x0FFFFFFF),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: kDashBorder),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: kDashBorder,
      thickness: 1,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.fustat(
        color: kDashText,
        fontSize: 36,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.fustat(
        color: kDashText,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      titleLarge: GoogleFonts.fustat(
        color: kDashText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.fustat(
        color: kDashText,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
      bodyLarge: GoogleFonts.inter(
        color: kDashText,
        fontSize: 14,
      ),
      bodyMedium: GoogleFonts.inter(
        color: kDashText,
        fontSize: 13,
      ),
      bodySmall: GoogleFonts.inter(
        color: kDashTextSub,
        fontSize: 12,
      ),
      labelMedium: GoogleFonts.inter(
        color: kDashTextSub,
        fontSize: 11,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        color: kDashTextMut,
        fontSize: 10,
        letterSpacing: 1.0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x0FFFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: kDashBorder,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: kDashAccent,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: kDashDanger,
        ),
      ),
      labelStyle: GoogleFonts.inter(
        color: kDashTextSub,
        fontSize: 13,
      ),
      hintStyle: GoogleFonts.inter(
        color: kDashTextSub.withValues(alpha: 0.5),
        fontSize: 13,
      ),
      prefixIconColor: kDashTextSub,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kDashAccent.withValues(alpha: 0.8),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0x0FFFFFFF),
        foregroundColor: kDashText,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: kDashBorder),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kDashText,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        side: const BorderSide(
          color: Color(0x4DFFFFFF),
          width: 1,
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kDashSurface,
      contentTextStyle: GoogleFonts.inter(
        color: kDashText,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kDashSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: GoogleFonts.fustat(
        color: kDashText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: GoogleFonts.inter(
        color: kDashTextSub,
        fontSize: 14,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0x0FFFFFFF),
      labelStyle: GoogleFonts.inter(
        color: kDashText,
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
    iconTheme: const IconThemeData(
      color: kDashTextSub,
      size: 20,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: kDashAccent,
      linearTrackColor: kDashSurface,
      circularTrackColor: kDashSurface,
    ),
  );
}

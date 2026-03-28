// dashboard/lib/core/dashboard_theme.dart
// Replace or create this file at that path.
// Run: flutter pub add google_fonts  (if not already in pubspec.yaml)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Palette ─────────────────────────────────────────────────────────────────
const kDashBg       = Color(0xFF060D1A);   // deep space navy
const kDashSurface  = Color(0xFF0D1A2E);   // card surface
const kDashSurface2 = Color(0xFF132134);   // elevated / input bg
const kDashBorder   = Color(0xFF1A2E44);   // subtle grid lines
const kDashAccent   = Color(0xFF00C9A7);   // teal – connected / safe
const kDashDanger   = Color(0xFFFF453A);   // red – critical / fire
const kDashWarning  = Color(0xFFFFB800);   // amber – high / warning
const kDashInfo     = Color(0xFF3B82F6);   // blue – acknowledged
const kDashText     = Color(0xFFE8F0FF);   // primary text
const kDashTextSub  = Color(0xFF6B8FA8);   // secondary text
const kDashTextMut  = Color(0xFF3D5269);   // muted / labels
const kDashGreen    = Color(0xFF30D158);   // online / resolved

// ── Severity helpers ─────────────────────────────────────────────────────────
Color severityColor(String s) {
  switch (s.toUpperCase()) {
    case 'CRITICAL': return kDashDanger;
    case 'HIGH':     return const Color(0xFFFF6B35);
    case 'MEDIUM':   return kDashWarning;
    default:         return kDashAccent;
  }
}

Color statusColor(String s) {
  switch (s.toUpperCase()) {
    case 'ACTIVE':       return kDashDanger;
    case 'ACKNOWLEDGED': return kDashInfo;
    case 'RESOLVED':     return kDashGreen;
    default:             return kDashTextMut;
  }
}

// ── Theme ────────────────────────────────────────────────────────────────────
ThemeData buildDashboardTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kDashBg,
    colorScheme: const ColorScheme.dark(
      surface:   kDashSurface,
      primary:   kDashAccent,
      secondary: kDashInfo,
      error:     kDashDanger,
      onSurface: kDashText,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: kDashSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.rajdhani(
        color: kDashText, fontSize: 15,
        fontWeight: FontWeight.w600, letterSpacing: 1.4,
      ),
      iconTheme: const IconThemeData(color: kDashTextSub),
    ),
    cardTheme: CardThemeData(
      color: kDashSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: kDashBorder),
      ),
    ),
    dividerTheme: const DividerThemeData(color: kDashBorder, thickness: 1),
    textTheme: TextTheme(
      displayLarge:   GoogleFonts.rajdhani(color: kDashText, fontSize: 36, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.rajdhani(color: kDashText, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0.4),
      titleLarge:     GoogleFonts.rajdhani(color: kDashText, fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium:    GoogleFonts.rajdhani(color: kDashText, fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0.2),
      bodyLarge:      GoogleFonts.karla(color: kDashText, fontSize: 14),
      bodyMedium:     GoogleFonts.karla(color: kDashText, fontSize: 13),
      bodySmall:      GoogleFonts.karla(color: kDashTextSub, fontSize: 12),
      labelMedium:    GoogleFonts.ibmPlexMono(color: kDashTextMut, fontSize: 11, letterSpacing: 1.2),
      labelSmall:     GoogleFonts.ibmPlexMono(color: kDashTextMut, fontSize: 10, letterSpacing: 1.0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kDashSurface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kDashBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kDashBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kDashAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kDashDanger),
      ),
      labelStyle:  GoogleFonts.karla(color: kDashTextSub, fontSize: 13),
      hintStyle:   GoogleFonts.karla(color: kDashTextMut, fontSize: 13),
      prefixIconColor: kDashTextMut,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kDashAccent,
        foregroundColor: kDashBg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kDashSurface2,
        foregroundColor: kDashText,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: kDashBorder),
        ),
        textStyle: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.8),
      ),
    ),
  );
}

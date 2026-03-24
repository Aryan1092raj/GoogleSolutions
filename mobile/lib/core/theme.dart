import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kBackground  = Color(0xFF051424);
const kSurface     = Color(0xFF0A1929);
const kPrimary     = Color(0xFFFF3B30);
const kSecondary   = Color(0xFF26A69A);
const kTextPrimary = Color(0xFFD5E4FA);
const kTextMuted   = Color(0xFF7A9BC2);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kBackground,
    colorScheme: const ColorScheme.dark(
      background:   kBackground,
      surface:      kSurface,
      primary:      kPrimary,
      secondary:    kSecondary,
      onBackground: kTextPrimary,
      onSurface:    kTextPrimary,
      onPrimary:    Colors.white,
    ),
    textTheme: TextTheme(
      displayLarge:  GoogleFonts.manrope(color: kTextPrimary, fontWeight: FontWeight.w700),
      headlineMedium:GoogleFonts.manrope(color: kTextPrimary, fontWeight: FontWeight.w600),
      titleMedium:   GoogleFonts.manrope(color: kTextPrimary, fontWeight: FontWeight.w500),
      bodyMedium:    GoogleFonts.inter(color: kTextPrimary),
      bodySmall:     GoogleFonts.inter(color: kTextMuted),
      labelSmall:    GoogleFonts.inter(color: kTextMuted, fontSize: 11),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kSurface,
      foregroundColor: kTextPrimary,
      elevation: 0,
    ),
    cardTheme: const CardTheme(
      color: kSurface,
      elevation: 0,
    ),
  );
}

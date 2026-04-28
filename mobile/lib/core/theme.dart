import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kBackground = Color(0xFF08090A);
const kSurface = Color(0xFF141516);
const kSurfaceHigh = Color(0xFF191A1B);
const kSurfaceActive = Color(0xFF252628);
const kPanel = Color(0xFF0F1011);

const kPrimary = Color(0xFFEF4444);
const kSecondary = Color(0xFF22C55E);
const kBrandBlue = Color(0xFF3B82F6);
const kBrandBlueSoft = Color(0x663B82F6);

const kTextPrimary = Color(0xFFF7F8F8);
const kTextMuted = Color(0xFF8A8F98);
const kTextSecondary = Color(0xFFD0D6E0);

BoxDecoration glassSurfaceDecoration = BoxDecoration(
  color: kSurface,
  borderRadius: BorderRadius.circular(8),
  border: Border.all(
    color: const Color(0x14FFFFFF),
    width: 1,
  ),
);

BoxDecoration glassSurfaceBlurredDecoration = BoxDecoration(
  color: kSurfaceHigh,
  borderRadius: BorderRadius.circular(8),
  border: Border.all(
    color: const Color(0x14FFFFFF),
    width: 1,
  ),
);

Widget buildBackgroundGlow({Alignment alignment = Alignment.topLeft}) {
  return Positioned.fill(
    child: IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: alignment,
            end: Alignment.bottomRight,
            colors: const [
              Color(0x11000000),
              Colors.transparent,
            ],
          ),
        ),
      ),
    ),
  );
}

BoxDecoration glassButtonDecoration = BoxDecoration(
  color: kBrandBlue,
  borderRadius: BorderRadius.circular(10),
  border: Border.all(
    color: kBrandBlue.withValues(alpha: 0.35),
  ),
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
      displayLarge: GoogleFonts.inter(
        color: kTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 32,
      ),
      displayMedium: GoogleFonts.inter(
        color: kTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 28,
      ),
      displaySmall: GoogleFonts.inter(
        color: kTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 24,
      ),
      headlineMedium: GoogleFonts.inter(
        color: kTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      headlineSmall: GoogleFonts.inter(
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
        color: kTextSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      bodyLarge: GoogleFonts.inter(
        color: kTextSecondary,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        color: kTextSecondary,
        fontSize: 14,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        color: kTextMuted,
        fontSize: 13,
        height: 1.45,
      ),
      labelLarge: GoogleFonts.inter(
        color: kTextPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: GoogleFonts.inter(
        color: kTextSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.inter(
        color: kTextMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: kPanel,
      foregroundColor: kTextPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        color: kTextPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(
        color: kTextPrimary,
        size: 22,
      ),
    ),
    cardTheme: CardThemeData(
      color: kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(
          color: Color(0x14FFFFFF),
          width: 1,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: const BorderSide(
          color: Color(0x1FFFFFFF),
          width: 1,
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kBrandBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kPanel,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0x1FFFFFFF),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: kBrandBlue,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: kPrimary,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: kPrimary,
          width: 1.5,
        ),
      ),
      labelStyle: GoogleFonts.inter(
        color: kTextMuted,
        fontSize: 14,
      ),
      hintStyle: GoogleFonts.inter(
        color: kTextMuted.withValues(alpha: 0.8),
        fontSize: 14,
      ),
      errorStyle: GoogleFonts.inter(
        color: kPrimary,
        fontSize: 12,
      ),
      prefixIconColor: kTextMuted,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kSurfaceHigh,
      contentTextStyle: GoogleFonts.inter(
        color: kTextPrimary,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      titleTextStyle: GoogleFonts.inter(
        color: kTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: GoogleFonts.inter(
        color: kTextSecondary,
        fontSize: 14,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x14FFFFFF),
      thickness: 1,
    ),
    iconTheme: const IconThemeData(
      color: kTextMuted,
      size: 22,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: kBrandBlue,
      linearTrackColor: kPanel,
      circularTrackColor: kPanel,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kSurfaceHigh,
      labelStyle: GoogleFonts.inter(
        color: kTextPrimary,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0x14FFFFFF),
          width: 1,
        ),
      ),
    ),
  );
}

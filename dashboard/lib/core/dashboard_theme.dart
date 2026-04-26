import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kDashBg = Color(0xFF08090A);
const kDashPanel = Color(0xFF0F1011);
const kDashSurface = Color(0xFF141516);
const kDashSurface2 = Color(0xFF191A1B);
const kDashSurfaceHover = Color(0xFF1E1F21);
const kDashSurfaceActive = Color(0xFF252628);

const kDashBorderSubtle = Color(0x0DFFFFFF);
const kDashBorder = Color(0x14FFFFFF);
const kDashBorderEmphasis = Color(0x1FFFFFFF);

const kDashAccent = Color(0xFF3B82F6);
const kDashAccentHover = Color(0xFF60A5FA);
const kDashDanger = Color(0xFFEF4444);
const kDashWarning = Color(0xFFF59E0B);
const kDashInfo = Color(0xFF3B82F6);
const kDashGreen = Color(0xFF22C55E);

const kDashText = Color(0xFFF7F8F8);
const kDashTextSub = Color(0xFFD0D6E0);
const kDashTextMut = Color(0xFF8A8F98);
const kDashTextDim = Color(0xFF62666D);

const kDashTopBarHeight = 48.0;
const kDashStatusBarHeight = 32.0;
const kDashNavRailWidth = 64.0;

BoxDecoration get glassSurfaceDecoration => BoxDecoration(
      color: kDashSurface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: kDashBorder),
    );

BoxDecoration dashboardPanelDecoration({
  Color background = kDashSurface,
  Color border = kDashBorder,
  bool selected = false,
}) {
  return BoxDecoration(
    color: selected ? kDashSurfaceActive : background,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: selected ? kDashBorderEmphasis : border,
    ),
  );
}

Color severityColor(String s) {
  switch (s.toUpperCase()) {
    case 'CRITICAL':
      return kDashDanger;
    case 'HIGH':
      return kDashWarning;
    case 'MEDIUM':
      return kDashInfo;
    case 'RESOLVED':
      return kDashGreen;
    default:
      return kDashTextMut;
  }
}

Color statusColor(String s) {
  switch (s.toUpperCase()) {
    case 'ACTIVE':
      return kDashDanger;
    case 'ACKNOWLEDGED':
      return kDashInfo;
    case 'RESOLVED':
    case 'FALSE_ALARM':
      return kDashGreen;
    default:
      return kDashTextDim;
  }
}

ThemeData buildDashboardTheme() {
  final interText = GoogleFonts.interTextTheme();
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kDashBg,
    colorScheme: const ColorScheme.dark(
      surface: kDashSurface,
      primary: kDashAccent,
      secondary: kDashGreen,
      error: kDashDanger,
      onSurface: kDashText,
    ),
    textTheme: interText.copyWith(
      displayLarge: GoogleFonts.inter(
        color: kDashText,
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: GoogleFonts.inter(
        color: kDashText,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.inter(
        color: kDashText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.inter(
        color: kDashText,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.inter(
        color: kDashTextSub,
        fontSize: 14,
      ),
      bodyMedium: GoogleFonts.inter(
        color: kDashTextSub,
        fontSize: 13,
      ),
      bodySmall: GoogleFonts.inter(
        color: kDashTextMut,
        fontSize: 12,
      ),
      labelLarge: GoogleFonts.inter(
        color: kDashText,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: GoogleFonts.inter(
        color: kDashTextSub,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        color: kDashTextMut,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: kDashBorderSubtle,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kDashPanel,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: kDashBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: kDashBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: kDashAccent),
      ),
      labelStyle: GoogleFonts.inter(color: kDashTextMut, fontSize: 13),
      hintStyle: GoogleFonts.inter(color: kDashTextDim, fontSize: 13),
      prefixIconColor: kDashTextMut,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kDashAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kDashSurface2,
        foregroundColor: kDashText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: kDashBorder),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kDashTextSub,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: kDashBorder),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kDashSurface2,
      contentTextStyle: GoogleFonts.inter(color: kDashTextSub, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    iconTheme: const IconThemeData(
      color: kDashTextMut,
      size: 18,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: kDashPanel,
      elevation: 0,
      titleTextStyle: GoogleFonts.inter(
        color: kDashText,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: kDashTextSub),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: kDashAccent,
      linearTrackColor: kDashPanel,
      circularTrackColor: kDashPanel,
    ),
  );
}

TextStyle dashboardMonoTextStyle({
  Color color = kDashTextSub,
  double fontSize = 12,
  FontWeight fontWeight = FontWeight.w500,
  double? height,
}) {
  return TextStyle(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    fontFamily: 'monospace',
  );
}

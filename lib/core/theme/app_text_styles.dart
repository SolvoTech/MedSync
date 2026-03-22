import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized text styles using Inter font per spec §9.
class AppTextStyles {
  AppTextStyles._();

  // ─── Display ─────────────────────────────────────
  static TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
  );

  static TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 45,
    fontWeight: FontWeight.w400,
  );

  static TextStyle displaySmall = GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w400,
  );

  // ─── Headline ────────────────────────────────────
  static TextStyle headlineLarge = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w600,
  );

  static TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
  );

  static TextStyle headlineSmall = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  // ─── Title ───────────────────────────────────────
  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w500,
  );

  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );

  static TextStyle titleSmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  // ─── Body ────────────────────────────────────────
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  // ─── Label ───────────────────────────────────────
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  /// Build a complete TextTheme with Inter.
  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized text styles for the MEDISNA visual system.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _heading({
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    return GoogleFonts.nunito(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0,
    );
  }

  static TextStyle _body({
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0,
    );
  }

  // ─── Display ─────────────────────────────────────
  static TextStyle displayLarge = _heading(
    fontSize: 57,
    fontWeight: FontWeight.w700,
  );

  static TextStyle displayMedium = _heading(
    fontSize: 45,
    fontWeight: FontWeight.w700,
  );

  static TextStyle displaySmall = _heading(
    fontSize: 36,
    fontWeight: FontWeight.w700,
  );

  // ─── Headline ────────────────────────────────────
  static TextStyle headlineLarge = _heading(
    fontSize: 32,
    fontWeight: FontWeight.w800,
  );

  static TextStyle headlineMedium = _heading(
    fontSize: 28,
    fontWeight: FontWeight.w800,
  );

  static TextStyle headlineSmall = _heading(
    fontSize: 24,
    fontWeight: FontWeight.w800,
  );

  // ─── Title ───────────────────────────────────────
  static TextStyle titleLarge = _heading(
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static TextStyle titleMedium = _body(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static TextStyle titleSmall = _body(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  // ─── Body ────────────────────────────────────────
  static TextStyle bodyLarge = _body(fontSize: 16, fontWeight: FontWeight.w400);

  static TextStyle bodyMedium = _body(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodySmall = _body(fontSize: 12, fontWeight: FontWeight.w400);

  // ─── Label ───────────────────────────────────────
  static TextStyle labelLarge = _body(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static TextStyle labelMedium = _body(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static TextStyle labelSmall = _body(
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );

  /// Build a complete TextTheme with the app font pairing.
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

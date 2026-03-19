import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // ─── Primary Blues ──────────────────────────────────
  static const Color primary = Color(0xFF0066CC);
  static const Color primaryLight = Color(0xFF3D8BDB);
  static const Color primaryDark = Color(0xFF004C99);

  // ─── Secondary Teal ─────────────────────────────────
  static const Color secondary = Color(0xFF00B4D8);
  static const Color secondaryLight = Color(0xFF4DD4EC);
  static const Color secondaryDark = Color(0xFF0090AD);

  // ─── Tertiary Cyan ──────────────────────────────────
  static const Color tertiary = Color(0xFF48CAE4);

  // ─── Surfaces (Light) ───────────────────────────────
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4F8);
  static const Color surfaceTint = Color(0xFFE8F0FE);

  // ─── Surfaces (Dark) ───────────────────────────────
  static const Color darkBackground = Color(0xFF0F1419);
  static const Color darkSurface = Color(0xFF1A2332);
  static const Color darkSurfaceVariant = Color(0xFF1E293B);
  static const Color darkSurfaceTint = Color(0xFF243447);

  // ─── Semantic / Status ──────────────────────────────
  static const Color error = Color(0xFFE53E3E);
  static const Color errorLight = Color(0xFFFED7D7);
  static const Color success = Color(0xFF38A169);
  static const Color successLight = Color(0xFFC6F6D5);
  static const Color warning = Color(0xFFED8936);
  static const Color warningLight = Color(0xFFFEEBC8);
  static const Color info = Color(0xFF4299E1);
  static const Color infoLight = Color(0xFFBEE3F8);

  // ─── Feature-specific accent colors ────────────────
  static const Color medicineAccent = Color(0xFF0077B6);
  static const Color measurementAccent = Color(0xFF38A169);
  static const Color activityAccent = Color(0xFFED8936);
  static const Color streakAccent = Color(0xFFE53E3E);

  // ─── Text (Light) ──────────────────────────────────
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textTertiary = Color(0xFF718096);
  static const Color textDisabled = Color(0xFFA0AEC0);

  // ─── Text (Dark) ───────────────────────────────────
  static const Color darkTextPrimary = Color(0xFFF7FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E0);
  static const Color darkTextTertiary = Color(0xFF8899A6);

  // ─── Misc ──────────────────────────────────────────
  static const Color divider = Color(0xFFE2E8F0);
  static const Color darkDivider = Color(0xFF2D3748);
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF7FAFC);
  static const Color darkShimmerBase = Color(0xFF2D3748);
  static const Color darkShimmerHighlight = Color(0xFF4A5568);

  // ─── Gradient Anchors ──────────────────────────────
  static const Color gradientStart = Color(0xFF0066CC);
  static const Color gradientEnd = Color(0xFF00B4D8);
  static const Color gradientDarkStart = Color(0xFF1A5FB4);
  static const Color gradientDarkEnd = Color(0xFF0090AD);
}

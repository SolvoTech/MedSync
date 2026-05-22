import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Reusable gradient definitions for the MedSync app.
class AppGradients {
  const AppGradients._();

  /// Main hero gradient (headers, splash, prominent UI).
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.gradientStart, AppColors.gradientEnd],
  );

  /// Darker variant for dark theme.
  static const LinearGradient primaryDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.gradientDarkStart, AppColors.gradientDarkEnd],
  );

  /// Vertical hero gradient for app bars.
  static const LinearGradient heroHeader = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0066CC), Color(0xFF57C8FF)],
  );

  /// Soft airy panel gradient used for friendly dashboard cards.
  static const LinearGradient softSky = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFE6F4FF), Color(0xFFDDF7FF)],
    stops: [0.0, 0.58, 1.0],
  );

  /// Stronger blue hero with enough contrast for white foreground text.
  static const LinearGradient blueHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0066CC), Color(0xFF0284C7), Color(0xFF5CCBFF)],
    stops: [0.0, 0.62, 1.0],
  );

  /// Subtle card accent gradient (overlay with low opacity).
  static const LinearGradient cardAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x140066CC), Color(0x0F48CAE4)],
  );

  /// Auth page top decoration.
  static const LinearGradient auth = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0066CC), Color(0xFF46BFFF)],
    stops: [0.0, 1.0],
  );

  /// Streak badge shimmer.
  static const LinearGradient streak = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B35), Color(0xFFE53E3E)],
  );

  /// Success gradient for completed items.
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF38A169), Color(0xFF48BB78)],
  );

  /// Get the appropriate primary gradient based on brightness.
  static LinearGradient primaryFor(Brightness brightness) {
    return brightness == Brightness.dark ? primaryDark : primary;
  }
}

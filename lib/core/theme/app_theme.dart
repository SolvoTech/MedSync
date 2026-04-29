import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  const AppTheme._();

  // ─── Border Radii ──────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radiusFull = 100;

  // ═══════════════════════════════════════════════════
  //  LIGHT THEME
  // ═══════════════════════════════════════════════════
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD6E8FF),
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFD0F0F8),
      onSecondaryContainer: AppColors.secondaryDark,
      tertiary: AppColors.tertiary,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorLight,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      outline: const Color(0xFFCBD5E0),
      outlineVariant: AppColors.divider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTextStyles.textTheme,

      // ─── AppBar ──────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // ─── Cards ───────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: AppColors.divider),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── Navigation Bar ──────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 68,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0,
              overflow: TextOverflow.ellipsis,
            );
          }
          return AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
            letterSpacing: 0,
            overflow: TextOverflow.ellipsis,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.textTertiary, size: 24);
        }),
      ),

      // ─── Filled Button ───────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      // ─── Outlined Button ─────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Text Button ─────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 44),
          textStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Input Decoration ────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.95),
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.95),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textDisabled,
        ),
        prefixIconColor: AppColors.textTertiary,
      ),

      // ─── Tabs ────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textTertiary,
        indicatorColor: AppColors.primary,
        labelStyle: AppTextStyles.labelLarge.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTextStyles.labelLarge,
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.primary, width: 3),
          ),
        ),
      ),

      // ─── Dialog ──────────────────────────────────
      dialogTheme: DialogThemeData(
        elevation: 8,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),

      // ─── Bottom Sheet ────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 8,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        dragHandleColor: AppColors.divider,
        dragHandleSize: const Size(40, 4),
        showDragHandle: true,
      ),

      // ─── Snackbar ────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 4,
        insetPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      ),

      // ─── Chip ────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        side: BorderSide.none,
      ),

      // ─── Divider ─────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ─── List Tile ───────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),

      // ─── Segmented Button ────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusFull),
            ),
          ),
        ),
      ),

      // ─── Progress Indicator ──────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceVariant,
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  DARK THEME
  // ═══════════════════════════════════════════════════
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: const Color(0xFF002B5C),
      primaryContainer: const Color(0xFF1A3A5C),
      onPrimaryContainer: const Color(0xFFD6E8FF),
      secondary: AppColors.secondaryLight,
      onSecondary: const Color(0xFF003544),
      secondaryContainer: const Color(0xFF1A3D4D),
      onSecondaryContainer: const Color(0xFFD0F0F8),
      tertiary: AppColors.tertiary,
      error: const Color(0xFFF56565),
      onError: const Color(0xFF450A0A),
      errorContainer: const Color(0xFF5C1A1A),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      outline: const Color(0xFF4A5568),
      outlineVariant: AppColors.darkDivider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: AppTextStyles.textTheme,

      // ─── AppBar (Dark) ───────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: AppColors.darkBackground,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      ),

      // ─── Cards (Dark) ────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: AppColors.darkDivider.withValues(alpha: 0.8)),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── Navigation Bar (Dark) ───────────────────
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 68,
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryLight.withValues(alpha: 0.15),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0,
              overflow: TextOverflow.ellipsis,
            );
          }
          return AppTextStyles.labelSmall.copyWith(
            color: AppColors.darkTextTertiary,
            fontSize: 10,
            letterSpacing: 0,
            overflow: TextOverflow.ellipsis,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryLight, size: 24);
          }
          return const IconThemeData(
            color: AppColors.darkTextTertiary,
            size: 24,
          );
        }),
      ),

      // ─── Filled Button (Dark) ────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: const Color(0xFF0F1419),
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      // ─── Outlined Button (Dark) ──────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          side: BorderSide(
            color: AppColors.primaryLight.withValues(alpha: 0.5),
            width: 1.5,
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Text Button (Dark) ──────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          minimumSize: const Size(0, 44),
          textStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Input Decoration (Dark) ─────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(
            color: AppColors.darkDivider.withValues(alpha: 0.9),
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(
            color: AppColors.darkDivider.withValues(alpha: 0.9),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(
            color: AppColors.primaryLight,
            width: 2.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: Color(0xFFF56565), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: Color(0xFFF56565), width: 2),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.darkTextTertiary,
        ),
        prefixIconColor: AppColors.darkTextTertiary,
      ),

      // ─── Tabs (Dark) ─────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryLight,
        unselectedLabelColor: AppColors.darkTextTertiary,
        indicatorColor: AppColors.primaryLight,
        labelStyle: AppTextStyles.labelLarge.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTextStyles.labelLarge,
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.primaryLight, width: 3),
          ),
        ),
      ),

      // ─── Dialog (Dark) ───────────────────────────
      dialogTheme: DialogThemeData(
        elevation: 8,
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),

      // ─── Bottom Sheet (Dark) ─────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 8,
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        dragHandleColor: AppColors.darkDivider,
        dragHandleSize: const Size(40, 4),
        showDragHandle: true,
      ),

      // ─── Snackbar (Dark) ─────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkSurface,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 4,
        insetPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      ),

      // ─── Chip (Dark) ─────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        side: BorderSide.none,
      ),

      // ─── Divider (Dark) ──────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),

      // ─── List Tile (Dark) ────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),

      // ─── Segmented Button (Dark) ─────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusFull),
            ),
          ),
        ),
      ),

      // ─── Progress Indicator (Dark) ───────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primaryLight,
        linearTrackColor: AppColors.darkSurfaceVariant,
      ),
    );
  }
}

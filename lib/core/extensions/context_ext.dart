import 'package:flutter/material.dart';

enum AppSnackBarType { success, info, warning, error }

extension BuildContextExt on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  void showSnackBar(String message, {bool isError = false}) {
    _showAppSnackBar(
      message,
      type: isError ? AppSnackBarType.error : AppSnackBarType.info,
    );
  }

  void showSuccessSnackBar(String message) {
    _showAppSnackBar(message, type: AppSnackBarType.success);
  }

  void showInfoSnackBar(String message) {
    _showAppSnackBar(message, type: AppSnackBarType.info);
  }

  void showWarningSnackBar(String message) {
    _showAppSnackBar(message, type: AppSnackBarType.warning);
  }

  void showErrorSnackBar(String message) {
    _showAppSnackBar(message, type: AppSnackBarType.error);
  }

  void _showAppSnackBar(
    String message, {
    required AppSnackBarType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    final config = _snackConfig(type);
    final isDark = theme.brightness == Brightness.dark;

    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          duration: duration,
          backgroundColor: config.background,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: config.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: config.border),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : colors.primary).withValues(
                    alpha: isDark ? 0.24 : 0.08,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: config.iconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(config.icon, size: 16, color: config.iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: textTheme.bodyMedium?.copyWith(
                      color: config.foreground,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  _SnackConfig _snackConfig(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return _SnackConfig(
          icon: Icons.check_rounded,
          background: colors.primaryContainer,
          border: colors.primary,
          foreground: colors.onPrimaryContainer,
          iconColor: colors.primary,
          iconBackground: colors.surface,
        );
      case AppSnackBarType.info:
        return _SnackConfig(
          icon: Icons.info_outline_rounded,
          background: colors.secondaryContainer,
          border: colors.secondary,
          foreground: colors.onSecondaryContainer,
          iconColor: colors.secondary,
          iconBackground: colors.surface,
        );
      case AppSnackBarType.warning:
        return _SnackConfig(
          icon: Icons.warning_amber_rounded,
          background: const Color(0xFFFFF3E5),
          border: const Color(0xFFF4C58A),
          foreground: const Color(0xFF7A4A13),
          iconColor: const Color(0xFFB5651D),
          iconBackground: const Color(0xFFFFE2BF),
        );
      case AppSnackBarType.error:
        return _SnackConfig(
          icon: Icons.error_outline_rounded,
          background: colors.errorContainer,
          border: colors.error,
          foreground: colors.onErrorContainer,
          iconColor: colors.error,
          iconBackground: colors.surface,
        );
    }
  }
}

class _SnackConfig {
  const _SnackConfig({
    required this.icon,
    required this.background,
    required this.border,
    required this.foreground,
    required this.iconColor,
    required this.iconBackground,
  });

  final IconData icon;
  final Color background;
  final Color border;
  final Color foreground;
  final Color iconColor;
  final Color iconBackground;
}

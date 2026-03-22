import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_gradients.dart';

enum AppButtonType { filled, outlined, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDestructive = false,
    this.icon,
    this.type = AppButtonType.filled,
    this.isFullWidth = true,
    this.useGradient = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDestructive;
  final IconData? icon;
  final AppButtonType type;
  final bool isFullWidth;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveOnPressed = isLoading ? null : onPressed;

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(
                type == AppButtonType.filled
                    ? Colors.white
                    : colorScheme.primary,
              ),
            ),
          )
        : icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          )
        : Text(label);

    final destructiveColor = isDestructive ? colorScheme.error : null;

    Widget button;
    switch (type) {
      case AppButtonType.filled:
        if (useGradient && !isDestructive) {
          // Gradient filled button
          button = _GradientButton(
            onPressed: effectiveOnPressed,
            gradient: AppGradients.primaryFor(
              isDark ? Brightness.dark : Brightness.light,
            ),
            borderRadius: 16,
            child: child,
          );
        } else {
          button = FilledButton(
            onPressed: effectiveOnPressed,
            style: FilledButton.styleFrom(backgroundColor: destructiveColor),
            child: child,
          );
        }
      case AppButtonType.outlined:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: destructiveColor,
            side: destructiveColor != null
                ? BorderSide(color: destructiveColor, width: 1.5)
                : null,
          ),
          child: child,
        );
      case AppButtonType.text:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(foregroundColor: destructiveColor),
          child: child,
        );
    }

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.onPressed,
    required this.gradient,
    required this.borderRadius,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Gradient gradient;
  final double borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Center(
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                child: IconTheme(
                  data: const IconThemeData(color: Colors.white, size: 18),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

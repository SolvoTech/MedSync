import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderRadius,
    this.margin,
    this.gradient,
    this.hasShadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? borderRadius;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final bool hasShadow;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = borderRadius ?? 20;
    final cardColor = color ?? colorScheme.surface;

    Widget card;

    if (gradient != null) {
      // Gradient card — use Container for gradient support
      card = Container(
        margin: margin ?? EdgeInsets.zero,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(effectiveRadius),
          boxShadow: hasShadow
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(effectiveRadius),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      );
    } else {
      // Standard card with soft shadow
      card = Container(
        margin: margin ?? EdgeInsets.zero,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(effectiveRadius),
          border: isDark
              ? Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
          boxShadow: hasShadow && !isDark
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F1419).withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF0F1419).withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(effectiveRadius),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      );
    }

    return card;
  }
}

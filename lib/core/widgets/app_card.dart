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
    final effectiveRadius = borderRadius ?? 22;
    final cardColor = color ?? colorScheme.surface;

    Widget card;

    if (gradient != null) {
      // Gradient card — use Container for gradient support
      card = Container(
        margin: margin ?? EdgeInsets.zero,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(effectiveRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.24),
          ),
          boxShadow: hasShadow && !isDark
              ? [
                  BoxShadow(
                    color: const Color(0xFF0B5CAD).withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(effectiveRadius),
          clipBehavior: Clip.antiAlias,
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
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.34 : 0.46,
            ),
            width: 1,
          ),
          boxShadow: hasShadow && !isDark
              ? [
                  BoxShadow(
                    color: const Color(0xFF0B5CAD).withValues(alpha: 0.08),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(effectiveRadius),
          clipBehavior: Clip.antiAlias,
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

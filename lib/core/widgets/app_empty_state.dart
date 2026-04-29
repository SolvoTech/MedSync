import 'package:flutter/material.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.subtitle,
    this.icon,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final String message;
  final String? subtitle;
  final IconData? icon;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 340;
    final iconSize = compact ? 56.0 : 64.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 28,
          vertical: compact ? 24 : 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.inbox_outlined,
                size: compact ? 26 : 30,
                color: colorScheme.primary.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                message,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  subtitle!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.56),
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? 280 : 320),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      minimumSize: const Size(0, 46),
                    ),
                    icon: Icon(actionIcon ?? Icons.add_rounded, size: 18),
                    label: Text(
                      actionLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

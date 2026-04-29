import 'package:flutter/material.dart';

import '../constants/app_strings.dart';

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 340;
    final iconSize = compact ? 64.0 : 80.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 20 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tonal error container for icon
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: compact ? 30 : 36,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message ?? AppStrings.errorGeneral,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  minimumSize: const Size(0, 46),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 18),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        AppStrings.retry,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Compact streak badge for displaying streak count.
class StreakBadge extends StatelessWidget {
  const StreakBadge({
    super.key,
    required this.currentStreak,
    this.compact = false,
  });

  final int currentStreak;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isHot = currentStreak >= 7;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: isHot
              ? const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFE53E3E)],
                )
              : null,
          color: isHot ? null : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isHot
                  ? Icons.local_fire_department_rounded
                  : Icons.auto_graph_rounded,
              size: 14,
              color: isHot ? Colors.white : colorScheme.primary,
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 42),
              child: Text(
                '$currentStreak',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isHot ? Colors.white : colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: isHot
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6B35), Color(0xFFE53E3E)],
              )
            : null,
        color: isHot ? null : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isHot
            ? [
                BoxShadow(
                  color: AppColors.streakAccent.withValues(alpha: 0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHot
                ? Icons.local_fire_department_rounded
                : Icons.auto_graph_rounded,
            size: 20,
            color: isHot ? Colors.white : colorScheme.primary,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 92),
            child: Text(
              '$currentStreak hari',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isHot ? Colors.white : colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

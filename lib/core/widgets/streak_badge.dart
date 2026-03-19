import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Compact streak badge for displaying streak count with emoji and gradient.
class StreakBadge extends StatelessWidget {
  const StreakBadge({
    super.key,
    required this.currentStreak,
    this.compact = false,
  });

  final int currentStreak;
  final bool compact;

  String get _emoji => currentStreak >= 7 ? '🔥' : '💪';

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
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '$currentStreak',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isHot ? Colors.white : colorScheme.primary,
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: isHot
            ? [
                BoxShadow(
                  color: AppColors.streakAccent.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text(
            '$currentStreak hari',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isHot ? Colors.white : colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

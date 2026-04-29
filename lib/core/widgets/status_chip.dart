import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

/// Status chip for task status display with theme-aware tonal colors.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status; // 'done', 'skipped', 'missed', 'pending'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (label, color, icon) = switch (status) {
      'done' => (
        AppStrings.tr('Done', 'Selesai'),
        AppColors.success,
        Icons.check_circle_outline,
      ),
      'skipped' => (
        AppStrings.tr('Skipped', 'Dilewati'),
        AppColors.warning,
        Icons.skip_next_outlined,
      ),
      'missed' => (
        AppStrings.tr('Missed', 'Terlewat'),
        AppColors.error,
        Icons.cancel_outlined,
      ),
      _ => (
        AppStrings.tr('Pending', 'Menunggu'),
        isDark ? const Color(0xFF8899A6) : const Color(0xFF718096),
        Icons.schedule_outlined,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      constraints: const BoxConstraints(maxWidth: 132),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

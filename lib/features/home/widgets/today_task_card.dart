import 'package:flutter/material.dart';

import '../../../core/widgets/status_chip.dart';
import '../../../domain/models/task_log.dart';

class TodayTaskCard extends StatelessWidget {
  const TodayTaskCard({
    super.key,
    required this.task,
    required this.onDone,
    required this.onSkip,
  });

  final TaskLog task;
  final VoidCallback onDone;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == 'done' || task.status == 'skipped';
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _colorForTaskType(task.taskType);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F1419).withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon in tonal circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconForTaskType(task.taskType),
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _labelForTaskType(task.taskType),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${task.scheduledAt.hour.toString().padLeft(2, '0')}:${task.scheduledAt.minute.toString().padLeft(2, '0')}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(status: task.status),
              ],
            ),
            if (!isCompleted) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSkip,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Lewati'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onDone,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Selesai'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForTaskType(String taskType) {
    switch (taskType) {
      case 'medicine':
        return Icons.medication_rounded;
      case 'measurement':
        return Icons.monitor_heart_rounded;
      case 'physical_activity':
        return Icons.directions_walk_rounded;
      default:
        return Icons.checklist_rounded;
    }
  }

  Color _colorForTaskType(String taskType) {
    switch (taskType) {
      case 'medicine':
        return const Color(0xFF0077B6);
      case 'measurement':
        return const Color(0xFF38A169);
      case 'physical_activity':
        return const Color(0xFFED8936);
      default:
        return const Color(0xFF4299E1);
    }
  }

  String _labelForTaskType(String taskType) {
    switch (taskType) {
      case 'medicine':
        return 'Obat';
      case 'measurement':
        return 'Pengukuran';
      case 'physical_activity':
        return 'Aktivitas Fisik';
      default:
        return taskType;
    }
  }
}

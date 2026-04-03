import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_card.dart';
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
    final isSkipped = task.status == 'skipped';
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accentColor = _colorForTaskType(task.taskType);
    final timeLabel = _timeLabel();

    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _iconForTaskType(task.taskType),
                        color: accentColor,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _labelForTaskType(task.taskType),
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _supportingText(),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.65,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.68,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeLabel,
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    StatusChip(status: task.status),
                    if (isCompleted) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _completedText(),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.58,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (!isCompleted) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onSkip,
                          icon: const Icon(Icons.skip_next_rounded, size: 18),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 42),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          label: Text(AppStrings.skip),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onDone,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 42),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          label: Text(AppStrings.done),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSkipped
                              ? Icons.pause_circle_outline_rounded
                              : Icons.verified_rounded,
                          size: 16,
                          color: accentColor,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            isSkipped
                                ? AppStrings.tr(
                                    'This task was skipped for today.',
                                    'Tugas ini dilewati untuk hari ini.',
                                  )
                                : AppStrings.tr(
                                    'Great, this task is done for today.',
                                    'Bagus, tugas ini sudah selesai hari ini.',
                                  ),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.72,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeLabel() {
    return '${task.scheduledAt.hour.toString().padLeft(2, '0')}:${task.scheduledAt.minute.toString().padLeft(2, '0')}';
  }

  String _supportingText() {
    switch (task.taskType) {
      case 'medicine':
        return AppStrings.tr(
          'Take your medication at this time.',
          'Minum obat sesuai waktu ini.',
        );
      case 'measurement':
        return AppStrings.tr(
          'Record your health measurement.',
          'Catat hasil pengukuran kesehatan.',
        );
      case 'physical_activity':
        return AppStrings.tr(
          'Do your planned physical activity.',
          'Lakukan aktivitas fisik sesuai jadwal.',
        );
      default:
        return AppStrings.tr(
          'Scheduled task reminder.',
          'Pengingat tugas terjadwal.',
        );
    }
  }

  String _completedText() {
    switch (task.status) {
      case 'done':
        return AppStrings.tr('Marked complete', 'Sudah ditandai selesai');
      case 'skipped':
        return AppStrings.tr('Skipped for today', 'Dilewati untuk hari ini');
      case 'missed':
        return AppStrings.tr('Missed schedule', 'Jadwal terlewat');
      default:
        return AppStrings.tr('Waiting action', 'Menunggu aksi');
    }
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
        return AppStrings.tr('Medicine', 'Obat');
      case 'measurement':
        return AppStrings.tr('Measurement', 'Pengukuran');
      case 'physical_activity':
        return AppStrings.tr('Physical Activity', 'Aktivitas Fisik');
      default:
        return taskType;
    }
  }
}

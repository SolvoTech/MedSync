import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
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
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;
    final tight = width < 360;
    final isCompleted = task.status == 'done' || task.status == 'skipped';
    final isSkipped = task.status == 'skipped';
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accentColor = _colorForTaskType(task.taskType);
    final timeLabel = _timeLabel();
    final radius = compact ? 20.0 : 24.0;

    Widget buildTimeChip() {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 9,
          vertical: compact ? 4 : 5,
        ),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: compact ? 13 : 14,
              color: accentColor,
            ),
            const SizedBox(width: 4),
            Text(
              timeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: radius,
      color: colorScheme.surface,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 12 : 16,
                compact ? 12 : 16,
                compact ? 12 : 16,
                compact ? 12 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: compact ? 36 : 40,
                        height: compact ? 36 : 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withValues(alpha: 0.20),
                              accentColor.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            compact ? 14 : 16,
                          ),
                        ),
                        child: Icon(
                          _iconForTaskType(task.taskType),
                          color: accentColor,
                          size: compact ? 18 : 20,
                        ),
                      ),
                      SizedBox(width: compact ? 9 : 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _labelForTaskType(task.taskType),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                              ),
                            ),
                            SizedBox(height: compact ? 2 : 3),
                            Text(
                              _supportingText(),
                              maxLines: tight ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
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
                      if (!tight) ...[
                        SizedBox(width: compact ? 6 : 8),
                        buildTimeChip(),
                      ],
                    ],
                  ),
                  if (tight) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: buildTimeChip(),
                    ),
                  ],
                  if (!isCompleted) ...[
                    SizedBox(height: compact ? 10 : 12),
                    StatusChip(status: task.status),
                    SizedBox(height: compact ? 12 : 14),
                    Row(
                      children: [
                        Expanded(
                          child: tight
                              ? OutlinedButton(
                                  onPressed: onSkip,
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                  child: Text(
                                    AppStrings.skip,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : OutlinedButton.icon(
                                  onPressed: onSkip,
                                  icon: Icon(
                                    Icons.skip_next_rounded,
                                    size: compact ? 16 : 18,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                  label: Text(
                                    AppStrings.skip,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                        ),
                        SizedBox(width: compact ? 8 : 9),
                        Expanded(
                          child: tight
                              ? FilledButton(
                                  onPressed: onDone,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 44),
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                  child: Text(
                                    AppStrings.done,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : FilledButton.icon(
                                  onPressed: onDone,
                                  icon: Icon(
                                    Icons.check_rounded,
                                    size: compact ? 16 : 18,
                                  ),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 44),
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                  label: Text(
                                    AppStrings.done,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ] else
                    Padding(
                      padding: EdgeInsets.only(top: compact ? 12 : 14),
                      child: _CompletedTaskState(
                        task: task,
                        isSkipped: isSkipped,
                        compact: compact,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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

class _CompletedTaskState extends StatelessWidget {
  const _CompletedTaskState({
    required this.task,
    required this.isSkipped,
    required this.compact,
  });

  final TaskLog task;
  final bool isSkipped;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tone = isSkipped ? AppColors.warning : AppColors.success;
    final hasProof = (task.completionProofPhotoPath ?? '').trim().isNotEmpty;
    final title = isSkipped
        ? AppStrings.tr('Skipped', 'Dilewati')
        : AppStrings.tr('Done', 'Selesai');
    final subtitle = isSkipped
        ? AppStrings.tr(
            'This task was skipped today.',
            'Tugas ini dilewati hari ini.',
          )
        : hasProof
        ? AppStrings.tr('Photo proof saved.', 'Bukti foto tersimpan.')
        : AppStrings.tr('Marked complete.', 'Sudah ditandai selesai.');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(color: tone.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 34 : 38,
            height: compact ? 34 : 38,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSkipped
                  ? Icons.pause_circle_outline_rounded
                  : Icons.check_circle_rounded,
              color: tone,
              size: compact ? 18 : 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    color: tone,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.66),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

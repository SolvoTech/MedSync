import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../domain/models/medicine_schedule.dart';

class MedicineScheduleBundleCard extends StatelessWidget {
  const MedicineScheduleBundleCard({
    required this.bundle,
    required this.onEdit,
    required this.onDelete,
    this.isReadOnly = false,
    super.key,
  });

  final MedicineScheduleBundle bundle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final schedule = bundle.schedule;
    final slots = bundle.slots;
    final colorScheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 340;
    final locale = AppStrings.languageCode == 'id' ? 'id_ID' : 'en_US';
    final startDateLabel = DateFormat(
      'dd MMM yyyy',
      locale,
    ).format(schedule.startDate);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isReadOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              color: Colors.orange.withValues(alpha: 0.15),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: Colors.orange.shade800,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppStrings.tr(
                        'Inactive mode: schedule is view-only',
                        'Mode nonaktif: jadwal hanya bisa dilihat',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.all(compact ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.schedule_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        schedule.scheduleName ??
                            AppStrings.tr('Daily Schedule', 'Jadwal Harian'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (!isReadOnly)
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.more_vert,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit();
                          }
                          if (value == 'delete') {
                            onDelete();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  AppStrings.tr('Edit Schedule', 'Edit Jadwal'),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppStrings.tr(
                                    'Delete Schedule',
                                    'Hapus Jadwal',
                                  ),
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: slots
                      .map(
                        (slot) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            slot.timeOfDay.substring(0, 5),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                Divider(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  height: 1,
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final startLabel = AppStrings.tr(
                      'Start: $startDateLabel',
                      'Mulai: $startDateLabel',
                    );
                    return Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _ScheduleMetaItem(
                          icon: Icons.calendar_today_outlined,
                          label: startLabel,
                          maxWidth: constraints.maxWidth,
                        ),
                        _ScheduleMetaItem(
                          icon: Icons.repeat_rounded,
                          label: _repeatTypeLabel(schedule.repeatType),
                          maxWidth: constraints.maxWidth,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _repeatTypeLabel(String value) {
    switch (value) {
      case 'weekly':
        return AppStrings.weekly;
      case 'daily':
      default:
        return AppStrings.daily;
    }
  }
}

class _ScheduleMetaItem extends StatelessWidget {
  const _ScheduleMetaItem({
    required this.icon,
    required this.label,
    required this.maxWidth,
  });

  final IconData icon;
  final String label;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

part of 'admin_user_activity_screen.dart';

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final AdminActivityPeriod selected;
  final ValueChanged<AdminActivityPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: Text(AppStrings.adminPeriodToday),
            selected: selected == AdminActivityPeriod.today,
            onSelected: (_) => onChanged(AdminActivityPeriod.today),
          ),
          ChoiceChip(
            label: Text(AppStrings.adminPeriodLast7Days),
            selected: selected == AdminActivityPeriod.last7Days,
            onSelected: (_) => onChanged(AdminActivityPeriod.last7Days),
          ),
          ChoiceChip(
            label: Text(AppStrings.adminPeriodLast30Days),
            selected: selected == AdminActivityPeriod.last30Days,
            onSelected: (_) => onChanged(AdminActivityPeriod.last30Days),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.data});

  final AdminUserActivityData data;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _AdherenceCard(
        title: AppStrings.adminUserActivityOverallAdherence,
        stat: data.overall,
        color: const Color(0xFF2B6CB0),
        icon: Icons.analytics_outlined,
      ),
      _AdherenceCard(
        title: AppStrings.adminUserActivityMedicineAdherence,
        stat: data.medicine,
        color: const Color(0xFF0077B6),
        icon: Icons.medication_rounded,
      ),
      _AdherenceCard(
        title: AppStrings.adminUserActivityMeasurementAdherence,
        stat: data.measurement,
        color: const Color(0xFF38A169),
        icon: Icons.monitor_heart_rounded,
      ),
      _AdherenceCard(
        title: AppStrings.adminUserActivityActivityAdherence,
        stat: data.activity,
        color: const Color(0xFFED8936),
        icon: Icons.directions_walk_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 320) {
          return Column(
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                if (index > 0) const SizedBox(height: 10),
                cards[index],
              ],
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 10),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 10),
                Expanded(child: cards[3]),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AdherenceCard extends StatelessWidget {
  const _AdherenceCard({
    required this.title,
    required this.stat,
    required this.color,
    required this.icon,
  });

  final String title;
  final AdminAdherenceStat stat;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final progress = stat.total == 0 ? 0.0 : stat.done / stat.total;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${stat.percent}%',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            AppStrings.adminUserActivityDoneOfTotal(
              done: stat.done,
              total: stat.total,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineSchedulesList extends StatelessWidget {
  const _MedicineSchedulesList({required this.items});

  final List<AdminMedicineScheduleActivity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _InlineEmptyCard(
        message: AppStrings.adminUserActivityNoMedicineSchedule,
      );
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ScheduleCard(
                title: item.scheduleName?.trim().isNotEmpty == true
                    ? item.scheduleName!
                    : item.medicineName,
                subtitle: item.scheduleName?.trim().isNotEmpty == true
                    ? item.medicineName
                    : AppStrings.adminUserActivityMedicineSubtitle,
                timeLabel: item.timeSlots.isEmpty
                    ? '-'
                    : item.timeSlots
                          .map(_formatTimeOfDay)
                          .where((value) => value.isNotEmpty)
                          .join(', '),
                repeatType: item.repeatType,
                isActive: item.isActive,
                stat: item.adherence,
                accentColor: const Color(0xFF0077B6),
                icon: Icons.medication_rounded,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MeasurementSchedulesList extends StatelessWidget {
  const _MeasurementSchedulesList({required this.items});

  final List<AdminMeasurementScheduleActivity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _InlineEmptyCard(
        message: AppStrings.adminUserActivityNoMeasurementSchedule,
      );
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ScheduleCard(
                title: item.displayName,
                subtitle: measurementTypeLabel(item.measurementType),
                timeLabel: _formatTimeOfDay(item.timeOfDay),
                repeatType: item.repeatType,
                isActive: item.isActive,
                stat: item.adherence,
                accentColor: const Color(0xFF38A169),
                icon: Icons.monitor_heart_rounded,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ActivitySchedulesList extends StatelessWidget {
  const _ActivitySchedulesList({required this.items});

  final List<AdminActivityScheduleActivity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _InlineEmptyCard(
        message: AppStrings.adminUserActivityNoActivitySchedule,
      );
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ScheduleCard(
                title: item.displayName,
                subtitle: activityTypeLabel(item.activityType),
                timeLabel: _formatTimeOfDay(item.timeOfDay),
                repeatType: item.repeatType,
                isActive: item.isActive,
                stat: item.adherence,
                accentColor: const Color(0xFFED8936),
                icon: Icons.directions_walk_rounded,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.repeatType,
    required this.isActive,
    required this.stat,
    required this.accentColor,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String timeLabel;
  final String repeatType;
  final bool isActive;
  final AdminAdherenceStat stat;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = stat.total == 0 ? 0.0 : stat.done / stat.total;
    final compact = MediaQuery.sizeOf(context).width < 340;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 32 : 36,
                height: compact ? 32 : 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: accentColor, size: compact ? 18 : 20),
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${stat.percent}%',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(
                icon: Icons.schedule_rounded,
                label: AppStrings.adminUserActivityTimeLabel(timeLabel),
              ),
              _Tag(
                icon: Icons.repeat_rounded,
                label: _repeatTypeLabel(repeatType),
              ),
              _Tag(
                icon: isActive
                    ? Icons.check_circle_outline
                    : Icons.pause_circle_outline,
                label: isActive
                    ? AppStrings.adminUserActivityScheduleActive
                    : AppStrings.adminUserActivityScheduleInactive,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.adminUserActivityDoneOfTotal(
              done: stat.done,
              total: stat.total,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress,
              backgroundColor: accentColor.withValues(alpha: 0.12),
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  String _repeatTypeLabel(String repeatType) {
    switch (repeatType) {
      case 'daily':
        return AppStrings.tr('Daily', 'Harian');
      case 'weekly':
        return AppStrings.tr('Weekly', 'Mingguan');
      case 'interval':
        return AppStrings.tr('Interval', 'Interval');
      default:
        return repeatType;
    }
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 48,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineEmptyCard extends StatelessWidget {
  const _InlineEmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(
            Icons.inbox_outlined,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminUserActivityLoading extends StatelessWidget {
  const _AdminUserActivityLoading();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 340;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 16,
        12,
        compact ? 12 : 16,
        24,
      ),
      children: [
        AppLoadingSkeleton(
          width: double.infinity,
          height: compact ? 84 : 96,
          borderRadius: 12,
        ),
        const SizedBox(height: 12),
        const AppLoadingSkeleton(
          width: double.infinity,
          height: 56,
          borderRadius: 12,
        ),
        const SizedBox(height: 12),
        const AppLoadingSkeleton(
          width: double.infinity,
          height: 56,
          borderRadius: 12,
        ),
        const SizedBox(height: 12),
        AppLoadingSkeleton(
          width: double.infinity,
          height: compact ? 118 : 130,
          borderRadius: 12,
        ),
        const SizedBox(height: 10),
        AppLoadingSkeleton(
          width: double.infinity,
          height: compact ? 118 : 130,
          borderRadius: 12,
        ),
      ],
    );
  }
}

String _formatTimeOfDay(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return value;
  }

  final parts = value.split(':');
  if (parts.length < 2) {
    return value;
  }

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) {
    return value;
  }

  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

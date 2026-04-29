part of 'medicine_tab.dart';

class _MedicineTile extends StatelessWidget {
  const _MedicineTile({
    required this.medicine,
    required this.onTap,
    required this.onLongPress,
  });

  final Medicine medicine;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;
    final tight = width < 360;
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = medicine.isActive ? Colors.green : Colors.orange;
    final radius = compact ? 10.0 : 12.0;

    return GestureDetector(
      onLongPress: onLongPress,
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        borderRadius: radius,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 3, color: statusColor),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 10 : 12,
                  compact ? 10 : 11,
                  compact ? 10 : 12,
                  compact ? 10 : 11,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: compact ? 38 : 42,
                      height: compact ? 38 : 42,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(compact ? 8 : 9),
                      ),
                      child: Icon(
                        Icons.medication_rounded,
                        color: colorScheme.primary,
                        size: compact ? 19 : 21,
                      ),
                    ),
                    SizedBox(width: compact ? 9 : 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: tight ? width * 0.34 : width * 0.42,
                                ),
                                child: Text(
                                  medicine.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: compact ? 7 : 8,
                                  vertical: compact ? 3 : 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  medicine.isActive
                                      ? AppStrings.statusActive
                                      : AppStrings.statusInactive,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: compact ? 5 : 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _MedicineInfoPill(
                                icon: Icons.straighten_rounded,
                                label:
                                    medicine.dosage ?? AppStrings.dosageNotSet,
                              ),
                              _MedicineInfoPill(
                                icon: Icons.inventory_2_outlined,
                                label:
                                    '${AppStrings.stockLabel} ${medicine.stockCurrent} ${medicine.stockUnit}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: compact ? 4 : 6),
                    IconButton(
                      onPressed: onLongPress,
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        padding: EdgeInsets.zero,
                        minimumSize: Size(compact ? 31 : 34, compact ? 31 : 34),
                      ),
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: compact ? 16 : 18,
                      ),
                      tooltip: AppStrings.tr('More options', 'Opsi lainnya'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicineInfoPill extends StatelessWidget {
  const _MedicineInfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;
    final width = MediaQuery.sizeOf(context).width;
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width * 0.7),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 8,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: compact ? 11 : 12,
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
  });

  final String label;
  final IconData icon;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MedicineStatsRow extends StatelessWidget {
  const _MedicineStatsRow({required this.medicine});

  final Medicine medicine;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 340;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: compact ? 12 : 16,
        horizontal: compact ? 6 : 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatColumn(
            context,
            icon: Icons.medication_outlined,
            label: AppStrings.tr('Dosage', 'Dosis'),
            value: medicine.dosage ?? '-',
            colorScheme: colorScheme,
            compact: compact,
          ),
          Container(
            width: 1,
            height: compact ? 28 : 32,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          _buildStatColumn(
            context,
            icon: Icons.inventory_2_outlined,
            label: AppStrings.tr('Stock', 'Stok'),
            value: '${medicine.stockCurrent} ${medicine.stockUnit}',
            colorScheme: colorScheme,
            compact: compact,
          ),
          Container(
            width: 1,
            height: compact ? 28 : 32,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          _buildStatColumn(
            context,
            icon: medicine.isActive
                ? Icons.check_circle_outline
                : Icons.pause_circle_outline,
            label: AppStrings.tr('Status', 'Status'),
            value: medicine.isActive
                ? AppStrings.statusActiveLabel
                : AppStrings.statusInactiveLabel,
            colorScheme: colorScheme,
            valueColor: medicine.isActive ? Colors.green : Colors.orange,
            compact: compact,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
    required bool compact,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 19 : 22, color: colorScheme.primary),
          SizedBox(height: compact ? 4 : 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

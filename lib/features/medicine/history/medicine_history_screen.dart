import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/app_loading_skeleton.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../domain/models/medicine.dart';
import '../../../domain/models/task_log.dart';

enum HistoryPeriod { week, month, all }

final historyPeriodProvider = StateProvider<HistoryPeriod>(
  (ref) => HistoryPeriod.week,
);

final medicineHistoryProvider = FutureProvider.autoDispose
    .family<List<TaskLog>, String>((ref, medicineId) async {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return [];

      final period = ref.watch(historyPeriodProvider);
      final now = DateTime.now();
      late DateTime startDate;

      switch (period) {
        case HistoryPeriod.week:
          startDate = now.subtract(const Duration(days: 7));
        case HistoryPeriod.month:
          startDate = now.subtract(const Duration(days: 30));
        case HistoryPeriod.all:
          startDate = DateTime(2020);
      }

      final scheduleRows = await client
          .from('medicine_schedules')
          .select('id')
          .eq('medicine_id', medicineId)
          .eq('owner_id', user.id);

      final scheduleIds = (scheduleRows as List)
          .map((r) => r['id'] as String)
          .toList();

      if (scheduleIds.isEmpty) return [];

      final rows = await client
          .from('task_logs')
          .select()
          .eq('owner_id', user.id)
          .eq('task_type', 'medicine')
          .inFilter('reference_id', scheduleIds)
          .gte('scheduled_at', startDate.toIso8601String())
          .order('scheduled_at', ascending: false);

      return (rows as List)
          .map((r) => TaskLog.fromMap(r as Map<String, dynamic>))
          .toList();
    });

class MedicineHistoryScreen extends ConsumerWidget {
  const MedicineHistoryScreen({super.key, required this.medicine});

  final Medicine medicine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(historyPeriodProvider);
    final historyState = ref.watch(medicineHistoryProvider(medicine.id));
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 340;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Riwayat ${medicine.name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 12 : 16),
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Row(
              children: [
                CircleAvatar(
                  radius: compact ? 21 : 24,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.medication, color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (medicine.dosage != null)
                        Text(
                          medicine.dosage!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: compact ? 76 : 96),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Stok', style: textTheme.labelSmall),
                      Text(
                        '${medicine.stockCurrent} ${medicine.stockUnit}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: medicine.isStockLow
                              ? colorScheme.error
                              : colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(compact ? 12 : 16, 12, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<HistoryPeriod>(
                segments: const [
                  ButtonSegment(
                    value: HistoryPeriod.week,
                    label: Text(
                      '7 Hari',
                      softWrap: false,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                  ButtonSegment(
                    value: HistoryPeriod.month,
                    label: Text(
                      '30 Hari',
                      softWrap: false,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                  ButtonSegment(
                    value: HistoryPeriod.all,
                    label: Text(
                      'Semua',
                      softWrap: false,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                ],
                selected: {period},
                onSelectionChanged: (selected) {
                  ref.read(historyPeriodProvider.notifier).state =
                      selected.first;
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: historyState.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.history,
                    message: 'Belum ada riwayat',
                    subtitle: 'Riwayat minum obat akan muncul di sini.',
                  );
                }

                final done = logs.where((l) => l.status == 'done').length;
                final total = logs.length;
                final adherence = total > 0 ? (done / total * 100).round() : 0;

                return ListView(
                  padding: EdgeInsets.all(compact ? 12 : 16),
                  children: [
                    AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              label: 'Kepatuhan',
                              value: '$adherence%',
                              color: adherence >= 80
                                  ? Colors.green
                                  : adherence >= 50
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                          ),
                          Expanded(
                            child: _StatItem(
                              label: 'Selesai',
                              value: '$done',
                              color: Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _StatItem(
                              label: 'Total',
                              value: '$total',
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...logs.map(
                      (log) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatDate(log.scheduledAt),
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      Text(
                                        _formatTime(log.scheduledAt),
                                        style: textTheme.titleSmall,
                                      ),
                                    ],
                                  ),
                                  if (log.completedAt != null) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 14,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _formatTime(log.completedAt!),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  if (log.mood != null)
                                    Text(
                                      _moodEmoji(log.mood!),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  if (!compact) ...[
                                    const SizedBox(width: 8),
                                    StatusChip(status: log.status),
                                  ],
                                ],
                              ),
                              if (compact) ...[
                                const SizedBox(height: 8),
                                StatusChip(status: log.status),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () =>
                  const AppListSkeleton(itemCount: 5, itemHeight: 60),
              error: (e, _) => AppErrorWidget(
                message: 'Gagal memuat riwayat. Silakan coba lagi.',
                onRetry: () =>
                    ref.invalidate(medicineHistoryProvider(medicine.id)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${months[dt.month]}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _moodEmoji(String mood) {
    return switch (mood) {
      'good' => '😊',
      'neutral' => '😐',
      'bad' => '😔',
      _ => '',
    };
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

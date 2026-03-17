import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_widget.dart';
import '../../core/widgets/app_loading_skeleton.dart';
import '../../data/remote/supabase_client.dart';
import '../../domain/models/task_log.dart';
import '../../services/pdf_export_service.dart';
import '../home/home_screen.dart';

enum ReportPeriod { daily, weekly, monthly }

final reportPeriodProvider = StateProvider<ReportPeriod>(
  (ref) => ReportPeriod.weekly,
);

final reportDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final reportDataProvider =
    FutureProvider.autoDispose<_ReportData>((ref) async {
  final client = SupabaseClientRef.maybeClient;
  if (client == null) throw Exception('Supabase belum diinisialisasi.');
  final user = client.auth.currentUser;
  if (user == null) throw Exception('Login terlebih dahulu.');

  final period = ref.watch(reportPeriodProvider);
  final refDate = ref.watch(reportDateProvider);
  final now = refDate;

  late DateTime startDate;
  switch (period) {
    case ReportPeriod.daily:
      startDate = DateTime(now.year, now.month, now.day);
    case ReportPeriod.weekly:
      startDate = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
    case ReportPeriod.monthly:
      startDate = DateTime(now.year, now.month, 1);
  }

  final endDate = switch (period) {
    ReportPeriod.daily => startDate.add(const Duration(days: 1)),
    ReportPeriod.weekly => startDate.add(const Duration(days: 7)),
    ReportPeriod.monthly =>
      DateTime(startDate.year, startDate.month + 1, 1),
  };

  final rows = await client
      .from('task_logs')
      .select()
      .eq('owner_id', user.id)
      .gte('scheduled_at', startDate.toIso8601String())
      .lt('scheduled_at', endDate.toIso8601String())
      .order('scheduled_at');

  final tasks = (rows as List<dynamic>)
      .map((r) => TaskLog.fromMap(r as Map<String, dynamic>))
      .toList();

  final total = tasks.length;
  final done = tasks.where((t) => t.status == 'done').length;
  final skipped = tasks.where((t) => t.status == 'skipped').length;
  final missed = tasks.where((t) => t.status == 'missed').length;
  final pending = tasks.where((t) => t.status == 'pending').length;
  final adherencePercent = total > 0 ? (done / total * 100).round() : 0;

  // Group by type
  final medicineTasks =
      tasks.where((t) => t.taskType == 'medicine').toList();
  final measurementTasks =
      tasks.where((t) => t.taskType == 'measurement').toList();
  final activityTasks =
      tasks.where((t) => t.taskType == 'physical_activity').toList();

  return _ReportData(
    total: total,
    done: done,
    skipped: skipped,
    missed: missed,
    pending: pending,
    adherencePercent: adherencePercent,
    medicineCount: medicineTasks.length,
    medicineDone:
        medicineTasks.where((t) => t.status == 'done').length,
    measurementCount: measurementTasks.length,
    measurementDone:
        measurementTasks.where((t) => t.status == 'done').length,
    activityCount: activityTasks.length,
    activityDone:
        activityTasks.where((t) => t.status == 'done').length,
    startDate: startDate,
    endDate: endDate,
    tasks: tasks,
  );
});

class _ReportData {
  const _ReportData({
    required this.total,
    required this.done,
    required this.skipped,
    required this.missed,
    required this.pending,
    required this.adherencePercent,
    required this.medicineCount,
    required this.medicineDone,
    required this.measurementCount,
    required this.measurementDone,
    required this.activityCount,
    required this.activityDone,
    required this.startDate,
    required this.endDate,
    required this.tasks,
  });

  final int total, done, skipped, missed, pending, adherencePercent;
  final int medicineCount, medicineDone;
  final int measurementCount, measurementDone;
  final int activityCount, activityDone;
  final DateTime startDate, endDate;
  final List<TaskLog> tasks;
}

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportPeriodProvider);
    final reportState = ref.watch(reportDataProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final streakState = ref.watch(streakProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reportTitle),
        actions: [
          reportState.maybeWhen(
            data: (data) {
              if (data.total == 0) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Simpan sebagai PDF',
                onPressed: () async {
                  final client = SupabaseClientRef.maybeClient;
                  final user = client?.auth.currentUser;
                  final userName = user?.userMetadata?['full_name'] as String? ?? 'Pengguna';
                  final currentStreak = streakState.valueOrNull?.currentStreak ?? 0;

                  try {
                    await PdfExportService.exportReport(
                      context: context,
                      userName: userName,
                      startDate: data.startDate,
                      endDate: data.endDate,
                      currentStreak: currentStreak,
                      logs: data.tasks,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal mengekspor PDF: $e')),
                      );
                    }
                  }
                },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Period filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<ReportPeriod>(
              segments: const [
                ButtonSegment(value: ReportPeriod.daily, label: Text('Harian')),
                ButtonSegment(
                    value: ReportPeriod.weekly, label: Text('Mingguan')),
                ButtonSegment(
                    value: ReportPeriod.monthly, label: Text('Bulanan')),
              ],
              selected: {period},
              onSelectionChanged: (selected) {
                ref.read(reportPeriodProvider.notifier).state =
                    selected.first;
              },
            ),
          ),
          const SizedBox(height: 12),

          // Report content
          Expanded(
            child: reportState.when(
              data: (data) {
                if (data.total == 0) {
                  return const AppEmptyState(
                    message: 'Belum ada data untuk periode ini',
                    icon: Icons.bar_chart_outlined,
                    subtitle:
                        'Mulai catat tugas kesehatan\nuntuk melihat laporan Anda.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(reportDataProvider),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Adherence overview
                      AppCard(
                        child: Column(
                          children: [
                            Text('Kepatuhan Keseluruhan',
                                style: textTheme.labelLarge),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CircularProgressIndicator(
                                    value: data.adherencePercent / 100,
                                    strokeWidth: 10,
                                    backgroundColor:
                                        colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation(
                                        colorScheme.primary),
                                  ),
                                  Center(
                                    child: Text(
                                      '${data.adherencePercent}%',
                                      style: textTheme.headlineMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatPill(
                                    label: 'Selesai',
                                    value: '${data.done}',
                                    color: Colors.green),
                                _StatPill(
                                    label: 'Lewati',
                                    value: '${data.skipped}',
                                    color: Colors.orange),
                                _StatPill(
                                    label: 'Terlewat',
                                    value: '${data.missed}',
                                    color: Colors.red),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Category breakdown
                      _CategoryCard(
                        icon: Icons.medication,
                        label: 'Obat',
                        done: data.medicineDone,
                        total: data.medicineCount,
                        color: const Color(0xFF0077B6),
                      ),
                      const SizedBox(height: 8),
                      _CategoryCard(
                        icon: Icons.monitor_heart,
                        label: 'Pengukuran',
                        done: data.measurementDone,
                        total: data.measurementCount,
                        color: const Color(0xFF16A34A),
                      ),
                      const SizedBox(height: 8),
                      _CategoryCard(
                        icon: Icons.directions_run,
                        label: 'Aktivitas Fisik',
                        done: data.activityDone,
                        total: data.activityCount,
                        color: const Color(0xFFEA580C),
                      ),
                    ],
                  ),
                );
              },
              loading: () => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: List.generate(
                    3,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: AppLoadingSkeleton(
                        width: double.infinity,
                        height: 80,
                        borderRadius: 16,
                      ),
                    ),
                  ),
                ),
              ),
              error: (e, _) => AppErrorWidget(
                message: 'Gagal memuat laporan',
                onRetry: () => ref.invalidate(reportDataProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.done,
    required this.total,
    required this.color,
  });
  final IconData icon;
  final String label;
  final int done, total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? done / total : 0.0;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.titleSmall),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 8,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$done/$total',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

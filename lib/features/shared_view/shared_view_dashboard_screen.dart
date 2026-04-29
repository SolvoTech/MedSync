import 'package:flutter/material.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_chip.dart';

/// Read-only dashboard showing care person status via shared token.
class SharedViewDashboardScreen extends StatelessWidget {
  const SharedViewDashboardScreen({
    super.key,
    required this.token,
    required this.data,
  });

  final String token;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final carePerson = data['care_person'] as Map<String, dynamic>? ?? {};
    final tasks = data['today_tasks'] as List? ?? [];
    final progress = data['progress'] as Map<String, dynamic>? ?? {};
    final streak = data['streak'] as int? ?? 0;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;
    final xxs = width < 340;

    final done = progress['done'] as int? ?? 0;
    final total = progress['total'] as int? ?? 0;
    final percent = progress['percent'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          carePerson['display_name'] ?? 'Status Kesehatan',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: MaterialLocalizations.of(
              context,
            ).refreshIndicatorSemanticLabel,
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Could re-invoke the edge function here
              context.showInfoSnackBar('Data sudah terbaru.');
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(compact ? 12 : 16),
        children: [
          // Care person header
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: xxs ? 23 : 28,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    _initials(carePerson['display_name'] as String?),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        carePerson['display_name'] ?? 'Pengguna',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (carePerson['relationship'] != null)
                        Text(
                          carePerson['relationship'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                ),
                if (streak > 0)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: xxs ? 54 : 70),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: xxs ? 8 : 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!xxs) ...[
                            const Text('🔥', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              '$streak',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelMedium?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Progress ring card
          AppCard(
            child: Column(
              children: [
                SizedBox(
                  width: xxs ? 86 : 100,
                  height: xxs ? 86 : 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: xxs ? 86 : 100,
                        height: xxs ? 86 : 100,
                        child: CircularProgressIndicator(
                          value: total > 0 ? done / total : 0,
                          strokeWidth: xxs ? 8 : 10,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(
                            percent >= 80
                                ? Colors.green
                                : percent >= 50
                                ? Colors.orange
                                : Colors.red,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$percent%',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$done/$total',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Progres Hari Ini',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tasks list
          Text(
            'TUGAS HARI INI',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),

          if (tasks.isEmpty)
            AppCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Tidak ada tugas hari ini',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            )
          else
            ...tasks.map((task) {
              final t = task as Map<String, dynamic>;
              final scheduledAt = DateTime.tryParse(
                t['scheduled_at'] as String? ?? '',
              );
              final time = scheduledAt != null
                  ? '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}'
                  : '--:--';
              final type = t['task_type'] as String? ?? '';
              final status = t['status'] as String? ?? 'pending';

              final icon = switch (type) {
                'medicine' => Icons.medication,
                'measurement' => Icons.monitor_heart,
                'physical_activity' => Icons.directions_run,
                _ => Icons.task_alt,
              };

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 20, color: colorScheme.primary),
                          const SizedBox(width: 10),
                          Text(
                            time,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              type.replaceAll('_', ' ').toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ),
                          if (!xxs) StatusChip(status: status),
                        ],
                      ),
                      if (xxs) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StatusChip(status: status),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          // Watermark
          Center(
            child: Text(
              'Dibagikan via MedSync',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

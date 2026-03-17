import 'package:flutter/material.dart';

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconForTaskType(task.taskType),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.taskType,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  '${task.scheduledAt.hour.toString().padLeft(2, '0')}:${task.scheduledAt.minute.toString().padLeft(2, '0')}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Status: ${_statusLabel(task.status)}'),
            if (!isCompleted) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSkip,
                      child: const Text('Lewati'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: onDone,
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

  String _statusLabel(String status) {
    switch (status) {
      case 'done':
        return 'Selesai';
      case 'skipped':
        return 'Dilewati';
      case 'missed':
        return 'Terlewat';
      default:
        return 'Menunggu';
    }
  }
}

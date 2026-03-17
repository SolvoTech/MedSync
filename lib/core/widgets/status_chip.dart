import 'package:flutter/material.dart';

/// Status chip for task status display.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status; // 'done', 'skipped', 'missed', 'pending'

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'done' => ('Selesai', Colors.green, Icons.check_circle_outline),
      'skipped' => ('Dilewati', Colors.orange, Icons.skip_next_outlined),
      'missed' => ('Terlewat', Colors.red, Icons.cancel_outlined),
      _ => ('Menunggu', Colors.grey, Icons.schedule_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

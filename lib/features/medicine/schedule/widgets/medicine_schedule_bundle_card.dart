import 'package:flutter/material.dart';

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schedule.scheduleName ?? 'Jadwal Harian',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (!isReadOnly)
              Align(
                alignment: Alignment.centerRight,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    }
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit Jadwal')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus Jadwal')),
                  ],
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'Mode nonaktif: jadwal hanya bisa dilihat',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Mulai: ${schedule.startDate.day.toString().padLeft(2, '0')}/${schedule.startDate.month.toString().padLeft(2, '0')}/${schedule.startDate.year}',
            ),
            const SizedBox(height: 2),
            Text('Ulang: ${_repeatTypeLabel(schedule.repeatType)}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots
                  .map(
                    (slot) => Chip(label: Text(slot.timeOfDay.substring(0, 5))),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _repeatTypeLabel(String value) {
    switch (value) {
      case 'weekly':
        return 'Mingguan';
      case 'daily':
      default:
        return 'Harian';
    }
  }
}

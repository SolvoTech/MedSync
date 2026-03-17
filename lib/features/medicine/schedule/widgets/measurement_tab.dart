import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/type_labels.dart';
import '../../../../domain/models/measurement_reminder.dart';
import '../../../measurement/measurement_controller.dart';
import 'reminder_common.dart';
import 'schedule_form_options.dart';

class MeasurementTab extends ConsumerWidget {
  const MeasurementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(measurementControllerProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(measurementControllerProvider.notifier).refresh(),
        child: state.when(
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Belum ada pengingat pengukuran.')),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ReminderListTile(
                  icon: Icons.monitor_heart_rounded,
                  title:
                      item.customName ??
                      measurementTypeLabel(item.measurementType),
                  timeOfDay: item.timeOfDay,
                  onTap: () =>
                      _openMeasurementEditor(context, ref, existing: item),
                  onActionSelected: (value) =>
                      _handleMeasurementAction(context, ref, item, value),
                );
              },
            );
          },
          loading: () => ListView(
            children: const [
              SizedBox(height: 180),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(child: Text('Gagal memuat pengukuran: $error')),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMeasurementEditor(context, ref, existing: null),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Pengukuran'),
      ),
    );
  }

  Future<void> _handleMeasurementAction(
    BuildContext context,
    WidgetRef ref,
    MeasurementReminder item,
    String action,
  ) async {
    await handleReminderAction(
      context: context,
      action: action,
      onEdit: () => _openMeasurementEditor(context, ref, existing: item),
      onDeactivate: () => ref
          .read(measurementControllerProvider.notifier)
          .deactivateReminder(item.id),
      onDelete: () => ref
          .read(measurementControllerProvider.notifier)
          .deleteReminder(item.id),
      deactivatedMessage: 'Reminder pengukuran dinonaktifkan.',
      deletedMessage: 'Reminder pengukuran dihapus.',
      deleteDialogContent:
          'Reminder pengukuran akan dihapus permanen dan notifikasinya dibatalkan.',
    );
  }

  Future<void> _openMeasurementEditor(
    BuildContext context,
    WidgetRef ref, {
    MeasurementReminder? existing,
  }) async {
    final controller = ref.read(measurementControllerProvider.notifier);
    await showReminderEditorSheet(
      context: context,
      availableTypes: measurementTypes,
      typeLabelBuilder: measurementTypeLabel,
      typeFieldLabel: 'Tipe Pengukuran',
      timeFieldLabel: 'Waktu Pengukuran',
      initialType: existing?.measurementType ?? measurementTypes.first,
      initialCustomName: existing?.customName,
      initialTimeOfDay: existing?.timeOfDay ?? '08:00:00',
      initialDate: existing?.startDate ?? DateTime.now(),
      isEditing: existing != null,
      createSuccessMessage: 'Reminder pengukuran disimpan.',
      updateSuccessMessage: 'Reminder pengukuran diperbarui.',
      onSubmit:
          ({
            required selectedType,
            customName,
            required timeOfDay,
            required startDate,
          }) async {
            if (existing == null) {
              await controller.addReminder(
                measurementType: selectedType,
                customName: customName,
                timeOfDay: timeOfDay,
                startDate: startDate,
              );
            } else {
              await controller.updateReminder(
                reminderId: existing.id,
                measurementType: selectedType,
                customName: customName,
                timeOfDay: timeOfDay,
                startDate: startDate,
                unit: existing.unit,
                targetValue: existing.targetValue,
              );
            }
          },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/type_labels.dart';
import '../../../../domain/models/physical_activity_reminder.dart';
import '../../../physical_activity/activity_controller.dart';
import 'reminder_common.dart';
import 'schedule_form_options.dart';

class ActivityTab extends ConsumerWidget {
  const ActivityTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityControllerProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(activityControllerProvider.notifier).refresh(),
        child: state.when(
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Belum ada pengingat aktivitas.')),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ReminderListTile(
                  icon: Icons.directions_walk_rounded,
                  title:
                      item.customName ?? activityTypeLabel(item.activityType),
                  timeOfDay: item.timeOfDay,
                  onTap: () =>
                      _openActivityEditor(context, ref, existing: item),
                  onActionSelected: (value) =>
                      _handleActivityAction(context, ref, item, value),
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
              Center(child: Text('Gagal memuat aktivitas: $error')),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openActivityEditor(context, ref, existing: null),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Aktivitas'),
      ),
    );
  }

  Future<void> _handleActivityAction(
    BuildContext context,
    WidgetRef ref,
    PhysicalActivityReminder item,
    String action,
  ) async {
    await handleReminderAction(
      context: context,
      action: action,
      onEdit: () => _openActivityEditor(context, ref, existing: item),
      onDeactivate: () => ref
          .read(activityControllerProvider.notifier)
          .deactivateReminder(item.id),
      onDelete: () =>
          ref.read(activityControllerProvider.notifier).deleteReminder(item.id),
      deactivatedMessage: 'Reminder aktivitas dinonaktifkan.',
      deletedMessage: 'Reminder aktivitas dihapus.',
      deleteDialogContent:
          'Reminder aktivitas akan dihapus permanen dan notifikasinya dibatalkan.',
    );
  }

  Future<void> _openActivityEditor(
    BuildContext context,
    WidgetRef ref, {
    PhysicalActivityReminder? existing,
  }) async {
    final controller = ref.read(activityControllerProvider.notifier);
    await showReminderEditorSheet(
      context: context,
      availableTypes: activityTypes,
      typeLabelBuilder: activityTypeLabel,
      typeFieldLabel: 'Tipe Aktivitas',
      timeFieldLabel: 'Waktu Aktivitas',
      initialType: existing?.activityType ?? activityTypes.first,
      initialCustomName: existing?.customName,
      initialTimeOfDay: existing?.timeOfDay ?? '08:00:00',
      initialDate: existing?.startDate ?? DateTime.now(),
      isEditing: existing != null,
      createSuccessMessage: 'Reminder aktivitas disimpan.',
      updateSuccessMessage: 'Reminder aktivitas diperbarui.',
      onSubmit:
          ({
            required selectedType,
            customName,
            required timeOfDay,
            required startDate,
          }) async {
            if (existing == null) {
              await controller.addReminder(
                activityType: selectedType,
                customName: customName,
                timeOfDay: timeOfDay,
                startDate: startDate,
              );
            } else {
              await controller.updateReminder(
                reminderId: existing.id,
                activityType: selectedType,
                customName: customName,
                timeOfDay: timeOfDay,
                startDate: startDate,
                targetUnit: existing.targetUnit,
                targetValue: existing.targetValue,
              );
            }
          },
    );
  }
}

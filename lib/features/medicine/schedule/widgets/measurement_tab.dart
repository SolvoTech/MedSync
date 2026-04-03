import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/constants/type_labels.dart';
import '../../../../data/remote/datasources/task_log_remote_datasource.dart';
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
                children: [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      AppStrings.tr(
                        'No measurement reminders yet.',
                        'Belum ada pengingat pengukuran.',
                      ),
                    ),
                  ),
                ],
              );
            }

            final tiles = <Widget>[
              ReminderSectionHeader(
                label: AppStrings.tr(
                  'Measurement Reminders',
                  'Reminder Pengukuran',
                ),
                icon: Icons.monitor_heart_rounded,
                color: const Color(0xFF2F855A),
                count: items.length,
              ),
              const SizedBox(height: 10),
            ];

            for (var i = 0; i < items.length; i++) {
              final item = items[i];
              tiles.add(
                ReminderListTile(
                  icon: Icons.monitor_heart_rounded,
                  accentColor: const Color(0xFF2F855A),
                  title:
                      item.customName ??
                      measurementTypeLabel(item.measurementType),
                  timeOfDay: item.timeOfDay,
                  showMarkDoneAction: true,
                  onTap: () =>
                      _openMeasurementEditor(context, ref, existing: item),
                  onActionSelected: (value) =>
                      _handleMeasurementAction(context, ref, item, value),
                ),
              );
              if (i != items.length - 1) {
                tiles.add(const SizedBox(height: 10));
              }
            }

            return ListView(
              padding: scheduleTabListPadding(context),
              children: tiles,
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
              Center(
                child: Text(
                  toUserErrorMessage(
                    error,
                    fallback: AppStrings.tr(
                      'Failed to load measurements. Please try again.',
                      'Gagal memuat pengukuran. Silakan coba lagi.',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: scheduleTabFabPadding(context),
        child: FloatingActionButton.extended(
          onPressed: () => _openMeasurementEditor(context, ref, existing: null),
          icon: const Icon(Icons.add),
          label: Text(AppStrings.addMeasurement),
        ),
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
      onMarkDone: () => TaskLogRemoteDataSource().markReminderDoneByReference(
        taskType: 'measurement',
        referenceId: item.id,
        timeOfDay: item.timeOfDay,
      ),
      doneMessage: AppStrings.tr(
        'Measurement marked as done.',
        'Pengukuran ditandai selesai.',
      ),
      onDeactivate: () => ref
          .read(measurementControllerProvider.notifier)
          .deactivateReminder(item.id),
      onDelete: () => ref
          .read(measurementControllerProvider.notifier)
          .deleteReminder(item.id),
      deactivatedMessage: AppStrings.tr(
        'Measurement reminder disabled.',
        'Reminder pengukuran dinonaktifkan.',
      ),
      deactivateDialogContent: AppStrings.tr(
        'Measurement reminder will be disabled. Schedule remains saved, but notifications will pause until reactivated.',
        'Reminder pengukuran akan dinonaktifkan. Jadwal tetap tersimpan, tetapi notifikasinya dihentikan sampai diaktifkan lagi.',
      ),
      deactivateDontAskAgainKey: 'confirm_skip_deactivate_measurement_reminder',
      deletedMessage: AppStrings.tr(
        'Measurement reminder deleted.',
        'Reminder pengukuran dihapus.',
      ),
      deleteDialogContent: AppStrings.tr(
        'Measurement reminder will be permanently deleted and notifications canceled.',
        'Reminder pengukuran akan dihapus permanen dan notifikasinya dibatalkan.',
      ),
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
      typeFieldLabel: AppStrings.measurementType,
      timeFieldLabel: AppStrings.tr('Measurement Time', 'Waktu Pengukuran'),
      initialType: existing?.measurementType ?? measurementTypes.first,
      initialCustomName: existing?.customName,
      initialTimeOfDay: existing?.timeOfDay ?? '08:00:00',
      initialDate: existing?.startDate ?? DateTime.now(),
      isEditing: existing != null,
      createSuccessMessage: AppStrings.tr(
        'Measurement reminder saved.',
        'Reminder pengukuran disimpan.',
      ),
      updateSuccessMessage: AppStrings.tr(
        'Measurement reminder updated.',
        'Reminder pengukuran diperbarui.',
      ),
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

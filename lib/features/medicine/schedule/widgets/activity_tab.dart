import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/constants/type_labels.dart';
import '../../../../data/remote/datasources/task_log_remote_datasource.dart';
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
                children: [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      AppStrings.tr(
                        'No activity reminders yet.',
                        'Belum ada pengingat aktivitas.',
                      ),
                    ),
                  ),
                ],
              );
            }

            final tiles = <Widget>[
              ReminderSectionHeader(
                label: AppStrings.tr(
                  'Activity Reminders',
                  'Reminder Aktivitas',
                ),
                icon: Icons.directions_walk_rounded,
                color: const Color(0xFFED8936),
                count: items.length,
              ),
              const SizedBox(height: 10),
            ];

            for (var i = 0; i < items.length; i++) {
              final item = items[i];
              tiles.add(
                ReminderListTile(
                  icon: Icons.directions_walk_rounded,
                  accentColor: const Color(0xFFED8936),
                  title:
                      item.customName ?? activityTypeLabel(item.activityType),
                  timeOfDay: item.timeOfDay,
                  showMarkDoneAction: true,
                  onTap: () =>
                      _openActivityEditor(context, ref, existing: item),
                  onActionSelected: (value) =>
                      _handleActivityAction(context, ref, item, value),
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
                      'Failed to load activities. Please try again.',
                      'Gagal memuat aktivitas. Silakan coba lagi.',
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
          onPressed: () => _openActivityEditor(context, ref, existing: null),
          icon: const Icon(Icons.add),
          label: Text(AppStrings.addActivity),
        ),
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
      onMarkDone: () => TaskLogRemoteDataSource().markReminderDoneByReference(
        taskType: 'physical_activity',
        referenceId: item.id,
        timeOfDay: item.timeOfDay,
      ),
      doneMessage: AppStrings.tr(
        'Activity marked as done.',
        'Aktivitas ditandai selesai.',
      ),
      onDeactivate: () => ref
          .read(activityControllerProvider.notifier)
          .deactivateReminder(item.id),
      onDelete: () =>
          ref.read(activityControllerProvider.notifier).deleteReminder(item.id),
      deactivatedMessage: AppStrings.tr(
        'Activity reminder disabled.',
        'Reminder aktivitas dinonaktifkan.',
      ),
      deactivateDialogContent: AppStrings.tr(
        'Activity reminder will be disabled. Schedule remains saved, but notifications will pause until reactivated.',
        'Reminder aktivitas akan dinonaktifkan. Jadwal tetap tersimpan, tetapi notifikasinya dihentikan sampai diaktifkan lagi.',
      ),
      deactivateDontAskAgainKey: 'confirm_skip_deactivate_activity_reminder',
      deletedMessage: AppStrings.tr(
        'Activity reminder deleted.',
        'Reminder aktivitas dihapus.',
      ),
      deleteDialogContent: AppStrings.tr(
        'Activity reminder will be permanently deleted and notifications canceled.',
        'Reminder aktivitas akan dihapus permanen dan notifikasinya dibatalkan.',
      ),
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
      typeFieldLabel: AppStrings.activityType,
      timeFieldLabel: AppStrings.tr('Activity Time', 'Waktu Aktivitas'),
      initialType: existing?.activityType ?? activityTypes.first,
      initialCustomName: existing?.customName,
      initialTimeOfDay: existing?.timeOfDay ?? '08:00:00',
      initialDate: existing?.startDate ?? DateTime.now(),
      isEditing: existing != null,
      createSuccessMessage: AppStrings.tr(
        'Activity reminder saved.',
        'Reminder aktivitas disimpan.',
      ),
      updateSuccessMessage: AppStrings.tr(
        'Activity reminder updated.',
        'Reminder aktivitas diperbarui.',
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

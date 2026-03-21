import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/type_labels.dart';
import '../../data/remote/datasources/physical_activity_remote_datasource.dart';
import '../../domain/models/physical_activity_reminder.dart';
import '../../services/notification_service.dart';
import '../../services/permission_service.dart';

final activityRemoteDataSourceProvider =
    Provider<PhysicalActivityRemoteDataSource>((ref) {
      return PhysicalActivityRemoteDataSource();
    });

final activityControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      ActivityController,
      List<PhysicalActivityReminder>
    >(ActivityController.new);

class ActivityController
    extends AutoDisposeAsyncNotifier<List<PhysicalActivityReminder>> {
  @override
  Future<List<PhysicalActivityReminder>> build() {
    return _fetch();
  }

  Future<List<PhysicalActivityReminder>> _fetch() {
    return ref.read(activityRemoteDataSourceProvider).getReminders();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> addReminder({
    required String activityType,
    required String timeOfDay,
    required DateTime startDate,
    String? customName,
    String? targetUnit,
    num? targetValue,
  }) async {
    final permissionService = ref.read(permissionServiceProvider);
    await permissionService.ensureNotificationPermission();
    final canScheduleExact = await permissionService.canScheduleExactAlarms();
    if (!canScheduleExact) {
      await permissionService.requestExactAlarmPermission();
    }

    final reminder = await ref
        .read(activityRemoteDataSourceProvider)
        .createReminder(
          activityType: activityType,
          timeOfDay: timeOfDay,
          startDate: startDate,
          customName: customName,
          targetUnit: targetUnit,
          targetValue: targetValue,
        );

    await ref
        .read(notificationServiceProvider)
        .scheduleTaskNotification(
          taskType: 'physical_activity',
          referenceId: reminder.id,
          timeOfDay: timeOfDay,
          channelId: 'activity_reminders',
          title: 'Pengingat Aktivitas',
          body:
              'Saatnya melakukan aktivitas ${activityTypeLabel(activityType)}.',
          scheduledAt: scheduleAt,
        );
    await refresh();
  }

  Future<void> updateReminder({
    required String reminderId,
    required String activityType,
    required String timeOfDay,
    required DateTime startDate,
    String? customName,
    String? targetUnit,
    num? targetValue,
  }) async {
    await ref
        .read(activityRemoteDataSourceProvider)
        .updateReminder(
          reminderId: reminderId,
          activityType: activityType,
          timeOfDay: timeOfDay,
          startDate: startDate,
          customName: customName,
          targetUnit: targetUnit,
          targetValue: targetValue,
        );

    final oldReminder = (state.valueOrNull ?? []).firstWhere((r) => r.id == reminderId);
    await ref
        .read(notificationServiceProvider)
        .cancelTaskNotification(
          taskType: 'physical_activity',
          referenceId: reminderId,
          timeOfDay: oldReminder.timeOfDay,
        );

    final scheduleAt = _nextScheduleTime(
      startDate: startDate,
      timeOfDay: timeOfDay,
    );

    await ref
        .read(notificationServiceProvider)
        .scheduleTaskNotification(
          taskType: 'physical_activity',
          referenceId: reminderId,
          timeOfDay: timeOfDay,
          channelId: 'activity_reminders',
          title: 'Pengingat Aktivitas',
          body:
              'Saatnya melakukan aktivitas ${activityTypeLabel(activityType)}.',
          scheduledAt: scheduleAt,
        );
    await refresh();
  }

  Future<void> deactivateReminder(String reminderId) async {
    try {
      final oldReminder = (state.valueOrNull ?? []).firstWhere((r) => r.id == reminderId);
      await ref
          .read(notificationServiceProvider)
          .cancelTaskNotification(
            taskType: 'physical_activity',
            referenceId: reminderId,
            timeOfDay: oldReminder.timeOfDay,
          );
    } catch (_) {}
    await ref
        .read(activityRemoteDataSourceProvider)
        .deactivateReminder(reminderId);
    await refresh();
  }

  Future<void> deleteReminder(String reminderId) async {
    try {
      final oldReminder = (state.valueOrNull ?? []).firstWhere((r) => r.id == reminderId);
      await ref
          .read(notificationServiceProvider)
          .cancelTaskNotification(
            taskType: 'physical_activity',
            referenceId: reminderId,
            timeOfDay: oldReminder.timeOfDay,
          );
    } catch (_) {}
    await ref.read(activityRemoteDataSourceProvider).deleteReminder(reminderId);
    await refresh();
  }

  DateTime _nextScheduleTime({
    required DateTime startDate,
    required String timeOfDay,
  }) {
    final parts = timeOfDay.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    var scheduledAt = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      hour,
      minute,
    );

    if (scheduledAt.isBefore(DateTime.now())) {
      scheduledAt = scheduledAt.add(const Duration(days: 1));
    }

    return scheduledAt;
  }
}

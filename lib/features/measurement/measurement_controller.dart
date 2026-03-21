import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/type_labels.dart';
import '../../data/remote/datasources/measurement_remote_datasource.dart';
import '../../domain/models/measurement_reminder.dart';
import '../../services/alarm_service.dart';
import '../../services/notification_service.dart';
import '../../services/permission_service.dart';

final measurementRemoteDataSourceProvider =
    Provider<MeasurementRemoteDataSource>((ref) {
      return MeasurementRemoteDataSource();
    });

final measurementControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      MeasurementController,
      List<MeasurementReminder>
    >(MeasurementController.new);

class MeasurementController
    extends AutoDisposeAsyncNotifier<List<MeasurementReminder>> {
  @override
  Future<List<MeasurementReminder>> build() {
    return _fetch();
  }

  Future<List<MeasurementReminder>> _fetch() {
    return ref.read(measurementRemoteDataSourceProvider).getReminders();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> addReminder({
    required String measurementType,
    required String timeOfDay,
    required DateTime startDate,
    String? customName,
    String? unit,
    String? targetValue,
  }) async {
    final permissionService = ref.read(permissionServiceProvider);
    await permissionService.ensureNotificationPermission();
    final canScheduleExact = await permissionService.canScheduleExactAlarms();
    if (!canScheduleExact) {
      await permissionService.requestExactAlarmPermission();
    }

    final reminder = await ref
        .read(measurementRemoteDataSourceProvider)
        .createReminder(
          measurementType: measurementType,
          timeOfDay: timeOfDay,
          startDate: startDate,
          customName: customName,
          unit: unit,
          targetValue: targetValue,
        );

    final notificationId = stableNotificationId('measurement:${reminder.id}');
    final scheduleAt = _nextScheduleTime(
      startDate: startDate,
      timeOfDay: timeOfDay,
    );
    await ref
        .read(notificationServiceProvider)
        .scheduleNotification(
          id: notificationId,
          channelId: 'measurement_reminders',
          title: 'Pengingat Pengukuran',
          body:
              'Saatnya melakukan pengukuran ${measurementTypeLabel(measurementType)}.',
          scheduledAt: scheduleAt,
          payload: 'task|measurement|${reminder.id}|$timeOfDay',
        );
    await ref
        .read(alarmServiceProvider)
        .scheduleExactAlarm(id: notificationId, dateTime: scheduleAt);

    await refresh();
  }

  Future<void> updateReminder({
    required String reminderId,
    required String measurementType,
    required String timeOfDay,
    required DateTime startDate,
    String? customName,
    String? unit,
    String? targetValue,
  }) async {
    await ref
        .read(measurementRemoteDataSourceProvider)
        .updateReminder(
          reminderId: reminderId,
          measurementType: measurementType,
          timeOfDay: timeOfDay,
          startDate: startDate,
          customName: customName,
          unit: unit,
          targetValue: targetValue,
        );

    final notificationId = stableNotificationId('measurement:$reminderId');
    final scheduleAt = _nextScheduleTime(
      startDate: startDate,
      timeOfDay: timeOfDay,
    );
    await ref
        .read(notificationServiceProvider)
        .cancelNotification(notificationId);
    await ref.read(alarmServiceProvider).cancelAlarm(notificationId);
    await ref
        .read(notificationServiceProvider)
        .scheduleNotification(
          id: notificationId,
          channelId: 'measurement_reminders',
          title: 'Pengingat Pengukuran',
          body:
              'Saatnya melakukan pengukuran ${measurementTypeLabel(measurementType)}.',
          scheduledAt: scheduleAt,
          payload: 'task|measurement|$reminderId|$timeOfDay',
        );
    await ref
        .read(alarmServiceProvider)
        .scheduleExactAlarm(id: notificationId, dateTime: scheduleAt);

    await refresh();
  }

  Future<void> deactivateReminder(String reminderId) async {
    final notificationId = stableNotificationId('measurement:$reminderId');
    await ref
        .read(notificationServiceProvider)
        .cancelNotification(notificationId);
    await ref.read(alarmServiceProvider).cancelAlarm(notificationId);
    await ref
        .read(measurementRemoteDataSourceProvider)
        .deactivateReminder(reminderId);
    await refresh();
  }

  Future<void> deleteReminder(String reminderId) async {
    final notificationId = stableNotificationId('measurement:$reminderId');
    await ref
        .read(notificationServiceProvider)
        .cancelNotification(notificationId);
    await ref.read(alarmServiceProvider).cancelAlarm(notificationId);
    await ref
        .read(measurementRemoteDataSourceProvider)
        .deleteReminder(reminderId);
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

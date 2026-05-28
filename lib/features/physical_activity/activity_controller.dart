import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/observability/app_monitoring.dart';
import '../../data/local/preferences/app_preferences.dart';
import '../../data/remote/datasources/physical_activity_remote_datasource.dart';
import '../../domain/models/physical_activity_reminder.dart';
import '../../services/notification_service.dart';
import '../../services/permission_service.dart';
import '../home/home_controller.dart';
import '../reports/report_screen.dart';

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
    await permissionService.ensureReminderReliabilityPermissions();

    await ref
        .read(activityRemoteDataSourceProvider)
        .createReminder(
          activityType: activityType,
          timeOfDay: timeOfDay,
          startDate: startDate,
          customName: customName,
          targetUnit: targetUnit,
          targetValue: targetValue,
        );

    if (AppPreferences.notifActivity) {
      await ref
          .read(notificationServiceProvider)
          .syncTaskNotificationsWithCurrentPreferences();
    }
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
    final permissionService = ref.read(permissionServiceProvider);
    await permissionService.ensureReminderReliabilityPermissions();

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

    final oldReminder = (state.valueOrNull ?? []).firstWhere(
      (r) => r.id == reminderId,
    );
    await ref
        .read(notificationServiceProvider)
        .cancelTaskNotification(
          taskType: 'physical_activity',
          referenceId: reminderId,
          timeOfDay: oldReminder.timeOfDay,
        );

    if (AppPreferences.notifActivity) {
      await ref
          .read(notificationServiceProvider)
          .syncTaskNotificationsWithCurrentPreferences();
    }
    await refresh();
  }

  Future<void> deactivateReminder(String reminderId) async {
    final oldReminder = _findReminderById(reminderId);
    if (oldReminder != null) {
      await _cancelReminderNotificationWithRetry(
        reminderId: reminderId,
        timeOfDay: oldReminder.timeOfDay,
        operation: 'deactivate',
      );
    }

    await ref
        .read(activityRemoteDataSourceProvider)
        .deactivateReminder(reminderId);
    ref.invalidate(todayTasksProvider);
    ref.invalidate(reportDataProvider);
    await refresh();
  }

  Future<void> deleteReminder(String reminderId) async {
    final oldReminder = _findReminderById(reminderId);
    if (oldReminder != null) {
      await _cancelReminderNotificationWithRetry(
        reminderId: reminderId,
        timeOfDay: oldReminder.timeOfDay,
        operation: 'delete',
      );
    }

    await ref.read(activityRemoteDataSourceProvider).deleteReminder(reminderId);
    ref.invalidate(todayTasksProvider);
    ref.invalidate(reportDataProvider);
    await refresh();
  }

  PhysicalActivityReminder? _findReminderById(String reminderId) {
    for (final reminder
        in state.valueOrNull ?? const <PhysicalActivityReminder>[]) {
      if (reminder.id == reminderId) {
        return reminder;
      }
    }
    return null;
  }

  Future<void> _cancelReminderNotificationWithRetry({
    required String reminderId,
    required String timeOfDay,
    required String operation,
  }) async {
    final notificationService = ref.read(notificationServiceProvider);
    Object? lastError;
    StackTrace? lastStackTrace;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await notificationService.cancelTaskNotification(
          taskType: 'physical_activity',
          referenceId: reminderId,
          timeOfDay: timeOfDay,
        );
        return;
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;

        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
      }
    }

    if (kDebugMode) {
      debugPrint(
        'Failed to cancel activity reminder notification after retry: $lastError',
      );
    }

    await AppMonitoring.logQueryFailure(
      source: 'activity_controller',
      event: 'activity_cancel_notification_failed',
      error: lastError ?? Exception('Unknown cancel notification error'),
      stackTrace: lastStackTrace,
      metadata: {
        'operation': operation,
        'reference_id': reminderId,
        'time_of_day': timeOfDay,
      },
    );
  }
}

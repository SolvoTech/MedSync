import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/observability/app_monitoring.dart';
import '../../data/local/preferences/app_preferences.dart';
import '../../data/remote/datasources/measurement_remote_datasource.dart';
import '../../domain/models/measurement_reminder.dart';
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
    await permissionService.ensureReminderReliabilityPermissions();

    await ref
        .read(measurementRemoteDataSourceProvider)
        .createReminder(
          measurementType: measurementType,
          timeOfDay: timeOfDay,
          startDate: startDate,
          customName: customName,
          unit: unit,
          targetValue: targetValue,
        );

    if (AppPreferences.notifMeasurement) {
      await ref
          .read(notificationServiceProvider)
          .syncTaskNotificationsWithCurrentPreferences();
    }
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
    final permissionService = ref.read(permissionServiceProvider);
    await permissionService.ensureReminderReliabilityPermissions();

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

    final oldReminder = (state.valueOrNull ?? []).firstWhere(
      (r) => r.id == reminderId,
    );
    await ref
        .read(notificationServiceProvider)
        .cancelTaskNotification(
          taskType: 'measurement',
          referenceId: reminderId,
          timeOfDay: oldReminder.timeOfDay,
        );

    if (AppPreferences.notifMeasurement) {
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
        .read(measurementRemoteDataSourceProvider)
        .deactivateReminder(reminderId);
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

    await ref
        .read(measurementRemoteDataSourceProvider)
        .deleteReminder(reminderId);
    await refresh();
  }

  MeasurementReminder? _findReminderById(String reminderId) {
    for (final reminder in state.valueOrNull ?? const <MeasurementReminder>[]) {
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
          taskType: 'measurement',
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
        'Failed to cancel measurement reminder notification after retry: $lastError',
      );
    }

    await AppMonitoring.logQueryFailure(
      source: 'measurement_controller',
      event: 'measurement_cancel_notification_failed',
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

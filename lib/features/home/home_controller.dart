import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/observability/app_monitoring.dart';
import '../../data/remote/datasources/measurement_remote_datasource.dart';
import '../../data/remote/datasources/physical_activity_remote_datasource.dart';
import '../../data/remote/datasources/task_log_remote_datasource.dart';
import '../../domain/models/task_log.dart';
import '../../services/notification_service.dart';

final taskLogRemoteDataSourceProvider = Provider<TaskLogRemoteDataSource>((
  ref,
) {
  return TaskLogRemoteDataSource();
});

final homeMeasurementDataSourceProvider = Provider<MeasurementRemoteDataSource>(
  (ref) {
    return MeasurementRemoteDataSource();
  },
);

final homeActivityDataSourceProvider =
    Provider<PhysicalActivityRemoteDataSource>((ref) {
      return PhysicalActivityRemoteDataSource();
    });

final todayTasksProvider =
    AutoDisposeAsyncNotifierProvider<HomeController, List<TaskLog>>(
      HomeController.new,
    );

class HomeController extends AutoDisposeAsyncNotifier<List<TaskLog>> {
  @override
  Future<List<TaskLog>> build() async {
    return _fetch();
  }

  Future<List<TaskLog>> _fetch() async {
    await _ensureSupplementalReminderTaskLogs();
    return ref.read(taskLogRemoteDataSourceProvider).getTodayTasks();
  }

  Future<void> _ensureSupplementalReminderTaskLogs() async {
    try {
      await ref
          .read(homeMeasurementDataSourceProvider)
          .ensureTaskLogsForActiveReminders();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'Failed to ensure measurement supplemental task logs: $error',
        );
      }

      await AppMonitoring.logQueryFailure(
        source: 'home_controller',
        event: 'ensure_measurement_supplemental_task_logs_failed',
        error: error,
        stackTrace: stackTrace,
        metadata: {
          'task_type': 'measurement',
          'operation': 'ensure_task_logs_for_active_reminders',
        },
      );
    }

    try {
      await ref
          .read(homeActivityDataSourceProvider)
          .ensureTaskLogsForActiveReminders();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to ensure activity supplemental task logs: $error');
      }

      await AppMonitoring.logQueryFailure(
        source: 'home_controller',
        event: 'ensure_activity_supplemental_task_logs_failed',
        error: error,
        stackTrace: stackTrace,
        metadata: {
          'task_type': 'physical_activity',
          'operation': 'ensure_task_logs_for_active_reminders',
        },
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> markDone(String taskLogId) async {
    await ref
        .read(taskLogRemoteDataSourceProvider)
        .updateTaskStatus(taskLogId: taskLogId, status: 'done');
    await _advanceSnoozes(taskLogId);
    await refresh();
  }

  Future<void> markSkipped(String taskLogId) async {
    await ref
        .read(taskLogRemoteDataSourceProvider)
        .updateTaskStatus(taskLogId: taskLogId, status: 'skipped');
    await _advanceSnoozes(taskLogId);
    await refresh();
  }

  Future<void> _advanceSnoozes(String taskLogId) async {
    final taskList = state.valueOrNull ?? [];
    try {
      final task = taskList.firstWhere((t) => t.id == taskLogId);
      final notificationService = ref.read(notificationServiceProvider);

      final h = task.scheduledAt.hour.toString().padLeft(2, '0');
      final m = task.scheduledAt.minute.toString().padLeft(2, '0');

      await notificationService.advanceScheduleToTomorrow(
        taskType: task.taskType,
        referenceId: task.referenceId,
        timeOfDay: '$h:$m',
      );
    } catch (_) {
      // Ignore if task not found in memory
    }
  }
}

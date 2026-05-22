import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/observability/app_monitoring.dart';
import '../../data/remote/datasources/measurement_remote_datasource.dart';
import '../../data/remote/datasources/physical_activity_remote_datasource.dart';
import '../../data/remote/datasources/task_log_remote_datasource.dart';
import '../../domain/models/task_log.dart';
import '../../services/notification_service.dart';
import '../../services/task_completion_service.dart';

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

  Future<void> markDone(
    String taskLogId, {
    String? completionProofPhotoPath,
    DateTime? completionProofCapturedAt,
    DateTime? completionProofUploadedAt,
  }) async {
    final task = await _findTaskByIdOrFetch(taskLogId);
    if (task == null) {
      await ref
          .read(taskLogRemoteDataSourceProvider)
          .updateTaskStatus(
            taskLogId: taskLogId,
            status: 'done',
            completionProofPhotoPath: completionProofPhotoPath,
            completionProofCapturedAt: completionProofCapturedAt,
            completionProofUploadedAt: completionProofUploadedAt,
          );
      await refresh();
      return;
    }

    await _taskCompletionService().markTaskStatusAndSilence(
      task: task,
      status: 'done',
      completionProofPhotoPath: completionProofPhotoPath,
      completionProofCapturedAt: completionProofCapturedAt,
      completionProofUploadedAt: completionProofUploadedAt,
    );
    await refresh();
  }

  Future<void> markSkipped(String taskLogId) async {
    final task = await _findTaskByIdOrFetch(taskLogId);
    if (task == null) {
      await ref
          .read(taskLogRemoteDataSourceProvider)
          .updateTaskStatus(taskLogId: taskLogId, status: 'skipped');
      await refresh();
      return;
    }

    await _taskCompletionService().markTaskStatusAndSilence(
      task: task,
      status: 'skipped',
    );
    await refresh();
  }

  TaskCompletionService _taskCompletionService() {
    return TaskCompletionService(
      taskLogStore: ref.read(taskLogRemoteDataSourceProvider),
      reminderScheduler: ref.read(notificationServiceProvider),
    );
  }

  Future<TaskLog?> _findTaskByIdOrFetch(String taskLogId) async {
    final task = _findTaskById(taskLogId);
    if (task != null) {
      return task;
    }

    return ref.read(taskLogRemoteDataSourceProvider).getTaskById(taskLogId);
  }

  TaskLog? _findTaskById(String taskLogId) {
    for (final task in state.valueOrNull ?? const <TaskLog>[]) {
      if (task.id == taskLogId) {
        return task;
      }
    }
    return null;
  }
}

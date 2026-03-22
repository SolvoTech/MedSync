import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/datasources/task_log_remote_datasource.dart';
import '../../domain/models/task_log.dart';
import '../../services/notification_service.dart';

final taskLogRemoteDataSourceProvider = Provider<TaskLogRemoteDataSource>((
  ref,
) {
  return TaskLogRemoteDataSource();
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

  Future<List<TaskLog>> _fetch() {
    return ref.read(taskLogRemoteDataSourceProvider).getTodayTasks();
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

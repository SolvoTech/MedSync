import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/datasources/task_log_remote_datasource.dart';
import '../../domain/models/task_log.dart';

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
    await refresh();
  }

  Future<void> markSkipped(String taskLogId) async {
    await ref
        .read(taskLogRemoteDataSourceProvider)
        .updateTaskStatus(taskLogId: taskLogId, status: 'skipped');
    await refresh();
  }
}

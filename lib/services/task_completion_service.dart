import '../core/utils/reminder_time.dart';
import '../domain/models/task_log.dart';

abstract interface class TaskLogCompletionStore {
  Future<void> updateTaskStatus({
    required String taskLogId,
    required String status,
  });

  Future<void> markReminderDoneByReference({
    required String taskType,
    required String referenceId,
    String? timeOfDay,
  });
}

abstract interface class TaskReminderScheduler {
  Future<void> advanceScheduleToTomorrow({
    required String taskType,
    required String referenceId,
    required String timeOfDay,
  });
}

class TaskCompletionService {
  const TaskCompletionService({
    required this.taskLogStore,
    required this.reminderScheduler,
  });

  final TaskLogCompletionStore taskLogStore;
  final TaskReminderScheduler reminderScheduler;

  Future<void> markTaskStatusAndSilence({
    required TaskLog task,
    required String status,
  }) async {
    await taskLogStore.updateTaskStatus(taskLogId: task.id, status: status);
    await reminderScheduler.advanceScheduleToTomorrow(
      taskType: task.taskType,
      referenceId: task.referenceId,
      timeOfDay: reminderTimeOfDayFromDateTime(task.scheduledAt),
    );
  }

  Future<void> markReminderDoneAndSilence({
    required String taskType,
    required String referenceId,
    String? timeOfDay,
  }) async {
    final normalizedTime = canonicalReminderTimeOfDay(timeOfDay);
    final rawTime = timeOfDay?.trim();

    await taskLogStore.markReminderDoneByReference(
      taskType: taskType,
      referenceId: referenceId,
      timeOfDay: normalizedTime ?? rawTime,
    );

    if (normalizedTime == null || normalizedTime.isEmpty) {
      return;
    }

    await reminderScheduler.advanceScheduleToTomorrow(
      taskType: taskType,
      referenceId: referenceId,
      timeOfDay: normalizedTime,
    );
  }
}

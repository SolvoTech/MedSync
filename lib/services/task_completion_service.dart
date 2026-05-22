import '../core/utils/reminder_time.dart';
import '../domain/models/task_log.dart';

abstract interface class TaskLogCompletionStore {
  Future<void> updateTaskStatus({
    required String taskLogId,
    required String status,
    String? completionProofPhotoPath,
    DateTime? completionProofCapturedAt,
    DateTime? completionProofUploadedAt,
  });

  Future<void> markReminderDoneByReference({
    required String taskType,
    required String referenceId,
    String? timeOfDay,
    DateTime? scheduledAt,
    String? completionProofPhotoPath,
    DateTime? completionProofCapturedAt,
    DateTime? completionProofUploadedAt,
  });
}

abstract interface class TaskReminderScheduler {
  Future<void> advanceScheduleToTomorrow({
    required String taskType,
    required String referenceId,
    required String timeOfDay,
    DateTime? scheduledAt,
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
    String? completionProofPhotoPath,
    DateTime? completionProofCapturedAt,
    DateTime? completionProofUploadedAt,
  }) async {
    await taskLogStore.updateTaskStatus(
      taskLogId: task.id,
      status: status,
      completionProofPhotoPath: completionProofPhotoPath,
      completionProofCapturedAt: completionProofCapturedAt,
      completionProofUploadedAt: completionProofUploadedAt,
    );
    await reminderScheduler.advanceScheduleToTomorrow(
      taskType: task.taskType,
      referenceId: task.referenceId,
      timeOfDay: reminderTimeOfDayFromDateTime(task.scheduledAt),
      scheduledAt: task.scheduledAt,
    );
  }

  Future<void> markReminderDoneAndSilence({
    required String taskType,
    required String referenceId,
    String? timeOfDay,
    DateTime? scheduledAt,
    String? completionProofPhotoPath,
    DateTime? completionProofCapturedAt,
    DateTime? completionProofUploadedAt,
  }) async {
    final normalizedTime = canonicalReminderTimeOfDay(timeOfDay);
    final rawTime = timeOfDay?.trim();

    await taskLogStore.markReminderDoneByReference(
      taskType: taskType,
      referenceId: referenceId,
      timeOfDay: normalizedTime ?? rawTime,
      scheduledAt: scheduledAt,
      completionProofPhotoPath: completionProofPhotoPath,
      completionProofCapturedAt: completionProofCapturedAt,
      completionProofUploadedAt: completionProofUploadedAt,
    );

    if (normalizedTime == null || normalizedTime.isEmpty) {
      return;
    }

    await reminderScheduler.advanceScheduleToTomorrow(
      taskType: taskType,
      referenceId: referenceId,
      timeOfDay: normalizedTime,
      scheduledAt: scheduledAt,
    );
  }
}

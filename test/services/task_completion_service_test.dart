import 'package:med_syn/domain/models/task_log.dart';
import 'package:med_syn/services/task_completion_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTaskLogStore implements TaskLogCompletionStore {
  String? updatedTaskLogId;
  String? updatedStatus;
  String? markedTaskType;
  String? markedReferenceId;
  String? markedTimeOfDay;
  DateTime? markedScheduledAt;

  @override
  Future<void> markReminderDoneByReference({
    required String taskType,
    required String referenceId,
    String? timeOfDay,
    DateTime? scheduledAt,
  }) async {
    markedTaskType = taskType;
    markedReferenceId = referenceId;
    markedTimeOfDay = timeOfDay;
    markedScheduledAt = scheduledAt;
  }

  @override
  Future<void> updateTaskStatus({
    required String taskLogId,
    required String status,
  }) async {
    updatedTaskLogId = taskLogId;
    updatedStatus = status;
  }
}

class _FakeReminderScheduler implements TaskReminderScheduler {
  String? taskType;
  String? referenceId;
  String? timeOfDay;
  DateTime? scheduledAt;

  @override
  Future<void> advanceScheduleToTomorrow({
    required String taskType,
    required String referenceId,
    required String timeOfDay,
    DateTime? scheduledAt,
  }) async {
    this.taskType = taskType;
    this.referenceId = referenceId;
    this.timeOfDay = timeOfDay;
    this.scheduledAt = scheduledAt;
  }
}

void main() {
  group('TaskCompletionService', () {
    test(
      'markTaskStatusAndSilence updates the task and silences its slot',
      () async {
        final store = _FakeTaskLogStore();
        final scheduler = _FakeReminderScheduler();
        final service = TaskCompletionService(
          taskLogStore: store,
          reminderScheduler: scheduler,
        );

        await service.markTaskStatusAndSilence(
          task: TaskLog(
            id: 'task-1',
            taskType: 'medicine',
            referenceId: 'ref-1',
            scheduledAt: DateTime(2026, 4, 28, 8, 0),
            status: 'pending',
          ),
          status: 'done',
        );

        expect(store.updatedTaskLogId, 'task-1');
        expect(store.updatedStatus, 'done');
        expect(scheduler.taskType, 'medicine');
        expect(scheduler.referenceId, 'ref-1');
        expect(scheduler.timeOfDay, '08:00');
        expect(scheduler.scheduledAt, DateTime(2026, 4, 28, 8, 0));
      },
    );

    test('markTaskStatusAndSilence also silences skipped tasks', () async {
      final store = _FakeTaskLogStore();
      final scheduler = _FakeReminderScheduler();
      final service = TaskCompletionService(
        taskLogStore: store,
        reminderScheduler: scheduler,
      );

      await service.markTaskStatusAndSilence(
        task: TaskLog(
          id: 'task-2',
          taskType: 'physical_activity',
          referenceId: 'activity-1',
          scheduledAt: DateTime(2026, 4, 28, 6, 30),
          status: 'pending',
        ),
        status: 'skipped',
      );

      expect(store.updatedTaskLogId, 'task-2');
      expect(store.updatedStatus, 'skipped');
      expect(scheduler.taskType, 'physical_activity');
      expect(scheduler.referenceId, 'activity-1');
      expect(scheduler.timeOfDay, '06:30');
    });

    test('markReminderDoneAndSilence canonicalizes time to HH:mm', () async {
      final store = _FakeTaskLogStore();
      final scheduler = _FakeReminderScheduler();
      final service = TaskCompletionService(
        taskLogStore: store,
        reminderScheduler: scheduler,
      );

      await service.markReminderDoneAndSilence(
        taskType: 'measurement',
        referenceId: 'reminder-1',
        timeOfDay: '08:00:00',
        scheduledAt: DateTime(2026, 4, 28, 8),
      );

      expect(store.markedTaskType, 'measurement');
      expect(store.markedReferenceId, 'reminder-1');
      expect(store.markedTimeOfDay, '08:00');
      expect(store.markedScheduledAt, DateTime(2026, 4, 28, 8));
      expect(scheduler.taskType, 'measurement');
      expect(scheduler.referenceId, 'reminder-1');
      expect(scheduler.timeOfDay, '08:00');
      expect(scheduler.scheduledAt, DateTime(2026, 4, 28, 8));
    });

    test(
      'markReminderDoneAndSilence skips scheduler when time is invalid',
      () async {
        final store = _FakeTaskLogStore();
        final scheduler = _FakeReminderScheduler();
        final service = TaskCompletionService(
          taskLogStore: store,
          reminderScheduler: scheduler,
        );

        await service.markReminderDoneAndSilence(
          taskType: 'measurement',
          referenceId: 'reminder-1',
          timeOfDay: 'invalid',
        );

        expect(store.markedTimeOfDay, 'invalid');
        expect(scheduler.taskType, isNull);
        expect(scheduler.referenceId, isNull);
        expect(scheduler.timeOfDay, isNull);
      },
    );
  });
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_syn/services/notification_service.dart';

void main() {
  group('stableNotificationId', () {
    test('returns deterministic IDs for task payload seeds', () {
      expect(
        stableNotificationId('taskv2|medicine|user-1|schedule-1|19:10|0'),
        1367291417,
      );
      expect(
        stableNotificationId('taskv2|medicine|user-1|schedule-1|19:10|1'),
        1350513798,
      );
      expect(
        stableNotificationId('task|medicine|schedule-1|19:10|6'),
        1160258564,
      );
    });
  });

  group('shouldOpenDashboardForNotificationAction', () {
    test('returns true only for the notification done action', () {
      const response = NotificationResponse(
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
        actionId: NotificationService.markDoneActionId,
        payload: 'taskv2|medicine|user-1|schedule-1|19:10|0',
      );

      expect(shouldOpenDashboardForNotificationAction(response), isTrue);
    });

    test('returns false for regular notification taps', () {
      const response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'taskv2|medicine|user-1|schedule-1|19:10|0',
      );

      expect(shouldOpenDashboardForNotificationAction(response), isFalse);
    });
  });

  group('taskNotificationIdsForSlot', () {
    test('builds cancel candidates for scoped and legacy payload IDs', () {
      final ids = taskNotificationIdsForSlot(
        taskType: 'medicine',
        activeUserId: 'user-1',
        referenceId: 'schedule-1',
        timeOfDay: '19:10:00',
      );

      expect(ids, hasLength(14));
      expect(
        ids,
        contains(
          stableNotificationId('taskv2|medicine|user-1|schedule-1|19:10|0'),
        ),
      );
      expect(
        ids,
        contains(
          stableNotificationId('taskv2|medicine|user-1|schedule-1|19:10|6'),
        ),
      );
      expect(
        ids,
        contains(stableNotificationId('task|medicine|schedule-1|19:10|0')),
      );
      expect(
        ids,
        contains(stableNotificationId('task|medicine|schedule-1|19:10|6')),
      );
    });

    test('builds only legacy candidates when no active user exists', () {
      final ids = taskNotificationIdsForSlot(
        taskType: 'measurement',
        activeUserId: null,
        referenceId: 'reminder-1',
        timeOfDay: '08:00',
      );

      expect(ids, hasLength(7));
      expect(
        ids,
        contains(stableNotificationId('task|measurement|reminder-1|08:00|0')),
      );
      expect(
        ids,
        contains(stableNotificationId('task|measurement|reminder-1|08:00|6')),
      );
    });

    test('builds occurrence-scoped candidates for the completed day', () {
      final scheduledAt = DateTime(2026, 5, 1, 14, 33);
      final ids = taskNotificationIdsForSlot(
        taskType: 'medicine',
        activeUserId: 'user-1',
        referenceId: 'schedule-1',
        timeOfDay: '14:33',
        scheduledAt: scheduledAt,
      );

      expect(ids, hasLength(21));
      expect(
        ids,
        contains(
          stableNotificationId(
            'taskv3|medicine|user-1|schedule-1|14:33|${scheduledAt.toIso8601String()}|0',
          ),
        ),
      );
      expect(
        ids,
        contains(
          stableNotificationId(
            'taskv3|medicine|user-1|schedule-1|14:33|${scheduledAt.toIso8601String()}|6',
          ),
        ),
      );
    });
  });

  group('taskNotificationPayloadMatchesSlot', () {
    test('matches scoped payloads with canonicalized time', () {
      expect(
        taskNotificationPayloadMatchesSlot(
          payload: 'taskv2|medicine|user-1|schedule-1|19:10:00|3',
          taskType: 'medicine',
          referenceId: 'schedule-1',
          timeOfDay: '19:10',
        ),
        isTrue,
      );
    });

    test('matches occurrence-scoped payloads with canonicalized time', () {
      expect(
        taskNotificationPayloadMatchesSlot(
          payload:
              'taskv3|medicine|user-1|schedule-1|19:10:00|2026-05-01T19:10:00.000|3',
          taskType: 'medicine',
          referenceId: 'schedule-1',
          timeOfDay: '19:10',
        ),
        isTrue,
      );
    });

    test('matches legacy payloads without user ID', () {
      expect(
        taskNotificationPayloadMatchesSlot(
          payload: 'task|physical_activity|activity-1|06:05:00|2',
          taskType: 'physical_activity',
          referenceId: 'activity-1',
          timeOfDay: '06:05',
        ),
        isTrue,
      );
    });

    test('rejects payloads for other slots', () {
      expect(
        taskNotificationPayloadMatchesSlot(
          payload: 'taskv2|medicine|user-1|schedule-1|19:10|0',
          taskType: 'medicine',
          referenceId: 'schedule-2',
          timeOfDay: '19:10',
        ),
        isFalse,
      );
      expect(
        taskNotificationPayloadMatchesSlot(
          payload: 'not-a-task-payload',
          taskType: 'medicine',
          referenceId: 'schedule-1',
          timeOfDay: '19:10',
        ),
        isFalse,
      );
    });
  });

  group('resolveNotificationScheduleTime', () {
    test('skips one-shot notifications that are already past', () {
      final now = DateTime(2026, 5, 1, 14, 33, 10);

      expect(
        resolveNotificationScheduleTime(
          scheduledAt: DateTime(2026, 5, 1, 14, 33),
          now: now,
          repeatDaily: false,
          isReminder: true,
        ),
        isNull,
      );
    });

    test('catches up a daily reminder that was missed by a few minutes', () {
      final now = DateTime(2026, 5, 1, 14, 33, 10);

      expect(
        resolveNotificationScheduleTime(
          scheduledAt: DateTime(2026, 5, 1, 14, 33),
          now: now,
          repeatDaily: true,
          isReminder: true,
        ),
        DateTime(2026, 5, 1, 14, 33, 15),
      );
    });

    test('keeps old daily reminder times for native next-day refresh', () {
      final scheduledAt = DateTime(2026, 5, 1, 8);

      expect(
        resolveNotificationScheduleTime(
          scheduledAt: scheduledAt,
          now: DateTime(2026, 5, 1, 14),
          repeatDaily: true,
          isReminder: true,
        ),
        scheduledAt,
      );
    });
  });

  group('resolveTaskReminderOccurrenceScheduleTime', () {
    test('catches up a just-missed one-shot reminder', () {
      final now = DateTime(2026, 5, 1, 14, 33, 10);

      expect(
        resolveTaskReminderOccurrenceScheduleTime(
          scheduledAt: DateTime(2026, 5, 1, 14, 33),
          now: now,
          isReminder: true,
        ),
        DateTime(2026, 5, 1, 14, 33, 15),
      );
    });

    test('skips stale one-shot reminders outside the catch-up window', () {
      expect(
        resolveTaskReminderOccurrenceScheduleTime(
          scheduledAt: DateTime(2026, 5, 1, 8),
          now: DateTime(2026, 5, 1, 14),
          isReminder: true,
        ),
        isNull,
      );
    });
  });
}

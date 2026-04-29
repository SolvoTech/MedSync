import 'package:med_syn/core/utils/reminder_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canonicalReminderTimeOfDay', () {
    test('normalizes seconds away', () {
      expect(canonicalReminderTimeOfDay('08:05:00'), '08:05');
    });

    test('normalizes single digit hour and minute', () {
      expect(canonicalReminderTimeOfDay('8:5'), '08:05');
    });

    test('returns null for invalid input', () {
      expect(canonicalReminderTimeOfDay('25:00'), isNull);
      expect(canonicalReminderTimeOfDay('abc'), isNull);
    });
  });

  group('reminderTimesMatch', () {
    test('matches HH:mm and HH:mm:ss values', () {
      expect(reminderTimesMatch('08:00', '08:00:00'), isTrue);
    });

    test('does not match different times', () {
      expect(reminderTimesMatch('08:00', '08:05:00'), isFalse);
    });
  });

  test('reminderScheduledAtForDay uses same calendar day', () {
    final scheduledAt = reminderScheduledAtForDay(
      day: DateTime(2026, 4, 28, 22, 10),
      timeOfDay: '06:30:00',
    );

    expect(scheduledAt, DateTime(2026, 4, 28, 6, 30));
  });

  group('nextReminderOccurrence', () {
    test('keeps future start date time', () {
      final next = nextReminderOccurrence(
        startDate: DateTime(2026, 4, 30),
        timeOfDay: '08:15',
        now: DateTime(2026, 4, 29, 22, 0),
      );

      expect(next, DateTime(2026, 4, 30, 8, 15));
    });

    test(
      'uses today when start date is in the past but time is still ahead',
      () {
        final next = nextReminderOccurrence(
          startDate: DateTime(2026, 4, 1),
          timeOfDay: '23:00',
          now: DateTime(2026, 4, 30, 10, 0),
        );

        expect(next, DateTime(2026, 4, 30, 23, 0));
      },
    );

    test('fires shortly when user chooses the current minute', () {
      final next = nextReminderOccurrence(
        startDate: DateTime(2026, 4, 30),
        timeOfDay: '01:30',
        now: DateTime(2026, 4, 30, 1, 30, 20),
      );

      expect(next, DateTime(2026, 4, 30, 1, 30, 25));
    });

    test('moves to tomorrow when today time is already past', () {
      final next = nextReminderOccurrence(
        startDate: DateTime(2026, 4, 30),
        timeOfDay: '01:30',
        now: DateTime(2026, 4, 30, 1, 31),
      );

      expect(next, DateTime(2026, 5, 1, 1, 30));
    });
  });
}

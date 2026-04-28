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
}

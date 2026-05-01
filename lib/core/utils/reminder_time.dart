String? canonicalReminderTimeOfDay(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }

  final parts = trimmed.split(':');
  if (parts.length < 2) {
    return null;
  }

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) {
    return null;
  }

  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return null;
  }

  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

String reminderTimeOfDayFromDateTime(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

DateTime parseReminderScheduledAt(String value) {
  final match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,6}))?)?',
  ).firstMatch(value.trim());

  if (match == null) {
    return DateTime.parse(value);
  }

  final fraction = (match.group(7) ?? '').padRight(6, '0');
  final microsecond = fraction.isEmpty
      ? 0
      : int.parse(fraction.substring(3, 6));

  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
    int.tryParse(match.group(6) ?? '') ?? 0,
    fraction.isEmpty ? 0 : int.parse(fraction.substring(0, 3)),
    microsecond,
  );
}

String reminderDateTimeWallKey(DateTime value) {
  return [
    value.year.toString().padLeft(4, '0'),
    value.month.toString().padLeft(2, '0'),
    value.day.toString().padLeft(2, '0'),
    value.hour.toString().padLeft(2, '0'),
    value.minute.toString().padLeft(2, '0'),
    value.second.toString().padLeft(2, '0'),
  ].join('-');
}

bool reminderTimesMatch(String? left, String? right) {
  final normalizedLeft = canonicalReminderTimeOfDay(left);
  final normalizedRight = canonicalReminderTimeOfDay(right);
  if (normalizedLeft == null || normalizedRight == null) {
    return false;
  }

  return normalizedLeft == normalizedRight;
}

DateTime? reminderScheduledAtForDay({
  required DateTime day,
  String? timeOfDay,
}) {
  final normalizedTime = canonicalReminderTimeOfDay(timeOfDay);
  if (normalizedTime == null) {
    return null;
  }

  final parts = normalizedTime.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);

  return DateTime(day.year, day.month, day.day, hour, minute);
}

DateTime nextReminderOccurrence({
  required DateTime startDate,
  required String timeOfDay,
  DateTime? now,
}) {
  final referenceNow = now ?? DateTime.now();
  final scheduledAt = reminderScheduledAtForDay(
    day: startDate,
    timeOfDay: timeOfDay,
  );

  if (scheduledAt == null) {
    return referenceNow.add(const Duration(seconds: 5));
  }

  if (!scheduledAt.isBefore(referenceNow)) {
    return scheduledAt;
  }

  final todayAtReminderTime = reminderScheduledAtForDay(
    day: referenceNow,
    timeOfDay: timeOfDay,
  );

  if (todayAtReminderTime == null) {
    return referenceNow.add(const Duration(seconds: 5));
  }

  if (!todayAtReminderTime.isBefore(referenceNow)) {
    return todayAtReminderTime;
  }

  if (referenceNow.hour == todayAtReminderTime.hour &&
      referenceNow.minute == todayAtReminderTime.minute) {
    return referenceNow.add(const Duration(seconds: 5));
  }

  return todayAtReminderTime.add(const Duration(days: 1));
}

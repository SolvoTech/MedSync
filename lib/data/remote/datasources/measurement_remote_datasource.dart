import '../../../domain/models/measurement_reminder.dart';
import '../supabase_client.dart';

class MeasurementRemoteDataSource {
  static const int _taskLogHorizonDays = 30;
  static const String _taskType = 'measurement';

  Future<List<MeasurementReminder>> getReminders() async {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      throw Exception(
        'Supabase belum diinisialisasi. Periksa konfigurasi .env.',
      );
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    final rows = await client
        .from('measurement_reminders')
        .select()
        .eq('owner_id', user.id)
        .eq('is_active', true)
        .order('time_of_day', ascending: true);

    return (rows as List<dynamic>)
        .map((row) => MeasurementReminder.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<MeasurementReminder> createReminder({
    required String measurementType,
    required String timeOfDay,
    required DateTime startDate,
    String? customName,
    String? unit,
    String? targetValue,
  }) async {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      throw Exception(
        'Supabase belum diinisialisasi. Periksa konfigurasi .env.',
      );
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    final inserted = await client
        .from('measurement_reminders')
        .insert({
          'owner_id': user.id,
          'measurement_type': measurementType,
          'custom_name': customName,
          'time_of_day': timeOfDay,
          'start_date': startDate.toIso8601String().split('T').first,
          'target_value': targetValue,
          'unit': unit,
          'is_active': true,
          'notification_enabled': true,
          'repeat_type': 'daily',
        })
        .select()
        .single();

    final reminder = MeasurementReminder.fromMap(inserted);

    await _syncTaskLogsForReminder(
      ownerId: user.id,
      reminderId: reminder.id,
      timeOfDay: reminder.timeOfDay,
      startDate: reminder.startDate,
      repeatType: 'daily',
      repeatDays: const <int>[],
      intervalDays: 1,
      horizonDays: _taskLogHorizonDays,
    );

    return reminder;
  }

  Future<void> updateReminder({
    required String reminderId,
    required String measurementType,
    required String timeOfDay,
    required DateTime startDate,
    String? customName,
    String? unit,
    String? targetValue,
  }) async {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      throw Exception(
        'Supabase belum diinisialisasi. Periksa konfigurasi .env.',
      );
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    await client
        .from('measurement_reminders')
        .update({
          'measurement_type': measurementType,
          'custom_name': customName,
          'time_of_day': timeOfDay,
          'start_date': startDate.toIso8601String().split('T').first,
          'target_value': targetValue,
          'unit': unit,
        })
        .eq('id', reminderId)
        .eq('owner_id', user.id);

    await _deletePendingTaskLogsForReminder(
      ownerId: user.id,
      reminderId: reminderId,
    );

    await _syncTaskLogsForReminder(
      ownerId: user.id,
      reminderId: reminderId,
      timeOfDay: timeOfDay,
      startDate: startDate,
      repeatType: 'daily',
      repeatDays: const <int>[],
      intervalDays: 1,
      horizonDays: _taskLogHorizonDays,
    );
  }

  Future<void> deactivateReminder(String reminderId) async {
    final client = SupabaseClientRef.maybeClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    await client
        .from('measurement_reminders')
        .update({'is_active': false})
        .eq('id', reminderId)
        .eq('owner_id', user.id);

    await _deletePendingTaskLogsForReminder(
      ownerId: user.id,
      reminderId: reminderId,
    );
  }

  Future<void> deleteReminder(String reminderId) async {
    final client = SupabaseClientRef.maybeClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    await _deleteAllTaskLogsForReminder(
      ownerId: user.id,
      reminderId: reminderId,
    );

    await client
        .from('measurement_reminders')
        .delete()
        .eq('id', reminderId)
        .eq('owner_id', user.id);
  }

  Future<void> ensureTaskLogsForActiveReminders({
    int horizonDays = _taskLogHorizonDays,
  }) async {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      throw Exception(
        'Supabase belum diinisialisasi. Periksa konfigurasi .env.',
      );
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    final rows = await client
        .from('measurement_reminders')
        .select(
          'id, time_of_day, start_date, repeat_type, repeat_days, interval_days',
        )
        .eq('owner_id', user.id)
        .eq('is_active', true);

    for (final row in (rows as List<dynamic>)) {
      final map = row as Map<String, dynamic>;
      final reminderId = map['id'] as String?;
      final timeOfDay = map['time_of_day'] as String?;
      final startDateRaw = map['start_date'] as String?;

      if (reminderId == null ||
          reminderId.isEmpty ||
          timeOfDay == null ||
          timeOfDay.isEmpty ||
          startDateRaw == null ||
          startDateRaw.isEmpty) {
        continue;
      }

      final startDate = DateTime.tryParse(startDateRaw);
      if (startDate == null) {
        continue;
      }

      final repeatType = (map['repeat_type'] as String?) ?? 'daily';
      final repeatDays = _parseRepeatDays(map['repeat_days']);
      final intervalDays = _parseIntervalDays(map['interval_days']);

      await _syncTaskLogsForReminder(
        ownerId: user.id,
        reminderId: reminderId,
        timeOfDay: timeOfDay,
        startDate: startDate,
        repeatType: repeatType,
        repeatDays: repeatDays,
        intervalDays: intervalDays,
        horizonDays: horizonDays,
      );
    }
  }

  Future<void> _syncTaskLogsForReminder({
    required String ownerId,
    required String reminderId,
    required String timeOfDay,
    required DateTime startDate,
    required String repeatType,
    required List<int> repeatDays,
    required int intervalDays,
    required int horizonDays,
  }) async {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      return;
    }

    final now = DateTime.now();
    final today = _startOfDay(now);
    final lastDay = today.add(Duration(days: horizonDays - 1));

    final occurrenceDays = _buildOccurrenceDays(
      startDate: startDate,
      repeatType: repeatType,
      repeatDays: repeatDays,
      intervalDays: intervalDays,
      firstDay: today,
      lastDay: lastDay,
    );

    if (occurrenceDays.isEmpty) {
      return;
    }

    final expectedScheduleTimes = <DateTime>[];
    for (final day in occurrenceDays) {
      final scheduledAt = _scheduledAtForDay(day, timeOfDay);
      if (scheduledAt != null) {
        expectedScheduleTimes.add(scheduledAt);
      }
    }

    if (expectedScheduleTimes.isEmpty) {
      return;
    }

    var earliest = expectedScheduleTimes.first;
    var latest = expectedScheduleTimes.first;
    for (final scheduledAt in expectedScheduleTimes.skip(1)) {
      if (scheduledAt.isBefore(earliest)) {
        earliest = scheduledAt;
      }
      if (scheduledAt.isAfter(latest)) {
        latest = scheduledAt;
      }
    }

    final existingRows = await client
        .from('task_logs')
        .select('scheduled_at')
        .eq('owner_id', ownerId)
        .eq('task_type', _taskType)
        .eq('reference_id', reminderId)
        .gte('scheduled_at', earliest.toIso8601String())
        .lte('scheduled_at', latest.toIso8601String());

    final existingKeys = <String>{};
    for (final row in (existingRows as List<dynamic>)) {
      final scheduledAtRaw = (row as Map<String, dynamic>)['scheduled_at'];
      if (scheduledAtRaw is String) {
        final parsed = DateTime.tryParse(scheduledAtRaw);
        if (parsed != null) {
          existingKeys.add(_dateTimeKey(parsed));
        }
      }
    }

    final missingRows = <Map<String, dynamic>>[];
    for (final scheduledAt in expectedScheduleTimes) {
      if (existingKeys.contains(_dateTimeKey(scheduledAt))) {
        continue;
      }

      missingRows.add({
        'owner_id': ownerId,
        'task_type': _taskType,
        'reference_id': reminderId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'status': 'pending',
      });
    }

    if (missingRows.isNotEmpty) {
      await client.from('task_logs').insert(missingRows);
    }
  }

  Future<void> _deletePendingTaskLogsForReminder({
    required String ownerId,
    required String reminderId,
  }) async {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      return;
    }

    final today = _startOfDay(DateTime.now());
    await client
        .from('task_logs')
        .delete()
        .eq('owner_id', ownerId)
        .eq('task_type', _taskType)
        .eq('reference_id', reminderId)
        .eq('status', 'pending')
        .gte('scheduled_at', today.toIso8601String());
  }

  Future<void> _deleteAllTaskLogsForReminder({
    required String ownerId,
    required String reminderId,
  }) async {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      return;
    }

    await client
        .from('task_logs')
        .delete()
        .eq('owner_id', ownerId)
        .eq('task_type', _taskType)
        .eq('reference_id', reminderId);
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime? _scheduledAtForDay(DateTime day, String timeOfDay) {
    final parts = timeOfDay.split(':');
    if (parts.length < 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }

    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  List<int> _parseRepeatDays(dynamic raw) {
    if (raw is! List<dynamic>) {
      return const <int>[];
    }

    final result = <int>[];
    for (final item in raw) {
      final value = int.tryParse(item.toString());
      if (value == null) {
        continue;
      }
      result.add(_normalizeWeekday(value));
    }
    return result;
  }

  int _parseIntervalDays(dynamic raw) {
    final value = int.tryParse(raw?.toString() ?? '1') ?? 1;
    return value < 1 ? 1 : value;
  }

  int _normalizeWeekday(int weekday) {
    if (weekday == 0) {
      return DateTime.sunday;
    }
    if (weekday >= DateTime.monday && weekday <= DateTime.sunday) {
      return weekday;
    }

    final normalized = weekday % 7;
    return normalized == 0 ? DateTime.sunday : normalized;
  }

  List<DateTime> _buildOccurrenceDays({
    required DateTime startDate,
    required String repeatType,
    required List<int> repeatDays,
    required int intervalDays,
    required DateTime firstDay,
    required DateTime lastDay,
  }) {
    final scheduleDate = _startOfDay(startDate);
    if (scheduleDate.isAfter(lastDay)) {
      return const <DateTime>[];
    }

    final begin = scheduleDate.isAfter(firstDay) ? scheduleDate : firstDay;
    final days = <DateTime>[];

    for (
      var day = begin;
      !day.isAfter(lastDay);
      day = day.add(const Duration(days: 1))
    ) {
      if (_isScheduledOnDay(
        day: day,
        scheduleDate: scheduleDate,
        repeatType: repeatType,
        repeatDays: repeatDays,
        intervalDays: intervalDays,
      )) {
        days.add(day);
      }
    }

    return days;
  }

  bool _isScheduledOnDay({
    required DateTime day,
    required DateTime scheduleDate,
    required String repeatType,
    required List<int> repeatDays,
    required int intervalDays,
  }) {
    if (day.isBefore(scheduleDate)) {
      return false;
    }

    switch (repeatType) {
      case 'weekly':
        if (repeatDays.isNotEmpty) {
          return repeatDays.contains(day.weekday);
        }
        return day.weekday == scheduleDate.weekday;
      case 'interval':
        final delta = day.difference(scheduleDate).inDays;
        return delta % intervalDays == 0;
      case 'daily':
      default:
        return true;
    }
  }

  String _dateTimeKey(DateTime value) {
    return value.toUtc().millisecondsSinceEpoch.toString();
  }
}

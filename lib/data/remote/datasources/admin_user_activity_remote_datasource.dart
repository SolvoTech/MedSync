import '../../../core/constants/type_labels.dart';
import '../supabase_client.dart';

class AdminActivityRange {
  const AdminActivityRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

enum AdminActivityPeriod { today, last7Days, last30Days }

extension AdminActivityPeriodRange on AdminActivityPeriod {
  AdminActivityRange toRange(DateTime now) {
    final end = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));

    switch (this) {
      case AdminActivityPeriod.today:
        return AdminActivityRange(
          start: end.subtract(const Duration(days: 1)),
          end: end,
        );
      case AdminActivityPeriod.last7Days:
        return AdminActivityRange(
          start: end.subtract(const Duration(days: 7)),
          end: end,
        );
      case AdminActivityPeriod.last30Days:
        return AdminActivityRange(
          start: end.subtract(const Duration(days: 30)),
          end: end,
        );
    }
  }
}

class AdminAdherenceStat {
  const AdminAdherenceStat({required this.done, required this.total});

  final int done;
  final int total;

  int get percent => total == 0 ? 0 : ((done / total) * 100).round();
}

class AdminUserProfileSnapshot {
  const AdminUserProfileSnapshot({
    required this.id,
    required this.fullName,
    required this.username,
    required this.role,
    required this.accountStatus,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String username;
  final String role;
  final String accountStatus;
  final DateTime? createdAt;

  factory AdminUserProfileSnapshot.fromMap(Map<String, dynamic> map) {
    final rawCreatedAt = map['created_at'];
    final createdAt = rawCreatedAt is String
        ? DateTime.tryParse(rawCreatedAt)
        : rawCreatedAt is DateTime
        ? rawCreatedAt
        : null;

    return AdminUserProfileSnapshot(
      id: map['id'] as String,
      fullName: (map['full_name'] as String?) ?? '-',
      username: (map['username'] as String?) ?? '-',
      role: (map['role'] as String?) ?? 'user',
      accountStatus: (map['account_status'] as String?) ?? 'active',
      createdAt: createdAt,
    );
  }
}

class AdminMedicineScheduleActivity {
  const AdminMedicineScheduleActivity({
    required this.scheduleId,
    required this.medicineName,
    required this.scheduleName,
    required this.repeatType,
    required this.startDate,
    required this.isActive,
    required this.timeSlots,
    required this.adherence,
  });

  final String scheduleId;
  final String medicineName;
  final String? scheduleName;
  final String repeatType;
  final DateTime startDate;
  final bool isActive;
  final List<String> timeSlots;
  final AdminAdherenceStat adherence;
}

class AdminMeasurementScheduleActivity {
  const AdminMeasurementScheduleActivity({
    required this.reminderId,
    required this.measurementType,
    required this.customName,
    required this.timeOfDay,
    required this.startDate,
    required this.repeatType,
    required this.isActive,
    required this.adherence,
  });

  final String reminderId;
  final String measurementType;
  final String? customName;
  final String timeOfDay;
  final DateTime startDate;
  final String repeatType;
  final bool isActive;
  final AdminAdherenceStat adherence;

  String get displayName {
    final custom = customName?.trim();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    return measurementTypeLabel(measurementType);
  }
}

class AdminActivityScheduleActivity {
  const AdminActivityScheduleActivity({
    required this.reminderId,
    required this.activityType,
    required this.customName,
    required this.timeOfDay,
    required this.startDate,
    required this.repeatType,
    required this.isActive,
    required this.adherence,
  });

  final String reminderId;
  final String activityType;
  final String? customName;
  final String timeOfDay;
  final DateTime startDate;
  final String repeatType;
  final bool isActive;
  final AdminAdherenceStat adherence;

  String get displayName {
    final custom = customName?.trim();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    return activityTypeLabel(activityType);
  }
}

class AdminUserActivityData {
  const AdminUserActivityData({
    required this.user,
    required this.period,
    required this.overall,
    required this.medicine,
    required this.measurement,
    required this.activity,
    required this.medicineSchedules,
    required this.measurementSchedules,
    required this.activitySchedules,
    required this.rangeStart,
    required this.rangeEnd,
    required this.fetchedAt,
  });

  final AdminUserProfileSnapshot user;
  final AdminActivityPeriod period;
  final AdminAdherenceStat overall;
  final AdminAdherenceStat medicine;
  final AdminAdherenceStat measurement;
  final AdminAdherenceStat activity;
  final List<AdminMedicineScheduleActivity> medicineSchedules;
  final List<AdminMeasurementScheduleActivity> measurementSchedules;
  final List<AdminActivityScheduleActivity> activitySchedules;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final DateTime fetchedAt;
}

class AdminUserActivityRemoteDataSource {
  Future<AdminUserActivityData> getUserActivity({
    required String userId,
    required AdminActivityPeriod period,
  }) async {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      throw Exception('Supabase belum diinisialisasi.');
    }

    final currentUser = client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    final now = DateTime.now();
    final range = period.toRange(now);

    final profileFuture = client
        .from('profiles')
        .select('id, full_name, username, role, account_status, created_at')
        .eq('id', userId)
        .single();

    final logsFuture = client
        .from('task_logs')
        .select('task_type, reference_id, status')
        .eq('owner_id', userId)
        .gte('scheduled_at', range.start.toIso8601String())
        .lt('scheduled_at', range.end.toIso8601String());

    final medicinesFuture = client
        .from('medicines')
        .select('id, name')
        .eq('owner_id', userId);

    final medicineSchedulesFuture = client
        .from('medicine_schedules')
        .select(
          'id, medicine_id, schedule_name, repeat_type, start_date, is_active',
        )
        .eq('owner_id', userId)
        .order('created_at', ascending: false);

    final measurementFuture = client
        .from('measurement_reminders')
        .select(
          'id, measurement_type, custom_name, time_of_day, start_date, repeat_type, is_active',
        )
        .eq('owner_id', userId)
        .order('time_of_day', ascending: true);

    final activityFuture = client
        .from('physical_activity_reminders')
        .select(
          'id, activity_type, custom_name, time_of_day, start_date, repeat_type, is_active',
        )
        .eq('owner_id', userId)
        .order('time_of_day', ascending: true);

    final profileRow = await profileFuture;
    final logRowsResponse = await logsFuture;
    final medicinesResponse = await medicinesFuture;
    final medicineSchedulesResponse = await medicineSchedulesFuture;
    final measurementResponse = await measurementFuture;
    final activityResponse = await activityFuture;

    final profile = AdminUserProfileSnapshot.fromMap(profileRow);

    final logRows = (logRowsResponse as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final statsByRef = _buildStatsByReference(logRows);

    final byType = _aggregateByType(statsByRef);

    final medicines = (medicinesResponse as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final medicineNameById = {
      for (final row in medicines)
        if (row['id'] is String)
          row['id'] as String: (row['name'] as String?) ?? '-',
    };

    final scheduleRows = (medicineSchedulesResponse as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final scheduleIds = scheduleRows
        .map((row) => row['id'])
        .whereType<String>()
        .toList();

    final slotsBySchedule = <String, List<String>>{};
    if (scheduleIds.isNotEmpty) {
      final slotRows = await client
          .from('schedule_time_slots')
          .select('schedule_id, time_of_day')
          .inFilter('schedule_id', scheduleIds)
          .order('time_of_day', ascending: true);

      for (final row in (slotRows as List<dynamic>)) {
        final map = row as Map<String, dynamic>;
        final scheduleId = map['schedule_id'] as String?;
        final time = map['time_of_day']?.toString();
        if (scheduleId == null || time == null || time.isEmpty) {
          continue;
        }
        slotsBySchedule.putIfAbsent(scheduleId, () => <String>[]).add(time);
      }
    }

    final medicineSchedules = scheduleRows
        .map((row) {
          final scheduleId = row['id'] as String;
          final medicineId = row['medicine_id'] as String?;
          final startDate = DateTime.tryParse(
            row['start_date']?.toString() ?? '',
          );
          if (startDate == null) {
            return null;
          }

          return AdminMedicineScheduleActivity(
            scheduleId: scheduleId,
            medicineName: medicineNameById[medicineId] ?? '-',
            scheduleName: row['schedule_name'] as String?,
            repeatType: (row['repeat_type'] as String?) ?? 'daily',
            startDate: startDate,
            isActive: (row['is_active'] as bool?) ?? true,
            timeSlots: List<String>.from(
              slotsBySchedule[scheduleId] ?? const <String>[],
            ),
            adherence:
                statsByRef['medicine|$scheduleId'] ??
                const AdminAdherenceStat(done: 0, total: 0),
          );
        })
        .whereType<AdminMedicineScheduleActivity>()
        .toList();

    final measurementSchedules =
        (measurementResponse as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((row) {
              final reminderId = row['id'] as String;
              final startDate = DateTime.tryParse(
                row['start_date']?.toString() ?? '',
              );
              if (startDate == null) {
                return null;
              }

              return AdminMeasurementScheduleActivity(
                reminderId: reminderId,
                measurementType:
                    (row['measurement_type'] as String?) ?? 'unknown',
                customName: row['custom_name'] as String?,
                timeOfDay: (row['time_of_day'] as String?) ?? '-',
                startDate: startDate,
                repeatType: (row['repeat_type'] as String?) ?? 'daily',
                isActive: (row['is_active'] as bool?) ?? true,
                adherence:
                    statsByRef['measurement|$reminderId'] ??
                    const AdminAdherenceStat(done: 0, total: 0),
              );
            })
            .whereType<AdminMeasurementScheduleActivity>()
            .toList()
          ..sort((a, b) => a.timeOfDay.compareTo(b.timeOfDay));

    final activitySchedules =
        (activityResponse as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((row) {
              final reminderId = row['id'] as String;
              final startDate = DateTime.tryParse(
                row['start_date']?.toString() ?? '',
              );
              if (startDate == null) {
                return null;
              }

              return AdminActivityScheduleActivity(
                reminderId: reminderId,
                activityType: (row['activity_type'] as String?) ?? 'unknown',
                customName: row['custom_name'] as String?,
                timeOfDay: (row['time_of_day'] as String?) ?? '-',
                startDate: startDate,
                repeatType: (row['repeat_type'] as String?) ?? 'daily',
                isActive: (row['is_active'] as bool?) ?? true,
                adherence:
                    statsByRef['physical_activity|$reminderId'] ??
                    const AdminAdherenceStat(done: 0, total: 0),
              );
            })
            .whereType<AdminActivityScheduleActivity>()
            .toList()
          ..sort((a, b) => a.timeOfDay.compareTo(b.timeOfDay));

    return AdminUserActivityData(
      user: profile,
      period: period,
      overall: _sumStats(statsByRef.values),
      medicine:
          byType['medicine'] ?? const AdminAdherenceStat(done: 0, total: 0),
      measurement:
          byType['measurement'] ?? const AdminAdherenceStat(done: 0, total: 0),
      activity:
          byType['physical_activity'] ??
          const AdminAdherenceStat(done: 0, total: 0),
      medicineSchedules: medicineSchedules,
      measurementSchedules: measurementSchedules,
      activitySchedules: activitySchedules,
      rangeStart: range.start,
      rangeEnd: range.end,
      fetchedAt: now,
    );
  }

  Map<String, AdminAdherenceStat> _buildStatsByReference(
    List<Map<String, dynamic>> rows,
  ) {
    final totalByKey = <String, int>{};
    final doneByKey = <String, int>{};

    for (final row in rows) {
      final taskType = row['task_type']?.toString();
      final referenceId = row['reference_id']?.toString();
      if (taskType == null ||
          taskType.isEmpty ||
          referenceId == null ||
          referenceId.isEmpty) {
        continue;
      }

      final key = '$taskType|$referenceId';
      totalByKey[key] = (totalByKey[key] ?? 0) + 1;
      if (row['status']?.toString() == 'done') {
        doneByKey[key] = (doneByKey[key] ?? 0) + 1;
      }
    }

    final result = <String, AdminAdherenceStat>{};
    for (final entry in totalByKey.entries) {
      result[entry.key] = AdminAdherenceStat(
        done: doneByKey[entry.key] ?? 0,
        total: entry.value,
      );
    }
    return result;
  }

  Map<String, AdminAdherenceStat> _aggregateByType(
    Map<String, AdminAdherenceStat> statsByReference,
  ) {
    final doneByType = <String, int>{};
    final totalByType = <String, int>{};

    for (final entry in statsByReference.entries) {
      final parts = entry.key.split('|');
      if (parts.isEmpty) {
        continue;
      }
      final type = parts.first;
      doneByType[type] = (doneByType[type] ?? 0) + entry.value.done;
      totalByType[type] = (totalByType[type] ?? 0) + entry.value.total;
    }

    final result = <String, AdminAdherenceStat>{};
    for (final entry in totalByType.entries) {
      result[entry.key] = AdminAdherenceStat(
        done: doneByType[entry.key] ?? 0,
        total: entry.value,
      );
    }
    return result;
  }

  AdminAdherenceStat _sumStats(Iterable<AdminAdherenceStat> stats) {
    var total = 0;
    var done = 0;

    for (final item in stats) {
      total += item.total;
      done += item.done;
    }

    return AdminAdherenceStat(done: done, total: total);
  }
}

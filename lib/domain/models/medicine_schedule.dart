class MedicineSchedule {
  const MedicineSchedule({
    required this.id,
    required this.medicineId,
    required this.ownerId,
    required this.startDate,
    required this.repeatType,
    this.scheduleName,
    this.endDate,
    this.repeatDays,
    this.intervalDays = 1,
    this.isActive = true,
  });

  final String id;
  final String medicineId;
  final String ownerId;
  final String? scheduleName;
  final String repeatType;
  final DateTime startDate;
  final DateTime? endDate;
  final List<int>? repeatDays;
  final int intervalDays;
  final bool isActive;

  factory MedicineSchedule.fromMap(Map<String, dynamic> map) {
    return MedicineSchedule(
      id: map['id'] as String,
      medicineId: map['medicine_id'] as String,
      ownerId: map['owner_id'] as String,
      scheduleName: map['schedule_name'] as String?,
      repeatType: (map['repeat_type'] as String?) ?? 'daily',
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] == null
          ? null
          : DateTime.tryParse(map['end_date'] as String),
      repeatDays: (map['repeat_days'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      intervalDays: (map['interval_days'] as num?)?.toInt() ?? 1,
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }
}

class ScheduleTimeSlot {
  const ScheduleTimeSlot({
    required this.id,
    required this.scheduleId,
    required this.timeOfDay,
    this.dosageAmount = 1,
    this.dosageUnit = 'tablet',
    this.withFood = false,
    this.notificationEnabled = true,
    this.notificationBeforeMinutes = 0,
    this.followupEnabled = false,
    this.followupAfterMinutes = 15,
    this.notes,
  });

  final String id;
  final String scheduleId;
  final String timeOfDay;
  final num dosageAmount;
  final String dosageUnit;
  final bool withFood;
  final bool notificationEnabled;
  final int notificationBeforeMinutes;
  final bool followupEnabled;
  final int followupAfterMinutes;
  final String? notes;

  factory ScheduleTimeSlot.fromMap(Map<String, dynamic> map) {
    return ScheduleTimeSlot(
      id: map['id'] as String,
      scheduleId: map['schedule_id'] as String,
      timeOfDay: map['time_of_day'] as String,
      dosageAmount: (map['dosage_amount'] as num?) ?? 1,
      dosageUnit: (map['dosage_unit'] as String?) ?? 'tablet',
      withFood: (map['with_food'] as bool?) ?? false,
      notificationEnabled: (map['notification_enabled'] as bool?) ?? true,
      notificationBeforeMinutes:
          (map['notification_before_minutes'] as num?)?.toInt() ?? 0,
      followupEnabled: (map['followup_enabled'] as bool?) ?? false,
      followupAfterMinutes:
          (map['followup_after_minutes'] as num?)?.toInt() ?? 15,
      notes: map['notes'] as String?,
    );
  }
}

class MedicineScheduleBundle {
  const MedicineScheduleBundle({required this.schedule, required this.slots});

  final MedicineSchedule schedule;
  final List<ScheduleTimeSlot> slots;
}

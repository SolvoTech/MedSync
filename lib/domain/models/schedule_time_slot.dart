class ScheduleTimeSlot {
  const ScheduleTimeSlot({
    required this.id,
    required this.scheduleId,
    required this.time,
    this.dosageAmount = 1,
    this.followupEnabled = false,
    this.followupAfterMinutes = 15,
  });

  final String id;
  final String scheduleId;
  final String time; // HH:mm format
  final int dosageAmount;
  final bool followupEnabled;
  final int followupAfterMinutes;

  factory ScheduleTimeSlot.fromMap(Map<String, dynamic> map) {
    return ScheduleTimeSlot(
      id: map['id'] as String,
      scheduleId: map['schedule_id'] as String,
      time: map['time'] as String,
      dosageAmount: (map['dosage_amount'] as num?)?.toInt() ?? 1,
      followupEnabled: (map['followup_enabled'] as bool?) ?? false,
      followupAfterMinutes:
          (map['followup_after_minutes'] as num?)?.toInt() ?? 15,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'schedule_id': scheduleId,
      'time': time,
      'dosage_amount': dosageAmount,
      'followup_enabled': followupEnabled,
      'followup_after_minutes': followupAfterMinutes,
    };
  }

  ScheduleTimeSlot copyWith({
    String? time,
    int? dosageAmount,
    bool? followupEnabled,
    int? followupAfterMinutes,
  }) {
    return ScheduleTimeSlot(
      id: id,
      scheduleId: scheduleId,
      time: time ?? this.time,
      dosageAmount: dosageAmount ?? this.dosageAmount,
      followupEnabled: followupEnabled ?? this.followupEnabled,
      followupAfterMinutes: followupAfterMinutes ?? this.followupAfterMinutes,
    );
  }
}

class PhysicalActivityReminder {
  const PhysicalActivityReminder({
    required this.id,
    required this.ownerId,
    required this.activityType,
    required this.timeOfDay,
    required this.startDate,
    this.customName,
    this.targetUnit,
    this.targetValue,
    this.isActive = true,
  });

  final String id;
  final String ownerId;
  final String activityType;
  final String? customName;
  final String timeOfDay;
  final DateTime startDate;
  final String? targetUnit;
  final num? targetValue;
  final bool isActive;

  factory PhysicalActivityReminder.fromMap(Map<String, dynamic> map) {
    return PhysicalActivityReminder(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      activityType: map['activity_type'] as String,
      customName: map['custom_name'] as String?,
      timeOfDay: map['time_of_day'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      targetUnit: map['target_unit'] as String?,
      targetValue: map['target_value'] as num?,
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }
}

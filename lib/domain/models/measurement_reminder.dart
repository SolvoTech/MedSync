class MeasurementReminder {
  const MeasurementReminder({
    required this.id,
    required this.ownerId,
    required this.measurementType,
    required this.timeOfDay,
    required this.startDate,
    this.customName,
    this.unit,
    this.targetValue,
    this.carePersonId,
    this.isActive = true,
  });

  final String id;
  final String ownerId;
  final String measurementType;
  final String? customName;
  final String timeOfDay;
  final DateTime startDate;
  final String? unit;
  final String? targetValue;
  final String? carePersonId;
  final bool isActive;

  factory MeasurementReminder.fromMap(Map<String, dynamic> map) {
    return MeasurementReminder(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      measurementType: map['measurement_type'] as String,
      customName: map['custom_name'] as String?,
      timeOfDay: map['time_of_day'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      unit: map['unit'] as String?,
      targetValue: map['target_value'] as String?,
      carePersonId: map['care_person_id'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }
}

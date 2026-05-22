class MeasurementLog {
  const MeasurementLog({
    required this.id,
    required this.reminderId,
    required this.ownerId,
    required this.value,
    this.unit,
    this.notes,
    required this.measuredAt,
  });

  final String id;
  final String reminderId;
  final String ownerId;
  final double value;
  final String? unit;
  final String? notes;
  final DateTime measuredAt;

  factory MeasurementLog.fromMap(Map<String, dynamic> map) {
    return MeasurementLog(
      id: map['id'] as String,
      reminderId: map['reminder_id'] as String,
      ownerId: map['owner_id'] as String,
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] as String?,
      notes: map['notes'] as String?,
      measuredAt: DateTime.parse(map['measured_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'reminder_id': reminderId,
      'owner_id': ownerId,
      'value': value,
      'unit': unit,
      'notes': notes,
      'measured_at': measuredAt.toIso8601String(),
    };
  }
}

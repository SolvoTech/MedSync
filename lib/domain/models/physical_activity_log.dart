class PhysicalActivityLog {
  const PhysicalActivityLog({
    required this.id,
    required this.reminderId,
    required this.ownerId,
    required this.durationMinutes,
    this.distanceKm,
    this.caloriesBurned,
    this.notes,
    required this.completedAt,
    this.carePersonId,
  });

  final String id;
  final String reminderId;
  final String ownerId;
  final int durationMinutes;
  final double? distanceKm;
  final int? caloriesBurned;
  final String? notes;
  final DateTime completedAt;
  final String? carePersonId;

  factory PhysicalActivityLog.fromMap(Map<String, dynamic> map) {
    return PhysicalActivityLog(
      id: map['id'] as String,
      reminderId: map['reminder_id'] as String,
      ownerId: map['owner_id'] as String,
      durationMinutes: (map['duration_minutes'] as num).toInt(),
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      caloriesBurned: (map['calories_burned'] as num?)?.toInt(),
      notes: map['notes'] as String?,
      completedAt: DateTime.parse(map['completed_at'] as String),
      carePersonId: map['care_person_id'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'reminder_id': reminderId,
      'owner_id': ownerId,
      'duration_minutes': durationMinutes,
      'distance_km': distanceKm,
      'calories_burned': caloriesBurned,
      'notes': notes,
      'completed_at': completedAt.toIso8601String(),
      'care_person_id': carePersonId,
    };
  }
}

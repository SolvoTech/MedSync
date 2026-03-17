class UserStreak {
  const UserStreak({
    required this.id,
    required this.ownerId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
    this.streakStartDate,
  });

  final String id;
  final String ownerId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;
  final DateTime? streakStartDate;

  factory UserStreak.fromMap(Map<String, dynamic> map) {
    return UserStreak(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      currentStreak: (map['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longest_streak'] as num?)?.toInt() ?? 0,
      lastCompletedDate: map['last_completed_date'] == null
          ? null
          : DateTime.tryParse(map['last_completed_date'] as String),
      streakStartDate: map['streak_start_date'] == null
          ? null
          : DateTime.tryParse(map['streak_start_date'] as String),
    );
  }

  /// Motivational message based on streak
  String get motivationMessage {
    if (currentStreak == 0) return 'Mulai hari pertamamu hari ini!';
    if (currentStreak < 7) return 'Bagus! Pertahankan!';
    return 'Luar biasa! $currentStreak hari berturut-turut!';
  }
}

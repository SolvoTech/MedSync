class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    this.birthDate,
    this.avatarUrl,
    this.themeMode = 'system',
  });

  final String id;
  final String fullName;
  final DateTime? birthDate;
  final String? avatarUrl;
  final String themeMode;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      birthDate: map['birth_date'] == null
          ? null
          : DateTime.tryParse(map['birth_date'] as String),
      avatarUrl: map['avatar_url'] as String?,
      themeMode: (map['theme_mode'] as String?) ?? 'system',
    );
  }
}

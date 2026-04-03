class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    this.username,
    this.birthDate,
    this.avatarUrl,
    this.themeMode = 'system',
    this.role = 'user',
    this.accountStatus = 'active',
    this.internalEmail,
  });

  final String id;
  final String fullName;
  final String? username;
  final DateTime? birthDate;
  final String? avatarUrl;
  final String themeMode;
  final String role;
  final String accountStatus;
  final String? internalEmail;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      username: map['username'] as String?,
      birthDate: map['birth_date'] == null
          ? null
          : DateTime.tryParse(map['birth_date'] as String),
      avatarUrl: map['avatar_url'] as String?,
      themeMode: (map['theme_mode'] as String?) ?? 'system',
      role: (map['role'] as String?) ?? 'user',
      accountStatus: (map['account_status'] as String?) ?? 'active',
      internalEmail: map['internal_email'] as String?,
    );
  }
}

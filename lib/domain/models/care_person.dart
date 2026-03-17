class CarePerson {
  const CarePerson({
    required this.id,
    required this.ownerId,
    required this.displayName,
    this.relationship,
    this.birthDate,
    this.notes,
    this.avatarColor,
  });

  final String id;
  final String ownerId;
  final String displayName;
  final String? relationship;
  final DateTime? birthDate;
  final String? notes;
  final String? avatarColor;

  factory CarePerson.fromMap(Map<String, dynamic> map) {
    return CarePerson(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      displayName: map['display_name'] as String,
      relationship: map['relationship'] as String?,
      birthDate: map['birth_date'] == null
          ? null
          : DateTime.tryParse(map['birth_date'] as String),
      notes: map['notes'] as String?,
      avatarColor: map['avatar_color'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'owner_id': ownerId,
      'display_name': displayName,
      'relationship': relationship,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'notes': notes,
      'avatar_color': avatarColor,
    };
  }
}

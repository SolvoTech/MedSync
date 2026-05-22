class Medicine {
  const Medicine({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.medicineType,
    required this.stockCurrent,
    required this.stockUnit,
    this.dosage,
    this.stockLowThreshold = 5,
    this.stockReminderAt = 3,
    this.notes,
    this.color,
    this.icon,
    this.photoUrl,
    this.isActive = true,
  });

  final String id;
  final String ownerId;
  final String name;
  final String? dosage;
  final String medicineType;
  final int stockCurrent;
  final String stockUnit;
  final int stockLowThreshold;
  final int stockReminderAt;
  final String? notes;
  final String? color;
  final String? icon;
  final String? photoUrl;
  final bool isActive;

  bool get isStockLow => stockCurrent <= stockLowThreshold;
  bool get needsStockReminder => stockCurrent <= stockReminderAt;

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      name: map['name'] as String,
      dosage: map['dosage'] as String?,
      medicineType: (map['medicine_type'] as String?) ?? 'tablet',
      stockCurrent: (map['stock_current'] as num?)?.toInt() ?? 0,
      stockUnit: (map['stock_unit'] as String?) ?? 'tablet',
      stockLowThreshold: (map['stock_low_threshold'] as num?)?.toInt() ?? 5,
      stockReminderAt: (map['stock_reminder_at'] as num?)?.toInt() ?? 3,
      notes: map['notes'] as String?,
      color: map['color'] as String?,
      icon: map['icon'] as String?,
      photoUrl: map['photo_url'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'owner_id': ownerId,
      'name': name,
      'dosage': dosage,
      'medicine_type': medicineType,
      'stock_current': stockCurrent,
      'stock_unit': stockUnit,
      'stock_low_threshold': stockLowThreshold,
      'stock_reminder_at': stockReminderAt,
      'notes': notes,
      'color': color,
      'icon': icon,
      'photo_url': photoUrl,
      'is_active': isActive,
    };
  }
}

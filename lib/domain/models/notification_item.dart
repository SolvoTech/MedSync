class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.ownerId,
    required this.notificationType,
    required this.title,
    required this.body,
    required this.scheduledAt,
    this.referenceId,
    this.referenceType,
    this.isRead = false,
    this.actionTaken,
    this.deliveredAt,
    this.createdAt,
  });

  final String id;
  final String ownerId;
  final String notificationType;
  final String title;
  final String body;
  final String? referenceId;
  final String? referenceType;
  final bool isRead;
  final String? actionTaken;
  final DateTime scheduledAt;
  final DateTime? deliveredAt;
  final DateTime? createdAt;

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      notificationType: map['notification_type'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      referenceId: map['reference_id'] as String?,
      referenceType: map['reference_type'] as String?,
      isRead: (map['is_read'] as bool?) ?? false,
      actionTaken: map['action_taken'] as String?,
      scheduledAt: DateTime.parse(map['scheduled_at'] as String),
      deliveredAt: map['delivered_at'] == null
          ? null
          : DateTime.tryParse(map['delivered_at'] as String),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
    );
  }
}

// lib/features/notifications/data/models/notification_log_model.dart
class NotificationLogModel {
  final String id;
  final String title;
  final String body;
  final String notifType;
  final String? referenceType; // 'reminder' | 'cattle' | null
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationLogModel({
    required this.id,
    required this.title,
    required this.body,
    required this.notifType,
    this.referenceType,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationLogModel.fromJson(Map<String, dynamic> j) => NotificationLogModel(
        id: j['id'],
        title: j['title'],
        body: j['body'],
        notifType: j['notif_type'] ?? 'other',
        referenceType: j['reference_type'],
        referenceId: j['reference_id'],
        isRead: j['is_read'] ?? false,
        createdAt: DateTime.parse(j['created_at']),
      );

  NotificationLogModel copyWith({bool? isRead}) => NotificationLogModel(
        id: id,
        title: title,
        body: body,
        notifType: notifType,
        referenceType: referenceType,
        referenceId: referenceId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}

// lib/features/notifications/data/models/reminder_model.dart
//
// Modelo de recordatorio (reminder) que refleja EXACTAMENTE el schema
// ReminderResponse del backend (core-service/src/schemas/reminder.py).

/// Tipos de recordatorio permitidos por el backend (pattern regex).
/// Debe coincidir 1:1 con ReminderBase.reminder_type en el backend.
enum ReminderType {
  vaccine,
  checkup,
  treatment,
  feeding,
  breeding,
  other;

  String get api => name;

  static ReminderType fromApi(String value) {
    return ReminderType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => ReminderType.other,
    );
  }

  String get display {
    switch (this) {
      case ReminderType.vaccine:
        return 'Vacuna';
      case ReminderType.checkup:
        return 'Chequeo';
      case ReminderType.treatment:
        return 'Tratamiento';
      case ReminderType.feeding:
        return 'Alimentación';
      case ReminderType.breeding:
        return 'Celo / Reproducción';
      case ReminderType.other:
        return 'Otro';
    }
  }
}

enum ReminderStatus {
  pending,
  completed,
  cancelled;

  String get api => name;

  static ReminderStatus fromApi(String value) {
    return ReminderStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => ReminderStatus.pending,
    );
  }
}

class ReminderModel {
  final String id;
  final String? cattleId;
  final String? userId;
  final String title;
  final String? description;
  final DateTime reminderDate;
  final ReminderType type;
  final ReminderStatus status;
  final String? healthEventId;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReminderModel({
    required this.id,
    this.cattleId,
    this.userId,
    required this.title,
    this.description,
    required this.reminderDate,
    required this.type,
    required this.status,
    this.healthEventId,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id']?.toString() ?? '',
      cattleId: json['cattle_id']?.toString(),
      userId: json['user_id']?.toString(),
      title: json['title'] ?? '',
      description: json['description'],
      reminderDate: DateTime.parse(json['reminder_date']),
      type: ReminderType.fromApi(json['reminder_type'] ?? 'other'),
      status: ReminderStatus.fromApi(json['status'] ?? 'pending'),
      healthEventId: json['health_event_id']?.toString(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// Para crear un recordatorio (POST). Solo campos permitidos por ReminderBase.
  Map<String, dynamic> toCreateJson() {
    return {
      if (cattleId != null) 'cattle_id': cattleId,
      'title': title,
      if (description != null) 'description': description,
      'reminder_date': _formatDate(reminderDate),
      'reminder_type': type.api,
    };
  }

  bool get isPending => status == ReminderStatus.pending;
  bool get isCompleted => status == ReminderStatus.completed;
  bool get isCancelled => status == ReminderStatus.cancelled;

  /// Está vencido si es pending y su fecha ya pasó.
  bool get isOverdue {
    if (!isPending) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rem = DateTime(reminderDate.year, reminderDate.month, reminderDate.day);
    return rem.isBefore(today);
  }

  /// Es de hoy si su fecha es la fecha actual (independiente del status).
  bool get isToday {
    final now = DateTime.now();
    return reminderDate.year == now.year &&
        reminderDate.month == now.month &&
        reminderDate.day == now.day;
  }

  /// Formato YYYY-MM-DD que espera el backend.
  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  ReminderModel copyWith({
    ReminderStatus? status,
    DateTime? completedAt,
  }) =>
      ReminderModel(
        id: id,
        cattleId: cattleId,
        userId: userId,
        title: title,
        description: description,
        reminderDate: reminderDate,
        type: type,
        status: status ?? this.status,
        healthEventId: healthEventId,
        completedAt: completedAt ?? this.completedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

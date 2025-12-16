// lib/features/cattle/data/models/health_event_model.dart

class HealthEventModel {
  final String? id;
  final String cattleId;
  final String eventType; // vaccine, treatment, checkup, surgery, injury, illness, other
  final String? diseaseName;
  final String? medicineName;
  final DateTime applicationDate;
  final String administrationRoute; // oral, intramuscular, subcutaneous, intravenous, topical, other
  final String? dosage;
  final String? veterinarianName;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HealthEventModel({
    this.id,
    required this.cattleId,
    required this.eventType,
    this.diseaseName,
    this.medicineName,
    required this.applicationDate,
    required this.administrationRoute,
    this.dosage,
    this.veterinarianName,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory HealthEventModel.fromJson(Map<String, dynamic> json) {
    return HealthEventModel(
      id: json['id'],
      cattleId: json['cattle_id'],
      eventType: json['event_type'],
      diseaseName: json['disease_name'],
      medicineName: json['medicine_name'],
      applicationDate: DateTime.parse(json['application_date']),
      administrationRoute: json['administration_route'],
      dosage: json['dosage'],
      veterinarianName: json['veterinarian_name'],
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cattle_id': cattleId,
      'event_type': eventType,
      if (diseaseName != null) 'disease_name': diseaseName,
      if (medicineName != null) 'medicine_name': medicineName,
      'application_date': applicationDate.toIso8601String().split('T')[0],
      'administration_route': administrationRoute,
      if (dosage != null) 'dosage': dosage,
      if (veterinarianName != null) 'veterinarian_name': veterinarianName,
      if (notes != null) 'notes': notes,
    };
  }

  // Formatear fecha para UI
  String get formattedDate {
    return '${applicationDate.day.toString().padLeft(2, '0')}/${applicationDate.month.toString().padLeft(2, '0')}/${applicationDate.year}';
  }

  // Traducción de tipos de evento
  String get eventTypeSpanish {
    const Map<String, String> translations = {
      'vaccine': 'Vacuna',
      'treatment': 'Tratamiento',
      'checkup': 'Chequeo',
      'surgery': 'Cirugía',
      'injury': 'Lesión',
      'illness': 'Enfermedad',
      'other': 'Otro',
    };
    return translations[eventType] ?? eventType;
  }

  // Traducción de rutas de administración
  String get administrationRouteSpanish {
    const Map<String, String> translations = {
      'oral': 'Oral',
      'intramuscular': 'Intramuscular',
      'subcutaneous': 'Subcutánea',
      'intravenous': 'Intravenosa',
      'topical': 'Tópica',
      'other': 'Otra',
    };
    return translations[administrationRoute] ?? administrationRoute;
  }
}

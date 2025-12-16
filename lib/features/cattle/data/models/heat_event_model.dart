// lib/features/cattle/data/models/heat_event_model.dart

class HeatEventModel {
  final String? id;
  final String cattleId;
  final DateTime heatDate;
  final bool allowsMounting;
  final String vaginalDischarge;
  final String vulvaSwelling;
  final String comportamiento;
  final bool wasInseminated;
  final DateTime? inseminationDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HeatEventModel({
    this.id,
    required this.cattleId,
    required this.heatDate,
    required this.allowsMounting,
    required this.vaginalDischarge,
    required this.vulvaSwelling,
    required this.comportamiento,
    required this.wasInseminated,
    this.inseminationDate,
    this.createdAt,
    this.updatedAt,
  });

  factory HeatEventModel.fromJson(Map<String, dynamic> json) {
    return HeatEventModel(
      id: json['id'],
      cattleId: json['cattle_id'],
      heatDate: DateTime.parse(json['heat_date']),
      allowsMounting: json['allows_mounting'],
      vaginalDischarge: json['vaginal_discharge'],
      vulvaSwelling: json['vulva_swelling'],
      comportamiento: json['comportamiento'],
      wasInseminated: json['was_inseminated'],
      inseminationDate: json['insemination_date'] != null
          ? DateTime.parse(json['insemination_date'])
          : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cattle_id': cattleId,
      'heat_date': heatDate.toIso8601String().split('T')[0],
      'allows_mounting': allowsMounting,
      'vaginal_discharge': vaginalDischarge,
      'vulva_swelling': vulvaSwelling,
      'comportamiento': comportamiento,
      'was_inseminated': wasInseminated,
      if (inseminationDate != null)
        'insemination_date': inseminationDate!.toIso8601String().split('T')[0],
    };
  }

  String get formattedHeatDate {
    return '${heatDate.day.toString().padLeft(2, '0')}/${heatDate.month.toString().padLeft(2, '0')}/${heatDate.year}';
  }

  String get formattedInseminationDate {
    if (inseminationDate == null) return 'Sin inseminar';
    return '${inseminationDate!.day.toString().padLeft(2, '0')}/${inseminationDate!.month.toString().padLeft(2, '0')}/${inseminationDate!.year}';
  }
}

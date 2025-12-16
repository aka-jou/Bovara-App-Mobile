// lib/features/cattle/data/models/cattle_model.dart (VERSIÓN FINAL)

class CattleModel {
  final String id;
  final String name;
  final String lote;
  final String breed;
  final String gender;
  final DateTime? birthDate;
  final double? weight;
  final DateTime? fechaUltimoParto;
  final String? clusterLabel; // 🆕 Viene del backend (opcional)
  final DateTime createdAt;
  final DateTime updatedAt;

  CattleModel({
    required this.id,
    required this.name,
    required this.lote,
    required this.breed,
    required this.gender,
    this.birthDate,
    this.weight,
    this.fechaUltimoParto,
    this.clusterLabel, // 🆕 OPCIONAL
    required this.createdAt,
    required this.updatedAt,
  });

  factory CattleModel.fromJson(Map<String, dynamic> json) {
    return CattleModel(
      id: json['id'],
      name: json['name'],
      lote: json['lote'],
      breed: json['breed'],
      gender: json['gender'],
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : null,
      weight: json['weight']?.toDouble(),
      fechaUltimoParto: json['fecha_ultimo_parto'] != null
          ? DateTime.parse(json['fecha_ultimo_parto'])
          : null,
      clusterLabel: json['cluster_label'], // 🆕
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lote': lote,
      'breed': breed,
      'gender': gender,
      if (birthDate != null)
        'birth_date': birthDate!.toIso8601String().split('T')[0],
      if (weight != null) 'weight': weight,
      if (fechaUltimoParto != null)
        'fecha_ultimo_parto': fechaUltimoParto!.toIso8601String().split('T')[0],
      // NO enviar cluster_label al crear (se calcula en backend)
    };
  }

  // Calcular edad
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int years = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      years--;
    }
    return years;
  }

  // 🆕 Calcular próximo celo (21 días después del último)
  DateTime? calculateNextHeat(DateTime? lastHeatDate) {
    if (lastHeatDate == null || gender != 'female') return null;
    return lastHeatDate.add(const Duration(days: 21));
  }

  // 🆕 Días hasta el próximo celo
  int? daysUntilNextHeat(DateTime? lastHeatDate) {
    final nextHeat = calculateNextHeat(lastHeatDate);
    if (nextHeat == null) return null;
    return nextHeat.difference(DateTime.now()).inDays;
  }

  // 🆕 Texto formateado del próximo celo
  String formattedNextHeat(DateTime? lastHeatDate) {
    final nextHeat = calculateNextHeat(lastHeatDate);
    if (nextHeat == null) return 'Sin registro';

    final days = daysUntilNextHeat(lastHeatDate);
    if (days == null) return 'Sin calcular';

    if (days < 0) {
      return 'Retrasado ${days.abs()} días';
    } else if (days == 0) {
      return 'Hoy';
    } else if (days <= 3) {
      return 'En $days días (${nextHeat.day}/${nextHeat.month})';
    } else {
      return '${nextHeat.day.toString().padLeft(2, '0')}/${nextHeat.month.toString().padLeft(2, '0')}/${nextHeat.year}';
    }
  }

  // 🆕 Calcular cluster de salud localmente
  String getHealthCluster(int eventos, int vacunas, int tratamientos, int enfermedades) {
    if (eventos <= 1) {
      return "Ganado Sano";
    } else if (vacunas >= 3 && tratamientos <= 1 && enfermedades == 0) {
      return "Mantenimiento Regular";
    } else if (enfermedades >= 2 || tratamientos >= 4) {
      return "Alta Atención Médica";
    } else if (tratamientos >= 2) {
      return "Ganado en Tratamiento";
    } else {
      return "Mantenimiento Regular";
    }
  }

  // 🆕 Color del cluster para UI
  String getClusterColor(String cluster) {
    switch (cluster) {
      case "Ganado Sano":
        return "#4CAF50"; // Verde
      case "Mantenimiento Regular":
        return "#2196F3"; // Azul
      case "Alta Atención Médica":
        return "#F44336"; // Rojo
      case "Ganado en Tratamiento":
        return "#FF9800"; // Naranja
      default:
        return "#9E9E9E"; // Gris
    }
  }

  // Formato de fecha para UI
  String get formattedBirthDate {
    if (birthDate == null) return 'Sin registro';
    return '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}';
  }

  String get formattedLastBirth {
    if (fechaUltimoParto == null) return 'Sin registro';
    return '${fechaUltimoParto!.day.toString().padLeft(2, '0')}/${fechaUltimoParto!.month.toString().padLeft(2, '0')}/${fechaUltimoParto!.year}';
  }

  String get tag {
    final lotCode = lote.split(' ').last;
    final number = id.substring(0, 3);
    return '#L$lotCode-$number';
  }
}

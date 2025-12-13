class CattleModel {
  final String id;
  final String name;
  final String lote;
  final String breed;
  final String gender;
  final DateTime? birthDate;
  final double? weight;
  final DateTime? fechaUltimoParto;
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
    required this.createdAt,
    required this.updatedAt,
  });

  // Desde JSON de la API
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
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Para enviar a la API
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

  // Formato de fecha para UI
  String get formattedBirthDate {
    if (birthDate == null) return 'Sin registro';
    return '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}';
  }

  String get formattedLastBirth {
    if (fechaUltimoParto == null) return 'Sin registro';
    return '${fechaUltimoParto!.day.toString().padLeft(2, '0')}/${fechaUltimoParto!.month.toString().padLeft(2, '0')}/${fechaUltimoParto!.year}';
  }

  // Tag formateado
  String get tag {
    final lotCode = lote.split(' ').last;
    final number = id.substring(0, 3);
    return '#L$lotCode-$number';
  }
}

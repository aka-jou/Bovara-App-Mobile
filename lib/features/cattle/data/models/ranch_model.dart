class RanchModel {
  final String id;
  final String name;
  final String location;
  final double sizeHectares;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int cattleCount;

  RanchModel({
    required this.id,
    required this.name,
    required this.location,
    required this.sizeHectares,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.cattleCount = 0,
  });

  factory RanchModel.fromJson(Map<String, dynamic> json) {
    return RanchModel(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      sizeHectares: (json['size_hectares'] as num).toDouble(),
      ownerId: json['owner_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      cattleCount: json['cattle_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'size_hectares': sizeHectares,
    };
  }
}

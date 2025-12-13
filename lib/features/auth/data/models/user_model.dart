class User {
  final String id;
  final String email;
  final String fullName;
  final bool isActive;
  final bool isSuperuser;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
    required this.isSuperuser,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      isActive: json['is_active'],
      isSuperuser: json['is_superuser'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'is_active': isActive,
      'is_superuser': isSuperuser,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

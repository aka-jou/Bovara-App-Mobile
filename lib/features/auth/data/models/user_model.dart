// lib/features/auth/data/models/user_model.dart

class User {
  final String id;
  final String email;
  final String fullName;
  final bool isActive;
  final bool isSuperuser;
  final DateTime? createdAt;
  final String? phone;
  final String? ranch;
  final String? role;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
    required this.isSuperuser,
    this.createdAt,
    this.phone,
    this.ranch,
    this.role,
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
      phone: json['phone'],
      ranch: json['ranch'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'is_active': isActive,
      'is_superuser': isSuperuser,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (phone != null) 'phone': phone,
      if (ranch != null) 'ranch': ranch,
      if (role != null) 'role': role,
    };
  }
}

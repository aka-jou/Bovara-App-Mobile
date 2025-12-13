import 'package:flutter/material.dart';

class AppStateRepository extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _currentUserEmail;

  // Datos de perfil
  String? _userName;
  String? _userRole;
  String? _ranchName;
  String? _userPhone;
  String? _userEmail;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String? get currentUserEmail => _currentUserEmail;

  String? get userName => _userName;
  String? get userRole => _userRole;
  String? get ranchName => _ranchName;
  String? get userPhone => _userPhone;
  String? get userEmail => _userEmail;

  // Nombre calculado para mostrar en el dashboard
  String get displayName =>
      _userName ??
          _userEmail?.split('@').first ??
          _currentUserEmail?.split('@').first ??
          'Ganadero';

  // Login / logout
  void setLoggedIn(bool value, {String? email}) {
    _isLoggedIn = value;
    if (email != null && email.isNotEmpty) {
      _currentUserEmail = email;
      _userEmail ??= email; // si no había email de perfil, lo sincronizamos
    }
    notifyListeners();
  }

  // Actualizar datos de perfil
  void updateProfile({
    String? name,
    String? role,
    String? ranch,
    String? phone,
    String? email,
  }) {
    if (name != null && name.isNotEmpty) _userName = name;
    if (role != null && role.isNotEmpty) _userRole = role;
    if (ranch != null && ranch.isNotEmpty) _ranchName = ranch;
    if (phone != null && phone.isNotEmpty) _userPhone = phone;
    if (email != null && email.isNotEmpty) {
      _userEmail = email;
      _currentUserEmail = email;
    }
    notifyListeners();
  }
}

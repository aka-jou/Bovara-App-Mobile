import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/token_storage.dart';

class AppStateRepository extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _hasLoadedFromDisk = false;
  String? _currentUserEmail;

  // Datos de perfil
  String? _userName;
  String? _userRole;
  String? _ranchName;
  String? _userPhone;
  String? _userEmail;

  final _tokenStorage = TokenStorage();

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  bool get hasLoadedFromDisk => _hasLoadedFromDisk;

  String? get currentUserEmail => _currentUserEmail;

  String? get userName => _userName;

  String? get userRole => _userRole;

  String? get ranchName => _ranchName;

  String? get userPhone => _userPhone;

  String? get userEmail => _userEmail;

  // Nombre calculado para mostrar en el dashboard
  String get displayName =>
      _userName ??
          _userEmail
              ?.split('@')
              .first ??
          _currentUserEmail
              ?.split('@')
              .first ??
          'Ganadero';

  /// Restaura el estado desde disco. Llamar UNA VEZ al arrancar la app
  /// (desde AuthGate). Considera "logueado" si existe un token JWT vivo
  /// en FlutterSecureStorage.
  Future<void> loadFromDisk() async {
    if (_hasLoadedFromDisk) return;

    // Token JWT (fuente de verdad de la sesión)
    _isLoggedIn = await _tokenStorage.hasToken();

    // Datos de perfil (opcionales, cachear para mostrar de una)
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name');
    _userRole = prefs.getString('user_role');
    _ranchName = prefs.getString('ranch_name');
    _userPhone = prefs.getString('user_phone');
    _userEmail = prefs.getString('user_email');
    _currentUserEmail = _userEmail;

    _hasLoadedFromDisk = true;
    notifyListeners();
  }

  // Login / logout
  void setLoggedIn(bool value, {String? email}) {
    _isLoggedIn = value;
    if (email != null && email.isNotEmpty) {
      _currentUserEmail = email;
      _userEmail ??= email; // si no había email de perfil, lo sincronizamos
    }
    _persistProfile();
    notifyListeners();
  }

  /// Borra sesión y todo el perfil (para cerrar sesión).
  Future<void> logout() async {
    _isLoggedIn = false;
    _currentUserEmail = null;
    _userName = null;
    _userRole = null;
    _ranchName = null;
    _userPhone = null;
    _userEmail = null;
    await _tokenStorage.clearAll(); // borra JWT + prefs
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
    _userPhone = phone;
    if (email != null && email.isNotEmpty) {
      _userEmail = email;
      _currentUserEmail = email;
    }
    _persistProfile();
    notifyListeners();
  }

  /// Guarda el perfil en SharedPreferences para restaurarlo al reabrir.
  Future<void> _persistProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (_userName != null) await prefs.setString('user_name', _userName!);
    if (_userRole != null) await prefs.setString('user_role', _userRole!);
    if (_ranchName != null) await prefs.setString('ranch_name', _ranchName!);
    if (_userPhone != null) await prefs.setString('user_phone', _userPhone!);
    if (_userEmail != null) await prefs.setString('user_email', _userEmail!);
  }
}

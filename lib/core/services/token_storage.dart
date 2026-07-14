import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ⚠️ IMPORTANTE: usa la MISMA storage y la MISMA key ('jwt_token') que
/// core/services/api_service.dart. Antes este archivo usaba SharedPreferences
/// con la key 'access_token', mientras que ApiService (usado por
/// CattleService, HealthEventService, etc.) usaba FlutterSecureStorage con
/// la key 'jwt_token'. Resultado: el token guardado al hacer login nunca
/// era visto por los servicios de ganado. Ahora todo el flujo de auth
/// converge a un único storage.
class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';

  // Datos de usuario complementarios (no sensibles) siguen en SharedPreferences
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveUserData(String userId, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userEmailKey, email);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../../../../core/services/token_storage.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthService {
  final TokenStorage _tokenStorage = TokenStorage();

  // Registro
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerEndpoint}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'full_name': fullName,
        }),
      );

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));

        // Guardar token
        await _tokenStorage.saveToken(authResponse.accessToken);
        await _tokenStorage.saveUserData(
            authResponse.user.id,
            authResponse.user.email
        );

        return authResponse;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Error en el registro');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Login
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));

        // Guardar token
        await _tokenStorage.saveToken(authResponse.accessToken);
        await _tokenStorage.saveUserData(
            authResponse.user.id,
            authResponse.user.email
        );

        return authResponse;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Credenciales inválidas');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener usuario actual
  Future<User> getCurrentUser() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.meEndpoint}');
    final token = await _tokenStorage.getToken();

    if (token == null) {
      throw Exception('No hay sesión activa');
    }

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al obtener usuario');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    await _tokenStorage.clearAll();
  }

  // Verificar si hay sesión activa
  Future<bool> isLoggedIn() async {
    return await _tokenStorage.hasToken();
  }
}

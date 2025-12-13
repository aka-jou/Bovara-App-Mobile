import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // ✅ PUERTO CORRECTO: 8003 (gateway)
  static const String baseUrl = 'http://192.168.0.4:8002/api/v1';

  final _storage = const FlutterSecureStorage();

  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> saveToken(String token) async {
    print('💾 Guardando token: ${token.substring(0, 20)}...');
    await _storage.write(key: 'jwt_token', value: token);

    // Verificar que se guardó
    final saved = await _storage.read(key: 'jwt_token');
    if (saved == token) {
      print('✅ Token verificado en storage');
    } else {
      print('❌ ERROR: Token NO se guardó correctamente');
    }
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      print('📤 GET $baseUrl$endpoint');

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      print('📥 Response status: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      print('❌ GET Error: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      print('📤 POST $baseUrl$endpoint');
      print('📦 Body: $body');

      // ✅ Login usa form-urlencoded, otros usan JSON
      if (endpoint.contains('/auth/login')) {
        print('🔐 Usando form-urlencoded para login');
        final response = await http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: body, // Sin jsonEncode
        );
        print('📥 Login response status: ${response.statusCode}');
        return _handleResponse(response);
      }

      // Para register y otros endpoints
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📥 Response status: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      print('❌ POST Error: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // DELETE request
  Future<void> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      _handleResponse(response);
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Manejar respuesta
  dynamic _handleResponse(http.Response response) {
    print('📥 Response body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        print('✅ Response decoded: $decoded');
        return decoded;
      }
      return null;
    } else if (response.statusCode == 401) {
      throw Exception('Token inválido o expirado.');
    } else if (response.statusCode == 403) {
      throw Exception('No autorizado.');
    } else if (response.statusCode == 404) {
      throw Exception('Recurso no encontrado.');
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Error desconocido');
      } catch (e) {
        throw Exception('Error del servidor (${response.statusCode})');
      }
    }
  }
}

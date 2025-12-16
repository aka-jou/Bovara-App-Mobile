import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cattle_model.dart';
import '../../../../core/config/api_config.dart'; // ✅ AGREGADO
import '../../../../core/services/auth_service.dart'; // ✅ AGREGADO

class CattleService {
  final AuthService _authService = AuthService();

  // ✅ Helper para obtener headers con token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ✅ Listar todas las vacas
  Future<List<CattleModel>> getCattleList() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cattleEndpoint}');
      print('🐄 Obteniendo vacas de: $url');

      final response = await http.get(url, headers: await _getHeaders());

      print('📡 Status getCattleList: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> cattleData = data is List
            ? data
            : data['cattle'] ?? data['data'] ?? [];

        return cattleData.map((json) => CattleModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener vacas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error obteniendo vacas: $e');
      rethrow;
    }
  }

  // ✅ Obtener una vaca por ID
  Future<CattleModel> getCattleById(String id) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cattleEndpoint}$id');
      print('🐄 Obteniendo vaca: $url');

      final response = await http.get(url, headers: await _getHeaders());

      print('📡 Status getCattleById: ${response.statusCode}');

      if (response.statusCode == 200) {
        return CattleModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al obtener vaca: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error obteniendo vaca: $e');
      rethrow;
    }
  }

  // ✅ Crear nueva vaca
  Future<CattleModel> createCattle(CattleModel cattle) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cattleEndpoint}');
      print('🐄 Creando vaca en: $url');

      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode(cattle.toJson()),
      );

      print('📡 Status createCattle: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return CattleModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al crear vaca: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error creando vaca: $e');
      rethrow;
    }
  }

  // ✅ Actualizar vaca
  Future<CattleModel> updateCattle(String id, Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cattleEndpoint}$id');
      print('🐄 Actualizando vaca: $url');

      final response = await http.put(
        url,
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );

      print('📡 Status updateCattle: ${response.statusCode}');

      if (response.statusCode == 200) {
        return CattleModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al actualizar vaca: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error actualizando vaca: $e');
      rethrow;
    }
  }

  // ✅ Eliminar vaca
  Future<void> deleteCattle(String id) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cattleEndpoint}$id');
      print('🐄 Eliminando vaca: $url');

      final response = await http.delete(url, headers: await _getHeaders());

      print('📡 Status deleteCattle: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar vaca: ${response.statusCode}');
      }

      print('✅ Vaca eliminada correctamente');
    } catch (e) {
      print('❌ Error eliminando vaca: $e');
      rethrow;
    }
  }

  // ✅ Buscar por lote
  Future<List<CattleModel>> searchByLote(String lote) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cattleEndpoint}search?lote=$lote');
      print('🐄 Buscando por lote: $url');

      final response = await http.get(url, headers: await _getHeaders());

      print('📡 Status searchByLote: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> cattleData = data is List
            ? data
            : data['cattle'] ?? data['data'] ?? [];

        return cattleData.map((json) => CattleModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al buscar vacas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error buscando vacas: $e');
      rethrow;
    }
  }
}

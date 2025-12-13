import '../models/cattle_model.dart';
import '../../../../core/services/api_service.dart';

class CattleService {
  final ApiService _api = ApiService();

  // Listar todas las vacas
  Future<List<CattleModel>> getCattleList() async {
    try {
      final response = await _api.get('/cattle');

      // La API puede devolver { cattle: [...] } o directamente [...]
      final List<dynamic> cattleData = response is List
          ? response
          : response['cattle'] ?? [];

      return cattleData.map((json) => CattleModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error obteniendo vacas: $e');
      rethrow;
    }
  }

  // Obtener una vaca por ID
  Future<CattleModel> getCattleById(String id) async {
    try {
      final response = await _api.get('/cattle/$id');
      return CattleModel.fromJson(response);
    } catch (e) {
      print('❌ Error obteniendo vaca: $e');
      rethrow;
    }
  }

  // Crear nueva vaca
  Future<CattleModel> createCattle(CattleModel cattle) async {
    try {
      final response = await _api.post('/cattle', cattle.toJson());
      return CattleModel.fromJson(response);
    } catch (e) {
      print('❌ Error creando vaca: $e');
      rethrow;
    }
  }

  // Actualizar vaca
  Future<CattleModel> updateCattle(String id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/cattle/$id', data);
      return CattleModel.fromJson(response);
    } catch (e) {
      print('❌ Error actualizando vaca: $e');
      rethrow;
    }
  }

  // Eliminar vaca
  Future<void> deleteCattle(String id) async {
    try {
      await _api.delete('/cattle/$id');
    } catch (e) {
      print('❌ Error eliminando vaca: $e');
      rethrow;
    }
  }

  // Buscar por lote
  Future<List<CattleModel>> searchByLote(String lote) async {
    try {
      final response = await _api.get('/cattle/search?query=$lote');
      final List<dynamic> cattleData = response is List
          ? response
          : response['cattle'] ?? [];
      return cattleData.map((json) => CattleModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error buscando vacas: $e');
      rethrow;
    }
  }
}

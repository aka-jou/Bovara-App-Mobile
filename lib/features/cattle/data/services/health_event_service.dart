import '../models/health_event_model.dart';
import '../../../../core/services/api_service.dart';

class HealthEventService {
  final ApiService _api = ApiService();

  // ✅ Registrar evento de salud (vacuna/tratamiento)
  Future<HealthEventModel> createHealthEvent(HealthEventModel event) async {
    try {
      final response = await _api.post('/health-events', event.toJson());
      print('✅ Evento de salud registrado');
      return HealthEventModel.fromJson(response);
    } catch (e) {
      print('❌ Error registrando evento: $e');
      rethrow;
    }
  }

  // ✅ Obtener historial de salud de una vaca
  Future<List<HealthEventModel>> getHealthEventsByCattle(String cattleId) async {
    try {
      final response = await _api.get('/health-events/cattle/$cattleId');

      final List<dynamic> eventsData = response is List
          ? response
          : response['health_events'] ?? response['data'] ?? [];

      return eventsData.map((json) => HealthEventModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error obteniendo historial: $e');
      rethrow;
    }
  }

  // ✅ Actualizar evento de salud
  Future<HealthEventModel> updateHealthEvent(String id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/health-events/$id', data);
      return HealthEventModel.fromJson(response);
    } catch (e) {
      print('❌ Error actualizando evento: $e');
      rethrow;
    }
  }

  // ✅ Eliminar evento de salud
  Future<void> deleteHealthEvent(String id) async {
    try {
      await _api.delete('/health-events/$id');
      print('✅ Evento eliminado');
    } catch (e) {
      print('❌ Error eliminando evento: $e');
      rethrow;
    }
  }
}

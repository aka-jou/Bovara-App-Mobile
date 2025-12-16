import '../models/heat_event_model.dart';
import '../../../../core/services/api_service.dart';

class HeatEventService {
  final ApiService _api = ApiService();

  // ✅ Registrar evento de celo
  Future<HeatEventModel> createHeatEvent(HeatEventModel event) async {
    try {
      final response = await _api.post('/heat-events/', event.toJson());
      print('✅ Evento de celo registrado');
      return HeatEventModel.fromJson(response);
    } catch (e) {
      print('❌ Error registrando celo: $e');
      rethrow;
    }
  }

  // ✅ Obtener eventos de celo de una vaca
  Future<List<HeatEventModel>> getHeatEventsByCattle(String cattleId) async {
    try {
      final response = await _api.get('/heat-events/cattle/$cattleId');

      final List<dynamic> eventsData = response is List
          ? response
          : response['heat_events'] ?? response['data'] ?? [];

      return eventsData.map((json) => HeatEventModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error obteniendo eventos de celo: $e');
      rethrow;
    }
  }

  // ✅ Actualizar evento (registrar inseminación)
  Future<HeatEventModel> updateHeatEvent(String id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/heat-events/$id', data);
      print('✅ Evento actualizado');
      return HeatEventModel.fromJson(response);
    } catch (e) {
      print('❌ Error actualizando evento: $e');
      rethrow;
    }
  }

  // ✅ Eliminar evento de celo
  Future<void> deleteHeatEvent(String id) async {
    try {
      await _api.delete('/heat-events/$id');
      print('✅ Evento eliminado');
    } catch (e) {
      print('❌ Error eliminando evento: $e');
      rethrow;
    }
  }
}

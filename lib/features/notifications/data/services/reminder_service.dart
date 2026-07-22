// lib/features/notifications/data/services/reminder_service.dart
//
// Servicio de recordatorios. Mapea 1:1 con los endpoints de
// core-service/src/api/v1/reminder.py:
//
//   POST   /reminders               → createReminder
//   GET    /reminders               → listReminders (filtros: status, rango de fechas)
//   GET    /reminders/today         → todayReminders
//   GET    /reminders/{id}          → getReminder
//   PUT    /reminders/{id}          → updateReminder
//   PATCH  /reminders/{id}/complete → completeReminder
//   DELETE /reminders/{id}          → deleteReminder

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../models/reminder_model.dart';

class ReminderService {
  final AuthService _auth = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ─────────── READ ───────────

  /// Listado con filtros opcionales.
  /// - [status]: 'pending' | 'completed' | 'cancelled'
  /// - [startDate], [endDate]: filtran por reminder_date (YYYY-MM-DD).
  Future<List<ReminderModel>> listReminders({
    ReminderStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int skip = 0,
    int limit = 100,
  }) async {
    final params = <String, String>{
      'skip': '$skip',
      'limit': '$limit',
      if (status != null) 'status': status.api,
      if (startDate != null) 'start_date': _fmt(startDate),
      if (endDate != null) 'end_date': _fmt(endDate),
    };
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.remindersEndpoint}')
        .replace(queryParameters: params);

    final resp = await http.get(uri, headers: await _headers());
    _ensureOk(resp, 'listar recordatorios');
    final list = jsonDecode(utf8.decode(resp.bodyBytes)) as List;
    return list.map((j) => ReminderModel.fromJson(j)).toList();
  }

  /// Solo recordatorios de HOY. Endpoint dedicado en el backend.
  Future<List<ReminderModel>> todayReminders() async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.remindersTodayEndpoint}');
    final resp = await http.get(uri, headers: await _headers());
    _ensureOk(resp, 'recordatorios de hoy');
    final list = jsonDecode(utf8.decode(resp.bodyBytes)) as List;
    return list.map((j) => ReminderModel.fromJson(j)).toList();
  }

  /// Un recordatorio por ID.
  Future<ReminderModel> getReminder(String id) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.remindersEndpoint}/$id');
    final resp = await http.get(uri, headers: await _headers());
    _ensureOk(resp, 'obtener recordatorio');
    return ReminderModel.fromJson(jsonDecode(utf8.decode(resp.bodyBytes)));
  }

  // ─────────── WRITE ───────────

  /// Crear un recordatorio. Devuelve el modelo con id, timestamps y user_id.
  Future<ReminderModel> createReminder({
    required String title,
    required DateTime reminderDate,
    required ReminderType type,
    String? description,
    String? cattleId,
  }) async {
    final body = jsonEncode({
      'title': title,
      'reminder_date': reminderDate.toIso8601String(),
      'reminder_type': type.api,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (cattleId != null) 'cattle_id': cattleId,
    });

    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.remindersEndpoint}');
    final resp = await http.post(uri, headers: await _headers(), body: body);
    _ensureOk(resp, 'crear recordatorio', expected: 201);
    return ReminderModel.fromJson(jsonDecode(utf8.decode(resp.bodyBytes)));
  }

  /// Editar campos parciales (envía solo los que no son null).
  Future<ReminderModel> updateReminder(
    String id, {
    String? title,
    String? description,
    DateTime? reminderDate,
    ReminderType? type,
    ReminderStatus? status,
    String? cattleId,
  }) async {
    final payload = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (reminderDate != null) 'reminder_date': reminderDate.toIso8601String(),
      if (type != null) 'reminder_type': type.api,
      if (status != null) 'status': status.api,
      if (cattleId != null) 'cattle_id': cattleId,
    };
    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.remindersEndpoint}/$id');
    final resp = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    _ensureOk(resp, 'actualizar recordatorio');
    return ReminderModel.fromJson(jsonDecode(utf8.decode(resp.bodyBytes)));
  }

  /// Marcar como completado (endpoint dedicado, más simple que PUT).
  Future<ReminderModel> completeReminder(String id) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.remindersEndpoint}/$id/complete');
    final resp = await http.patch(uri, headers: await _headers());
    _ensureOk(resp, 'completar recordatorio');
    return ReminderModel.fromJson(jsonDecode(utf8.decode(resp.bodyBytes)));
  }

  Future<void> deleteReminder(String id) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.remindersEndpoint}/$id');
    final resp = await http.delete(uri, headers: await _headers());
    // 204 No Content en éxito.
    if (resp.statusCode != 204) {
      throw Exception(
        'No pude eliminar el recordatorio (${resp.statusCode}): ${resp.body}',
      );
    }
  }

  // ─────────── helpers ───────────

  void _ensureOk(http.Response resp, String action, {int expected = 200}) {
    if (resp.statusCode == expected) return;
    // El backend devuelve {"detail": "..."} en errores.
    String detail = resp.body;
    try {
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
      if (decoded is Map && decoded['detail'] != null) {
        detail = decoded['detail'].toString();
      }
    } catch (_) {}
    throw Exception('No pude $action (${resp.statusCode}): $detail');
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

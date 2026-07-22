// lib/features/notifications/data/services/notification_log_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../models/notification_log_model.dart';

class NotificationLogService {
  final _auth = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<NotificationLogModel>> list({int limit = 50}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/notifications?limit=$limit',
    );
    final resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode != 200) {
      throw Exception('No pude cargar notificaciones (${resp.statusCode})');
    }
    final List list = jsonDecode(utf8.decode(resp.bodyBytes));
    return list.map((j) => NotificationLogModel.fromJson(j)).toList();
  }

  Future<void> markRead(String id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/$id/read');
    await http.patch(uri, headers: await _headers());
  }

  Future<void> markAllRead() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/read-all');
    await http.post(uri, headers: await _headers());
  }
}

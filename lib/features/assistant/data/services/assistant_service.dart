import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart'; // ✅ AGREGADO

class AssistantService {
  final String baseUrl = ApiConfig.baseUrl; // ✅ USA EL GATEWAY

  Future<AssistantResponse> sendMessage(String message) async {
    try {
      final url = '${baseUrl}${ApiConfig.chatEndpoint}';
      print('🤖 Enviando mensaje a: $url');
      print('💬 Mensaje: $message');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'message': message,
        }),
      );

      print('📡 Status: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AssistantResponse.fromJson(data);
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  Future<bool> checkHealth() async {
    try {
      final url = '${baseUrl}${ApiConfig.chatHealthEndpoint}';
      print('🏥 Health check: $url');

      final response = await http.get(Uri.parse(url));

      print('📡 Health status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }
}

class AssistantResponse {
  final String response;
  final String? toolUsed;
  final String? toolResult;

  AssistantResponse({
    required this.response,
    this.toolUsed,
    this.toolResult,
  });

  factory AssistantResponse.fromJson(Map<String, dynamic> json) {
    return AssistantResponse(
      response: json['response'] ?? '',
      toolUsed: json['tool_used'],
      toolResult: json['tool_result'],
    );
  }

  String get fullText {
    if (toolUsed != null && toolResult != null) {
      return '$response\n\n📊 Herramienta: $toolUsed';
    }
    return response;
  }
}

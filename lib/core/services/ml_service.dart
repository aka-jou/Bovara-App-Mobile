// lib/core/services/ml_service.dart
//
// Cliente del ml-service (via api-gateway). Por ahora solo expone
// predictHeatProbability(); se puede extender a forecasting/clustering
// cuando se integren esas features al UI.

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class HeatReason {
  final String weight;
  final String title;
  final String detail;
  final String color; // celo | info | primary | warning
  const HeatReason({
    required this.weight,
    required this.title,
    required this.detail,
    required this.color,
  });
  factory HeatReason.fromJson(Map<String, dynamic> j) => HeatReason(
        weight: j['weight'] as String,
        title: j['title'] as String,
        detail: j['detail'] as String,
        color: j['color'] as String,
      );
}

class HeatProbabilityResult {
  final int probability;
  final String verdict;
  final String window;
  final List<HeatReason> reasons;
  final int historyBoost;
  final String source;

  const HeatProbabilityResult({
    required this.probability,
    required this.verdict,
    required this.window,
    required this.reasons,
    required this.historyBoost,
    required this.source,
  });

  factory HeatProbabilityResult.fromJson(Map<String, dynamic> j) => HeatProbabilityResult(
        probability: j['probability'] as int,
        verdict: j['verdict'] as String,
        window: j['window'] as String,
        reasons: (j['reasons'] as List)
            .map((r) => HeatReason.fromJson(r as Map<String, dynamic>))
            .toList(),
        historyBoost: (j['history_boost'] ?? 0) as int,
        source: (j['source'] ?? 'heuristic_v1') as String,
      );
}

class MlService {
  final _auth = AuthService();

  Future<HeatProbabilityResult> predictHeatProbability({
    String? cattleId,
    required bool inmovilidad,
    required int vecesMontada,
    required int intentosMonta,
    required String secrecion,
    required String hinchazon,
    required String actividad,
    required Map<String, bool> social,
  }) async {
    final token = await _auth.getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/heat/predict');
    final body = jsonEncode({
      if (cattleId != null) 'cattle_id': cattleId,
      'inmovilidad': inmovilidad,
      'veces_montada': vecesMontada,
      'intentos_monta': intentosMonta,
      'secrecion': secrecion,
      'hinchazon': hinchazon,
      'actividad': actividad,
      'social_mugidos': social['mugidos'] ?? false,
      'social_nerviosismo': social['nerviosismo'] ?? false,
      'social_monta_otras': social['monta_otras'] ?? false,
      'social_inquietud': social['inquietud'] ?? false,
      'social_olfatea': social['olfatea'] ?? false,
      'social_lame': social['lame'] ?? false,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('ML ${response.statusCode}: ${response.body}');
    }
    return HeatProbabilityResult.fromJson(jsonDecode(response.body));
  }
}

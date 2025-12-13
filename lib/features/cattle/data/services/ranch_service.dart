import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../models/ranch_model.dart';

class RanchService {
  final String baseUrl = ApiConfig.coreBaseUrl; // Usa tu config existente

  Future<RanchModel> createRanch({
    required String name,
    required String location,
    required double sizeHectares,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/ranches/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'location': location,
        'size_hectares': sizeHectares,
      }),
    );

    if (response.statusCode == 201) {
      return RanchModel.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al crear rancho');
    }
  }

  Future<List<RanchModel>> getRanches(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/ranches/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => RanchModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener ranchos');
    }
  }
}

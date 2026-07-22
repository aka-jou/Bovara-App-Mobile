// lib/core/services/cloudinary_service.dart
//
// Sube imágenes a Cloudinary usando "unsigned upload preset". La API
// secret NO se expone en el cliente (por eso "unsigned"). Devuelve la
// secure_url que luego se guarda en el backend en la columna photo_url.

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Config del usuario:
  static const _cloudName = 'herltu7d';
  static const _uploadPreset = 'bovara_cattle';

  static Uri get _uploadUrl =>
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

  /// Sube el archivo. Devuelve la URL segura (https) del recurso.
  Future<String> uploadImage(File file) async {
    final request = http.MultipartRequest('POST', _uploadUrl)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = 'bovara/cattle'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('Cloudinary ${streamed.statusCode}: $body');
    }

    final Map<String, dynamic> json = jsonDecode(body);
    final url = json['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary no devolvió secure_url');
    }
    return url;
  }
}

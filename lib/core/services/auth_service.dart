import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      print('🔐 Intentando login...');

      final response = await _api.post('/auth/login', {
        'username': username,
        'password': password,
      });

      print('📦 Respuesta login: $response');

      // Guardar token
      final token = response['access_token'];
      await _api.saveToken(token);

      print('✅ Login exitoso. Token guardado: ${token.substring(0, 20)}...');
      return response;
    } catch (e) {
      print('❌ Error en login: $e');
      rethrow;
    }
  }

  // Register
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      print('📝 Iniciando registro...');
      print('📧 Email: $email');
      print('👤 Nombre: $fullName');

      final dynamic rawResponse = await _api.post('/auth/register', {
        'email': email,
        'password': password,
        'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });

      print('📦 RAW RESPONSE: $rawResponse');
      print('📦 RAW RESPONSE TYPE: ${rawResponse.runtimeType}');

      // Convertir a Map
      final Map<String, dynamic> response = Map<String, dynamic>.from(rawResponse);

      print('🗺️ RESPONSE MAP: $response');
      print('🔑 Keys en response: ${response.keys.toList()}');
      print('🔍 ¿Tiene access_token? ${response.containsKey('access_token')}');

      if (response.containsKey('access_token')) {
        final token = response['access_token'];
        print('🎫 Token encontrado: ${token.toString().substring(0, 20)}...');

        await _api.saveToken(token.toString());

        // Verificar que se guardó
        final savedToken = await _api.getToken();
        print('✅ Token guardado y verificado: ${savedToken?.substring(0, 20)}...');
      } else {
        print('❌ NO SE ENCONTRÓ access_token EN LA RESPUESTA');
        print('❌ Response completo: $response');
      }

      return response;
    } catch (e) {
      print('❌ Error en registro: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _api.deleteToken();
    print('✅ Sesión cerrada.');
  }

  // Verificar si está autenticado
  Future<bool> isAuthenticated() async {
    final token = await _api.getToken();
    final isAuth = token != null && token.isNotEmpty;
    print('🔐 isAuthenticated: $isAuth');
    if (token != null) {
      print('🎫 Token actual: ${token.substring(0, 20)}...');
    }
    return isAuth;
  }

  // Obtener el token actual
  Future<String?> getToken() async {
    final token = await _api.getToken();
    if (token != null) {
      print('🎫 getToken: ${token.substring(0, 20)}...');
    } else {
      print('❌ getToken: null');
    }
    return token;
  }
}

class ApiConfig {
  static const String _baseUrlAndroidEmulator = 'http://10.0.2.2:8000';
  static const String _baseUrlPhysicalDevice = 'http://192.168.0.4:8000';
  static const String _baseUrlIOSSimulator = 'http://localhost:8000';

  // ← AUTH SERVICE (puerto 8000)
  static const String baseUrl = _baseUrlPhysicalDevice;

  // ← CORE SERVICE (puerto 8001) - NUEVO
  static const String coreBaseUrl = 'http://192.168.0.4:8001';

  // Auth endpoints
  static const String registerEndpoint = '/api/v1/auth/register';
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String meEndpoint = '/api/v1/auth/me';
  static const String logoutEndpoint = '/api/v1/auth/logout';

  // Core endpoints - NUEVO
  static const String ranchesEndpoint = '/api/v1/ranches/';
  static const String cattleEndpoint = '/api/v1/cattle/';

  static const String apiKey = '';
}

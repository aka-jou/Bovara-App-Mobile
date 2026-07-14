class ApiConfig {
  // 🔧 IP de tu máquina en la red local (donde corre el api-gateway)
  // Emulador Android: usa '10.0.2.2'
  // Dispositivo físico: usa la IP LAN de tu PC (ej. 192.168.x.x)
  static const String _baseIp = '10.14.0.41';

  // ✅ UN SOLO ENDPOINT: El API Gateway (puerto 8002)
  static const String baseUrl = 'http://$_baseIp:8002';

  // ============================================
  // Endpoints (todos pasan por el gateway)
  // ============================================

  // Auth
  static const String registerEndpoint = '/api/v1/auth/register';
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String meEndpoint = '/api/v1/auth/me';
  static const String logoutEndpoint = '/api/v1/auth/logout';

  // Core (Cattle, Ranches)
  static const String ranchesEndpoint = '/api/v1/ranches/';
  static const String cattleEndpoint = '/api/v1/cattle';

  // Chatbot
  static const String chatEndpoint = '/api/v1/chat/';
  static const String chatHealthEndpoint = '/api/v1/chat/health';

  static const String apiKey = '';
}

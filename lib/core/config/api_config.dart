class ApiConfig {
  // ✅ UN SOLO ENDPOINT: El API Gateway en Railway
  static const String baseUrl = 'https://bovara-server.up.railway.app';

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

  // Recordatorios (calendario / tareas)
  static const String remindersEndpoint = '/api/v1/reminders';
  static const String remindersTodayEndpoint = '/api/v1/reminders/today';

  // Chatbot
  static const String chatEndpoint = '/api/v1/chat/';
  static const String chatHealthEndpoint = '/api/v1/chat/health';
}
// lib/core/services/notification_service.dart
//
// Wiring de Firebase Cloud Messaging:
//   - initialize(): pide permiso (Android 13+), configura canal local
//     para mostrar push cuando la app está en foreground.
//   - registerToken(): obtiene el token FCM y lo manda al backend
//     (POST /api/v1/notifications/register-device). Llamar tras login
//     exitoso y también al arrancar si ya había sesión.
//   - unregisterToken(): llamar en logout.
//
// El canal "bovara_reminders" debe coincidir con el channel_id que usa
// el notifications-service al construir el AndroidNotification (ver
// fcm_service.py del backend).

import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../router/app_router.dart';
import 'auth_service.dart';

/// Debe ser una función top-level (no método de clase) — la exige el SDK
/// para el handler de mensajes en background/terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No hace falta lógica aquí: Android ya muestra la notificación del
  // payload "notification" automáticamente cuando la app está en
  // background/terminated. Este handler solo debe existir para que el
  // SDK no lo reclame en consola.
}

class NotificationService {
  static final _local = FlutterLocalNotificationsPlugin();
  final _auth = AuthService();

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Canal Android para cuando la app está ABIERTA (foreground). FCM no
    // muestra notificación automática en foreground; hay que dispararla
    // manualmente con flutter_local_notifications.
    const channel = AndroidNotificationChannel(
      'bovara_reminders',
      'Recordatorios Bovara',
      description: 'Vacunas, celos y tareas del rancho',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        _navigateFromPayload(response.payload);
      },
    );

    FirebaseMessaging.onMessage.listen((message) {
      final notif = message.notification;
      if (notif == null) return;
      _local.show(
        notif.hashCode,
        notif.title,
        notif.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'bovara_reminders',
            'Recordatorios Bovara',
            channelDescription: 'Vacunas, celos y tareas del rancho',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });

    // Tap con la app en background (no terminada)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigateFromData(message.data);
    });

    // App abierta DESDE terminada tocando la notificación
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _navigateFromData(initialMessage.data);
    }
  }

  void _navigateFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateFromData(data.map((k, v) => MapEntry(k, v.toString())));
    } catch (_) {}
  }

  /// El payload de FCM siempre trae reminder_id/type (ver fcm_service.py
  /// del backend). Por ahora todo tipo de recordatorio navega a /reminders
  /// — es la única pantalla que lista el detalle de tareas hoy.
  void _navigateFromData(Map<String, dynamic> data) {
    if (data.containsKey('reminder_id')) {
      appRouter.go('/reminders');
    }
  }

  /// Llamar tras login exitoso, y también al abrir la app si ya había
  /// sesión (AuthGate), para mantener el token fresco.
  Future<void> registerToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      final authToken = await _auth.getToken();
      if (authToken == null) return; // sin sesión, no registrar

      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/register-device'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcm_token': fcmToken, 'platform': 'android'}),
      );
    } catch (_) {
      // Silencioso a propósito: no bloquear login/arranque si falla.
    }
  }

  /// Llamar antes de limpiar la sesión en logout.
  Future<void> unregisterToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      final authToken = await _auth.getToken();
      if (authToken == null) return;

      await http.delete(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/notifications/unregister-device'
          '?fcm_token=${Uri.encodeComponent(fcmToken)}',
        ),
        headers: {'Authorization': 'Bearer $authToken'},
      );
    } catch (_) {
      // Silencioso: el logout no debe fallar por esto.
    }
  }
}

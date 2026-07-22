import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/application/app_state_repository.dart';
import 'core/services/notification_service.dart';
import 'features/auth/data/services/auth_service.dart';        // ← NUEVO
import 'features/auth/presentation/providers/auth_provider.dart'; // ← NUEVO

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppStateRepository(),
        ),
        // ← NUEVO: Provider para autenticación
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService()),
        ),
      ],
      child: const BovaraApp(),
    ),
  );
}

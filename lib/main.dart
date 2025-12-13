import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/application/app_state_repository.dart';
import 'features/auth/data/services/auth_service.dart';        // ← NUEVO
import 'features/auth/presentation/providers/auth_provider.dart'; // ← NUEVO

void main() {
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

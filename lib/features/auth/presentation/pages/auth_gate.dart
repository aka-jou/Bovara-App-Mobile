// lib/features/auth/presentation/pages/auth_gate.dart
//
// Pantalla splash mínima que decide adónde mandar al usuario al arrancar:
//
//   1. Si NUNCA ha visto el onboarding (SharedPreferences 'onboarding_seen'
//      == false) → /onboarding.
//   2. Si ya lo vio pero no tiene sesión (no hay token JWT en storage) →
//      /welcome.
//   3. Si tiene sesión (hay token) → /home.
//
// Se muestra en /splash como initialLocation del router. Cuando termina
// de decidir, hace context.go(...) hacia la ruta correspondiente. Muestra
// el logo grande mientras lo hace (usualmente <100ms).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/application/app_state_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/theme.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // WidgetsBinding para que el go() ocurra después del primer frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideRoute());
  }

  Future<void> _decideRoute() async {
    // 1. Restaurar sesión desde disco (JWT + perfil).
    final appState = context.read<AppStateRepository>();
    await appState.loadFromDisk();

    // 2. Chequear si ya vio el onboarding.
    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

    if (!mounted) return;

    if (appState.isLoggedIn) {
      NotificationService().registerToken();
      context.go('/home');
    } else if (!onboardingSeen) {
      context.go('/onboarding');
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BovaraColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SplashLogo(),
            const SizedBox(height: 24),
            Text('Bovara',
                style: BovaraText.logo(size: 32, color: BovaraColors.textOnDark)),
          ],
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: BovaraColors.primaryDeep.withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -14,
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Image.asset(
        'assets/images/bovara_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

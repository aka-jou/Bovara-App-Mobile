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
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: BovaraColors.primaryGradient,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: BovaraColors.primaryDeep.withValues(alpha: 0.55),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -14,
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 48,
          height: 36,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EDE0),
                    borderRadius: BorderRadius.circular(80),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 11,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2B2018),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 11,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2B2018),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                left: 14,
                child: Container(
                  width: 20,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9B7A6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

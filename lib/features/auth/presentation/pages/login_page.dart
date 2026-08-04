// lib/features/auth/presentation/pages/login_page.dart
//
// Login (Grupo B — Login del prototipo).
// Cabeza: sello grande con gradient, título "Bienvenido de vuelta".
// Campos: email + password (con toggle mostrar/ocultar).
// Extras: enlace "¿Olvidaste tu contraseña?", divider "o", botón crear cuenta,
//         chip "Cifrado de extremo a extremo activo".
// Footer: banner ambar cuando no hay conexión ("Modo offline activo").
//
// La LÓGICA (AuthService, AppStateRepository, ConnectivityService) se
// preserva 100%; solo cambia la capa visual.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/application/app_state_repository.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/bovara_buttons.dart';
import '../../../../core/widgets/bovara_text_field.dart';
import '../../data/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  late final ConnectivityService _connectivityService;
  bool _isConnected = true;

  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _isConnected = _connectivityService.isConnected;
    _connectivityService.connectivityStream.listen((isConnected) {
      if (mounted) setState(() => _isConnected = isConnected);
    });
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    _connectivityService.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sin conexión. No se puede iniciar sesión.'),
          backgroundColor: BovaraColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.login(
        email: _userController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      final appState = context.read<AppStateRepository>();
      appState.updateProfile(
        name: response.user.fullName,
        email: response.user.email,
        phone: response.user.phone,
        ranch: response.user.ranch,
        role: response.user.role,
      );
      appState.setLoggedIn(true, email: response.user.email);
      NotificationService().registerToken();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Bienvenido, ${response.user.fullName}!'),
          backgroundColor: BovaraColors.primary,
        ),
      );

      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: BovaraColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BovaraColors.surface,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Contenido scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(30, 22, 30, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabeza: sello + título
                      Center(
                        child: Column(
                          children: [
                            const _LoginSeal(),
                            const SizedBox(height: 20),
                            Text(
                              'Bienvenido de vuelta',
                              style: BovaraText.title().copyWith(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.25,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Inicia sesión para continuar',
                              style: BovaraText.body(
                                size: 14,
                                color: BovaraColors.textSecondary,
                              ).copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Campos
                      BovaraTextField(
                        label: 'Email o teléfono',
                        hint: 'don.carlos@rancho.com',
                        controller: _userController,
                        keyboardType: TextInputType.emailAddress,
                        leadingIcon: Icons.mail_outline,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Ingresa tu email o teléfono'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      BovaraTextField(
                        label: 'Contraseña',
                        controller: _passwordController,
                        obscureText: true,
                        canToggleObscure: true,
                        leadingIcon: Icons.lock_outline,
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Mínimo 6 caracteres'
                            : null,
                      ),
                      const SizedBox(height: 9),
                      // "¿Olvidaste tu contraseña?"
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Función disponible próximamente'),
                              ),
                            );
                          },
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: BovaraText.label(
                              size: 13,
                              color: BovaraColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Botón login
                      PrimaryButton(
                        label: 'Iniciar sesión',
                        onPressed: _isLoading ? null : _onLoginPressed,
                        isLoading: _isLoading,
                        height: 54,
                      ),
                      const SizedBox(height: 22),
                      // Divider "o"
                      _OrDivider(),
                      const SizedBox(height: 22),
                      SecondaryButton(
                        label: 'Crear cuenta nueva',
                        onPressed: () => context.go('/signup'),
                        height: 52,
                      ),
                      const SizedBox(height: 20),
                      // Chip cifrado
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_outline,
                                size: 14, color: BovaraColors.primary),
                            const SizedBox(width: 7),
                            Text(
                              'Cifrado de extremo a extremo activo',
                              style: BovaraText.label(
                                size: 12.5,
                                color: BovaraColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Footer offline (solo si no hay conexión)
              if (!_isConnected) const _OfflineBanner(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────

class _LoginSeal extends StatelessWidget {
  const _LoginSeal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: BovaraColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: BovaraColors.primaryDeep.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 16),
            spreadRadius: -12,
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

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: BovaraColors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'o',
            style: BovaraText.label(size: 12, color: BovaraColors.textDisabled),
          ),
        ),
        const Expanded(child: Divider(color: BovaraColors.border, height: 1)),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFBF1DD),
        border: Border(top: BorderSide(color: Color(0xFFF0E2C2))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0xFFF4D9A0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_off, size: 14, color: Color(0xFFB0862E)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sin conexión · Modo offline activo',
                  style: BovaraText.label(size: 12.5, color: const Color(0xFF8A6A1E)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Puedes entrar con tu sesión guardada',
                  style: BovaraText.body(size: 11.5, color: const Color(0xFFA8863C))
                      .copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

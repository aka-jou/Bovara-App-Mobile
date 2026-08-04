// lib/features/auth/presentation/pages/signup_page.dart
//
// Crear cuenta (Grupo B — Sign up del prototipo).
// AppBar limpio con botón atrás + "Crear cuenta" + subtítulo "Paso 1 de 2".
// Campos: nombre completo, rol, nombre del rancho, teléfono, correo (opcional),
//         contraseña. Checkbox de términos, botón "Continuar" al fondo.
//
// La LÓGICA de _authService.register() y AppStateRepository se preserva.

import 'package:flutter/material.dart';
import '../../../../core/services/notification_service.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/application/app_state_repository.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/bovara_buttons.dart';
import '../../../../core/widgets/bovara_text_field.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _ranchoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = false;
  bool _acceptTerms = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _ranchoController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      _showError('Debes aceptar los términos y condiciones');
      return;
    }

    final email = _correoController.text.trim();
    if (email.isEmpty) {
      _showError('El correo electrónico es requerido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authResponse = await _authService.register(
        email: email,
        password: _passwordController.text,
        fullName: _nombreController.text.trim(),
        phone: _telefonoController.text.trim().isNotEmpty
            ? _telefonoController.text.trim()
            : null,
      );

      if (!mounted) return;

      final appState = context.read<AppStateRepository>();
      appState.updateProfile(
        name: _nombreController.text.trim(),
        ranch: _ranchoController.text.trim(),
        phone: _telefonoController.text.trim(),
        email: email,
      );
      appState.setLoggedIn(true, email: email);
      NotificationService().registerToken();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Cuenta creada exitosamente!'),
          backgroundColor: BovaraColors.primary,
        ),
      );
    debugPrint('Registro exitoso: $authResponse');

    if (!mounted) return;


      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: BovaraColors.danger),
    );
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
              _Header(onBack: () => context.go('/welcome')),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(26, 6, 26, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BovaraTextField(
                        label: 'Nombre completo',
                        hint: 'Ej: Carlos Pérez García',
                        controller: _nombreController,
                        validator: (v) => (v == null || v.trim().length < 3)
                            ? 'Ingresa tu nombre completo'
                            : null,
                      ),
                      const SizedBox(height: 15),
                      BovaraTextField(
                        label: 'Nombre del rancho',
                        hint: 'Ej: Rancho La Esperanza',
                        controller: _ranchoController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Ingresa el nombre del rancho'
                            : null,
                      ),
                      const SizedBox(height: 15),
                      BovaraTextField(
                        label: 'Teléfono',
                        hint: '333 123 4567',
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 15),
                      BovaraTextField(
                        label: 'Correo',
                        hint: 'carlos@correo.com',
                        controller: _correoController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                          if (!v.contains('@')) return 'Correo no válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      BovaraTextField(
                        label: 'Contraseña',
                        hint: 'Mínimo 6 caracteres',
                        controller: _passwordController,
                        obscureText: true,
                        canToggleObscure: true,
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Mínimo 6 caracteres'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _TermsCheckbox(
                        checked: _acceptTerms,
                        onChanged: (v) => setState(() => _acceptTerms = v),
                      ),
                    ],
                  ),
                ),
              ),
              // Footer con botón continuar
              Container(
                decoration: const BoxDecoration(
                  color: BovaraColors.surface,
                  border: Border(top: BorderSide(color: Color(0xFFEFF0EA))),
                ),
                padding: const EdgeInsets.fromLTRB(26, 14, 26, 30),
                child: PrimaryButton(
                  label: 'Continuar',
                  onPressed: _isLoading ? null : _handleSignUp,
                  isLoading: _isLoading,
                  height: 54,
                ),
              ),
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

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 12, 26, 16),
      child: Row(
        children: [
          // Botón atrás cuadrado
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(BovaraRadius.sm),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(BovaraRadius.sm),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  border: Border.all(color: BovaraColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(BovaraRadius.sm),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 14, color: BovaraColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crear cuenta',
                  style: BovaraText.title(color: BovaraColors.textPrimary).copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Paso 1 de 2 · Datos del rancho',
                  style: BovaraText.label(size: 12.5, color: BovaraColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool> onChanged;
  const _TermsCheckbox({required this.checked, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(BovaraRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked ? BovaraColors.primary : Colors.transparent,
                border: checked
                    ? null
                    : Border.all(color: BovaraColors.border, width: 1.5),
                borderRadius: BorderRadius.circular(7),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: BovaraText.body(
                    size: 12.5,
                    color: BovaraColors.textSecondary,
                  ).copyWith(fontWeight: FontWeight.w500, height: 1.45),
                  children: [
                    const TextSpan(text: 'Acepto los '),
                    TextSpan(
                      text: 'términos y condiciones',
                      style: BovaraText.label(size: 12.5, color: BovaraColors.primary),
                    ),
                    const TextSpan(text: ' y la política de privacidad de Bovara.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

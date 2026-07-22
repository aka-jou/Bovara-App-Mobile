// lib/features/auth/presentation/pages/welcome_page.dart
//
// Pantalla de Bienvenida (Grupo B — Welcome del prototipo).
// Fondo con gradient radial claro, logo grande centrado, dos botones abajo.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/bovara_buttons.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BovaraColors.surface,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6), // 22% desde arriba
            radius: 1.2,
            colors: [Color(0xFFEFF5EF), BovaraColors.surface],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 34),
            child: Column(
              children: [
                const Spacer(),
                // Logo grande centrado
                _BigLogo(),
                const SizedBox(height: 38),
                // Título
                Column(
                  children: [
                    Text(
                      'Bienvenido a',
                      textAlign: TextAlign.center,
                      style: BovaraText.title(color: BovaraColors.textPrimary)
                          .copyWith(
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.58,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bovara',
                      textAlign: TextAlign.center,
                      style: BovaraText.logo(size: 44, color: BovaraColors.primary),
                    ),
                    const SizedBox(height: BovaraSpace.md),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Text(
                        'El sistema que convierte tu rancho en datos que trabajan para ti.',
                        textAlign: TextAlign.center,
                        style: BovaraText.body(
                          size: 15,
                          color: BovaraColors.textSecondary,
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Botones
                PrimaryButton(
                  label: 'Iniciar sesión',
                  onPressed: () => context.go('/login'),
                  height: 54,
                ),
                const SizedBox(height: 13),
                SecondaryButton(
                  label: 'Crear cuenta',
                  onPressed: () => context.go('/signup'),
                  height: 54,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo grande de bienvenida — versión ampliada del sello del logo pero
/// solo el ícono con estilo más suave y sombra difusa (del prototipo).
class _BigLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: BovaraColors.primaryGradient,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: BovaraColors.primaryDeep.withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -16,
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 62,
          height: 46,
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
                left: 16,
                top: 14,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2B2018),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 14,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2B2018),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 3,
                left: 18,
                child: Container(
                  width: 26,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9B7A6),
                    borderRadius: BorderRadius.circular(20),
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

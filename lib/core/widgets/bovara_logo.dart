// lib/core/widgets/bovara_logo.dart
//
// Logotipo de Bovara: cuadrado con gradient verde + cabeza estilizada de vaca +
// texto "Bovara" en Changa One. Extraído del rediseño.
// Uso: BovaraLogo() | BovaraLogo.small() | BovaraLogo.iconOnly()

import 'package:flutter/material.dart';
import '../theme/theme.dart';

class BovaraLogo extends StatelessWidget {
  final double iconSize;
  final double textSize;
  final Color textColor;
  final bool showText;

  const BovaraLogo({
    super.key,
    this.iconSize = 40,
    this.textSize = 24,
    this.textColor = BovaraColors.textOnDark,
    this.showText = true,
  });

  /// Versión compacta (32px + texto 19px) para headers y AppBars.
  const BovaraLogo.small({super.key, this.textColor = BovaraColors.textOnDark})
      : iconSize = 32,
        textSize = 19,
        showText = true;

  /// Solo el ícono, sin texto.
  const BovaraLogo.iconOnly({super.key, this.iconSize = 40})
      : textSize = 0,
        textColor = BovaraColors.textOnDark,
        showText = false;

  @override
  Widget build(BuildContext context) {
    final icon = _BovaraLogoMark(size: iconSize);
    if (!showText) return icon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(width: iconSize * 0.3),
        Text('Bovara', style: BovaraText.logo(size: textSize, color: textColor)),
      ],
    );
  }
}

/// El "sello" cuadrado del logo — cuadrado con gradient + cabeza abstracta.
class _BovaraLogoMark extends StatelessWidget {
  final double size;
  const _BovaraLogoMark({required this.size});

  @override
  Widget build(BuildContext context) {
    // proporciones tomadas del prototipo (círculos de la cabeza)
    final headW = size * 0.55;
    final headH = size * 0.4;
    final eye = size * 0.062;
    final muzzleW = size * 0.25;
    final muzzleH = size * 0.15;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: BovaraColors.primaryGradient,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99176B34),
            blurRadius: 18,
            offset: Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: headW,
          height: headH,
          child: Stack(
            children: [
              // Cara (elipse crema)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EDE0),
                    borderRadius: BorderRadius.circular(size),
                  ),
                ),
              ),
              // Ojo izquierdo
              Positioned(
                left: headW * 0.22,
                top: headH * 0.28,
                child: Container(
                  width: eye,
                  height: eye,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2B2018),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Ojo derecho
              Positioned(
                right: headW * 0.22,
                top: headH * 0.28,
                child: Container(
                  width: eye,
                  height: eye,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2B2018),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Hocico (rosa)
              Positioned(
                bottom: 0,
                left: (headW - muzzleW) / 2,
                child: Container(
                  width: muzzleW,
                  height: muzzleH,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9B7A6),
                    borderRadius: BorderRadius.circular(size),
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

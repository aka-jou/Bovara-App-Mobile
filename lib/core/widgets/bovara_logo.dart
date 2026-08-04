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

/// El "sello" del logo — la imagen real de Bovara.
class _BovaraLogoMark extends StatelessWidget {
  final double size;
  const _BovaraLogoMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x99176B34),
            blurRadius: 18,
            offset: Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.06),
      child: Image.asset(
        'assets/images/bovara_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

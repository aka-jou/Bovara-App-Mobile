// lib/core/widgets/bovara_buttons.dart
//
// Botones estándar del rediseño. Extraídos del prototipo:
//   - PrimaryButton: gradient verde (#2E8B45 → #1E6B34), texto blanco,
//     radio pill (28-30), sombra sesgada. Usado para acciones principales.
//   - SecondaryButton: transparente con borde claro sobre fondo oscuro,
//     o gris muy sutil sobre fondo claro.
//   - GhostButton: solo texto, sin fondo. Para "Saltar", "Cancelar".

import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Botón principal (call to action). Gradient verde + sombra.
///
/// Uso:
///   PrimaryButton(
///     label: 'Comenzar',
///     onPressed: () {},
///     trailingIcon: Icons.arrow_forward,
///   )
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool expand;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = true,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    final child = Container(
      height: height,
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                begin: Alignment(-1, -0.5),
                end: Alignment(1, 0.5),
                colors: BovaraColors.primaryGradient,
              )
            : null,
        color: enabled ? null : BovaraColors.surfaceMuted,
        borderRadius: BorderRadius.circular(BovaraRadius.pill),
        boxShadow: enabled ? BovaraShadow.button : null,
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon,
                        size: 18,
                        color: enabled ? Colors.white : BovaraColors.textDisabled),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: BovaraText.label(
                      size: 15,
                      color: enabled ? Colors.white : BovaraColors.textDisabled,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 10),
                    Icon(trailingIcon,
                        size: 18,
                        color: enabled ? Colors.white : BovaraColors.textDisabled),
                  ],
                ],
              ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(BovaraRadius.pill),
        child: child,
      ),
    );
  }
}

/// Botón secundario. Dos variantes según el fondo.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final bool onDarkBackground;
  final bool expand;
  final double height;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.onDarkBackground = false,
    this.expand = true,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        onDarkBackground ? Colors.white.withValues(alpha: 0.08) : BovaraColors.surfaceMuted;
    final borderColor =
        onDarkBackground ? BovaraColors.borderOnDark : BovaraColors.border;
    final textColor =
        onDarkBackground ? BovaraColors.textOnDark : BovaraColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(BovaraRadius.pill),
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(BovaraRadius.pill),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, size: 18, color: textColor),
                  const SizedBox(width: 8),
                ],
                Text(label, style: BovaraText.label(size: 15, color: textColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón "ghost": solo texto, sin caja. Ideal para "Saltar", "Cancelar".
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool onDarkBackground;

  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.onDarkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = onDarkBackground
        ? BovaraColors.textOnDark.withValues(alpha: 0.85)
        : BovaraColors.textSecondary;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BovaraRadius.pill),
        ),
      ),
      child: Text(label, style: BovaraText.label(size: 14, color: color)),
    );
  }
}

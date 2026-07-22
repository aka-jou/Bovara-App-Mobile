// lib/core/widgets/bovara_chips.dart
//
// Chips estándar del rediseño:
//   - GlassChip: pill translúcido con blur (para overlays sobre fotos).
//   - TagChip: chip sólido con par bg+text semántico (info/success/celo/…).

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Chip translúcido con blur y borde blanco tenue. Usado sobre imágenes
/// de fondo (onboarding, welcome). Opcionalmente incluye un punto de color
/// pulsante a la izquierda.
class GlassChip extends StatelessWidget {
  final String label;
  final Color? dotColor;
  final EdgeInsets padding;

  const GlassChip({
    super.key,
    required this.label,
    this.dotColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(BovaraRadius.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF141814).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(BovaraRadius.pill),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: dotColor!, blurRadius: 8),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: BovaraText.caption(color: Colors.white).copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip sólido para etiquetas semánticas: success, info, warning, danger, celo.
class TagChip extends StatelessWidget {
  final String label;
  final TagChipVariant variant;
  final IconData? icon;
  final EdgeInsets padding;

  const TagChip({
    super.key,
    required this.label,
    this.variant = TagChipVariant.neutral,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      TagChipVariant.success => (BovaraColors.primarySoftBg, BovaraColors.primarySoftText),
      TagChipVariant.info => (BovaraColors.infoSoftBg, BovaraColors.info),
      TagChipVariant.warning => (BovaraColors.warningSoftBg, BovaraColors.warning),
      TagChipVariant.danger => (BovaraColors.dangerSoftBg, BovaraColors.danger),
      TagChipVariant.celo => (BovaraColors.celoSoftBg, BovaraColors.celoSoftText),
      TagChipVariant.neutral => (BovaraColors.surfaceMuted, BovaraColors.textSecondary),
    };

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(BovaraRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: BovaraText.label(size: 11, color: fg).copyWith(
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

enum TagChipVariant { neutral, success, info, warning, danger, celo }

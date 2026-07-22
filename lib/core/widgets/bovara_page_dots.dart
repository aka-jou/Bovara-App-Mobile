// lib/core/widgets/bovara_page_dots.dart
//
// Indicador de página estilo píldora: el dot activo se estira hasta
// 28px, los inactivos son puntos de 6px con opacidad reducida.
// Del rediseño, se usa en onboarding y en cualquier carrusel.

import 'package:flutter/material.dart';
import '../theme/theme.dart';

class BovaraPageDots extends StatelessWidget {
  final int count;
  final int activeIndex;
  final bool onDarkBackground;
  final ValueChanged<int>? onTap;

  const BovaraPageDots({
    super.key,
    required this.count,
    required this.activeIndex,
    this.onDarkBackground = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor =
        onDarkBackground ? BovaraColors.primary : BovaraColors.primary;
    final inactiveColor = onDarkBackground
        ? Colors.white.withValues(alpha: 0.25)
        : BovaraColors.borderMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        final dot = AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 28 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(BovaraRadius.pill),
          ),
        );

        if (onTap == null) return dot;
        return GestureDetector(
          onTap: () => onTap!(i),
          behavior: HitTestBehavior.opaque,
          child: dot,
        );
      }),
    );
  }
}

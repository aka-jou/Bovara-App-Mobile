// lib/core/widgets/bovara_status_bar.dart
//
// "Falsa" barra de estado (9:41 + barras de señal) que aparece en cada
// mockup del prototipo. En la app real el sistema operativo la reemplaza,
// pero la dejamos como widget para mantener el diseño coherente cuando
// SafeArea muestra el área bajo la barra real.
//
// Uso: BovaraStatusBar() dentro de un Stack, alineado top.

import 'package:flutter/material.dart';

class BovaraStatusBar extends StatelessWidget {
  final Color color;
  final String time;

  const BovaraStatusBar({
    super.key,
    this.color = Colors.white,
    this.time = '9:41',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Padding(
        padding: const EdgeInsets.only(left: 26, right: 26, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final h in [6.0, 9.0, 12.0, 15.0]) ...[
                  Container(
                    width: 3,
                    height: h,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  if (h != 15.0) const SizedBox(width: 3),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

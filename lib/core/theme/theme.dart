// lib/core/theme/theme.dart
//
// Sistema de diseño Bovara — Rediseño 2026
//
// Extraído del prototipo de Claude Design (Bovara_Rediseño_dc.html).
// Este archivo es la ÚNICA fuente de verdad de colores, tipografías y
// tokens visuales. Todos los widgets y pantallas leen de aquí. Cualquier
// color hexadecimal hardcodeado en otra parte del código es un error a
// corregir.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════
// Paleta — nombres semánticos, no descriptivos ("primary" no "green")
// ═══════════════════════════════════════════════════════════════════

class BovaraColors {
  // Fondos de la app (dark)
  static const Color background = Color(0xFF0B0D0B);       // fondo global de la app (casi negro verdoso)
  static const Color backgroundElevated = Color(0xFF1A1D19); // slots de imagen, contenedores oscuros
  static const Color darkBar = Color(0xFF16201A);          // bottom nav, botones oscuros

  // Superficies claras (los "sheets" que suben desde el fondo oscuro)
  static const Color surface = Color(0xFFFBFBF8);          // sheets, cards principales
  static const Color surfaceAlt = Color(0xFFF1F1EC);       // superficies secundarias
  static const Color surfaceMuted = Color(0xFFF2F3ED);     // fondos de campos, chips inactivos

  // Texto
  static const Color textPrimary = Color(0xFF16201A);      // texto principal sobre superficies claras
  static const Color textSecondary = Color(0xFF5C6B60);    // texto secundario
  static const Color textMuted = Color(0xFF8A9488);        // hints, íconos idle
  static const Color textDisabled = Color(0xFF9AA79C);     // texto deshabilitado
  static const Color textOnDark = Color(0xFFEEF2EC);       // texto sobre fondo oscuro
  static const Color textOnDarkMuted = Color(0xFFC5CCC3);  // texto secundario sobre oscuro

  // Bordes
  static const Color border = Color(0xFFE7EAE3);           // borde estándar de card/input
  static const Color borderMuted = Color(0xFFD8DCD4);      // borde muy sutil
  static const Color borderOnDark = Color(0x1AFFFFFF);     // borde sobre fondo oscuro (10% blanco)

  // Marca — verde
  static const Color primary = Color(0xFF2E8B45);          // verde vivo (botones, chips activos)
  static const Color primaryDark = Color(0xFF1E6B34);      // verde oscuro (final del gradient)
  static const Color primaryDeep = Color(0xFF17532A);      // verde más profundo
  static const Color primarySoftBg = Color(0xFFDCEEDF);    // fondo suave para chips/badges
  static const Color primarySoftText = Color(0xFF1E6B34);  // texto sobre fondo suave

  // Semánticos — mismos que el prototipo, con pares bg+text
  static const Color info = Color(0xFF2F6FEB);
  static const Color infoSoftBg = Color(0xFFE3ECFD);

  static const Color warning = Color(0xFFE8912A);
  static const Color warningSoftBg = Color(0xFFFEF0DC);

  static const Color danger = Color(0xFFD6453C);
  static const Color dangerSoftBg = Color(0xFFFCE1DE);

  static const Color celo = Color(0xFFD6407A);             // rosa para eventos de celo
  static const Color celoSoftBg = Color(0xFFFCE3EE);
  static const Color celoSoftText = Color(0xFFB03A6B);

  // Gradients (usar con LinearGradient)
  static const List<Color> primaryGradient = [primary, primaryDark];
  static const List<Color> darkFadeGradient = [
    Color(0x8C0B0D0B), // 55%
    Color(0x260B0D0B), // 15%
    Color(0x8C0B0D0B), // 55%
    Color(0xF00B0D0B), // 94%
  ];
}

// ═══════════════════════════════════════════════════════════════════
// Tipografía
//   - Logotipo: Changa One (solo para la palabra "Bovara")
//   - Cuerpo:   Roboto — usamos Roboto de Google Fonts.
// ═══════════════════════════════════════════════════════════════════

class BovaraText {
  // Logotipo (usa Changa One)
  static TextStyle logo({double size = 24, Color? color}) => GoogleFonts.changaOne(
        fontSize: size,
        color: color ?? BovaraColors.textOnDark,
        letterSpacing: size * 0.005,
        height: 1.0,
      );

  // Display — titulares grandes de onboarding y bienvenida
  static TextStyle display({Color? color}) => GoogleFonts.roboto(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: -0.54, // -0.015em
        color: color ?? BovaraColors.textOnDark,
      );

  // Títulos de pantalla
  static TextStyle title({Color? color}) => GoogleFonts.roboto(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.2,
        color: color ?? BovaraColors.textPrimary,
      );

  // Encabezados de sección
  static TextStyle heading({Color? color}) => GoogleFonts.roboto(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: color ?? BovaraColors.textPrimary,
      );

  // Cuerpo estándar
  static TextStyle body({Color? color, double size = 14}) => GoogleFonts.roboto(
        fontSize: size,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color ?? BovaraColors.textPrimary,
      );

  // Texto secundario (subtítulos, hints)
  static TextStyle secondary({Color? color, double size = 13}) => GoogleFonts.roboto(
        fontSize: size,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: color ?? BovaraColors.textSecondary,
      );

  // Etiquetas de acción (botones, chips)
  static TextStyle label({Color? color, double size = 14}) => GoogleFonts.roboto(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.2,
        color: color ?? BovaraColors.textPrimary,
      );

  // Overline — "01 · PRESENTACIÓN"
  static TextStyle overline({Color? color}) => GoogleFonts.roboto(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.76, // 0.16em
        height: 1.4,
        color: color ?? BovaraColors.textMuted,
      );

  // Caption — timestamps, metadata
  static TextStyle caption({Color? color}) => GoogleFonts.roboto(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.23, // 0.02em
        height: 1.3,
        color: color ?? BovaraColors.textMuted,
      );
}

// ═══════════════════════════════════════════════════════════════════
// Radios y espaciados
// ═══════════════════════════════════════════════════════════════════

class BovaraRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double pill = 999;
}

class BovaraSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

// ═══════════════════════════════════════════════════════════════════
// Sombras
// ═══════════════════════════════════════════════════════════════════

class BovaraShadow {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x14000000), // 8% negro
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> button = [
    BoxShadow(
      color: Color(0x59176B34), // gradient del botón primario
      blurRadius: 22,
      offset: Offset(0, 10),
      spreadRadius: -10,
    ),
  ];

  static const List<BoxShadow> sheet = [
    BoxShadow(
      color: Color(0x8C000000), // 55% negro
      blurRadius: 80,
      offset: Offset(0, 40),
      spreadRadius: -30,
    ),
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 26,
      offset: Offset(0, 10),
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════════
// ThemeData de Material
// ═══════════════════════════════════════════════════════════════════

ThemeData buildBovaraTheme() {
  final base = ThemeData(brightness: Brightness.dark);
  return base.copyWith(
    useMaterial3: true,
    scaffoldBackgroundColor: BovaraColors.background,
    colorScheme: const ColorScheme.dark(
      primary: BovaraColors.primary,
      onPrimary: Colors.white,
      secondary: BovaraColors.celo,
      onSecondary: Colors.white,
      surface: BovaraColors.surface,
      onSurface: BovaraColors.textPrimary,
      error: BovaraColors.danger,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.robotoTextTheme(base.textTheme).apply(
      bodyColor: BovaraColors.textOnDark,
      displayColor: BovaraColors.textOnDark,
    ),
    splashColor: BovaraColors.primary.withValues(alpha: 0.08),
    highlightColor: Colors.transparent,
  );
}

// Alias para mantener compatibilidad con imports viejos.
final ThemeData bovaraTheme = buildBovaraTheme();

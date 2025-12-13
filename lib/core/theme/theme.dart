// lib/src/core/constants/theme.dart
import 'package:flutter/material.dart';

const Color primaryGreen = Color(0xFF2E7D32);
const Color secondaryBrown = Color(0xFF8D6E63);
const Color backgroundLight = Color(0xFFF5F5F5);
const Color scaffoldDark = Color(0xFF151515);

final ThemeData bovaraTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: primaryGreen,
    secondary: secondaryBrown,
    background: backgroundLight,
  ),
  scaffoldBackgroundColor: scaffoldDark,
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: Color(0xFF222222),
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      color: Color(0xFF616161),
    ),
  ),
);

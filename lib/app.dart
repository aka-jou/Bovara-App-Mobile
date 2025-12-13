
import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
// importa tu tema si ya lo tienes
// import 'core/theme/theme.dart';

class BovaraApp extends StatelessWidget {
  const BovaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Bovara',
      // theme: bovaraTheme,  // si ya tienes theme central
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2E7D32),
          background: Color(0xFFF5F5F5),
        ),
      ),
      routerConfig: appRouter,     // 👈 aquí conectamos go_router
    );
  }
}

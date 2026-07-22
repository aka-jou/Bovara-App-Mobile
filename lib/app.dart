import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/router/app_router.dart';
import 'core/theme/theme.dart';

class BovaraApp extends StatelessWidget {
  const BovaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    // La app entera es dark: barra de estado del sistema con íconos claros.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: BovaraColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Bovara',
      theme: buildBovaraTheme(),
      routerConfig: appRouter,
    );
  }
}

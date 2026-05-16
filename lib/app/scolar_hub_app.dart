import 'package:flutter/material.dart';

import '../pages/splash_screen.dart';
import '../theme/app_palette.dart';

class ScolarHubApp extends StatelessWidget {
  const ScolarHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ScolarHub',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: AppPalette.blue,
          secondary: AppPalette.yellow,
          surface: AppPalette.white,
          onPrimary: AppPalette.white,
          onSecondary: AppPalette.black,
          onSurface: AppPalette.black,
        ),
        scaffoldBackgroundColor: AppPalette.white,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: AppPalette.black,
          displayColor: AppPalette.black,
        ),
        cardTheme: CardThemeData(
          color: AppPalette.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

import 'package:flutter/material.dart';

import '../pages/splash_screen.dart';
import '../admin/admin_theme.dart';


class ScolarHubApp extends StatelessWidget {
  const ScolarHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'ScolarHub',

      theme: AdminTheme.buildTheme(Brightness.light),

      darkTheme: AdminTheme.buildTheme(Brightness.dark),

      themeMode: ThemeMode.system,

      home: const SplashScreen(),
    );
  }
}
import 'package:flutter/material.dart';

import '../pages/splash_screen.dart';
import '../admin/admin_theme.dart';


class ScolarHubApp extends StatelessWidget {
  const ScolarHubApp({super.key});

  /// Navigateur global : permet de naviguer (ex. déconnexion) sans dépendre
  /// du context d'une page qui a pu être retirée de l'arbre.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      navigatorKey: navigatorKey,

      title: 'ScolarHub',

      theme: AdminTheme.buildTheme(Brightness.light),

      darkTheme: AdminTheme.buildTheme(Brightness.dark),

      themeMode: ThemeMode.system,

      home: const SplashScreen(),
    );
  }
}
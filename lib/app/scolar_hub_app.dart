import 'package:flutter/material.dart';

import '../pages/splash_screen.dart';
import '../pages/auth_page.dart';
import '../pages/choose_school_page.dart';
import '../admin/admin_theme.dart';


class ScolarHubApp extends StatelessWidget {
  const ScolarHubApp({super.key});

  /// Navigateur global : permet de naviguer (ex. déconnexion) sans dépendre
  /// du context d'une page qui a pu être retirée de l'arbre.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Lien d'activation reçu par SMS/email : http://.../?matricule=XXX
    // → on ouvre directement la connexion avec le matricule pré-rempli.
    final matriculeLien = Uri.base.queryParameters['matricule']?.trim();
    final Widget accueil =
        (matriculeLien != null && matriculeLien.isNotEmpty)
            ? AuthPage(
                etablissement: kEtablissements.firstWhere(
                  (e) => e.disponible,
                  orElse: () => kEtablissements.first,
                ),
                matriculePrefill: matriculeLien,
              )
            : const SplashScreen();

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      navigatorKey: navigatorKey,

      title: 'ScolarHub',

      theme: AdminTheme.buildTheme(Brightness.light),

      darkTheme: AdminTheme.buildTheme(Brightness.dark),

      themeMode: ThemeMode.system,

      home: accueil,
    );
  }
}
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

      // ✅ CORRIGÉ — l'app n'est pas conçue pour le mode sombre (quasi tout
      // l'UI utilise des couleurs codées en dur pensées pour un fond clair :
      // champs de saisie blancs, texte bleu foncé, etc.). Avec
      // ThemeMode.system, un téléphone en mode sombre système (ou un
      // navigateur mobile qui force le mode sombre sur les sites web, ex.
      // Chrome Android) pouvait rendre certains éléments illisibles
      // (champs sombres, texte invisible). On force donc le thème clair
      // partout, indépendamment du thème système/navigateur.
      theme: AdminTheme.buildTheme(Brightness.light),

      darkTheme: AdminTheme.buildTheme(Brightness.light),

      themeMode: ThemeMode.light,

      home: accueil,
    );
  }
}
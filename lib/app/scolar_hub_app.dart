import 'package:flutter/material.dart';

import '../pages/splash_screen.dart';
import '../pages/auth_page.dart';
import '../pages/choose_school_page.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_shell.dart';
import '../models/student_profile.dart';
import '../pages/bureau_des_etudiants.dart';
import '../pages/parent/parent_shell.dart';
import '../pages/student_shell.dart';
import '../professeur/professor_shell.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../services/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
            : const _Demarrage();

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

      // Suit l'activité et applique la déconnexion automatique choisie.
      builder: (context, child) => SessionWatcher(child: child ?? const SizedBox.shrink()),

      home: accueil,
    );
  }
}

/// Premier écran : reprend la session mémorisée (si la politique de session
/// l'autorise) et ouvre directement l'espace, sinon affiche l'accueil habituel.
class _Demarrage extends StatefulWidget {
  const _Demarrage();
  @override
  State<_Demarrage> createState() => _DemarrageState();
}

class _DemarrageState extends State<_Demarrage> {
  bool _fini = false;
  StudentProfile? _profil;

  @override
  void initState() {
    super.initState();
    SessionService.restaurer().then((p) {
      if (!mounted) return;
      if (p != null) {
        SocketService().connect(p.matricule);
        SharedPreferences.getInstance().then((prefs) => prefs.setString('matricule', p.matricule));
      }
      setState(() {
        _profil = p;
        _fini = true;
      });
    });
  }

  void _logout() {
    ApiService.clearToken().then((_) {
      SessionService.oublier();
      ScolarHubApp.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (_) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_fini) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final p = _profil;
    if (p == null) return const SplashScreen();
    final r = p.role.toLowerCase().trim();
    if (r == 'admin' || r == 'admi' || r == 'administrator') {
      return AdminShell(profile: p, onLogout: _logout);
    } else if (r == 'prof' || r == 'professeur' || r == 'enseignant' || r == 'teacher') {
      return ProfessorShell(profile: p, onLogout: _logout);
    } else if (r == 'parent' || r == 'tuteur') {
      return ParentShell(profile: p, onLogout: _logout);
    } else if (r == 'bde') {
      return const BureauDesEtudiantsScreen();
    }
    return StudentShell(profile: p, onLogout: _logout);
  }
}
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../app/scolar_hub_app.dart';
import '../models/student_profile.dart';
import '../pages/splash_screen.dart';
import 'api_service.dart';

/// Politique de session (par appareil).
///  • demander      : à chaque ouverture de l'application, on redemande les informations.
///  • inactivite10  : déconnexion après 10 minutes sans activité.
///  • septJours     : session gardée 7 jours (puis reconnexion).
///  • trenteJours   : session gardée 30 jours (puis reconnexion).
enum SessionMode { demander, inactivite10, septJours, trenteJours }

enum SessionFamille { etudiant, professeur, admin, autre }

class SessionService {
  SessionService._();

  static const _kProfil = 'session_profil';
  static const _kDebut = 'session_debut';
  static const _kActif = 'session_dernier_actif';
  static const _kMode = 'session_mode';

  static const Duration inactivite = Duration(minutes: 10);

  // ── Famille de compte ─────────────────────────────────────────────────────
  static SessionFamille famille(String role) {
    final r = role.toLowerCase().trim();
    if (r == 'admin' || r == 'admi' || r == 'administrator') return SessionFamille.admin;
    if (r == 'prof' || r == 'professeur' || r == 'enseignant' || r == 'teacher') return SessionFamille.professeur;
    if (r == 'parent' || r == 'tuteur') return SessionFamille.autre;
    return SessionFamille.etudiant; // étudiant, délégué, BDE…
  }

  /// Étudiant : 30 jours par défaut. Professeur / administration : on
  /// redemande toujours les informations tant que l'utilisateur n'a pas choisi autrement.
  static SessionMode modeParDefaut(String role) =>
      famille(role) == SessionFamille.etudiant ? SessionMode.trenteJours : SessionMode.demander;

  /// Choix proposés dans les paramètres selon le type de compte.
  static List<SessionMode> choix(String role) => switch (famille(role)) {
        SessionFamille.etudiant => [SessionMode.trenteJours, SessionMode.inactivite10, SessionMode.demander],
        _ => [SessionMode.demander, SessionMode.inactivite10, SessionMode.septJours],
      };

  static String libelle(SessionMode m) => switch (m) {
        SessionMode.demander => 'Toujours demander mes informations',
        SessionMode.inactivite10 => 'Déconnexion après 10 minutes d\'inactivité',
        SessionMode.septJours => 'Rester connecté 7 jours',
        SessionMode.trenteJours => 'Rester connecté 30 jours',
      };

  static String description(SessionMode m) => switch (m) {
        SessionMode.demander => 'À chaque ouverture de l\'application, vous devez vous reconnecter.',
        SessionMode.inactivite10 => 'Sans aucune activité pendant 10 minutes, vous êtes déconnecté.',
        SessionMode.septJours => 'Vous entrez directement dans l\'application pendant 7 jours, sauf déconnexion.',
        SessionMode.trenteJours => 'Vous entrez directement dans l\'application pendant 30 jours, sauf déconnexion.',
      };

  // ── Mode choisi ───────────────────────────────────────────────────────────
  static Future<SessionMode> mode(String role) async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getString(_kMode);
      for (final m in SessionMode.values) {
        if (m.name == v) return m;
      }
    } catch (_) {}
    return modeParDefaut(role);
  }

  static Future<void> definirMode(SessionMode m) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kMode, m.name);
    _dernierActif = DateTime.now();
    await p.setInt(_kActif, _dernierActif.millisecondsSinceEpoch);
  }

  // ── Mémorisation après connexion ──────────────────────────────────────────
  static Future<void> memoriser(StudentProfile p) async {
    try {
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) return; // comptes démo : rien à garder
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString(
        _kProfil,
        jsonEncode({
          'nom': p.nom,
          'prenoms': p.prenoms,
          'matricule': p.matricule,
          'email': p.email,
          'telephone': p.telephone,
          'filiere': p.filiere,
          'domaine': p.domaine,
          'niveau': p.niveau,
          'role': p.role,
          'adminSubRole': p.adminSubRole,
          'domaineAdmin': p.domaineAdmin,
          'filiereRole': p.filiereRole,
          'photoUrl': p.photoUrl,
          'coverUrl': p.coverUrl,
          'enfantNom': p.enfantNom,
          'matriculeEnfant': p.matriculeEnfant,
          'adresse': p.adresse,
          'attestationUrl': p.attestationUrl,
          'langue': p.langue,
          'notificationsActives': p.notificationsActives,
        }),
      );
      await prefs.setInt(_kDebut, now.millisecondsSinceEpoch);
      _dernierActif = now;
      await prefs.setInt(_kActif, now.millisecondsSinceEpoch);
    } catch (_) {}
  }

  static Future<void> oublier() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kProfil);
      await prefs.remove(_kDebut);
      await prefs.remove(_kActif);
    } catch (_) {}
  }

  // ── Reprise automatique au démarrage ──────────────────────────────────────
  /// Renvoie le profil à ouvrir directement, ou null (→ écran de connexion).
  static Future<StudentProfile?> restaurer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await ApiService.getToken();
      final brut = prefs.getString(_kProfil);
      if (token == null || token.isEmpty || brut == null) return null;
      final m = Map<String, dynamic>.from(jsonDecode(brut) as Map);
      final role = (m['role'] ?? 'etudiant').toString();

      final mode = await SessionService.mode(role);
      if (mode == SessionMode.demander) {
        await ApiService.clearToken();
        await oublier();
        return null;
      }
      if (_expire(mode, prefs)) {
        await ApiService.clearToken();
        await oublier();
        return null;
      }

      // Le jeton est-il encore accepté par le serveur ?
      var roleFrais = role;
      String? photo = m['photoUrl'] as String?;
      String? cover = m['coverUrl'] as String?;
      try {
        final res = await http
            .get(Uri.parse('${ApiService.baseUrl}/auth/me'), headers: await ApiService.getHeaders())
            .timeout(const Duration(seconds: 8));
        if (res.statusCode == 401 || res.statusCode == 403 || res.statusCode == 404) {
          await ApiService.clearToken();
          await oublier();
          return null;
        }
        if (res.statusCode == 200) {
          final me = jsonDecode(utf8.decode(res.bodyBytes));
          if (me is Map) {
            roleFrais = (me['role'] ?? role).toString();
            photo = (me['photo_url'] ?? photo)?.toString();
            cover = (me['cover_url'] ?? cover)?.toString();
          }
        }
      } catch (_) {
        // Hors ligne : on garde la session locale.
      }

      _dernierActif = DateTime.now();
      await prefs.setInt(_kActif, _dernierActif.millisecondsSinceEpoch);
      String? s(String k) => m[k] as String?;
      return StudentProfile(
        nom: s('nom') ?? '',
        prenoms: s('prenoms') ?? '',
        matricule: s('matricule') ?? '',
        email: s('email') ?? '',
        telephone: s('telephone') ?? '',
        filiere: s('filiere') ?? '',
        motDePasse: '',
        domaine: s('domaine') ?? '',
        niveau: s('niveau') ?? '',
        role: roleFrais,
        adminSubRole: s('adminSubRole'),
        domaineAdmin: s('domaineAdmin') ?? 'Tous',
        filiereRole: s('filiereRole'),
        photoUrl: photo,
        coverUrl: cover,
        enfantNom: s('enfantNom'),
        matriculeEnfant: s('matriculeEnfant'),
        adresse: s('adresse'),
        attestationUrl: s('attestationUrl'),
        langue: s('langue') ?? 'fr',
        notificationsActives: m['notificationsActives'] != false,
      );
    } catch (_) {
      return null;
    }
  }

  static bool _expire(SessionMode mode, SharedPreferences prefs) {
    final now = DateTime.now();
    final debut = DateTime.fromMillisecondsSinceEpoch(prefs.getInt(_kDebut) ?? 0);
    final actif = DateTime.fromMillisecondsSinceEpoch(prefs.getInt(_kActif) ?? 0);
    switch (mode) {
      case SessionMode.trenteJours:
        return now.difference(debut) > const Duration(days: 30);
      case SessionMode.septJours:
        return now.difference(debut) > const Duration(days: 7);
      case SessionMode.inactivite10:
        return now.difference(actif) > inactivite;
      case SessionMode.demander:
        return true;
    }
  }

  // ── Activité de l'utilisateur ─────────────────────────────────────────────
  static DateTime _dernierActif = DateTime.now();
  static DateTime _derniereEcriture = DateTime.fromMillisecondsSinceEpoch(0);

  static void toucher() {
    final now = DateTime.now();
    _dernierActif = now;
    if (now.difference(_derniereEcriture) < const Duration(seconds: 15)) return;
    _derniereEcriture = now;
    SharedPreferences.getInstance().then((p) => p.setInt(_kActif, now.millisecondsSinceEpoch)).catchError((_) => false);
  }

  /// Vérifie la session en cours (retour au premier plan, minuteur) et
  /// déconnecte si la durée choisie est dépassée.
  static Future<void> verifierExpiration() async {
    try {
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final brut = prefs.getString(_kProfil);
      if (brut == null) return;
      final role = (jsonDecode(brut) as Map)['role']?.toString() ?? 'etudiant';
      final mode = await SessionService.mode(role);
      if (mode == SessionMode.demander) return; // session en cours : reste ouverte jusqu'à fermeture
      final now = DateTime.now();
      final debut = DateTime.fromMillisecondsSinceEpoch(prefs.getInt(_kDebut) ?? now.millisecondsSinceEpoch);
      final expire = switch (mode) {
        SessionMode.inactivite10 => now.difference(_dernierActif) > inactivite,
        SessionMode.septJours => now.difference(debut) > const Duration(days: 7),
        SessionMode.trenteJours => now.difference(debut) > const Duration(days: 30),
        SessionMode.demander => false,
      };
      if (expire) await deconnecter();
    } catch (_) {}
  }

  static Future<void> deconnecter() async {
    await ApiService.clearToken();
    await oublier();
    ScolarHubApp.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }
}

/// Enveloppe l'application : suit l'activité (toucher, retour au premier plan)
/// et applique la déconnexion automatique choisie.
class SessionWatcher extends StatefulWidget {
  const SessionWatcher({super.key, required this.child});
  final Widget child;
  @override
  State<SessionWatcher> createState() => _SessionWatcherState();
}

class _SessionWatcherState extends State<SessionWatcher> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => SessionService.verifierExpiration());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) SessionService.verifierExpiration();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => SessionService.toucher(),
      onPointerSignal: (_) => SessionService.toucher(),
      child: widget.child,
    );
  }
}

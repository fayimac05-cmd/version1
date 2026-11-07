import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache local des messages des discussions (canaux, groupe de filière,
/// messages privés), pour toutes les interfaces (étudiant, professeur, admin).
///
/// Principe : à l'ouverture d'une discussion, on affiche tout de suite les
/// derniers messages déjà vus (mémoire, puis disque si l'appli vient d'être
/// relancée), puis on rafraîchit depuis le serveur en arrière-plan.
///
/// On stocke le JSON brut renvoyé par le serveur : aucune dépendance aux
/// modèles d'affichage de chaque écran.
class MessagesCache {
  MessagesCache._();

  static const int _max = 60; // derniers messages gardés par discussion
  static const String _prefixe = 'msgcache:';
  static final Map<String, List<dynamic>> _mem = {};

  /// Lecture immédiate (mémoire uniquement).
  static List<dynamic>? lire(String cle) => _mem[cle];

  /// Mémoire d'abord, sinon disque (premier affichage après relance).
  static Future<List<dynamic>?> lireOuDisque(String cle) async {
    final m = _mem[cle];
    if (m != null) return m;
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString('$_prefixe$cle');
      if (s == null) return null;
      final l = jsonDecode(s);
      if (l is List) {
        _mem[cle] = l;
        return l;
      }
    } catch (_) {}
    return null;
  }

  /// Remplace le cache d'une discussion par la liste fraîche du serveur.
  static void ecrire(String cle, List<dynamic> brut) {
    final l = brut.length > _max
        ? List<dynamic>.from(brut.sublist(brut.length - _max))
        : List<dynamic>.from(brut);
    _mem[cle] = l;
    _persister(cle, l);
  }

  /// Ajoute un message reçu en direct (socket) au cache, sans doublon.
  static void ajouter(String cle, Map<String, dynamic> message) {
    final l = _mem[cle];
    if (l == null) return; // pas encore de cache : le prochain chargement le crée
    final id = message['id']?.toString();
    if (id != null && l.any((m) => m is Map && m['id']?.toString() == id)) return;
    l.add(message);
    ecrire(cle, l);
  }

  static Future<void> _persister(String cle, List<dynamic> l) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefixe$cle', jsonEncode(l));
    } catch (_) {
      // Stockage plein ou indisponible : le cache mémoire reste actif.
    }
  }

  // Petites valeurs texte (ex. filière de l'utilisateur) pour démarrer sans réseau.
  static Future<String?> lireTexte(String cle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_prefixe$cle');
    } catch (_) {
      return null;
    }
  }

  static Future<void> ecrireTexte(String cle, String valeur) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefixe$cle', valeur);
    } catch (_) {}
  }

  /// À appeler à la déconnexion : efface tous les messages gardés sur l'appareil.
  static Future<void> vider() async {
    _mem.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in prefs.getKeys().where((k) => k.startsWith(_prefixe)).toList()) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }
}

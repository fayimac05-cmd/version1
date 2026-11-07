import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'messages_cache.dart';

/// Précharge en arrière-plan, juste après la connexion, les messages des
/// discussions principales : canaux, groupe de filière et conversations
/// privées récentes. Ils sont écrits dans [MessagesCache], donc la première
/// ouverture d'une discussion est instantanée.
///
/// Utilisé pour l'étudiant et le professeur (mêmes clés de cache que les écrans).
class MessagesPrefetch {
  MessagesPrefetch._();

  static bool _dejaLance = false;
  static const int _maxPrives = 8;

  /// À appeler une fois à l'ouverture de l'espace connecté. Sans effet si déjà fait.
  static void lancer() {
    if (_dejaLance) return;
    _dejaLance = true;
    // Petit délai : l'accueil se charge d'abord, le préchargement passe après.
    Future.delayed(const Duration(seconds: 2), _executer);
  }

  /// À appeler à la déconnexion, avec MessagesCache.vider().
  static void reinitialiser() => _dejaLance = false;

  static Future<void> _executer() async {
    try {
      final uid = await ApiService.getUserId() ?? '';
      if (uid.isEmpty) return;
      final headers = await ApiService.getHeaders();
      final base = ApiService.baseUrl;

      // 1. Récupération des listes (en parallèle)
      final listes = await Future.wait([
        _json('$base/messages/canaux-standard', headers), // canaux standard
        _json('$base/auth/me', headers), // filière
        _json('$base/messages/prives', headers), // conversations privées
        _json('$base/canaux/mon-admin-filiere', headers), // canal admin de filière
        _json('$base/canaux/admin-filieres', headers), // administrateur : un canal par filière/niveau
        _json('$base/professeurs/mes-canaux-coordination', headers), // professeur : coordination
      ]);

      final taches = <Future<void> Function()>[];

      // Canaux standard (ceux interdits à ce rôle répondent par une erreur : ignorés)
      final std = listes[0];
      final stdData = std is Map ? std['data'] : null;
      if (stdData is Map) {
        for (final id in stdData.values.map((v) => v.toString()).toSet()) {
          taches.add(() => _charger('$base/messages/canal/$id', 'canal:$id:$uid', headers));
        }
      }

      // Canal admin de la filière (étudiant)
      final mon = listes[3];
      final monData = mon is Map ? mon['data'] : null;
      final canalFiliere = monData is Map ? monData['canal_id']?.toString() : null;
      if (canalFiliere != null && canalFiliere.isNotEmpty) {
        taches.add(() => _charger(
            '$base/messages/canal/$canalFiliere', 'canal:$canalFiliere:$uid', headers));
      }

      // Canaux par (filière, niveau) : administrateur et professeur.
      // Les rôles non concernés reçoivent une erreur : ignorée.
      for (final idx in [4, 5]) {
        final r = listes[idx];
        final filieres = r is Map && r['data'] is List ? r['data'] as List : const [];
        for (final f in filieres) {
          final niveaux = f is Map && f['niveaux'] is List ? f['niveaux'] as List : const [];
          for (final n in niveaux) {
            final cid = n is Map ? n['canal_id']?.toString() : null;
            if (cid == null || cid.isEmpty) continue;
            taches.add(() => _charger('$base/messages/canal/$cid', 'canal:$cid:$uid', headers));
          }
        }
      }

      // Groupe de la filière
      final me = listes[1];
      final raw = me is Map ? me['filiere_id'] : null;
      final filiere = raw is int ? raw : int.tryParse('$raw');
      if (filiere != null) {
        MessagesCache.ecrireTexte('filiere:$uid', '$filiere');
        taches.add(() =>
            _charger('$base/messages/groupe/$filiere', 'groupe:$filiere:$uid', headers));
      }

      // Conversations privées récentes
      final prives = listes[2];
      final privesData = prives is Map ? prives['data'] : null;
      if (privesData is List) {
        for (final c in privesData.take(_maxPrives)) {
          final id = c is Map ? c['correspondant_id']?.toString() : null;
          if (id == null || id.isEmpty) continue;
          taches.add(() => _charger('$base/messages/prives/$id', 'prive:$id:$uid', headers));
        }
      }

      // 2. Téléchargement par petits lots de 3, pour ne pas saturer le serveur
      for (var i = 0; i < taches.length; i += 3) {
        await Future.wait(taches.skip(i).take(3).map((t) => t()));
      }
    } catch (e) {
      debugPrint('[MessagesPrefetch] ignoré : $e');
    }
  }

  /// Préchargement d'une liste de discussions connue de l'appelant (écran admin).
  /// [cibles] : chemin relatif à l'API (ex. '/messages/canal/12') -> clé de cache.
  /// Téléchargement par lots de 3, à faible priorité, sans jamais bloquer l'écran.
  static Future<void> precharger(Map<String, String> cibles, {int max = 40}) async {
    try {
      final headers = await ApiService.getHeaders();
      final base = ApiService.baseUrl;
      final liste = cibles.entries.take(max).toList();
      for (var i = 0; i < liste.length; i += 3) {
        await Future.wait(liste
            .skip(i)
            .take(3)
            .map((e) => _charger('$base${e.key}', e.value, headers)));
      }
    } catch (e) {
      debugPrint('[MessagesPrefetch] ignoré : $e');
    }
  }

  static Future<dynamic> _json(String url, Map<String, String> headers) async {
    try {
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode != 200) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  static Future<void> _charger(
      String url, String cle, Map<String, String> headers) async {
    final body = await _json(url, headers);
    if (body == null) return;
    final data = (body is Map ? body['data'] : body);
    if (data is List) MessagesCache.ecrire(cle, data);
  }
}

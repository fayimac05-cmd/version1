import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

// ════════════════════════════════════════════════════════════════════════
// MODE HORS LIGNE — pour toute l'application, sans toucher aux écrans
//
// OfflineCacheClient s'intercale devant TOUTES les requêtes http de l'app
// (voir main.dart : http.runWithClient). Pour chaque requête GET vers notre
// serveur :
//   • réponse reçue (200)            → on en garde une copie sur l'appareil ;
//   • pas de réseau / serveur endormi (erreur ou 502-504) → on rend la
//     dernière copie connue, comme si le serveur avait répondu, et on
//     allume le bandeau « Mode hors ligne ».
// Les copies sont rangées par utilisateur (jamais mélangées entre comptes) et
// sous le préfixe « cache_http_ » : ApiService.clearToken() les efface déjà à
// la déconnexion.
// ════════════════════════════════════════════════════════════════════════

/// État « hors ligne » de l'application (null = en ligne).
class HorsLigne {
  HorsLigne._();

  /// Date des données affichées quand on est hors ligne ; null si en ligne.
  static final ValueNotifier<DateTime?> depuis = ValueNotifier<DateTime?>(null);
  static Timer? _sonde;

  static void marquerHorsLigne(DateTime? dateDonnees) {
    depuis.value = dateDonnees ?? DateTime.now();
    _sonde ??= Timer.periodic(const Duration(seconds: 15), (_) => _verifierRetour());
  }

  static void marquerEnLigne() {
    if (depuis.value != null) depuis.value = null;
    _sonde?.cancel();
    _sonde = null;
  }

  // Tant qu'on est hors ligne, on teste régulièrement le retour du réseau.
  static Future<void> _verifierRetour() async {
    try {
      final racine = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
      final r = await http.Client().get(Uri.parse('$racine/health')).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) marquerEnLigne();
    } catch (_) {}
  }
}

class OfflineCacheClient extends http.BaseClient {
  OfflineCacheClient(this._inner);
  final http.Client _inner;

  static const _prefixe = 'cache_http_';
  static const _tailleMax = 600 * 1024; // une réponse plus grosse n'est pas gardée
  static const _totalMax = 3 * 1024 * 1024; // plafond total des copies
  static int _ecritures = 0;

  // Le client est partagé : http.get() le « ferme » après chaque appel, on ignore.
  @override
  void close() {}

  bool _aMettreEnCache(http.BaseRequest r) {
    if (r.method != 'GET') return false;
    final url = r.url.toString();
    if (!url.startsWith(ApiService.baseUrl)) return false;
    final chemin = r.url.path;
    if (chemin.contains('/auth/') && !chemin.endsWith('/auth/me')) return false;
    return true;
  }

  static int _hash(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h;
  }

  Future<String> _cle(http.BaseRequest r) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id') ?? '';
    return '$_prefixe${_hash('$uid|${r.url}').toRadixString(16)}';
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!_aMettreEnCache(request)) return _inner.send(request);

    final cle = await _cle(request);
    http.StreamedResponse reseau;
    try {
      reseau = await _inner.send(request);
    } catch (e) {
      final copie = await _lire(cle);
      if (copie != null) return copie;
      rethrow; // rien en cache : l'écran affiche son erreur habituelle
    }

    // Serveur endormi / indisponible : on préfère la dernière copie connue.
    if (reseau.statusCode >= 502 && reseau.statusCode <= 504) {
      final copie = await _lire(cle);
      if (copie != null) {
        await reseau.stream.drain<void>();
        return copie;
      }
      return reseau;
    }

    final octets = await reseau.stream.toBytes();
    if (reseau.statusCode == 200) {
      HorsLigne.marquerEnLigne();
      if (octets.length <= _tailleMax) {
        // On ne garde que du texte (JSON) : pas d'images ni de fichiers.
        final type = reseau.headers['content-type'] ?? '';
        if (type.contains('json') || type.contains('text')) {
          unawaited(_ecrire(cle, octets));
        }
      }
    }
    return http.StreamedResponse(
      Stream<List<int>>.value(octets),
      reseau.statusCode,
      contentLength: octets.length,
      request: reseau.request,
      headers: reseau.headers,
      isRedirect: reseau.isRedirect,
      persistentConnection: reseau.persistentConnection,
      reasonPhrase: reseau.reasonPhrase,
    );
  }

  Future<void> _ecrire(String cle, List<int> octets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cle, jsonEncode({'t': DateTime.now().millisecondsSinceEpoch, 'b': utf8.decode(octets, allowMalformed: true)}));
      if (++_ecritures % 25 == 0) await _elaguer(prefs);
    } catch (_) {}
  }

  // Garde le total sous le plafond en retirant les copies les plus anciennes.
  Future<void> _elaguer(SharedPreferences prefs) async {
    final entrees = <(String, int, int)>[];
    var total = 0;
    for (final k in prefs.getKeys().where((k) => k.startsWith(_prefixe))) {
      final v = prefs.getString(k);
      if (v == null) continue;
      var t = 0;
      try {
        t = (jsonDecode(v) as Map)['t'] as int;
      } catch (_) {}
      entrees.add((k, t, v.length));
      total += v.length;
    }
    if (total <= _totalMax) return;
    entrees.sort((a, b) => a.$2.compareTo(b.$2));
    for (final e in entrees) {
      if (total <= _totalMax) break;
      await prefs.remove(e.$1);
      total -= e.$3;
    }
  }

  Future<http.StreamedResponse?> _lire(String cle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final brut = prefs.getString(cle);
      if (brut == null) return null;
      final m = jsonDecode(brut) as Map<String, dynamic>;
      final octets = utf8.encode(m['b'] as String);
      final date = DateTime.fromMillisecondsSinceEpoch(m['t'] as int);
      HorsLigne.marquerHorsLigne(date);
      return http.StreamedResponse(
        Stream<List<int>>.value(octets),
        200,
        contentLength: octets.length,
        headers: {
          'content-type': 'application/json; charset=utf-8',
          'x-hors-ligne': '1',
          'x-donnees-du': date.toIso8601String(),
        },
      );
    } catch (_) {
      return null;
    }
  }
}

/// Bandeau « Mode hors ligne » à poser en haut d'un écran principal.
class BandeauHorsLigne extends StatelessWidget {
  const BandeauHorsLigne({super.key});

  String _quand(DateTime d) {
    final now = DateTime.now();
    final hm = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final memeJour = d.year == now.year && d.month == now.month && d.day == now.day;
    return memeJour ? 'aujourd\'hui à $hm' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} à $hm';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: HorsLigne.depuis,
      builder: (_, date, __) {
        if (date == null) return const SizedBox.shrink();
        return Material(
          color: const Color(0xFF334155),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Row(children: [
                const Icon(Icons.cloud_off_rounded, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Mode hors ligne · données d\'${_quand(date)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

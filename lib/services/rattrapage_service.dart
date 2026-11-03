import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Appels API du rattrapage (voir backend/src/controllers/rattrapage.controller.js)
/// et des paramètres de l'année académique (annees.controller.js).
/// Chaque méthode renvoie {'success': bool, 'data'?, 'message'?, 'error'?}.
class RattrapageService {
  static Future<Map<String, dynamic>> _appel(
    String methode,
    String chemin, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final h = await ApiService.getHeaders();
      final uri = Uri.parse('${ApiService.baseUrl}$chemin');
      late http.Response r;
      switch (methode) {
        case 'POST':
          r = await http.post(uri, headers: h, body: jsonEncode(body ?? {}));
          break;
        case 'PATCH':
          r = await http.patch(uri, headers: h, body: jsonEncode(body ?? {}));
          break;
        case 'PUT':
          r = await http.put(uri, headers: h, body: jsonEncode(body ?? {}));
          break;
        default:
          r = await http.get(uri, headers: h);
      }
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      if (r.statusCode >= 200 && r.statusCode < 300 && j is Map && j['success'] == true) {
        return {
          'success': true,
          'data': j['data'],
          'message': j['message'],
          'session_id': j['session_id'],
          'warnings': j['warnings'],
        };
      }
      final msg = (j is Map ? j['message'] : null) ?? 'Une erreur est survenue.';
      return {'success': false, 'error': msg.toString()};
    } catch (_) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  // ── Année académique ───────────────────────────────────────
  static Future<Map<String, dynamic>> anneeCourante() => _appel('GET', '/annees/courante');

  static Future<Map<String, dynamic>> reglerRattrapage(
    dynamic anneeId, {
    String? debut,
    String? fin,
    required String regle,
  }) =>
      _appel('PUT', '/annees/$anneeId/rattrapage',
          body: {'date_debut': debut, 'date_fin': fin, 'regle': regle});

  // ── Professeur ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> apercu(dynamic filiereId, String niveau) =>
      _appel('GET', '/rattrapage/apercu?filiere_id=$filiereId&niveau=${Uri.encodeQueryComponent(niveau)}');

  static Future<Map<String, dynamic>> creerSession({
    required dynamic filiereId,
    required String niveau,
    required dynamic moduleId,
    required List<Map<String, dynamic>> notes,
  }) =>
      _appel('POST', '/rattrapage/sessions', body: {
        'filiere_id': filiereId,
        'niveau': niveau,
        'module_id': moduleId,
        'notes': notes,
      });

  static Future<Map<String, dynamic>> envoyer(String sessionId) =>
      _appel('POST', '/rattrapage/sessions/$sessionId/envoyer');

  static Future<Map<String, dynamic>> mesSessions() => _appel('GET', '/rattrapage/mes-sessions');

  static Future<Map<String, dynamic>> detail(String sessionId) =>
      _appel('GET', '/rattrapage/sessions/$sessionId');

  // ── Administration ─────────────────────────────────────────
  static Future<Map<String, dynamic>> sessionsAdmin(String statut) =>
      _appel('GET', '/rattrapage/admin/sessions?statut=$statut');

  static Future<Map<String, dynamic>> valider(String sessionId) =>
      _appel('PATCH', '/rattrapage/admin/sessions/$sessionId/valider');

  static Future<Map<String, dynamic>> rejeter(String sessionId, String motif) =>
      _appel('PATCH', '/rattrapage/admin/sessions/$sessionId/rejeter', body: {'motif': motif});

  // ── Étudiant ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> maSituation() => _appel('GET', '/rattrapage/ma-situation');

  static Future<Map<String, dynamic>> mesNotes() => _appel('GET', '/rattrapage/mes-notes');
}

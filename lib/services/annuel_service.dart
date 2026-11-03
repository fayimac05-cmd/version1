import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Appels API de la fin d'année, des réinscriptions et des archives
/// (backend : annuel / reinscriptions / archives).
/// Chaque méthode renvoie {'success': bool, 'data'?, 'message'?, 'error'?, 'raw'?}.
/// 'raw' contient la réponse complète du serveur (utile pour les confirmations 409).
class AnnuelService {
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
      final raw = j is Map ? Map<String, dynamic>.from(j) : <String, dynamic>{};
      if (r.statusCode >= 200 && r.statusCode < 300 && raw['success'] == true) {
        return {'success': true, 'data': raw['data'], 'message': raw['message'], 'raw': raw};
      }
      return {
        'success': false,
        'error': (raw['message'] ?? 'Une erreur est survenue.').toString(),
        'raw': raw,
      };
    } catch (_) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.', 'raw': <String, dynamic>{}};
    }
  }

  // ── Administration : fin d'année ───────────────────────────
  static Future<Map<String, dynamic>> etat() => _appel('GET', '/annuel/etat');

  static Future<Map<String, dynamic>> apercuDecisions(dynamic filiereId, String niveau) =>
      _appel('GET', '/annuel/decisions?filiere_id=$filiereId&niveau=${Uri.encodeQueryComponent(niveau)}');

  static Future<Map<String, dynamic>> validerDecisions({
    required dynamic filiereId,
    required String niveau,
    Map<String, String> corrections = const {},
    bool forcer = false,
  }) =>
      _appel('POST', '/annuel/decisions', body: {
        'filiere_id': filiereId,
        'niveau': niveau,
        'corrections': corrections,
        'forcer': forcer,
      });

  static Future<Map<String, dynamic>> cloturer(String prochaineAnnee) =>
      _appel('POST', '/annuel/cloturer', body: {'prochaine_annee': prochaineAnnee});

  // ── Administration : réinscriptions ────────────────────────
  static Future<Map<String, dynamic>> listerReinscriptions(String statut) =>
      _appel('GET', '/reinscriptions/admin?statut=$statut');

  static Future<Map<String, dynamic>> validerReinscription(dynamic id, String reference, {String? montant}) =>
      _appel('PATCH', '/reinscriptions/admin/$id/valider',
          body: {'reference_recu': reference, if (montant != null && montant.trim().isNotEmpty) 'montant': montant.trim()});

  static Future<Map<String, dynamic>> refuserReinscription(dynamic id, String motif) =>
      _appel('PATCH', '/reinscriptions/admin/$id/refuser', body: {'motif': motif});

  static Future<Map<String, dynamic>> frais() => _appel('GET', '/reinscriptions/frais');

  static Future<Map<String, dynamic>> enregistrerFrais(List<Map<String, dynamic>> frais) =>
      _appel('PUT', '/reinscriptions/frais', body: {'frais': frais});

  // ── Étudiant ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> monStatut() => _appel('GET', '/reinscriptions/mon-statut');

  static Future<Map<String, dynamic>> demanderReinscription() => _appel('POST', '/reinscriptions/demander');

  static Future<Map<String, dynamic>> mesAnnees() => _appel('GET', '/archives/mes-annees');

  static Future<Map<String, dynamic>> monAnnee(String annee) =>
      _appel('GET', '/archives/mon-annee?annee=${Uri.encodeQueryComponent(annee)}');
}

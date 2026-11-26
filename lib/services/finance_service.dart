// lib/services/finance_service.dart
// Appels du module Finances. Contrairement aux helpers génériques d'ApiService,
// celui-ci conserve le message d'erreur du serveur (ex. « Le montant dépasse… »).
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Droits de l'utilisateur connecté dans le module Finances (chargés à l'ouverture de l'écran).
/// admin = direction/administration (tout) ; caisse = personnel de caisse (encaisser, clôturer, journal).
class FinDroits {
  FinDroits._();
  static bool admin = true;
  static bool caisse = true;
  static String role = '';
}

class FinanceService {
  FinanceService._();

  static Future<Map<String, dynamic>> _appel(
    String methode,
    String chemin, {
    Map<String, dynamic>? corps,
    Map<String, String>? requete,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      var uri = Uri.parse('${ApiService.baseUrl}/finances$chemin');
      if (requete != null && requete.isNotEmpty) {
        uri = uri.replace(queryParameters: requete);
      }
      late http.Response r;
      switch (methode) {
        case 'POST':
          r = await http.post(uri, headers: headers, body: jsonEncode(corps ?? {}));
          break;
        case 'PUT':
          r = await http.put(uri, headers: headers, body: jsonEncode(corps ?? {}));
          break;
        case 'DELETE':
          r = await http.delete(uri, headers: headers);
          break;
        default:
          r = await http.get(uri, headers: headers);
      }
      Map<String, dynamic> body = {};
      try {
        final d = jsonDecode(utf8.decode(r.bodyBytes));
        if (d is Map<String, dynamic>) body = d;
      } catch (_) {}
      final ok = r.statusCode >= 200 && r.statusCode < 300 && body['success'] != false;
      return {
        ...body,
        'success': ok,
        'status': r.statusCode,
        if (!ok) 'message': body['message'] ?? 'Erreur (${r.statusCode}).',
      };
    } catch (_) {
      return {'success': false, 'message': 'Serveur injoignable. Vérifie ta connexion.'};
    }
  }

  static Map<String, String> _q(Map<String, String?> m) =>
      {for (final e in m.entries) if (e.value != null && e.value!.isNotEmpty) e.key: e.value!};

  // ── Administration ──────────────────────────────────────────
  static Future<Map<String, dynamic>> rapport(String? annee) =>
      _appel('GET', '/rapport', requete: _q({'annee': annee}));

  static Future<Map<String, dynamic>> grilles(String? annee) =>
      _appel('GET', '/grilles', requete: _q({'annee': annee}));
  static Future<Map<String, dynamic>> creerGrille(Map<String, dynamic> g) =>
      _appel('POST', '/grilles', corps: g);
  static Future<Map<String, dynamic>> modifierGrille(dynamic id, Map<String, dynamic> g) =>
      _appel('PUT', '/grilles/$id', corps: g);
  static Future<Map<String, dynamic>> supprimerGrille(dynamic id) =>
      _appel('DELETE', '/grilles/$id');
  static Future<Map<String, dynamic>> dupliquerAnnee(String de, String vers) =>
      _appel('POST', '/grilles/dupliquer', corps: {'de': de, 'vers': vers});

  static Future<Map<String, dynamic>> etudiants({String? annee, String? filiereId, String? niveau, String? q, String? statut}) =>
      _appel('GET', '/etudiants',
          requete: _q({'annee': annee, 'filiere_id': filiereId, 'niveau': niveau, 'q': q, 'statut': statut}));
  static Future<Map<String, dynamic>> detailEtudiant(dynamic id, String? annee) =>
      _appel('GET', '/etudiants/$id', requete: _q({'annee': annee}));

  static Future<Map<String, dynamic>> encaisser(Map<String, dynamic> v, {String? annee}) =>
      _appel('POST', '/versements${annee == null ? '' : '?annee=$annee'}', corps: v);
  static Future<Map<String, dynamic>> annulerVersement(dynamic id, String motif) =>
      _appel('POST', '/versements/$id/annuler', corps: {'motif': motif});
  static Future<Map<String, dynamic>> recu(dynamic versementId) =>
      _appel('GET', '/versements/$versementId/recu');

  static Future<Map<String, dynamic>> ajouterRemise(dynamic etudiantId, num montant, String motif, {String? annee}) =>
      _appel('POST', '/remises${annee == null ? '' : '?annee=$annee'}',
          corps: {'etudiant_id': etudiantId, 'montant': montant, 'motif': motif});
  static Future<Map<String, dynamic>> supprimerRemise(dynamic id) => _appel('DELETE', '/remises/$id');

  static Future<Map<String, dynamic>> blocage(List<dynamic> ids, bool bloque, {String? motif}) =>
      _appel('POST', '/blocage', corps: {'etudiant_ids': ids, 'bloque': bloque, if (motif != null) 'motif': motif});

  static Future<Map<String, dynamic>> relancer({
    List<dynamic>? ids,
    bool tousImpayes = false,
    required List<String> canaux,
    String? message,
    String? annee,
  }) =>
      _appel('POST', '/relances${annee == null ? '' : '?annee=$annee'}', corps: {
        if (ids != null) 'etudiant_ids': ids,
        'tous_impayes': tousImpayes,
        'canaux': canaux,
        if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
      });

  static Future<Map<String, dynamic>> depenses(String? annee) =>
      _appel('GET', '/depenses', requete: _q({'annee': annee}));
  static Future<Map<String, dynamic>> creerDepense(Map<String, dynamic> d) =>
      _appel('POST', '/depenses', corps: d);
  static Future<Map<String, dynamic>> supprimerDepense(dynamic id) =>
      _appel('DELETE', '/depenses/$id');

  // ── Caisse ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> droits() => _appel('GET', '/droits');
  static Future<Map<String, dynamic>> caisseJour(String date) =>
      _appel('GET', '/caisse/jour', requete: {'date': date});
  static Future<Map<String, dynamic>> cloturerCaisse(String date, num especesComptees, String note) =>
      _appel('POST', '/caisse/cloture', corps: {'date': date, 'especes_comptees': especesComptees, 'note': note});
  static Future<Map<String, dynamic>> clotures({String? du, String? au}) =>
      _appel('GET', '/caisse/clotures', requete: _q({'du': du, 'au': au}));
  static Future<Map<String, dynamic>> versements({String? du, String? au, String? mode, String? caissier, String? q, String? statut, String? canal}) =>
      _appel('GET', '/versements',
          requete: _q({'du': du, 'au': au, 'mode': mode, 'caissier': caissier, 'q': q, 'statut': statut, 'canal': canal}));

  // ── Étudiant / parent ───────────────────────────────────────
  static Future<Map<String, dynamic>> maSituation() => _appel('GET', '/ma-situation');
  static Future<Map<String, dynamic>> situationEnfant(dynamic etudiantId) =>
      _appel('GET', '/enfant/$etudiantId/situation');
  static Future<Map<String, dynamic>> payer({
    dynamic etudiantId,
    required num montant,
    required String operateur,
    required String telephone,
  }) =>
      _appel('POST', '/payer', corps: {
        if (etudiantId != null) 'etudiant_id': etudiantId,
        'montant': montant,
        'operateur': operateur,
        'telephone': telephone,
      });
  static Future<Map<String, dynamic>> confirmerPaiement(dynamic versementId, String? code) =>
      _appel('POST', '/payer/$versementId/confirmer', corps: {'code': code});
}

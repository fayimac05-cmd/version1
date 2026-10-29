import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Appels backend de la page admin « Notes & Moyennes » (stocker, transférer,
/// archiver, moyennes provisoires). Séparé d'ApiService pour ne pas toucher à
/// ce gros fichier ; il réutilise son adresse et son jeton.
class NotesAdminService {
  static Future<Map<String, dynamic>> _appel(
    String methode,
    String chemin, {
    Map<String, dynamic>? corps,
    Map<String, String>? query,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      var uri = Uri.parse('${ApiService.baseUrl}$chemin');
      if (query != null) uri = uri.replace(queryParameters: query);
      late http.Response r;
      switch (methode) {
        case 'GET':
          r = await http.get(uri, headers: headers);
          break;
        case 'POST':
          r = await http.post(uri, headers: headers, body: jsonEncode(corps ?? {}));
          break;
        default:
          r = await http.patch(uri, headers: headers, body: jsonEncode(corps ?? {}));
      }
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      if (r.statusCode >= 200 && r.statusCode < 300) {
        return {'success': true, ...(body as Map<String, dynamic>)};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur (${r.statusCode}).'};
    } catch (_) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  static Future<Map<String, dynamic>> stocker(List<String> ids) =>
      _appel('PATCH', '/notes/sessions/admin/stocker', corps: {'ids': ids});

  static Future<Map<String, dynamic>> transferer(List<String> ids) =>
      _appel('PATCH', '/notes/sessions/admin/transferer', corps: {'ids': ids});

  static Future<Map<String, dynamic>> archiver(List<String> ids, {bool archive = true}) =>
      _appel('PATCH', '/notes/sessions/admin/archiver', corps: {'ids': ids, 'archive': archive});

  static Future<Map<String, dynamic>> apercuMoyennes({
    required String filiereId,
    required String niveau,
    required String semestre,
    String? annee,
  }) =>
      _appel('GET', '/notes/moyennes-provisoires/apercu', query: {
        'filiere_id': filiereId,
        'niveau': niveau,
        'semestre': semestre,
        if (annee != null && annee.isNotEmpty) 'annee_academique': annee,
      });

  static Future<Map<String, dynamic>> publierMoyennes({
    required String filiereId,
    required String niveau,
    required String semestre,
    String? annee,
  }) =>
      _appel('POST', '/notes/moyennes-provisoires/publier', corps: {
        'filiere_id': filiereId,
        'niveau': niveau,
        'semestre': semestre,
        if (annee != null && annee.isNotEmpty) 'annee_academique': annee,
      });

  /// Étudiant connecté : uniquement SES moyennes provisoires.
  static Future<Map<String, dynamic>> mesMoyennesProvisoires() =>
      _appel('GET', '/notes/moyennes-provisoires/mes');
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Appels backend de la page admin « Publication des bulletins ».
class BulletinsAdminService {
  /// Calcule les moyennes de chaque étudiant du groupe + la liste des modules.
  static Future<Map<String, dynamic>> preparation({
    required String filiereId,
    required String niveau,
    required String semestre,
    required String anneeAcademique,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      final uri = Uri.parse('${ApiService.baseUrl}/bulletins/preparation').replace(queryParameters: {
        'filiere_id': filiereId,
        'niveau': niveau,
        'semestre': semestre,
        'annee_academique': anneeAcademique,
      });
      final r = await http.get(uri, headers: headers);
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      if (r.statusCode == 200) {
        return {
          'success': true,
          'data': body['data'] as List<dynamic>,
          'modules': (body['modules'] as List<dynamic>? ?? []),
          'regle': body['regle'],
          'modules_hors_ue': (body['modules_hors_ue'] as List<dynamic>? ?? []),
        };
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du calcul des bulletins.'};
    } catch (_) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  /// [publier] false = « Enregistrer sans publier » (invisible aux étudiants).
  static Future<Map<String, dynamic>> publier({
    required String filiereId,
    required String niveau,
    required String semestre,
    required String anneeAcademique,
    required List<Map<String, dynamic>> resultats,
    bool publier = true,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      final r = await http.post(
        Uri.parse('${ApiService.baseUrl}/bulletins/publier'),
        headers: headers,
        body: jsonEncode({
          'filiere_id': filiereId,
          'niveau': niveau,
          'semestre': semestre,
          'annee_academique': anneeAcademique,
          'resultats': resultats,
          'publier': publier,
        }),
      );
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      if (r.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'message': body['message']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la publication.'};
    } catch (_) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  /// Règle de validation d'un semestre (général par défaut si rien n'est défini).
  static Future<Map<String, dynamic>> regles({
    required String filiereId,
    required String niveau,
    required String semestre,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      final uri = Uri.parse('${ApiService.baseUrl}/bulletins/regles').replace(queryParameters: {
        'filiere_id': filiereId, 'niveau': niveau, 'semestre': semestre,
      });
      final r = await http.get(uri, headers: headers);
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      if (r.statusCode == 200) return {'success': true, 'data': body['data'] as Map<String, dynamic>};
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement des règles.'};
    } catch (_) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  static Future<Map<String, dynamic>> sauverRegles({
    required String filiereId,
    required String niveau,
    required String semestre,
    required String mode,
    required double seuilValidation,
    required double seuilUe,
    required double seuilCompensation,
    required List<Map<String, dynamic>> ues,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      final r = await http.put(
        Uri.parse('${ApiService.baseUrl}/bulletins/regles'),
        headers: headers,
        body: jsonEncode({
          'filiere_id': filiereId, 'niveau': niveau, 'semestre': semestre, 'mode': mode,
          'seuil_validation': seuilValidation, 'seuil_ue': seuilUe, 'seuil_compensation': seuilCompensation,
          'ues': ues,
        }),
      );
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      if (r.statusCode == 200 && body['success'] == true) return {'success': true};
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de l\'enregistrement des règles.'};
    } catch (_) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }
}

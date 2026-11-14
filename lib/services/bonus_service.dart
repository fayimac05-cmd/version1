import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Bonus de participation attribués par les professeurs (voir bonus.controller.js).
class BonusService {
  /// Bonus non encore appliqués d'un module : { matricule: { total, items:[…] } }.
  static Future<Map<String, dynamic>> parModule(String moduleId) async {
    try {
      final headers = await ApiService.getHeaders();
      final r = await http.get(Uri.parse('${ApiService.baseUrl}/bonus/module/$moduleId'), headers: headers);
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      if (r.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': Map<String, dynamic>.from(body['data'] as Map)};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement des bonus.'};
    } catch (_) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> ajouter({
    required String moduleId,
    required String matricule,
    required double valeur,
    String? motif,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      final r = await http.post(
        Uri.parse('${ApiService.baseUrl}/bonus'),
        headers: headers,
        body: jsonEncode({'module_id': int.tryParse(moduleId) ?? moduleId, 'matricule': matricule, 'valeur': valeur, 'motif': motif}),
      );
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      if (r.statusCode == 201 && body['success'] == true) return {'success': true};
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de l\'ajout du bonus.'};
    } catch (_) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> supprimer(String id) async {
    try {
      final headers = await ApiService.getHeaders();
      final r = await http.delete(Uri.parse('${ApiService.baseUrl}/bonus/$id'), headers: headers);
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      if (r.statusCode == 200 && body['success'] == true) return {'success': true};
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la suppression.'};
    } catch (_) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }
}

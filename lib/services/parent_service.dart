import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ParentService {
  static final String baseUrl = ApiService.baseUrl;

  /// Récupère toutes les notes d'un étudiant depuis la base de données
  static Future<Map<String, dynamic>> getEnfantNotes(String etudiantId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/parents/enfant/$etudiantId/notes'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement des notes.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  /// Récupère toutes les présences d'un étudiant depuis la base de données
  static Future<Map<String, dynamic>> getEnfantPresences(String etudiantId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/parents/enfant/$etudiantId/presences'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {
          'success': true,
          'data': body['data'],
          'stats': body['stats'],
        };
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement des présences.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  /// Récupère les informations de l'enfant rattaché au parent connecté
  static Future<Map<String, dynamic>> getMonEnfant() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/parents/mon-enfant'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Enfant introuvable'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }
}

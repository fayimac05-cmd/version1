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

  /// Récupère les bulletins publiés d'un étudiant
  static Future<Map<String, dynamic>> getEnfantBulletins(String etudiantId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/parents/enfant/$etudiantId/bulletins'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement des bulletins.'};
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

  /// Récupère la liste des enfants rattachés au parent connecté, chacun avec
  /// sa moyenne, son taux de présence, et ses badges "nouveau" (notes,
  /// bulletins). Remplace l'ancien getMonEnfant() (mono-enfant).
  static Future<Map<String, dynamic>> getMesEnfants() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/parents/mes-enfants'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Enfant introuvable.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  /// Récupère les infos du parent connecté lui-même (nom, prénom, tel, email).
  static Future<Map<String, dynamic>> getMonProfil() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/parents/mon-profil'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Profil introuvable.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  /// Marque l'onglet [type] ('notes' ou 'bulletins') comme consulté pour cet
  /// enfant — fait retomber le badge "nouveau" à zéro à partir de maintenant.
  static Future<void> marquerConsulte(String etudiantId, String type) async {
    try {
      final headers = await ApiService.getHeaders();
      await http.post(
        Uri.parse('$baseUrl/parents/consultation'),
        headers: headers,
        body: jsonEncode({'etudiantId': etudiantId, 'type': type}),
      );
    } catch (_) {
      // Best-effort : un échec ici ne doit pas bloquer l'affichage.
    }
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ProfessorService {
  static final String baseUrl = ApiService.baseUrl;

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/professeurs/profile'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          return {'success': true, 'data': body['data']};
        }
        return {'success': false, 'error': body['message'] ?? 'Réponse inattendue du serveur.'};
      }
      if (response.statusCode == 401) {
        return {'success': false, 'error': 'Session expirée. Veuillez vous reconnecter.'};
      }
      return {'success': false, 'error': 'Erreur lors de la récupération du profil.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/professeurs/profile'),
        headers: headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return {'success': true};
      }
      final body = jsonDecode(response.body);
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la mise à jour du profil.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  // ── Classes & Modules ──────────────────────────────────────
  static Future<Map<String, dynamic>> getClasses() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/professeurs/classes'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) return {'success': true, 'data': body['data']};
        return {'success': false, 'error': 'Réponse inattendue du serveur.'};
      }
      return {'success': false, 'error': 'Erreur lors du chargement des classes.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  static Future<Map<String, dynamic>> getModules() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/professeurs/modules'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) return {'success': true, 'data': body['data']};
        return {'success': false, 'error': 'Réponse inattendue du serveur.'};
      }
      return {'success': false, 'error': 'Erreur lors du chargement des modules.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  // ── Assigned Classes ──────────────────────────────────────
  static Future<Map<String, dynamic>> getAssignedClasses() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/professeurs/classes/assigned'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) return {'success': true, 'data': body['data']};
        return {'success': false, 'error': 'Réponse inattendue du serveur.'};
      }
      return {'success': false, 'error': 'Erreur lors du chargement des classes assignées.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  static Future<Map<String, dynamic>> getStudentsByFiliere(int filiereId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/professeurs/classes/$filiereId/students'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) return {'success': true, 'data': body['data']};
        return {'success': false, 'error': 'Réponse inattendue du serveur.'};
      }
      return {'success': false, 'error': 'Erreur lors du chargement des étudiants.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  // ── Cours (Upload & List) ──────────────────────────────────
  static Future<Map<String, dynamic>> getCours() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/cours'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) return {'success': true, 'data': body['data']};
        return {'success': false, 'error': 'Réponse inattendue du serveur.'};
      }
      return {'success': false, 'error': 'Erreur lors du chargement des cours.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  static Future<Map<String, dynamic>> uploadCours({
    required String titre,
    required String description,
    required String filiereId,
    required String filiereNom,
    required String niveau,
    required String moduleId,
    required String filePath,
  }) async {
    try {
      final token = await ApiService.getToken();
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/cours'));
      
      request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['titre'] = titre;
      request.fields['description'] = description;
      request.fields['filiere_id'] = filiereId;
      request.fields['filiere_nom'] = filiereNom;
      request.fields['niveau'] = niveau;
      request.fields['module_id'] = moduleId;
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final body = jsonDecode(response.body);
        return {'success': false, 'error': body['message'] ?? 'Erreur lors de l\'envoi du cours.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  // ── Notes ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getGradeSessions() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notes/sessions'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) return {'success': true, 'data': body['data']};
        return {'success': false, 'error': 'Réponse inattendue du serveur.'};
      }
      return {'success': false, 'error': 'Erreur lors du chargement des sessions de notes.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  static Future<Map<String, dynamic>> createGradeSession(Map<String, dynamic> data) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/notes/sessions'),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'session_id': body['session_id']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la création'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  static Future<Map<String, dynamic>> markSessionSent(String sessionId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/notes/sessions/$sessionId/send'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return {'success': true};
      }
      final body = jsonDecode(response.body);
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de l\'envoi de la session.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  static Future<Map<String, dynamic>> getSessionDetail(String sessionId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notes/sessions/$sessionId'),
        headers: headers,
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement de la session.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  static Future<Map<String, dynamic>> updateGradeSession(String sessionId, Map<String, dynamic> data) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/notes/sessions/$sessionId'),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la mise à jour de la session.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  // ── Appels (présences) ─────────────────────────────────────
  static Future<Map<String, dynamic>> getAppels() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/appels'),
        headers: headers,
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement des appels.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  static Future<Map<String, dynamic>> createAppel(Map<String, dynamic> data) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/appels'),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'appel_id': body['appel_id']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de l\'enregistrement de l\'appel.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  static Future<Map<String, dynamic>> getAppelDetail(String appelId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/appels/$appelId'),
        headers: headers,
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement de l\'appel.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }
}

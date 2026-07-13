import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';

  // ── Sauvegarder le token ─────────────────────────────────
  static Future<void> saveToken(String token, {dynamic userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    if (userId != null) await prefs.setString('user_id', userId.toString());
  }

  // ── Récupérer le token ───────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ── Récupérer l'id utilisateur connecté ──────────────────
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  // ── Supprimer le token (logout) ──────────────────────────
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // ── Headers avec token ───────────────────────────────────
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Login ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    String? matricule,
    String? nom,
    String? tel,
    required String motDePasse,
  }) async {
    try {
      final body = matricule != null
          ? {'matricule': matricule, 'motDePasse': motDePasse}
          : {'nom': nom, 'tel': tel, 'motDePasse': motDePasse};

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        await saveToken(data['token'], userId: data['user']?['id']);
        return {'success': true, 'user': data['user']};
      } else if (data['premierLogin'] == true) {
        return {'success': true, 'premierLogin': true, 'userId': data['userId']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Erreur de connexion'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  // ── Setup password (première connexion) ──────────────────
  static Future<Map<String, dynamic>> setupPassword({
    required String userId,
    required String email,
    required String motDePasse,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/setup-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'email': email, 'motDePasse': motDePasse}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return {'success': true, 'user': data['user']};
      }
      final data = jsonDecode(response.body);
      return {'success': false, 'error': data['message'] ?? 'Erreur lors de la configuration du mot de passe.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  // ── Liste des étudiants ──────────────────────────────────
  static Future<Map<String, dynamic>> getEtudiants() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/etudiants'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body) as List<dynamic>};
      }
      if (response.statusCode == 401) {
        return {'success': false, 'error': 'Session expirée. Veuillez vous reconnecter.'};
      }
      return {'success': false, 'error': 'Erreur lors du chargement des étudiants.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Inscription publique (auto-inscription étudiant) ─────
  static Future<Map<String, dynamic>> register({
    required String nom,
    required String prenoms,
    required String email,
    required String telephone,
    required String motDePasse,
    required String filiere,
    required String niveau,
    String? matricule,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom': nom,
          'prenoms': prenoms,
          'email': email,
          'telephone': telephone,
          'motDePasse': motDePasse,
          'filiere': filiere,
          'niveau': niveau,
          if (matricule != null && matricule.isNotEmpty) 'matricule': matricule,
        }),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 201 && body['token'] != null) {
        await saveToken(body['token'], userId: body['user']?['id']);
        return {'success': true, 'user': body['user']};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de l\'inscription.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Liste des filières ────────────────────────────────────
  static Future<Map<String, dynamic>> getFilieres() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/filieres'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>,
        };
      }
      return {'success': false, 'error': 'Erreur lors du chargement des filières.'};
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Inscrire un étudiant (admin) ─────────────────────────
  static Future<Map<String, dynamic>> inscrireEtudiant(
      Map<String, dynamic> data) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/etudiants'),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, ...body};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de l\'inscription.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Annonces : liste ──────────────────────────────────────
  static Future<Map<String, dynamic>> getAnnonces({String? statut}) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse('$baseUrl/annonces').replace(
        queryParameters: statut != null ? {'statut': statut, 'limit': '100'} : {'limit': '100'},
      );
      final response = await http.get(uri, headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement des annonces.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Annonces : créer ──────────────────────────────────────
  static Future<Map<String, dynamic>> createAnnonce(Map<String, dynamic> data) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/annonces'),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la création de l\'annonce.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Annonces : modifier ───────────────────────────────────
  static Future<Map<String, dynamic>> updateAnnonce(String id, Map<String, dynamic> data) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/annonces/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la mise à jour de l\'annonce.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Annonces : supprimer ──────────────────────────────────
  static Future<Map<String, dynamic>> deleteAnnonce(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/annonces/$id'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la suppression de l\'annonce.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Annonces : publier ────────────────────────────────────
  static Future<Map<String, dynamic>> publierAnnonce(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/annonces/$id/publier'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la publication de l\'annonce.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── EDT : liste (admin) ───────────────────────────────────
  static Future<Map<String, dynamic>> getEdtAdmin({bool includeArchives = false}) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse('$baseUrl/edt/admin/all').replace(
        queryParameters: {'includeArchives': includeArchives.toString(), 'limit': '100'},
      );
      final response = await http.get(uri, headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement des emplois du temps.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── EDT : créer (format grille jours/heures) ──────────────
  static Future<Map<String, dynamic>> createEdtGrille(Map<String, dynamic> data) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/edt/grille'),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la création de l\'EDT.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── EDT : modifier les créneaux ────────────────────────────
  static Future<Map<String, dynamic>> updateEdtGrille(String id, Map<String, dynamic> data) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/edt/grille/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la mise à jour de l\'EDT.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── EDT : archiver ─────────────────────────────────────────
  static Future<Map<String, dynamic>> archiveEdt(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/edt/$id/archiver'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de l\'archivage.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── EDT : supprimer ────────────────────────────────────────
  static Future<Map<String, dynamic>> deleteEdt(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/edt/$id'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la suppression.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Modules : liste (optionnellement par filière) ─────────
  static Future<Map<String, dynamic>> getModules({String? filiereId}) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse('$baseUrl/modules').replace(
        queryParameters: filiereId != null ? {'filiere_id': filiereId} : null,
      );
      final response = await http.get(uri, headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement des modules.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Modules : créer ────────────────────────────────────────
  static Future<Map<String, dynamic>> createModule({
    required String nom,
    num? coefficient,
    int? volumeHoraire,
    int? filiereId,
    String? filiereNom,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/modules'),
        headers: headers,
        body: jsonEncode({
          'nom': nom,
          'coefficient': coefficient,
          'volume_horaire': volumeHoraire,
          'filiere_id': filiereId,
          'filiere_nom': filiereNom,
        }),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la création du module.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Modules : modifier ─────────────────────────────────────
  static Future<Map<String, dynamic>> updateModule(String id, Map<String, dynamic> data) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/modules/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la modification du module.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Modules : supprimer ────────────────────────────────────
  static Future<Map<String, dynamic>> deleteModule(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/modules/$id'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return {'success': true};
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la suppression du module.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Notes : sessions (admin, toutes confondues) ───────────
  static Future<Map<String, dynamic>> getSessionsNotesAdmin({String? statut}) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse('$baseUrl/notes/sessions/admin/all').replace(
        queryParameters: statut != null ? {'statut': statut} : null,
      );
      final response = await http.get(uri, headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement des sessions de notes.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Notes : créer une session (saisie directe ou soumission) ──
  static Future<Map<String, dynamic>> createSessionNotes(Map<String, dynamic> data) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/notes/sessions'),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201) {
        return {'success': true, 'data': body};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la création de la session de notes.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Notes : valider une session (admin) ───────────────────
  static Future<Map<String, dynamic>> validerSessionNotes(String sessionId) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/notes/sessions/$sessionId/valider'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la validation.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Notes : rejeter une session (admin) ───────────────────
  static Future<Map<String, dynamic>> rejeterSessionNotes(String sessionId, {String? motif}) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/notes/sessions/$sessionId/rejeter'),
        headers: headers,
        body: jsonEncode({if (motif != null && motif.isNotEmpty) 'motif': motif}),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du rejet.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Notes : moyennes générales (admin) ────────────────────
  static Future<Map<String, dynamic>> getMoyennesAdmin() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notes/moyennes'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du calcul des moyennes.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Récupérer le profil connecté ─────────────────────────
  static Future<Map<String, dynamic>> getMe() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      if (response.statusCode == 401) {
        return {'success': false, 'error': 'Session expirée. Veuillez vous reconnecter.'};
      }
      return {'success': false, 'error': 'Erreur lors de la récupération du profil.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }
}
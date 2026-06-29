import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // ── Sauvegarder le token ─────────────────────────────────
  static Future<void> saveToken(String token, {int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    if (userId != null) await prefs.setString('user_id', userId.toString());
  }

  // ── Récupérer le token ───────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
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

  // ── Inscrire un étudiant ─────────────────────────────────
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
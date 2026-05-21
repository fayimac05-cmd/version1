import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // ── Sauvegarder le token ─────────────────────────────────
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
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
        await saveToken(data['token']);
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
  static Future<bool> setupPassword({
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
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ── Récupérer le profil connecté ─────────────────────────
  static Future<Map<String, dynamic>?> getMe() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
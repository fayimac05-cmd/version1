import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student_profile.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:5000/api';

  // Connexion générique (Étudiant ou Membre/Prof)
  static Future<Map<String, dynamic>> login(String identifier, String password, {bool isStudent = true}) async {
    try {
      final endpoint = isStudent ? '/etudiants/login' : '/membres/login';
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(isStudent 
          ? {'matricule': identifier, 'password': password}
          : {'email': identifier, 'password': password}
        ),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else if (isStudent && response.statusCode == 200 && data['premiereFois'] == true) {
        return {'success': true, 'premiereFois': true, 'student': data['student']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Erreur d\'authentification'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable ($baseUrl)'};
    }
  }

  static Future<bool> finaliserCompte(int id, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/etudiants/finaliser'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'email': email,
          'password': password,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

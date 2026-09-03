import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../admin/admin_parents.dart';

class ParentsService {
  static final String baseUrl = ApiService.baseUrl;

  /// Récupère la liste de tous les parents depuis l'API
  static Future<List<Parent>> getAllParents() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/parents'),
        headers: headers,
      );
      
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        List<dynamic> data = body['data'];
        return data.map((item) {
          return Parent(
            id: item['id']?.toString() ?? 'PAR-${DateTime.now().millisecondsSinceEpoch}',
            nom: item['nom'] ?? '',
            prenoms: item['prenoms'] ?? '',
            email: item['email'] ?? '',
            telephone: item['telephone'] ?? '',
            relation: item['relation'] ?? 'Parent',
            matriculeEnfant: item['matricule_enfant'] ?? '',
            credentialsEnvoyes: item['credentialsEnvoyes'] ?? false,
          );
        }).toList();
      }
      throw Exception(body['message'] ?? 'Erreur lors du chargement des parents');
    } catch (e) {
      print('Erreur getAllParents: $e');
      throw Exception('Serveur injoignable');
    }
  }

  /// Crée un nouveau parent via l'API (sans mot de passe - le parent le définira lors de sa 1ère connexion)
  static Future<Map<String, dynamic>> createParent({
    required String nom,
    required String prenoms,
    required String email,
    required String telephone,
    required String relation,
    required String matriculeEnfant,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/parents'),
        headers: headers,
        body: jsonEncode({
          'nom': nom,
          'prenoms': prenoms,
          'email': email,
          'telephone': telephone,
          'relation': relation,
          'matriculeEnfant': matriculeEnfant,
        }),
      );

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': body['message']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la création'};
    } catch (e) {
      print('Erreur createParent: $e');
      return {'success': false, 'error': 'Serveur injoignable'};
    }
  }
}
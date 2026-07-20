import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Adresse du backend — toute l'app (y compris le Socket.IO) en dépend.
  //
  // _useCloud = true  → backend hébergé sur Render (fonctionne partout, 24h/24,
  //                     sans allumer le PC ni le serveur local).
  // _useCloud = false → backend local pour le développement (npm start sur le
  //                     PC, téléphone sur le même Wi-Fi).
  //
  // Après le premier déploiement Render, remplacer _cloudUrl par l'URL
  // affichée dans le dashboard (https://scolarhub-backend.onrender.com).
  static const bool _useCloud = true;
  static const String _cloudUrl = 'https://scolarhub-backend.onrender.com/api';
  static const String _localUrl = 'http://192.168.11.161:5000/api';
  static const String baseUrl = _useCloud ? _cloudUrl : _localUrl;

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

  // ── Cache hors-ligne ─────────────────────────────────────
  // Les GET fréquents sont mis en cache localement : si le réseau
  // est indisponible, on sert les dernières données connues avec
  // le drapeau 'offline': true (les écrans peuvent l'afficher).

  static Future<void> _cacheSet(String key, String body) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_$key', body);
    await prefs.setInt('cache_${key}_ts', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<Map<String, dynamic>?> _cacheGet(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final body = prefs.getString('cache_$key');
    if (body == null) return null;
    final ts = prefs.getInt('cache_${key}_ts');
    return {
      'body': body,
      'date': ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null,
    };
  }

  /// Renvoie les données en cache pour [key] au format standard
  /// {'success': true, 'data': ..., 'offline': true}, ou null si vide.
  static Future<Map<String, dynamic>?> _reponseHorsLigne(String key) async {
    final cached = await _cacheGet(key);
    if (cached == null) return null;
    try {
      final decoded = jsonDecode(cached['body'] as String);
      return {
        'success': true,
        'data': decoded,
        'offline': true,
        'cache_date': cached['date']?.toString(),
      };
    } catch (_) {
      return null;
    }
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
        final body = utf8.decode(response.bodyBytes);
        await _cacheSet('filieres', body);
        return {'success': true, 'data': jsonDecode(body) as List<dynamic>};
      }
      return {'success': false, 'error': 'Erreur lors du chargement des filières.'};
    } catch (e) {
      final horsLigne = await _reponseHorsLigne('filieres');
      if (horsLigne != null) return horsLigne;
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
        await _cacheSet('annonces', jsonEncode(body['data']));
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement des annonces.'};
    } catch (e) {
      final horsLigne = await _reponseHorsLigne('annonces');
      if (horsLigne != null) return horsLigne;
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

  // ── Événements : liste ────────────────────────────────────
  static Future<Map<String, dynamic>> getEvenements({String? statut}) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse('$baseUrl/evenements').replace(
        queryParameters: statut != null ? {'statut': statut} : null,
      );
      final response = await http.get(uri, headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        await _cacheSet('evenements', jsonEncode(body['data']));
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement des événements.'};
    } catch (e) {
      final horsLigne = await _reponseHorsLigne('evenements');
      if (horsLigne != null) return horsLigne;
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Événements : créer ────────────────────────────────────
  static Future<Map<String, dynamic>> createEvenement(Map<String, dynamic> data) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/evenements'),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la création de l\'événement.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Événements : changer le statut (admin) ────────────────
  static Future<Map<String, dynamic>> updateEvenementStatut(String id, String statut) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/evenements/$id/statut'),
        headers: headers,
        body: jsonEncode({'statut': statut}),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la mise à jour du statut.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Événements : supprimer ────────────────────────────────
  static Future<Map<String, dynamic>> deleteEvenement(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/evenements/$id'),
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

  // ── Événements : upload de l'affiche ──────────────────────
  static Future<Map<String, dynamic>> uploadEvenementAffiche(
      String id, List<int> bytes, String filename) async {
    try {
      final token = await getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/evenements/$id/affiche'),
      );
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'url': body['url'], 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de l\'upload de l\'affiche.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Événements : fiche d'inscription ──────────────────────
  static Future<Map<String, dynamic>> inscrireEvenement(
      String id, Map<String, dynamic> fiche) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/evenements/$id/inscriptions'),
        headers: headers,
        body: jsonEncode(fiche),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de l\'inscription.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Événements : historique des inscriptions (admin) ──────
  static Future<Map<String, dynamic>> getHistoriqueInscriptions() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/evenements/admin/inscriptions'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement de l\'historique.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Événements : liste des inscrits (auteur/admin) ────────
  static Future<Map<String, dynamic>> getEvenementInscriptions(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/evenements/$id/inscriptions'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement des inscriptions.'};
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

  // ── Professeurs : liste (admin, pour attribution de modules) ──
  static Future<Map<String, dynamic>> getProfesseurs() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/professeurs'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement des professeurs.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Disponibilités des professeurs (vue admin) ────────────
  static Future<Map<String, dynamic>> getDisponibilitesProfesseurs() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/professeurs/disponibilites/all'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement des disponibilités.'};
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
        await _cacheSet('modules_${filiereId ?? 'all'}', jsonEncode(body['data']));
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement des modules.'};
    } catch (e) {
      final horsLigne = await _reponseHorsLigne('modules_${filiereId ?? 'all'}');
      if (horsLigne != null) return horsLigne;
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
    String? professeurUserId,
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
          if (professeurUserId != null) 'professeur_user_id': professeurUserId,
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
        await _cacheSet('me', response.body);
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      if (response.statusCode == 401) {
        return {'success': false, 'error': 'Session expirée. Veuillez vous reconnecter.'};
      }
      return {'success': false, 'error': 'Erreur lors de la récupération du profil.'};
    } catch (e) {
      final horsLigne = await _reponseHorsLigne('me');
      if (horsLigne != null) return horsLigne;
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Détection du décrochage scolaire (admin)
  // ═══════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getEtudiantsARisque() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/risque'), headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] as List<dynamic>, 'periode_jours': body['periode_jours']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du calcul des risques.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  static Future<Map<String, dynamic>> alerterEtudiantRisque(int etudiantId, {String? message}) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/risque/$etudiantId/alerter'),
        headers: headers,
        body: jsonEncode({if (message != null && message.isNotEmpty) 'message': message}),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, ...body};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de l\'envoi de l\'alerte.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Paiements mobile money
  // ═══════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getMesPaiements() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/paiements'), headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        await _cacheSet('paiements', utf8.decode(response.bodyBytes));
        return {'success': true, ...body};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement des paiements.'};
    } catch (e) {
      final cached = await _cacheGet('paiements');
      if (cached != null) {
        try {
          final decoded = jsonDecode(cached['body'] as String) as Map<String, dynamic>;
          return {'success': true, ...decoded, 'offline': true};
        } catch (_) {}
      }
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  static Future<Map<String, dynamic>> initierPaiement({
    required int fraisId,
    required num montant,
    required String telephone,
    required String operateur,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/paiements/initier'),
        headers: headers,
        body: jsonEncode({
          'frais_id': fraisId,
          'montant': montant,
          'telephone': telephone,
          'operateur': operateur,
        }),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201) {
        return {'success': true, ...body};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de l\'initialisation du paiement.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  static Future<Map<String, dynamic>> confirmerPaiement(String paiementId, String code) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/paiements/$paiementId/confirmer'),
        headers: headers,
        body: jsonEncode({'code': code}),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, ...body};
      }
      return {'success': false, 'error': body['message'] ?? 'Paiement refusé.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Assistant IA de révision (quiz / fiches depuis les cours)
  // ═══════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getSupportsRevision() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/ia/supports'), headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        await _cacheSet('supports_revision', jsonEncode(body['data']));
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement des cours.'};
    } catch (e) {
      final horsLigne = await _reponseHorsLigne('supports_revision');
      if (horsLigne != null) return horsLigne;
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  static Future<Map<String, dynamic>> genererRevision(String supportId, String type) async {
    try {
      final headers = await getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/ia/revision'),
            headers: headers,
            body: jsonEncode({'support_id': supportId, 'type': type}),
          )
          .timeout(const Duration(seconds: 90));
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, ...body};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la génération.'};
    } catch (e) {
      return {'success': false, 'error': 'Génération impossible. Vérifiez votre connexion.'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Appel par QR code — check-in étudiant
  // ═══════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> checkinAppel(String code) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/appels/qr/checkin'),
        headers: headers,
        body: jsonEncode({'code': code}),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201) {
        return {'success': true, 'message': body['message']};
      }
      return {'success': false, 'error': body['message'] ?? 'Code invalide.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Vérifiez votre connexion.'};
    }
  }
}
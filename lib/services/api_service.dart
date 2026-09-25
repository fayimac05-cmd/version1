import 'dart:convert';
import 'dart:typed_data';
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
  // affichée dans le dashboard (https://backend-scolarhub.onrender.com).
  static const bool _useCloud = true;
  static const String _cloudUrl = 'https://backend-scolarhub.onrender.com/api';
  // Chrome/Windows sur ce PC : localhost. Pour un téléphone sur le même Wi-Fi,
  // remplacer par l'IP LAN du PC (actuellement 192.168.11.146).
  static const String _localUrl = 'http://localhost:5000/api';
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
    await prefs.remove('user_id');
    await prefs.remove('matricule');
    // ✅ CORRIGÉ — fuite de données entre comptes : clearToken() n'effaçait
    // que 'token', jamais les caches hors-ligne (cache_me, cache_filieres,
    // etc.). Après une déconnexion, ces caches gardaient les données du
    // compte précédent ; si un appel réseau échouait/tardait juste après
    // une nouvelle connexion, l'app retombait sur ces vieilles données —
    // par exemple le profil (et donc potentiellement les notes) d'un autre
    // étudiant se sont affichées sur un compte qui vient d'être créé.
    // On efface maintenant systématiquement tous les caches connus à la
    // déconnexion, pour qu'aucune trace du compte précédent ne subsiste.
    const clesCache = [
      'me', 'filieres', 'annonces', 'evenements', 'paiements',
      'supports_revision', 'membres_admin',
    ];
    for (final cle in clesCache) {
      await prefs.remove('cache_$cle');
      await prefs.remove('cache_${cle}_ts');
    }
    // cache_modules_<filiereId ou 'all'> a une clé dynamique — on balaie
    // toutes les clés restantes commençant par 'cache_' par sécurité.
    final toutesLesCles = prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
    for (final cle in toutesLesCles) {
      await prefs.remove(cle);
    }
  }

  // ── Cache hors-ligne ─────────────────────────────────────
  // Les GET fréquents sont mis en cache localement : si le réseau
  // est indisponible, on sert les dernières données connues avec
  // le drapeau 'offline': true (les écrans peuvent l'afficher).

  static Future<void> _cacheSet(String key, String body) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_$key', body);
    await prefs.setInt(
      'cache_${key}_ts',
      DateTime.now().millisecondsSinceEpoch,
    );
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

  // ── Méthodes HTTP génériques ──────────────────────────────
  static Future<Map<String, dynamic>?> get(String endpoint) async {
    try {
      final headers = await getHeaders();
      final url = endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint';
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>?;
      }
      return {'success': false, 'status': response.statusCode};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> post(String endpoint, [dynamic body]) async {
    try {
      final headers = await getHeaders();
      final url = endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint';
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>?;
      }
      return {'success': false, 'status': response.statusCode};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> put(String endpoint, [dynamic body]) async {
    try {
      final headers = await getHeaders();
      final url = endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint';
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>?;
      }
      return {'success': false, 'status': response.statusCode};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> delete(String endpoint) async {
    try {
      final headers = await getHeaders();
      final url = endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint';
      final response = await http.delete(Uri.parse(url), headers: headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>?;
      }
      return {'success': false, 'status': response.statusCode};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── Login ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    String? userId,
    String? matricule,
    String? email,
    String? nom,
    String? tel,
    required String motDePasse,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'password': motDePasse,
        'motDePasse': motDePasse,
      };
      if (userId != null && userId.isNotEmpty) body['userId'] = userId;
      if (matricule != null && matricule.isNotEmpty) body['matricule'] = matricule;
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (nom != null) body['nom'] = nom;
      if (tel != null) body['tel'] = tel;

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      // Première connexion détectée par le backend
      if (data['premiereFois'] == true && data['student'] != null) {
        return {
          'success': false,
          'premiereFois': true,
          'student': data['student'],
        };
      }

      if (response.statusCode == 200 && data['token'] != null) {
        await saveToken(data['token'], userId: data['user']?['id']);
        return {'success': true, 'user': data['user']};
      } else if (data['premierLogin'] == true) {
        return {
          'success': true,
          'premierLogin': true,
          'userId': data['userId'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? data['message'] ?? 'Erreur de connexion',
        };
      }
    } catch (e) {
      // 'offline' distingue une panne réseau (backend injoignable) d'un refus
      // du serveur : seul ce cas autorise le repli sur la base mock locale.
      return {
        'success': false,
        'offline': true,
        'error': 'Serveur injoignable. Vérifiez votre connexion.',
      };
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
        body: jsonEncode({
          'userId': userId,
          'email': email,
          'motDePasse': motDePasse,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return {'success': true, 'user': data['user']};
      }
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'error':
            data['message'] ??
            'Erreur lors de la configuration du mot de passe.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Vérifiez votre connexion.',
      };
    }
  }

  // ── Finaliser l'inscription (Première connexion étudiants) ─
  static Future<Map<String, dynamic>> finaliserInscription({
    String? matricule,
    String? id,
    required String email,
    String? telephone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/etudiants/finaliser'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (id != null) 'id': id,
          if (matricule != null) 'matricule': matricule,
          'email': email,
          'telephone': telephone ?? '',
          'password': password,
        }),
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        if (data['token'] != null) {
          await saveToken(data['token'], userId: data['user']?['id']);
        }
        return {'success': true, 'user': data['user'] ?? {}};
      }
      return {
        'success': false,
        'error':
            data['error'] ?? data['message'] ?? 'Erreur lors de l\'activation.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Vérifiez votre connexion.',
      };
    }
  }

  // ── Recherche d'un compte par matricule (avant connexion) ──
  // Renvoie les infos d'affichage + premierLogin, sans mot de passe.
  static Future<Map<String, dynamic>> lookupMatricule(String matricule) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/auth/lookup?matricule=${Uri.encodeQueryComponent(matricule)}',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 45));
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && data['found'] == true) {
        return {
          'success': true,
          'premierLogin': data['premierLogin'] == true,
          'userId': data['userId'],
          'user': data['user'],
        };
      }
      return {
        'success': false,
        'error': data['message'] ?? 'Matricule non reconnu.',
      };
    } catch (e) {
      return {
        'success': false,
        'offline': true,
        'error': 'Serveur injoignable. Vérifiez votre connexion.',
      };
    }
  }

  // ── Recherche d'un compte par détails nom/prénom/téléphone (avant connexion) ──
  static Future<Map<String, dynamic>> lookupDetails({
    required String nom,
    required String prenom,
    required String tel,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/auth/lookup?nom=${Uri.encodeQueryComponent(nom)}&prenom=${Uri.encodeQueryComponent(prenom)}&tel=${Uri.encodeQueryComponent(tel)}',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 45));
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && data['found'] == true) {
        return {
          'success': true,
          'premierLogin': data['premierLogin'] == true,
          'userId': data['userId'],
          // Présent uniquement pour un parent en première connexion (pas
          // encore de ligne `users` — voir auth.controller.js::lookup,
          // fallback parents). null dans tous les autres cas.
          'parentId': data['parentId'],
          'user': data['user'],
        };
      }
      return {
        'success': false,
        'error': data['message'] ?? 'Utilisateur non reconnu.',
      };
    } catch (e) {
      return {
        'success': false,
        'offline': true,
        'error': 'Serveur injoignable. Vérifiez votre connexion.',
      };
    }
  }

  // ── Finaliser la première connexion d'un parent ───────────
  // Contrairement à finaliserInscription (étudiants), aucun `userId` n'existe
  // encore : on identifie le compte par parentId (renvoyé par lookupDetails
  // quand le parent n'a pas encore de ligne `users`). L'email n'est jamais
  // obligatoire pour un parent (contrairement aux étudiants).
  static Future<Map<String, dynamic>> finaliserParent({
    required String parentId,
    required String password,
    String? email,
    String? telephone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/parents/finaliser'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'parentId': parentId,
          'password': password,
          if (email != null && email.isNotEmpty) 'email': email,
          if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
        }),
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        if (data['token'] != null) {
          await saveToken(data['token'], userId: data['user']?['id']);
        }
        return {'success': true, 'user': data['user'] ?? {}};
      }
      return {
        'success': false,
        'error': data['message'] ?? 'Erreur lors de l\'activation du compte.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Vérifiez votre connexion.',
      };
    }
  }

  // ── Mot de passe oublié ──────────────────────────────────
  static Future<Map<String, dynamic>> forgotPassword({
    required String identifiant,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifiant': identifiant}),
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Code envoyé.',
          'code': data['code']?.toString(),
        };
      }
      return {
        'success': false,
        'error': data['message'] ?? 'Erreur lors de la demande.',
      };
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  // ── Réinitialiser le mot de passe ────────────────────────
  static Future<Map<String, dynamic>> resetPassword({
    required String identifiant,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifiant': identifiant,
          'code': code,
          'newPassword': newPassword,
        }),
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Mot de passe réinitialisé.',
        };
      }
      return {
        'success': false,
        'error': data['message'] ?? 'Erreur lors de la réinitialisation.',
      };
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  // ── Liste des étudiants ──────────────────────────────────
  static Future<Map<String, dynamic>> getEtudiants({String? domaine}) async {
    try {
      final headers = await getHeaders();
      String url = '$baseUrl/etudiants';
      if (domaine != null && domaine.isNotEmpty && domaine != 'Tous') {
        url += '?domaine=${Uri.encodeQueryComponent(domaine)}';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList;
        if (decoded is List) {
          dataList = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          dataList = decoded['data'] as List<dynamic>;
        } else {
          dataList = [];
        }
        return {
          'success': true,
          'data': dataList,
        };
      }
      if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Session expirée. Veuillez vous reconnecter.',
        };
      }
      return {
        'success': false,
        'error': 'Erreur lors du chargement des étudiants.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
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
      return {
        'success': false,
        'error': 'Erreur lors du chargement des filières.',
      };
    } catch (e) {
      final horsLigne = await _reponseHorsLigne('filieres');
      if (horsLigne != null) return horsLigne;
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  static Future<Map<String, dynamic>> createFiliere({
    required String nom,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/filieres'),
        headers: await getHeaders(),
        body: jsonEncode({'nom': nom, 'description': description}),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201) return {'success': true, 'data': body};
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur création filière.',
      };
    } catch (_) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend.',
      };
    }
  }

  // ── Inscrire un étudiant (admin) ─────────────────────────
  static Future<Map<String, dynamic>> inscrireEtudiant(
    Map<String, dynamic> data,
  ) async {
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
        queryParameters: statut != null
            ? {'statut': statut, 'limit': '100'}
            : {'limit': '100'},
      );
      final response = await http.get(uri, headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        await _cacheSet('annonces', jsonEncode(body['data']));
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du chargement des annonces.',
      };
    } catch (e) {
      final horsLigne = await _reponseHorsLigne('annonces');
      if (horsLigne != null) return horsLigne;
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Annonces : créer ──────────────────────────────────────
  static Future<Map<String, dynamic>> createAnnonce(
    Map<String, dynamic> data,
  ) async {
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
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de la création de l\'annonce.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Annonces : modifier ───────────────────────────────────
  static Future<Map<String, dynamic>> updateAnnonce(
    String id,
    Map<String, dynamic> data,
  ) async {
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
      return {
        'success': false,
        'error':
            body['message'] ?? 'Erreur lors de la mise à jour de l\'annonce.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Annonces : publier ────────────────────────────────────
  static Future<Map<String, dynamic>> publishAnnonce(String id) async {
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
      return {
        'success': false,
        'error':
            body['message'] ?? 'Erreur lors de la publication de l\'annonce.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
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
      return {
        'success': false,
        'error':
            body['message'] ?? 'Erreur lors de la suppression de l\'annonce.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
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
      return {
        'success': false,
        'error':
            body['message'] ?? 'Erreur lors de la publication de l\'annonce.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Événements : liste ────────────────────────────────────
  static Future<Map<String, dynamic>> getEvenements({String? statut}) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse(
        '$baseUrl/evenements',
      ).replace(queryParameters: statut != null ? {'statut': statut} : null);
      final response = await http.get(uri, headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        await _cacheSet('evenements', jsonEncode(body['data']));
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du chargement des événements.',
      };
    } catch (e) {
      final horsLigne = await _reponseHorsLigne('evenements');
      if (horsLigne != null) return horsLigne;
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Événements : créer ────────────────────────────────────
  static Future<Map<String, dynamic>> createEvenement(
    Map<String, dynamic> data,
  ) async {
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
      return {
        'success': false,
        'error':
            body['message'] ?? 'Erreur lors de la création de l\'événement.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Événements : changer le statut (admin) ────────────────
  static Future<Map<String, dynamic>> updateEvenementStatut(
    String id,
    String statut,
  ) async {
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
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de la mise à jour du statut.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
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
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de la suppression.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Événements : upload de l'affiche ──────────────────────
  static Future<Map<String, dynamic>> uploadEvenementAffiche(
    String id,
    List<int> bytes,
    String filename,
  ) async {
    try {
      final token = await getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/evenements/$id/affiche'),
      );
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'url': body['url'], 'data': body['data']};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de l\'upload de l\'affiche.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Événements : fiche d'inscription ──────────────────────
  static Future<Map<String, dynamic>> inscrireEvenement(
    String id,
    Map<String, dynamic> fiche,
  ) async {
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
      return {
        'success': false,
        'error':
            body['message'] ?? 'Erreur lors du chargement de l\'historique.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Événements : liste des inscrits (auteur/admin) ────────
  static Future<Map<String, dynamic>> getEvenementInscriptions(
    String id,
  ) async {
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
      return {
        'success': false,
        'error':
            body['message'] ?? 'Erreur lors du chargement des inscriptions.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── EDT : liste (admin) ───────────────────────────────────
  static Future<Map<String, dynamic>> getEdtAdmin({
    bool includeArchives = false,
  }) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse('$baseUrl/edt/admin/all').replace(
        queryParameters: {
          'includeArchives': includeArchives.toString(),
          'limit': '100',
        },
      );
      final response = await http.get(uri, headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {
        'success': false,
        'error':
            body['message'] ??
            'Erreur lors du chargement des emplois du temps.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── EDT : créer (format grille jours/heures) ──────────────
  static Future<Map<String, dynamic>> createEdtGrille(
    Map<String, dynamic> data,
  ) async {
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
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de la création de l\'EDT.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── EDT : modifier les créneaux ────────────────────────────
  static Future<Map<String, dynamic>> updateEdtGrille(
    String id,
    Map<String, dynamic> data,
  ) async {
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
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de la mise à jour de l\'EDT.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
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
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de l\'archivage.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Notifications de l'utilisateur connecté ──────────────────
  static Future<Map<String, dynamic>> getNotifications() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['notifications'] ?? []};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur de chargement.',
      };
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }


  static Future<Map<String, dynamic>> getListeClasseAvecNotes({
  required String filiereId,
  required String niveau,
  required String moduleId,
  required String semestre,
  required String anneeAcademique,
}) async {
  try {
    final headers = await getHeaders();
    final uri = Uri.parse('$baseUrl/notes/liste-classe').replace(queryParameters: {
      'filiere_id': filiereId,
      'niveau': niveau,
      'module_id': moduleId,
      'semestre': semestre,
      'annee_academique': anneeAcademique,
    });
    final response = await http.get(uri, headers: headers);
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 && body['success'] == true) {
      return {'success': true, 'data': body['data']};
    }
    return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement.'};
  } catch (e) {
    return {'success': false, 'error': 'Serveur injoignable.'};
  }
}

  static Future<Map<String, dynamic>> getCantineJour(String date) async {
  try {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/cantine/jour?date=$date'),
      headers: headers,
    );
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 && body['success'] == true) {
      return {'success': true, 'data': body['data']};
    }
    return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement du menu.'};
  } catch (e) {
    return {'success': false, 'error': 'Serveur injoignable.'};
  }
}

static Future<Map<String, dynamic>> publierMenuCantine({
  required String date,
  required String repas,
  required List<Map<String, dynamic>> plats,
}) async {
  try {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/cantine/publier'),
      headers: headers,
      body: jsonEncode({'date': date, 'repas': repas, 'plats': plats}),
    );
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 && body['success'] == true) {
      return {'success': true, 'message': body['message']};
    }
    return {'success': false, 'error': body['message'] ?? 'Erreur lors de la publication.'};
  } catch (e) {
    return {'success': false, 'error': 'Serveur injoignable.'};
  }
}

static Future<Map<String, dynamic>> getCantineAujourdhui() async {
  try {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/cantine/aujourdhui'),
      headers: headers,
    );
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 && body['success'] == true) {
      return {'success': true, 'data': body['data']};
    }
    return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement du menu.'};
  } catch (e) {
    return {'success': false, 'error': 'Serveur injoignable.'};
  }
}

  static Future<Map<String, dynamic>> changerStatutEtudiant(String etudiantId, String statut) async {
  try {
    final headers = await getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/etudiants/$etudiantId/statut'),
      headers: headers,
      body: jsonEncode({'statut': statut}),
    );
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 && body['success'] == true) {
      return {'success': true};
    }
    return {'success': false, 'error': body['message'] ?? 'Erreur lors du changement de statut.'};
  } catch (e) {
    return {'success': false, 'error': 'Serveur injoignable.'};
  }
}

  static Future<int> getNombreNotificationsNonLues() async {
  try {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/non-lues/count'),
      headers: headers,
    );
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 && body['success'] == true) {
      return (body['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  } catch (e) {
    return 0;
  }
}


  static Future<int> getNombreSessionsEnAttente() async {
  try {
    final headers = await getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/notes/sessions/en-attente/count'), headers: headers);
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 && body['success'] == true) {
      return (body['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  } catch (e) {
    return 0;
  }
}
  static Future<bool> marquerNotificationLue(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/$id/lue'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> marquerToutesNotificationsLues() async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/lire-tout'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ── Envoyer un EDT aux étudiants (filière + niveau) ──────────
  static Future<Map<String, dynamic>> envoyerEdt(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/edt/$id/envoyer'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {
          'success': true,
          'total': body['total'] ?? 0,
          'notifies': body['notifies'] ?? 0,
          'message': body['message'],
        };
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de l\'envoi.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
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
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de la suppression.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
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
        List<dynamic> dataList;
        if (body is List) {
          dataList = body;
        } else if (body is Map && body['data'] is List) {
          dataList = body['data'] as List<dynamic>;
        } else {
          dataList = [];
        }
        return {'success': true, 'data': dataList};
      }
      return {
        'success': false,
        'error':
            body['message'] ?? 'Erreur lors du chargement des professeurs.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
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
      return {
        'success': false,
        'error':
            body['message'] ?? 'Erreur lors du chargement des disponibilités.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Réclamations : liste (admin voit tout, étudiant voit les siennes) ──
  static Future<Map<String, dynamic>> getReclamations() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/reclamations'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du chargement des réclamations.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Notes individuelles blâmables (< 7, récentes) — admin ─────────────
  static Future<Map<String, dynamic>> getNotesBlamables() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notes/blamables'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du chargement des notes blâmables.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Évolution des inscriptions (12 derniers mois) — admin ─────────────
  static Future<Map<String, dynamic>> getInscriptionsParMois() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/statistiques/inscriptions'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du chargement des inscriptions.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Sous-fils "Professeurs & Délégués" du délégué/adjoint connecté ────
  static Future<Map<String, dynamic>> getMesCoordinationsDelegue() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/canaux/mes-coordinations'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du chargement des canaux de coordination.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Affectation module précis à un professeur (module + niveau + semestre) ──
  static Future<Map<String, dynamic>> assignerModuleProfesseur({
    required String professeurId,
    required int moduleId,
    required int filiereId,
    required String niveau,
    required int semestre,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/professeurs/$professeurId/modules'),
        headers: headers,
        body: jsonEncode({
          'module_id': moduleId,
          'filiere_id': filiereId,
          'niveau': niveau,
          'semestre': semestre,
        }),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de l\'affectation du module.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Retirer une affectation module précise d'un professeur ───────────────
  static Future<Map<String, dynamic>> retirerModuleProfesseur({
    required String professeurId,
    required int affectationId,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/professeurs/$professeurId/modules/$affectationId'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du retrait du module.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Modules déjà affectés à un professeur (module + niveau + semestre) ───
  static Future<Map<String, dynamic>> getModulesAffectesProfesseur(String professeurId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/professeurs/$professeurId/modules'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du chargement des modules affectés.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Photo de profil / couverture — commun à tous les rôles ────────────
  // ✅ NOUVEAU — remplace l'ancien ProfileMediaService (client Supabase
  // direct, RLS bloquant en silence, clé par matricule cassée pour les
  // profs sans matricule). Authentification JWT classique, comme partout
  // ailleurs dans l'app — le backend identifie l'utilisateur via le token.
  static Future<Map<String, dynamic>> uploadPhotoProfil(List<int> fileBytes, String fileName) async {
    return _uploadPhoto('$baseUrl/upload/photo-profil', fileBytes, fileName);
  }

  static Future<Map<String, dynamic>> uploadPhotoCouverture(List<int> fileBytes, String fileName) async {
    return _uploadPhoto('$baseUrl/upload/photo-couverture', fileBytes, fileName);
  }

  static Future<Map<String, dynamic>> _uploadPhoto(String url, List<int> fileBytes, String fileName) async {
    try {
      final token = await getToken();
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'url': body['url']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de l\'envoi de la photo.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  static Future<Map<String, dynamic>> deletePhotoProfil() async {
    return _deletePhoto('$baseUrl/upload/photo-profil');
  }

  static Future<Map<String, dynamic>> deletePhotoCouverture() async {
    return _deletePhoto('$baseUrl/upload/photo-couverture');
  }

  static Future<Map<String, dynamic>> uploaderFichierMessage(List<int> fileBytes, String fileName) async {
    try {
      final token = await getToken();
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/message'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'url': body['url']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de l\'envoi du fichier.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  // ── Sondages ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> creerSondage({
    required String question,
    required List<String> options,
    required bool choixMultiple,
    required bool anonyme,
    DateTime? dateCloture,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sondages'),
        headers: headers,
        body: jsonEncode({
          'question': question,
          'options': options,
          'choix_multiple': choixMultiple,
          'anonyme': anonyme,
          'date_cloture': dateCloture?.toIso8601String(),
        }),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201 && body['success'] == true) {
        return {'success': true, 'id': body['id']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la création du sondage.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  // ── "Vu par" ───────────────────────────────────────────────────────────
  static Future<void> marquerMessageLu(String type, String id) async {
    try {
      final headers = await getHeaders();
      await http.post(Uri.parse('$baseUrl/messages/$type/$id/lu'), headers: headers);
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> getLecteursMessage(String type, String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/messages/$type/$id/lecteurs'), headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['error'] ?? 'Erreur lors du chargement.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> getSondage(String id) async {    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/sondages/$id'), headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Sondage introuvable.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> voterSondage(String id, List<String> optionIds) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sondages/$id/voter'),
        headers: headers,
        body: jsonEncode({'option_ids': optionIds}),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) return {'success': true};
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du vote.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> cloturerSondage(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(Uri.parse('$baseUrl/sondages/$id/cloturer'), headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) return {'success': true};
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la clôture.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> _deletePhoto(String url) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(Uri.parse(url), headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la suppression.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable. Démarrez le backend (npm start).'};
    }
  }

  // ── Canal "Admin Filière" de l'étudiant connecté (sa propre filière/niveau) ──
  static Future<Map<String, dynamic>> getMonCanalAdminFiliere() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/canaux/mon-admin-filiere'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data'] as Map<String, dynamic>};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du chargement du canal Admin Filière.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Hiérarchie Admin Filière (admin) : filières → niveaux → canaux ────
  static Future<Map<String, dynamic>> getCanauxAdminFilieres() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/canaux/admin-filieres'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du chargement des canaux Admin Filière.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
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
        await _cacheSet(
          'modules_${filiereId ?? 'all'}',
          jsonEncode(body['data']),
        );
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du chargement des modules.',
      };
    } catch (e) {
      final horsLigne = await _reponseHorsLigne(
        'modules_${filiereId ?? 'all'}',
      );
      if (horsLigne != null) return horsLigne;
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
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
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de la création du module.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Modules : modifier ─────────────────────────────────────
  static Future<Map<String, dynamic>> updateModule(
    String id,
    Map<String, dynamic> data,
  ) async {
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
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de la modification du module.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
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
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de la suppression du module.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Notes : sessions (admin, toutes confondues) ───────────
  static Future<Map<String, dynamic>> getSessionsNotesAdmin({
    String? statut,
  }) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse(
        '$baseUrl/notes/sessions/admin/all',
      ).replace(queryParameters: statut != null ? {'statut': statut} : null);
      final response = await http.get(uri, headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {
        'success': false,
        'error':
            body['message'] ??
            'Erreur lors du chargement des sessions de notes.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Notes : créer une session (saisie directe ou soumission) ──
  static Future<Map<String, dynamic>> createSessionNotes(
    Map<String, dynamic> data,
  ) async {
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
      return {
        'success': false,
        'error':
            body['message'] ??
            'Erreur lors de la création de la session de notes.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Notes : valider une session (admin) ───────────────────
  static Future<Map<String, dynamic>> validerSessionNotes(
    String sessionId,
  ) async {
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
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de la validation.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Notes : rejeter une session (admin) ───────────────────
  static Future<Map<String, dynamic>> rejeterSessionNotes(
    String sessionId, {
    String? motif,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/notes/sessions/$sessionId/rejeter'),
        headers: headers,
        body: jsonEncode({
          if (motif != null && motif.isNotEmpty) 'motif': motif,
        }),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du rejet.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
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
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du calcul des moyennes.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Bulletins — publication de la moyenne générale du semestre
  // ═══════════════════════════════════════════════════════════

  // ── Bulletins : préparation (admin) ───────────────────────
  // Calcule automatiquement la moyenne générale de chaque étudiant d'une
  // filière/niveau/semestre/année à partir des notes déjà validées, et
  // indique l'état d'un éventuel bulletin déjà publié pour ce semestre.
  static Future<Map<String, dynamic>> getPreparationBulletin({
    required String filiereId,
    required String niveau,
    required String semestre,
    required String anneeAcademique,
  }) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse('$baseUrl/bulletins/preparation').replace(
        queryParameters: {
          'filiere_id': filiereId,
          'niveau': niveau,
          'semestre': semestre,
          'annee_academique': anneeAcademique,
        },
      );
      final response = await http.get(uri, headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {
        'success': false,
        'error':
            body['message'] ?? 'Erreur lors du calcul des moyennes générales.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Bulletins : publier (admin) ───────────────────────────
  // [resultats] : liste de { 'etudiant_id': ..., 'statut': 'valide' |
  // 'ajourne' | 'invalide' } — statut coché manuellement par l'admin pour
  // chaque étudiant. La moyenne générale est recalculée côté serveur au
  // moment de la publication, jamais confiée au client.
  static Future<Map<String, dynamic>> publierBulletins({
    required String filiereId,
    required String niveau,
    required String semestre,
    required String anneeAcademique,
    required List<Map<String, dynamic>> resultats,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/bulletins/publier'),
        headers: headers,
        body: jsonEncode({
          'filiere_id': filiereId,
          'niveau': niveau,
          'semestre': semestre,
          'annee_academique': anneeAcademique,
          'resultats': resultats,
        }),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'], 'message': body['message']};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de la publication des bulletins.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Mes notes (étudiant connecté) — filtre optionnel par semestre ────────
  // Utilisée par bulletin_screen.dart pour le détail des modules d'un
  // semestre publié précis. Toujours scopée côté backend par le JWT
  // (req.user.id) — jamais les notes d'un autre étudiant.
  static Future<Map<String, dynamic>> getMesNotes({
    String? semestre,
    String? anneeAcademique,
  }) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse('$baseUrl/notes/etudiant').replace(
        queryParameters: {
          if (semestre != null) 'semestre': semestre,
          if (anneeAcademique != null) 'annee_academique': anneeAcademique,
        },
      );
      final response = await http.get(uri, headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du chargement des notes.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Mon aperçu (moyenne + taux de présence) — étudiant connecté ─────────
  // Remplace les requêtes Supabase directes de home_tab.dart pour ces deux
  // chiffres, bloquées en silence par RLS (etudiants/notes/sessions_notes
  // activé sans politique). Toujours scopé côté backend par le JWT.
  static Future<Map<String, dynamic>> getMonApercu() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notes/mon-apercu'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] as Map<String, dynamic>};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du chargement de l\'aperçu.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ── Bulletins : mon bulletin (étudiant connecté) ──────────
  // Ne renvoie que les bulletins déjà publiés de l'étudiant connecté —
  // jamais un brouillon, jamais celui d'un autre étudiant. Inclut aussi
  // les infos étudiant (nom/prenoms/filiere_nom/niveau) pour éviter un
  // appel Supabase direct côté Flutter (bloqué par RLS pour la clé
  // publique — voir diagnostic du 29/08).
  static Future<Map<String, dynamic>> getMonBulletin() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/bulletins/mon-bulletin'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': body['data'] as List<dynamic>,
          'etudiant': body['etudiant'] as Map<String, dynamic>?,
        };
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du chargement du bulletin.',
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
        await _cacheSet('me', response.body);
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Session expirée. Veuillez vous reconnecter.',
        };
      }
      return {
        'success': false,
        'error': 'Erreur lors de la récupération du profil.',
      };
    } catch (e) {
      final horsLigne = await _reponseHorsLigne('me');
      if (horsLigne != null) return horsLigne;
      return {
        'success': false,
        'error': 'Serveur injoignable. Vérifiez votre connexion.',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Détection du décrochage scolaire (admin)
  // ═══════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getEtudiantsARisque() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/risque'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': body['data'] as List<dynamic>,
          'periode_jours': body['periode_jours'],
        };
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du calcul des risques.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  static Future<Map<String, dynamic>> alerterEtudiantRisque(
    int etudiantId, {
    String? message,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/risque/$etudiantId/alerter'),
        headers: headers,
        body: jsonEncode({
          if (message != null && message.isNotEmpty) 'message': message,
        }),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, ...body};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de l\'envoi de l\'alerte.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Paiements mobile money
  // ═══════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getMesPaiements() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/paiements'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        await _cacheSet('paiements', utf8.decode(response.bodyBytes));
        return {'success': true, ...body};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du chargement des paiements.',
      };
    } catch (e) {
      final cached = await _cacheGet('paiements');
      if (cached != null) {
        try {
          final decoded =
              jsonDecode(cached['body'] as String) as Map<String, dynamic>;
          return {'success': true, ...decoded, 'offline': true};
        } catch (_) {}
      }
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
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
      return {
        'success': false,
        'error':
            body['message'] ?? 'Erreur lors de l\'initialisation du paiement.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  static Future<Map<String, dynamic>> confirmerPaiement(
    String paiementId,
    String code,
  ) async {
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
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Assistant IA de révision (quiz / fiches depuis les cours)
  // ═══════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getSupportsRevision() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/ia/supports'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        await _cacheSet('supports_revision', jsonEncode(body['data']));
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du chargement des cours.',
      };
    } catch (e) {
      final horsLigne = await _reponseHorsLigne('supports_revision');
      if (horsLigne != null) return horsLigne;
      return {
        'success': false,
        'error': 'Serveur injoignable. Démarrez le backend (npm start).',
      };
    }
  }

  static Future<Map<String, dynamic>> genererRevision(
    String supportId,
    String type,
  ) async {
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
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de la génération.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Génération impossible. Vérifiez votre connexion.',
      };
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
      return {
        'success': false,
        'error': 'Serveur injoignable. Vérifiez votre connexion.',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Gestion des Membres Administrateurs (RBAC / Base de Données)
  // ═══════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getMembresAdmin() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/membres'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        await _cacheSet('membres_admin', jsonEncode(body['data']));
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur de chargement des membres.',
      };
    } catch (e) {
      final horsLigne = await _reponseHorsLigne('membres_admin');
      if (horsLigne != null) return horsLigne;
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> creerMembreAdmin({
    required String nom,
    required String prenoms,
    required String email,
    String? tel,
    String? motDePasse,
    String? domaine,
    required String role,
    required Map<String, bool> permissions,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/membres'),
        headers: headers,
        body: jsonEncode({
          'nom': nom,
          'prenoms': prenoms,
          'email': email,
          if (tel != null && tel.trim().isNotEmpty) 'tel': tel,
          if (motDePasse != null && motDePasse.trim().isNotEmpty)
            'motDePasse': motDePasse,
          if (domaine != null && domaine.trim().isNotEmpty) 'domaine': domaine,
          'role': role,
          'admin_sub_role': role,
          'permissions': permissions,
        }),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de la création en base.',
      };
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> updatePermissionsMembre(
    String id, {
    Map<String, bool>? permissions,
    String? role,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/membres/$id/permissions'),
        headers: headers,
        body: jsonEncode({
          if (permissions != null) 'permissions': permissions,
          if (role != null) 'role': role,
        }),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur de mise à jour.',
      };
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> deleteMembreAdmin(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/membres/$id'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de la suppression.',
      };
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Délégués / adjoints (nomination, révocation, liste)
  // ═══════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getDelegues() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/etudiants/delegues'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data'] as List<dynamic>};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du chargement des délégués.',
      };
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> nommerDelegue({
    required String etudiantId,
    required String role, // 'delegue' | 'delegue_adjoint'
    required String filiereId,
    required String niveau,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/etudiants/$etudiantId/nommer-delegue'),
        headers: headers,
        body: jsonEncode({
          'role': role,
          'filiere_id': filiereId,
          'niveau': niveau,
        }),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de la nomination.',
      };
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> revoquerDelegue(String etudiantId) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/etudiants/$etudiantId/revoquer-delegue'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors du retrait.',
      };
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  // ── Réclamations (contestation de note/moyenne/absence) ──────────────
  static Future<Map<String, dynamic>> creerReclamation({
    required String moduleId,
    required String moduleNom,
    required String type, // 'note' | 'moyenne' | 'absence'
    String? typeEval,
    num? noteActuelle,
    String? semestre,
    String? annee,
    String? partiesContestees,
    required String justification,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/reclamations'),
        headers: headers,
        body: jsonEncode({
          'module_id': moduleId,
          'module_nom': moduleNom,
          'type': type,
          'type_eval': typeEval,
          'note_actuelle': noteActuelle,
          'semestre': semestre,
          'annee': annee,
          'parties_contestees': partiesContestees,
          'justification': justification,
        }),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201 && body['success'] == true) {
        return {'success': true};
      }
      return {
        'success': false,
        'error': body['message'] ?? 'Erreur lors de l\'envoi.',
      };
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> getMesReclamations() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/reclamations/mes-reclamations'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message']};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> getAllReclamations({String? statut}) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse('$baseUrl/reclamations').replace(
        queryParameters: statut != null ? {'statut': statut} : null,
      );
      final response = await http.get(uri, headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message']};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<int> getNombreReclamationsEnAttente() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/reclamations/en-attente/count'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return (body['count'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<Map<String, dynamic>> transfererReclamation(String id, String profTransfere) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/reclamations/$id/transferer'),
        headers: headers,
        body: jsonEncode({'prof_transfere': profTransfere}),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) return {'success': true};
      return {'success': false, 'error': body['message']};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> repondreReclamation(String id, String reponse) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/reclamations/$id/repondre'),
        headers: headers,
        body: jsonEncode({'reponse': reponse}),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) return {'success': true};
      return {'success': false, 'error': body['message']};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> rejeterReclamation(String id, String motif) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/reclamations/$id/rejeter'),
        headers: headers,
        body: jsonEncode({'motif': motif}),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) return {'success': true};
      return {'success': false, 'error': body['message']};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  // ── Statistiques admin — inscriptions réelles groupées par mois+domaine ──
  static Future<Map<String, dynamic>> getStatsInscriptions() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/etudiants/stats/inscriptions'), headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  // ── Évaluation des professeurs ────────────────────────────────────────
  static Future<Map<String, dynamic>> creerPeriodeEvaluation({
    required String filiereId,
    required String dateDebut,
    required String dateFin,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/evaluations/periodes'),
        headers: headers,
        body: jsonEncode({'filiere_id': filiereId, 'date_debut': dateDebut, 'date_fin': dateFin}),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201 && body['success'] == true) return {'success': true};
      return {'success': false, 'error': body['message']};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> getPeriodesEvaluation() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/evaluations/periodes'), headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message']};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> cloturerPeriodeEvaluation(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(Uri.parse('$baseUrl/evaluations/periodes/$id/cloturer'), headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) return {'success': true};
      return {'success': false, 'error': body['message']};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> getResultatsPeriodeEvaluation(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/evaluations/periodes/$id/resultats'), headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message']};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> getEvaluationsAFaire() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/evaluations/a-faire'), headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message']};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> soumettreEvaluationProf({
    required String periodeId,
    required String professeurId,
    required Map<String, int> criteres,
    String? commentaire,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/evaluations'),
        headers: headers,
        body: jsonEncode({
          'periode_id': periodeId,
          'professeur_id': professeurId,
          'criteres': criteres,
          'commentaire': commentaire,
        }),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201 && body['success'] == true) return {'success': true};
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de l\'envoi.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> getPrevisionMoyenne({
    required String filiereId,
    required String niveau,
    required String semestre,
    required String anneeAcademique,
  }) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse('$baseUrl/bulletins/prevision').replace(queryParameters: {
        'filiere_id': filiereId,
        'niveau': niveau,
        'semestre': semestre,
        'annee_academique': anneeAcademique,
      });
      final response = await http.get(uri, headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> envoyerPrevision({
    required String filiereId,
    required String niveau,
    required String semestre,
    required String anneeAcademique,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/bulletins/prevision/envoyer'),
        headers: headers,
        body: jsonEncode({
          'filiere_id': filiereId,
          'niveau': niveau,
          'semestre': semestre,
          'annee_academique': anneeAcademique,
        }),
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) return {'success': true};
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de l\'envoi.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> getMesPrevisions() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/bulletins/mes-previsions'), headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du chargement.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> getMembresGroupe(String filiereId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/messages/groupe/$filiereId/membres'), headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['error'] ?? 'Erreur lors du chargement.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<void> marquerGroupeLu(String filiereId) async {
    try {
      final headers = await getHeaders();
      await http.patch(Uri.parse('$baseUrl/messages/groupe/$filiereId/lu'), headers: headers);
    } catch (_) {}
  }

  static Future<int> getNombreNonLusGroupe(String filiereId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/messages/groupe/$filiereId/non-lus/count'), headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return (body['count'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ── GIF (proxy GIPHY côté backend) ────────────────────────────────────
  static Future<Map<String, dynamic>> rechercherGifs(String? q) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse('$baseUrl/gifs/search').replace(queryParameters: q != null ? {'q': q} : null);
      final response = await http.get(uri, headers: headers);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors de la recherche de GIF.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  /// Télécharge un fichier distant (image/GIF/sticker) en octets bruts —
  /// sert à enregistrer localement un sticker reçu en message.
  static Future<Uint8List?> telechargerFichier(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return response.bodyBytes;
      return null;
    } catch (_) {
      return null;
    }
  }
}
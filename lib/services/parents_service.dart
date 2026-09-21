import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

// ── Modèles ──────────────────────────────────────────────────────────────────

class EnfantLie {
  final String etudiantId;
  final String matricule;
  final String nom;
  final String prenoms;
  final String filiere;
  final String niveau;
  final String relation;

  EnfantLie({
    required this.etudiantId,
    required this.matricule,
    required this.nom,
    required this.prenoms,
    required this.filiere,
    required this.niveau,
    required this.relation,
  });

  factory EnfantLie.fromJson(Map<String, dynamic> json) => EnfantLie(
        etudiantId: json['etudiantId']?.toString() ?? '',
        matricule: json['matricule'] ?? '',
        nom: json['nom'] ?? '',
        prenoms: json['prenoms'] ?? '',
        filiere: json['filiere'] ?? '',
        niveau: json['niveau'] ?? '',
        relation: json['relation'] ?? 'Tuteur',
      );
}

class Parent {
  final String id;
  final String nom;
  final String prenoms;
  final String email;
  final String tel;
  final bool compteActif;
  final List<EnfantLie> enfants;

  Parent({
    required this.id,
    required this.nom,
    required this.prenoms,
    required this.email,
    required this.tel,
    required this.compteActif,
    required this.enfants,
  });

  factory Parent.fromJson(Map<String, dynamic> json) => Parent(
        id: json['id']?.toString() ?? '',
        nom: json['nom'] ?? '',
        prenoms: json['prenoms'] ?? '',
        email: json['email'] ?? '',
        tel: json['tel'] ?? '',
        compteActif: json['compte_actif'] == true,
        enfants: (json['enfants'] as List<dynamic>? ?? [])
            .map((e) => EnfantLie.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// Étudiant dont le champ tuteur est renseigné (nom_parent/tel_parent) sur
/// `etudiants` mais qui n'a pas encore de compte parent lié via
/// parent_etudiants — c'est cette liste que l'écran admin utilise pour
/// proposer un rattachement a posteriori.
class EnfantSansTuteurLie {
  final String etudiantId;
  final String matricule;
  final String nom;
  final String prenoms;
  final String nomParent;
  final String telParent;
  final String emailParent;

  EnfantSansTuteurLie({
    required this.etudiantId,
    required this.matricule,
    required this.nom,
    required this.prenoms,
    required this.nomParent,
    required this.telParent,
    required this.emailParent,
  });

  factory EnfantSansTuteurLie.fromJson(Map<String, dynamic> json) => EnfantSansTuteurLie(
        etudiantId: json['etudiant_id']?.toString() ?? '',
        matricule: json['matricule'] ?? '',
        nom: json['nom'] ?? '',
        prenoms: json['prenoms'] ?? '',
        nomParent: json['nom_parent'] ?? '',
        telParent: json['tel_parent'] ?? '',
        emailParent: json['email_parent'] ?? '',
      );
}

/// Résultat combiné renvoyé par GET /api/parents : les parents déjà liés
/// (avec leurs enfants) + les étudiants en attente de rattachement.
class ParentsListe {
  final List<Parent> parents;
  final List<EnfantSansTuteurLie> enfantsSansTuteurLie;
  ParentsListe({required this.parents, required this.enfantsSansTuteurLie});
}

// ── Service ──────────────────────────────────────────────────────────────────

class ParentsService {
  static final String baseUrl = ApiService.baseUrl;

  /// Récupère la liste des parents (avec enfants agrégés) et des étudiants
  /// en attente de rattachement.
  static Future<ParentsListe> getAllParents() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/parents'),
        headers: headers,
      );

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body['success'] == true) {
        final parents = (body['parents'] as List<dynamic>? ?? [])
            .map((p) => Parent.fromJson(Map<String, dynamic>.from(p as Map)))
            .toList();
        final enfantsSansTuteurLie = (body['enfantsSansTuteurLie'] as List<dynamic>? ?? [])
            .map((e) => EnfantSansTuteurLie.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return ParentsListe(parents: parents, enfantsSansTuteurLie: enfantsSansTuteurLie);
      }
      throw Exception(body['message'] ?? 'Erreur lors du chargement des parents');
    } catch (e) {
      throw Exception('Serveur injoignable');
    }
  }

  /// Lie (ou crée puis lie) un tuteur à un étudiant, désigné par son matricule.
  /// L'admin ne définit jamais de mot de passe — le parent l'active lui-même
  /// via sa première connexion (nom + prénom + téléphone).
  /// Si l'enfant a déjà un tuteur principal, renvoie `conflict: true` :
  /// l'appelant peut alors relancer avec `remplacerExistant: true`.
  static Future<Map<String, dynamic>> createParent({
    required String nom,
    required String prenoms,
    required String email,
    required String telephone,
    required String relation,
    required String matriculeEnfant,
    bool remplacerExistant = false,
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
          if (remplacerExistant) 'remplacerExistant': true,
        }),
      );

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': body['message']};
      }
      return {
        'success': false,
        'conflict': body['conflict'] == true,
        'error': body['message'] ?? 'Erreur lors de la création',
      };
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable'};
    }
  }

  /// Retire le lien tuteur↔enfant (le compte parent lui-même n'est pas
  /// supprimé — il peut rester lié à d'autres enfants).
  static Future<Map<String, dynamic>> supprimerLien(String etudiantId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/parents/lien/$etudiantId'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': body['message'] ?? 'Erreur lors du retrait.'};
    } catch (e) {
      return {'success': false, 'error': 'Serveur injoignable'};
    }
  }
}
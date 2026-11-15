import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Catégories d'un plat (clé = valeur stockée côté serveur).
const Map<String, String> categoriesCantine = {
  'plat_principal': 'Plat principal',
  'entree': 'Entrée',
  'accompagnement': 'Accompagnement',
  'boisson': 'Boisson',
  'dessert': 'Dessert',
};

class CantinePlat {
  final String id;
  final String repas;
  String nom;
  String description;
  String categorie;
  int prix;
  String? imageUrl;
  bool disponible;

  CantinePlat({
    required this.id,
    required this.repas,
    required this.nom,
    this.description = '',
    this.categorie = 'plat_principal',
    required this.prix,
    this.imageUrl,
    this.disponible = true,
  });

  factory CantinePlat.fromJson(Map<String, dynamic> j) => CantinePlat(
        id: '${j['id']}',
        repas: '${j['repas'] ?? ''}',
        nom: '${j['nom'] ?? ''}',
        description: '${j['description'] ?? ''}',
        categorie: categoriesCantine.containsKey(j['categorie']) ? j['categorie'] as String : 'plat_principal',
        prix: (j['prix'] as num?)?.toInt() ?? 0,
        imageUrl: (j['image_url'] == null || '${j['image_url']}'.isEmpty) ? null : '${j['image_url']}',
        disponible: j['disponible'] != false,
      );
}

/// Horaires d'ouverture et lieu (réglés par l'admin, lus par les étudiants).
class CantineParametres {
  final String ouverture; // 'HH:MM'
  final String fermeture;
  final String lieu;
  const CantineParametres({this.ouverture = '07:00', this.fermeture = '19:00', this.lieu = 'Restaurant universitaire'});

  factory CantineParametres.fromJson(dynamic j) {
    if (j is! Map) return const CantineParametres();
    String t(String k, String d) => ('${j[k] ?? ''}'.trim().isEmpty) ? d : '${j[k]}'.trim();
    return CantineParametres(ouverture: t('ouverture', '07:00'), fermeture: t('fermeture', '19:00'), lieu: t('lieu', 'Restaurant universitaire'));
  }

  static int _minutes(String hhmm) {
    final p = hhmm.split(':');
    return (int.tryParse(p.first) ?? 0) * 60 + (p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
  }

  /// « 07:00 » → « 07h00 »
  static String affiche(String hhmm) => hhmm.replaceFirst(':', 'h');

  bool ouvertA(DateTime t) {
    final m = t.hour * 60 + t.minute;
    return m >= _minutes(ouverture) && m < _minutes(fermeture);
  }
}

/// Menu publié d'un repas (vue étudiant).
class MenuPublie {
  final String repas;
  final List<CantinePlat> plats;
  MenuPublie(this.repas, this.plats);
}

/// Ligne d'une commande (un plat, une quantité).
class CommandeLigne {
  final String repas;
  final String nom;
  final int prix;
  final int quantite;
  const CommandeLigne({required this.repas, required this.nom, required this.prix, required this.quantite});

  factory CommandeLigne.fromJson(Map<String, dynamic> j) => CommandeLigne(
        repas: '${j['repas'] ?? ''}',
        nom: '${j['nom'] ?? ''}',
        prix: (j['prix'] as num?)?.toInt() ?? 0,
        quantite: (j['quantite'] as num?)?.toInt() ?? 1,
      );
}

/// Commande + ticket.
class CantineCommande {
  final String id;
  final String ticket; // « T-007 »
  final String date; // AAAA-MM-JJ
  final String heure; // HH:MM
  final String nom;
  final String prenoms;
  final String matricule;
  final String filiere;
  final String niveau;
  final int total;
  final String statut; // en_cours | traitee | annulee
  final List<CommandeLigne> lignes;

  const CantineCommande({
    required this.id,
    required this.ticket,
    required this.date,
    required this.heure,
    required this.nom,
    required this.prenoms,
    required this.matricule,
    required this.filiere,
    required this.niveau,
    required this.total,
    required this.statut,
    required this.lignes,
  });

  factory CantineCommande.fromJson(Map<String, dynamic> j) => CantineCommande(
        id: '${j['id']}',
        ticket: '${j['ticket'] ?? ''}',
        date: '${j['date'] ?? ''}',
        heure: '${j['heure'] ?? ''}',
        nom: '${j['nom'] ?? ''}',
        prenoms: '${j['prenoms'] ?? ''}',
        matricule: '${j['matricule'] ?? ''}',
        filiere: '${j['filiere'] ?? ''}',
        niveau: '${j['niveau'] ?? ''}',
        total: (j['total'] as num?)?.toInt() ?? 0,
        statut: '${j['statut'] ?? 'en_cours'}',
        lignes: [for (final l in (j['lignes'] as List? ?? [])) CommandeLigne.fromJson(Map<String, dynamic>.from(l as Map))],
      );

  /// « 2026-11-15 » → « 15/11/2026 »
  String get dateFr {
    final p = date.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : date;
  }

  String get nomComplet => '$prenoms $nom'.trim();
}

/// Appels API de l'écran Cantine (administration).
class CantineService {
  static Future<Map<String, dynamic>> _json(Future<http.Response> Function(Map<String, String> h) appel, String erreurDefaut) async {
    try {
      final headers = await ApiService.getHeaders();
      final r = await appel(headers);
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      if (r.statusCode >= 200 && r.statusCode < 300 && body['success'] == true) {
        return {'success': true, ...Map<String, dynamic>.from(body as Map)};
      }
      return {'success': false, 'error': body['message'] ?? erreurDefaut};
    } catch (_) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  /// Plats de la date + état « publié » de chaque repas.
  static Future<Map<String, dynamic>> jour(String dateIso) async {
    final r = await _json((h) => http.get(Uri.parse('${ApiService.baseUrl}/cantine/jour?date=$dateIso'), headers: h),
        'Erreur lors du chargement du menu.');
    if (r['success'] != true) return r;
    final plats = [for (final p in (r['plats'] as List? ?? [])) CantinePlat.fromJson(Map<String, dynamic>.from(p as Map))];
    final publie = <String, bool>{};
    for (final m in (r['data'] as List? ?? [])) {
      publie['${m['repas']}'] = m['publie'] == true;
    }
    return {'success': true, 'plats': plats, 'publie': publie, 'parametres': CantineParametres.fromJson(r['parametres'])};
  }

  /// Menus publiés du jour + horaires (vue étudiant, tous rôles connectés).
  static Future<Map<String, dynamic>> aujourdhui() async {
    final r = await _json((h) => http.get(Uri.parse('${ApiService.baseUrl}/cantine/aujourdhui'), headers: h), 'Erreur lors du chargement du menu.');
    if (r['success'] != true) return r;
    final menus = <MenuPublie>[];
    for (final m in (r['data'] as List? ?? [])) {
      final repas = '${m['repas']}';
      final plats = <CantinePlat>[];
      for (final p in (m['plats'] as List? ?? [])) {
        final j = Map<String, dynamic>.from(p as Map);
        j['repas'] = repas;
        j['id'] = j['id'] ?? '$repas-${plats.length}';
        plats.add(CantinePlat.fromJson(j));
      }
      menus.add(MenuPublie(repas, plats));
    }
    return {'success': true, 'menus': menus, 'parametres': CantineParametres.fromJson(r['parametres'])};
  }

  // ── Commandes ─────────────────────────────────────────────────────────

  /// [lignes] : {repas, plat_id, nom, quantite}. Renvoie {success, commande}.
  static Future<Map<String, dynamic>> passerCommande(List<Map<String, dynamic>> lignes) async {
    final r = await _json((h) => http.post(Uri.parse('${ApiService.baseUrl}/cantine/commandes'), headers: h, body: jsonEncode({'lignes': lignes})),
        "Erreur lors de l'enregistrement de la commande.");
    if (r['success'] == true) r['commande'] = CantineCommande.fromJson(Map<String, dynamic>.from(r['data'] as Map));
    return r;
  }

  static Future<Map<String, dynamic>> mesCommandes() async {
    final r = await _json((h) => http.get(Uri.parse('${ApiService.baseUrl}/cantine/mes-commandes'), headers: h), 'Erreur lors du chargement de vos commandes.');
    if (r['success'] != true) return r;
    return {'success': true, 'commandes': [for (final c in (r['data'] as List? ?? [])) CantineCommande.fromJson(Map<String, dynamic>.from(c as Map))]};
  }

  static Future<Map<String, dynamic>> annulerCommande(String id) =>
      _json((h) => http.patch(Uri.parse('${ApiService.baseUrl}/cantine/commandes/$id/annuler'), headers: h), "Erreur lors de l'annulation.");

  /// Admin. [statut] : en_cours | traitee | annulee | toutes. [date] : AAAA-MM-JJ (facultatif).
  static Future<Map<String, dynamic>> commandes({String statut = 'en_cours', String? date}) async {
    final q = 'statut=$statut${date == null ? '' : '&date=$date'}';
    final r = await _json((h) => http.get(Uri.parse('${ApiService.baseUrl}/cantine/commandes?$q'), headers: h), 'Erreur lors du chargement des commandes.');
    if (r['success'] != true) return r;
    return {
      'success': true,
      'commandes': [for (final c in (r['data'] as List? ?? [])) CantineCommande.fromJson(Map<String, dynamic>.from(c as Map))],
      'en_cours': (r['en_cours'] as num?)?.toInt() ?? 0,
    };
  }

  static Future<Map<String, dynamic>> traiterCommande(String id) =>
      _json((h) => http.patch(Uri.parse('${ApiService.baseUrl}/cantine/commandes/$id/traiter'), headers: h), 'Erreur lors du traitement de la commande.');

  static Future<Map<String, dynamic>> enregistrerParametres(CantineParametres p) =>
      _json((h) => http.put(Uri.parse('${ApiService.baseUrl}/cantine/parametres'),
              headers: h, body: jsonEncode({'ouverture': p.ouverture, 'fermeture': p.fermeture, 'lieu': p.lieu})),
          "Erreur lors de l'enregistrement des horaires.");

  static Future<Map<String, dynamic>> creer({
    required String date,
    required String repas,
    required String nom,
    required int prix,
    String description = '',
    String categorie = 'plat_principal',
    String? imageUrl,
    bool disponible = true,
  }) async {
    final r = await _json(
        (h) => http.post(Uri.parse('${ApiService.baseUrl}/cantine/plats'),
            headers: h,
            body: jsonEncode({
              'date': date,
              'repas': repas,
              'nom': nom,
              'prix': prix,
              'description': description,
              'categorie': categorie,
              'image_url': imageUrl,
              'disponible': disponible,
            })),
        "Erreur lors de l'ajout du plat.");
    if (r['success'] == true) r['plat'] = CantinePlat.fromJson(Map<String, dynamic>.from(r['data'] as Map));
    return r;
  }

  static Future<Map<String, dynamic>> modifier(String id, Map<String, dynamic> champs) async {
    final r = await _json((h) => http.put(Uri.parse('${ApiService.baseUrl}/cantine/plats/$id'), headers: h, body: jsonEncode(champs)),
        'Erreur lors de la modification du plat.');
    if (r['success'] == true) r['plat'] = CantinePlat.fromJson(Map<String, dynamic>.from(r['data'] as Map));
    return r;
  }

  static Future<Map<String, dynamic>> supprimer(String id) =>
      _json((h) => http.delete(Uri.parse('${ApiService.baseUrl}/cantine/plats/$id'), headers: h), 'Erreur lors de la suppression du plat.');

  static Future<Map<String, dynamic>> publier(String date, String repas) =>
      _json((h) => http.post(Uri.parse('${ApiService.baseUrl}/cantine/publier'), headers: h, body: jsonEncode({'date': date, 'repas': repas})),
          'Erreur lors de la publication.');

  /// Envoie la photo d'un plat ; renvoie {success, url}.
  static Future<Map<String, dynamic>> televerserImage(List<int> bytes, String nomFichier) async {
    try {
      final token = await ApiService.getToken();
      final req = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/cantine/plats/image'));
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: nomFichier));
      final r = await http.Response.fromStream(await req.send());
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      if (r.statusCode == 200 && body['success'] == true) return {'success': true, 'url': body['url']};
      return {'success': false, 'error': body['message'] ?? "Erreur lors de l'envoi de la photo."};
    } catch (_) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }
}
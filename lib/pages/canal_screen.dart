import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/student_profile.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../widgets/delegue_badge.dart';
import 'choisir_professeur_page.dart';
import 'messages_screen.dart';
import 'emoji_gif_sticker_picker.dart';
import 'message_extras.dart';
import 'voice_message.dart';
import 'chat_theme.dart';
import 'chat_theme_picker_sheet.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLE MESSAGE CANAL
// ════════════════════════════════════════════════════════════════════════════
class _MessageCanal {
  final String id, expediteur, initiales, texte, heure, date, type;
  final Color color;
  final String? etudiantRole, niveau;
  /// URL de la photo de profil de l'expéditeur, si disponible — remplace les
  /// initiales dans la bulle quand présente. Renseignée localement à
  /// l'envoi (depuis le profil courant) ; côté serveur, dépend de ce que
  /// l'API renvoie (peut être absente pour les anciens messages/API).
  final String? photoUrl;
  final String? expediteurId;
  Map<String, int> reactions;
  bool epingle = false;
  bool important = false;
  final String? idMessageRepondu;
  final String? texteRepondu;
  final String? expediteurRepondu;

  _MessageCanal({
    required this.id,
    required this.expediteur,
    required this.initiales,
    required this.texte,
    required this.heure,
    required this.date,
    required this.type,
    required this.color,
    this.etudiantRole,
    this.niveau,
    this.photoUrl,
    this.expediteurId,
    Map<String, int>? reactions,
    this.idMessageRepondu,
    this.texteRepondu,
    this.expediteurRepondu,
  }) : reactions = reactions ?? {};

  factory _MessageCanal.fromJson(Map<String, dynamic> json, Color color) {
    final rawDate = json['created_at'] ?? json['createdAt'];
    final createdAt =
        (rawDate != null ? DateTime.tryParse(rawDate.toString()) : null)?.toLocal() ?? DateTime.now();
    final heure =
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    String date = 'Aujourd\'hui';
    if (createdAt.day != now.day || createdAt.month != now.month || createdAt.year != now.year) {
      date = '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}';
    }
    // Le backend renvoie soit un champ 'expediteur', soit 'prenoms'/'nom'
    final nomComplet = '${json['prenoms'] ?? ''} ${json['nom'] ?? ''}'.trim();
    final nom = (json['expediteur'] as String?) ??
        (nomComplet.isNotEmpty ? nomComplet : 'Administration');
    final parts = nom.trim().split(RegExp(r'\s+'));
    final initiales = parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (nom.isNotEmpty ? nom[0].toUpperCase() : 'A');
    return _MessageCanal(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      expediteur: nom,
      initiales: initiales,
      texte: json['contenu']?.toString() ?? json['titre']?.toString() ?? '',
      heure: heure,
      date: date,
      type: json['type']?.toString() ?? 'texte',
      color: color,
      etudiantRole: json['etudiant_role']?.toString(),
      niveau: json['niveau']?.toString(),
      photoUrl: (json['photo_url'] ?? json['photoUrl'])?.toString(),
      expediteurId: (json['expediteur_id'] ?? json['auteur_id'])?.toString(),
      reactions: _reactionsDepuisJson(json['reactions']),
    );
  }
}

/// Convertit le tableau d'emojis renvoyé par le backend (une entrée par
/// réaction, ex. ["👍","👍","❤️"]) en comptage par emoji pour l'affichage.
Map<String, int> _reactionsDepuisJson(dynamic raw) {
  final map = <String, int>{};
  if (raw is List) {
    for (final e in raw) {
      final emoji = e?.toString();
      if (emoji != null && emoji.isNotEmpty) map[emoji] = (map[emoji] ?? 0) + 1;
    }
  }
  return map;
}

// ════════════════════════════════════════════════════════════════════════════
// CANAL SCREEN — Hub principal
// ════════════════════════════════════════════════════════════════════════════
class CanalScreen extends StatefulWidget {
  final StudentProfile profile;
  const CanalScreen({super.key, required this.profile});
  @override
  State<CanalScreen> createState() => _CanalScreenState();
}

class _CanalScreenState extends State<CanalScreen> {
  List<Map<String, dynamic>> _canauxProfesseur = [];
  bool _chargementCanauxProfesseur = false;
  String? _erreurCanauxProfesseur;

  // ✅ NOUVEAU — canal "Admin Filière" réel de CET étudiant (sa propre
  // filière/niveau), résolu dynamiquement — remplace l'ancien canal global
  // fixe id='2' (toutes filières/niveaux mélangés).
  Map<String, dynamic>? _monCanalAdminFiliere;
  bool _chargementMonCanal = false;

  // ✅ NOUVEAU (étape 5) — sous-fils "Professeurs & Délégués" du délégué/
  // adjoint connecté : un par professeur qui enseigne dans sa filière/niveau.
  List<Map<String, dynamic>> _mesCoordinations = [];
  bool _chargementCoordinations = false;

  // ✅ NOUVEAU — nombre réel de messages non lus par canal (au lieu des
  // badges fixes '3'/'1' précédents), indexé par canalId.
  final Map<String, int> _nonLus = {};

  // Couleurs de l'identité premium
  static const Color _brandBlue = Color(0xFF1E40AF);
  static const Color _textMain = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _bgPage = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    final role = widget.profile.role.toLowerCase().trim();
    if (['professeur', 'prof', 'enseignant', 'teacher'].contains(role)) {
      _chargerCanauxProfesseur();
    } else {
      _chargerMonCanalAdminFiliere();
      if (widget.profile.estDelegue) {
        _chargerMesCoordinations();
      }
      _chargerNonLus();
    }
  }

  /// Compte les messages non lus (envoyés par quelqu'un d'autre, marqués
  /// `lu: false` côté serveur) pour les canaux fixes 'Administration' et
  /// 'Bureau des Étudiants', puis pour 'Admin & Filière' une fois son id
  /// résolu par [_chargerMonCanalAdminFiliere].
  Future<void> _chargerNonLus() async {
    final myId = await ApiService.getUserId();
    for (final canalId in ['1', '3']) {
      final n = await _compterNonLus(canalId, myId);
      if (mounted) setState(() => _nonLus[canalId] = n);
    }
    final canalIdAdminFiliere = _monCanalAdminFiliere?['canal_id']?.toString();
    if (canalIdAdminFiliere != null && canalIdAdminFiliere.isNotEmpty) {
      final n = await _compterNonLus(canalIdAdminFiliere, myId);
      if (mounted) setState(() => _nonLus[canalIdAdminFiliere] = n);
    }
  }

  Future<int> _compterNonLus(String canalId, String? myId) async {
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/messages/canal/$canalId'),
        headers: headers,
      );
      if (res.statusCode != 200) return 0;
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      final data = (body is Map ? body['data'] : body) as List? ?? [];
      return data.where((m) {
        final senderId = (m['expediteur_id'] ?? m['auteur_id'])?.toString();
        if (senderId == myId) return false;
        // Le nom du champ diffère selon les endpoints ('lu' pour les
        // canaux, 'is_read' pour les privés) — on vérifie les deux.
        return m['lu'] == false || m['is_read'] == false;
      }).length;
    } catch (_) {
      return 0;
    }
  }

  /// Libellé du badge à afficher sur la carte du canal, ou null pour ne rien
  /// afficher (aucun message non lu, ou id de canal pas encore résolu).
  String? _badgeNonLus(String? canalId) {
    if (canalId == null || canalId.isEmpty) return null;
    final n = _nonLus[canalId] ?? 0;
    return n > 0 ? '$n' : null;
  }

  Future<void> _chargerMesCoordinations() async {
    setState(() => _chargementCoordinations = true);
    final res = await ApiService.getMesCoordinationsDelegue();
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        _mesCoordinations = List<Map<String, dynamic>>.from(res['data']);
      }
      _chargementCoordinations = false;
    });
  }

  Future<void> _chargerMonCanalAdminFiliere() async {
    setState(() => _chargementMonCanal = true);
    final res = await ApiService.getMonCanalAdminFiliere();
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        _monCanalAdminFiliere = res['data'] as Map<String, dynamic>;
      }
      _chargementMonCanal = false;
    });
    final canalId = _monCanalAdminFiliere?['canal_id']?.toString();
    if (canalId != null && canalId.isNotEmpty) {
      final myId = await ApiService.getUserId();
      final n = await _compterNonLus(canalId, myId);
      if (mounted) setState(() => _nonLus[canalId] = n);
    }
  }

  Future<void> _chargerCanauxProfesseur() async {
    setState(() {
      _chargementCanauxProfesseur = true;
      _erreurCanauxProfesseur = null;
    });
    try {
      // ✅ CORRIGÉ — utilisait /canaux/professeur-filieres (ancien mécanisme,
      // un canal par filière mélangeant tous les profs et tous les niveaux).
      // Utilise désormais le même endpoint granulaire que la vue Messages
      // (admin_messages.dart, étape 4) : un sous-fil par (filière, niveau)
      // où CE prof a un module affecté.
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/professeurs/mes-canaux-coordination'),
        headers: await ApiService.getHeaders(),
      );
      if (response.statusCode == 200 && mounted) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        final List data = body['data'] as List? ?? [];
        // Aplati la structure {filiere_nom, niveaux: [{niveau, canal_id}]}
        // en une liste plate d'un item par (filière, niveau), pour l'affichage.
        final aplatis = <Map<String, dynamic>>[];
        for (final f in data) {
          final filiereNom = f['filiere_nom']?.toString() ?? '';
          for (final n in (f['niveaux'] as List? ?? [])) {
            aplatis.add({
              'id': n['canal_id'],
              'nom': '$filiereNom · ${n['niveau']}',
              'niveau': n['niveau'],
              'description': 'Coordination pédagogique — $filiereNom ${n['niveau']}',
            });
          }
        }
        setState(() => _canauxProfesseur = aplatis);
      } else if (mounted) {
        setState(() => _erreurCanauxProfesseur =
            'Le serveur a répondu ${response.statusCode}.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _erreurCanauxProfesseur =
            'Impossible de charger les canaux. Vérifie le serveur local.');
      }
    } finally {
      if (mounted) setState(() => _chargementCanauxProfesseur = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.profile.role.toLowerCase().trim();
    if (role == 'professeur' || role == 'prof' || role == 'enseignant' || role == 'teacher') {
      return _buildProfessorView(context);
    }
    // Description dynamique de la carte "Admin & Filière" : nom réel de la
    // filière/niveau une fois résolu, sinon message d'attente/erreur.
    final String descriptionAdminFiliere = _chargementMonCanal
        ? 'Chargement du canal de votre filière...'
        : _monCanalAdminFiliere != null
            ? 'Messages de l\'administration pour ${_monCanalAdminFiliere!['filiere_nom']} ${_monCanalAdminFiliere!['niveau']}'
            : 'Messages ciblés de l\'administration et de votre délégué';
    final String? canalIdAdminFiliere = _monCanalAdminFiliere?['canal_id']?.toString();

    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: Column(children: [
          
          // ── App Bar / Header Épuré ──
          
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white, // La couleur va ICI, à l'intérieur !
              border: Border(bottom: BorderSide(color: _border, width: 1)),
            ),
            
            child: Row(children: [
              // Bouton retour (visible quand la page est ouverte par-dessus une autre,
              // pas quand elle sert d'onglet dans la navigation principale)
              if (Navigator.canPop(context))
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: _textMain, size: 18)),
                  ),
                ),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Canaux de discussion', style: TextStyle(fontSize: 22,
                    fontWeight: FontWeight.w800, color: _textMain, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text('${widget.profile.prenoms} ${widget.profile.nom}',
                    style: const TextStyle(fontSize: 13, color: _textMuted, fontWeight: FontWeight.w500)),
              ])),
              Container(width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: const Icon(Icons.notifications_none_rounded, color: _textMain, size: 22)),
            ]),
          ),

          // ── Liste des Canaux ──
          Expanded(child: ListView(padding: const EdgeInsets.all(20), children: [
            _sectionLabel('CANAUX OFFICIELS'),
            const SizedBox(height: 12),
            _carteCanal(context, icon: Icons.account_balance_rounded, nom: 'Administration',
                description: 'Annonces officielles et informations pédagogiques',
                couleur: _brandBlue, badge: _badgeNonLus('1'), tag: 'Lecture seule',
                canalId: '1', type: 'administration'),
            const SizedBox(height: 12),
            _carteCanal(context, icon: Icons.campaign_rounded, nom: 'Admin & Filière',
                description: descriptionAdminFiliere,
                couleur: const Color(0xFF0891B2), tag: 'Broadcast',
                badge: _badgeNonLus(canalIdAdminFiliere),
                canalId: canalIdAdminFiliere ?? '',
                type: 'admin_filiere',
                enCours: canalIdAdminFiliere == null),
            if (widget.profile.estDelegue) ...[
              const SizedBox(height: 28),
              _sectionLabel('COORDINATION PÉDAGOGIQUE'),
              const SizedBox(height: 12),
              if (_chargementCoordinations)
                const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ))
              else if (_mesCoordinations.isEmpty)
                const Text('Aucun professeur affecté à votre niveau pour le moment.',
                    style: TextStyle(fontSize: 13, color: _textMuted))
              else
                ..._mesCoordinations.map((c) {
                  final profNom = '${c['prof_prenoms'] ?? ''} ${c['prof_nom'] ?? ''}'.trim();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _carteCanal(context,
                      icon: Icons.hub_rounded,
                      nom: profNom.isEmpty ? 'Professeur' : profNom,
                      description: '${c['filiere_nom'] ?? ''} ${c['niveau'] ?? ''}',
                      couleur: _couleurNiveau(c['niveau']?.toString()),
                      tag: 'Coordination',
                      canalId: c['canal_id'].toString(),
                      type: 'prof_delegues'),
                  );
                }),
            ],
            const SizedBox(height: 12),
            _carteCanal(context, icon: Icons.gavel_rounded, nom: 'Bureau des Étudiants',
                description: 'Événements, activités et annonces du BDE',
                couleur: const Color(0xFF7C3AED), badge: _badgeNonLus('3'), tag: 'BDE',
                canalId: '3', type: 'bde'),
            const SizedBox(height: 28),
            _sectionLabel('COMMUNICATIONS PRIVÉES'),
            const SizedBox(height: 12),
            _carteCanal(context, icon: Icons.lock_person_rounded, nom: 'Contacter l\'Administration',
                description: 'Posez une question en privé de manière confidentielle',
                couleur: const Color(0xFF059669), tag: 'Privé',
                canalId: '0', type: 'prive'),
            const SizedBox(height: 16),
            
            // Note d'information épurée
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _brandBlue.withValues(alpha:0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _brandBlue.withValues(alpha:0.12)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, color: _brandBlue, size: 16),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'Le groupe privé de votre filière est accessible directement depuis l\'onglet d\'accueil principal.',
                  style: TextStyle(fontSize: 12, color: _brandBlue, fontWeight: FontWeight.w500, height: 1.4))),
              ]),
            ),
          ])),
        ]),
      ),
    );
  }

  Widget _buildProfessorView(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: const Row(children: [
              Icon(Icons.forum_rounded, color: _brandBlue, size: 26),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Espace Professeur', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textMain)),
                Text('Échanges professionnels et coordination pédagogique', style: TextStyle(fontSize: 13, color: _textMuted)),
              ])),
            ]),
          ),
          Expanded(child: ListView(padding: const EdgeInsets.all(20), children: [
            _sectionLabel('COMMUNICATION ENSEIGNANTS'),
            const SizedBox(height: 12),
            _carteCanal(context, icon: Icons.account_balance_rounded, nom: 'Administration & Professeurs',
              description: 'Canal officiel Admin ↔ Tous les professeurs',
              couleur: const Color(0xFF059669), tag: 'Admin ↔ Professeurs', canalId: '5', type: 'admin_profs'),
            const SizedBox(height: 12),
            _carteCanal(context, icon: Icons.groups_rounded, nom: 'Salle des Professeurs',
              description: 'Canal d\'échanges entre professeurs',
              couleur: _brandBlue, tag: 'Tous les professeurs', canalId: '4', type: 'professeurs'),
            const SizedBox(height: 22),
            _sectionLabel('COORDINATION PAR FILIÈRE'),
            const SizedBox(height: 12),
            if (_chargementCanauxProfesseur)
              const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ))
            else if (_canauxProfesseur.isEmpty)
              _erreurCanauxProfesseur != null
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_erreurCanauxProfesseur!,
                      style: const TextStyle(fontSize: 13, color: Colors.redAccent)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _chargerCanauxProfesseur,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Réessayer'),
                    ),
                  ])
                : const Text('Aucun canal de filière disponible.',
                    style: TextStyle(fontSize: 13, color: _textMuted))
            else
              ..._canauxProfesseur.map((canal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _carteCanal(context,
                  icon: Icons.hub_rounded,
                  nom: canal['nom']?.toString() ?? 'Professeurs & Délégués',
                  description: canal['description']?.toString() ?? 'Coordination pédagogique',
                  couleur: _couleurNiveau(canal['niveau']?.toString()),
                  tag: 'Coordination',
                  canalId: canal['id'].toString(),
                  type: 'prof_delegues'),
              )),
          ])),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text, style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w800, color: _textMuted, letterSpacing: 1.0));

  // Même palette que côté professeur (admin_messages.dart) pour que le
  // délégué reconnaisse visuellement le même niveau des deux côtés.
  Color _couleurNiveau(String? niveau) {
    const couleurs = {
      'Licence 1': Color(0xFF10B981),
      'Licence 2': Color(0xFF3B82F6),
      'Licence 3': Color(0xFFF59E0B),
      'Master 1':  Color(0xFF8B5CF6),
      'Master 2':  Color(0xFFEC4899),
    };
    return couleurs[niveau] ?? const Color(0xFF64748B);
  }

  Widget _carteCanal(BuildContext context, {
    required IconData icon, required String nom, required String description,
    required Color couleur, required String type, required String canalId,
    String? badge, String? tag, bool enCours = false,
  }) {
    return GestureDetector(
      onTap: enCours ? null : () => _ouvrir(context, type, canalId),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(children: [
          Container(width: 46, height: 46,
            decoration: BoxDecoration(
              color: couleur.withValues(alpha:0.08),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: couleur, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(nom, style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w700, color: _textMain)),
              if (tag != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: couleur.withValues(alpha:0.08),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(tag, style: TextStyle(fontSize: 9,
                      fontWeight: FontWeight.w700, color: couleur))),
              ],
            ]),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(fontSize: 12, color: _textMuted),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          if (enCours)
            const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
          else if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(10)),
              child: Text(badge, style: const TextStyle(
                  fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)))
          else
            Icon(Icons.arrow_forward_ios_rounded, color: _textMuted.withValues(alpha:0.4), size: 14),
        ]),
      ),
    );
  }

  void _ouvrir(BuildContext context, String type, String canalId) {
    final p = widget.profile;
    // p.role porte directement 'delegue'/'delegue_adjoint' dans cette classe
    // (voir StudentProfile.estDelegue) — pas de champ séparé etudiantRole.
    final peutEcrireAdminFiliere = (p.role == 'delegue' || p.role == 'delegue_adjoint');
    final peutEcrireBDE = p.role == 'bde_president' || p.role == 'bde_adjoint';

    late Widget page;
    switch (type) {
      case 'administration':
        page = _CanalDetail(profile: p, nom: 'Administration', icon: Icons.account_balance_rounded,
            couleur: _brandBlue, tag: 'Lecture seule', canalId: canalId,
            canWrite: false);
        break;
      case 'professeurs':
      case 'prof_prof':
        page = _CanalDetail(profile: p, nom: 'Salle des Professeurs', icon: Icons.groups_rounded,
            couleur: _brandBlue, tag: 'Tous les professeurs', canalId: canalId, canWrite: true);
        break;
      case 'admin_profs':
      case 'prof_admin':
        page = _CanalDetail(profile: p, nom: 'Administration & Professeurs', icon: Icons.account_balance_rounded,
            couleur: const Color(0xFF059669), tag: 'Admin ↔ Professeurs', canalId: canalId, canWrite: true);
        break;
      case 'prof_delegues':
        page = _CanalDetail(profile: p, nom: 'Professeurs & Délégués', icon: Icons.hub_rounded,
            couleur: const Color(0xFF0891B2), tag: 'Coordination pédagogique',
            canalId: canalId, canWrite: true);
        break;
      case 'admin_filiere':
        // ✅ CORRIGÉ — canalId est désormais le canal réel de la filière/niveau
        // de CET étudiant (résolu dynamiquement), plus le canal global fixe.
        page = _CanalDetail(profile: p,
            nom: _monCanalAdminFiliere != null
                ? 'Admin · ${_monCanalAdminFiliere!['filiere_nom']} ${_monCanalAdminFiliere!['niveau']}'
                : 'Admin & Filière',
            icon: Icons.campaign_rounded,
            couleur: const Color(0xFF0891B2),
            tag: p.role == 'professeur' || peutEcrireAdminFiliere ? 'Droits d\'écriture actifs' : 'Broadcast',
            canalId: canalId, canWrite: p.role == 'professeur' || peutEcrireAdminFiliere);
        break;
      case 'bde':
        page = _CanalDetail(profile: p, nom: 'Bureau des Étudiants', icon: Icons.gavel_rounded,
            couleur: const Color(0xFF7C3AED),
            tag: peutEcrireBDE ? 'BDE · Droits de publication actifs' : 'BDE',
            canalId: canalId, canWrite: peutEcrireBDE);
        break;
      case 'contact_profs':
        page = ChoisirProfesseurPage(profile: p);
        break;
      case 'contact_etudiants':
        page = MessagesScreen(profile: p);
        break;
      case 'prive':
        page = _MessagePriveAdmin(profile: p);
        break;
      default:
        page = _CanalDetail(profile: p, nom: 'Administration', icon: Icons.account_balance_rounded,
            couleur: _brandBlue, tag: 'Lecture seule',
            canalId: canalId, canWrite: false);
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page))
        .then((_) => _chargerNonLus());
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CANAL DÉTAIL — Canal de discussion interne
// ════════════════════════════════════════════════════════════════════════════
class _CanalDetail extends StatefulWidget {
  final StudentProfile profile;
  final String nom, tag, canalId;
  final IconData icon;
  final Color couleur;
  final bool canWrite;

  const _CanalDetail({
    required this.profile, required this.nom, required this.icon,
    required this.tag, required this.couleur, required this.canalId,
    this.canWrite = false,
  });
  @override
  State<_CanalDetail> createState() => _CanalDetailState();
}

class _CanalDetailState extends State<_CanalDetail> {
  static final String _baseUrl = ApiService.baseUrl;
  final List<_MessageCanal> _msgs = [];
  final _inputCtrl = TextEditingController();
  final _scroll = ScrollController();
  bool _hasText = false;
  bool _loading = true;
  String? _myUserId;
  bool _panneauOuvert = false;
  _MessageCanal? _messageEnReponse;
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  final _voiceRecorder = VoiceRecorderController();
  String _themeId = ChatThemes.classique.id;
  bool _modeSelection = false;
  final Set<String> _selectionnes = {};

  @override
  void initState() {
    super.initState();
    _init();
    _chargerTheme();
  }

  Future<void> _init() async {
    _myUserId = await ApiService.getUserId();
    await _chargerMessages();
    await _connecterSocket();
  }

  Future<void> _chargerTheme() async {
    final id = await ChatThemeService.getThemeFor(widget.canalId);
    if (mounted) setState(() => _themeId = id);
  }

  Future<void> _choisirTheme() async {
    final applique = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChatThemePickerSheet(
        currentThemeId: _themeId,
        conversationId: widget.canalId,
      ),
    );
    if (applique == true) _chargerTheme();
  }

  @override
  void dispose() {
    SocketService().off('message:canal');
    _recordTimer?.cancel();
    _voiceRecorder.dispose();
    _inputCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _chargerMessages() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/messages/canal/${widget.canalId}'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        final data = (body is Map ? body['data'] : body) as List? ?? [];
        if (!mounted) return;
        setState(() {
          _msgs.clear();
          _msgs.addAll(data.map((m) =>
              _MessageCanal.fromJson(m as Map<String, dynamic>, widget.couleur)));
          _loading = false;
        });
        _scrollBasInitial();
        // Marque comme lus tous les messages reçus (pas les miens) —
        // ouvrir le canal vaut consultation, comme WhatsApp.
        for (final m in _msgs) {
          if (m.expediteurId != _myUserId) ApiService.marquerMessageLu('canal', m.id);
        }
      } else {
        if (!mounted) return;
        setState(() { _loading = false; _msgs.addAll(_fallbackMsgs()); });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _msgs.addAll(_fallbackMsgs()); });
    }
  }

  Future<void> _connecterSocket() async {
    await SocketService().connect();
    SocketService().joinRoom('canal:${widget.canalId}');
    SocketService().onCanalMessage((data) {
      if (!mounted) return;
      final json = data is Map<String, dynamic>
          ? data
          : jsonDecode(data.toString()) as Map<String, dynamic>;
      // Ne concerne pas ce canal, ou message déjà affiché (envoyé par moi)
      final cid = json['canal_id']?.toString() ?? json['canalId']?.toString();
      if (cid != widget.canalId) return;
      if (_myUserId != null && json['auteur_id']?.toString() == _myUserId) return;
      final msg = _MessageCanal.fromJson(json, widget.couleur);
      setState(() => _msgs.add(msg));
      _scrollBas();
    });
  }

  Future<void> _envoyerMessage() async {
    final texte = _inputCtrl.text.trim();
    if (texte.isEmpty) return;
    final p = widget.profile;
    final now = TimeOfDay.now();
    final heure = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final rep = _messageEnReponse;

    final msgLocal = _MessageCanal(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      expediteur: '${p.prenoms} ${p.nom}',
      initiales: '${p.prenoms[0]}${p.nom[0]}'.toUpperCase(),
      texte: texte, heure: heure, date: 'Aujourd\'hui',
      type: 'texte', color: widget.couleur,
      photoUrl: p.photoUrl,
      expediteurId: _myUserId,
      idMessageRepondu: rep?.id,
      texteRepondu: rep?.texte,
      expediteurRepondu: rep?.expediteur,
      // Rôle/niveau rafraîchis dès que le message a fait l'aller-retour
      // serveur (WebSocket ou rechargement) — pas connus localement ici.
      etudiantRole: null,
      niveau: null,
    );
    setState(() { _msgs.add(msgLocal); _hasText = false; _messageEnReponse = null; });
    _inputCtrl.clear();
    _scrollBas();

    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/messages/canal/${widget.canalId}'),
        headers: headers,
        body: jsonEncode({'contenu': texte}),
      );
      if (response.statusCode != 201 && mounted) {
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          final err = body is Map && body['error'] != null ? body['error'].toString() : 'Échec de l\'envoi (${response.statusCode})';
          setState(() => _msgs.remove(msgLocal));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        } catch (_) {
          setState(() => _msgs.remove(msgLocal));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Échec de l\'envoi du message')));
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _msgs.remove(msgLocal));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Serveur injoignable — message non envoyé')));
    }
  }

  // ── Envoi réel d'un GIF (URL publique GIPHY) ─────────────────────────
  Future<void> _envoyerGif(String url) async {
    setState(() => _panneauOuvert = false);
    final contenu = '[GIF]$url';
    final p = widget.profile;
    final now = TimeOfDay.now();
    final heure = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final msgLocal = _MessageCanal(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      expediteur: '${p.prenoms} ${p.nom}',
      initiales: '${p.prenoms[0]}${p.nom[0]}'.toUpperCase(),
      texte: contenu, heure: heure, date: 'Aujourd\'hui',
      type: 'texte', color: widget.couleur,
      photoUrl: p.photoUrl,
      expediteurId: _myUserId,
      etudiantRole: null,
      niveau: null,
    );
    setState(() => _msgs.add(msgLocal));
    _scrollBas();
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/messages/canal/${widget.canalId}'),
        headers: headers,
        body: jsonEncode({'contenu': contenu}),
      );
      if (response.statusCode != 201 && mounted) {
        setState(() => _msgs.remove(msgLocal));
      }
    } catch (_) {
      if (mounted) setState(() => _msgs.remove(msgLocal));
    }
  }

  // ── Enregistrement vocal en direct (capture micro réelle) ────────────
  Future<void> _startRecording() async {
    final ok = await _voiceRecorder.start();
    if (!ok) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Permission microphone refusée. Autorise le micro dans les réglages.')));
      return;
    }
    setState(() { _isRecording = true; _isPaused = false; _recordSeconds = 0; });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && mounted) setState(() => _recordSeconds++);
    });
  }

  Future<void> _pauseRecording() async {
    await _voiceRecorder.pauseOuReprendre();
    setState(() => _isPaused = _voiceRecorder.isPaused);
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    await _voiceRecorder.annuler();
    setState(() { _isRecording = false; _isPaused = false; _recordSeconds = 0; });
  }

  String _fmtDurationCanal(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  Future<void> _sendRecording() async {
    _recordTimer?.cancel();
    final duree = _fmtDurationCanal(_recordSeconds);
    setState(() { _isRecording = false; _isPaused = false; _recordSeconds = 0; });

    final bytes = await _voiceRecorder.arreterEtRecuperer();
    if (bytes == null || bytes.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Échec de l\'enregistrement.')));
      return;
    }
    final upload = await ApiService.uploaderFichierMessage(bytes, 'vocal_${DateTime.now().millisecondsSinceEpoch}.m4a');
    if (!mounted) return;
    if (upload['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(upload['error']?.toString() ?? 'Échec de l\'envoi du message vocal.')));
      return;
    }
    final url = upload['url'].toString();
    final contenu = '[FICHIER]vocal|$url|$duree';
    final p = widget.profile;
    final now = TimeOfDay.now();
    final heure = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final msgLocal = _MessageCanal(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      expediteur: '${p.prenoms} ${p.nom}',
      initiales: '${p.prenoms[0]}${p.nom[0]}'.toUpperCase(),
      texte: contenu, heure: heure, date: 'Aujourd\'hui',
      type: 'texte', color: widget.couleur,
      photoUrl: p.photoUrl,
      expediteurId: _myUserId,
      etudiantRole: null, niveau: null,
    );
    setState(() => _msgs.add(msgLocal));
    _scrollBas();
    try {
      final headers = await ApiService.getHeaders();
      await http.post(
        Uri.parse('$_baseUrl/messages/canal/${widget.canalId}'),
        headers: headers,
        body: jsonEncode({'contenu': contenu}),
      );
    } catch (_) {}
  }

  void _repondreA(_MessageCanal msg) {
    setState(() => _messageEnReponse = msg);
  }

  Future<void> _transfererMsg(_MessageCanal msg) async {
    final contenu = 'Transféré : ${msg.texte}';
    final p = widget.profile;
    final now = TimeOfDay.now();
    final heure = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final msgLocal = _MessageCanal(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      expediteur: '${p.prenoms} ${p.nom}',
      initiales: '${p.prenoms[0]}${p.nom[0]}'.toUpperCase(),
      texte: contenu, heure: heure, date: 'Aujourd\'hui',
      type: 'texte', color: widget.couleur,
      photoUrl: p.photoUrl,
      expediteurId: _myUserId,
      etudiantRole: null, niveau: null,
    );
    setState(() => _msgs.add(msgLocal));
    _scrollBas();
    try {
      final headers = await ApiService.getHeaders();
      await http.post(
        Uri.parse('$_baseUrl/messages/canal/${widget.canalId}'),
        headers: headers,
        body: jsonEncode({'contenu': contenu}),
      );
    } catch (_) {}
  }

  // ── Menu pièce jointe ──────────────────────────────────────────────────
  void _menuPieceJointe() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          _mitemPiece(Icons.insert_drive_file_outlined, 'Document', const Color(0xFF7F66FF), () { Navigator.pop(context); _envoyerFichier('document'); }),
          _mitemPiece(Icons.photo_library_outlined, 'Photos et vidéos', const Color(0xFF00A884), () { Navigator.pop(context); _envoyerFichier('media'); }),
          _mitemPiece(Icons.camera_alt_outlined, 'Caméra', const Color(0xFFDC3545), () { Navigator.pop(context); _envoyerFichier('camera'); }),
          _mitemPiece(Icons.headphones_outlined, 'Audio', const Color(0xFFFF6B35), () { Navigator.pop(context); _envoyerFichier('audio'); }),
          _mitemPiece(Icons.poll_outlined, 'Sondage', const Color(0xFF0D6EFD), () { Navigator.pop(context); _creerSondage(); }),
          const SizedBox(height: 8),
        ]),
      ));
  }

  Widget _mitemPiece(IconData icon, String label, Color color, VoidCallback onTap) => ListTile(
        leading: Container(width: 38, height: 38,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
        title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        onTap: onTap,
      );

  // ── Envoi réel d'un fichier (document/photo/vidéo/audio) ─────────────
  Future<void> _envoyerFichier(String categorie) async {
    List<int>? bytes;
    String? nom;
    String type = categorie;
    try {
      if (categorie == 'media') {
        final result = await FilePicker.platform.pickFiles(type: FileType.media, withData: true);
        if (result == null || result.files.isEmpty) return;
        bytes = result.files.first.bytes;
        nom = result.files.first.name;
        const videoExts = ['mp4', 'mov', 'avi', 'mkv', '3gp', 'webm'];
        final ext = nom.contains('.') ? nom.split('.').last.toLowerCase() : '';
        type = videoExts.contains(ext) ? 'video' : 'image';
      } else if (categorie == 'camera') {
        final picked = await ImagePicker().pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front, imageQuality: 85);
        if (picked == null) return;
        bytes = await picked.readAsBytes();
        nom = picked.name;
        type = 'image';
      } else if (categorie == 'audio') {
        final result = await FilePicker.platform.pickFiles(type: FileType.audio, withData: true);
        if (result == null || result.files.isEmpty) return;
        bytes = result.files.first.bytes;
        nom = result.files.first.name;
        type = 'audio';
      } else {
        final result = await FilePicker.platform.pickFiles(withData: true);
        if (result == null || result.files.isEmpty) return;
        bytes = result.files.first.bytes;
        nom = result.files.first.name;
        type = 'document';
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la sélection du fichier.')));
      return;
    }
    if (bytes == null || bytes.isEmpty || nom == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de lire le fichier sélectionné.')));
      return;
    }

    setState(() => _panneauOuvert = false);
    final upload = await ApiService.uploaderFichierMessage(bytes, nom);
    if (!mounted) return;
    if (upload['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(upload['error']?.toString() ?? 'Échec de l\'envoi du fichier.')));
      return;
    }
    final url = upload['url'].toString();
    final contenu = '[FICHIER]$type|$url|$nom';
    final p = widget.profile;
    final now = TimeOfDay.now();
    final heure = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final msgLocal = _MessageCanal(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      expediteur: '${p.prenoms} ${p.nom}',
      initiales: '${p.prenoms[0]}${p.nom[0]}'.toUpperCase(),
      texte: contenu, heure: heure, date: 'Aujourd\'hui',
      type: 'texte', color: widget.couleur,
      photoUrl: p.photoUrl,
      expediteurId: _myUserId,
      etudiantRole: null, niveau: null,
    );
    setState(() => _msgs.add(msgLocal));
    _scrollBas();
    try {
      final headers = await ApiService.getHeaders();
      await http.post(
        Uri.parse('$_baseUrl/messages/canal/${widget.canalId}'),
        headers: headers,
        body: jsonEncode({'contenu': contenu}),
      );
    } catch (_) {}
  }

  // ── Sondage ────────────────────────────────────────────────────────────
  Future<void> _creerSondage() async {
    final sondageId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreationSondageSheet(),
    );
    if (sondageId == null || !mounted) return;
    setState(() => _panneauOuvert = false);
    final contenu = '[SONDAGE]$sondageId';
    final p = widget.profile;
    final now = TimeOfDay.now();
    final heure = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final msgLocal = _MessageCanal(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      expediteur: '${p.prenoms} ${p.nom}',
      initiales: '${p.prenoms[0]}${p.nom[0]}'.toUpperCase(),
      texte: contenu, heure: heure, date: 'Aujourd\'hui',
      type: 'texte', color: widget.couleur,
      photoUrl: p.photoUrl,
      expediteurId: _myUserId,
      etudiantRole: null, niveau: null,
    );
    setState(() => _msgs.add(msgLocal));
    _scrollBas();
    try {
      final headers = await ApiService.getHeaders();
      await http.post(
        Uri.parse('$_baseUrl/messages/canal/${widget.canalId}'),
        headers: headers,
        body: jsonEncode({'contenu': contenu}),
      );
    } catch (_) {}
  }

  // ── Sticker : fichier local, écho visible seulement pour vous (pas
  // d'upload disponible pour l'instant) ────────────────────────────────
  void _envoyerSticker(String chemin) {
    final p = widget.profile;
    final now = TimeOfDay.now();
    final heure = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      _panneauOuvert = false;
      _msgs.add(_MessageCanal(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        expediteur: '${p.prenoms} ${p.nom}',
        initiales: '${p.prenoms[0]}${p.nom[0]}'.toUpperCase(),
        texte: '[STICKER]$chemin', heure: heure, date: 'Aujourd\'hui',
        type: 'texte', color: widget.couleur,
        photoUrl: p.photoUrl,
        expediteurId: _myUserId,
        etudiantRole: null,
        niveau: null,
      ));
    });
    _scrollBas();
  }

  void _scrollBas() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  /// Scroll tout en bas à l'ouverture du canal — en plusieurs passes, car les
  /// avatars/images des messages finissent de charger après le premier
  /// affichage et modifient la hauteur réelle du contenu (sinon on atterrit
  /// un peu trop haut et il faut descendre manuellement).
  void _scrollBasInitial() {
    void jump() {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => jump());
    Future.delayed(const Duration(milliseconds: 250), jump);
    Future.delayed(const Duration(milliseconds: 600), jump);
  }

  List<_MessageCanal> _fallbackMsgs() => [
    _MessageCanal(id: 'F1', expediteur: 'Direction Pédagogique', initiales: 'DP',
        texte: 'Bienvenue sur le canal de l\'${widget.nom}. Les annonces importantes seront publiées ici.',
        heure: '08:00', date: 'Aujourd\'hui', type: 'texte', color: widget.couleur),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Fond gris pro très doux
      appBar: _modeSelection
          ? AppBar(
              backgroundColor: widget.couleur,
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _annulerSelection,
              ),
              title: Text('${_selectionnes.length} sélectionné${_selectionnes.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _selectionnes.isEmpty ? null : _supprimerSelection,
                ),
              ],
            )
          : AppBar(
        backgroundColor: widget.couleur,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 16),
          onPressed: () => Navigator.pop(context)),
        titleSpacing: 0,
        title: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(widget.icon, color: Colors.white, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.nom, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), 
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(widget.tag, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ])),
        ]),
        actions: [
          GestureDetector(
            onTap: _choisirTheme,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.palette_outlined, color: Colors.white, size: 20),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('${_msgs.length} messages',
                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600))),
          ),
        ],
      ),
      body: Column(children: [
        
        // ── BANDEAU D'INFORMATION DU RÔLE (CORRIGÉ ICI) ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white, // La couleur est maintenant bien dans la decoration !
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(children: [
            Icon(widget.canWrite ? Icons.border_color_rounded : Icons.lock_outline_rounded,
                size: 14, color: widget.couleur),
            const SizedBox(width: 10),
            Expanded(child: Text(
              widget.canWrite
                  ? 'Compte autorisé (${widget.profile.roleLabel}) — Vous disposez des droits d\'édition.'
                  : 'Canal d\'information en lecture seule.',
              style: TextStyle(fontSize: 12, color: widget.couleur, fontWeight: FontWeight.w600))),
          ]),
        ),
        _banniereEpingleCanal(),
        Expanded(child: ChatWallpaper(theme: ChatThemes.byId(_themeId), child: _loading
            ? Center(child: CircularProgressIndicator(color: widget.couleur))
            : _msgs.isEmpty
                ? const Center(child: Text('Aucun message à afficher.', style: TextStyle(color: Color(0xFF94A3B8))))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: _msgs.length,
                    itemBuilder: (_, i) {
                      final showDate = i == 0 || _msgs[i - 1].date != _msgs[i].date;
                      return Column(children: [
                        if (showDate) _separateur(_msgs[i].date),
                        _BulleCanal(
                          key: ValueKey(_msgs[i].id),
                          message: _msgs[i],
                          couleur: widget.couleur,
                          theme: ChatThemes.byId(_themeId),
                          estMoi: _myUserId != null && _msgs[i].expediteurId == _myUserId,
                          onMenu: () => _menuOptions(_msgs[i]),
                          modeSelection: _modeSelection,
                          selectionne: _selectionnes.contains(_msgs[i].id),
                          onToggleSelection: () => _basculerSelection(_msgs[i].id),
                          onDemarrerSelection: () => _demarrerSelection(_msgs[i].id),
                        ),
                      ]);
                    },
                  ))),
        if (_messageEnReponse != null)
          Container(
            color: const Color(0xFFEAF2FE),
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            child: Row(children: [
              Container(width: 3, height: 34,
                  decoration: BoxDecoration(color: widget.couleur, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(_messageEnReponse!.expediteur, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: widget.couleur)),
                  Text(_messageEnReponse!.texte, style: const TextStyle(fontSize: 12, color: Color(0xFF54656F)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              GestureDetector(
                onTap: () => setState(() => _messageEnReponse = null),
                child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8))),
              ),
            ]),
          ),
        if (widget.canWrite) _zoneSaisie(),
        if (widget.canWrite && _panneauOuvert)
          EmojiGifStickerPicker(
            onEmoji: (emoji) {
              _inputCtrl.text += emoji;
              _inputCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _inputCtrl.text.length));
              setState(() => _hasText = _inputCtrl.text.trim().isNotEmpty);
            },
            onEnvoiDirect: (type, valeur) {
              if (type == 'gif') {
                _envoyerGif(valeur);
              } else {
                _envoyerSticker(valeur);
              }
            },
          ),
      ]),
    );
  }
 
Widget _zoneSaisie() {
  if (_isRecording) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        GestureDetector(
          onTap: _cancelRecording,
          child: Container(width: 42, height: 42,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 22)),
        ),
        const SizedBox(width: 8),
        _BlinkingDotCanal(paused: _isPaused),
        const SizedBox(width: 6),
        Text(_fmtDurationCanal(_recordSeconds), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111B21))),
        const SizedBox(width: 10),
        Expanded(child: VoiceWaveform(paused: _isPaused, controller: _voiceRecorder, couleur: widget.couleur)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _pauseRecording,
          child: Container(width: 38, height: 38,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: const Color(0xFF54656F), size: 22)),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _sendRecording,
          child: Container(width: 42, height: 42,
            decoration: BoxDecoration(color: widget.couleur, shape: BoxShape.circle),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 19)),
        ),
      ]),
    );
  }
  return Container(
  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
  decoration: const BoxDecoration(
    color: Colors.white, // Déplacé à l'intérieur !
    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0))),
        child: TextField(
          controller: _inputCtrl, maxLines: null,
          onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
          decoration: const InputDecoration(
            hintText: 'Écrire une annonce officielle...',
            hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
      )),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: _menuPieceJointe,
        child: Container(width: 44, height: 44,
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.add_rounded, color: widget.couleur, size: 24)),
      ),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: () => setState(() => _panneauOuvert = !_panneauOuvert),
        child: Container(width: 44, height: 44,
          decoration: BoxDecoration(
            color: _panneauOuvert ? widget.couleur.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(_panneauOuvert ? Icons.keyboard_alt_outlined : Icons.emoji_emotions_outlined,
              color: widget.couleur, size: 22)),
      ),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: _hasText ? _envoyerMessage : _startRecording,
        child: Container(width: 44, height: 44,
          decoration: BoxDecoration(
            color: widget.couleur,
            shape: BoxShape.circle),
          child: Icon(_hasText ? Icons.send_rounded : Icons.mic_rounded, color: Colors.white, size: _hasText ? 18 : 22)),
      ),
    ]),
);
}

  Widget _separateur(String date) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(20)),
      child: Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)))));

  Widget _banniereEpingleCanal() {
    final epingles = _msgs.where((m) => m.epingle).toList();
    if (epingles.isEmpty) return const SizedBox.shrink();
    final dernier = epingles.last;
    return GestureDetector(
      onTap: () {}, // pas d'ancre de défilement dans cette liste simple pour l'instant
      child: Container(
        color: const Color(0xFFF0F2F5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(children: [
          Icon(Icons.push_pin_rounded, color: widget.couleur, size: 15),
          const SizedBox(width: 10),
          if (epingles.length > 1)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: widget.couleur, borderRadius: BorderRadius.circular(8)),
              child: Text('${epingles.length}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dernier.expediteur, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: widget.couleur)),
              Text(dernier.texte, style: const TextStyle(fontSize: 12, color: Color(0xFF54656F)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          GestureDetector(
            onTap: () => setState(() => dernier.epingle = false),
            child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF8696A0))),
          ),
        ]),
      ),
    );
  }

  /// Ajoute une réaction avec mise à jour optimiste immédiate, puis envoi au
  /// serveur pour qu'elle survive à un rafraîchissement. Les messages sans
  /// id numérique réel (annonces 'ann_...', échos locaux 'local_...' pas
  /// encore confirmés par le serveur) restent en local uniquement — le
  /// backend ne les connaît pas encore.
  void _envoyerReaction(_MessageCanal msg, String emoji) {
    setState(() => msg.reactions[emoji] = (msg.reactions[emoji] ?? 0) + 1);
    final idNumerique = int.tryParse(msg.id);
    if (idNumerique == null) return;
    () async {
      try {
        final headers = await ApiService.getHeaders();
        await http.post(
          Uri.parse('$_baseUrl/messages/$idNumerique/reaction'),
          headers: headers,
          body: jsonEncode({'emoji': emoji, 'type': 'canal', 'canalId': widget.canalId}),
        );
      } catch (_) {}
    }();
  }

  void _demarrerSelection(String id) {
    setState(() { _modeSelection = true; _selectionnes.clear(); _selectionnes.add(id); });
  }

  void _basculerSelection(String id) {
    setState(() {
      if (_selectionnes.contains(id)) {
        _selectionnes.remove(id);
        if (_selectionnes.isEmpty) _modeSelection = false;
      } else {
        _selectionnes.add(id);
      }
    });
  }

  void _annulerSelection() {
    setState(() { _modeSelection = false; _selectionnes.clear(); });
  }

  Future<void> _supprimerSelection() async {
    final idsSelectionnes = _selectionnes.toList();
    final tousMoi = idsSelectionnes.every((id) {
      for (final m in _msgs) {
        if (m.id == id) return m.expediteurId == _myUserId;
      }
      return false;
    });
    final choix = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: EdgeInsets.only(top: 8, bottom: 8 + MediaQuery.of(context).padding.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('${idsSelectionnes.length} message${idsSelectionnes.length > 1 ? 's' : ''} sélectionné${idsSelectionnes.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ),
          const SizedBox(height: 4),
          ListTile(
            leading: const Icon(Icons.person_remove_outlined, color: Color(0xFF64748B)),
            title: const Text('Supprimer pour moi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            onTap: () => Navigator.pop(context, 'moi'),
          ),
          if (tousMoi)
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626)),
              title: const Text('Supprimer pour tout le monde', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFDC2626))),
              onTap: () => Navigator.pop(context, 'tous'),
            ),
          ListTile(
            leading: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
            title: const Text('Annuler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            onTap: () => Navigator.pop(context, null),
          ),
        ]),
      ),
    );
    if (choix == null) return;

    setState(() {
      _msgs.removeWhere((m) => idsSelectionnes.contains(m.id));
      _modeSelection = false;
      _selectionnes.clear();
    });

    final headers = await ApiService.getHeaders();
    for (final id in idsSelectionnes) {
      final idNumerique = int.tryParse(id);
      if (idNumerique == null) continue; // message pas encore confirmé par le serveur
      try {
        if (choix == 'tous') {
          await http.delete(Uri.parse('$_baseUrl/messages/$idNumerique'), headers: headers);
        } else {
          await http.post(Uri.parse('$_baseUrl/messages/canal/$idNumerique/masquer'), headers: headers);
        }
      } catch (_) {}
    }
  }

  void _menuOptions(_MessageCanal msg) {
    final estMoi = _myUserId != null && msg.expediteurId == _myUserId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
        onTap: () {},
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 6),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 8),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  ...['👍', '❤️', '😂', '😮', '😢', '🙏'].map((emoji) => GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _envoyerReaction(msg, emoji);
                        },
                        child: Container(width: 32, height: 32, alignment: Alignment.center,
                            child: Text(emoji, style: const TextStyle(fontSize: 20))),
                      )),
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      final emoji = await showModalBottomSheet<String>(
                        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                        builder: (_) => EmojiGifStickerPicker(
                          emojiOnly: true,
                          onEmoji: (e) => Navigator.pop(context, e),
                          onEnvoiDirect: (_, __) {},
                        ),
                      );
                      if (emoji != null) _envoyerReaction(msg, emoji);
                    },
                    child: Container(width: 32, height: 32,
                      decoration: const BoxDecoration(color: Color(0xFFF5F7FA), shape: BoxShape.circle),
                      child: const Icon(Icons.add_rounded, color: Color(0xFF54656F), size: 17)),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              if (estMoi)
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B)),
                  title: const Text('Infos du message', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                      builder: (_) => InfosMessageSheet(type: 'canal', messageId: msg.id, heureEnvoi: msg.heure),
                    );
                  }),
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Color(0xFF64748B)),
                title: const Text('Copier le texte de l\'annonce', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: msg.texte));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Texte copié')));
                }),
              if (widget.canWrite)
                ListTile(
                  leading: const Icon(Icons.reply_rounded, color: Color(0xFF64748B)),
                  title: const Text('Répondre', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  onTap: () { Navigator.pop(context); _repondreA(msg); }),
              ListTile(
                leading: const Icon(Icons.forward_rounded, color: Color(0xFF64748B)),
                title: const Text('Transférer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () { Navigator.pop(context); _transfererMsg(msg); }),
              ListTile(
                leading: Icon(msg.epingle ? Icons.push_pin_outlined : Icons.push_pin_rounded, color: widget.couleur),
                title: Text(msg.epingle ? 'Désépingler le message' : 'Épingler en haut du canal', style: TextStyle(fontSize: 14, color: widget.couleur, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => msg.epingle = !msg.epingle);
                }),
              ListTile(
                leading: Icon(msg.important ? Icons.star_rounded : Icons.star_outline_rounded, color: const Color(0xFF64748B)),
                title: Text(msg.important ? 'Retirer des importants' : 'Marquer comme important', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () { Navigator.pop(context); setState(() => msg.important = !msg.important); }),
              ListTile(
                leading: const Icon(Icons.check_box_outlined, color: Color(0xFF64748B)),
                title: const Text('Sélectionner', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mode sélection')));
                }),
              ListTile(
                leading: const Icon(Icons.save_alt_rounded, color: Color(0xFF64748B)),
                title: const Text('Enregistrer sous', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enregistrement...')));
                }),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: Color(0xFF64748B)),
                title: const Text('Partager', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partage...')));
                }),
              ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF64748B)),
                title: const Text('Sélectionner', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _demarrerSelection(msg.id);
                }),
              if (estMoi)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                  title: const Text('Supprimer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFDC2626))),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirme = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Supprimer le message ?'),
                        content: const Text('Ce message sera supprimé pour tout le monde. Cette action est irréversible.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Supprimer', style: TextStyle(color: Color(0xFFDC2626))),
                          ),
                        ],
                      ),
                    );
                    if (confirme != true) return;
                    setState(() => _msgs.removeWhere((m) => m.id == msg.id));
                    final idNumerique = int.tryParse(msg.id);
                    if (idNumerique == null) return; // message pas encore confirmé par le serveur
                    try {
                      final headers = await ApiService.getHeaders();
                      await http.delete(Uri.parse('$_baseUrl/messages/$idNumerique'), headers: headers);
                    } catch (_) {}
                  }),
              SizedBox(height: 8 + MediaQuery.of(context).padding.bottom),
            ]),
          ),
        ),
        ),
        ),
      ),
    );
  }

}

// ════════════════════════════════════════════════════════════════════════════
// BULLE CANAL — Design Épuré type Slack
// ════════════════════════════════════════════════════════════════════════════
class _BulleCanal extends StatefulWidget {
  final _MessageCanal message;
  final Color couleur;
  final ChatThemeData theme;
  final bool estMoi;
  final VoidCallback onMenu;
  final bool modeSelection;
  final bool selectionne;
  final VoidCallback onToggleSelection;
  final VoidCallback onDemarrerSelection;
  const _BulleCanal({
    super.key,
    required this.message,
    required this.couleur,
    required this.theme,
    required this.estMoi,
    required this.onMenu,
    required this.modeSelection,
    required this.selectionne,
    required this.onToggleSelection,
    required this.onDemarrerSelection,
  });

  @override
  State<_BulleCanal> createState() => _BulleCanalState();
}

class _BulleCanalState extends State<_BulleCanal> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final onMenu = widget.onMenu;
    final isPDF = message.type == 'pdf';
    final estMoi = widget.estMoi;
    // Couleurs du thème choisi pour la discussion (voir bouton palette dans
    // l'en-tête) — mes messages vs messages reçus.
    final bulleColor = estMoi ? widget.theme.bulleMoi : widget.theme.bulleAutre;
    final texteColor = estMoi ? widget.theme.texteMoi : widget.theme.texteAutre;

    return GestureDetector(
      onTap: widget.modeSelection ? widget.onToggleSelection : null,
      onLongPress: widget.modeSelection ? null : widget.onDemarrerSelection,
      child: MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.modeSelection) ...[
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 8),
                child: Icon(
                  widget.selectionne ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 22,
                  color: widget.selectionne ? widget.couleur : const Color(0xFFCBD5E1),
                ),
              ),
            ],
            Expanded(child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: estMoi ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!estMoi) ...[
              Builder(builder: (_) {
                debugPrint('[Avatar canal] ${message.expediteur} → photoUrl = ${message.photoUrl}');
                return Container(width: 38, height: 38,
                decoration: BoxDecoration(
                  color: message.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: (message.photoUrl != null && message.photoUrl!.isNotEmpty)
                    ? Image.network(
                        message.photoUrl!,
                        fit: BoxFit.cover,
                        width: 38,
                        height: 38,
                        errorBuilder: (_, error, ___) {
                          debugPrint('[Avatar canal] échec chargement photo pour ${message.expediteur} : $error (url: ${message.photoUrl})');
                          return Center(child: Text(message.initiales, style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)));
                        },
                      )
                    : Center(child: Text(message.initiales, style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white))),
                );
              }),
              const SizedBox(width: 12),
            ],
            Flexible(child: Column(
              crossAxisAlignment: estMoi ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  if (!estMoi) ...[
                    Text(message.expediteur, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: message.color)),
                    const SizedBox(width: 6),
                    DelegueBadge(role: message.etudiantRole, niveau: message.niveau, compact: true),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: widget.couleur.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text('Vous', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: widget.couleur)),
                    ),
                  ],
                ]),
                const SizedBox(height: 4),
                GestureDetector(
                  onLongPress: onMenu,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.fromLTRB(13, 11, 11, 8),
                    decoration: BoxDecoration(
                      color: bulleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(estMoi ? 14 : 4),
                        bottomRight: Radius.circular(estMoi ? 4 : 14),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))],
                      border: estMoi ? null : Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      if (message.texteRepondu != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.fromLTRB(8, 5, 8, 6),
                          decoration: BoxDecoration(
                            color: (estMoi ? texteColor : message.color).withValues(alpha: estMoi ? 0.18 : 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border(left: BorderSide(color: estMoi ? texteColor : message.color, width: 3)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            Text(message.expediteurRepondu ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: estMoi ? texteColor : message.color)),
                            const SizedBox(height: 2),
                            Text(message.texteRepondu!, style: TextStyle(fontSize: 12, color: (estMoi ? texteColor.withValues(alpha: 0.85) : const Color(0xFF64748B))), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ]),
                        ),
                      _contenuBulleCanal(context, message, isPDF, texteColor, estMoi),
                      const SizedBox(height: 2),
                      // Heure + épingle en bas à droite de la bulle, façon
                      // WhatsApp (au lieu d'une ligne séparée au-dessus).
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        if (message.epingle) ...[
                          Icon(Icons.push_pin_rounded, size: 11, color: texteColor.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                        ],
                        Text(message.heure, style: TextStyle(fontSize: 10.5, color: texteColor.withValues(alpha: 0.65))),
                      ]),
                    ]),
                  ),
                ),
                // Réactions + flèche du menu, juste sous le message (et non
                // plus à côté du nom) — c'est là qu'on survole/clique pour
                // ouvrir le menu (répondre, réagir, copier, infos...).
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (message.reactions.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
                        ),
                        child: Text(message.reactions.keys.join(' '), style: const TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (_hovered) ...[
                      GestureDetector(
                        onTap: onMenu,
                        child: Container(width: 20, height: 20,
                          decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9), shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 3)]),
                          child: const Icon(Icons.expand_more_rounded, size: 14, color: Color(0xFF54656F))),
                      ),
                    ],
                  ]),
                ),
              ],
            )),
          ],
        )),
          ],
        ),
      ),
      ),
    );
  }

  Widget _contenuBulleCanal(BuildContext context, _MessageCanal message, bool isPDF, Color texteColor, bool estMoi) {
    if (isPDF) {
      return Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: message.color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.picture_as_pdf_rounded, color: message.color, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(message.texte, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: texteColor)),
          Text('Document PDF officiel', style: TextStyle(fontSize: 11.5, color: texteColor.withValues(alpha: 0.7))),
        ])),
        Icon(Icons.file_download_rounded, color: message.color, size: 20),
      ]);
    }
    if (message.texte.startsWith('[GIF]')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          message.texte.substring(5), width: 160, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Text('[GIF]', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        ),
      );
    }
    if (message.texte.startsWith('[STICKER]')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: kIsWeb
            ? const Text('🏷️ Sticker', style: TextStyle(fontSize: 13, color: Color(0xFF64748B)))
            : Image.file(File(message.texte.substring(9)), width: 120, height: 120, fit: BoxFit.cover),
      );
    }
    if (message.texte.startsWith('[FICHIER]')) {
      final parts = message.texte.substring(9).split('|');
      final fType = parts.isNotEmpty ? parts[0] : 'document';
      final url = parts.length > 1 ? parts[1] : '';
      final nom = parts.length > 2 ? parts.sublist(2).join('|') : 'Fichier';
      if (fType == 'image') {
        return GestureDetector(
          onTap: () => Navigator.push(context, PageRouteBuilder(
            opaque: false, barrierColor: Colors.black,
            pageBuilder: (_, __, ___) => VisionneuseImage(url: url),
          )),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width: 300, height: 155,
              child: Image.network(url, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFFCCD0D5), alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined, color: Color(0xFF8696A0))),
              ),
            ),
          ),
        );
      }
      if (fType == 'vocal') {
        return VoiceMessagePlayer(
          url: url, dureeLabel: nom,
          couleur: estMoi ? texteColor : message.color,
          texteColor: texteColor,
        );
      }
      final icone = fType == 'video' ? Icons.videocam_rounded : fType == 'audio' ? Icons.audiotrack_rounded : Icons.insert_drive_file_rounded;
      final couleur = fType == 'video' ? const Color(0xFFDC3545) : fType == 'audio' ? const Color(0xFFFF6B35) : const Color(0xFF7F66FF);
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 34, height: 34,
          decoration: BoxDecoration(color: couleur.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icone, size: 18, color: couleur)),
        const SizedBox(width: 8),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nom, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: texteColor), maxLines: 2, overflow: TextOverflow.ellipsis),
          Text(fType == 'video' ? 'Vidéo' : fType == 'audio' ? 'Audio' : 'Document', style: TextStyle(fontSize: 12, color: texteColor.withValues(alpha: 0.7))),
        ])),
      ]);
    }
    if (message.texte.startsWith('[SONDAGE]')) {
      return SizedBox(width: 230, child: SondageWidget(sondageId: message.texte.substring(9)));
    }
    return Text(message.texte, style: TextStyle(fontSize: 15.5, color: texteColor, height: 1.4));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// MESSAGE PRIVÉ ADMIN — Version Épurée Professionnelle (Entièrement Corrigée)
// ════════════════════════════════════════════════════════════════════════════
class _MessagePriveAdmin extends StatefulWidget {
  final StudentProfile profile;
  const _MessagePriveAdmin({required this.profile});
  @override
  State<_MessagePriveAdmin> createState() => _MessagePriveAdminState();
}

class _MessagePriveAdminState extends State<_MessagePriveAdmin> {
  static final String _baseUrl = ApiService.baseUrl;
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _hasText = false;
  String? _adminId;
  String? _myUserId;

  final List<Map<String, dynamic>> _msgs = [
    {'texte': 'Bonjour, l\'administration est à votre écoute. Posez votre question de manière détaillée.',
     'estMoi': false, 'heure': '08:00', 'lu': true},
  ];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() => _hasText = _ctrl.text.trim().isNotEmpty));
    _init();
  }

  Future<void> _init() async {
    _myUserId = await ApiService.getUserId();
    await _chargerConversation();
    await SocketService().connect();
    SocketService().onPrivateMessage((data) {
      if (!mounted) return;
      final json = data is Map<String, dynamic>
          ? data
          : jsonDecode(data.toString()) as Map<String, dynamic>;
      final destinataireId = json['destinataire_id']?.toString();
      final expediteurId = json['expediteur_id']?.toString();
      if (_adminId != null && expediteurId != _adminId && destinataireId != _adminId) return;
      if (_myUserId != null && expediteurId == _myUserId) return;
      setState(() => _msgs.add({
        'texte': json['contenu'] ?? json['texte'] ?? '',
        'estMoi': false, 'heure': _now(), 'lu': true,
      }));
      _scrollBas();
    });
  }

  String _heureDe(String? createdAt) {
    final dt = (DateTime.tryParse(createdAt ?? '') ?? DateTime.now()).toLocal();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _chargerConversation() async {
    try {
      final headers = await ApiService.getHeaders();
      final rc = await http.get(
          Uri.parse('$_baseUrl/messages/admin-contact'), headers: headers);
      if (rc.statusCode != 200) return;
      _adminId = (jsonDecode(rc.body)['data']?['id'])?.toString();
      if (_adminId == null) return;

      final rh = await http.get(
          Uri.parse('$_baseUrl/messages/prives/$_adminId'), headers: headers);
      if (rh.statusCode != 200 || !mounted) return;
      final data = jsonDecode(utf8.decode(rh.bodyBytes))['data'] as List? ?? [];
      setState(() {
        _msgs.addAll(data.map((m) => {
          'texte': m['contenu'] ?? '',
          'estMoi': m['expediteur_id']?.toString() == _myUserId,
          'heure': _heureDe(m['created_at'] as String?),
          'lu': true,
        }));
      });
      _scrollBasInitial();
    } catch (_) {
      // Hors ligne : on garde le message d'accueil local
    }
  }

  @override
  void dispose() {
    SocketService().off('message:prive');
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollBas() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  /// Scroll tout en bas à l'ouverture — en plusieurs passes (voir note
  /// équivalente plus haut dans le fichier).
  void _scrollBasInitial() {
    void jump() {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => jump());
    Future.delayed(const Duration(milliseconds: 250), jump);
    Future.delayed(const Duration(milliseconds: 600), jump);
  }

  String _now() {
    final t = TimeOfDay.now();
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 16),
            onPressed: () => Navigator.pop(context)),
        title: const Row(children: [
          CircleAvatar(radius: 16, backgroundColor: Colors.white24,
              child: Icon(Icons.lock_outline_rounded, color: Colors.white, size: 16)),
          SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Administration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text('Espace d\'échange sécurisé', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(
          controller: _scroll, padding: const EdgeInsets.all(16),
          itemCount: _msgs.length,
          itemBuilder: (_, i) {
            final m = _msgs[i];
            final estMoi = m['estMoi'] as bool;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: estMoi ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (!estMoi) ...[
                    const CircleAvatar(radius: 14, backgroundColor: Color(0xFF059669),
                        child: Text('A', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white))),
                    const SizedBox(width: 8),
                  ],
                  Flexible(child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: estMoi ? const Color(0xFF1E40AF) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(estMoi ? 12 : 0),
                        bottomRight: Radius.circular(estMoi ? 0 : 12)),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(m['texte'] as String, style: TextStyle(
                          fontSize: 14, color: estMoi ? Colors.white : const Color(0xFF0F172A), height: 1.4)),
                      const SizedBox(height: 4),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(m['heure'] as String, style: TextStyle(
                            fontSize: 9, color: estMoi ? Colors.white70 : const Color(0xFF94A3B8))),
                        if (estMoi) ...[
                          const SizedBox(width: 4),
                          Icon((m['lu'] as bool) ? Icons.done_all_rounded : Icons.done_rounded,
                              size: 13, color: Colors.white70),
                        ],
                      ]),
                    ]))),
                ]));
          })),
        
        // ── ZONE D'ENVOI PRIVÉE (CORRIGÉE ICI À LA LIGNE 680) ──
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: const BoxDecoration(
            color: Colors.white, // La couleur blanche est maintenant à sa place légitime !
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Container(
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0))),
              child: TextField(controller: _ctrl, maxLines: null,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                decoration: const InputDecoration(
                  hintText: 'Poser une question à la scolarité...',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12))))),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _hasText ? _envoyer : null,
              child: Container(width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _hasText ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle),
                child: Icon(Icons.send_rounded, color: _hasText ? Colors.white : const Color(0xFF94A3B8), size: 18)),
            ),
          ]),
        ),
      ]),
    );
  }

  Future<void> _envoyer() async {
    if (_ctrl.text.trim().isEmpty) return;
    final texte = _ctrl.text.trim();
    final msgLocal = {'texte': texte, 'estMoi': true, 'heure': _now(), 'lu': false};
    setState(() => _msgs.add(msgLocal));
    _ctrl.clear();
    _scrollBas();

    if (_adminId == null) {
      // Contact admin pas encore chargé (hors ligne ?) : nouvelle tentative
      await _chargerConversation();
      if (_adminId == null) {
        if (!mounted) return;
        setState(() => _msgs.remove(msgLocal));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Serveur injoignable — message non envoyé')));
        return;
      }
    }

    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/messages/prives/$_adminId'),
        headers: headers,
        body: jsonEncode({'contenu': texte}),
      );
      if (response.statusCode == 201 && mounted) {
        setState(() => msgLocal['lu'] = true);
      } else if (mounted) {
        setState(() => _msgs.remove(msgLocal));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Échec de l\'envoi du message')));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _msgs.remove(msgLocal));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Serveur injoignable — message non envoyé')));
    }
  }
}
// ════════════════════════════════════════════════════════════════════════
// WIDGETS — enregistrement vocal (point clignotant + onde simulée)
// ════════════════════════════════════════════════════════════════════════
class _BlinkingDotCanal extends StatefulWidget {
  final bool paused;
  const _BlinkingDotCanal({required this.paused});
  @override
  State<_BlinkingDotCanal> createState() => _BlinkingDotCanalState();
}

class _BlinkingDotCanalState extends State<_BlinkingDotCanal> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.paused ? const AlwaysStoppedAnimation(1.0) : _ctrl,
      child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle)),
    );
  }
}
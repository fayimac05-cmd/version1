import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../admin/admin_theme.dart';
import '../admin/admin_widgets.dart';
import '../utils/snackbar_helper.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../widgets/delegue_badge.dart';
import '../pages/discussion_privee_page.dart';
import '../pages/emoji_gif_sticker_picker.dart';
import '../pages/chat_theme.dart';
import '../pages/chat_theme_picker_sheet.dart';
import '../pages/voice_message.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES
// ════════════════════════════════════════════════════════════════════════════
class MessageAdmin {
  final String id, expediteur, texte, heure, type;
  final bool estMoi;
  final String? etudiantRole, niveau;
  final String? photoUrl;
  // ID du message cité
  final String? idMessageRepondu;
  // Texte + expéditeur du message cité (pour l'affichage sans chercher dans la liste)
  final String? texteRepondu;
  final String? expediteurRepondu;
  bool lu;
  Map<String, int> reactions;
  bool epingle, important;

  MessageAdmin({
    required this.id, required this.expediteur, required this.texte,
    required this.heure, required this.type, required this.estMoi,
    this.etudiantRole,
    this.niveau,
    this.photoUrl,
    this.lu = true, Map<String, int>? reactions,
    this.epingle = false, this.important = false,
    this.idMessageRepondu,
    this.texteRepondu,
    this.expediteurRepondu,
  }) : reactions = reactions ?? {};
}

class GroupeAdmin {
  final String id, nom, type, avatar, description;
  final String? filiereId;
  final String? niveau; // pour colorer différemment chaque niveau (étape 4)
  final List<String> membres;
  final List<MessageAdmin> messages;
  int nbNonLus;
  bool readonly;

  GroupeAdmin({
    required this.id, required this.nom, required this.type,
    required this.avatar, required this.description,
    this.filiereId, this.niveau, required this.membres,
    required this.messages, this.nbNonLus = 0, this.readonly = false,
  });
}

// ── Données initiales / mock ──────────────────────────────────────────────
// ✅ CORRIGÉ — le canal global "Admin & Filière" (id fixe '2', toutes
// filières/niveaux mélangés) a été retiré d'ici : chaque (filière, niveau)
// a désormais son propre canal réel, chargé dynamiquement dans
// _loadGroupes() via /api/canaux/admin-filieres.
final List<GroupeAdmin> _defaultAdminGroupes = [
  GroupeAdmin(
    id: '5', nom: 'Administration & Professeurs',
    type: 'admin_profs', avatar: '',
    description: 'Canal officiel Admin ↔ Tous les professeurs',
    membres: ['Administration', 'Tous les professeurs'],
    nbNonLus: 0, readonly: false,
    messages: [],
  ),
  GroupeAdmin(
    id: '4', nom: 'Salle des Professeurs',
    type: 'professeurs', avatar: '',
    description: 'Canal d\'échanges entre professeurs',
    membres: ['Tous les professeurs'],
    nbNonLus: 0, readonly: false,
    messages: [],
  ),
  GroupeAdmin(
    id: '6', nom: 'Administration & Délégués',
    type: 'admin_delegues', avatar: '',
    description: 'Canal Admin ↔ Délégués de toutes les filières',
    membres: ['Administration', 'Délégués de filières'],
    nbNonLus: 0, readonly: false,
    messages: [],
  ),
  GroupeAdmin(
    id: '1', nom: 'Administration (Général)',
    type: 'administration', avatar: '',
    description: 'Annonces officielles et informations pédagogiques',
    membres: ['Administration', 'Tous les étudiants'],
    nbNonLus: 0, readonly: true,
    messages: [],
  ),
  GroupeAdmin(
    id: '3', nom: 'Bureau des Étudiants',
    type: 'bde', avatar: '',
    description: 'Annonces et activités du BDE',
    membres: ['Administration', 'BDE', 'Tous les étudiants'],
    nbNonLus: 0, readonly: false,
    messages: [],
  ),
];

// ── Couleur par niveau — étape 4 : chaque niveau se distingue visuellement
// dans la liste des canaux "Professeurs & Délégués" du professeur.
const Map<String, Color> _couleursNiveaux = {
  'Licence 1': Color(0xFF10B981), // vert
  'Licence 2': Color(0xFF3B82F6), // bleu
  'Licence 3': Color(0xFFF59E0B), // orange
  'Master 1':  Color(0xFF8B5CF6), // violet
  'Master 2':  Color(0xFFEC4899), // rose
};
Color _couleurPourNiveau(String? niveau) =>
    _couleursNiveaux[niveau] ?? const Color(0xFF64748B);

// ════════════════════════════════════════════════════════════════════════════
// PAGE ADMIN MESSAGES
// ════════════════════════════════════════════════════════════════════════════
class AdminMessages extends StatefulWidget {
  const AdminMessages({super.key, this.role = 'admin'});
  /// 'admin' ou 'professeur' — filtre les groupes visibles
  final String role;
  @override State<AdminMessages> createState() => AdminMessagesState();
}

class AdminMessagesState extends State<AdminMessages>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  GroupeAdmin? _groupeActif;
  final _msgCtrl           = TextEditingController();
  final _scrollCtrl        = ScrollController();
  final _keyboardFocusNode = FocusNode();
  final _textFocusNode     = FocusNode();

  bool _hasText     = false;
  bool _showEmoji   = false;
  String _themeId   = ChatThemes.classique.id;
  bool   _isRecording   = false;
  bool   _isPaused      = false;
  int    _recordSeconds = 0;
  dynamic _recordTimer; // Timer
  final _voiceRecorder = VoiceRecorderController();
  String _query         = '';
  MessageAdmin? _messageEnReponse;

  // GlobalKeys pour scroll précis vers un message cité
  final Map<String, GlobalKey> _msgKeys = {};

  String? _myUserId;
  List<GroupeAdmin> adminGroupes = List.from(_defaultAdminGroupes);

  bool get _estProf => widget.role == 'professeur';

  /// Groupes visibles pour le rôle courant
  List<GroupeAdmin> get _groupesVisibles {
    if (_estProf) {
      // Un prof voit : salle des profs, admin↔profs, coordination filière, groupes étudiants, privés
      return adminGroupes.where((g) =>
          g.type == 'professeurs' ||
          g.type == 'admin_profs' ||
          g.type == 'prof_delegues' ||
          g.type == 'prive').toList();
    } else {
      // Un admin voit tout sauf la salle des profs — et, depuis cette
      // refonte, jamais les sous-fils "Professeurs & Délégués" (type
      // prof_delegues) : ceux-ci ne sont jamais chargés pour l'admin (voir
      // _loadGroupes) donc ce filtre n'a rien à exclure en pratique, mais
      // on le garde par sécurité si jamais un ancien canal traînait.
      return adminGroupes.where((g) => g.type != 'professeurs' && g.type != 'prof_delegues').toList();
    }
  }

  List<GroupeAdmin> get _officiels => _groupesVisibles
      .where((g) => g.type == 'admin_profs' || g.type == 'admin_delegues' || g.type == 'professeurs' || g.type == 'administration' || g.type == 'bde')
      .toList();
  List<GroupeAdmin> get _filieres =>
      _groupesVisibles.where((g) => g.type == 'admin_filiere' || g.type == 'prof_delegues').toList();
  List<GroupeAdmin> get _prives =>
      _groupesVisibles.where((g) => g.type == 'prive').toList();
  int get _totalNonLus =>
      _groupesVisibles.fold(0, (s, g) => s + g.nbNonLus);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _msgCtrl.addListener(() =>
        setState(() => _hasText = _msgCtrl.text.trim().isNotEmpty));
    _loadGroupes();
  }

  Future<void> _loadGroupes() async {
    try {
      _myUserId = await ApiService.getUserId();
      final headers = await ApiService.getHeaders();

      final newGroupes = <GroupeAdmin>[];
      for (final def in _defaultAdminGroupes) {
        newGroupes.add(GroupeAdmin(
          id: def.id,
          nom: def.nom,
          type: def.type,
          avatar: def.avatar,
          description: def.description,
          membres: List.from(def.membres),
          messages: [],
          readonly: def.readonly,
        ));
      }

      // ── Canaux "Professeurs & Délégués" — UNIQUEMENT pour la vue
      // professeur. Un sous-fil par (filière, niveau) où CE prof a au moins
      // un module affecté (créés automatiquement à l'étape 2 — voir
      // getOrCreateCanalProfDelegue). Ne mélange plus tous les profs et
      // tous les niveaux d'une filière comme l'ancien mécanisme.
      if (_estProf) {
        try {
          final resF = await http.get(Uri.parse('${ApiService.baseUrl}/professeurs/mes-canaux-coordination'), headers: headers);
          if (resF.statusCode == 200) {
            final body = jsonDecode(utf8.decode(resF.bodyBytes));
            final List data = body is Map ? (body['data'] as List? ?? []) : [];
            for (final f in data) {
              final filiereNom = f['filiere_nom']?.toString() ?? '';
              final niveaux = (f['niveaux'] as List? ?? []);
              for (final n in niveaux) {
                newGroupes.add(GroupeAdmin(
                  id: n['canal_id'].toString(),
                  nom: '$filiereNom · ${n['niveau']}',
                  type: 'prof_delegues',
                  avatar: '',
                  filiereId: f['filiere_id'].toString(),
                  niveau: n['niveau']?.toString(),
                  description: 'Coordination pédagogique — $filiereNom ${n['niveau']}',
                  membres: const ['Vous', 'Délégué(e)/Adjoint(e) du niveau'],
                  nbNonLus: 0, readonly: false,
                  messages: [],
                ));
              }
            }
          }
        } catch (errF) {
          debugPrint('[AdminMessages] Erreur chargement canaux professeur-coordination: $errF');
        }
      }

      // ── Canaux Admin Filière — UNIQUEMENT pour la vue administration.
      // ✅ Remplace l'ancien canal global unique "Admin & Filière" (id=2,
      // toutes filières/niveaux mélangés) : désormais un vrai canal par
      // (filière, niveau) réellement peuplé d'étudiants. L'admin peut
      // toujours y écrire ; seuls le(s) délégué(s)/adjoint(s) de ce niveau
      // peuvent répondre (règle appliquée côté backend).
      if (!_estProf) {
        try {
          final resAF = await http.get(
            Uri.parse('${ApiService.baseUrl}/canaux/admin-filieres'),
            headers: headers,
          );
          if (resAF.statusCode == 200) {
            final body = jsonDecode(utf8.decode(resAF.bodyBytes));
            final List data = body is Map ? (body['data'] as List? ?? []) : [];
            for (final f in data) {
              final filiereNom = f['filiere_nom']?.toString() ?? '';
              final niveaux = (f['niveaux'] as List? ?? []);
              for (final n in niveaux) {
                newGroupes.add(GroupeAdmin(
                  id: n['canal_id'].toString(),
                  nom: '$filiereNom · ${n['niveau']}',
                  type: 'admin_filiere',
                  avatar: '',
                  filiereId: f['filiere_id'].toString(),
                  description: 'Administration ↔ étudiants de $filiereNom ${n['niveau']}',
                  membres: const ['Administration', 'Étudiants du niveau', 'Délégué(e)/Adjoint(e)'],
                  nbNonLus: 0, readonly: false,
                  messages: [],
                ));
              }
            }
          }
        } catch (errAF) {
          debugPrint('[AdminMessages] Erreur chargement canaux admin-filieres: $errAF');
        }
      }

      // ✅ RETIRÉ — "Prof ↔ Étudiants" (groupe_etudiants, messages_groupe
      // côté backend) permettait à un professeur de discuter avec TOUS les
      // étudiants d'une filière. Ce n'est pas la règle voulue : un
      // professeur ne doit échanger qu'avec le(s) délégué(s)/adjoint(s) de
      // son niveau — exactement ce que fait déjà "Coordination Pédagogique"
      // (canaux prof_delegue_niveau, étapes 2/4/5). Section supprimée.

      // ── Conversations privées ──
      try {
        final resP = await http.get(Uri.parse('${ApiService.baseUrl}/messages/prives'), headers: headers);
        if (resP.statusCode == 200) {
          final body = jsonDecode(utf8.decode(resP.bodyBytes));
          final List data = body is Map ? (body['data'] as List? ?? []) : (body is List ? body : []);
          for (var p in data) {
            final correspId = p['correspondant_id']?.toString();
            if (correspId == null || correspId.isEmpty) continue;
            final nom = '${p['prenoms'] ?? ''} ${p['nom'] ?? ''}'.trim();
            final nonLu = (p['is_read'] == false && p['expediteur_id']?.toString() != _myUserId);
            newGroupes.add(GroupeAdmin(
              id: correspId,
              nom: nom.isNotEmpty ? nom : 'Étudiant',
              type: 'prive',
              avatar: '',
              description: p['dernier_message']?.toString() ?? 'Conversation privée',
              membres: [nom.isNotEmpty ? nom : 'Utilisateur'],
              nbNonLus: nonLu ? 1 : 0,
              readonly: false,
              messages: [],
            ));
          }
        }
      } catch (errP) {
        debugPrint("[AdminMessages] Erreur chargement messages privés: $errP");
      }

      setState(() { adminGroupes = newGroupes; });
      _chargerNonLusCanaux(newGroupes);

      await SocketService().connect();
      SocketService().onCanalMessage((data) {
        if (!mounted) return;
        final json = data is Map<String, dynamic> ? data : jsonDecode(data.toString()) as Map<String, dynamic>;
        final cid = json['canal_id']?.toString() ?? json['canalId']?.toString();
        if (cid == null) return;
        
        final idx = adminGroupes.indexWhere((g) => g.id == cid);
        if (idx == -1) return;
        
        final g = adminGroupes[idx];
        final msgId = json['id']?.toString() ?? UniqueKey().toString();
        if (g.messages.any((m) => m.id == msgId)) return;
        if (_myUserId != null && json['auteur_id']?.toString() == _myUserId) return;

        final rawDate = json['created_at'] ?? json['createdAt'];
        final createdAt = (rawDate != null ? DateTime.tryParse(rawDate.toString()) : null)?.toLocal() ?? DateTime.now();
        final heure = '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
        final nomComplet = '${json['prenoms'] ?? ''} ${json['nom'] ?? ''}'.trim();
        final auteur = nomComplet.isNotEmpty ? nomComplet : (json['role'] == 'professeur' ? 'Professeur' : 'Utilisateur');

        setState(() {
          g.messages.add(MessageAdmin(
            id: msgId,
            expediteur: auteur,
            texte: json['contenu']?.toString() ?? '',
            heure: heure,
            type: json['type']?.toString() ?? 'texte',
            estMoi: false,
            etudiantRole: json['etudiant_role']?.toString(),
            niveau: json['niveau']?.toString(),
            photoUrl: json['photo_url']?.toString(),
            lu: _groupeActif?.id == g.id,
          ));
          if (_groupeActif?.id != g.id) g.nbNonLus++;
        });

        if (_groupeActif?.id == g.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
          });
        }
      });

      SocketService().onGroupeMessage((data) {
        if (!mounted) return;
        final json = data is Map<String, dynamic> ? data : jsonDecode(data.toString()) as Map<String, dynamic>;
        final fid = json['filiere_id']?.toString();
        if (fid == null) return;
        
        final idx = adminGroupes.indexWhere((g) => g.type == 'groupe_etudiants' && g.filiereId == fid);
        if (idx == -1) return;
        
        final g = adminGroupes[idx];
        final msgId = json['id']?.toString() ?? UniqueKey().toString();
        if (g.messages.any((m) => m.id == msgId)) return;
        if (_myUserId != null && json['auteur_id']?.toString() == _myUserId) return;

        final rawDate = json['created_at'] ?? json['createdAt'];
        final createdAt = (rawDate != null ? DateTime.tryParse(rawDate.toString()) : null)?.toLocal() ?? DateTime.now();
        final heure = '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
        final nomComplet = '${json['prenoms'] ?? ''} ${json['nom'] ?? ''}'.trim();
        final auteur = nomComplet.isNotEmpty ? nomComplet : 'Étudiant';

        setState(() {
          g.messages.add(MessageAdmin(
            id: msgId,
            expediteur: auteur,
            texte: json['contenu']?.toString() ?? '',
            heure: heure,
            type: 'texte',
            estMoi: false,
            etudiantRole: json['etudiant_role']?.toString(),
            niveau: json['niveau']?.toString(),
            photoUrl: json['photo_url']?.toString(),
            lu: _groupeActif?.id == g.id,
          ));
          if (_groupeActif?.id != g.id) g.nbNonLus++;
        });

        if (_groupeActif?.id == g.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
          });
        }
      });

      SocketService().onPrivateMessage((data) {
        if (!mounted) return;
        final json = data is Map<String, dynamic> ? data : jsonDecode(data.toString()) as Map<String, dynamic>;
        final expediteurId = json['expediteur_id']?.toString();
        if (expediteurId == null) return;
        if (_myUserId != null && expediteurId == _myUserId) return;

        final correspId = expediteurId;
        final rawDate = json['created_at'] ?? json['createdAt'];
        final createdAt = (rawDate != null ? DateTime.tryParse(rawDate.toString()) : null)?.toLocal() ?? DateTime.now();
        final heure = '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
        final nomComplet = '${json['prenoms'] ?? ''} ${json['nom'] ?? ''}'.trim();
        final auteur = nomComplet.isNotEmpty ? nomComplet : (json['role'] == 'professeur' ? 'Professeur' : 'Étudiant');

        setState(() {
          var idx = adminGroupes.indexWhere((g) => g.type == 'prive' && g.id == correspId);
          if (idx == -1) {
            final nouveauPrive = GroupeAdmin(
              id: correspId,
              nom: auteur,
              type: 'prive',
              avatar: '',
              description: json['contenu']?.toString() ?? '',
              membres: [auteur],
              nbNonLus: _groupeActif?.id == correspId ? 0 : 1,
              readonly: false,
              messages: [],
            );
            adminGroupes.add(nouveauPrive);
            idx = adminGroupes.length - 1;
          }

          final g = adminGroupes[idx];
          final msgId = json['id']?.toString() ?? UniqueKey().toString();
          if (g.messages.any((m) => m.id == msgId)) return;

          g.messages.add(MessageAdmin(
            id: msgId,
            expediteur: auteur,
            texte: json['contenu']?.toString() ?? '',
            heure: heure,
            type: 'texte',
            estMoi: false,
            photoUrl: json['photo_url']?.toString(),
            lu: _groupeActif?.id == g.id,
          ));
          if (_groupeActif?.id != g.id) g.nbNonLus++;
        });

        if (_groupeActif?.id == correspId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollCtrl.hasClients) {
              _scrollCtrl.animateTo(
                _scrollCtrl.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      });
      
    } catch (e) {
      debugPrint("Erreur loadGroupes: $e");
    }
  }

  Future<void> refreshGroupes() => _loadGroupes();

  /// Remplace les compteurs "non lus" par des valeurs réelles venant du
  /// serveur (au lieu de rester bloqués à 0 jusqu'au prochain message reçu
  /// en direct pendant la session). Les conversations privées ont déjà un
  /// vrai statut via `is_read` sur la liste `/messages/prives`, donc on ne
  /// les recharge pas ici.
  Future<void> _chargerNonLusCanaux(List<GroupeAdmin> groupes) async {
    for (final g in groupes) {
      if (g.type == 'prive') continue;
      try {
        final headers = await ApiService.getHeaders();
        final url = g.type == 'groupe_etudiants'
            ? '${ApiService.baseUrl}/messages/groupe/${g.filiereId}'
            : '${ApiService.baseUrl}/messages/canal/${g.id}';
        final res = await http.get(Uri.parse(url), headers: headers);
        if (res.statusCode != 200) continue;
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        final data = (body is Map ? body['data'] : body) as List? ?? [];
        final n = data.where((m) {
          final senderId = (m['expediteur_id'] ?? m['auteur_id'])?.toString();
          if (senderId == _myUserId) return false;
          // Le nom du champ diffère selon les endpoints ('lu' pour les
          // canaux, 'is_read' pour les privés) — on vérifie les deux.
          return m['lu'] == false || m['is_read'] == false;
        }).length;
        if (mounted) setState(() => g.nbNonLus = n);
      } catch (_) {
        // Silencieux : la conversation garde son compteur précédent (0).
      }
    }
  }

  /// Scroll tout en bas à l'ouverture d'une conversation — en plusieurs
  /// passes, car les avatars/images des messages finissent de charger après
  /// le premier affichage et modifient la hauteur réelle du contenu (sinon
  /// on atterrit un peu trop haut et il faut descendre manuellement).
  void _scrollBasInitial() {
    void jump() {
      if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => jump());
    Future.delayed(const Duration(milliseconds: 250), jump);
    Future.delayed(const Duration(milliseconds: 600), jump);
  }

  @override
  void dispose() {
    SocketService().off('message:groupe');
    SocketService().off('message:canal');
    SocketService().off('message:prive');
    _tabCtrl.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _keyboardFocusNode.dispose();
    _textFocusNode.dispose();
    _voiceRecorder.dispose();
    super.dispose();
  }

  Future<void> _chargerTheme(String conversationId) async {
    final id = await ChatThemeService.getThemeFor(conversationId);
    if (mounted) setState(() => _themeId = id);
  }

  Future<void> _choisirTheme(GroupeAdmin g) async {
    final applique = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChatThemePickerSheet(
        currentThemeId: _themeId,
        conversationId: g.id,
      ),
    );
    if (applique == true) _chargerTheme(g.id);
  }

  // Le backend "vu par" ne connaît que 3 familles de messages ; les
  // nombreux types d'affichage (admin_profs, bde, admin_filiere...)
  // transitent tous par la table messages_canal.
  String _typeBackend(GroupeAdmin g) {
    if (g.type == 'prive') return 'prive';
    if (g.type == 'groupe_etudiants') return 'groupe';
    return 'canal';
  }

  void _infosMessage(MessageAdmin msg, GroupeAdmin g) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InfosMessageSheet(type: _typeBackend(g), messageId: msg.id, heureEnvoi: msg.heure),
    );
  }

  void _repondreA(MessageAdmin msg) {
    setState(() => _messageEnReponse = msg);
    _textFocusNode.requestFocus();
  }

  bool get _isDesktop => AdminTheme.isDesktop(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isDesktop ? _layoutDesktop() : _layoutMobile(),
    );
  }

  Widget _layoutDesktop() => Row(children: [
    Container(width: 340,
      decoration: const BoxDecoration(color: Colors.white,
          border: Border(right: BorderSide(color: Color(0xFFE5E7EB)))),
      child: _sidebar()),
    Expanded(child: _groupeActif == null
        ? _accueilVide() : _chatView(_groupeActif!)),
  ]);

  Widget _layoutMobile() => _groupeActif == null
      ? Scaffold(backgroundColor: const Color(0xFFF5F7FA), body: _sidebar())
      : Scaffold(
          backgroundColor: const Color(0xFFEBE5DD),
          appBar: _chatAppBar(_groupeActif!),
          body: Column(children: [
            if (_groupeActif!.readonly) _banniereBroadcast(),
            _banniereEpingle(_groupeActif!),
            Expanded(child: ChatWallpaper(theme: ChatThemes.byId(_themeId), child: _listeMessages(_groupeActif!))),
            if (_groupeActif!.type == 'bde') _banniereLectureSeuleBde() else _zoneSaisie(_groupeActif!),
            if (_showEmoji) _panneauEmojiGifSticker(_groupeActif!),
          ]));

  // ── Bouton « Nouvelle discussion » ──────────────────────────────────────
  Future<void> _initierNouvelleDiscussion() async {
    // Détermination des types de contacts proposés selon le rôle
    final isProf = _estProf;
    List<String> options = isProf
        ? ['Étudiant', 'Administration', 'Collègue professeur']
        : ['Étudiant', 'Professeur']; // admin

    final choix = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Nouvelle discussion privée',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 4),
            const Text('Choisissez avec qui vous souhaitez échanger',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 20),
            ...options.map((opt) => GestureDetector(
              onTap: () => Navigator.pop(context, opt),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _couleurChoix(opt).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_iconeChoix(opt), color: _couleurChoix(opt), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(opt, style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)))),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                ]),
              ),
            )),
          ],
        ),
      ),
    );

    if (choix == null || !mounted) return;
    await _ouvrirSelecteurContact(choix);
  }

  Color _couleurChoix(String choix) {
    switch (choix) {
      case 'Étudiant': return const Color(0xFF059669);
      case 'Professeur': return const Color(0xFF2563EB);
      case 'Administration': return const Color(0xFF7C3AED);
      case 'Collègue professeur': return const Color(0xFF0891B2);
      default: return AdminTheme.primary;
    }
  }

  IconData _iconeChoix(String choix) {
    switch (choix) {
      case 'Étudiant': return Icons.school_rounded;
      case 'Professeur': return Icons.person_rounded;
      case 'Administration': return Icons.account_balance_rounded;
      case 'Collègue professeur': return Icons.groups_rounded;
      default: return Icons.person_outline_rounded;
    }
  }

  Future<void> _ouvrirSelecteurContact(String type) async {
    String roleFiltre;
    String titre;
    Color couleur;
    switch (type) {
      case 'Étudiant':
        roleFiltre = 'etudiant';
        titre = 'Choisir un étudiant';
        couleur = const Color(0xFF059669);
        break;
      case 'Professeur':
      case 'Collègue professeur':
        roleFiltre = 'professeur';
        titre = 'Choisir un professeur';
        couleur = const Color(0xFF2563EB);
        break;
      case 'Administration':
        roleFiltre = 'admin';
        titre = 'Choisir un administrateur';
        couleur = const Color(0xFF7C3AED);
        break;
      default:
        roleFiltre = 'etudiant';
        titre = 'Choisir un contact';
        couleur = AdminTheme.primary;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SelecteurContactPage(
          titre: titre,
          roleFiltre: roleFiltre,
          couleur: couleur,
          onContactChoisi: (id, nom, sousTitre) {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DiscussionPriveePage(
                  destinataireId: id,
                  destinataireNom: nom,
                  destinataireRole: type,
                  destinataireSousTitre: sousTitre,
                  themeColor: couleur,
                ),
              ),
            ).then((_) => _loadGroupes());
          },
        ),
      ),
    );
  }

  Widget _sidebar() => Column(children: [
    Container(color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(children: [
        Row(children: [
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_estProf ? 'Messages' : 'Messagerie', style: const TextStyle(fontSize: 18,
                fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
            if (_estProf)
              const Text('Restez en contact avec vos étudiants',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)))
            else if (_totalNonLus > 0)
              Text('$_totalNonLus non lu(s)', style: const TextStyle(
                  fontSize: 12, color: AdminTheme.primary,
                  fontWeight: FontWeight.w600)),
          ])),
          // ── Bouton Nouvelle Discussion ──
          GestureDetector(
            onTap: _initierNouvelleDiscussion,
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: AdminTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Container(height: 36,
          decoration: BoxDecoration(color: AdminTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AdminTheme.border)),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Rechercher...',
              hintStyle: TextStyle(fontSize: 13, color: AdminTheme.textMuted),
              prefixIcon: Icon(Icons.search_rounded,
                  color: AdminTheme.textMuted, size: 16),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 9)))),
        const SizedBox(height: 10),
        TabBar(controller: _tabCtrl,
          labelColor: AdminTheme.primary,
          unselectedLabelColor: AdminTheme.textSecondary,
          indicatorColor: AdminTheme.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: [
            _tabLabel('Conversations', _prives.fold(0, (s, g) => s + g.nbNonLus)),
            _tabLabel('Groupes', _officiels.fold(0, (s, g) => s + g.nbNonLus) + _filieres.fold(0, (s, g) => s + g.nbNonLus)),
          ]),
      ])),
    Container(height: 1, color: AdminTheme.border),
    Expanded(child: TabBarView(controller: _tabCtrl, children: [
      _listeGroupes(_prives),
      _listeGroupes([..._officiels, ..._filieres]),
    ])),
  ]);

  Tab _tabLabel(String label, int count) => Tab(
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label),
      if (count > 0) ...[
        const SizedBox(width: 4),
        Container(width: 16, height: 16,
          decoration: const BoxDecoration(
              color: AdminTheme.danger, shape: BoxShape.circle),
          child: Center(child: Text('$count', style: const TextStyle(
              fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)))),
      ],
    ]));

  Widget _listeGroupes(List<GroupeAdmin> groupes) {
    final f = _query.isEmpty ? groupes : groupes.where((g) =>
        g.nom.toLowerCase().contains(_query.toLowerCase())).toList();
    if (f.isEmpty) {
      return const Center(child: Text('Aucun groupe',
          style: TextStyle(fontSize: 13, color: AdminTheme.textMuted)));
    }
    return ListView.builder(
      itemCount: f.length,
      itemBuilder: (_, i) => _itemGroupe(f[i]));
  }

  IconData _getIconForSection(String type) {
    switch (type) {
      case 'admin_profs':      return Icons.school_rounded;
      case 'admin_delegues':   return Icons.groups_rounded;
      case 'admin_filiere':    return Icons.campaign_rounded;
      case 'bde':              return Icons.gavel_rounded;
      case 'prof_delegues':    return Icons.hub_rounded;
      case 'groupe_etudiants': return Icons.chat_bubble_rounded;
      default:                 return Icons.person_outline_rounded;
    }
  }

  Future<void> _selectionnerGroupe(GroupeAdmin g) async {
    setState(() {
      _groupeActif = g;
      g.nbNonLus = 0;
      _showEmoji = false;
      _msgKeys.clear();
    });
    _chargerTheme(g.id);
    if (g.type == 'groupe_etudiants' && g.filiereId != null) {
      SocketService().joinRoom('filiere:${g.filiereId}');
    } else {
      SocketService().joinRoom('canal:${g.id}');
      if (g.filiereId != null) {
        SocketService().joinRoom('filiere:${g.filiereId}');
      }
    }

    try {
      final headers = await ApiService.getHeaders();
      final url = g.type == 'prive'
          ? '${ApiService.baseUrl}/messages/prives/${g.id}'
          : g.type == 'groupe_etudiants'
              ? '${ApiService.baseUrl}/messages/groupe/${g.filiereId}'
              : '${ApiService.baseUrl}/messages/canal/${g.id}';
      
      final res = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        final data = (body is Map ? body['data'] : body) as List? ?? [];
        setState(() {
          g.messages.clear();
          for (final m in data) {
            final rawDate = m['created_at'] ?? m['createdAt'];
            final createdAt = (rawDate != null ? DateTime.tryParse(rawDate.toString()) : null)?.toLocal() ?? DateTime.now();
            final heure = '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
            final senderId = (m['expediteur_id'] ?? m['auteur_id'])?.toString();
            final estMoi = _myUserId != null && senderId == _myUserId;
            final nomComplet = '${m['prenoms'] ?? ''} ${m['nom'] ?? ''}'.trim();
            final auteur = estMoi ? 'Moi' : (nomComplet.isNotEmpty ? nomComplet : (m['role'] == 'professeur' ? 'Professeur' : 'Utilisateur'));

            g.messages.add(MessageAdmin(
              id: m['id']?.toString() ?? UniqueKey().toString(),
              expediteur: auteur,
              texte: m['contenu']?.toString() ?? '',
              heure: heure,
              type: m['type']?.toString() ?? 'texte',
              estMoi: estMoi,
              etudiantRole: m['etudiant_role']?.toString(),
              niveau: m['niveau']?.toString(),
              photoUrl: m['photo_url']?.toString(),
              lu: true,
              reactions: _reactionsDepuisJson(m['reactions']),
            ));
          }
        });
        // Marque tous les messages reçus (pas les miens) comme lus par moi —
        // ouvrir la conversation vaut consultation, comme WhatsApp.
        final typeBackend = _typeBackend(g);
        for (final m in g.messages) {
          if (!m.estMoi) ApiService.marquerMessageLu(typeBackend, m.id);
        }
        _scrollBasInitial();
      }
    } catch (e) {
      debugPrint('[AdminMessages] Erreur chargement messages: $e');
    }
  }

  Widget _itemGroupe(GroupeAdmin g) {
    final active    = _groupeActif?.id == g.id;
    final dernMsg   = g.messages.isNotEmpty ? g.messages.last : null;
    final isPrive   = g.type == 'prive';
    final isFiliere = g.type == 'admin_filiere' || g.type == 'prof_delegues';
    final color     = _couleurGroupe(g);

    return GestureDetector(
      onTap: () => _selectionnerGroupe(g),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        color: active ? AdminTheme.primaryLight : Colors.transparent,
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.12),
              borderRadius: isPrive ? null : BorderRadius.circular(12),
              shape: isPrive ? BoxShape.circle : BoxShape.rectangle),
            child: Center(child: isPrive
                ? Text(g.avatar, style: TextStyle(fontSize: 14,
                    fontWeight: FontWeight.bold, color: color))
                : Icon(_getIconForSection(g.type), size: 22, color: color))),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(g.nom, style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? AdminTheme.primary : const Color(0xFF1A1A2E)),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (dernMsg != null)
                Text(dernMsg.heure, style: const TextStyle(
                    fontSize: 10, color: AdminTheme.textMuted)),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              if (isFiliere)
                Container(margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    g.type == 'prof_delegues' ? 'Coordination' : 'Broadcast',
                    style: TextStyle(
                        fontSize: 8, fontWeight: FontWeight.w700,
                        color: color))),
              Expanded(child: Text(
                dernMsg != null ? dernMsg.texte : 'Aucun message',
                style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (g.nbNonLus > 0)
                Container(width: 18, height: 18,
                  decoration: const BoxDecoration(
                      color: AdminTheme.primary, shape: BoxShape.circle),
                  child: Center(child: Text('${g.nbNonLus}',
                      style: const TextStyle(fontSize: 9,
                          color: Colors.white, fontWeight: FontWeight.bold)))),
            ]),
          ])),
        ])));
  }

  Widget _chatView(GroupeAdmin g) => Scaffold(
      backgroundColor: const Color(0xFFEBE5DD),
      appBar: _chatAppBar(g),
      body: Column(children: [
        if (g.readonly) _banniereBroadcast(),
        _banniereEpingle(g),
        Expanded(child: ChatWallpaper(theme: ChatThemes.byId(_themeId), child: GestureDetector(
            onTap: () => setState(() => _showEmoji = false),
            child: _listeMessages(g)))),
        if (g.type == 'bde') _banniereLectureSeuleBde() else _zoneSaisie(g),
        if (_showEmoji) _panneauEmojiGifSticker(g),
      ]));

  PreferredSizeWidget _chatAppBar(GroupeAdmin g) => AppBar(
      backgroundColor: AdminTheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: !_isDesktop
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => setState(() => _groupeActif = null))
          : null,
      automaticallyImplyLeading: !_isDesktop,
      titleSpacing: 0,
      title: Row(children: [
        Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.2),
                borderRadius: g.type == 'prive' ? null : BorderRadius.circular(8),
                shape: g.type == 'prive' ? BoxShape.circle : BoxShape.rectangle),
            child: Center(child: Text(g.avatar,
                style: TextStyle(
                    fontSize: g.type == 'prive' ? 12 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)))),
        const SizedBox(width: 10),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(g.nom, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${g.membres.length} membres',
              style: const TextStyle(fontSize: 10, color: Colors.white70)),
        ])),
      ]),
      actions: [
        IconButton(
            icon: const Icon(Icons.palette_outlined,
                color: Colors.white70, size: 20),
            onPressed: () => _choisirTheme(g)),
        IconButton(
            icon: const Icon(Icons.info_outline_rounded,
                color: Colors.white70, size: 20),
            onPressed: () => _infoGroupe(g)),
      ],
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withValues(alpha:0.2))));

  Widget _banniereBroadcast() => Container(
      color: AdminTheme.infoLight,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: const Row(children: [
        Icon(Icons.campaign_rounded, color: AdminTheme.info, size: 14),
        SizedBox(width: 8),
        Expanded(child: Text('Broadcast — Seuls Admin et Délégué peuvent écrire.',
            style: TextStyle(fontSize: 11, color: AdminTheme.info,
                fontWeight: FontWeight.w500))),
      ]));

  // ── Bannière "lecture seule" pour le canal Bureau des Étudiants — le BDE
  // est composé d'élèves (président/adjoint nommés par l'admin), pas d'un
  // rôle administratif : l'administration n'a donc aucun droit d'écriture
  // ici, ni via l'interface ni via l'API (voir peutEcrireCanal côté
  // backend). Remplace entièrement la zone de saisie, contrairement à
  // _banniereBroadcast() qui elle laisse l'admin écrire.
  Widget _banniereLectureSeuleBde() => Container(
      color: const Color(0xFFF5F3FF),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: const Row(children: [
        Icon(Icons.lock_outline_rounded, color: Color(0xFF7C3AED), size: 16),
        SizedBox(width: 8),
        Expanded(child: Text(
            'Lecture seule — seuls le/la président(e) et l\'adjoint(e) du BDE (élèves nommés) peuvent écrire ici, depuis leur propre compte.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF7C3AED), fontWeight: FontWeight.w500))),
      ]));

  // ── Bannière "message épinglé" — affiche le plus récent, tap pour y
  // aller directement, épingle multiples comptées à côté.
  Widget _banniereEpingle(GroupeAdmin g) {
    final epingles = g.messages.where((m) => m.epingle).toList();
    if (epingles.isEmpty) return const SizedBox.shrink();
    final dernier = epingles.last;
    return GestureDetector(
      onTap: () => _scrollerVersMessage(dernier.id),
      child: Container(
        color: const Color(0xFFF0F2F5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(children: [
          const Icon(Icons.push_pin_rounded, color: AdminTheme.primary, size: 15),
          const SizedBox(width: 10),
          if (epingles.length > 1)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: AdminTheme.primary, borderRadius: BorderRadius.circular(8)),
              child: Text('${epingles.length}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dernier.expediteur,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminTheme.primary)),
              Text(dernier.texte,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF54656F)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          GestureDetector(
            onTap: () => setState(() => dernier.epingle = false),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF8696A0)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Scroll précis vers le message cité via GlobalKey ─────────────────
  void _scrollerVersMessage(String idCible) {
    final key = _msgKeys[idCible];
    if (key == null) return;
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      alignment: 0.3, // positionne le message à 30% du haut
    );
  }

  // ── Liste des messages avec swipe-to-reply ───────────────────────────
  Widget _listeMessages(GroupeAdmin g) {
    // Prépare une GlobalKey par message
    for (final msg in g.messages) {
      _msgKeys.putIfAbsent(msg.id, () => GlobalKey());
    }
    return ListView.builder(
      clipBehavior: Clip.hardEdge,
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      itemCount: g.messages.length,
      itemBuilder: (_, i) {
        final msg = g.messages[i];
        // Retrouve le texte du message cité
        MessageAdmin? msgCite;
        if (msg.idMessageRepondu != null) {
          try {
            msgCite = g.messages
                .firstWhere((m) => m.id == msg.idMessageRepondu);
          } catch (_) {}
        }
        return Column(
          key: _msgKeys[msg.id],
          children: [
            if (i == 0) _separateurDate('Aujourd\'hui'),
            _BulleAdmin(
              key: ValueKey(msg.id),
              message: msg,
              msgCite: msgCite,
              maxWidth: MediaQuery.of(context).size.width * 0.55,
              theme: ChatThemes.byId(_themeId),
              onMenu: () => _menuMsg(msg, g),
              onReply: () => _repondreA(msg),
              onTapReply: msgCite != null
                  ? () => _scrollerVersMessage(msg.idMessageRepondu!)
                  : null,
            ),
          ],
        );
      });
  }

  // ── Menu message ──────────────────────────────────────────────────────
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

  /// Ajoute une réaction avec mise à jour optimiste immédiate, puis envoi au
  /// serveur pour qu'elle survive à un rafraîchissement. Les conversations
  /// privées ('prive') ne sont pas encore supportées côté backend pour les
  /// réactions (getMessagesPrives ne les renvoie pas) — la réaction y reste
  /// locale uniquement pour l'instant.
  void _envoyerReaction(MessageAdmin msg, GroupeAdmin g, String emoji) {
    setState(() => msg.reactions[emoji] = (msg.reactions[emoji] ?? 0) + 1);
    if (g.type == 'prive') return;
    final idNumerique = int.tryParse(msg.id);
    if (idNumerique == null) return;
    () async {
      try {
        final headers = await ApiService.getHeaders();
        final body = g.type == 'groupe_etudiants'
            ? {'emoji': emoji, 'type': 'groupe', 'filiereId': g.filiereId}
            : {'emoji': emoji, 'type': 'canal', 'canalId': g.id};
        await http.post(
          Uri.parse('${ApiService.baseUrl}/messages/$idNumerique/reaction'),
          headers: headers,
          body: jsonEncode(body),
        );
      } catch (_) {}
    }();
  }

  Future<String?> _choisirEmojiReaction() {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmojiGifStickerPicker(
        emojiOnly: true,
        onEmoji: (emoji) => Navigator.pop(context, emoji),
        onEnvoiDirect: (_, __) {},
      ),
    );
  }

  void _menuMsg(MessageAdmin msg, GroupeAdmin g) {
    showModalBottomSheet(context: context,
      backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 6),
          Container(width: 36, height: 4, decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...['👍', '❤️', '😂', '😮', '😢', '🙏'].map((emoji) => GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _envoyerReaction(msg, g, emoji);
                      },
                      child: Container(width: 32, height: 32,
                        alignment: Alignment.center,
                        child: Text(emoji, style: const TextStyle(fontSize: 20))),
                    )),
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    final emoji = await _choisirEmojiReaction();
                    if (emoji != null) {
                      _envoyerReaction(msg, g, emoji);
                    }
                  },
                  child: Container(width: 32, height: 32,
                    decoration: const BoxDecoration(
                        color: Color(0xFFF5F7FA), shape: BoxShape.circle),
                    child: const Icon(Icons.add_rounded, color: Color(0xFF54656F), size: 17)),
                ),
              ])),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _act(Icons.info_outline_rounded, 'Infos du message',
              const Color(0xFF54656F), () {
                Navigator.pop(context);
                _infosMessage(msg, g);
              }),
          _act(Icons.reply_rounded, 'Répondre',
              const Color(0xFF54656F), () {
                Navigator.pop(context);
                _repondreA(msg);
              }),
          _act(Icons.copy_rounded, 'Copier',
              const Color(0xFF54656F), () { Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: msg.texte));
                _snack('Texte copié !'); }),
          _act(Icons.forward_rounded, 'Transférer',
              const Color(0xFF54656F), () { Navigator.pop(context);
                _transferer(msg); }),
          _act(msg.epingle ? Icons.push_pin_outlined : Icons.push_pin_rounded,
            msg.epingle ? 'Désépingler' : 'Épingler',
            const Color(0xFF54656F), () { Navigator.pop(context);
              setState(() => msg.epingle = !msg.epingle); }),
          _act(msg.important ? Icons.star_rounded : Icons.star_outline_rounded,
            msg.important ? 'Retirer des importants' : 'Marquer comme important',
            const Color(0xFF54656F), () { Navigator.pop(context);
              setState(() => msg.important = !msg.important); }),
          _act(Icons.check_box_outlined, 'Sélectionner',
              const Color(0xFF54656F), () { Navigator.pop(context);
                _snack('Mode sélection'); }),
          _act(Icons.save_alt_rounded, 'Enregistrer sous',
              const Color(0xFF54656F), () { Navigator.pop(context);
                _snack('Enregistrement...'); }),
          _act(Icons.share_rounded, 'Partager',
              const Color(0xFF54656F), () { Navigator.pop(context);
                _snack('Partage...'); }),
          if (msg.estMoi)
            _act(Icons.delete_outline_rounded, 'Supprimer',
                const Color(0xFFDC2626), () { Navigator.pop(context);
                  setState(() => g.messages.remove(msg)); }),
          SizedBox(height: 8 + MediaQuery.of(context).padding.bottom),
        ]),
          ),
        ),
      ),
    );
  }

  Widget _act(IconData icon, String label, Color color, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(fontSize: 13.5, color: color, fontWeight: FontWeight.w500)),
          ]),
        ),
      );

  void _tousEmojis(MessageAdmin msg) {
    // Panneau de réactions supprimé — interface professionnelle sans emoji
    _snack('Réaction ajoutée');
  }

  // ── Zone de saisie avec bandeau de réponse ───────────────────────────
  // ── helpers enregistrement (capture micro réelle) ─────────────────────
  Future<void> _startRecording() async {
    final ok = await _voiceRecorder.start();
    if (!ok) {
      _snack('Permission microphone refusée. Autorise le micro dans les réglages.');
      return;
    }
    setState(() { _isRecording = true; _isPaused = false; _recordSeconds = 0; });
    HapticFeedback.mediumImpact();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) setState(() => _recordSeconds++);
    });
  }

  Future<void> _pauseRecording() async {
    await _voiceRecorder.pauseOuReprendre();
    setState(() => _isPaused = _voiceRecorder.isPaused);
    HapticFeedback.lightImpact();
  }

  Future<void> _cancelRecording() async {
    (_recordTimer as Timer?)?.cancel();
    await _voiceRecorder.annuler();
    setState(() { _isRecording = false; _isPaused = false; _recordSeconds = 0; });
  }

  Future<void> _sendRecording(GroupeAdmin g) async {
    (_recordTimer as Timer?)?.cancel();
    final dur = _fmtDuration(_recordSeconds);
    setState(() { _isRecording = false; _isPaused = false; _recordSeconds = 0; });

    final bytes = await _voiceRecorder.arreterEtRecuperer();
    if (bytes == null || bytes.isEmpty) {
      _snack('Échec de l\'enregistrement.');
      return;
    }
    _snack('Envoi en cours...');
    final upload = await ApiService.uploaderFichierMessage(bytes, 'vocal_${DateTime.now().millisecondsSinceEpoch}.m4a');
    if (!mounted) return;
    if (upload['success'] != true) {
      _snack(upload['error']?.toString() ?? 'Échec de l\'envoi du message vocal.');
      return;
    }
    final url = upload['url'].toString();
    final contenu = '[FICHIER]vocal|$url|$dur';

    setState(() {
      g.messages.add(MessageAdmin(
        id: 'MD${DateTime.now().millisecondsSinceEpoch}',
        expediteur: 'Administration', texte: contenu,
        heure: _now(), type: 'texte', estMoi: true));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
    try {
      final headers = await ApiService.getHeaders();
      final Uri uri = g.type == 'prive'
          ? Uri.parse('${ApiService.baseUrl}/messages/prives/${g.id}')
          : g.type == 'groupe_etudiants'
              ? Uri.parse('${ApiService.baseUrl}/messages/groupe/${g.filiereId}')
              : Uri.parse('${ApiService.baseUrl}/messages/canal/${g.id}');
      await http.post(uri, headers: headers, body: jsonEncode({'contenu': contenu}));
    } catch (e) {
      debugPrint('[AdminMessages] Erreur envoi vocal: $e');
    }
  }

  String _fmtDuration(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  Widget _zoneSaisie(GroupeAdmin g) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Bandeau "En réponse à…"
      if (_messageEnReponse != null && !_isRecording)
        Container(
          color: const Color(0xFFEAE6DF),
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          child: Row(children: [
            Container(width: 3, height: 40,
              decoration: BoxDecoration(
                color: AdminTheme.primary,
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_messageEnReponse!.expediteur,
                  style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700, color: AdminTheme.primary)),
                const SizedBox(height: 1),
                Text(_messageEnReponse!.texte,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF54656F)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
            GestureDetector(
              onTap: () => setState(() => _messageEnReponse = null),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close_rounded,
                    size: 20, color: Color(0xFF8696A0)))),
          ])),

      // ── Barre d'enregistrement WhatsApp style ──────────────────────
      if (_isRecording)
        Container(
          color: const Color(0xFFF0EBE3),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Bouton supprimer
            GestureDetector(
              onTap: _cancelRecording,
              child: Container(width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0))),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFDC2626), size: 22))),
            const SizedBox(width: 8),
            // Point rouge clignotant + timer
            _BlinkingDot(paused: _isPaused),
            const SizedBox(width: 6),
            Text(_fmtDuration(_recordSeconds),
              style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w600, color: Color(0xFF111B21))),
            const SizedBox(width: 10),
            // Waveform simulée
            Expanded(child: VoiceWaveform(paused: _isPaused, controller: _voiceRecorder, couleur: AdminTheme.primary)),
            const SizedBox(width: 8),
            // Bouton pause/reprendre
            GestureDetector(
              onTap: _pauseRecording,
              child: Container(width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Icon(
                  _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  color: const Color(0xFF54656F), size: 22))),
            const SizedBox(width: 8),
            // Bouton envoyer
            GestureDetector(
              onTap: () => _sendRecording(g),
              child: Container(width: 42, height: 42,
                decoration: const BoxDecoration(
                    color: AdminTheme.primary, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 19))),
          ])),

      // ── Champ de saisie normal ──────────────────────────────────────
      if (!_isRecording)
        Container(
          color: const Color(0xFFF0EBE3),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _icnBtn(Icons.add_rounded, () => _menuPieceJointe(g)),
            const SizedBox(width: 6),
            _icnBtn(
              _showEmoji ? Icons.keyboard_alt_outlined : Icons.emoji_emotions_outlined,
              () => setState(() => _showEmoji = !_showEmoji),
            ),
            const SizedBox(width: 6),
            Expanded(child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha:0.06), blurRadius: 4)]),
              child: KeyboardListener(
                focusNode: _keyboardFocusNode,
                onKeyEvent: (e) {
                  if (e is KeyDownEvent &&
                      e.logicalKey == LogicalKeyboardKey.enter &&
                      !HardwareKeyboard.instance.isShiftPressed) {
                    _envoyer(g);
                  }
                },
                child: TextField(
                  controller: _msgCtrl,
                  focusNode: _textFocusNode,
                  maxLines: null,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF111B21)),
                  decoration: InputDecoration(
                    hintText: g.readonly ? 'Message broadcast...' : 'Message...',
                    hintStyle: const TextStyle(
                        fontSize: 14, color: Color(0xFF8696A0)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10)))))),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _hasText
                  ? GestureDetector(key: const ValueKey('send'),
                      onTap: () => _envoyer(g),
                      child: Container(width: 42, height: 42,
                        decoration: const BoxDecoration(
                            color: AdminTheme.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 19)))
                  : GestureDetector(
                      key: const ValueKey('mic'),
                      onTap: _startRecording,
                      child: Container(width: 42, height: 42,
                        decoration: const BoxDecoration(
                            color: AdminTheme.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.mic_rounded,
                            color: Colors.white, size: 22)))),
          ])),
    ]);

  Widget _icnBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: SizedBox(width: 34, height: 34,
      child: Icon(icon, color: const Color(0xFF667781), size: 22)));

  Widget _panneauEmojiGifSticker(GroupeAdmin g) => EmojiGifStickerPicker(
    onEmoji: (emoji) {
      _msgCtrl.text += emoji;
      _msgCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _msgCtrl.text.length));
    },
    onEnvoiDirect: (type, valeur) {
      if (type == 'gif') {
        _envoyerGif(g, valeur);
      } else {
        _envoyerSticker(valeur, g);
      }
    },
  );

  void _menuPieceJointe(GroupeAdmin g) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          _mitem(Icons.insert_drive_file_outlined, 'Document',
              const Color(0xFF7F66FF), () { Navigator.pop(context);
                _envoyerFichier(g, 'document'); }),
          _mitem(Icons.photo_library_outlined, 'Photos et vidéos',
              const Color(0xFF00A884), () { Navigator.pop(context);
                _envoyerFichier(g, 'media'); }),
          _mitem(Icons.camera_alt_outlined, 'Caméra',
              const Color(0xFFDC3545), () { Navigator.pop(context);
                _envoyerFichier(g, 'camera'); }),
          _mitem(Icons.headphones_outlined, 'Audio',
              const Color(0xFFFF6B35), () { Navigator.pop(context);
                _envoyerFichier(g, 'audio'); }),
          _mitem(Icons.poll_outlined, 'Sondage',
              const Color(0xFF0D6EFD), () { Navigator.pop(context);
                _creerSondage(g); }),
          _mitem(Icons.add_circle_outline_rounded, 'Nouveau sticker',
              const Color(0xFF20C997), () { Navigator.pop(context);
                setState(() => _showEmoji = true); }),
          const SizedBox(height: 8),
        ])));
  }

  Widget _mitem(IconData icon, String label, Color color, VoidCallback onTap) =>
      ListTile(
        leading: Container(width: 38, height: 38,
          decoration: BoxDecoration(color: color.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
        title: Text(label, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500)),
        onTap: onTap);

  void _transferer(MessageAdmin msg) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.all(14),
            child: Text('Transférer à...', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800))),
          const Divider(height: 1),
          ListTile(
            leading: Container(width: 40, height: 40,
              decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Icon(
                  Icons.share_rounded, color: Color(0xFF25D366), size: 22))),
            title: const Text('Partager sur WhatsApp',
                style: TextStyle(fontWeight: FontWeight.w700)),
            onTap: () { Navigator.pop(context);
              _snack('Ouverture WhatsApp...'); }),
          const Divider(height: 1),
          Expanded(child: ListView.builder(
            itemCount: adminGroupes.length,
            itemBuilder: (_, i) {
              final g = adminGroupes[i];
              return ListTile(
                leading: Container(width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: AdminTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text(g.avatar,
                      style: const TextStyle(fontSize: 16)))),
                title: Text(g.nom, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
                onTap: () { Navigator.pop(context);
                  setState(() => g.messages.add(MessageAdmin(
                    id: 'T${DateTime.now().millisecondsSinceEpoch}',
                    expediteur: 'Admin',
                    texte: 'Transféré : ${msg.texte}',
                    heure: _now(), type: 'texte', estMoi: true)));
                   _snack('Transféré !'); });
            })),
        ])));
  }

  void _infoGroupe(GroupeAdmin g) {
    showModalBottomSheet(context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: AdminTheme.border,
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          const Icon(Icons.forum_rounded, size: 32, color: AdminTheme.textSecondary),
          const SizedBox(height: 6),
          Text(g.nom, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800)),
          Text(g.description, style: const TextStyle(
              fontSize: 12, color: AdminTheme.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 14),
          if (g.readonly)
            Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AdminTheme.infoLight,
                  borderRadius: BorderRadius.circular(8)),
              child: const Row(children: [
                Icon(Icons.info_outline, color: AdminTheme.info, size: 14),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Mode Broadcast : Admin et Délégué écrivent. '
                  'Les étudiants lisent et réagissent.',
                  style: TextStyle(fontSize: 11, color: AdminTheme.info,
                      fontWeight: FontWeight.w600))),
              ])),
          const SizedBox(height: 12),
          Text('${g.membres.length} membres',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ...g.membres.map((m) => ListTile(dense: true,
            leading: CircleAvatar(radius: 14,
                backgroundColor: AdminTheme.primaryLight,
                child: Text(m[0], style: const TextStyle(fontSize: 11,
                    fontWeight: FontWeight.bold, color: AdminTheme.primary))),
            title: Text(m, style: const TextStyle(fontSize: 13)))),
        ]))));
  }

  Widget _accueilVide() => Container(
    color: const Color(0xFFF5F7FA),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 72, height: 72,
        decoration: BoxDecoration(color: AdminTheme.primaryLight,
            borderRadius: BorderRadius.circular(18)),
        child: const Center(child: Text('💬',
            style: TextStyle(fontSize: 32)))),
      const SizedBox(height: 14),
      const Text('Sélectionnez une conversation',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      const Text('Choisissez un groupe dans la liste.',
          style: TextStyle(fontSize: 13, color: AdminTheme.textSecondary)),
    ])));

  Future<void> _envoyer(GroupeAdmin g) async {
    if (_msgCtrl.text.trim().isEmpty) return;
    final rep = _messageEnReponse;
    final texte = _msgCtrl.text.trim();
    
    setState(() {
      g.messages.add(MessageAdmin(
        id: 'M${DateTime.now().millisecondsSinceEpoch}',
        expediteur: 'Administration',
        texte: texte,
        heure: _now(),
        type: 'texte',
        estMoi: true,
        idMessageRepondu: rep?.id,
        texteRepondu: rep?.texte,
        expediteurRepondu: rep?.expediteur,
      ));
      _messageEnReponse = null;
    });
    _msgCtrl.clear();
    _textFocusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final headers = await ApiService.getHeaders();
      if (g.type == 'prive') {
        // Envoi privé via HTTP (le serveur persiste et notifie le destinataire par socket)
        await http.post(
          Uri.parse('${ApiService.baseUrl}/messages/prives/${g.id}'),
          headers: headers,
          body: jsonEncode({'contenu': texte}),
        );
      } else if (g.type == 'groupe_etudiants') {
        // Envoi via HTTP (le serveur persiste et diffuse dans filiere:X par socket)
        await http.post(
          Uri.parse('${ApiService.baseUrl}/messages/groupe/${g.filiereId}'),
          headers: headers,
          body: jsonEncode({'contenu': texte}),
        );
      } else {
        // Canaux officiels : envoi via HTTP (le serveur persiste et diffuse dans canal:X par socket)
        await http.post(
          Uri.parse('${ApiService.baseUrl}/messages/canal/${g.id}'),
          headers: headers,
          body: jsonEncode({'contenu': texte}),
        );
      }
    } catch (e) {
      debugPrint('[AdminMessages] Erreur envoi: $e');
    }
  }

  void _envoyerSticker(String emoji, GroupeAdmin g) {
    setState(() {
      _showEmoji = false;
      g.messages.add(MessageAdmin(
        id: 'S${DateTime.now().millisecondsSinceEpoch}',
        expediteur: 'Admin', texte: emoji,
        heure: _now(), type: 'sticker', estMoi: true));
    });
  }

  // ── GIF réel (URL publique GIPHY) — envoyé via le même canal texte que
  // les messages normaux, en réutilisant le routage prive/groupe/canal
  // déjà en place dans _envoyer(). ─────────────────────────────────────
  Future<void> _envoyerGif(GroupeAdmin g, String url) async {
    final contenu = '[GIF]$url';
    setState(() {
      _showEmoji = false;
      g.messages.add(MessageAdmin(
        id: 'M${DateTime.now().millisecondsSinceEpoch}',
        expediteur: 'Administration', texte: contenu,
        heure: _now(), type: 'texte', estMoi: true));
    });
    try {
      final headers = await ApiService.getHeaders();
      final Uri uri;
      if (g.type == 'prive') {
        uri = Uri.parse('${ApiService.baseUrl}/messages/prives/${g.id}');
      } else if (g.type == 'groupe_etudiants') {
        uri = Uri.parse('${ApiService.baseUrl}/messages/groupe/${g.filiereId}');
      } else {
        uri = Uri.parse('${ApiService.baseUrl}/messages/canal/${g.id}');
      }
      await http.post(uri, headers: headers, body: jsonEncode({'contenu': contenu}));
    } catch (e) {
      debugPrint('[AdminMessages] Erreur envoi GIF: $e');
    }
  }

  // ── Envoi réel d'un fichier (document/photo/vidéo/audio) — sélectionné
  // depuis l'appareil, uploadé sur Cloudinary via le backend, puis envoyé
  // comme un vrai message texte contenant "[FICHIER]type|url|nom" — aucune
  // modification des tables de messages existantes n'est nécessaire.
  Future<void> _envoyerFichier(GroupeAdmin g, String categorie) async {
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
        final picked = await ImagePicker().pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
          imageQuality: 85,
        );
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
      _snack('Erreur lors de la sélection du fichier.');
      return;
    }

    if (bytes == null || bytes.isEmpty || nom == null) {
      _snack('Impossible de lire le fichier sélectionné.');
      return;
    }

    _snack('Envoi en cours...');
    final upload = await ApiService.uploaderFichierMessage(bytes, nom);
    if (!mounted) return;
    if (upload['success'] != true) {
      _snack(upload['error']?.toString() ?? 'Échec de l\'envoi du fichier.');
      return;
    }
    final url = upload['url'].toString();
    final contenu = '[FICHIER]$type|$url|$nom';

    setState(() {
      g.messages.add(MessageAdmin(
        id: 'MD${DateTime.now().millisecondsSinceEpoch}',
        expediteur: 'Administration', texte: contenu,
        heure: _now(), type: 'texte', estMoi: true));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });

    try {
      final headers = await ApiService.getHeaders();
      final Uri uri = g.type == 'prive'
          ? Uri.parse('${ApiService.baseUrl}/messages/prives/${g.id}')
          : g.type == 'groupe_etudiants'
              ? Uri.parse('${ApiService.baseUrl}/messages/groupe/${g.filiereId}')
              : Uri.parse('${ApiService.baseUrl}/messages/canal/${g.id}');
      await http.post(uri, headers: headers, body: jsonEncode({'contenu': contenu}));
    } catch (e) {
      debugPrint('[AdminMessages] Erreur envoi fichier: $e');
    }
  }

  // ── Création d'un sondage — entièrement configurable par le créateur ──
  Future<void> _creerSondage(GroupeAdmin g) async {
    final sondageId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreationSondageSheet(),
    );
    if (sondageId == null || !mounted) return;
    await _envoyerSondage(g, sondageId);
  }

  Future<void> _envoyerSondage(GroupeAdmin g, String sondageId) async {
    final contenu = '[SONDAGE]$sondageId';
    setState(() {
      g.messages.add(MessageAdmin(
        id: 'MD${DateTime.now().millisecondsSinceEpoch}',
        expediteur: 'Administration', texte: contenu,
        heure: _now(), type: 'texte', estMoi: true));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
    try {
      final headers = await ApiService.getHeaders();
      final Uri uri = g.type == 'prive'
          ? Uri.parse('${ApiService.baseUrl}/messages/prives/${g.id}')
          : g.type == 'groupe_etudiants'
              ? Uri.parse('${ApiService.baseUrl}/messages/groupe/${g.filiereId}')
              : Uri.parse('${ApiService.baseUrl}/messages/canal/${g.id}');
      await http.post(uri, headers: headers, body: jsonEncode({'contenu': contenu}));
    } catch (e) {
      debugPrint('[AdminMessages] Erreur envoi sondage: $e');
    }
  }

  // Couleur d'un groupe — pour "Professeurs & Délégués" (vue prof), la
  // couleur dépend du niveau (étape 4) plutôt que du type seul, pour
  // distinguer visuellement Licence 1 / Licence 2 / etc.
  Color _couleurGroupe(GroupeAdmin g) {
    if (g.type == 'prof_delegues' && g.niveau != null) {
      return _couleurPourNiveau(g.niveau);
    }
    return _couleurType(g.type);
  }

  Color _couleurType(String type) {
    switch (type) {
      case 'admin_profs':      return AdminTheme.primary;
      case 'admin_delegues':   return AdminTheme.warning;
      case 'admin_filiere':    return AdminTheme.info;
      case 'bde':              return const Color(0xFF7C3AED); // Matching canal_screen.dart BDE color
      case 'prive':            return AdminTheme.success;
      case 'groupe_etudiants': return const Color(0xFFF59E0B);
      case 'prof_delegues':    return const Color(0xFF7C3AED);
      default:                 return AdminTheme.textMuted;
    }
  }

  Widget _separateurDate(String d) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFD9F2E4),
          borderRadius: BorderRadius.circular(8)),
      child: Text(d, style: const TextStyle(fontSize: 11,
          color: Color(0xFF54656F), fontWeight: FontWeight.w500)))));

  String _now() {
    final t = TimeOfDay.now();
    return '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
  }

  void _snack(String msg) => showAppSnackBar(context, msg);
}

// ════════════════════════════════════════════════════════════════════════════
// BULLE ADMIN — swipe-to-reply + citation WhatsApp style
// ════════════════════════════════════════════════════════════════════════════
class _BulleAdmin extends StatefulWidget {
  final MessageAdmin message;
  final MessageAdmin? msgCite;   // le message cité complet (pour afficher le vrai texte)
  final double maxWidth;
  final ChatThemeData theme;
  final VoidCallback onMenu;
  final VoidCallback onReply;
  final VoidCallback? onTapReply;

  const _BulleAdmin({
    super.key,
    required this.message,
    this.msgCite,
    required this.maxWidth,
    required this.theme,
    required this.onMenu,
    required this.onReply,
    this.onTapReply,
  });

  @override
  State<_BulleAdmin> createState() => _BulleAdminState();
}

class _BulleAdminState extends State<_BulleAdmin>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;

  // ── Swipe-to-reply ────────────────────────────────────────────────────
  double _dragOffset = 0;
  bool   _replyTriggered = false;
  late AnimationController _snapCtrl;
  late Animation<double>   _snapAnim;

  static const double _triggerThreshold = 60.0; // px pour déclencher la réponse
  static const double _maxDrag          = 80.0;

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    // Seulement glisser vers la droite
    final delta = d.delta.dx;
    if (delta < 0 && _dragOffset <= 0) return;
    setState(() {
      _dragOffset = (_dragOffset + delta).clamp(0.0, _maxDrag);
      if (_dragOffset >= _triggerThreshold && !_replyTriggered) {
        _replyTriggered = true;
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails d) {
    if (_replyTriggered) {
      widget.onReply();
    }
    // Snap retour à 0
    _snapAnim = Tween<double>(begin: _dragOffset, end: 0).animate(
        CurvedAnimation(parent: _snapCtrl, curve: Curves.easeOut));
    _snapAnim.addListener(() => setState(() => _dragOffset = _snapAnim.value));
    _snapCtrl.forward(from: 0);
    _replyTriggered = false;
  }

  MessageAdmin get msg => widget.message;

  @override
  Widget build(BuildContext context) {
    final estMoi = msg.estMoi;

    return GestureDetector(
      // Swipe vers la droite = répondre (tactile)
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      // Long press = menu
      onLongPress: widget.onMenu,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Stack(
            children: [
              // ── Icône réponse qui apparaît lors du swipe ──────────────
              if (_dragOffset > 8)
                Positioned(
                  left: estMoi ? null : (_dragOffset - 32).clamp(4.0, 48.0),
                  right: estMoi ? (_dragOffset - 32).clamp(4.0, 48.0) : null,
                  top: 0, bottom: 0,
                  child: Align(
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: (_dragOffset / _triggerThreshold).clamp(0.0, 1.0),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: AdminTheme.primary.withValues(alpha:0.15),
                          shape: BoxShape.circle),
                        child: Icon(Icons.reply_rounded,
                          size: 18,
                          color: _replyTriggered
                              ? AdminTheme.primary
                              : const Color(0xFF8696A0)),
                      ),
                    ),
                  ),
                ),

              // ── La bulle elle-même translatée ──────────────────────────
              Transform.translate(
                offset: Offset(_dragOffset, 0),
                child: Row(
                  mainAxisAlignment: estMoi
                      ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Avatar expéditeur (messages reçus)
                    if (!estMoi) ...[
                      Container(width: 24, height: 24,
                        decoration: BoxDecoration(
                            color: AdminTheme.primaryLight,
                            shape: BoxShape.circle,
                            image: (msg.photoUrl != null && msg.photoUrl!.isNotEmpty)
                                ? DecorationImage(image: NetworkImage(msg.photoUrl!), fit: BoxFit.cover)
                                : null),
                        child: (msg.photoUrl == null || msg.photoUrl!.isEmpty)
                            ? Center(child: Text(_initialesExpediteur(msg.expediteur),
                                style: const TextStyle(fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: AdminTheme.primary)))
                            : null),
                      const SizedBox(width: 4),
                    ],

                    // Chevron menu (hover, mes messages)
                    if (estMoi && _hovered)
                      GestureDetector(onTap: widget.onMenu,
                        child: Container(width: 20, height: 20,
                          margin: const EdgeInsets.only(right: 4, bottom: 6),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.9),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(
                                  color: Colors.black.withValues(alpha:0.15),
                                  blurRadius: 3)]),
                          child: const Icon(Icons.expand_more_rounded,
                              size: 14, color: Color(0xFF54656F))))
                    else if (estMoi)
                      const SizedBox(width: 24),

                    // ── Corps de la bulle ──────────────────────────────
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: widget.maxWidth),
                      child: Container(
                        decoration: BoxDecoration(
                          color: msg.type == 'sticker'
                              ? Colors.transparent
                              : estMoi
                                  ? widget.theme.bulleMoi
                                  : widget.theme.bulleAutre,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(8),
                            topRight: const Radius.circular(8),
                            bottomLeft: Radius.circular(estMoi ? 8 : 0),
                            bottomRight: Radius.circular(estMoi ? 0 : 8)),
                          boxShadow: msg.type == 'sticker' ? null
                              : [BoxShadow(
                                  color: Colors.black.withValues(alpha:0.07),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1))]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nom expéditeur (messages reçus)
                            if (!estMoi)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(9, 5, 9, 0),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Text(msg.expediteur,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AdminTheme.primary)),
                                  const SizedBox(width: 6),
                                  DelegueBadge(role: msg.etudiantRole, niveau: msg.niveau, compact: true),
                                ])),

                            // ── Citation WhatsApp style ────────────────
                            if (widget.msgCite != null)
                              GestureDetector(
                                onTap: widget.onTapReply,
                                child: Container(
                                  margin: const EdgeInsets.fromLTRB(5, 5, 5, 0),
                                  decoration: BoxDecoration(
                                    color: estMoi
                                        ? const Color(0xFFB2DFB0)
                                        : const Color(0xFFECECEC),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border(
                                      left: BorderSide(
                                        color: _couleurCitation(
                                            widget.msgCite!.expediteur),
                                        width: 4))),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(8, 5, 8, 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(widget.msgCite!.expediteur,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: _couleurCitation(
                                                widget.msgCite!.expediteur))),
                                        const SizedBox(height: 2),
                                        Text(widget.msgCite!.texte,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF54656F)),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      ])))),

                            // Contenu du message
                            Padding(
                              padding: msg.type == 'sticker'
                                  ? EdgeInsets.zero
                                  : const EdgeInsets.fromLTRB(10, 5, 10, 2),
                              child: _contenu()),

                            // Heure + statut + réactions
                            Padding(
                              padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (msg.reactions.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha:0.06),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Text(
                                        msg.reactions.entries
                                            .map((e) =>
                                                '${e.key}${e.value > 1 ? ' ${e.value}' : ''}')
                                            .join(' '),
                                        style: const TextStyle(fontSize: 11))),
                                    const SizedBox(width: 4),
                                  ],
                                  if (msg.important)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 3),
                                      child: Icon(Icons.star_rounded,
                                          size: 11, color: Color(0xFFFFB800))),
                                  if (msg.epingle)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 3),
                                      child: Icon(Icons.push_pin_rounded,
                                          size: 10, color: Color(0xFF8696A0))),
                                  Text(msg.heure, style: const TextStyle(
                                      fontSize: 10, color: Color(0xFF667781))),
                                  if (estMoi) ...[
                                    const SizedBox(width: 3),
                                    Icon(
                                      msg.lu ? Icons.done_all_rounded
                                             : Icons.done_rounded,
                                      size: 13,
                                      color: msg.lu
                                          ? const Color(0xFF53BDEB)
                                          : const Color(0xFF8696A0)),
                                  ],
                                ])),
                          ]))),

                    // Chevron menu (hover, messages reçus)
                    if (!estMoi && _hovered)
                      GestureDetector(onTap: widget.onMenu,
                        child: Container(width: 20, height: 20,
                          margin: const EdgeInsets.only(left: 4, bottom: 6),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.9),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(
                                  color: Colors.black.withValues(alpha:0.15),
                                  blurRadius: 3)]),
                          child: const Icon(Icons.expand_more_rounded,
                              size: 14, color: Color(0xFF54656F))))
                    else if (!estMoi)
                      const SizedBox(width: 24),

                    if (estMoi) const SizedBox(width: 4),
                  ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Couleur de la barre gauche de la citation selon l'expéditeur
  Color _couleurCitation(String expediteur) {
    if (expediteur == 'Admin') return AdminTheme.primary;
    final colors = [
      const Color(0xFF06CF9C), const Color(0xFF1DA1F2),
      const Color(0xFFFF6B35), const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
    ];
    return colors[expediteur.codeUnits.fold(0, (a, b) => a + b) % colors.length];
  }

  // Deux lettres (prénom + nom), comme le veut l'usage — pas juste une.
  String _initialesExpediteur(String nomComplet) {
    final parts = nomComplet.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.length == 1 && parts[0].length >= 2) return parts[0].substring(0, 2).toUpperCase();
    if (parts.length == 1) return parts[0].toUpperCase();
    return '?';
  }

  Widget _contenu() {
    if (msg.type == 'sticker') {
      final estFichierOuUrl = msg.texte.startsWith('http') || msg.texte.contains('/');
      if (!estFichierOuUrl) {
        return Text(msg.texte, style: const TextStyle(fontSize: 52));
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: msg.texte.startsWith('http')
            ? Image.network(msg.texte, width: 130, height: 130, fit: BoxFit.cover)
            : Image.file(File(msg.texte), width: 130, height: 130, fit: BoxFit.cover),
      );
    }
    if (msg.type == 'image' && msg.texte.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          msg.texte, width: 200, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 200, height: 140, color: const Color(0xFFCCD0D5),
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined, color: Color(0xFF8696A0)),
          ),
        ),
      );
    }
    if (msg.type == 'document' || msg.type == 'image') {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 34, height: 34,
          decoration: BoxDecoration(
              color: const Color(0xFF7F66FF).withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(
            msg.type == 'image'
                ? Icons.photo_rounded : Icons.insert_drive_file_rounded,
            size: 18, color: const Color(0xFF7F66FF))),
        const SizedBox(width: 8),
        Flexible(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(msg.texte, style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w600, color: Color(0xFF111B21)),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          Text(msg.type == 'image' ? 'Image' : 'Document',
              style: const TextStyle(fontSize: 11, color: Color(0xFF8696A0))),
        ])),
        const Icon(Icons.download_rounded, size: 16, color: Color(0xFF8696A0)),
      ]);
    }
    if (msg.texte.startsWith('[GIF]')) {
      final url = msg.texte.substring(5);
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url, width: 160, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Text('[GIF]', style: TextStyle(fontSize: 13, color: Color(0xFF8696A0))),
        ),
      );
    }
    if (msg.texte.startsWith('[FICHIER]')) {
      final parts = msg.texte.substring(9).split('|');
      final fType = parts.isNotEmpty ? parts[0] : 'document';
      final url = parts.length > 1 ? parts[1] : '';
      final nom = parts.length > 2 ? parts.sublist(2).join('|') : 'Fichier';
      if (fType == 'image') {
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              opaque: false,
              barrierColor: Colors.black,
              pageBuilder: (_, __, ___) => _VisionneuseImage(url: url),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 300,
              height: 155,
              child: Image.network(
                url, fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(color: const Color(0xFFE9EDF0), alignment: Alignment.center,
                        child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFCCD0D5),
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, color: Color(0xFF8696A0)),
                ),
              ),
            ),
          ),
        );
      }
      if (fType == 'vocal') {
        return VoiceMessagePlayer(
          url: url, dureeLabel: nom,
          couleur: AdminTheme.primary,
          texteColor: msg.estMoi ? widget.theme.texteMoi : widget.theme.texteAutre,
        );
      }
      final icone = fType == 'video'
          ? Icons.videocam_rounded
          : fType == 'audio'
              ? Icons.audiotrack_rounded
              : Icons.insert_drive_file_rounded;
      final couleur = fType == 'video'
          ? const Color(0xFFDC3545)
          : fType == 'audio'
              ? const Color(0xFFFF6B35)
              : const Color(0xFF7F66FF);
      return GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Téléchargement non disponible pour l\'instant.'))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 34, height: 34,
            decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icone, size: 18, color: couleur)),
          const SizedBox(width: 8),
          Flexible(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nom, style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600, color: Color(0xFF111B21)),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            Text(fType == 'video' ? 'Vidéo' : fType == 'audio' ? 'Audio' : 'Document',
                style: const TextStyle(fontSize: 11, color: Color(0xFF8696A0))),
          ])),
          const SizedBox(width: 6),
          const Icon(Icons.download_rounded, size: 16, color: Color(0xFF8696A0)),
        ]),
      );
    }
    if (msg.texte.startsWith('[SONDAGE]')) {
      final sondageId = msg.texte.substring(9);
      return SizedBox(width: 240, child: _SondageWidget(sondageId: sondageId));
    }
    return Text(msg.texte, style: TextStyle(
        fontSize: 14, color: msg.estMoi ? widget.theme.texteMoi : widget.theme.texteAutre, height: 1.4));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// EXTENSIONS
// ════════════════════════════════════════════════════════════════════════════
extension GroupeAdminExtension on GroupeAdmin {
  bool get isPrive    => type == 'prive';
  bool get isFiliere  => type == 'admin_filiere' || type == 'prof_delegues';
  bool get isProfs    => type == 'admin_profs';
  bool get isDelegues => type == 'admin_delegues';
  int  get totalMessages => messages.length;
}

// ════════════════════════════════════════════════════════════════════════════
// WIDGET — Point rouge clignotant (enregistrement)
// ════════════════════════════════════════════════════════════════════════════
class _BlinkingDot extends StatefulWidget {
  final bool paused;
  const _BlinkingDot({required this.paused});
  @override State<_BlinkingDot> createState() => _BlinkingDotState();
}
class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.paused
          ? const AlwaysStoppedAnimation(1.0)
          : _ctrl,
      child: Container(width: 10, height: 10,
        decoration: const BoxDecoration(
            color: Color(0xFFDC2626), shape: BoxShape.circle)));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SÉLECTEUR DE CONTACT pour initier une nouvelle discussion privée
// ════════════════════════════════════════════════════════════════════════════
class _SelecteurContactPage extends StatefulWidget {
  final String titre;
  final String roleFiltre;
  final Color couleur;
  final void Function(String id, String nom, String? sousTitre) onContactChoisi;

  const _SelecteurContactPage({
    required this.titre,
    required this.roleFiltre,
    required this.couleur,
    required this.onContactChoisi,
  });

  @override
  State<_SelecteurContactPage> createState() => _SelecteurContactPageState();
}

class _SelecteurContactPageState extends State<_SelecteurContactPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;
  String? _erreur;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _chargerContacts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerContacts() async {
    setState(() { _loading = true; _erreur = null; });
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/messages/contacts?role=${widget.roleFiltre}'),
        headers: headers,
      );
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        final list = (body is Map ? body['data'] : body) as List? ?? [];
        setState(() {
          _contacts = list.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else if (mounted) {
        setState(() {
          _erreur = 'Impossible de charger les contacts (code ${res.statusCode}).';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _erreur = 'Erreur réseau.'; _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtres {
    if (_query.trim().isEmpty) return _contacts;
    final q = _query.trim().toLowerCase();
    return _contacts.where((c) {
      final nom = '${c['prenoms'] ?? ''} ${c['nom'] ?? ''}'.toLowerCase();
      final extra = (c['specialite'] ?? c['domaine'] ?? c['filiere_nom'] ?? '').toString().toLowerCase();
      final matricule = (c['matricule'] ?? '').toString().toLowerCase();
      return nom.contains(q) || extra.contains(q) || matricule.contains(q);
    }).toList();
  }

  String _initiales(Map<String, dynamic> c) {
    final p = (c['prenoms'] ?? '').toString().trim();
    final n = (c['nom'] ?? '').toString().trim();
    return '${p.isNotEmpty ? p[0] : ''}${n.isNotEmpty ? n[0] : ''}'.toUpperCase().isNotEmpty
        ? '${p.isNotEmpty ? p[0] : ''}${n.isNotEmpty ? n[0] : ''}'.toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    final liste = _filtres;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.titre,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const Text('Appuyez pour ouvrir la discussion',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom ou matricule...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                          onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(_erreur!, textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B))),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _chargerContacts,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Réessayer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.couleur,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ]),
                  ),
                )
              : liste.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.person_search_rounded, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          _query.isNotEmpty ? 'Aucun résultat pour "$_query"' : 'Aucun contact disponible',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                        ),
                      ]),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: liste.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final c = liste[i];
                        final nomComplet = '${c['prenoms'] ?? ''} ${c['nom'] ?? ''}'.trim();
                        final sousTitre = c['specialite'] ?? c['domaine'] ?? c['filiere_nom'] ?? c['matricule'];
                        final id = c['id']?.toString() ?? '';
                        return GestureDetector(
                          onTap: () => widget.onContactChoisi(id, nomComplet, sousTitre?.toString()),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6, offset: const Offset(0, 2),
                              )],
                            ),
                            child: Row(children: [
                              Container(
                                width: 46, height: 46,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [widget.couleur, widget.couleur.withValues(alpha: 0.7)],
                                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Center(
                                  child: Text(_initiales(c),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(
                                    nomComplet.isNotEmpty ? nomComplet : 'Contact',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                  if (sousTitre != null && sousTitre.toString().isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(sousTitre.toString(),
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ]),
                              ),
                              Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                  color: widget.couleur.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.chat_bubble_outline_rounded, color: widget.couleur, size: 17),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
    );
  }
}
// ════════════════════════════════════════════════════════════════════════
// CRÉATION D'UN SONDAGE — entièrement configurable par le créateur :
// choix unique/multiple, anonyme ou non, avec ou sans date de clôture.
// ════════════════════════════════════════════════════════════════════════
class _CreationSondageSheet extends StatefulWidget {
  const _CreationSondageSheet();

  @override
  State<_CreationSondageSheet> createState() => _CreationSondageSheetState();
}

class _CreationSondageSheetState extends State<_CreationSondageSheet> {
  final _questionCtrl = TextEditingController();
  final List<TextEditingController> _optionsCtrl = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _choixMultiple = false;
  bool _anonyme = false;
  DateTime? _dateCloture;
  bool _envoi = false;

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _optionsCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  void _ajouterOption() {
    if (_optionsCtrl.length >= 12) return;
    setState(() => _optionsCtrl.add(TextEditingController()));
  }

  void _retirerOption(int i) {
    if (_optionsCtrl.length <= 2) return;
    setState(() => _optionsCtrl.removeAt(i).dispose());
  }

  Future<void> _choisirDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final heure = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
    if (!mounted) return;
    setState(() => _dateCloture = DateTime(date.year, date.month, date.day, heure?.hour ?? 18, heure?.minute ?? 0));
  }

  Future<void> _valider() async {
    final question = _questionCtrl.text.trim();
    final options = _optionsCtrl.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ La question est requise.'), backgroundColor: Colors.redAccent));
      return;
    }
    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Au moins 2 options sont requises.'), backgroundColor: Colors.redAccent));
      return;
    }
    setState(() => _envoi = true);
    final result = await ApiService.creerSondage(
      question: question,
      options: options,
      choixMultiple: _choixMultiple,
      anonyme: _anonyme,
      dateCloture: _dateCloture,
    );
    if (!mounted) return;
    setState(() => _envoi = false);
    if (result['success'] == true) {
      Navigator.pop(context, result['id'].toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']?.toString() ?? 'Erreur.'), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
            ),
            const Row(children: [
              Icon(Icons.poll_outlined, color: Color(0xFF0D6EFD)),
              SizedBox(width: 8),
              Text('Créer un sondage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: [
                  TextField(
                    controller: _questionCtrl,
                    decoration: InputDecoration(
                      labelText: 'Question',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Options', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  ...List.generate(_optionsCtrl.length, (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          Expanded(
                            child: TextField(
                              controller: _optionsCtrl[i],
                              decoration: InputDecoration(
                                hintText: 'Option ${i + 1}',
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          if (_optionsCtrl.length > 2)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 20),
                              onPressed: () => _retirerOption(i),
                            ),
                        ]),
                      )),
                  if (_optionsCtrl.length < 12)
                    TextButton.icon(
                      onPressed: _ajouterOption,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Ajouter une option'),
                    ),
                  const Divider(height: 28),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Choix multiple', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Autoriser plusieurs réponses par personne', style: TextStyle(fontSize: 11.5)),
                    value: _choixMultiple,
                    onChanged: (v) => setState(() => _choixMultiple = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sondage anonyme', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Personne ne verra qui a voté quoi, seuls les totaux', style: TextStyle(fontSize: 11.5)),
                    value: _anonyme,
                    onChanged: (v) => setState(() => _anonyme = v),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date de clôture (optionnel)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _dateCloture != null
                          ? '${_dateCloture!.day}/${_dateCloture!.month}/${_dateCloture!.year} à ${_dateCloture!.hour.toString().padLeft(2, '0')}:${_dateCloture!.minute.toString().padLeft(2, '0')}'
                          : 'Aucune — le sondage reste ouvert jusqu\'à clôture manuelle',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    trailing: _dateCloture != null
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => setState(() => _dateCloture = null),
                          )
                        : const Icon(Icons.calendar_today_outlined, size: 18),
                    onTap: _choisirDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _envoi ? null : _valider,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD), padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _envoi
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Envoyer le sondage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// AFFICHAGE + VOTE — rendu dans une bulle de message
// ════════════════════════════════════════════════════════════════════════
class _SondageWidget extends StatefulWidget {
  const _SondageWidget({required this.sondageId});
  final String sondageId;

  @override
  State<_SondageWidget> createState() => _SondageWidgetState();
}

class _SondageWidgetState extends State<_SondageWidget> {
  bool _loading = true;
  String? _erreur;
  Map<String, dynamic>? _sondage;
  final Set<String> _selection = {};
  bool _vote = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _erreur = null; });
    final result = await ApiService.getSondage(widget.sondageId);
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        _sondage = result['data'] as Map<String, dynamic>;
        _selection
          ..clear()
          ..addAll((_sondage!['mes_votes'] as List<dynamic>).map((e) => e.toString()));
      } else {
        _erreur = result['error']?.toString() ?? 'Sondage introuvable.';
      }
      _loading = false;
    });
  }

  Future<void> _voter() async {
    if (_selection.isEmpty) return;
    setState(() => _vote = true);
    final result = await ApiService.voterSondage(widget.sondageId, _selection.toList());
    if (!mounted) return;
    setState(() => _vote = false);
    if (result['success'] == true) {
      await _charger();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']?.toString() ?? 'Erreur lors du vote.')));
    }
  }

  Future<void> _cloturer() async {
    final result = await ApiService.cloturerSondage(widget.sondageId);
    if (!mounted) return;
    if (result['success'] == true) {
      await _charger();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']?.toString() ?? 'Erreur.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_erreur != null || _sondage == null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(_erreur ?? 'Sondage introuvable.', style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
      );
    }
    final s = _sondage!;
    final options = s['options'] as List<dynamic>;
    final totalVotants = (s['total_votants'] as num?)?.toInt() ?? 0;
    final cloture = s['cloture'] == true;
    final choixMultiple = s['choix_multiple'] == true;
    final anonyme = s['anonyme'] == true;
    final estCreateur = s['est_createur'] == true;
    final dejaVote = (s['mes_votes'] as List).isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.poll_outlined, size: 16, color: Color(0xFF0D6EFD)),
            const SizedBox(width: 6),
            Expanded(child: Text(s['question']?.toString() ?? '',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF111B21)))),
          ]),
          const SizedBox(height: 2),
          Text(
            [
              choixMultiple ? 'Choix multiple' : 'Choix unique',
              anonyme ? 'Anonyme' : null,
              cloture ? 'Clôturé' : null,
            ].whereType<String>().join(' · '),
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF8696A0)),
          ),
          const SizedBox(height: 10),
          ...options.map((o) {
            final id = o['id'].toString();
            final texte = o['texte']?.toString() ?? '';
            final nbVotes = (o['nb_votes'] as num?)?.toInt() ?? 0;
            final pourcentage = totalVotants > 0 ? nbVotes / totalVotants : 0.0;
            final selectionne = _selection.contains(id);
            final peutVoter = !cloture;

            return GestureDetector(
              onTap: !peutVoter ? null : () {
                setState(() {
                  if (choixMultiple) {
                    if (selectionne) {
                      _selection.remove(id);
                    } else {
                      _selection.add(id);
                    }
                  } else {
                    _selection
                      ..clear()
                      ..add(id);
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selectionne ? const Color(0xFF0D6EFD) : Colors.transparent, width: 1.5),
                ),
                child: Stack(children: [
                  if (dejaVote || cloture)
                    Positioned.fill(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: pourcentage.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D6EFD).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  Row(children: [
                    if (peutVoter)
                      Icon(
                        selectionne
                            ? (choixMultiple ? Icons.check_box_rounded : Icons.radio_button_checked_rounded)
                            : (choixMultiple ? Icons.check_box_outline_blank_rounded : Icons.radio_button_unchecked_rounded),
                        size: 18,
                        color: selectionne ? const Color(0xFF0D6EFD) : const Color(0xFF94A3B8),
                      ),
                    if (peutVoter) const SizedBox(width: 8),
                    Expanded(child: Text(texte, style: const TextStyle(fontSize: 13, color: Color(0xFF111B21)))),
                    if (dejaVote || cloture)
                      Text('${(pourcentage * 100).round()}%',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0D6EFD))),
                  ]),
                ]),
              ),
            );
          }),
          const SizedBox(height: 4),
          Row(children: [
            Text('$totalVotants vote(s)', style: const TextStyle(fontSize: 10.5, color: Color(0xFF8696A0))),
            const Spacer(),
            if (!cloture && !dejaVote)
              TextButton(
                onPressed: _vote || _selection.isEmpty ? null : _voter,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), minimumSize: Size.zero),
                child: _vote
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Voter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            if (estCreateur && !cloture)
              TextButton(
                onPressed: _cloturer,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), minimumSize: Size.zero),
                child: const Text('Clôturer', style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w700)),
              ),
          ]),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// VISIONNEUSE PLEIN ÉCRAN — image agrandie, zoom au pincement, fermeture
// par le bouton ou en balayant vers le bas.
// ════════════════════════════════════════════════════════════════════════
class _VisionneuseImage extends StatelessWidget {
  const _VisionneuseImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 200) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// INFOS DU MESSAGE — qui a vu ce message, et à quelle heure.
// ════════════════════════════════════════════════════════════════════════
class _InfosMessageSheet extends StatefulWidget {
  const _InfosMessageSheet({required this.type, required this.messageId, required this.heureEnvoi});
  final String type;
  final String messageId;
  final String heureEnvoi;

  @override
  State<_InfosMessageSheet> createState() => _InfosMessageSheetState();
}

class _InfosMessageSheetState extends State<_InfosMessageSheet> {
  bool _loading = true;
  String? _erreur;
  List<dynamic> _lecteurs = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _erreur = null; });
    final result = await ApiService.getLecteursMessage(widget.type, widget.messageId);
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        _lecteurs = result['data'] as List<dynamic>;
      } else {
        _erreur = result['error']?.toString() ?? 'Erreur lors du chargement.';
      }
      _loading = false;
    });
  }

  String _formatHeure(dynamic iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso.toString())?.toLocal();
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
          child: Row(children: [
            const Icon(Icons.visibility_outlined, size: 18, color: AdminTheme.primary),
            const SizedBox(width: 8),
            Text('Vu par (${_lecteurs.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('Envoyé à ${widget.heureEnvoi}', style: const TextStyle(fontSize: 11, color: Color(0xFF8696A0))),
          ]),
        ),
        const Divider(height: 1),
        Flexible(
          child: _loading
              ? const Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())
              : _erreur != null
                  ? Padding(padding: const EdgeInsets.all(20), child: Text(_erreur!, style: const TextStyle(color: Colors.redAccent)))
                  : _lecteurs.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Personne n\'a encore vu ce message.', style: TextStyle(fontSize: 13, color: Color(0xFF8696A0))),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: _lecteurs.length,
                          itemBuilder: (_, i) {
                            final l = _lecteurs[i] as Map<String, dynamic>;
                            final nom = '${l['prenoms'] ?? ''} ${l['nom'] ?? ''}'.trim();
                            final photo = l['photo_url']?.toString();
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: AdminTheme.primaryLight,
                                backgroundImage: (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
                                child: (photo == null || photo.isEmpty)
                                    ? Text(nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.primary))
                                    : null,
                              ),
                              title: Text(nom.isNotEmpty ? nom : 'Utilisateur', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                              trailing: Text(_formatHeure(l['lu_at']), style: const TextStyle(fontSize: 11.5, color: Color(0xFF8696A0))),
                            );
                          },
                        ),
        ),
        SizedBox(height: 8 + MediaQuery.of(context).padding.bottom),
      ]),
    );
  }
}
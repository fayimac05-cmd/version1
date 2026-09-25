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
import '../theme/app_palette.dart';
import '../widgets/delegue_badge.dart';
import 'chat_theme.dart';
import 'chat_theme_picker_sheet.dart';
import 'emoji_gif_sticker_picker.dart';
import 'message_extras.dart';
import 'voice_message.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES
// ════════════════════════════════════════════════════════════════════════════
enum TypeMessage { texte, photo, video, document, vocal }

class _Membre {
  final String nom;
  final String prenoms;
  final String matricule;
  final String? etudiantRole;
  final String? niveau;
  final String? photoUrl;

  const _Membre({
    required this.nom,
    required this.prenoms,
    required this.matricule,
    this.etudiantRole,
    this.niveau,
    this.photoUrl,
  });

  String get initiales =>
      '${prenoms.isNotEmpty ? prenoms[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'
          .toUpperCase();

  String get nomComplet => '$prenoms $nom';
}

class _MessageGroupe {
  final String id;
  final _Membre auteur;
  final String contenu;
  final TypeMessage type;
  final DateTime heure;
  final Map<String, String> reactions; // emoji → matricule
  final bool estMoi;
  bool epingle;
  bool important;
  final String? idMessageRepondu;
  final String? texteRepondu;
  final String? expediteurRepondu;

  _MessageGroupe({
    required this.id,
    required this.auteur,
    required this.contenu,
    required this.type,
    required this.heure,
    required this.reactions,
    required this.estMoi,
    this.epingle = false,
    this.important = false,
    this.idMessageRepondu,
    this.texteRepondu,
    this.expediteurRepondu,
  });

  _MessageGroupe copyWith({Map<String, String>? reactions}) => _MessageGroupe(
    id: id,
    auteur: auteur,
    contenu: contenu,
    type: type,
    heure: heure,
    reactions: reactions ?? this.reactions,
    estMoi: estMoi,
    epingle: epingle,
    important: important,
    idMessageRepondu: idMessageRepondu,
    texteRepondu: texteRepondu,
    expediteurRepondu: expediteurRepondu,
  );
}

// ════════════════════════════════════════════════════════════════════════════
// PAGE MESSAGERIE GROUPE
// ════════════════════════════════════════════════════════════════════════════
class GroupeFiliere extends StatefulWidget {
  final StudentProfile profile;
  const GroupeFiliere({super.key, required this.profile});

  @override
  State<GroupeFiliere> createState() => _GroupeFiliereState();
}

class _GroupeFiliereState extends State<GroupeFiliere> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _enregistrement = false;
  final _voiceRecorder = VoiceRecorderController();
  bool _modeSelection = false;
  final Set<String> _selectionnes = {};
  int _dureeEnregistrement = 0;
  Timer? _recordTimer;

  // ── Membres réels de la filière (chargés depuis le backend) ──────────
  List<_Membre> _membres = [];
  bool _chargementInitial = true;
  String _themeId = ChatThemes.classique.id;
  bool _panneauOuvert = false;
  String? _hoveredMsgId;
  _MessageGroupe? _messageEnReponse;

  late List<_MessageGroupe> _messages;

  // Id de la filière côté backend (récupéré via /auth/me) ; null si hors ligne
  // → dans ce cas l'écran reste en mode démo locale.
  int? _filiereId;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _messages = [];
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollBasInitial());
    _chargerTheme();
    _init();
  }

  Future<void> _init() async {
    _myUserId = await ApiService.getUserId();
    try {
      final headers = await ApiService.getHeaders();
      final me = await http.get(
          Uri.parse('${ApiService.baseUrl}/auth/me'), headers: headers);
      if (me.statusCode != 200) {
        setState(() => _chargementInitial = false);
        return;
      }
      final filiereId = jsonDecode(me.body)['filiere_id'];
      if (filiereId == null) {
        setState(() => _chargementInitial = false);
        return;
      }
      _filiereId = filiereId is int ? filiereId : int.tryParse('$filiereId');
      if (_filiereId == null) {
        setState(() => _chargementInitial = false);
        return;
      }
      _chargerTheme();

      await Future.wait([_chargerMessages(), _chargerMembres()]);
      // Ouvrir l'écran vaut lecture : réinitialise le compteur non-lu.
      ApiService.marquerGroupeLu(_filiereId.toString());
      await _connecterSocket();
    } catch (_) {
      // Serveur injoignable.
    } finally {
      if (mounted) setState(() => _chargementInitial = false);
    }
  }

  Future<void> _chargerMembres() async {
    if (_filiereId == null) return;
    final result = await ApiService.getMembresGroupe(_filiereId.toString());
    if (!mounted || result['success'] != true) return;
    final data = result['data'] as List<dynamic>;
    setState(() {
      _membres = data.map((m) => _Membre(
            nom: m['nom']?.toString() ?? '',
            prenoms: m['prenoms']?.toString() ?? '',
            matricule: m['matricule']?.toString() ?? '',
            etudiantRole: m['etudiant_role']?.toString(),
            niveau: m['niveau']?.toString(),
            photoUrl: m['photo_url']?.toString(),
          )).toList();
    });
  }

  Future<void> _chargerMessages() async {
    final headers = await ApiService.getHeaders();
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/messages/groupe/$_filiereId'),
      headers: headers,
    );
    if (response.statusCode != 200 || !mounted) return;
    final data = jsonDecode(utf8.decode(response.bodyBytes))['data'] as List? ?? [];
    setState(() {
      _messages = data
          .map((m) => _messageDepuisJson(m as Map<String, dynamic>))
          .toList();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollBasInitial());
    // Marque comme lus tous les messages reçus (pas les miens) — ouvrir la
    // discussion vaut consultation, comme WhatsApp.
    for (final m in _messages) {
      if (!m.estMoi) ApiService.marquerMessageLu('groupe', m.id);
    }
  }

  Future<void> _connecterSocket() async {
    await SocketService().connect();
    if (_filiereId != null) {
      SocketService().joinRoom('filiere:$_filiereId');
    }
    SocketService().onGroupeMessage((data) {
      if (!mounted) return;
      final json = data is Map<String, dynamic>
          ? data
          : jsonDecode(data.toString()) as Map<String, dynamic>;
      if (json['filiere_id']?.toString() != _filiereId?.toString()) return;
      // Mes propres messages sont déjà affichés à l'envoi
      if (_myUserId != null && json['auteur_id']?.toString() == _myUserId) return;
      setState(() => _messages.add(_messageDepuisJson(json)));
      Future.delayed(const Duration(milliseconds: 100), _scrollBas);
    });
  }

  /// Convertit le tableau d'emojis renvoyé par le backend en un set de clés
  /// (le modèle local ne garde qu'un "qui a réagi en dernier" par emoji —
  /// on se contente ici de marquer quels emojis sont présents).
  Map<String, String> _reactionsDepuisJson(dynamic raw) {
    final map = <String, String>{};
    if (raw is List) {
      for (final e in raw) {
        final emoji = e?.toString();
        if (emoji != null && emoji.isNotEmpty) map[emoji] = 'srv';
      }
    }
    return map;
  }

  _MessageGroupe _messageDepuisJson(Map<String, dynamic> json) {
    final estMoi = _myUserId != null &&
        json['auteur_id']?.toString() == _myUserId;
    return _MessageGroupe(
      id: json['id'].toString(),
      auteur: estMoi
          ? _moi
          : _Membre(
              nom: (json['nom'] ?? '') as String,
              prenoms: (json['prenoms'] ?? '') as String,
              matricule: json['auteur_id']?.toString() ?? '',
              etudiantRole: json['etudiant_role']?.toString(),
              niveau: json['niveau']?.toString(),
              photoUrl: (json['photo_url'] ?? json['photoUrl'])?.toString(),
            ),
      contenu: (json['contenu'] ?? '') as String,
      type: TypeMessage.texte,
      heure: (DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now())
          .toLocal(),
      reactions: _reactionsDepuisJson(json['reactions']),
      estMoi: estMoi,
    );
  }

  @override
  void dispose() {
    SocketService().off('message:groupe');
    _recordTimer?.cancel();
    _voiceRecorder.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  _Membre get _moi => _Membre(
    nom: widget.profile.nom,
    prenoms: widget.profile.prenoms,
    matricule: widget.profile.matricule,
    etudiantRole: widget.profile.role,
    niveau: widget.profile.niveau,
    photoUrl: widget.profile.photoUrl,
  );

  DateTime _heure(int minutesAvant) =>
      DateTime.now().subtract(Duration(minutes: -minutesAvant.abs()));

  void _scrollBas() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Scroll tout en bas à l'ouverture du groupe — en plusieurs passes, car
  /// les avatars/images des messages finissent de charger après le premier
  /// affichage et modifient la hauteur réelle du contenu (sinon on atterrit
  /// un peu trop haut et il faut descendre manuellement).
  void _scrollBasInitial() {
    void jump() {
      if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    }
    jump();
    Future.delayed(const Duration(milliseconds: 250), jump);
    Future.delayed(const Duration(milliseconds: 600), jump);
  }

  // ── Envoyer message texte ─────────────────────────────────────────────
  Future<void> _envoyerTexte() async {
    final texte = _inputCtrl.text.trim();
    if (texte.isEmpty) return;
    _inputCtrl.clear();
    final rep = _messageEnReponse;
    final msgLocal = _MessageGroupe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      auteur: _moi,
      contenu: texte,
      type: TypeMessage.texte,
      heure: DateTime.now(),
      reactions: {},
      estMoi: true,
      idMessageRepondu: rep?.id,
      texteRepondu: rep?.contenu,
      expediteurRepondu: rep?.auteur.nomComplet,
    );
    setState(() { _messages.add(msgLocal); _messageEnReponse = null; });
    Future.delayed(const Duration(milliseconds: 100), _scrollBas);

    if (_filiereId == null) return; // mode démo locale

    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/messages/groupe/$_filiereId'),
        headers: headers,
        body: jsonEncode({'contenu': texte}),
      );
      if (response.statusCode != 201 && mounted) {
        setState(() => _messages.remove(msgLocal));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Échec de l\'envoi du message')));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _messages.remove(msgLocal));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Serveur injoignable — message non envoyé')));
    }
  }

  // ── Enregistrement vocal réel — barre complète (annuler/pause/envoyer) ─
  Future<void> _demarrerEnregistrement() async {
    final ok = await _voiceRecorder.start();
    if (!ok) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Permission microphone refusée. Autorise le micro dans les réglages.')));
      return;
    }
    setState(() { _enregistrement = true; _dureeEnregistrement = 0; });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_voiceRecorder.isPaused && mounted) setState(() => _dureeEnregistrement++);
    });
  }

  Future<void> _pauseOuReprendreEnregistrement() async {
    await _voiceRecorder.pauseOuReprendre();
    setState(() {});
  }

  Future<void> _annulerEnregistrement() async {
    _recordTimer?.cancel();
    await _voiceRecorder.annuler();
    setState(() { _enregistrement = false; _dureeEnregistrement = 0; });
  }

  String _fmtDureeVocal(int s) => VoiceRecordingBar.fmtDuree(s);

  Future<void> _arreterEtEnvoyerEnregistrement() async {
    _recordTimer?.cancel();
    final duree = _fmtDureeVocal(_dureeEnregistrement);
    setState(() { _enregistrement = false; _dureeEnregistrement = 0; });

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
    setState(() {
      _messages.add(_MessageGroupe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        auteur: _moi, contenu: contenu, type: TypeMessage.texte,
        heure: DateTime.now(), reactions: {}, estMoi: true,
      ));
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollBas);
    if (_filiereId == null) return;
    try {
      final headers = await ApiService.getHeaders();
      await http.post(
        Uri.parse('${ApiService.baseUrl}/messages/groupe/$_filiereId'),
        headers: headers,
        body: jsonEncode({'contenu': contenu}),
      );
    } catch (_) {}
  }

  // ── Envoi réel d'un GIF (URL publique GIPHY — visible par tout le monde,
  // pas besoin d'upload puisque l'URL est déjà publique) ──────────────────
  Future<void> _envoyerGif(String url) async {
    setState(() => _panneauOuvert = false);
    final contenu = '[GIF]$url';
    final msgLocal = _MessageGroupe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      auteur: _moi,
      contenu: contenu,
      type: TypeMessage.texte,
      heure: DateTime.now(),
      reactions: {},
      estMoi: true,
    );
    setState(() => _messages.add(msgLocal));
    Future.delayed(const Duration(milliseconds: 100), _scrollBas);
    if (_filiereId == null) return;
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/messages/groupe/$_filiereId'),
        headers: headers,
        body: jsonEncode({'contenu': contenu}),
      );
      if (response.statusCode != 201 && mounted) {
        setState(() => _messages.remove(msgLocal));
      }
    } catch (_) {
      if (mounted) setState(() => _messages.remove(msgLocal));
    }
  }

  // ── Sticker : fichier local à l'appareil, pas d'upload disponible pour
  // l'instant → écho visible seulement pour vous, comme les autres pièces
  // jointes simulées de cet écran (photo/vidéo/document/vocal). ───────────
  void _envoyerSticker(String chemin) {
    setState(() {
      _panneauOuvert = false;
      _messages.add(
        _MessageGroupe(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          auteur: _moi,
          contenu: '[STICKER]$chemin',
          type: TypeMessage.texte,
          heure: DateTime.now(),
          reactions: {},
          estMoi: true,
        ),
      );
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollBas);
  }

  // ── Envoi réel d'un fichier (document/photo/vidéo/audio) ─────────────
  Future<void> _envoyerFichier(String categorie) async {
    Navigator.of(context).pop();
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
    final upload = await ApiService.uploaderFichierMessage(bytes, nom);
    if (!mounted) return;
    if (upload['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(upload['error']?.toString() ?? 'Échec de l\'envoi du fichier.')));
      return;
    }
    final url = upload['url'].toString();
    final contenu = '[FICHIER]$type|$url|$nom';
    setState(() {
      _messages.add(_MessageGroupe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        auteur: _moi, contenu: contenu, type: TypeMessage.texte,
        heure: DateTime.now(), reactions: {}, estMoi: true,
      ));
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollBas);
    if (_filiereId == null) return;
    try {
      final headers = await ApiService.getHeaders();
      await http.post(
        Uri.parse('${ApiService.baseUrl}/messages/groupe/$_filiereId'),
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
    final contenu = '[SONDAGE]$sondageId';
    setState(() {
      _messages.add(_MessageGroupe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        auteur: _moi, contenu: contenu, type: TypeMessage.texte,
        heure: DateTime.now(), reactions: {}, estMoi: true,
      ));
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollBas);
    if (_filiereId == null) return;
    try {
      final headers = await ApiService.getHeaders();
      await http.post(
        Uri.parse('${ApiService.baseUrl}/messages/groupe/$_filiereId'),
        headers: headers,
        body: jsonEncode({'contenu': contenu}),
      );
    } catch (_) {}
  }

  // ── Réaction emoji ────────────────────────────────────────────────────
  Widget _banniereEpingleGroupe() {
    final epingles = _messages.where((m) => m.epingle).toList();
    if (epingles.isEmpty) return const SizedBox.shrink();
    final dernier = epingles.last;
    return Container(
      color: const Color(0xFFF0F2F5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(children: [
        const Icon(Icons.push_pin_rounded, color: AppPalette.blue, size: 15),
        const SizedBox(width: 10),
        if (epingles.length > 1)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: AppPalette.blue, borderRadius: BorderRadius.circular(8)),
            child: Text('${epingles.length}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(dernier.auteur.nomComplet, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppPalette.blue)),
            Text(dernier.contenu, style: const TextStyle(fontSize: 12, color: Color(0xFF54656F)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        GestureDetector(
          onTap: () => setState(() => dernier.epingle = false),
          child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF8696A0))),
        ),
      ]),
    );
  }

  void _repondreA(_MessageGroupe msg) {
    setState(() => _messageEnReponse = msg);
  }

  Future<void> _transferer(_MessageGroupe msg) async {
    final contenu = 'Transféré : ${msg.contenu}';
    setState(() {
      _messages.add(_MessageGroupe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        auteur: _moi, contenu: contenu, type: TypeMessage.texte,
        heure: DateTime.now(), reactions: {}, estMoi: true,
      ));
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollBas);
    if (_filiereId == null) return;
    try {
      final headers = await ApiService.getHeaders();
      await http.post(
        Uri.parse('${ApiService.baseUrl}/messages/groupe/$_filiereId'),
        headers: headers,
        body: jsonEncode({'contenu': contenu}),
      );
    } catch (_) {}
  }

  Widget _barreSelection() {
    return Container(
      color: AppPalette.blue,
      padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 8, 8, 8),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => setState(() { _modeSelection = false; _selectionnes.clear(); }),
        ),
        Expanded(
          child: Text('${_selectionnes.length} sélectionné${_selectionnes.length > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          onPressed: _selectionnes.isEmpty ? null : _supprimerSelection,
        ),
      ]),
    );
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

  Future<void> _supprimerSelection() async {
    final idsSelectionnes = _selectionnes.toList();
    final tousMoi = idsSelectionnes.every((id) {
      for (final m in _messages) {
        if (m.id == id) return m.estMoi;
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
      _messages.removeWhere((m) => idsSelectionnes.contains(m.id));
      _modeSelection = false;
      _selectionnes.clear();
    });

    final headers = await ApiService.getHeaders();
    for (final id in idsSelectionnes) {
      final idNumerique = int.tryParse(id);
      if (idNumerique == null) continue; // message pas encore confirmé par le serveur
      try {
        if (choix == 'tous') {
          await http.delete(Uri.parse('${ApiService.baseUrl}/messages/groupe/$idNumerique'), headers: headers);
        } else {
          await http.post(Uri.parse('${ApiService.baseUrl}/messages/groupe/$idNumerique/masquer'), headers: headers);
        }
      } catch (_) {}
    }
  }

  void _reagir(String msgId) {
    final msg = _messages.firstWhere((m) => m.id == msgId, orElse: () => _messages.first);
    const emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    void ajouterReaction(String e) {
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == msgId);
        if (idx != -1) {
          final newR = Map<String, String>.from(_messages[idx].reactions);
          newR[e] = widget.profile.matricule;
          _messages[idx] = _messages[idx].copyWith(reactions: newR);
        }
      });
      // Envoi au serveur pour que la réaction survive à un rafraîchissement
      // — les messages pas encore confirmés par le serveur (id temporaire
      // non numérique) restent en local seulement.
      final idNumerique = int.tryParse(msgId);
      if (idNumerique == null || _filiereId == null) return;
      () async {
        try {
          final headers = await ApiService.getHeaders();
          await http.post(
            Uri.parse('${ApiService.baseUrl}/messages/$idNumerique/reaction'),
            headers: headers,
            body: jsonEncode({'emoji': e, 'type': 'groupe', 'filiereId': _filiereId}),
          );
        } catch (_) {}
      }();
    }

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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 6),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 8),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  ...emojis.map((e) => GestureDetector(
                        onTap: () { Navigator.of(context).pop(); ajouterReaction(e); },
                        child: Container(width: 32, height: 32, alignment: Alignment.center,
                            child: Text(e, style: const TextStyle(fontSize: 20))),
                      )),
                  GestureDetector(
                    onTap: () async {
                      Navigator.of(context).pop();
                      final emoji = await showModalBottomSheet<String>(
                        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                        builder: (_) => EmojiGifStickerPicker(
                          emojiOnly: true,
                          onEmoji: (e) => Navigator.pop(context, e),
                          onEnvoiDirect: (_, __) {},
                        ),
                      );
                      if (emoji != null) ajouterReaction(emoji);
                    },
                    child: Container(width: 32, height: 32,
                      decoration: const BoxDecoration(color: Color(0xFFF5F7FA), shape: BoxShape.circle),
                      child: const Icon(Icons.add_rounded, color: Color(0xFF54656F), size: 17)),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              if (msg.estMoi)
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B)),
                  title: const Text('Infos du message', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.of(context).pop();
                    showModalBottomSheet(
                      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                      builder: (_) => InfosMessageSheet(type: 'groupe', messageId: msg.id, heureEnvoi: _formatHeure(msg.heure)),
                    );
                  }),
              ListTile(
                leading: const Icon(Icons.reply_rounded, color: Color(0xFF64748B)),
                title: const Text('Répondre', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () { Navigator.of(context).pop(); _repondreA(msg); }),
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Color(0xFF64748B)),
                title: const Text('Copier', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.of(context).pop();
                  Clipboard.setData(ClipboardData(text: msg.contenu));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Texte copié !')));
                }),
              ListTile(
                leading: const Icon(Icons.forward_rounded, color: Color(0xFF64748B)),
                title: const Text('Transférer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () { Navigator.of(context).pop(); _transferer(msg); }),
              ListTile(
                leading: Icon(msg.epingle ? Icons.push_pin_outlined : Icons.push_pin_rounded, color: AppPalette.blue),
                title: Text(msg.epingle ? 'Désépingler' : 'Épingler', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => msg.epingle = !msg.epingle);
                }),
              ListTile(
                leading: Icon(msg.important ? Icons.star_rounded : Icons.star_outline_rounded, color: const Color(0xFF64748B)),
                title: Text(msg.important ? 'Retirer des importants' : 'Marquer comme important', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () { Navigator.of(context).pop(); setState(() => msg.important = !msg.important); }),
              ListTile(
                leading: const Icon(Icons.check_box_outlined, color: Color(0xFF64748B)),
                title: const Text('Sélectionner', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.of(context).pop();
                  _demarrerSelection(msg.id);
                }),
              ListTile(
                leading: const Icon(Icons.save_alt_rounded, color: Color(0xFF64748B)),
                title: const Text('Enregistrer sous', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enregistrement...')));
                }),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: Color(0xFF64748B)),
                title: const Text('Partager', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partage...')));
                }),
              if (msg.estMoi)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                  title: const Text('Supprimer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFDC2626))),
                  onTap: () async {
                    Navigator.of(context).pop();
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
                    setState(() => _messages.removeWhere((m) => m.id == msg.id));
                    final idNumerique = int.tryParse(msg.id);
                    if (idNumerique == null) return;
                    try {
                      final headers = await ApiService.getHeaders();
                      await http.delete(Uri.parse('${ApiService.baseUrl}/messages/groupe/$idNumerique'), headers: headers);
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

  // ── Menu pièce jointe ─────────────────────────────────────────────────
  void _menuPieceJointe() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Partager',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _mediaBtn(
                  Icons.photo_library_outlined,
                  'Photo/Vidéo',
                  const Color(0xFF7C3AED),
                  () => _envoyerFichier('media'),
                ),
                _mediaBtn(
                  Icons.camera_alt_outlined,
                  'Caméra',
                  const Color(0xFFDC2626),
                  () => _envoyerFichier('camera'),
                ),
                _mediaBtn(
                  Icons.insert_drive_file_outlined,
                  'Document',
                  AppPalette.blue,
                  () => _envoyerFichier('document'),
                ),
                _mediaBtn(
                  Icons.mic_outlined,
                  'Audio',
                  const Color(0xFF15803D),
                  () => _envoyerFichier('audio'),
                ),
                _mediaBtn(
                  Icons.poll_outlined,
                  'Sondage',
                  const Color(0xFF0D6EFD),
                  () { Navigator.of(context).pop(); _creerSondage(); },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _mediaBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );

  // ── Liste membres ─────────────────────────────────────────────────────
  Future<void> _choisirTheme() async {
    final applique = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChatThemePickerSheet(
        currentThemeId: _themeId,
        conversationId: _filiereId?.toString(),
      ),
    );
    if (applique == true) _chargerTheme();
  }

  Future<void> _chargerTheme() async {
    final id = await ChatThemeService.getThemeFor(_filiereId?.toString());
    if (mounted) setState(() => _themeId = id);
  }

  void _voirMembres() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        margin: const EdgeInsets.only(top: 60),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Membres du groupe (${_membres.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Color(0xFF15803D), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Groupe 100% privé — Visible uniquement par les membres',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                itemCount: _membres.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                itemBuilder: (_, i) {
                  final m = _membres[i];
                  final estMoi = m.matricule == widget.profile.matricule;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppPalette.yellow,
                      backgroundImage: (m.photoUrl != null && m.photoUrl!.isNotEmpty)
                          ? NetworkImage(m.photoUrl!)
                          : null,
                      child: (m.photoUrl == null || m.photoUrl!.isEmpty)
                          ? Text(
                              m.initiales,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppPalette.blue,
                                fontSize: 14,
                              ),
                            )
                          : null,
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            m.nomComplet,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (m.etudiantRole != null && m.etudiantRole!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          DelegueBadge(role: m.etudiantRole, niveau: m.niveau, compact: true),
                        ],
                        if (estMoi) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.lightBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Vous',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppPalette.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: estMoi
                        ? Text(
                            m.matricule,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final filiere = widget.profile.filiere.isNotEmpty
        ? widget.profile.filiere
        : 'Réseaux Informatiques et Télécom';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [
          if (_modeSelection) _barreSelection(),
          // ── Header ────────────────────────────────────────────────────
          if (!_modeSelection)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppPalette.blue, Color(0xFF1565C0)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                // Bouton retour (visible quand la page est ouverte par-dessus une autre)
                if (Navigator.canPop(context))
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                // Avatar groupe
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppPalette.yellow,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.yellow.withValues(alpha:0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: AppPalette.blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        filiere,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF4ADE80),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_membres.length} membres',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  color: Colors.white,
                                  size: 11,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '100% Privé',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Bouton thème de discussion
                GestureDetector(
                  onTap: _choisirTheme,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.palette_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                // Bouton membres
                GestureDetector(
                  onTap: _voirMembres,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.people_outline,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bandeau confidentialité ───────────────────────────────────
          Container(
            color: AppPalette.blue.withValues(alpha:0.07),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: AppPalette.blue,
                  size: 15,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Messages visibles uniquement par les étudiants de cette filière',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppPalette.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _banniereEpingleGroupe(),

          // ── Messages ──────────────────────────────────────────────────
          Expanded(
            child: ChatWallpaper(
              theme: ChatThemes.byId(_themeId),
              child: _chargementInitial
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun message pour l\'instant.\nSoyez le premier à écrire !',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      )
                    : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                final showDate =
                    i == 0 || !_memeJour(_messages[i - 1].heure, msg.heure);
                return Column(
                  children: [
                    if (showDate) _separateurDate(msg.heure),
                    _bulleMessage(msg),
                  ],
                );
              },
            ),
            ),
          ),

          // ── Bandeau "En réponse à…" ──────────────────────────────────
          if (_messageEnReponse != null)
            Container(
              color: const Color(0xFFEAF2FE),
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              child: Row(children: [
                Container(width: 3, height: 34,
                    decoration: BoxDecoration(color: AppPalette.blue, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(_messageEnReponse!.auteur.nomComplet,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppPalette.blue)),
                    Text(_messageEnReponse!.contenu, style: const TextStyle(fontSize: 12, color: Color(0xFF54656F)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                GestureDetector(
                  onTap: () => setState(() => _messageEnReponse = null),
                  child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8))),
                ),
              ]),
            ),

          // ── Zone saisie ───────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(12, 10, 12, _enregistrement ? 10 : 14),
            child: _enregistrement
                ? VoiceRecordingBar(
                    paused: _voiceRecorder.isPaused,
                    secondes: _dureeEnregistrement,
                    couleur: AppPalette.blue,
                    controller: _voiceRecorder,
                    onCancel: _annulerEnregistrement,
                    onPauseResume: _pauseOuReprendreEnregistrement,
                    onSend: _arreterEtEnvoyerEnregistrement,
                  )
                : Row(
              children: [
                // Bouton pièce jointe
                GestureDetector(
                  onTap: _menuPieceJointe,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppPalette.lightBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppPalette.blue,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Champ texte
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _inputCtrl,
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Message au groupe...',
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Bouton emoji / GIF / stickers
                GestureDetector(
                  onTap: () => setState(() => _panneauOuvert = !_panneauOuvert),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _panneauOuvert ? AppPalette.blue.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _panneauOuvert ? Icons.keyboard_alt_outlined : Icons.emoji_emotions_outlined,
                      color: AppPalette.blue,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Bouton micro (vocal) — tap pour démarrer l'enregistrement
                GestureDetector(
                  onTap: _demarrerEnregistrement,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF15803D),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF15803D).withValues(alpha:0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Bouton envoyer
                GestureDetector(
                  onTap: _envoyerTexte,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppPalette.blue,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppPalette.blue.withValues(alpha:0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_panneauOuvert)
            EmojiGifStickerPicker(
              onEmoji: (emoji) {
                _inputCtrl.text += emoji;
                _inputCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _inputCtrl.text.length));
              },
              onEnvoiDirect: (type, valeur) {
                if (type == 'gif') {
                  _envoyerGif(valeur);
                } else {
                  _envoyerSticker(valeur);
                }
              },
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // WIDGETS
  // ════════════════════════════════════════════════════════════════════════

  Widget _separateurDate(DateTime dt) {
    final now = DateTime.now();
    final label = _memeJour(dt, now)
        ? 'Aujourd\'hui'
        : _memeJour(dt, now.subtract(const Duration(days: 1)))
        ? 'Hier'
        : '${dt.day}/${dt.month}/${dt.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bulleMessage(_MessageGroupe msg) {
    final estMoi = msg.estMoi;
    final theme = ChatThemes.byId(_themeId);
    final hovered = _hoveredMsgId == msg.id;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredMsgId = msg.id),
      onExit: (_) => setState(() => _hoveredMsgId = null),
      child: GestureDetector(
      onTap: _modeSelection ? () => _basculerSelection(msg.id) : null,
      onLongPress: _modeSelection ? null : () => _demarrerSelection(msg.id),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_modeSelection) ...[
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  _selectionnes.contains(msg.id) ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 22,
                  color: _selectionnes.contains(msg.id) ? AppPalette.blue : const Color(0xFFCBD5E1),
                ),
              ),
            ],
            Expanded(child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: estMoi
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!estMoi) ...[
              CircleAvatar(
                radius: 18,
                backgroundColor: AppPalette.blue.withValues(alpha:0.15),
                backgroundImage: (msg.auteur.photoUrl != null && msg.auteur.photoUrl!.isNotEmpty)
                    ? NetworkImage(msg.auteur.photoUrl!)
                    : null,
                child: (msg.auteur.photoUrl == null || msg.auteur.photoUrl!.isEmpty)
                    ? Text(
                        msg.auteur.initiales,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.blue,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],

            Flexible(
              child: Column(
                crossAxisAlignment: estMoi
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!estMoi)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                          msg.auteur.prenoms,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.blue,
                          ),
                        ),
                        const SizedBox(width: 6),
                        DelegueBadge(role: msg.auteur.etudiantRole, niveau: msg.auteur.niveau, compact: true),
                      ]),
                    ),

                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
                    decoration: BoxDecoration(
                      color: estMoi ? theme.bulleMoi : theme.bulleAutre,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(estMoi ? 18 : 4),
                        bottomRight: Radius.circular(estMoi ? 4 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: estMoi
                          ? null
                          : Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      if (msg.texteRepondu != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.fromLTRB(8, 5, 8, 6),
                          decoration: BoxDecoration(
                            color: (estMoi ? Colors.white : AppPalette.blue).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border(left: BorderSide(color: estMoi ? Colors.white : AppPalette.blue, width: 3)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            Text(msg.expediteurRepondu ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: estMoi ? Colors.white : AppPalette.blue)),
                            const SizedBox(height: 2),
                            Text(msg.texteRepondu!, style: TextStyle(fontSize: 12, color: (estMoi ? Colors.white : const Color(0xFF54656F)).withValues(alpha: 0.85)), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ]),
                        ),
                      _contenuMessage(msg, estMoi, theme),
                      const SizedBox(height: 2),
                      // Heure en bas à droite de la bulle, façon WhatsApp.
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                          _formatHeure(msg.heure),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: (estMoi ? Colors.white : const Color(0xFF64748B)).withValues(alpha: 0.7),
                          ),
                        ),
                      ]),
                    ]),
                  ),

                  // Réactions + flèche du menu, juste sous le message.
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (msg.reactions.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha:0.04),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              msg.reactions.keys.join(' '),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (hovered) ...[
                          GestureDetector(
                            onTap: () => _reagir(msg.id),
                            child: Container(width: 20, height: 20,
                              decoration: BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 3)]),
                              child: const Icon(Icons.expand_more_rounded, size: 14, color: Color(0xFF54656F))),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (estMoi) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppPalette.yellow,
                backgroundImage: (msg.auteur.photoUrl != null && msg.auteur.photoUrl!.isNotEmpty)
                    ? NetworkImage(msg.auteur.photoUrl!)
                    : null,
                child: (msg.auteur.photoUrl == null || msg.auteur.photoUrl!.isEmpty)
                    ? Text(
                        msg.auteur.initiales,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.blue,
                        ),
                      )
                    : null,
              ),
            ],
          ],
        )),
          ],
        ),
      ),
      ),
    );
  }

  Widget _contenuMessage(_MessageGroupe msg, bool estMoi, ChatThemeData theme) {
    final textColor = estMoi ? theme.texteMoi : theme.texteAutre;
    final subColor = estMoi ? theme.texteMoi.withValues(alpha: 0.7) : theme.texteAutre.withValues(alpha: 0.65);

    switch (msg.type) {
      case TypeMessage.photo:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: estMoi
                    ? Colors.white.withValues(alpha:0.2)
                    : AppPalette.blue.withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_outlined,
                    size: 40,
                    color: estMoi ? Colors.white70 : AppPalette.blue,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    msg.contenu,
                    style: TextStyle(
                      fontSize: 13,
                      color: subColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case TypeMessage.video:
        return Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: estMoi
                    ? Colors.white.withValues(alpha:0.2)
                    : const Color(0xFFDC2626).withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.play_circle_outline_rounded,
                size: 28,
                color: estMoi ? Colors.white : const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.contenu,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Vidéo',
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                ],
              ),
            ),
          ],
        );

      case TypeMessage.document:
        return Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: estMoi
                    ? Colors.white.withValues(alpha:0.2)
                    : AppPalette.blue.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.insert_drive_file_rounded,
                size: 26,
                color: estMoi ? Colors.white : AppPalette.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.contenu,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Document',
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.download_outlined,
              size: 20,
              color: estMoi ? Colors.white70 : AppPalette.blue,
            ),
          ],
        );

      case TypeMessage.vocal:
        return Row(
          children: [
            Icon(
              Icons.mic_rounded,
              size: 22,
              color: estMoi ? Colors.white : const Color(0xFF15803D),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: estMoi
                      ? Colors.white.withValues(alpha:0.4)
                      : const Color(0xFF15803D).withValues(alpha:0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              msg.contenu.replaceAll('vocal_', ''),
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      default:
        if (msg.contenu.startsWith('[GIF]')) {
          final url = msg.contenu.substring(5);
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              url,
              width: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text('[GIF]', style: TextStyle(fontSize: 13, color: subColor)),
            ),
          );
        }
        if (msg.contenu.startsWith('[STICKER]')) {
          final chemin = msg.contenu.substring(9);
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: kIsWeb
                ? const Text('🏷️ Sticker', style: TextStyle(fontSize: 13))
                : Image.file(File(chemin), width: 120, height: 120, fit: BoxFit.cover),
          );
        }
        if (msg.contenu.startsWith('[FICHIER]')) {
          final parts = msg.contenu.substring(9).split('|');
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
              couleur: estMoi ? Colors.white : AppPalette.blue,
              texteColor: textColor,
            );
          }
          final icone = fType == 'video' ? Icons.videocam_rounded : fType == 'audio' ? Icons.audiotrack_rounded : Icons.insert_drive_file_rounded;
          final couleurIcone = fType == 'video' ? const Color(0xFFDC2626) : fType == 'audio' ? const Color(0xFF15803D) : AppPalette.blue;
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(
                  color: estMoi ? Colors.white.withValues(alpha: 0.2) : couleurIcone.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icone, size: 20, color: estMoi ? Colors.white : couleurIcone)),
            const SizedBox(width: 10),
            Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nom, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor), maxLines: 2, overflow: TextOverflow.ellipsis),
              Text(fType == 'video' ? 'Vidéo' : fType == 'audio' ? 'Audio' : 'Document', style: TextStyle(fontSize: 12, color: subColor)),
            ])),
          ]);
        }
        if (msg.contenu.startsWith('[SONDAGE]')) {
          return SizedBox(width: 220, child: SondageWidget(sondageId: msg.contenu.substring(9)));
        }
        return Text(
          msg.contenu,
          style: TextStyle(fontSize: 15, color: textColor, height: 1.5),
        );
    }
  }

  bool _memeJour(DateTime a, DateTime b) =>
      a.day == b.day && a.month == b.month && a.year == b.year;

  String _formatHeure(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
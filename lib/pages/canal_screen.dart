import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../theme/app_palette.dart';
import '../models/student_profile.dart';
import '../services/socket_service.dart';
import 'messages_screen.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLE MESSAGE CANAL
// ════════════════════════════════════════════════════════════════════════════
class _MessageCanal {
  final String id, expediteur, initiales, texte, heure, date, type;
  final Color color;
  Map<String, int> reactions;
  bool epingle = false;

  _MessageCanal({
    required this.id,
    required this.expediteur,
    required this.initiales,
    required this.texte,
    required this.heure,
    required this.date,
    required this.type,
    required this.color,
    Map<String, int>? reactions,
  }) : reactions = reactions ?? {};

  factory _MessageCanal.fromJson(Map<String, dynamic> json, Color color) {
    final createdAt = DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now();
    final heure =
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    String date = 'Aujourd\'hui';
    if (createdAt.day != now.day || createdAt.month != now.month) {
      date = 'Hier';
    }
    final nom = json['expediteur'] ?? 'Inconnu';
    final parts = nom.split(' ');
    final initiales = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : nom.substring(0, 1).toUpperCase();
    return _MessageCanal(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      expediteur: nom,
      initiales: initiales,
      texte: json['contenu'] ?? '',
      heure: heure,
      date: date,
      type: json['type'] ?? 'texte',
      color: color,
      reactions: {},
    );
  }
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
  static const String _baseUrl = 'http://localhost:3000/api';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Canaux', style: TextStyle(fontSize: 22,
                    fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                Text('${widget.profile.prenoms} ${widget.profile.nom}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ])),
              Container(width: 38, height: 38,
                decoration: BoxDecoration(color: AppPalette.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.notifications_outlined,
                    color: AppPalette.blue, size: 20)),
            ]),
          ),
          Container(height: 1, color: const Color(0xFFE2E8F0)),
          Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
            _sectionLabel('📢 Officiels'),
            const SizedBox(height: 8),
            _carteCanal(context, avatar: '🏛️', nom: 'Administration',
                description: 'Annonces officielles et informations pédagogiques',
                couleur: AppPalette.blue, badge: '3', tag: 'Lecture seule',
                canalId: '1', type: 'administration'),
            const SizedBox(height: 10),
            _carteCanal(context, avatar: '📢', nom: 'Admin & Filière',
                description: 'Messages ciblés Admin+Délégué → votre filière',
                couleur: const Color(0xFF0891B2), badge: '1', tag: 'Broadcast',
                canalId: '2', type: 'admin_filiere'),
            const SizedBox(height: 10),
            _carteCanal(context, avatar: '🎉', nom: 'Bureau des Étudiants',
                description: 'Événements, activités et annonces du BDE',
                couleur: const Color(0xFF7C3AED), badge: '1', tag: 'BDE',
                canalId: '3', type: 'bde'),
            const SizedBox(height: 20),
            _sectionLabel('💬 Messages privés'),
            const SizedBox(height: 8),
            _carteCanal(context, avatar: '🔒', nom: 'Contacter l\'Administration',
                description: 'Posez une question en privé à l\'administration',
                couleur: const Color(0xFF059669), tag: 'Privé',
                canalId: '0', type: 'prive'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.blue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppPalette.blue.withOpacity(0.15)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, color: AppPalette.blue, size: 14),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Le groupe filière privé entre étudiants est accessible via l\'accueil → Groupe Filière.',
                  style: TextStyle(fontSize: 11, color: AppPalette.blue,
                      fontWeight: FontWeight.w500))),
              ]),
            ),
          ])),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String l) => Text(l, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B)));

  Widget _carteCanal(BuildContext context, {
    required String avatar, required String nom, required String description,
    required Color couleur, required String type, required String canalId,
    String? badge, String? tag,
  }) {
    return GestureDetector(
      onTap: () => _ouvrir(context, type, canalId),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(color: couleur.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(avatar, style: const TextStyle(fontSize: 22)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(nom, style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              if (tag != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: couleur.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(tag, style: TextStyle(fontSize: 9,
                      fontWeight: FontWeight.w700, color: couleur))),
              ],
            ]),
            const SizedBox(height: 3),
            Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          if (badge != null)
            Container(width: 22, height: 22,
              decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
              child: Center(child: Text(badge, style: const TextStyle(
                  fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold))))
          else
            Icon(Icons.chevron_right_rounded, color: couleur.withOpacity(0.5)),
        ]),
      ),
    );
  }

  void _ouvrir(BuildContext context, String type, String canalId) {
    final p = widget.profile;
    final peutEcrireAdminFiliere =
        (p.role == 'delegue' || p.role == 'delegue_adjoint');
    final peutEcrireBDE =
        p.role == 'bde_president' || p.role == 'bde_adjoint';

    late Widget page;
    switch (type) {
      case 'administration':
        page = _CanalDetail(profile: p, nom: 'Administration', avatar: '🏛️',
            couleur: AppPalette.blue, tag: 'Lecture seule', canalId: canalId,
            canWrite: false);
        break;
      case 'admin_filiere':
        page = _CanalDetail(profile: p, nom: 'Admin & Filière', avatar: '📢',
            couleur: const Color(0xFF0891B2),
            tag: peutEcrireAdminFiliere ? 'Broadcast · Vous pouvez écrire' : 'Broadcast',
            canalId: canalId, canWrite: peutEcrireAdminFiliere);
        break;
      case 'bde':
        page = _CanalDetail(profile: p, nom: 'Bureau des Étudiants', avatar: '🎉',
            couleur: const Color(0xFF7C3AED),
            tag: peutEcrireBDE ? 'BDE · Vous pouvez publier' : 'BDE',
            canalId: canalId, canWrite: peutEcrireBDE);
        break;
      case 'prive':
        page = _MessagePriveAdmin(profile: p);
        break;
      default:
        page = _CanalDetail(profile: p, nom: 'Administration', avatar: '🏛️',
            couleur: AppPalette.blue, tag: 'Lecture seule',
            canalId: canalId, canWrite: false);
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CANAL DÉTAIL — chargement API + Socket.io temps réel
// ════════════════════════════════════════════════════════════════════════════
class _CanalDetail extends StatefulWidget {
  final StudentProfile profile;
  final String nom, avatar, tag, canalId;
  final Color couleur;
  final bool canWrite;

  const _CanalDetail({
    required this.profile, required this.nom, required this.avatar,
    required this.tag, required this.couleur, required this.canalId,
    this.canWrite = false,
  });
  @override
  State<_CanalDetail> createState() => _CanalDetailState();
}

class _CanalDetailState extends State<_CanalDetail> {
  static const String _baseUrl = 'http://localhost:3000/api';
  final List<_MessageCanal> _msgs = [];
  final _inputCtrl = TextEditingController();
  final _scroll = ScrollController();
  bool _hasText = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _chargerMessages();
    _connecterSocket();
  }

  @override
  void dispose() {
    SocketService().off('new_canal_message');
    _inputCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Charger messages depuis l'API ─────────────────────────────────────
  Future<void> _chargerMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/messages/canal/${widget.canalId}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _msgs.clear();
          _msgs.addAll(data.map((m) =>
              _MessageCanal.fromJson(m, widget.couleur)));
          _loading = false;
        });
        _scrollBas();
      } else {
        // Fallback données locales si API indisponible
        setState(() { _loading = false; _msgs.addAll(_fallbackMsgs()); });
      }
    } catch (_) {
      setState(() { _loading = false; _msgs.addAll(_fallbackMsgs()); });
    }
  }

  // ── Connecter Socket.io ───────────────────────────────────────────────
  void _connecterSocket() {
    final roomId = 'canal_${widget.canalId}';
    SocketService().joinRoom(roomId);
    SocketService().onCanalMessage((data) {
      if (!mounted) return;
      final msg = _MessageCanal.fromJson(
          data is Map<String, dynamic> ? data : jsonDecode(data.toString()),
          widget.couleur);
      setState(() => _msgs.add(msg));
      _scrollBas();
    });
  }

  // ── Envoyer message ───────────────────────────────────────────────────
  Future<void> _envoyerMessage() async {
    final texte = _inputCtrl.text.trim();
    if (texte.isEmpty) return;
    final p = widget.profile;
    final now = TimeOfDay.now();
    final heure =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Ajout optimiste local
    final msgLocal = _MessageCanal(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      expediteur: '${p.prenoms} ${p.nom}',
      initiales: '${p.prenoms[0]}${p.nom[0]}'.toUpperCase(),
      texte: texte, heure: heure, date: 'Aujourd\'hui',
      type: 'texte', color: widget.couleur,
    );
    setState(() { _msgs.add(msgLocal); _hasText = false; });
    _inputCtrl.clear();
    _scrollBas();

    try {
      // Envoi via API REST
      await http.post(
        Uri.parse('$_baseUrl/messages/canal/${widget.canalId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contenu': texte,
          'expediteur': '${p.prenoms} ${p.nom}',
          'userId': p.matricule,
        }),
      );

      // Diffusion via Socket.io
      SocketService().sendCanalMessage(widget.canalId, {
        'contenu': texte,
        'expediteur': '${p.prenoms} ${p.nom}',
        'created_at': DateTime.now().toIso8601String(),
        'type': 'texte',
      });
    } catch (_) {
      // Message déjà affiché en local, on ignore l'erreur silencieusement
    }
  }

  void _scrollBas() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  // ── Données de fallback si API indisponible ───────────────────────────
  List<_MessageCanal> _fallbackMsgs() => [
    _MessageCanal(id: 'F1', expediteur: 'Dir. Pédagogique', initiales: 'DP',
        texte: 'Bienvenue sur ${widget.nom}. Les messages s\'afficheront ici.',
        heure: '08:00', date: 'Aujourd\'hui', type: 'texte', color: widget.couleur),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBE5DD),
      appBar: AppBar(
        backgroundColor: widget.couleur,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context)),
        titleSpacing: 0,
        title: Row(children: [
          Container(width: 34, height: 34,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(widget.avatar,
                style: const TextStyle(fontSize: 16)))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.nom, style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.bold), maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(widget.tag, style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ])),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8)),
            child: Text('${_msgs.length} msg',
                style: const TextStyle(fontSize: 11, color: Colors.white,
                    fontWeight: FontWeight.w600))),
        ],
      ),
      body: Column(children: [
        // Bannière rôle
        Container(
          color: widget.couleur.withOpacity(0.07),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(children: [
            Icon(widget.canWrite ? Icons.edit_rounded : Icons.lock_outline_rounded,
                size: 13, color: widget.couleur),
            const SizedBox(width: 8),
            Expanded(child: Text(
              widget.canWrite
                  ? '${widget.profile.roleBadgeEmoji} ${widget.profile.roleLabel} — Vous pouvez écrire dans ce canal.'
                  : 'Canal en lecture seule — Appuyez longuement pour réagir.',
              style: TextStyle(fontSize: 11, color: widget.couleur,
                  fontWeight: FontWeight.w500))),
          ]),
        ),
        Expanded(child: _loading
            ? Center(child: CircularProgressIndicator(color: widget.couleur))
            : _msgs.isEmpty
                ? Center(child: Text('Aucun message dans ce canal.',
                    style: TextStyle(color: Colors.grey.shade500)))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: _msgs.length,
                    itemBuilder: (_, i) {
                      final showDate = i == 0 || _msgs[i - 1].date != _msgs[i].date;
                      return Column(children: [
                        if (showDate) _separateur(_msgs[i].date),
                        _BulleCanal(
                          key: ValueKey(_msgs[i].id),
                          message: _msgs[i],
                          couleur: widget.couleur,
                          onMenu: () => _menuReaction(_msgs[i]),
                        ),
                      ]);
                    },
                  )),
        if (widget.canWrite) _zoneSaisie(),
      ]),
    );
  }

  Widget _zoneSaisie() => StatefulBuilder(
    builder: (ctx, setS) => Container(
      color: const Color(0xFFF0EBE3),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          margin: const EdgeInsets.only(right: 6, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: widget.couleur.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.couleur.withOpacity(0.3))),
          child: Text(widget.profile.roleBadgeEmoji,
              style: const TextStyle(fontSize: 16))),
        Expanded(child: Container(
          constraints: const BoxConstraints(maxHeight: 100),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                  blurRadius: 4)]),
          child: TextField(
            controller: _inputCtrl, maxLines: null,
            onChanged: (v) => setS(() => _hasText = v.trim().isNotEmpty),
            style: const TextStyle(fontSize: 14, color: Color(0xFF111B21)),
            decoration: InputDecoration(
              hintText: 'Message en tant que ${widget.profile.roleLabel}...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8696A0)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10))),
        )),
        const SizedBox(width: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _hasText
              ? GestureDetector(key: const ValueKey('send'),
                  onTap: _envoyerMessage,
                  child: Container(width: 42, height: 42,
                    decoration: BoxDecoration(color: widget.couleur,
                        shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 19)))
              : Container(key: const ValueKey('mic'), width: 42, height: 42,
                  decoration: BoxDecoration(color: widget.couleur,
                      shape: BoxShape.circle),
                  child: const Icon(Icons.mic_rounded,
                      color: Colors.white, size: 22)),
        ),
      ]),
    ),
  );

  Widget _separateur(String date) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFD9F2E4),
          borderRadius: BorderRadius.circular(8)),
      child: Text(date, style: const TextStyle(fontSize: 12,
          color: Color(0xFF54656F), fontWeight: FontWeight.w500)))));

  void _menuReaction(_MessageCanal msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['👍', '❤️', '😂', '😮', '😢', '🙏'].map((e) =>
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => msg.reactions[e] = (msg.reactions[e] ?? 0) + 1);
                  },
                  child: Container(width: 46, height: 46,
                    decoration: BoxDecoration(color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(e,
                        style: const TextStyle(fontSize: 26)))))).toList()),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          ListTile(dense: true,
            leading: const Icon(Icons.copy_rounded, color: Color(0xFF54656F), size: 20),
            title: const Text('Copier le texte',
                style: TextStyle(fontSize: 14, color: Color(0xFF54656F))),
            onTap: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: msg.texte));
              _snack('Texte copié !');
            }),
          ListTile(dense: true,
            leading: Icon(msg.epingle
                ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                color: AppPalette.blue, size: 20),
            title: Text(msg.epingle ? 'Désépingler' : 'Épingler',
                style: const TextStyle(fontSize: 14, color: AppPalette.blue)),
            onTap: () {
              Navigator.pop(context);
              setState(() => msg.epingle = !msg.epingle);
            }),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppPalette.blue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
}

// ════════════════════════════════════════════════════════════════════════════
// BULLE CANAL
// ════════════════════════════════════════════════════════════════════════════
class _BulleCanal extends StatefulWidget {
  final _MessageCanal message;
  final Color couleur;
  final VoidCallback onMenu;
  const _BulleCanal({super.key, required this.message,
      required this.couleur, required this.onMenu});
  @override
  State<_BulleCanal> createState() => _BulleCanalState();
}

class _BulleCanalState extends State<_BulleCanal> {
  bool _hovered = false;
  _MessageCanal get msg => widget.message;

  @override
  Widget build(BuildContext context) {
    final isPDF = msg.type == 'pdf';
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onLongPress: widget.onMenu,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(color: msg.color, shape: BoxShape.circle),
              child: Center(child: Text(msg.initiales, style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(msg.expediteur, style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.bold, color: msg.color)),
                const SizedBox(width: 8),
                Text(msg.heure, style: const TextStyle(fontSize: 10,
                    color: Color(0xFF94A3B8))),
                if (msg.epingle) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.push_pin_rounded, size: 11, color: AppPalette.blue),
                ],
              ]),
              const SizedBox(height: 4),
              Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72),
                padding: isPDF
                    ? const EdgeInsets.all(10)
                    : const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                      blurRadius: 4, offset: const Offset(0, 1))]),
                child: isPDF
                    ? Row(children: [
                        Container(width: 42, height: 42,
                          decoration: BoxDecoration(color: msg.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.picture_as_pdf_rounded,
                              color: msg.color, size: 24)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(msg.texte, style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                          const Text('PDF · Appuyer pour télécharger',
                              style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ])),
                        Icon(Icons.download_rounded, color: msg.color, size: 18),
                      ])
                    : Text(msg.texte, style: const TextStyle(fontSize: 14,
                          color: Color(0xFF0F172A), height: 1.5))),
              // Réactions
              if (msg.reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(spacing: 5,
                    children: msg.reactions.entries.map((e) =>
                      GestureDetector(
                        onTap: () => setState(() =>
                            msg.reactions[e.key] = (msg.reactions[e.key] ?? 0) + 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                                  blurRadius: 3)]),
                          child: Text('${e.key} ${e.value}',
                              style: const TextStyle(fontSize: 12))))).toList())),
              if (_hovered)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: GestureDetector(
                    onTap: widget.onMenu,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                              blurRadius: 3)]),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('😊', style: TextStyle(fontSize: 13)),
                        SizedBox(width: 2),
                        Icon(Icons.expand_more_rounded, size: 14,
                            color: Color(0xFF64748B)),
                      ])))),
            ])),
          ]),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// MESSAGE PRIVÉ ADMIN
// ════════════════════════════════════════════════════════════════════════════
class _MessagePriveAdmin extends StatefulWidget {
  final StudentProfile profile;
  const _MessagePriveAdmin({required this.profile});
  @override
  State<_MessagePriveAdmin> createState() => _MessagePriveAdminState();
}

class _MessagePriveAdminState extends State<_MessagePriveAdmin> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _hasText = false;

  final List<Map<String, dynamic>> _msgs = [
    {'texte': 'Bonjour, je suis disponible pour répondre à vos questions.',
     'estMoi': false, 'heure': '08:00', 'lu': true},
  ];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() => _hasText = _ctrl.text.trim().isNotEmpty));
    // Écouter les messages privés entrants
    SocketService().onPrivateMessage((data) {
      if (!mounted) return;
      setState(() => _msgs.add({
        'texte': data['contenu'] ?? data['texte'] ?? '',
        'estMoi': false,
        'heure': _now(), 'lu': true,
      }));
      _scrollBas();
    });
  }

  @override
  void dispose() {
    SocketService().off('new_private_message');
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollBas() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBE5DD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.pop(context)),
        title: const Row(children: [
          CircleAvatar(radius: 16, backgroundColor: Colors.white24,
              child: Text('🔒', style: TextStyle(fontSize: 14))),
          SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Administration', style: TextStyle(fontSize: 14,
                fontWeight: FontWeight.bold)),
            Text('Message privé · Confidentiel',
                style: TextStyle(fontSize: 10, color: Colors.white70)),
          ]),
        ]),
      ),
      body: Column(children: [
        Container(
          color: const Color(0xFF059669).withOpacity(0.07),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: const Row(children: [
            Icon(Icons.lock_rounded, size: 12, color: Color(0xFF059669)),
            SizedBox(width: 8),
            Expanded(child: Text('Conversation privée et confidentielle.',
                style: TextStyle(fontSize: 11, color: Color(0xFF059669),
                    fontWeight: FontWeight.w500))),
          ])),
        Expanded(child: ListView.builder(
          controller: _scroll, padding: const EdgeInsets.all(12),
          itemCount: _msgs.length,
          itemBuilder: (_, i) {
            final m = _msgs[i];
            final estMoi = m['estMoi'] as bool;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: estMoi
                    ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (!estMoi) ...[
                    const CircleAvatar(radius: 13,
                        backgroundColor: Color(0xFF059669),
                        child: Text('A', style: TextStyle(fontSize: 10,
                            fontWeight: FontWeight.bold, color: Colors.white))),
                    const SizedBox(width: 5),
                  ],
                  Flexible(child: Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.65),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: estMoi ? const Color(0xFFD9FDD3) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(estMoi ? 14 : 0),
                        bottomRight: Radius.circular(estMoi ? 0 : 14)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                          blurRadius: 3)]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(m['texte'] as String, style: const TextStyle(
                          fontSize: 14, color: Color(0xFF111B21), height: 1.4)),
                      const SizedBox(height: 2),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(m['heure'] as String, style: const TextStyle(
                            fontSize: 9, color: Color(0xFF667781))),
                        if (estMoi) ...[
                          const SizedBox(width: 3),
                          Icon((m['lu'] as bool)
                              ? Icons.done_all_rounded : Icons.done_rounded,
                              size: 12,
                              color: (m['lu'] as bool)
                                  ? const Color(0xFF53BDEB)
                                  : const Color(0xFF8696A0)),
                        ],
                      ]),
                    ]))),
                  if (estMoi) const SizedBox(width: 5),
                ]));
          })),
        Container(
          color: const Color(0xFFF0EBE3),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Container(
              constraints: const BoxConstraints(maxHeight: 100),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                      blurRadius: 4)]),
              child: TextField(controller: _ctrl, maxLines: null,
                style: const TextStyle(fontSize: 14, color: Color(0xFF111B21)),
                decoration: const InputDecoration(
                  hintText: 'Écrire un message privé...',
                  hintStyle: TextStyle(fontSize: 14, color: Color(0xFF8696A0)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10))))),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _hasText
                  ? GestureDetector(key: const ValueKey('send'), onTap: _envoyer,
                      child: Container(width: 42, height: 42,
                        decoration: const BoxDecoration(color: Color(0xFF059669),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 19)))
                  : Container(key: const ValueKey('mic'), width: 42, height: 42,
                      decoration: const BoxDecoration(color: Color(0xFF059669),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 22))),
          ])),
      ]),
    );
  }

  void _envoyer() {
    if (_ctrl.text.trim().isEmpty) return;
    final texte = _ctrl.text.trim();
    setState(() {
      _msgs.add({'texte': texte, 'estMoi': true, 'heure': _now(), 'lu': false});
    });
    // Envoyer via socket
    SocketService().sendPrivateMessage('admin', {
      'contenu': texte,
      'expediteur': '${widget.profile.prenoms} ${widget.profile.nom}',
    });
    _ctrl.clear();
    _scrollBas();
  }

  String _now() {
    final t = TimeOfDay.now();
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

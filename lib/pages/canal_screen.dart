import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../theme/app_palette.dart';
import '../models/student_profile.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../utils/snackbar_helper.dart';
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

  // Couleurs de l'identité premium
  static const Color _brandBlue = Color(0xFF1E40AF);
  static const Color _textMain = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _bgPage = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
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
                couleur: _brandBlue, badge: '3', tag: 'Lecture seule',
                canalId: '1', type: 'administration'),
            const SizedBox(height: 12),
            _carteCanal(context, icon: Icons.campaign_rounded, nom: 'Admin & Filière',
                description: 'Messages ciblés de l\'administration et de votre délégué',
                couleur: const Color(0xFF0891B2), badge: '1', tag: 'Broadcast',
                canalId: '2', type: 'admin_filiere'),
            const SizedBox(height: 12),
            _carteCanal(context, icon: Icons.gavel_rounded, nom: 'Bureau des Étudiants',
                description: 'Événements, activités et annonces du BDE',
                couleur: const Color(0xFF7C3AED), badge: '1', tag: 'BDE',
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

  Widget _sectionLabel(String text) => Text(text, style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w800, color: _textMuted, letterSpacing: 1.0));

  Widget _carteCanal(BuildContext context, {
    required IconData icon, required String nom, required String description,
    required Color couleur, required String type, required String canalId,
    String? badge, String? tag,
  }) {
    return GestureDetector(
      onTap: () => _ouvrir(context, type, canalId),
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
          if (badge != null)
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
    final peutEcrireAdminFiliere = (p.role == 'delegue' || p.role == 'delegue_adjoint');
    final peutEcrireBDE = p.role == 'bde_president' || p.role == 'bde_adjoint';

    late Widget page;
    switch (type) {
      case 'administration':
        page = _CanalDetail(profile: p, nom: 'Administration', icon: Icons.account_balance_rounded,
            couleur: _brandBlue, tag: 'Lecture seule', canalId: canalId,
            canWrite: false);
        break;
      case 'admin_filiere':
        page = _CanalDetail(profile: p, nom: 'Admin & Filière', icon: Icons.campaign_rounded,
            couleur: const Color(0xFF0891B2),
            tag: peutEcrireAdminFiliere ? 'Broadcast · Droits d\'écriture actifs' : 'Broadcast',
            canalId: canalId, canWrite: peutEcrireAdminFiliere);
        break;
      case 'bde':
        page = _CanalDetail(profile: p, nom: 'Bureau des Étudiants', icon: Icons.gavel_rounded,
            couleur: const Color(0xFF7C3AED),
            tag: peutEcrireBDE ? 'BDE · Droits de publication actifs' : 'BDE',
            canalId: canalId, canWrite: peutEcrireBDE);
        break;
      case 'prive':
        page = _MessagePriveAdmin(profile: p);
        break;
      default:
        page = _CanalDetail(profile: p, nom: 'Administration', icon: Icons.account_balance_rounded,
            couleur: _brandBlue, tag: 'Lecture seule',
            canalId: canalId, canWrite: false);
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
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
          _msgs.addAll(data.map((m) => _MessageCanal.fromJson(m, widget.couleur)));
          _loading = false;
        });
        _scrollBas();
      } else {
        setState(() { _loading = false; _msgs.addAll(_fallbackMsgs()); });
      }
    } catch (_) {
      setState(() { _loading = false; _msgs.addAll(_fallbackMsgs()); });
    }
  }

  void _connecterSocket() {
    final roomId = 'canal_${widget.canalId}';
    SocketService().joinRoom(roomId);
    SocketService().onCanalMessage((data) {
      if (!mounted) return;
      final msg = _MessageCanal.fromJson(
          data is Map<String, dynamic> ? data : jsonDecode(data.toString()), widget.couleur);
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
      await http.post(
        Uri.parse('$_baseUrl/messages/canal/${widget.canalId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contenu': texte,
          'expediteur': '${p.prenoms} ${p.nom}',
          'userId': p.matricule,
        }),
      );

      SocketService().sendCanalMessage(widget.canalId, {
        'contenu': texte,
        'expediteur': '${p.prenoms} ${p.nom}',
        'created_at': DateTime.now().toIso8601String(),
        'type': 'texte',
      });
    } catch (_) {}
  }

  void _scrollBas() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
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
      appBar: AppBar(
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
        
        Expanded(child: _loading
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
                          onMenu: () => _menuOptions(_msgs[i]),
                        ),
                      ]);
                    },
                  )),
        if (widget.canWrite) _zoneSaisie(),
      ]),
    );
  }
 
Widget _zoneSaisie() => Container(
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
        onTap: _hasText ? _envoyerMessage : null,
        child: Container(width: 44, height: 44,
          decoration: BoxDecoration(
            color: _hasText ? widget.couleur : const Color(0xFFE2E8F0),
            shape: BoxShape.circle),
          child: Icon(Icons.send_rounded, color: _hasText ? Colors.white : const Color(0xFF94A3B8), size: 18)),
      ),
    ]),
);

  Widget _separateur(String date) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(20)),
      child: Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)))));

  void _menuOptions(_MessageCanal msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          ListTile(
            leading: const Icon(Icons.copy_rounded, color: Color(0xFF64748B)),
            title: const Text('Copier le texte de l\'annonce', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: msg.texte));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Texte copié')));
            }),
          ListTile(
            leading: Icon(msg.epingle ? Icons.push_pin_outlined : Icons.push_pin_rounded, color: widget.couleur),
            title: Text(msg.epingle ? 'Désépingler le message' : 'Épingler en haut du canal', style: TextStyle(fontSize: 14, color: widget.couleur, fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              setState(() => msg.epingle = !msg.epingle);
            }),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _snack(String msg) => showAppSnackBar(context, msg,
      backgroundColor: AppPalette.blue);
}

// ════════════════════════════════════════════════════════════════════════════
// BULLE CANAL — Design Épuré type Slack
// ════════════════════════════════════════════════════════════════════════════
class _BulleCanal extends StatelessWidget {
  final _MessageCanal message;
  final Color couleur;
  final VoidCallback onMenu;
  const _BulleCanal({super.key, required this.message, required this.couleur, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final isPDF = message.type == 'pdf';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 38, height: 38,
          decoration: BoxDecoration(color: message.color, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(message.initiales, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(message.expediteur, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: message.color)),
            const SizedBox(width: 8),
            Text(message.heure, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            if (message.epingle) ...[
              const SizedBox(width: 8),
              const Icon(Icons.push_pin_rounded, size: 12, color: Color(0xFF1E40AF)),
            ],
          ]),
          const SizedBox(height: 6),
          GestureDetector(
            onLongPress: onMenu,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12), bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: isPDF
                  ? Row(children: [
                      Container(width: 40, height: 40,
                        decoration: BoxDecoration(color: message.color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.picture_as_pdf_rounded, color: message.color, size: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(message.texte, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const Text('Document PDF officiel', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ])),
                      Icon(Icons.file_download_rounded, color: message.color, size: 20),
                    ])
                  : Text(message.texte, style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), height: 1.45)),
            ),
          ),
        ])),
      ]),
    );
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
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _hasText = false;

  final List<Map<String, dynamic>> _msgs = [
    {'texte': 'Bonjour, l\'administration est à votre écoute. Posez votre question de manière détaillée.',
     'estMoi': false, 'heure': '08:00', 'lu': true},
  ];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() => _hasText = _ctrl.text.trim().isNotEmpty));
    SocketService().onPrivateMessage((data) {
      if (!mounted) return;
      setState(() => _msgs.add({
        'texte': data['contenu'] ?? data['texte'] ?? '',
        'estMoi': false, 'heure': _now(), 'lu': true,
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
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
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

  void _envoyer() {
    if (_ctrl.text.trim().isEmpty) return;
    final texte = _ctrl.text.trim();
    setState(() {
      _msgs.add({'texte': texte, 'estMoi': true, 'heure': _now(), 'lu': false});
    });
    SocketService().sendPrivateMessage('admin', {
      'contenu': texte,
      'expediteur': '${widget.profile.prenoms} ${widget.profile.nom}',
    });
    _ctrl.clear();
    _scrollBas();
  }
}
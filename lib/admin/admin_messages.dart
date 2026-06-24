import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../admin/admin_theme.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES
// ════════════════════════════════════════════════════════════════════════════
class MessageAdmin {
  final String id, expediteur, texte, heure, type;
  final bool estMoi;
  bool lu;
  Map<String, int> reactions;
  bool epingle, important;

  MessageAdmin({
    required this.id, required this.expediteur, required this.texte,
    required this.heure, required this.type, required this.estMoi,
    this.lu = true, Map<String, int>? reactions,
    this.epingle = false, this.important = false,
  }) : reactions = reactions ?? {};
}

class GroupeAdmin {
  final String id, nom, type, avatar, description;
  final String? filiereId;
  final List<String> membres;
  final List<MessageAdmin> messages;
  int nbNonLus;
  bool readonly;

  GroupeAdmin({
    required this.id, required this.nom, required this.type,
    required this.avatar, required this.description,
    this.filiereId, required this.membres,
    required this.messages, this.nbNonLus = 0, this.readonly = false,
  });
}

// ── Données mock ─────────────────────────────────────────────────────────
final List<GroupeAdmin> adminGroupes = [
  GroupeAdmin(
    id: 'G001', nom: 'Administration & Professeurs',
    type: 'admin_profs', avatar: '👨‍🏫',
    description: 'Canal officiel Admin ↔ Tous les professeurs',
    membres: ['Admin', 'OUÉDRAOGO Mamadou', 'SAWADOGO Issa'],
    nbNonLus: 2, readonly: false,
    messages: [
      MessageAdmin(id: 'M1', expediteur: 'Admin',
          texte: 'Les notes du S2 doivent être soumises avant le 05 Mai.',
          heure: '09:00', type: 'texte', estMoi: true),
      MessageAdmin(id: 'M2', expediteur: 'OUÉDRAOGO Mamadou',
          texte: 'Bien reçu. Je soumets les notes de RIT L2 aujourd\'hui.',
          heure: '09:15', type: 'texte', estMoi: false, lu: true),
      MessageAdmin(id: 'M3', expediteur: 'SAWADOGO Issa',
          texte: 'J\'ai besoin d\'un délai jusqu\'au 06 Mai.',
          heure: '09:32', type: 'texte', estMoi: false, lu: false),
    ]),
  GroupeAdmin(
    id: 'G002', nom: 'Administration & Délégués',
    type: 'admin_delegues', avatar: '🎓',
    description: 'Canal Admin ↔ Délégués de toutes les filières',
    membres: ['Admin', 'Délégué RIT L2', 'Délégué Marketing L2'],
    nbNonLus: 1, readonly: false,
    messages: [
      MessageAdmin(id: 'M4', expediteur: 'Admin',
          texte: 'Réunion vendredi 03 Mai à 10h en salle A1.',
          heure: '08:30', type: 'texte', estMoi: true),
      MessageAdmin(id: 'M5', expediteur: 'Délégué RIT L2',
          texte: 'Présent !',
          heure: '08:45', type: 'texte', estMoi: false, lu: false),
    ]),
  GroupeAdmin(
    id: 'G003', nom: 'RIT L2 — Admin & Délégué',
    type: 'admin_filiere', avatar: '💻', filiereId: 'F001',
    description: 'Canal broadcast Admin+Délégué → étudiants RIT L2',
    membres: ['Admin', 'Délégué RIT L2', '38 étudiants (lecture)'],
    nbNonLus: 0, readonly: true,
    messages: [
      MessageAdmin(id: 'M6', expediteur: 'Admin',
          texte: '📢 Examen de Réseaux & Protocoles le 10 Mai à 8h en salle B2.',
          heure: '14:00', type: 'texte', estMoi: true,
          reactions: {'👍': 12, '✅': 8, '😮': 2}),
      MessageAdmin(id: 'M7', expediteur: 'Délégué RIT L2',
          texte: 'Confirme ! On se retrouve à 7h45.',
          heure: '14:20', type: 'texte', estMoi: false, lu: true,
          reactions: {'👍': 15}),
    ]),
  GroupeAdmin(
    id: 'MP001', nom: 'Ibrahim KOURAOGO', type: 'prive',
    avatar: 'IK', description: 'RIT L2 · 24IST-O2/1851',
    membres: ['Admin', 'Ibrahim KOURAOGO'],
    nbNonLus: 1, readonly: false,
    messages: [
      MessageAdmin(id: 'MP1', expediteur: 'Ibrahim KOURAOGO',
          texte: 'Bonjour, je voudrais avoir des informations sur ma réclamation.',
          heure: '11:00', type: 'texte', estMoi: false, lu: false),
    ]),
  GroupeAdmin(
    id: 'MP002', nom: 'Fatimata TRAORÉ', type: 'prive',
    avatar: 'FT', description: 'RIT L2 · 24IST-O2/1234',
    membres: ['Admin', 'Fatimata TRAORÉ'],
    nbNonLus: 0, readonly: false,
    messages: [
      MessageAdmin(id: 'MP2', expediteur: 'Fatimata TRAORÉ',
          texte: 'Merci pour la correction de ma note !',
          heure: '09:30', type: 'texte', estMoi: false, lu: true),
      MessageAdmin(id: 'MP3', expediteur: 'Admin',
          texte: 'De rien Fatimata. Bonne continuation !',
          heure: '09:45', type: 'texte', estMoi: true),
    ]),
];

// ════════════════════════════════════════════════════════════════════════════
// PAGE ADMIN MESSAGES
// ════════════════════════════════════════════════════════════════════════════
class AdminMessages extends StatefulWidget {
  const AdminMessages({super.key});
  @override State<AdminMessages> createState() => _AdminMessagesState();
}

class _AdminMessagesState extends State<AdminMessages>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  GroupeAdmin? _groupeActif;
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _hasText     = false;
  bool _showEmoji   = false;
  bool _showSticker = false;
  String _query     = '';

  List<GroupeAdmin> get _officiels => adminGroupes
      .where((g) => g.type == 'admin_profs' || g.type == 'admin_delegues')
      .toList();
  List<GroupeAdmin> get _filieres =>
      adminGroupes.where((g) => g.type == 'admin_filiere').toList();
  List<GroupeAdmin> get _prives =>
      adminGroupes.where((g) => g.type == 'prive').toList();
  int get _totalNonLus =>
      adminGroupes.fold(0, (s, g) => s + g.nbNonLus);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _msgCtrl.addListener(() =>
        setState(() => _hasText = _msgCtrl.text.trim().isNotEmpty));
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

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
      ? Scaffold(backgroundColor: const Color(0xFFF5F7FA),
          body: _sidebar())
      : Scaffold(
          backgroundColor: const Color(0xFFEBE5DD),
          appBar: _chatAppBar(_groupeActif!),
          body: Column(children: [
            if (_groupeActif!.readonly) _banniereBroadcast(),
            Expanded(child: _listeMessages(_groupeActif!)),
            _zoneSaisie(_groupeActif!),
            if (_showEmoji) _panneauEmoji(),
            if (_showSticker) _panneauStickers(),
          ]));

  Widget _sidebar() => Column(children: [
    Container(color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(children: [
        Row(children: [
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Messagerie', style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
            if (_totalNonLus > 0)
              Text('$_totalNonLus non lu(s)', style: const TextStyle(
                  fontSize: 12, color: AdminTheme.primary,
                  fontWeight: FontWeight.w600)),
          ])),
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
          labelStyle: const TextStyle(fontWeight: FontWeight.w700,
              fontSize: 12),
          tabs: [
            _tabLabel('Officiels',
                _officiels.fold(0, (s, g) => s + g.nbNonLus)),
            _tabLabel('Filières',
                _filieres.fold(0, (s, g) => s + g.nbNonLus)),
            _tabLabel('Privés',
                _prives.fold(0, (s, g) => s + g.nbNonLus)),
          ]),
      ])),
    Container(height: 1, color: AdminTheme.border),
    Expanded(child: TabBarView(controller: _tabCtrl, children: [
      _listeGroupes(_officiels),
      _listeGroupes(_filieres),
      _listeGroupes(_prives),
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
              fontSize: 8, color: Colors.white,
              fontWeight: FontWeight.bold)))),
      ],
    ]));

  Widget _listeGroupes(List<GroupeAdmin> groupes) {
    final f = _query.isEmpty ? groupes : groupes.where((g) =>
        g.nom.toLowerCase().contains(_query.toLowerCase())).toList();
    if (f.isEmpty) return const Center(child: Text('Aucun groupe',
        style: TextStyle(fontSize: 13, color: AdminTheme.textMuted)));
    return ListView.builder(
      itemCount: f.length,
      itemBuilder: (_, i) => _itemGroupe(f[i]));
  }

  Widget _itemGroupe(GroupeAdmin g) {
    final active    = _groupeActif?.id == g.id;
    final dernMsg   = g.messages.isNotEmpty ? g.messages.last : null;
    final isPrive   = g.type == 'prive';
    final isFiliere = g.type == 'admin_filiere';
    final color     = _couleurType(g.type);

    return GestureDetector(
      onTap: () => setState(() {
        _groupeActif = g; g.nbNonLus = 0;
        _showEmoji = false; _showSticker = false;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        color: active ? AdminTheme.primaryLight : Colors.transparent,
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: isPrive ? null : BorderRadius.circular(12),
              shape: isPrive ? BoxShape.circle : BoxShape.rectangle),
            child: Center(child: isPrive
                ? Text(g.avatar, style: TextStyle(fontSize: 14,
                    fontWeight: FontWeight.bold, color: color))
                : Text(g.avatar, style: const TextStyle(fontSize: 20)))),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(g.nom, style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? AdminTheme.primary
                      : const Color(0xFF1A1A2E)),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (dernMsg != null)
                Text(dernMsg.heure, style: const TextStyle(
                    fontSize: 10, color: AdminTheme.textMuted)),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              if (isFiliere)
                Container(margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: AdminTheme.infoLight,
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('Broadcast', style: TextStyle(
                      fontSize: 8, fontWeight: FontWeight.w700,
                      color: AdminTheme.info))),
              Expanded(child: Text(
                dernMsg != null ? dernMsg.texte : 'Aucun message',
                style: const TextStyle(fontSize: 11,
                    color: AdminTheme.textSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (g.nbNonLus > 0)
                Container(width: 18, height: 18,
                  decoration: const BoxDecoration(
                      color: AdminTheme.primary, shape: BoxShape.circle),
                  child: Center(child: Text('${g.nbNonLus}',
                      style: const TextStyle(fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)))),
            ]),
          ])),
        ])));
  }

  Widget _chatView(GroupeAdmin g) => Scaffold(
    backgroundColor: const Color(0xFFEBE5DD),
    appBar: _chatAppBar(g),
    body: Column(children: [
      if (g.readonly) _banniereBroadcast(),
      Expanded(child: GestureDetector(
        onTap: () => setState(() {
          _showEmoji = false; _showSticker = false;
        }),
        child: _listeMessages(g))),
      _zoneSaisie(g),
      if (_showEmoji) _panneauEmoji(),
      if (_showSticker) _panneauStickers(),
    ]));

  PreferredSizeWidget _chatAppBar(GroupeAdmin g) => AppBar(
    backgroundColor: AdminTheme.primary, foregroundColor: Colors.white,
    elevation: 0,
    leading: !_isDesktop
        ? IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => setState(() => _groupeActif = null))
        : null,
    automaticallyImplyLeading: !_isDesktop,
    titleSpacing: 0,
    title: Row(children: [
      Container(width: 34, height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: g.type == 'prive' ? null : BorderRadius.circular(8),
          shape: g.type == 'prive' ? BoxShape.circle : BoxShape.rectangle),
        child: Center(child: Text(g.avatar, style: TextStyle(
            fontSize: g.type == 'prive' ? 12 : 16,
            fontWeight: FontWeight.bold, color: Colors.white)))),
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
      IconButton(icon: const Icon(Icons.info_outline_rounded,
          color: Colors.white70, size: 20),
          onPressed: () => _infoGroupe(g)),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: Colors.white.withOpacity(0.2))));

  Widget _banniereBroadcast() => Container(
    color: AdminTheme.infoLight,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    child: const Row(children: [
      Icon(Icons.campaign_rounded, color: AdminTheme.info, size: 14),
      SizedBox(width: 8),
      Expanded(child: Text(
        'Broadcast — Seuls Admin et Délégué peuvent écrire.',
        style: TextStyle(fontSize: 11, color: AdminTheme.info,
            fontWeight: FontWeight.w500))),
    ]));

  Widget _listeMessages(GroupeAdmin g) => ListView.builder(
    controller: _scrollCtrl,
    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
    itemCount: g.messages.length,
    itemBuilder: (_, i) => Column(children: [
      if (i == 0) _separateurDate('Aujourd\'hui'),
      // ← StatefulWidget séparé pour éviter mouse_tracker error
      _BulleAdmin(
        key: ValueKey(g.messages[i].id),
        message: g.messages[i],
        maxWidth: MediaQuery.of(context).size.width * 0.62,
        onMenu: () => _menuMsg(g.messages[i], g),
      ),
    ]));

  // ── Menu message ──────────────────────────────────────────────────────
  void _menuMsg(MessageAdmin msg, GroupeAdmin g) {
    showModalBottomSheet(context: context,
      backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 10),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...['👍','❤️','😂','😮','😢','🙏'].map((e) =>
                    GestureDetector(
                      onTap: () { Navigator.pop(context);
                        setState(() => msg.reactions[e] =
                            (msg.reactions[e] ?? 0) + 1); },
                      child: Container(width: 46, height: 46,
                        decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(12)),
                        child: Center(child: Text(e,
                            style: const TextStyle(fontSize: 26)))))),
                GestureDetector(
                  onTap: () { Navigator.pop(context);
                    _tousEmojis(msg); },
                  child: Container(width: 46, height: 46,
                    decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: const Icon(Icons.add_rounded,
                        color: Color(0xFF54656F), size: 24))),
              ])),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _act(Icons.reply_rounded, 'Répondre',
              const Color(0xFF54656F), () { Navigator.pop(context); }),
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
            msg.important ? 'Retirer des importants'
                : 'Marquer comme important',
            const Color(0xFF54656F), () { Navigator.pop(context);
              setState(() => msg.important = !msg.important); }),
          _act(Icons.check_box_outlined, 'Sélectionner',
              const Color(0xFF54656F), () { Navigator.pop(context);
                _snack('Mode sélection'); }),
          _act(Icons.save_alt_rounded, 'Enregistrer sous',
              const Color(0xFF54656F), () { Navigator.pop(context);
                _snack('💾 Enregistrement...'); }),
          _act(Icons.share_rounded, 'Partager',
              const Color(0xFF54656F), () { Navigator.pop(context);
                _snack('📤 Partage...'); }),
          if (msg.estMoi)
            _act(Icons.delete_outline_rounded, 'Supprimer',
                const Color(0xFFDC2626), () { Navigator.pop(context);
                  setState(() => g.messages.remove(msg)); }),
          const SizedBox(height: 12),
        ])));
  }

  Widget _act(IconData icon, String label, Color color,
      VoidCallback onTap) => ListTile(
    dense: true,
    leading: Icon(icon, color: color, size: 20),
    title: Text(label, style: TextStyle(fontSize: 14, color: color,
        fontWeight: FontWeight.w500)),
    onTap: onTap);

  void _tousEmojis(MessageAdmin msg) {
    final sc = TextEditingController();
    const emojis = ['😀','😃','😄','😁','😆','😅','🤣','😂','🙂','😉',
      '😊','😇','🥰','😍','😘','😋','😛','😜','🤪','🤑','🤗','🤔',
      '😐','😑','😶','😏','😒','🙄','😬','😌','😔','😴','🥺','😢',
      '😭','😱','😡','😠','💀','👍','👎','❤️','🔥','💯','🎉','🙏',
      '✅','👏','💪','🤝','👌','🫶','🤞','✌️','⭐','🌟','🎯','💫'];
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        final q = sc.text;
        final shown = q.isEmpty ? emojis
            : emojis.where((e) => e.contains(q)).toList();
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Container(height: 36,
                decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0))),
                child: TextField(
                  controller: sc, onChanged: (_) => setS(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher réaction',
                    hintStyle: TextStyle(fontSize: 13,
                        color: Color(0xFF94A3B8)),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Color(0xFF94A3B8), size: 16),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 9))))),
            Expanded(child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8, mainAxisSpacing: 2, crossAxisSpacing: 2),
              itemCount: shown.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () { Navigator.pop(ctx);
                  setState(() => msg.reactions[shown[i]] =
                      (msg.reactions[shown[i]] ?? 0) + 1); },
                child: Center(child: Text(shown[i],
                    style: const TextStyle(fontSize: 24)))))),
          ]));
      }));
  }

  // ── Zone saisie ───────────────────────────────────────────────────────
  Widget _zoneSaisie(GroupeAdmin g) => Container(
    color: const Color(0xFFF0EBE3),
    padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      _icnBtn(Icons.emoji_emotions_outlined, () => setState(() {
        _showEmoji = !_showEmoji; _showSticker = false;
      })),
      const SizedBox(width: 4),
      _icnBtn(Icons.gif_box_outlined,
          () => _snack('GIF bientôt disponible')),
      const SizedBox(width: 4),
      _icnBtn(Icons.sticky_note_2_outlined, () => setState(() {
        _showSticker = !_showSticker; _showEmoji = false;
      })),
      const SizedBox(width: 4),
      _icnBtn(Icons.add_rounded, () => _menuPieceJointe(g)),
      const SizedBox(width: 6),
      Expanded(child: Container(
        constraints: const BoxConstraints(maxHeight: 120),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.06), blurRadius: 4)]),
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (e) {
            if (e is KeyDownEvent &&
                e.logicalKey == LogicalKeyboardKey.enter &&
                !HardwareKeyboard.instance.isShiftPressed) _envoyer(g);
          },
          child: TextField(
            controller: _msgCtrl, maxLines: null,
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
            : Container(key: const ValueKey('mic'),
                width: 42, height: 42,
                decoration: const BoxDecoration(
                    color: AdminTheme.primary, shape: BoxShape.circle),
                child: const Icon(Icons.mic_rounded,
                    color: Colors.white, size: 22))),
    ]));

  Widget _icnBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: SizedBox(width: 34, height: 34,
      child: Icon(icon, color: const Color(0xFF667781), size: 22)));

  Widget _panneauEmoji() {
    const emojis = ['😀','😃','😄','😁','😆','😅','🤣','😂','🙂','😉',
      '😊','😇','🥰','😍','😘','😋','😛','😜','🤪','🤑','🤗','🤔',
      '😐','😑','😶','😏','😒','🙄','😬','😌','😔','😴','🥺','😢',
      '😭','😱','😡','😠','💀','👍','👎','❤️','🔥','💯','🎉','🙏',
      '✅','👏','💪','🤝','👌','🫶','🤞','✌️','⭐','🌟','🎯'];
    return Container(height: 210, color: Colors.white,
      child: Column(children: [
        Container(height: 1, color: const Color(0xFFE5E7EB)),
        Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Row(children: [
            const Text('Émojis', style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700)),
            const Spacer(),
            GestureDetector(onTap: () => setState(() => _showEmoji = false),
                child: const Icon(Icons.close_rounded,
                    size: 18, color: Color(0xFF94A3B8))),
          ])),
        Expanded(child: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 9, mainAxisSpacing: 2, crossAxisSpacing: 2),
          itemCount: emojis.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => setState(() {
              _msgCtrl.text += emojis[i];
              _msgCtrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: _msgCtrl.text.length));
            }),
            child: Center(child: Text(emojis[i],
                style: const TextStyle(fontSize: 20)))))),
      ]));
  }

  Widget _panneauStickers() {
    const stickers = ['😂','🔥','💯','🎉','👑','💪','😍','🤣','😭','🙏',
      '😤','🥳','😎','🤔','😅','✨','💀','🫡','🤯','😴','🫶','❤️',
      '💚','💙','⭐','🌟','🎯','🏆','🐱','🐶','🦁','🍕','🎮','🚀'];
    return Container(height: 210, color: Colors.white,
      child: Column(children: [
        Container(height: 1, color: const Color(0xFFE5E7EB)),
        Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Row(children: [
            const Text('Stickers', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700)),
            const Spacer(),
            GestureDetector(onTap: () => setState(() => _showSticker = false),
                child: const Icon(Icons.close_rounded,
                    size: 18, color: Color(0xFF94A3B8))),
          ])),
        Expanded(child: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
          itemCount: stickers.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () { setState(() => _showSticker = false);
              _envoyerSticker(stickers[i], _groupeActif!); },
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(stickers[i],
                  style: const TextStyle(fontSize: 26))))))),
      ]));
  }

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
                _envoyerMedia(g, 'document', 'document.pdf'); }),
          _mitem(Icons.photo_library_outlined, 'Photos et vidéos',
              const Color(0xFF00A884), () { Navigator.pop(context);
                _envoyerMedia(g, 'image', 'photo.jpg'); }),
          _mitem(Icons.camera_alt_outlined, 'Caméra',
              const Color(0xFFDC3545), () { Navigator.pop(context);
                _snack('📸 Caméra...'); }),
          _mitem(Icons.headphones_outlined, 'Audio',
              const Color(0xFFFF6B35), () { Navigator.pop(context);
                _envoyerMedia(g, 'vocal', '00:15'); }),
          _mitem(Icons.poll_outlined, 'Sondage',
              const Color(0xFF0D6EFD), () { Navigator.pop(context);
                _snack('📊 Sondage'); }),
          _mitem(Icons.add_circle_outline_rounded, 'Nouveau sticker',
              const Color(0xFF20C997), () { Navigator.pop(context);
                setState(() { _showSticker = true; _showEmoji = false; }); }),
          const SizedBox(height: 8),
        ])));
  }

  Widget _mitem(IconData icon, String label, Color color,
      VoidCallback onTap) => ListTile(
    leading: Container(width: 38, height: 38,
      decoration: BoxDecoration(color: color.withOpacity(0.12),
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
                  color: const Color(0xFF25D366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('💬',
                  style: TextStyle(fontSize: 20)))),
            title: const Text('Partager sur WhatsApp',
                style: TextStyle(fontWeight: FontWeight.w700)),
            onTap: () { Navigator.pop(context);
              _snack('✅ Ouverture WhatsApp...'); }),
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
                    texte: '↩️ Transféré : ${msg.texte}',
                    heure: _now(), type: 'texte', estMoi: true)));
                  _snack('✅ Transféré !'); });
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
          Text(g.avatar, style: const TextStyle(fontSize: 32)),
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
              style: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w700)),
          ...g.membres.map((m) => ListTile(dense: true,
            leading: CircleAvatar(radius: 14,
                backgroundColor: AdminTheme.primaryLight,
                child: Text(m[0], style: const TextStyle(fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.primary))),
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

  void _envoyer(GroupeAdmin g) {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() {
      g.messages.add(MessageAdmin(
        id: 'M${DateTime.now().millisecondsSinceEpoch}',
        expediteur: 'Admin', texte: _msgCtrl.text.trim(),
        heure: _now(), type: 'texte', estMoi: true));
    });
    _msgCtrl.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  void _envoyerSticker(String emoji, GroupeAdmin g) {
    setState(() {
      g.messages.add(MessageAdmin(
        id: 'S${DateTime.now().millisecondsSinceEpoch}',
        expediteur: 'Admin', texte: emoji,
        heure: _now(), type: 'sticker', estMoi: true));
    });
  }

  void _envoyerMedia(GroupeAdmin g, String type, String nom) {
    setState(() {
      g.messages.add(MessageAdmin(
        id: 'MD${DateTime.now().millisecondsSinceEpoch}',
        expediteur: 'Admin', texte: nom,
        heure: _now(), type: type, estMoi: true));
    });
  }

  Color _couleurType(String type) {
    switch (type) {
      case 'admin_profs':    return AdminTheme.primary;
      case 'admin_delegues': return AdminTheme.warning;
      case 'admin_filiere':  return AdminTheme.info;
      case 'prive':          return AdminTheme.success;
      default:               return AdminTheme.textMuted;
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

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AdminTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))));
}

// ════════════════════════════════════════════════════════════════════════════
// BULLE ADMIN — StatefulWidget séparé pour éviter mouse_tracker error
// ════════════════════════════════════════════════════════════════════════════
class _BulleAdmin extends StatefulWidget {
  final MessageAdmin message;
  final double maxWidth;
  final VoidCallback onMenu;

  const _BulleAdmin({
    super.key,
    required this.message,
    required this.maxWidth,
    required this.onMenu,
  });

  @override
  State<_BulleAdmin> createState() => _BulleAdminState();
}

class _BulleAdminState extends State<_BulleAdmin> {
  bool _hovered = false;

  MessageAdmin get msg => widget.message;

  @override
  Widget build(BuildContext context) {
    final estMoi = msg.estMoi;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onLongPress: widget.onMenu,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: estMoi
                ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!estMoi) ...[
                Container(width: 24, height: 24,
                  decoration: BoxDecoration(
                      color: AdminTheme.primaryLight,
                      shape: BoxShape.circle),
                  child: Center(child: Text(
                      msg.expediteur.isNotEmpty ? msg.expediteur[0] : '?',
                      style: const TextStyle(fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.primary)))),
                const SizedBox(width: 4),
              ],
              if (estMoi && _hovered)
                GestureDetector(onTap: widget.onMenu,
                  child: Container(width: 20, height: 20,
                    margin: const EdgeInsets.only(right: 4, bottom: 6),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 3)]),
                    child: const Icon(Icons.expand_more_rounded,
                        size: 14, color: Color(0xFF54656F))))
              else if (estMoi) const SizedBox(width: 24),

              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.maxWidth),
                child: Container(
                  decoration: BoxDecoration(
                    color: msg.type == 'sticker'
                        ? Colors.transparent
                        : estMoi ? const Color(0xFFD9FDD3) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(8),
                      topRight: const Radius.circular(8),
                      bottomLeft: Radius.circular(estMoi ? 8 : 0),
                      bottomRight: Radius.circular(estMoi ? 0 : 8)),
                    boxShadow: msg.type == 'sticker' ? null
                        : [BoxShadow(color: Colors.black.withOpacity(0.07),
                            blurRadius: 3, offset: const Offset(0, 1))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!estMoi)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(9, 5, 9, 0),
                          child: Text(msg.expediteur, style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: AdminTheme.primary))),
                      Padding(
                        padding: msg.type == 'sticker'
                            ? EdgeInsets.zero
                            : const EdgeInsets.fromLTRB(10, 5, 10, 2),
                        child: _contenu()),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (msg.reactions.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                msg.reactions.entries.map((e) =>
                                    '${e.key}${e.value > 1 ? ' ${e.value}' : ''}')
                                    .join(' '),
                                style: const TextStyle(fontSize: 11))),
                            const SizedBox(width: 4),
                          ],
                          if (msg.important)
                            const Padding(padding: EdgeInsets.only(right: 3),
                              child: Icon(Icons.star_rounded,
                                  size: 11, color: Color(0xFFFFB800))),
                          if (msg.epingle)
                            const Padding(padding: EdgeInsets.only(right: 3),
                              child: Icon(Icons.push_pin_rounded,
                                  size: 10, color: Color(0xFF8696A0))),
                          Text(msg.heure, style: const TextStyle(
                              fontSize: 10, color: Color(0xFF667781))),
                          if (estMoi) ...[
                            const SizedBox(width: 3),
                            Icon(msg.lu ? Icons.done_all_rounded
                                : Icons.done_rounded, size: 13,
                                color: msg.lu
                                    ? const Color(0xFF53BDEB)
                                    : const Color(0xFF8696A0)),
                          ],
                        ])),
                    ])),
              ),

              if (!estMoi && _hovered)
                GestureDetector(onTap: widget.onMenu,
                  child: Container(width: 20, height: 20,
                    margin: const EdgeInsets.only(left: 4, bottom: 6),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 3)]),
                    child: const Icon(Icons.expand_more_rounded,
                        size: 14, color: Color(0xFF54656F))))
              else if (!estMoi) const SizedBox(width: 24),

              if (estMoi) const SizedBox(width: 4),
            ]))));
  }

  Widget _contenu() {
    if (msg.type == 'sticker') {
      return Text(msg.texte, style: const TextStyle(fontSize: 52));
    }
    if (msg.type == 'document' || msg.type == 'image') {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 34, height: 34,
          decoration: BoxDecoration(
              color: const Color(0xFF7F66FF).withOpacity(0.15),
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
        const Icon(Icons.download_rounded,
            size: 16, color: Color(0xFF8696A0)),
      ]);
    }
    return Text(msg.texte, style: const TextStyle(
        fontSize: 14, color: Color(0xFF111B21), height: 1.4));
  }
}

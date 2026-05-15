import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES
// ════════════════════════════════════════════════════════════════════════════
class ContactEtudiant {
  final String nom, prenoms, matricule, filiere, niveau, telephone;
  const ContactEtudiant({
    required this.nom, required this.prenoms, required this.matricule,
    required this.filiere, required this.niveau, required this.telephone,
  });
  String get initiales => '${prenoms[0]}${nom[0]}'.toUpperCase();
  String get nomComplet => '$prenoms $nom';
}

enum TypeMessagePrive { texte, image, document, vocal, sticker, video, lien }

class MessagePrive {
  final String id;
  String texte;
  final String heure;
  final TypeMessagePrive type;
  final bool estMoi;
  bool lu;
  Map<String, int> reactions;
  bool epingle;
  bool important;

  MessagePrive({
    required this.id, required this.texte, required this.heure,
    required this.type, required this.estMoi,
    this.lu = true, Map<String, int>? reactions,
    this.epingle = false, this.important = false,
  }) : reactions = reactions ?? {};
}

class ConversationPrivee {
  final String id;
  final ContactEtudiant contact;
  List<MessagePrive> messages;
  bool epingle;

  ConversationPrivee({
    required this.id, required this.contact,
    required this.messages, this.epingle = false,
  });

  MessagePrive? get dernierMessage =>
      messages.isEmpty ? null : messages.last;
  int get nbNonLus =>
      messages.where((m) => !m.estMoi && !m.lu).length;
}

// ── Données mock ─────────────────────────────────────────────────────────
final List<ContactEtudiant> tousLesEtudiants = [
  const ContactEtudiant(nom: 'TRAORÉ', prenoms: 'Fatimata',
      matricule: '24IST-O2/1234',
      filiere: 'Réseaux Informatiques et Télécom',
      niveau: 'Licence 2', telephone: '70000002'),
  const ContactEtudiant(nom: 'OUÉDRAOGO', prenoms: 'Salif',
      matricule: '24IST-O2/1102',
      filiere: 'Réseaux Informatiques et Télécom',
      niveau: 'Licence 2', telephone: '70000007'),
  const ContactEtudiant(nom: 'KABORÉ', prenoms: 'Aminata',
      matricule: '24IST-O2/1456',
      filiere: 'Réseaux Informatiques et Télécom',
      niveau: 'Licence 2', telephone: '70000004'),
  const ContactEtudiant(nom: 'ZONGO', prenoms: 'Daouda',
      matricule: '24IST-O2/1789',
      filiere: 'Réseaux Informatiques et Télécom',
      niveau: 'Licence 2', telephone: '70000005'),
  const ContactEtudiant(nom: 'SAWADOGO', prenoms: 'Raïssa',
      matricule: '24IST-O2/1320',
      filiere: 'Réseaux Informatiques et Télécom',
      niveau: 'Licence 2', telephone: '70000008'),
];

final List<ConversationPrivee> conversationsPrivees = [
  ConversationPrivee(
    id: 'C001', contact: tousLesEtudiants[0], epingle: true,
    messages: [
      MessagePrive(id: 'M1',
          texte: 'Salut ! Tu as les notes du cours de BDD ?',
          heure: '14:30', type: TypeMessagePrive.texte,
          estMoi: false, lu: true),
      MessagePrive(id: 'M2',
          texte: 'Oui je te les envoie demain matin',
          heure: '14:45', type: TypeMessagePrive.texte,
          estMoi: true, lu: true),
      MessagePrive(id: 'M3', texte: 'Merci beaucoup ! 🙏',
          heure: '14:46', type: TypeMessagePrive.texte,
          estMoi: false, lu: false, reactions: {'❤️': 1}),
    ]),
  ConversationPrivee(
    id: 'C002', contact: tousLesEtudiants[2],
    messages: [
      MessagePrive(id: 'M4',
          texte: 'On se retrouve à la biblio à 14h ?',
          heure: '09:00', type: TypeMessagePrive.texte,
          estMoi: false, lu: true),
      MessagePrive(id: 'M5', texte: 'Oui parfait !',
          heure: '09:05', type: TypeMessagePrive.texte,
          estMoi: true, lu: true),
    ]),
  ConversationPrivee(
    id: 'C003', contact: tousLesEtudiants[1],
    messages: [
      MessagePrive(id: 'M6',
          texte: 'Tu viens à la séance de révision ?',
          heure: '08:30', type: TypeMessagePrive.texte,
          estMoi: false, lu: false),
    ]),
];

final List<String> stickersSauvegardes = ['😂', '🔥', '💯', '🎉', '👑', '💪'];

// ════════════════════════════════════════════════════════════════════════════
// PAGE MESSAGES
// ════════════════════════════════════════════════════════════════════════════
class MessagesScreen extends StatefulWidget {
  final StudentProfile profile;
  const MessagesScreen({super.key, required this.profile});
  @override State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  ConversationPrivee? _convActive;
  final _searchCtrl = TextEditingController();
  String _query = '';

  bool get _isDesktop => MediaQuery.of(context).size.width > 700;
  int get _totalNonLus =>
      conversationsPrivees.fold(0, (s, c) => s + c.nbNonLus);

  @override
  Widget build(BuildContext context) {
    if (_isDesktop) {
      return Row(children: [
        Container(width: 340,
          decoration: const BoxDecoration(color: Colors.white,
              border: Border(right: BorderSide(color: Color(0xFFE2E8F0)))),
          child: _sidebar()),
        Expanded(child: _convActive == null
            ? _accueilVide()
            : _ConversationView(
                profile: widget.profile,
                conversation: _convActive!,
                onBack: null,
                onUpdate: () => setState(() {}))),
      ]);
    }
    if (_convActive != null) {
      return _ConversationView(
        profile: widget.profile, conversation: _convActive!,
        onBack: () => setState(() => _convActive = null),
        onUpdate: () => setState(() {}));
    }
    return Scaffold(backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(child: _sidebar()));
  }

  Widget _sidebar() => Column(children: [
    Container(color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(children: [
        Row(children: [
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Messages', style: TextStyle(fontSize: 20,
                fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            if (_totalNonLus > 0)
              Text('$_totalNonLus non lu(s)', style: const TextStyle(
                  fontSize: 12, color: AppPalette.blue,
                  fontWeight: FontWeight.w600)),
          ])),
          GestureDetector(
            onTap: _nouvelleConv,
            child: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: AppPalette.blue,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.edit_rounded,
                  color: Colors.white, size: 18))),
        ]),
        const SizedBox(height: 10),
        Container(height: 36,
          decoration: BoxDecoration(color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0))),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Rechercher...',
              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: Icon(Icons.search_rounded,
                  color: Color(0xFF94A3B8), size: 16),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 9)))),
        const SizedBox(height: 10),
      ])),
    Container(height: 1, color: const Color(0xFFE2E8F0)),
    Expanded(child: ListView(children: [
      ..._filtres.where((c) => c.epingle).map(_itemConv),
      if (_filtres.any((c) => c.epingle) && _filtres.any((c) => !c.epingle))
        const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('Récentes', style: TextStyle(fontSize: 11,
              fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)))),
      ..._filtres.where((c) => !c.epingle).map(_itemConv),
    ])),
    Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
      child: GestureDetector(
        onTap: _nouvelleConv,
        child: Container(padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
              color: AppPalette.blue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppPalette.blue.withOpacity(0.15))),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.people_rounded, color: AppPalette.blue, size: 16),
            SizedBox(width: 6),
            Text('Voir tous les contacts', style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: AppPalette.blue)),
          ])))),
  ]);

  List<ConversationPrivee> get _filtres {
    if (_query.isEmpty) return conversationsPrivees;
    return conversationsPrivees.where((c) =>
        c.contact.nomComplet.toLowerCase().contains(
            _query.toLowerCase())).toList();
  }

  Widget _itemConv(ConversationPrivee c) {
    final active  = _convActive?.id == c.id;
    final dernMsg = c.dernierMessage;
    return GestureDetector(
      onTap: () => setState(() {
        _convActive = c;
        for (final m in c.messages) { if (!m.estMoi) m.lu = true; }
      }),
      onLongPress: () => _menuConv(c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: active ? AppPalette.blue.withOpacity(0.07) : Colors.transparent,
        child: Row(children: [
          Stack(children: [
            Container(width: 46, height: 46,
              decoration: BoxDecoration(
                  color: AppPalette.blue.withOpacity(0.12),
                  shape: BoxShape.circle),
              child: Center(child: Text(c.contact.initiales,
                  style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.blue)))),
            if (c.epingle)
              Positioned(bottom: 0, right: 0,
                child: Container(width: 16, height: 16,
                  decoration: const BoxDecoration(
                      color: AppPalette.blue, shape: BoxShape.circle),
                  child: const Icon(Icons.push_pin_rounded,
                      color: Colors.white, size: 10))),
          ]),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(c.contact.nomComplet, style: TextStyle(
                  fontSize: 14,
                  fontWeight: c.nbNonLus > 0
                      ? FontWeight.w800 : FontWeight.w600,
                  color: const Color(0xFF0F172A)))),
              if (dernMsg != null)
                Text(dernMsg.heure, style: TextStyle(fontSize: 11,
                    color: c.nbNonLus > 0
                        ? AppPalette.blue : const Color(0xFF94A3B8),
                    fontWeight: c.nbNonLus > 0
                        ? FontWeight.bold : FontWeight.normal)),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              if (dernMsg?.estMoi == true)
                Icon(dernMsg!.lu ? Icons.done_all_rounded
                    : Icons.done_rounded, size: 13,
                    color: dernMsg.lu ? const Color(0xFF0891B2)
                        : const Color(0xFF94A3B8)),
              if (dernMsg?.estMoi == true) const SizedBox(width: 3),
              Expanded(child: Text(
                dernMsg == null ? '' :
                dernMsg.type == TypeMessagePrive.image ? '📷 Photo' :
                dernMsg.type == TypeMessagePrive.document ? '📄 Document' :
                dernMsg.type == TypeMessagePrive.vocal ? '🎤 Vocal' :
                dernMsg.type == TypeMessagePrive.sticker ? '😊 Sticker' :
                dernMsg.texte,
                style: TextStyle(fontSize: 12,
                    color: c.nbNonLus > 0
                        ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    fontWeight: c.nbNonLus > 0
                        ? FontWeight.w600 : FontWeight.normal),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (c.nbNonLus > 0)
                Container(width: 20, height: 20,
                  decoration: const BoxDecoration(
                      color: AppPalette.blue, shape: BoxShape.circle),
                  child: Center(child: Text('${c.nbNonLus}',
                      style: const TextStyle(fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)))),
            ]),
          ])),
        ])));
  }

  Widget _accueilVide() => Container(
    color: const Color(0xFFF5F7FA),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 72, height: 72,
        decoration: BoxDecoration(
            color: AppPalette.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.chat_bubble_outline_rounded,
            color: AppPalette.blue, size: 36)),
      const SizedBox(height: 14),
      const Text('Sélectionnez une conversation',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      const Text('Choisissez une discussion dans la liste.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
    ])));

  void _menuConv(ConversationPrivee c) {
    showModalBottomSheet(context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(
          mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 10),
        Text(c.contact.nomComplet, style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold)),
        const Divider(),
        ListTile(
          leading: Icon(c.epingle
              ? Icons.push_pin_outlined : Icons.push_pin_rounded,
              color: AppPalette.blue),
          title: Text(c.epingle ? 'Désépingler' : 'Épingler'),
          onTap: () { Navigator.pop(context);
            setState(() => c.epingle = !c.epingle); }),
        ListTile(
          leading: const Icon(Icons.delete_outline_rounded,
              color: Color(0xFFDC2626)),
          title: const Text('Supprimer',
              style: TextStyle(color: Color(0xFFDC2626))),
          onTap: () { Navigator.pop(context);
            setState(() {
              conversationsPrivees.remove(c);
              if (_convActive?.id == c.id) _convActive = null;
            }); }),
        const SizedBox(height: 8),
      ])));
  }

  void _nouvelleConv() {
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.all(14),
            child: Text('Nouvelle conversation', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800))),
          const Divider(height: 1),
          Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [
            ...tousLesEtudiants.map((e) => GestureDetector(
              onTap: () { Navigator.pop(context); _ouvrirOuCreer(e); },
              child: Container(margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Container(width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: AppPalette.blue.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: Center(child: Text(e.initiales,
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.blue)))),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.nomComplet, style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(e.filiere, style: const TextStyle(
                        fontSize: 11, color: Color(0xFF64748B)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8)),
                ])))),
            const Divider(),
            GestureDetector(
              onTap: () { Navigator.pop(context); _ajouterParNumero(); },
              child: Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: AppPalette.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppPalette.blue.withOpacity(0.15))),
                child: const Row(children: [
                  Icon(Icons.dialpad_rounded, color: AppPalette.blue, size: 18),
                  SizedBox(width: 10),
                  Text('Ajouter par numéro', style: TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w700, color: AppPalette.blue)),
                ]))),
          ])),
        ])));
  }

  void _ouvrirOuCreer(ContactEtudiant e) {
    final exist = conversationsPrivees.where(
        (c) => c.contact.matricule == e.matricule).firstOrNull;
    if (exist != null) { setState(() => _convActive = exist); return; }
    final n = ConversationPrivee(
        id: 'C${DateTime.now().millisecondsSinceEpoch}',
        contact: e, messages: []);
    setState(() { conversationsPrivees.insert(0, n); _convActive = n; });
  }

  void _ajouterParNumero() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Trouver par numéro'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Numéro enregistré sur le compte ScolarHub.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(height: 12),
        Container(decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0))),
          child: TextField(controller: ctrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'Ex: 70000002',
              prefixIcon: Icon(Icons.phone_rounded, size: 16,
                  color: Color(0xFF94A3B8)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12)))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            final f = tousLesEtudiants.where(
                (e) => e.telephone == ctrl.text.trim()).firstOrNull;
            Navigator.pop(context);
            if (f != null) _ouvrirOuCreer(f);
            else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Aucun compte trouvé.'),
              backgroundColor: Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating));
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppPalette.blue,
              foregroundColor: Colors.white),
          child: const Text('Rechercher')),
      ]));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// VUE CONVERSATION
// ════════════════════════════════════════════════════════════════════════════
class _ConversationView extends StatefulWidget {
  final StudentProfile profile;
  final ConversationPrivee conversation;
  final VoidCallback? onBack;
  final VoidCallback onUpdate;
  const _ConversationView({
    required this.profile, required this.conversation,
    required this.onBack, required this.onUpdate});
  @override State<_ConversationView> createState() =>
      _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode  = FocusNode();
  bool _hasText     = false;
  bool _showEmoji   = false;
  bool _showSticker = false;

  ConversationPrivee get _conv => widget.conversation;
  ContactEtudiant   get _contact => _conv.contact;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() =>
        setState(() => _hasText = _msgCtrl.text.trim().isNotEmpty));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollBas());
  }

  @override
  void dispose() {
    _msgCtrl.dispose(); _scrollCtrl.dispose(); _focusNode.dispose();
    super.dispose();
  }

  void _scrollBas() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBE5DD),
      appBar: _appBar(),
      body: Column(children: [
        Expanded(child: GestureDetector(
          onTap: () => setState(() {
            _showEmoji = false; _showSticker = false;
          }),
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            itemCount: _conv.messages.length,
            itemBuilder: (_, i) => Column(children: [
              if (i == 0) _separateurDate('Aujourd\'hui'),
              // ← Chaque bulle est son propre StatefulWidget
              _BulleMessage(
                key: ValueKey(_conv.messages[i].id),
                message: _conv.messages[i],
                contact: _contact,
                maxWidth: MediaQuery.of(context).size.width * 0.62,
                onMenuTap: () => _menuMsg(_conv.messages[i]),
                onProfilTap: () => _voirProfil(),
              ),
            ])))),
        _zoneSaisie(),
        if (_showEmoji) _panneauEmoji(),
        if (_showSticker) _panneauStickers(),
      ]),
    );
  }

  AppBar _appBar() => AppBar(
    backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
    elevation: 0,
    leading: widget.onBack != null
        ? IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: widget.onBack)
        : null,
    automaticallyImplyLeading: widget.onBack != null,
    titleSpacing: 0,
    title: GestureDetector(
      onTap: () => _voirProfil(),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: Center(child: Text(_contact.initiales,
              style: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.bold, color: Colors.white)))),
        const SizedBox(width: 10),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_contact.nomComplet, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700)),
          const Text('en ligne', style: TextStyle(
              fontSize: 10, color: Colors.white70)),
        ])),
      ])),
    actions: [
      IconButton(icon: const Icon(Icons.videocam_rounded, size: 22),
          onPressed: () {}),
      IconButton(icon: const Icon(Icons.call_rounded, size: 20),
          onPressed: () {}),
      PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'profil') _voirProfil();
          if (v == 'effacer') _effacer();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'profil', child: Text('Voir le profil')),
          PopupMenuItem(value: 'effacer',
              child: Text('Effacer la discussion')),
        ]),
    ]);

  Widget _zoneSaisie() => Container(
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
      _icnBtn(Icons.add_rounded, _menuPieceJointe),
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
                !HardwareKeyboard.instance.isShiftPressed) _envoyer();
          },
          child: TextField(
            controller: _msgCtrl, focusNode: _focusNode,
            maxLines: null,
            style: const TextStyle(fontSize: 14, color: Color(0xFF111B21)),
            decoration: const InputDecoration(
              hintText: 'Message...',
              hintStyle: TextStyle(fontSize: 14, color: Color(0xFF8696A0)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10)))))),
      const SizedBox(width: 6),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: _hasText
            ? GestureDetector(key: const ValueKey('send'), onTap: _envoyer,
                child: Container(width: 42, height: 42,
                  decoration: const BoxDecoration(
                      color: AppPalette.blue, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 19)))
            : GestureDetector(key: const ValueKey('mic'),
                onTap: () => _envoyerMedia(TypeMessagePrive.vocal, '00:08'),
                child: Container(width: 42, height: 42,
                  decoration: const BoxDecoration(
                      color: AppPalette.blue, shape: BoxShape.circle),
                  child: const Icon(Icons.mic_rounded,
                      color: Colors.white, size: 22)))),
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
        Container(height: 1, color: const Color(0xFFE2E8F0)),
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
      '💚','💙','⭐','🌟','🎯','🏆','🐱','🐶','🦁','🍕','🎮','🚀','🌈'];
    return Container(height: 210, color: Colors.white,
      child: Column(children: [
        Container(height: 1, color: const Color(0xFFE2E8F0)),
        Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Row(children: [
            const Text('Stickers', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700)),
            const Spacer(),
            GestureDetector(onTap: () => _snack('📸 Créer un sticker'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: AppPalette.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, color: AppPalette.blue, size: 14),
                  SizedBox(width: 3),
                  Text('Créer', style: TextStyle(fontSize: 11,
                      color: AppPalette.blue, fontWeight: FontWeight.w700)),
                ]))),
            const SizedBox(width: 8),
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
              _envoyerSticker(stickers[i]); },
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(stickers[i],
                  style: const TextStyle(fontSize: 26))))))),
      ]));
  }

  void _menuMsg(MessagePrive msg) {
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
          _act(Icons.reply_rounded, 'Répondre', const Color(0xFF54656F),
              () { Navigator.pop(context); }),
          _act(Icons.copy_rounded, 'Copier', const Color(0xFF54656F), () {
            Navigator.pop(context);
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
          if (!msg.estMoi)
            _act(Icons.flag_outlined, 'Signaler',
                const Color(0xFFDC2626), () { Navigator.pop(context);
                  _snack('⚠️ Message signalé.'); }),
          if (!msg.estMoi && msg.type == TypeMessagePrive.sticker)
            _act(Icons.bookmark_add_rounded, 'Sauvegarder le sticker',
                const Color(0xFF54656F), () { Navigator.pop(context);
                  if (!stickersSauvegardes.contains(msg.texte)) {
                    stickersSauvegardes.add(msg.texte);
                  }
                  _snack('✅ Sticker sauvegardé !'); }),
          if (msg.estMoi)
            _act(Icons.delete_outline_rounded, 'Supprimer',
                const Color(0xFFDC2626), () { Navigator.pop(context);
                  setState(() => _conv.messages.remove(msg)); }),
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

  void _tousEmojis(MessagePrive msg) {
    final sc = TextEditingController();
    const emojis = ['😀','😃','😄','😁','😆','😅','🤣','😂','🙂','😉',
      '😊','😇','🥰','😍','😘','😋','😛','😜','🤪','🤑','🤗','🤔',
      '😐','😑','😶','😏','😒','🙄','😬','😌','😔','😴','🥺','😢',
      '😭','😱','😡','😠','💀','👍','👎','❤️','🔥','💯','🎉','🙏',
      '✅','👏','💪','🤝','👌','🫶','🤞','✌️','⭐','🌟','🎯','💫',
      '🎵','🎶','🎸','🎹','🎺','🎻','🥁','🎤','🎧','🎮','🎯','🎲'];
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
                  controller: sc,
                  onChanged: (_) => setS(() {}),
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

  void _menuPieceJointe() {
    showModalBottomSheet(context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          _mitem(Icons.insert_drive_file_outlined, 'Document',
              const Color(0xFF7F66FF), () { Navigator.pop(context);
                _envoyerMedia(TypeMessagePrive.document, 'document.pdf'); }),
          _mitem(Icons.photo_library_outlined, 'Photos et vidéos',
              const Color(0xFF00A884), () { Navigator.pop(context);
                _envoyerMedia(TypeMessagePrive.image, 'photo.jpg'); }),
          _mitem(Icons.camera_alt_outlined, 'Caméra',
              const Color(0xFFDC3545), () { Navigator.pop(context);
                _snack('📸 Caméra...'); }),
          _mitem(Icons.headphones_outlined, 'Audio',
              const Color(0xFFFF6B35), () { Navigator.pop(context);
                _envoyerMedia(TypeMessagePrive.vocal, '00:15'); }),
          _mitem(Icons.person_outline_rounded, 'Contact',
              const Color(0xFF0DCAF0), () { Navigator.pop(context);
                _snack('👤 Contact'); }),
          _mitem(Icons.poll_outlined, 'Sondage',
              const Color(0xFF0D6EFD), () { Navigator.pop(context);
                _snack('📊 Sondage'); }),
          _mitem(Icons.event_outlined, 'Événement',
              const Color(0xFFFFB800), () { Navigator.pop(context);
                _snack('📅 Événement'); }),
          _mitem(Icons.add_circle_outline_rounded, 'Nouveau sticker',
              const Color(0xFF20C997), () { Navigator.pop(context);
                setState(() { _showSticker = true; _showEmoji = false; }); }),
          const SizedBox(height: 8),
        ])));
  }

  Widget _mitem(IconData icon, String label, Color color,
      VoidCallback onTap) => ListTile(
    leading: Container(width: 40, height: 40,
      decoration: BoxDecoration(color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 20)),
    title: Text(label, style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500)),
    onTap: onTap);

  void _transferer(MessagePrive msg) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.all(14),
            child: Text('Transférer à...', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800))),
          const Divider(height: 1),
          ListTile(
            leading: Container(width: 42, height: 42,
              decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('💬',
                  style: TextStyle(fontSize: 22)))),
            title: const Text('Partager sur WhatsApp',
                style: TextStyle(fontWeight: FontWeight.w700)),
            onTap: () { Navigator.pop(context);
              _snack('✅ Ouverture WhatsApp...'); }),
          const Divider(height: 1),
          Expanded(child: ListView.builder(
            itemCount: conversationsPrivees.length,
            itemBuilder: (_, i) {
              final c = conversationsPrivees[i];
              if (c.id == _conv.id) return const SizedBox();
              return ListTile(
                leading: Container(width: 38, height: 38,
                  decoration: BoxDecoration(
                      color: AppPalette.blue.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Center(child: Text(c.contact.initiales,
                      style: const TextStyle(fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.blue)))),
                title: Text(c.contact.nomComplet,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () { Navigator.pop(context);
                  c.messages.add(MessagePrive(
                    id: 'T${DateTime.now().millisecondsSinceEpoch}',
                    texte: '↩️ Transféré : ${msg.texte}',
                    heure: _now(), type: TypeMessagePrive.texte,
                    estMoi: true));
                  _snack('✅ Transféré !'); });
            })),
        ])));
  }

  void _envoyer() {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() {
      _conv.messages.add(MessagePrive(
        id: 'M${DateTime.now().millisecondsSinceEpoch}',
        texte: _msgCtrl.text.trim(), heure: _now(),
        type: TypeMessagePrive.texte, estMoi: true));
    });
    _msgCtrl.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollBas);
    widget.onUpdate();
  }

  void _envoyerSticker(String e) {
    setState(() {
      _conv.messages.add(MessagePrive(
        id: 'S${DateTime.now().millisecondsSinceEpoch}',
        texte: e, heure: _now(),
        type: TypeMessagePrive.sticker, estMoi: true));
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollBas);
  }

  void _envoyerMedia(TypeMessagePrive type, String nom) {
    setState(() {
      _conv.messages.add(MessagePrive(
        id: 'MD${DateTime.now().millisecondsSinceEpoch}',
        texte: nom, heure: _now(), type: type, estMoi: true));
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollBas);
  }

  void _voirProfil() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 18),
          Container(width: 68, height: 68,
            decoration: BoxDecoration(
                color: AppPalette.blue.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Center(child: Text(_contact.initiales,
                style: const TextStyle(fontSize: 24,
                    fontWeight: FontWeight.bold, color: AppPalette.blue)))),
          const SizedBox(height: 10),
          Text(_contact.nomComplet, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(_contact.filiere, style: const TextStyle(
              fontSize: 13, color: Color(0xFF64748B))),
          Text(_contact.niveau, style: const TextStyle(
              fontSize: 12, color: Color(0xFF94A3B8))),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.badge_rounded,
                  color: Color(0xFF64748B), size: 14),
              const SizedBox(width: 8),
              Text(_contact.matricule, style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  fontFamily: 'monospace')),
            ])),
        ])));
  }

  void _effacer() {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Effacer la discussion ?'),
      content: const Text('Tous les messages seront supprimés.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () { Navigator.pop(context);
            setState(() => _conv.messages.clear()); },
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white),
          child: const Text('Effacer')),
      ]));
  }

  Widget _separateurDate(String d) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFD9F2E4),
          borderRadius: BorderRadius.circular(8)),
      child: Text(d, style: const TextStyle(fontSize: 12,
          color: Color(0xFF54656F), fontWeight: FontWeight.w500)))));

  String _now() =>
      '${TimeOfDay.now().hour.toString().padLeft(2,'0')}:${TimeOfDay.now().minute.toString().padLeft(2,'0')}';

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppPalette.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))));
}

// ════════════════════════════════════════════════════════════════════════════
// BULLE MESSAGE — StatefulWidget séparé pour éviter erreur mouse_tracker
// ════════════════════════════════════════════════════════════════════════════
class _BulleMessage extends StatefulWidget {
  final MessagePrive message;
  final ContactEtudiant contact;
  final double maxWidth;
  final VoidCallback onMenuTap;
  final VoidCallback onProfilTap;

  const _BulleMessage({
    super.key,
    required this.message,
    required this.contact,
    required this.maxWidth,
    required this.onMenuTap,
    required this.onProfilTap,
  });

  @override
  State<_BulleMessage> createState() => _BulleMessageState();
}

class _BulleMessageState extends State<_BulleMessage> {
  bool _hovered = false;

  MessagePrive get msg => widget.message;

  @override
  Widget build(BuildContext context) {
    final estMoi = msg.estMoi;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onLongPress: widget.onMenuTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: estMoi
                ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!estMoi) ...[
                GestureDetector(
                  onTap: widget.onProfilTap,
                  child: Container(width: 24, height: 24,
                    decoration: BoxDecoration(
                        color: AppPalette.blue.withOpacity(0.15),
                        shape: BoxShape.circle),
                    child: Center(child: Text(widget.contact.initiales,
                        style: const TextStyle(fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.blue))))),
                const SizedBox(width: 4),
              ],
              // Flèche gauche (messages envoyés)
              if (estMoi && _hovered)
                GestureDetector(
                  onTap: widget.onMenuTap,
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
              else if (estMoi)
                const SizedBox(width: 24),

              // Bulle
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.maxWidth),
                child: Container(
                  decoration: BoxDecoration(
                    color: msg.type == TypeMessagePrive.sticker
                        ? Colors.transparent
                        : estMoi ? const Color(0xFFD9FDD3) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(8),
                      topRight: const Radius.circular(8),
                      bottomLeft: Radius.circular(estMoi ? 8 : 0),
                      bottomRight: Radius.circular(estMoi ? 0 : 8)),
                    boxShadow: msg.type == TypeMessagePrive.sticker ? null
                        : [BoxShadow(color: Colors.black.withOpacity(0.07),
                            blurRadius: 3, offset: const Offset(0, 1))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: msg.type == TypeMessagePrive.sticker
                            ? EdgeInsets.zero
                            : const EdgeInsets.fromLTRB(10, 7, 10, 2),
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

              // Flèche droite (messages reçus)
              if (!estMoi && _hovered)
                GestureDetector(
                  onTap: widget.onMenuTap,
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
              else if (!estMoi)
                const SizedBox(width: 24),

              if (estMoi) const SizedBox(width: 4),
            ]))));
  }

  Widget _contenu() {
    final estMoi = msg.estMoi;
    switch (msg.type) {
      case TypeMessagePrive.sticker:
        return Text(msg.texte, style: const TextStyle(fontSize: 52));
      case TypeMessagePrive.image:
        return Container(width: 200, height: 140,
          decoration: BoxDecoration(color: const Color(0xFFCCD0D5),
              borderRadius: BorderRadius.circular(6)),
          child: const Center(child: Icon(Icons.photo_rounded,
              size: 48, color: Color(0xFF8696A0))));
      case TypeMessagePrive.document:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFF7F66FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.insert_drive_file_rounded,
                size: 20, color: Color(0xFF7F66FF))),
          const SizedBox(width: 8),
          Flexible(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(msg.texte, style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600, color: Color(0xFF111B21)),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const Text('Document', style: TextStyle(
                fontSize: 11, color: Color(0xFF8696A0))),
          ])),
          const SizedBox(width: 6),
          const Icon(Icons.download_rounded,
              size: 16, color: Color(0xFF8696A0)),
        ]);
      case TypeMessagePrive.vocal:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.play_circle_filled_rounded,
              size: 32, color: Color(0xFF00A884)),
          const SizedBox(width: 6),
          SizedBox(width: 80,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFF8696A0).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2))),
              Text(msg.texte, style: const TextStyle(
                  fontSize: 10, color: Color(0xFF8696A0))),
            ])),
        ]);
      case TypeMessagePrive.lien:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.link_rounded, size: 16, color: Color(0xFF027EB5)),
          const SizedBox(width: 6),
          Flexible(child: Text(msg.texte, style: const TextStyle(
              fontSize: 13, color: Color(0xFF027EB5),
              decoration: TextDecoration.underline),
              maxLines: 2, overflow: TextOverflow.ellipsis)),
        ]);
      default:
        return Text(msg.texte, style: const TextStyle(
            fontSize: 14, color: Color(0xFF111B21), height: 1.4));
    }
  }
}

// Export pour usage depuis d'autres pages
class ConversationScreen extends StatelessWidget {
  final StudentProfile profile;
  final ConversationPrivee conversation;
  const ConversationScreen({
    super.key, required this.profile, required this.conversation});
  @override
  Widget build(BuildContext context) => _ConversationView(
    profile: profile, conversation: conversation,
    onBack: () => Navigator.pop(context), onUpdate: () {});
}

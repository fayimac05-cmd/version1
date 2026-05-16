import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import 'messages_screen.dart';

// ════════════════════════════════════════════════════════════════════════════
// PAGE CONVERSATION — Style WhatsApp Web
// ════════════════════════════════════════════════════════════════════════════
class ConversationScreen extends StatefulWidget {
  final StudentProfile profile;
  final ConversationPrivee conversation;
  const ConversationScreen({
    super.key, required this.profile, required this.conversation});
  @override State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode  = FocusNode();
  bool _hasText     = false;
  bool _showEmojiPicker   = false;
  bool _showStickerPicker = false;
  bool _showGifPicker     = false;
  MessagePrive? _messageEpingle;
  MessagePrive? _messageARepondre;

  ConversationPrivee get _conv => widget.conversation;
  ContactEtudiant   get _contact => _conv.contact;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() =>
        setState(() => _hasText = _msgCtrl.text.trim().isNotEmpty));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollBas());
    _messageEpingle = _conv.messages.where((m) => m.epingle).firstOrNull;
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollBas() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  bool get _isDesktop => MediaQuery.of(context).size.width > 600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBE5DD), // fond WhatsApp
      appBar: _buildAppBar(),
      body: Column(children: [
        if (_messageEpingle != null) _banniereEpingle(),
        // Messages
        Expanded(child: GestureDetector(
          onTap: () => setState(() {
            _showEmojiPicker   = false;
            _showStickerPicker = false;
            _showGifPicker     = false;
          }),
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            itemCount: _conv.messages.length,
            itemBuilder: (_, i) {
              final msg = _conv.messages[i];
              final showDate = i == 0;
              return Column(children: [
                if (showDate) _separateurDate('Aujourd\'hui'),
                _bulleMessage(msg),
              ]);
            }))),
        if (_messageARepondre != null) _banniereRepondre(),
        _zoneSaisie(),
        if (_showEmojiPicker) _panneauEmoji(),
        if (_showStickerPicker) _panneauStickers(),
        if (_showGifPicker) _panneauGIF(),
      ]),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────
  AppBar _buildAppBar() => AppBar(
    backgroundColor: const Color(0xFF1F2C34),
    foregroundColor: Colors.white,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
      onPressed: () => Navigator.pop(context)),
    titleSpacing: 0,
    title: GestureDetector(
      onTap: () => _voirProfil(),
      child: Row(children: [
        Container(width: 38, height: 38,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle),
          child: Center(child: Text(_contact.initiales, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold,
              color: Colors.white)))),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_contact.nomComplet, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600)),
          const Text('en ligne', style: TextStyle(
              fontSize: 11, color: Colors.white70)),
        ])),
      ])),
    actions: [
      IconButton(icon: const Icon(Icons.videocam_rounded, size: 22),
          onPressed: () => _snack('📹 Appel vidéo')),
      IconButton(icon: const Icon(Icons.call_rounded, size: 20),
          onPressed: () => _snack('📞 Appel')),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded),
        color: const Color(0xFF233138),
        onSelected: (v) {
          if (v == 'profil') _voirProfil();
          if (v == 'epingle') {}
          if (v == 'effacer') _effacerMessages();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'profil',
              child: Text('Voir le profil',
                  style: TextStyle(color: Colors.white))),
          PopupMenuItem(value: 'epingle',
              child: Text('Messages épinglés',
                  style: TextStyle(color: Colors.white))),
          PopupMenuItem(value: 'effacer',
              child: Text('Effacer la discussion',
                  style: TextStyle(color: Colors.white))),
        ]),
    ]);

  // ── Bannière épinglé ──────────────────────────────────────────────────
  Widget _banniereEpingle() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    color: const Color(0xFF1F2C34).withOpacity(0.95),
    child: Row(children: [
      Container(width: 3, height: 32,
          color: const Color(0xFF00A884),
          margin: const EdgeInsets.only(right: 10)),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Message épinglé', style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: Color(0xFF00A884))),
        Text(_messageEpingle!.texte, style: const TextStyle(
            fontSize: 12, color: Colors.white70),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
      const Icon(Icons.push_pin_rounded, color: Color(0xFF00A884), size: 16),
    ]));

  // ── Bannière répondre ─────────────────────────────────────────────────
  Widget _banniereRepondre() => Container(
    color: const Color(0xFF1F2C34),
    padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
    child: Row(children: [
      Container(width: 3, height: 36,
          color: const Color(0xFF00A884),
          margin: const EdgeInsets.only(right: 10)),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_messageARepondre!.estMoi ? 'Vous' : _contact.prenoms,
            style: const TextStyle(fontSize: 11,
                fontWeight: FontWeight.w700, color: Color(0xFF00A884))),
        Text(_messageARepondre!.texte, style: const TextStyle(
            fontSize: 12, color: Colors.white70),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
      IconButton(icon: const Icon(Icons.close_rounded,
          size: 18, color: Colors.white70),
          onPressed: () => setState(() => _messageARepondre = null)),
    ]));

  // ── BULLE MESSAGE ─────────────────────────────────────────────────────
  Widget _bulleMessage(MessagePrive msg) {
    final estMoi = msg.estMoi;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: estMoi
            ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!estMoi) ...[
            GestureDetector(
              onTap: () => _voirProfil(),
              child: Container(width: 26, height: 26,
                decoration: BoxDecoration(
                    color: AppPalette.blue.withOpacity(0.2),
                    shape: BoxShape.circle),
                child: Center(child: Text(_contact.initiales,
                    style: const TextStyle(fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white))))),
            const SizedBox(width: 4),
          ],
          GestureDetector(
            onLongPress: () => _menuMessage(msg),
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.68),
              decoration: BoxDecoration(
                color: msg.type == TypeMessagePrive.sticker
                    ? Colors.transparent
                    : estMoi
                        ? const Color(0xFFD9FDD3)
                        : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(8),
                  topRight: const Radius.circular(8),
                  bottomLeft: Radius.circular(estMoi ? 8 : 0),
                  bottomRight: Radius.circular(estMoi ? 0 : 8)),
                boxShadow: msg.type == TypeMessagePrive.sticker
                    ? null
                    : [BoxShadow(color: Colors.black.withOpacity(0.08),
                        blurRadius: 3, offset: const Offset(0, 1))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Réponse citée
                  if (_messageARepondre != null && false)
                    Container(
                      margin: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                        border: const Border(left: BorderSide(
                            color: Color(0xFF00A884), width: 3))),
                      child: Text('Réponse citée',
                          style: const TextStyle(fontSize: 12))),
                  // Contenu
                  Padding(
                    padding: msg.type == TypeMessagePrive.sticker
                        ? EdgeInsets.zero
                        : const EdgeInsets.fromLTRB(9, 7, 9, 3),
                    child: _contenuBulle(msg, estMoi)),
                  // Heure + statut
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
                      Text(msg.heure, style: TextStyle(fontSize: 10,
                          color: estMoi
                              ? const Color(0xFF667781)
                              : const Color(0xFF8696A0))),
                      if (estMoi) ...[
                        const SizedBox(width: 3),
                        Icon(msg.lu
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                            size: 14,
                            color: msg.lu
                                ? const Color(0xFF53BDEB)
                                : const Color(0xFF8696A0)),
                      ],
                      if (msg.epingle) ...[
                        const SizedBox(width: 3),
                        const Icon(Icons.push_pin_rounded,
                            size: 11, color: Color(0xFF8696A0)),
                      ],
                    ])),
                ])),
          ),
          if (estMoi) const SizedBox(width: 4),
        ]));
  }

  Widget _contenuBulle(MessagePrive msg, bool estMoi) {
    switch (msg.type) {
      case TypeMessagePrive.sticker:
        return Text(msg.texte, style: const TextStyle(fontSize: 52));

      case TypeMessagePrive.image:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 160, width: 220,
            decoration: BoxDecoration(
              color: const Color(0xFFCCD0D5),
              borderRadius: BorderRadius.circular(6)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.photo_rounded, size: 48,
                  color: Color(0xFF8696A0)),
              const SizedBox(height: 4),
              Text(msg.texte, style: const TextStyle(
                  fontSize: 11, color: Color(0xFF667781)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
        ]);

      case TypeMessagePrive.document:
        return Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF7F66FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.insert_drive_file_rounded,
                size: 22, color: Color(0xFF7F66FF))),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(msg.texte, style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600, color: Color(0xFF111B21)),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const Text('Document', style: TextStyle(
                fontSize: 11, color: Color(0xFF8696A0))),
          ])),
          const Icon(Icons.download_rounded,
              size: 18, color: Color(0xFF8696A0)),
        ]);

      case TypeMessagePrive.vocal:
        return Row(children: [
          const Icon(Icons.play_circle_filled_rounded,
              size: 36, color: Color(0xFF00A884)),
          const SizedBox(width: 6),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 2, margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF8696A0).withOpacity(0.3),
                borderRadius: BorderRadius.circular(2))),
            Text(msg.texte, style: const TextStyle(
                fontSize: 11, color: Color(0xFF8696A0))),
          ])),
        ]);

      case TypeMessagePrive.video:
        return Container(width: 220, height: 130,
          decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(6)),
          child: const Center(child: Icon(Icons.play_circle_outline_rounded,
              color: Colors.white, size: 48)));

      case TypeMessagePrive.lien:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(6)),
            child: Row(children: [
              const Icon(Icons.link_rounded, size: 18, color: Color(0xFF00A884)),
              const SizedBox(width: 6),
              Expanded(child: Text(msg.texte, style: const TextStyle(
                  fontSize: 12, color: Color(0xFF027EB5),
                  decoration: TextDecoration.underline),
                  maxLines: 2, overflow: TextOverflow.ellipsis)),
            ])),
        ]);

      default:
        return Text(msg.texte, style: const TextStyle(
            fontSize: 14, color: Color(0xFF111B21), height: 1.4));
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // ZONE SAISIE — Style WhatsApp
  // ════════════════════════════════════════════════════════════════════════
  Widget _zoneSaisie() => Container(
    color: const Color(0xFF1F2C34),
    padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      // ── Bouton émoji/sticker/GIF ─────────────────────────────────
      _iconBtn(Icons.emoji_emotions_outlined, () => setState(() {
        _showEmojiPicker   = !_showEmojiPicker;
        _showStickerPicker = false;
        _showGifPicker     = false;
      })),
      const SizedBox(width: 6),

      // ── Champ texte ───────────────────────────────────────────────
      Expanded(child: Container(
        constraints: const BoxConstraints(maxHeight: 120),
        decoration: BoxDecoration(
          color: const Color(0xFF2A3942),
          borderRadius: BorderRadius.circular(24)),
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.enter &&
                  !HardwareKeyboard.instance.isShiftPressed) {
                _envoyer();
              }
            }
          },
          child: TextField(
            controller: _msgCtrl,
            focusNode: _focusNode,
            maxLines: null,
            style: const TextStyle(fontSize: 14, color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Message...',
              hintStyle: TextStyle(fontSize: 14, color: Color(0xFF8696A0)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10))),
        ))),
      const SizedBox(width: 6),

      // ── Bouton + (pièces jointes) ─────────────────────────────────
      if (!_hasText)
        _iconBtn(Icons.add_rounded, _menuPieceJointe),
      if (!_hasText) const SizedBox(width: 6),

      // ── Micro (pas de texte) ou Envoyer (avec texte) ──────────────
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _hasText
            ? GestureDetector(
                key: const ValueKey('send'),
                onTap: _envoyer,
                child: Container(width: 44, height: 44,
                  decoration: const BoxDecoration(
                      color: Color(0xFF00A884), shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20)))
            : GestureDetector(
                key: const ValueKey('mic'),
                onTap: () => _envoyerMedia(TypeMessagePrive.vocal, '00:08'),
                child: Container(width: 44, height: 44,
                  decoration: const BoxDecoration(
                      color: Color(0xFF00A884), shape: BoxShape.circle),
                  child: const Icon(Icons.mic_rounded,
                      color: Colors.white, size: 22))),
      ),
    ]));

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: SizedBox(width: 38, height: 38,
      child: Icon(icon, color: const Color(0xFF8696A0), size: 24)));

  // ════════════════════════════════════════════════════════════════════════
  // PANNEAUX EMOJI / STICKER / GIF
  // ════════════════════════════════════════════════════════════════════════
  Widget _panneauEmoji() => Container(
    height: 240, color: const Color(0xFF1F2C34),
    child: Column(children: [
      // Onglets
      Container(height: 40, color: const Color(0xFF2A3942),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _ongletEmoji(Icons.access_time_rounded, 'Récents', 0),
          _ongletEmoji(Icons.emoji_emotions_outlined, 'Émojis', 1),
          _ongletEmoji(Icons.gif_box_outlined, 'GIF', 2),
          _ongletEmoji(Icons.sticky_note_2_outlined, 'Stickers', 3),
          _ongletEmoji(Icons.add_circle_outline_rounded, 'Créer', 4),
        ])),
      Expanded(child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8, mainAxisSpacing: 4, crossAxisSpacing: 4),
        itemCount: _emojisFrequents.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () {
            setState(() {
              _msgCtrl.text += _emojisFrequents[i];
              _msgCtrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: _msgCtrl.text.length));
            });
          },
          child: Center(child: Text(_emojisFrequents[i],
              style: const TextStyle(fontSize: 22)))))),
    ]));

  Widget _ongletEmoji(IconData icon, String label, int idx) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, color: const Color(0xFF8696A0), size: 20),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 8,
          color: Color(0xFF8696A0))),
    ]);

  Widget _panneauStickers() {
    const predefinis = ['😂', '🔥', '💯', '🎉', '👑', '💪', '😍', '🤣',
      '😭', '🙏', '😤', '🥳', '😎', '🤔', '😅', '✨', '💀', '🫡',
      '🤯', '😴', '🫶', '❤️', '💚', '💙', '⭐', '🌟', '🎯', '🏆',
      '🐱', '🐶', '🦁', '🐸', '🍕', '🎮', '🚀', '🌈'];
    return Container(
      height: 240, color: const Color(0xFF1F2C34),
      child: Column(children: [
        Container(height: 40, color: const Color(0xFF2A3942),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            const Icon(Icons.access_time_rounded,
                color: Color(0xFF8696A0), size: 18),
            const SizedBox(width: 8),
            const Expanded(child: TextField(
              style: TextStyle(fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher dans les stickers...',
                hintStyle: TextStyle(fontSize: 12, color: Color(0xFF8696A0)),
                border: InputBorder.none))),
            GestureDetector(
              onTap: () => _snack('📸 Créer un nouveau sticker'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFF00A884).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, color: Color(0xFF00A884), size: 14),
                  SizedBox(width: 3),
                  Text('Créer', style: TextStyle(fontSize: 11,
                      color: Color(0xFF00A884), fontWeight: FontWeight.w700)),
                ]))),
          ])),
        Expanded(child: GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8),
          itemCount: predefinis.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () {
              setState(() => _showStickerPicker = false);
              _envoyerSticker(predefinis[i]);
            },
            child: Container(
              decoration: BoxDecoration(
                  color: const Color(0xFF2A3942),
                  borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(predefinis[i],
                  style: const TextStyle(fontSize: 28))))))),
      ]),
    );
  }

  Widget _panneauGIF() => Container(
    height: 240, color: const Color(0xFF1F2C34),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('GIF', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 8),
      const Text('Fonctionnalité GIF bientôt disponible',
          style: TextStyle(fontSize: 13, color: Color(0xFF8696A0))),
    ])));

  // ── Menu pièces jointes ───────────────────────────────────────────────
  void _menuPieceJointe() {
    showModalBottomSheet(context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFF233138),
            borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          // Menu items style WhatsApp
          _menuItem(Icons.insert_drive_file_outlined, 'Document',
              const Color(0xFF7F66FF), () {
            Navigator.pop(context);
            _envoyerMedia(TypeMessagePrive.document, 'document.pdf');
          }),
          _menuItem(Icons.photo_library_outlined, 'Photos et vidéos',
              const Color(0xFF00A884), () {
            Navigator.pop(context);
            _envoyerMedia(TypeMessagePrive.image, 'photo.jpg');
          }),
          _menuItem(Icons.camera_alt_outlined, 'Caméra',
              const Color(0xFFDC3545), () {
            Navigator.pop(context);
            _snack('📸 Ouverture caméra...');
          }),
          _menuItem(Icons.headphones_outlined, 'Audio',
              const Color(0xFFFF6B35), () {
            Navigator.pop(context);
            _envoyerMedia(TypeMessagePrive.vocal, '00:15');
          }),
          _menuItem(Icons.person_outline_rounded, 'Contact',
              const Color(0xFF0DCAF0), () {
            Navigator.pop(context);
            _snack('👤 Partage de contact');
          }),
          _menuItem(Icons.poll_outlined, 'Sondage',
              const Color(0xFF0D6EFD), () {
            Navigator.pop(context);
            _snack('📊 Création de sondage');
          }),
          _menuItem(Icons.event_outlined, 'Événement',
              const Color(0xFFFFB800), () {
            Navigator.pop(context);
            _snack('📅 Création d\'événement');
          }),
          _menuItem(Icons.add_circle_outline_rounded, 'Nouveau sticker',
              const Color(0xFF20C997), () {
            Navigator.pop(context);
            setState(() => _showStickerPicker = true);
          }),
          const SizedBox(height: 12),
        ])));
  }

  Widget _menuItem(IconData icon, String label, Color color,
      VoidCallback onTap) => ListTile(
    leading: Container(width: 42, height: 42,
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 22)),
    title: Text(label, style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
    onTap: onTap);

  // ── Menu message (long press) ─────────────────────────────────────────
  void _menuMessage(MessagePrive msg) {
    showModalBottomSheet(context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
            color: Color(0xFF233138),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          // Picker émojis rapides
          Padding(padding: const EdgeInsets.all(16),
            child: _emojiPickerRapide(msg)),
          const Divider(height: 1, color: Colors.white12),
          _actionItem(Icons.reply_rounded, 'Répondre', Colors.white, () {
            Navigator.pop(context);
            setState(() => _messageARepondre = msg);
          }),
          _actionItem(Icons.forward_rounded, 'Transférer', Colors.white, () {
            Navigator.pop(context);
            _transfererMessage(msg);
          }),
          _actionItem(
            msg.epingle ? Icons.push_pin_outlined : Icons.push_pin_rounded,
            msg.epingle ? 'Désépingler' : 'Épingler',
            const Color(0xFF00A884), () {
              Navigator.pop(context);
              setState(() {
                msg.epingle = !msg.epingle;
                _messageEpingle = msg.epingle ? msg : null;
              });
            }),
          _actionItem(Icons.copy_rounded, 'Copier', Colors.white, () {
            Navigator.pop(context);
            Clipboard.setData(ClipboardData(text: msg.texte));
            _snack('Texte copié !');
          }),
          if (!msg.estMoi && msg.type == TypeMessagePrive.sticker)
            _actionItem(Icons.bookmark_add_rounded, 'Sauvegarder le sticker',
                Colors.white, () {
              Navigator.pop(context);
              if (!stickersSauvegardes.contains(msg.texte)) {
                stickersSauvegardes.add(msg.texte);
              }
              _snack('✅ Sticker sauvegardé !');
            }),
          if (msg.estMoi)
            _actionItem(Icons.delete_outline_rounded, 'Supprimer',
                const Color(0xFFEF4444), () {
              Navigator.pop(context);
              setState(() => _conv.messages.remove(msg));
            }),
          const SizedBox(height: 8),
        ])));
  }

  Widget _emojiPickerRapide(MessagePrive msg) {
    const emojis = ['❤️', '👍', '😂', '😮', '😢', '🙏', '🔥', '✅',
      '👎', '💯', '🎉', '👏', '🤣', '😍', '🤔', '😅'];
    return Wrap(spacing: 6, runSpacing: 6, children: emojis.map((e) =>
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
            setState(() {
              msg.reactions[e] = (msg.reactions[e] ?? 0) + 1;
            });
          },
          child: Container(width: 40, height: 40,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(e,
                style: const TextStyle(fontSize: 20)))))).toList());
  }

  Widget _actionItem(IconData icon, String label, Color color,
      VoidCallback onTap) => ListTile(
    leading: Icon(icon, color: color, size: 20),
    title: Text(label, style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500, color: color)),
    onTap: onTap);

  // ── Transfert ─────────────────────────────────────────────────────────
  void _transfererMessage(MessagePrive msg) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
            color: Color(0xFF1F2C34),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.all(16),
            child: Text('Transférer à...', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: Colors.white))),
          const Divider(height: 1, color: Colors.white12),
          // WhatsApp
          ListTile(
            leading: Container(width: 44, height: 44,
              decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('💬',
                  style: TextStyle(fontSize: 22)))),
            title: const Text('Partager sur WhatsApp',
                style: TextStyle(fontWeight: FontWeight.w700,
                    color: Colors.white)),
            subtitle: const Text('Ouvre WhatsApp avec le message',
                style: TextStyle(color: Color(0xFF8696A0))),
            onTap: () { Navigator.pop(context);
              _snack('✅ Ouverture WhatsApp...'); }),
          const Divider(height: 1, color: Colors.white12),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: conversationsPrivees.length,
            itemBuilder: (_, i) {
              final c = conversationsPrivees[i];
              if (c.id == _conv.id) return const SizedBox();
              return ListTile(
                leading: Container(width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: AppPalette.blue.withOpacity(0.15),
                      shape: BoxShape.circle),
                  child: Center(child: Text(c.contact.initiales,
                      style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.bold, color: Colors.white)))),
                title: Text(c.contact.nomComplet, style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  c.messages.add(MessagePrive(
                    id: 'T${DateTime.now().millisecondsSinceEpoch}',
                    texte: '↩️ Transféré : ${msg.texte}',
                    heure: _now(), type: TypeMessagePrive.texte,
                    estMoi: true));
                  _snack('✅ Message transféré !');
                });
            })),
        ])));
  }

  // ── Actions ───────────────────────────────────────────────────────────
  void _envoyer() {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() {
      _conv.messages.add(MessagePrive(
        id: 'M${DateTime.now().millisecondsSinceEpoch}',
        texte: _msgCtrl.text.trim(),
        heure: _now(),
        type: TypeMessagePrive.texte, estMoi: true));
      _messageARepondre = null;
    });
    _msgCtrl.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollBas);
  }

  void _envoyerSticker(String emoji) {
    setState(() {
      _showStickerPicker = false;
      _conv.messages.add(MessagePrive(
        id: 'S${DateTime.now().millisecondsSinceEpoch}',
        texte: emoji, heure: _now(),
        type: TypeMessagePrive.sticker, estMoi: true));
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollBas);
  }

  void _envoyerMedia(TypeMessagePrive type, String nom) {
    setState(() {
      _conv.messages.add(MessagePrive(
        id: 'MD${DateTime.now().millisecondsSinceEpoch}',
        texte: nom, heure: _now(),
        type: type, estMoi: true));
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollBas);
  }

  void _voirProfil() {
    showModalBottomSheet(context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfilEtudiant(
          contact: _contact,
          onMessage: () => Navigator.pop(context)));
  }

  void _effacerMessages() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF233138),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Effacer la discussion ?',
          style: TextStyle(color: Colors.white)),
      content: const Text('Tous les messages seront supprimés.',
          style: TextStyle(color: Color(0xFF8696A0))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF8696A0)))),
        ElevatedButton(
          onPressed: () { Navigator.pop(context);
            setState(() => _conv.messages.clear()); },
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white),
          child: const Text('Effacer')),
      ]));
  }

  Widget _separateurDate(String date) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: const Color(0xFFD9F2E4),
          borderRadius: BorderRadius.circular(8)),
      child: Text(date, style: const TextStyle(
          fontSize: 12, color: Color(0xFF54656F),
          fontWeight: FontWeight.w500)))));

  String _now() =>
      '${TimeOfDay.now().hour.toString().padLeft(2,'0')}:${TimeOfDay.now().minute.toString().padLeft(2,'0')}';

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg),
          backgroundColor: const Color(0xFF00A884),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))));

  // ── Émojis fréquents ──────────────────────────────────────────────────
  static const _emojisFrequents = [
    '😀','😃','😄','😁','😆','😅','🤣','😂','🙂','🙃','😉','😊','😇',
    '🥰','😍','🤩','😘','😗','😚','😙','😋','😛','😜','🤪','😝','🤑',
    '🤗','🤭','🤫','🤔','🤐','🤨','😐','😑','😶','😏','😒','🙄','😬',
    '🤥','😌','😔','😪','🤤','😴','😷','🤒','🤕','🤢','🤧','🥵','🥶',
    '🥴','😵','🤯','🤠','🥳','😎','🤓','🧐','😕','😟','🙁','☹️','😮',
    '😯','😲','😳','🥺','😦','😧','😨','😰','😥','😢','😭','😱','😖',
    '😣','😞','😓','😩','😫','🥱','😤','😡','😠','🤬','😈','👿','💀',
    '☠️','💩','🤡','👹','👺','👻','👽','👾','🤖','😺','😸','😹','😻',
    '👍','👎','👊','✊','🤛','🤜','🤞','✌️','🤟','🤘','👌','🤌','🤏',
    '👈','👉','👆','🖕','👇','☝️','👋','🤚','🖐️','✋','🖖','🤙','💪',
    '❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔','❣️','💕','💞',
    '💓','💗','💖','💘','💝','💟','☮️','✝️','☪️','🕉️','✡️','🔯','🆘',
  ];
}

// ════════════════════════════════════════════════════════════════════════════
// PROFIL ÉTUDIANT
// ════════════════════════════════════════════════════════════════════════════
class _ProfilEtudiant extends StatelessWidget {
  final ContactEtudiant contact;
  final VoidCallback onMessage;
  const _ProfilEtudiant({required this.contact, required this.onMessage});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
        color: Color(0xFF233138),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    padding: const EdgeInsets.all(20),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 40, height: 4, decoration: BoxDecoration(
          color: Colors.white24, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 20),
      Container(width: 80, height: 80,
        decoration: BoxDecoration(
            color: AppPalette.blue.withOpacity(0.2),
            shape: BoxShape.circle),
        child: Center(child: Text(contact.initiales, style: const TextStyle(
            fontSize: 28, fontWeight: FontWeight.bold,
            color: Colors.white)))),
      const SizedBox(height: 12),
      Text(contact.nomComplet, style: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 4),
      Text(contact.filiere, style: const TextStyle(
          fontSize: 13, color: Color(0xFF8696A0))),
      Text(contact.niveau, style: const TextStyle(
          fontSize: 12, color: Color(0xFF8696A0))),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.badge_rounded,
              color: Color(0xFF8696A0), size: 16),
          const SizedBox(width: 8),
          Text(contact.matricule, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: Colors.white, fontFamily: 'monospace')),
        ])),
      const SizedBox(height: 14),
      GestureDetector(
        onTap: onMessage,
        child: Container(width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
              color: const Color(0xFF00A884),
              borderRadius: BorderRadius.circular(12)),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Envoyer un message', style: TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700, color: Colors.white)),
          ]))),
    ]));
}

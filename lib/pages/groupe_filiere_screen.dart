import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import 'messages_screen.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES
// ════════════════════════════════════════════════════════════════════════════
enum TypeMessage { texte, photo, video, document, vocal, sticker }

class _Membre {
  final String nom, prenoms, matricule;
  final String role;       // 'etudiant' | 'delegue' | 'delegue_adjoint'
  final String? filiereRole;
  const _Membre({required this.nom, required this.prenoms,
      required this.matricule,
      this.role = 'etudiant', this.filiereRole});
  String get initiales =>
      '${prenoms.isNotEmpty ? prenoms[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'
          .toUpperCase();
  String get nomComplet => '$prenoms $nom';

  bool get estDelegue => role == 'delegue' || role == 'delegue_adjoint';

  String get badgeEmoji {
    switch (role) {
      case 'delegue':         return '🎖️';
      case 'delegue_adjoint': return '🏅';
      default:                return '';
    }
  }

  String get badgeLabel {
    switch (role) {
      case 'delegue':         return 'Délégué(e)';
      case 'delegue_adjoint': return 'Adjoint(e)';
      default:                return '';
    }
  }
}

class _MessageGroupe {
  final String id;
  final _Membre auteur;
  String contenu;
  final TypeMessage type;
  final DateTime heure;
  Map<String, int> reactions;
  final bool estMoi;
  bool epingle;
  bool important;

  _MessageGroupe({
    required this.id, required this.auteur, required this.contenu,
    required this.type, required this.heure,
    required this.reactions, required this.estMoi,
    this.epingle = false, this.important = false,
  });

  _MessageGroupe copyWith({Map<String, int>? reactions}) => _MessageGroupe(
    id: id, auteur: auteur, contenu: contenu, type: type,
    heure: heure, reactions: reactions ?? this.reactions,
    estMoi: estMoi, epingle: epingle, important: important,
  );
}

// ════════════════════════════════════════════════════════════════════════════
// PAGE GROUPE FILIÈRE
// ════════════════════════════════════════════════════════════════════════════
class GroupeFiliere extends StatefulWidget {
  final StudentProfile profile;
  const GroupeFiliere({super.key, required this.profile});
  @override State<GroupeFiliere> createState() => _GroupeFiliereState();
}

class _GroupeFiliereState extends State<GroupeFiliere> {
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _hasText     = false;
  bool _showEmoji   = false;
  bool _showSticker = false;
  bool _enregistrement = false;

  final List<_Membre> _membres = const [
    _Membre(nom: 'KOURAOGO',  prenoms: 'Ibrahim',  matricule: '24IST-O2/1851',
        role: 'delegue', filiereRole: 'Réseaux Informatiques et Télécom'),
    _Membre(nom: 'TRAORÉ',    prenoms: 'Fatimata', matricule: '24IST-O2/1234',
        role: 'delegue_adjoint', filiereRole: 'Réseaux Informatiques et Télécom'),
    _Membre(nom: 'OUÉDRAOGO', prenoms: 'Salif',    matricule: '24IST-O2/1102'),
    _Membre(nom: 'KABORÉ',    prenoms: 'Aminata',  matricule: '24IST-O2/1456'),
    _Membre(nom: 'ZONGO',     prenoms: 'Daouda',   matricule: '24IST-O2/1789'),
    _Membre(nom: 'SAWADOGO',  prenoms: 'Raïssa',   matricule: '24IST-O2/1320'),
  ];

  late List<_MessageGroupe> _messages;

  @override
  void initState() {
    super.initState();
    _messages = _messagesSimules();
    _inputCtrl.addListener(() =>
        setState(() => _hasText = _inputCtrl.text.trim().isNotEmpty));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollBas());
  }

  @override
  void dispose() {
    _inputCtrl.dispose(); _scrollCtrl.dispose();
    super.dispose();
  }

  _Membre get _moi => _Membre(
    nom: widget.profile.nom,
    prenoms: widget.profile.prenoms,
    matricule: widget.profile.matricule,
  );

  List<_MessageGroupe> _messagesSimules() => [
    _MessageGroupe(id: '1', auteur: _membres[1],
        contenu: 'Salut tout le monde ! Quelqu\'un a compris le TP de BDD ?',
        type: TypeMessage.texte, heure: _heure(120),
        reactions: {'👍': 1}, estMoi: false),
    _MessageGroupe(id: '2', auteur: _membres[2],
        contenu: 'Moi pas du tout 😅 Le prof est allé trop vite',
        type: TypeMessage.texte, heure: _heure(115),
        reactions: {}, estMoi: false),
    _MessageGroupe(id: '3', auteur: _membres[0],
        contenu: 'J\'ai mes notes du cours, je peux partager',
        type: TypeMessage.texte, heure: _heure(110),
        reactions: {'❤️': 1, '🙏': 1},
        estMoi: widget.profile.matricule == _membres[0].matricule),
    _MessageGroupe(id: '4', auteur: _membres[3],
        contenu: 'Notes_BDD_S3.pdf',
        type: TypeMessage.document, heure: _heure(108),
        reactions: {'👍': 1}, estMoi: false),
    _MessageGroupe(id: '5', auteur: _membres[4],
        contenu: 'Merci ! Et pour Réseaux, le DS c\'est quand ?',
        type: TypeMessage.texte, heure: _heure(60),
        reactions: {}, estMoi: false),
    _MessageGroupe(id: '6', auteur: _membres[5],
        contenu: 'Vendredi 02 Mai d\'après le programme',
        type: TypeMessage.texte, heure: _heure(55),
        reactions: {'😮': 1}, estMoi: false),
    _MessageGroupe(id: '7', auteur: _membres[0],
        contenu: 'On peut organiser une séance de révision demain ?',
        type: TypeMessage.texte, heure: _heure(30),
        reactions: {'👍': 2},
        estMoi: widget.profile.matricule == _membres[0].matricule),
    _MessageGroupe(id: '8', auteur: _membres[1],
        contenu: 'Yes ! 14h à la bibliothèque ça vous va ?',
        type: TypeMessage.texte, heure: _heure(25),
        reactions: {'👍': 1}, estMoi: false),
  ];

  DateTime _heure(int min) =>
      DateTime.now().subtract(Duration(minutes: min));

  void _scrollBas() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filiere = widget.profile.filiere.isNotEmpty
        ? widget.profile.filiere : 'Réseaux Informatiques et Télécom';

    return Scaffold(
      backgroundColor: const Color(0xFFEBE5DD),
      body: Column(children: [
        _header(filiere),
        _banniere(),
        Expanded(child: GestureDetector(
          onTap: () => setState(() {
            _showEmoji = false; _showSticker = false;
          }),
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            itemCount: _messages.length,
            itemBuilder: (_, i) => Column(children: [
              if (i == 0) _separateurDate(_messages[i].heure),
              // ← StatefulWidget séparé pour éviter mouse_tracker error
              _BulleGroupe(
                key: ValueKey(_messages[i].id),
                message: _messages[i],
                moi: _moi,
                maxWidth: MediaQuery.of(context).size.width * 0.65,
                onMenu: () => _menuMsg(_messages[i]),
                onProfil: () => _voirProfilMembre(_messages[i].auteur),
              ),
            ])))),
        _zoneSaisie(),
        if (_showEmoji) _panneauEmoji(),
        if (_showSticker) _panneauStickers(),
      ]),
    );
  }

  Widget _header(String filiere) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [AppPalette.blue, Color(0xFF1565C0)],
          begin: Alignment.topLeft, end: Alignment.bottomRight)),
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back_ios_new,
            color: Colors.white, size: 18)),
      const SizedBox(width: 10),
      Container(width: 46, height: 46,
        decoration: BoxDecoration(color: AppPalette.yellow,
            borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.groups_rounded,
            color: AppPalette.blue, size: 26)),
      const SizedBox(width: 12),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(filiere, style: const TextStyle(fontSize: 15,
            fontWeight: FontWeight.bold, color: Colors.white),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        Row(children: [
          Container(width: 7, height: 7,
            decoration: const BoxDecoration(
                color: Color(0xFF4ADE80), shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text('${_membres.length} membres',
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10)),
            child: const Row(children: [
              Icon(Icons.lock_outline, color: Colors.white, size: 10),
              SizedBox(width: 3),
              Text('100% Privé', style: TextStyle(
                  fontSize: 9, color: Colors.white,
                  fontWeight: FontWeight.w600)),
            ])),
        ]),
      ])),
      GestureDetector(
        onTap: _voirMembres,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.people_outline,
              color: Colors.white, size: 20))),
    ]));

  Widget _banniere() => Container(
    color: AppPalette.blue.withOpacity(0.07),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    child: const Row(children: [
      Icon(Icons.shield_outlined, color: AppPalette.blue, size: 13),
      SizedBox(width: 8),
      Expanded(child: Text(
        'Messages visibles uniquement par les étudiants de cette filière',
        style: TextStyle(fontSize: 11, color: AppPalette.blue,
            fontWeight: FontWeight.w500))),
    ]));

  // ── Menu message ──────────────────────────────────────────────────────
  void _menuMsg(_MessageGroupe msg) {
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
          // Émojis rapides
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...['👍','❤️','😂','😮','😢','🙏'].map((e) =>
                    GestureDetector(
                      onTap: () { Navigator.pop(context);
                        setState(() {
                          final idx = _messages.indexWhere(
                              (m) => m.id == msg.id);
                          if (idx != -1) {
                            final r = Map<String, int>.from(
                                _messages[idx].reactions);
                            r[e] = (r[e] ?? 0) + 1;
                            _messages[idx] = _messages[idx].copyWith(
                                reactions: r);
                          }
                        }); },
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
            Clipboard.setData(ClipboardData(text: msg.contenu));
            _snack('Texte copié !'); }),
          _act(Icons.forward_rounded, 'Transférer',
              const Color(0xFF54656F), () { Navigator.pop(context);
                _transferer(msg); }),
          _act(msg.epingle ? Icons.push_pin_outlined : Icons.push_pin_rounded,
            msg.epingle ? 'Désépingler' : 'Épingler',
            const Color(0xFF54656F), () { Navigator.pop(context);
              setState(() => msg.epingle = !msg.epingle); }),
          _act(msg.important
              ? Icons.star_rounded : Icons.star_outline_rounded,
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
            _act(Icons.person_outline_rounded,
                'Voir le profil de ${msg.auteur.prenoms}',
                AppPalette.blue, () { Navigator.pop(context);
                  _voirProfilMembre(msg.auteur); }),
          if (!msg.estMoi)
            _act(Icons.chat_bubble_outline_rounded,
                'Écrire en privé à ${msg.auteur.prenoms}',
                AppPalette.blue, () { Navigator.pop(context);
                  _ecrireEnPrive(msg.auteur); }),
          if (!msg.estMoi)
            _act(Icons.flag_outlined, 'Signaler',
                const Color(0xFFDC2626), () { Navigator.pop(context);
                  _snack('⚠️ Message signalé.'); }),
          if (msg.type == TypeMessage.sticker && !msg.estMoi)
            _act(Icons.bookmark_add_rounded, 'Sauvegarder le sticker',
                const Color(0xFF54656F), () { Navigator.pop(context);
                  if (!stickersSauvegardes.contains(msg.contenu)) {
                    stickersSauvegardes.add(msg.contenu);
                  }
                  _snack('✅ Sticker sauvegardé !'); }),
          if (msg.estMoi)
            _act(Icons.delete_outline_rounded, 'Supprimer',
                const Color(0xFFDC2626), () { Navigator.pop(context);
                  setState(() => _messages.removeWhere(
                      (m) => m.id == msg.id)); }),
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

  void _tousEmojis(_MessageGroupe msg) {
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
                  setState(() {
                    final idx = _messages.indexWhere((m) => m.id == msg.id);
                    if (idx != -1) {
                      final r = Map<String, int>.from(
                          _messages[idx].reactions);
                      r[shown[i]] = (r[shown[i]] ?? 0) + 1;
                      _messages[idx] = _messages[idx].copyWith(reactions: r);
                    }
                  }); },
                child: Center(child: Text(shown[i],
                    style: const TextStyle(fontSize: 24)))))),
          ]));
      }));
  }

  // ── Zone saisie ───────────────────────────────────────────────────────
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
                !HardwareKeyboard.instance.isShiftPressed) _envoyerTexte();
          },
          child: TextField(
            controller: _inputCtrl, maxLines: null,
            style: const TextStyle(fontSize: 14, color: Color(0xFF111B21)),
            decoration: const InputDecoration(
              hintText: 'Message au groupe...',
              hintStyle: TextStyle(fontSize: 14, color: Color(0xFF8696A0)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10)))))),
      const SizedBox(width: 6),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: _hasText
            ? GestureDetector(key: const ValueKey('send'),
                onTap: _envoyerTexte,
                child: Container(width: 42, height: 42,
                  decoration: const BoxDecoration(
                      color: AppPalette.blue, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 19)))
            : GestureDetector(key: const ValueKey('mic'),
                onTap: () {
                  setState(() => _enregistrement = !_enregistrement);
                  if (_enregistrement) {
                    Future.delayed(const Duration(seconds: 3), () {
                      if (mounted && _enregistrement) {
                        setState(() => _enregistrement = false);
                        _simulerMedia(TypeMessage.vocal);
                      }
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: _enregistrement
                        ? const Color(0xFFDC2626) : AppPalette.blue,
                    shape: BoxShape.circle),
                  child: Icon(
                    _enregistrement ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white, size: 22)))),
    ]));

  Widget _icnBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: SizedBox(width: 34, height: 34,
      child: Icon(icon, color: const Color(0xFF667781), size: 22)));

  // ── Panneaux ──────────────────────────────────────────────────────────
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
              _inputCtrl.text += emojis[i];
              _inputCtrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: _inputCtrl.text.length));
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

  void _menuPieceJointe() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
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
                _simulerMedia(TypeMessage.document); }),
          _mitem(Icons.photo_library_outlined, 'Photos et vidéos',
              const Color(0xFF00A884), () { Navigator.pop(context);
                _simulerMedia(TypeMessage.photo); }),
          _mitem(Icons.camera_alt_outlined, 'Caméra',
              const Color(0xFFDC3545), () { Navigator.pop(context);
                _snack('📸 Caméra...'); }),
          _mitem(Icons.headphones_outlined, 'Audio',
              const Color(0xFFFF6B35), () { Navigator.pop(context);
                _simulerMedia(TypeMessage.vocal); }),
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
    leading: Container(width: 40, height: 40,
      decoration: BoxDecoration(color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 20)),
    title: Text(label, style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500)),
    onTap: onTap);

  void _transferer(_MessageGroupe msg) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
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
              return ListTile(
                leading: Container(width: 38, height: 38,
                  decoration: BoxDecoration(
                      color: AppPalette.blue.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Center(child: Text(c.contact.initiales,
                      style: const TextStyle(fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.blue)))),
                title: Text(c.contact.nomComplet),
                onTap: () { Navigator.pop(context);
                  c.messages.add(MessagePrive(
                    id: 'T${DateTime.now().millisecondsSinceEpoch}',
                    texte: '↩️ ${msg.contenu}',
                    heure: _nowStr(), type: TypeMessagePrive.texte,
                    estMoi: true));
                  _snack('✅ Transféré !'); });
            })),
        ])));
  }

  void _voirProfilMembre(_Membre m) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Container(width: 70, height: 70,
            decoration: BoxDecoration(
                color: AppPalette.blue.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Center(child: Text(m.initiales, style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold,
                color: AppPalette.blue)))),
          const SizedBox(height: 10),
          Text(m.nomComplet, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(m.matricule, style: const TextStyle(
              fontSize: 12, color: Color(0xFF64748B),
              fontFamily: 'monospace')),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () { Navigator.pop(context); _ecrireEnPrive(m); },
            child: Container(width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(color: AppPalette.blue,
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.chat_bubble_rounded,
                    color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text('Message privé', style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w700, color: Colors.white)),
              ]))),
        ])));
  }

  void _ecrireEnPrive(_Membre m) {
    final contact = tousLesEtudiants.where(
        (e) => e.matricule == m.matricule).firstOrNull;
    if (contact == null) { _snack('Contact non disponible'); return; }
    final exist = conversationsPrivees.where(
        (c) => c.contact.matricule == m.matricule).firstOrNull;
    if (exist == null) {
      conversationsPrivees.insert(0, ConversationPrivee(
        id: 'C${DateTime.now().millisecondsSinceEpoch}',
        contact: contact, messages: []));
    }
    _snack('💬 Conversation avec ${m.prenoms} disponible dans Messages');
  }

  void _voirMembres() {
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Text('Membres (${_membres.length})', style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC))),
            child: const Row(children: [
              Icon(Icons.lock_outline, color: Color(0xFF15803D), size: 14),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Groupe 100% privé — Visible uniquement par les membres',
                style: TextStyle(fontSize: 12, color: Color(0xFF15803D)))),
            ])),
          Expanded(child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _membres.length,
            separatorBuilder: (_, __) => const Divider(
                height: 1, color: Color(0xFFE2E8F0)),
            itemBuilder: (_, i) {
              final m = _membres[i];
              final estMoi = m.matricule == widget.profile.matricule;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: GestureDetector(
                  onTap: () => _voirProfilMembre(m),
                  child: Container(width: 42, height: 42,
                    decoration: const BoxDecoration(
                        color: AppPalette.yellow, shape: BoxShape.circle),
                    child: Center(child: Text(m.initiales,
                        style: const TextStyle(fontWeight: FontWeight.bold,
                            color: AppPalette.blue, fontSize: 14))))),
                title: Row(children: [
                  Text(m.nomComplet, style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
                  if (estMoi) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppPalette.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('Vous', style: TextStyle(
                          fontSize: 10, color: AppPalette.blue,
                          fontWeight: FontWeight.bold))),
                  ],
                  // Badge délégué dans la liste membres
                  if (m.estDelegue) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppPalette.yellow.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppPalette.blue.withOpacity(0.25))),
                      child: Text(
                        '${m.badgeEmoji} ${m.badgeLabel}',
                        style: const TextStyle(fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppPalette.blue))),
                  ],
                ]),
                subtitle: Text(m.matricule, style: const TextStyle(
                    fontSize: 11, color: Color(0xFF64748B))),
                trailing: estMoi ? null : GestureDetector(
                  onTap: () { Navigator.pop(context); _ecrireEnPrive(m); },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: AppPalette.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.chat_bubble_outline_rounded,
                        color: AppPalette.blue, size: 18))),
              );
            })),
        ])));
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  void _envoyerTexte() {
    final t = _inputCtrl.text.trim();
    if (t.isEmpty) return;
    _inputCtrl.clear();
    setState(() {
      _messages.add(_MessageGroupe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        auteur: _moi, contenu: t,
        type: TypeMessage.texte, heure: DateTime.now(),
        reactions: {}, estMoi: true));
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollBas);
  }

  void _envoyerSticker(String emoji) {
    setState(() {
      _messages.add(_MessageGroupe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        auteur: _moi, contenu: emoji,
        type: TypeMessage.sticker, heure: DateTime.now(),
        reactions: {}, estMoi: true));
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollBas);
  }

  void _simulerMedia(TypeMessage type) {
    String contenu;
    switch (type) {
      case TypeMessage.photo:    contenu = 'photo_révision.jpg'; break;
      case TypeMessage.video:    contenu = 'video_cours.mp4'; break;
      case TypeMessage.document: contenu = 'document_BDD.pdf'; break;
      case TypeMessage.vocal:    contenu = '00:08'; break;
      default:                   contenu = 'fichier';
    }
    setState(() {
      _messages.add(_MessageGroupe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        auteur: _moi, contenu: contenu,
        type: type, heure: DateTime.now(),
        reactions: {}, estMoi: true));
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollBas);
  }

  Widget _separateurDate(DateTime dt) {
    final now = DateTime.now();
    final label = _memeJour(dt, now) ? 'Aujourd\'hui'
        : _memeJour(dt, now.subtract(const Duration(days: 1))) ? 'Hier'
        : '${dt.day}/${dt.month}/${dt.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFD9F2E4),
            borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(fontSize: 12,
            color: Color(0xFF54656F), fontWeight: FontWeight.w500)))));
  }

  bool _memeJour(DateTime a, DateTime b) =>
      a.day == b.day && a.month == b.month && a.year == b.year;

  String _nowStr() {
    final t = TimeOfDay.now();
    return '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppPalette.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))));
}

// ════════════════════════════════════════════════════════════════════════════
// BULLE GROUPE — StatefulWidget séparé pour éviter mouse_tracker error
// ════════════════════════════════════════════════════════════════════════════
class _BulleGroupe extends StatefulWidget {
  final _MessageGroupe message;
  final _Membre moi;
  final double maxWidth;
  final VoidCallback onMenu;
  final VoidCallback onProfil;

  const _BulleGroupe({
    super.key,
    required this.message,
    required this.moi,
    required this.maxWidth,
    required this.onMenu,
    required this.onProfil,
  });

  @override
  State<_BulleGroupe> createState() => _BulleGroupeState();
}

class _BulleGroupeState extends State<_BulleGroupe> {
  bool _hovered = false;

  _MessageGroupe get msg => widget.message;

  @override
  Widget build(BuildContext context) {
    final estMoi = msg.estMoi;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onLongPress: widget.onMenu,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            mainAxisAlignment: estMoi
                ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!estMoi) ...[
                GestureDetector(
                  onTap: widget.onProfil,
                  child: Container(width: 28, height: 28,
                    decoration: BoxDecoration(
                        color: AppPalette.blue.withOpacity(0.15),
                        shape: BoxShape.circle),
                    child: Center(child: Text(msg.auteur.initiales,
                        style: const TextStyle(fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.blue))))),
                const SizedBox(width: 5),
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
                    color: msg.type == TypeMessage.sticker
                        ? Colors.transparent
                        : estMoi ? const Color(0xFFD9FDD3) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(8),
                      topRight: const Radius.circular(8),
                      bottomLeft: Radius.circular(estMoi ? 8 : 0),
                      bottomRight: Radius.circular(estMoi ? 0 : 8)),
                    boxShadow: msg.type == TypeMessage.sticker ? null
                        : [BoxShadow(color: Colors.black.withOpacity(0.07),
                            blurRadius: 3, offset: const Offset(0, 1))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!estMoi)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(msg.auteur.prenoms,
                                style: const TextStyle(fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppPalette.blue)),
                            // Badge délégué
                            if (msg.auteur.estDelegue) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                    color: AppPalette.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(5)),
                                child: Text(
                                  '${msg.auteur.badgeEmoji} ${msg.auteur.badgeLabel}',
                                  style: const TextStyle(fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppPalette.blue))),
                            ],
                          ])),
                      Padding(
                        padding: msg.type == TypeMessage.sticker
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
                          Text(_fmt(msg.heure), style: const TextStyle(
                              fontSize: 10, color: Color(0xFF667781))),
                          if (estMoi) ...[
                            const SizedBox(width: 3),
                            const Icon(Icons.done_all_rounded,
                                size: 13, color: Color(0xFF53BDEB)),
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

              if (estMoi) ...[
                const SizedBox(width: 4),
                Container(width: 28, height: 28,
                  decoration: const BoxDecoration(
                      color: AppPalette.yellow, shape: BoxShape.circle),
                  child: Center(child: Text(widget.moi.initiales,
                      style: const TextStyle(fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.blue)))),
              ],
            ]))));
  }

  Widget _contenu() {
    switch (msg.type) {
      case TypeMessage.sticker:
        return Text(msg.contenu, style: const TextStyle(fontSize: 52));
      case TypeMessage.photo:
        return Container(width: 200, height: 140,
          decoration: BoxDecoration(color: const Color(0xFFCCD0D5),
              borderRadius: BorderRadius.circular(6)),
          child: const Center(child: Icon(Icons.photo_rounded,
              size: 48, color: Color(0xFF8696A0))));
      case TypeMessage.video:
        return Container(width: 200, height: 130,
          decoration: BoxDecoration(color: Colors.black87,
              borderRadius: BorderRadius.circular(6)),
          child: const Center(child: Icon(
              Icons.play_circle_outline_rounded,
              color: Colors.white, size: 48)));
      case TypeMessage.document:
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
            Text(msg.contenu, style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600, color: Color(0xFF111B21)),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const Text('Document', style: TextStyle(
                fontSize: 11, color: Color(0xFF8696A0))),
          ])),
          const Icon(Icons.download_rounded,
              size: 16, color: Color(0xFF8696A0)),
        ]);
      case TypeMessage.vocal:
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
              Text(msg.contenu.replaceAll('vocal_', ''),
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF8696A0))),
            ])),
        ]);
      default:
        return Text(msg.contenu, style: const TextStyle(
            fontSize: 14, color: Color(0xFF111B21), height: 1.4));
    }
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
}

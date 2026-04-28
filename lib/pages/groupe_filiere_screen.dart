import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES
// ════════════════════════════════════════════════════════════════════════════
enum TypeMessage { texte, photo, video, document, vocal }

class _Membre {
  final String nom;
  final String prenoms;
  final String matricule;

  const _Membre({required this.nom, required this.prenoms, required this.matricule});

  String get initiales =>
      '${prenoms.isNotEmpty ? prenoms[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase();

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

  _MessageGroupe({
    required this.id,
    required this.auteur,
    required this.contenu,
    required this.type,
    required this.heure,
    required this.reactions,
    required this.estMoi,
  });

  _MessageGroupe copyWith({Map<String, String>? reactions}) => _MessageGroupe(
    id: id, auteur: auteur, contenu: contenu, type: type,
    heure: heure, reactions: reactions ?? this.reactions, estMoi: estMoi,
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

  final TextEditingController _inputCtrl  = TextEditingController();
  final ScrollController      _scrollCtrl = ScrollController();
  bool _enregistrement = false;

  // ── Membres simulés ──────────────────────────────────────────────────
  final List<_Membre> _membres = const [
    _Membre(nom: 'KOURAOGO',  prenoms: 'Ibrahim',  matricule: '24IST-O2/1851'),
    _Membre(nom: 'TRAORÉ',    prenoms: 'Fatimata', matricule: '24IST-O2/1234'),
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollBas());
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  _Membre get _moi => _Membre(
    nom: widget.profile.nom,
    prenoms: widget.profile.prenoms,
    matricule: widget.profile.matricule,
  );

  List<_MessageGroupe> _messagesSimules() {
    final membres = _membres;
    return [
      _MessageGroupe(id: '1', auteur: membres[1],
          contenu: 'Salut tout le monde ! Quelqu\'un a compris le TP de BDD sur les jointures ?',
          type: TypeMessage.texte, heure: _heure(-120),
          reactions: {'👍': membres[0].matricule}, estMoi: false),
      _MessageGroupe(id: '2', auteur: membres[2],
          contenu: 'Moi pas du tout 😅 Le prof est allé trop vite',
          type: TypeMessage.texte, heure: _heure(-115),
          reactions: {}, estMoi: false),
      _MessageGroupe(id: '3', auteur: membres[0],
          contenu: 'J\'ai mes notes du cours, je peux partager',
          type: TypeMessage.texte, heure: _heure(-110),
          reactions: {'❤️': membres[1].matricule, '🙏': membres[2].matricule},
          estMoi: widget.profile.matricule == membres[0].matricule),
      _MessageGroupe(id: '4', auteur: membres[3],
          contenu: 'Notes_BDD_S3.pdf',
          type: TypeMessage.document, heure: _heure(-108),
          reactions: {'👍': membres[1].matricule}, estMoi: false),
      _MessageGroupe(id: '5', auteur: membres[4],
          contenu: 'Merci beaucoup ! Et pour Réseaux, le DS c\'est quand ?',
          type: TypeMessage.texte, heure: _heure(-60),
          reactions: {}, estMoi: false),
      _MessageGroupe(id: '6', auteur: membres[5],
          contenu: 'Vendredi 02 Mai d\'après le programme',
          type: TypeMessage.texte, heure: _heure(-55),
          reactions: {'😮': membres[4].matricule}, estMoi: false),
      _MessageGroupe(id: '7', auteur: members(0),
          contenu: 'On peut organiser une séance de révision demain ?',
          type: TypeMessage.texte, heure: _heure(-30),
          reactions: {'👍': membres[1].matricule, '👍': membres[3].matricule},
          estMoi: widget.profile.matricule == membres[0].matricule),
      _MessageGroupe(id: '8', auteur: membres[1],
          contenu: 'Yes ! 14h à la bibliothèque ça vous va ?',
          type: TypeMessage.texte, heure: _heure(-25),
          reactions: {'👍': membres[2].matricule}, estMoi: false),
    ];
  }

  _Membre members(int i) => _membres[i];

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

  // ── Envoyer message texte ─────────────────────────────────────────────
  void _envoyerTexte() {
    final texte = _inputCtrl.text.trim();
    if (texte.isEmpty) return;
    _inputCtrl.clear();
    setState(() {
      _messages.add(_MessageGroupe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        auteur: _moi,
        contenu: texte,
        type: TypeMessage.texte,
        heure: DateTime.now(),
        reactions: {},
        estMoi: true,
      ));
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollBas);
  }

  // ── Simuler envoi média ───────────────────────────────────────────────
  void _simulerMedia(TypeMessage type) {
    Navigator.of(context).pop();
    String contenu;
    switch (type) {
      case TypeMessage.photo:    contenu = 'photo_révision.jpg'; break;
      case TypeMessage.video:    contenu = 'video_cours.mp4'; break;
      case TypeMessage.document: contenu = 'document_BDD.pdf'; break;
      case TypeMessage.vocal:    contenu = 'vocal_00:12'; break;
      default:                   contenu = 'fichier';
    }
    setState(() {
      _messages.add(_MessageGroupe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        auteur: _moi,
        contenu: contenu,
        type: type,
        heure: DateTime.now(),
        reactions: {},
        estMoi: true,
      ));
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollBas);
  }

  // ── Réaction emoji ────────────────────────────────────────────────────
  void _reagir(String msgId) {
    const emojis = ['❤️', '👍', '😂', '😮', '😢', '🙏'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12),
                blurRadius: 24)]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Réagir', style: TextStyle(fontSize: 15,
              color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: emojis.map((e) => GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                setState(() {
                  final idx = _messages.indexWhere((m) => m.id == msgId);
                  if (idx != -1) {
                    final newR = Map<String, String>.from(_messages[idx].reactions);
                    newR[e] = widget.profile.matricule;
                    _messages[idx] = _messages[idx].copyWith(reactions: newR);
                  }
                });
              },
              child: Container(width: 52, height: 52,
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(e,
                    style: const TextStyle(fontSize: 28)))),
            )).toList(),
          ),
        ]),
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
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(24)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Partager', style: TextStyle(fontSize: 18,
              fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _mediaBtn(Icons.photo_library_outlined, 'Photo',
                const Color(0xFF7C3AED),
                    () => _simulerMedia(TypeMessage.photo)),
            _mediaBtn(Icons.videocam_outlined, 'Vidéo',
                const Color(0xFFDC2626),
                    () => _simulerMedia(TypeMessage.video)),
            _mediaBtn(Icons.insert_drive_file_outlined, 'Document',
                AppPalette.blue,
                    () => _simulerMedia(TypeMessage.document)),
            _mediaBtn(Icons.mic_outlined, 'Vocal',
                const Color(0xFF15803D),
                    () => _simulerMedia(TypeMessage.vocal)),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _mediaBtn(IconData icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(width: 60, height: 60,
            decoration: BoxDecoration(color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 28)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w600, color: color)),
        ]),
      );

  // ── Liste membres ─────────────────────────────────────────────────────
  void _voirMembres() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        margin: const EdgeInsets.only(top: 60),
        decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24))),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Membres du groupe (${_membres.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC))),
            child: const Row(children: [
              Icon(Icons.lock_outline, color: Color(0xFF15803D), size: 16),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Groupe 100% privé — Visible uniquement par les membres',
                style: TextStyle(fontSize: 13, color: Color(0xFF15803D),
                    fontWeight: FontWeight.w500),
              )),
            ]),
          ),
          Expanded(child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: _membres.length,
            separatorBuilder: (_, __) => const Divider(height: 1,
                color: Color(0xFFE2E8F0)),
            itemBuilder: (_, i) {
              final m = _membres[i];
              final estMoi = m.matricule == widget.profile.matricule;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppPalette.yellow,
                  child: Text(m.initiales,
                      style: const TextStyle(fontWeight: FontWeight.bold,
                          color: AppPalette.blue, fontSize: 14)),
                ),
                title: Row(children: [
                  Text(m.nomComplet, style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                  if (estMoi) ...[
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppPalette.lightBlue,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text('Vous', style: TextStyle(fontSize: 11,
                          color: AppPalette.blue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ]),
                subtitle: Text(m.matricule, style: const TextStyle(
                    fontSize: 12, color: Color(0xFF64748B))),
              );
            },
          )),
        ]),
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
      body: Column(children: [

        // ── Header ────────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [AppPalette.blue, Color(0xFF1565C0)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Row(children: [
            // Avatar groupe
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppPalette.yellow,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppPalette.yellow.withOpacity(0.4),
                    blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.groups_rounded,
                  color: AppPalette.blue, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(filiere,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                      color: Colors.white, letterSpacing: -0.2),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Container(width: 8, height: 8,
                  decoration: const BoxDecoration(shape: BoxShape.circle,
                      color: Color(0xFF4ADE80))),
                const SizedBox(width: 6),
                Text('${_membres.length} membres',
                    style: const TextStyle(fontSize: 12,
                        color: Colors.white70)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(children: [
                    Icon(Icons.lock_outline, color: Colors.white, size: 11),
                    SizedBox(width: 4),
                    Text('100% Privé', style: TextStyle(fontSize: 10,
                        color: Colors.white, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ])),
            // Bouton membres
            GestureDetector(
              onTap: _voirMembres,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.people_outline,
                    color: Colors.white, size: 22),
              ),
            ),
          ]),
        ),

        // ── Bandeau confidentialité ───────────────────────────────────
        Container(
          color: AppPalette.blue.withOpacity(0.07),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            const Icon(Icons.shield_outlined,
                color: AppPalette.blue, size: 15),
            const SizedBox(width: 8),
            const Expanded(child: Text(
              'Messages visibles uniquement par les étudiants de cette filière',
              style: TextStyle(fontSize: 12, color: AppPalette.blue,
                  fontWeight: FontWeight.w500),
            )),
          ]),
        ),

        // ── Messages ──────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            itemCount: _messages.length,
            itemBuilder: (_, i) {
              final msg = _messages[i];
              final showDate = i == 0 ||
                  !_memeJour(_messages[i - 1].heure, msg.heure);
              return Column(children: [
                if (showDate) _separateurDate(msg.heure),
                _bulleMessage(msg),
              ]);
            },
          ),
        ),

        // ── Zone saisie ───────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                blurRadius: 10, offset: const Offset(0, -2))],
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          child: Row(children: [
            // Bouton pièce jointe
            GestureDetector(
              onTap: _menuPieceJointe,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppPalette.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded,
                    color: AppPalette.blue, size: 26),
              ),
            ),
            const SizedBox(width: 10),
            // Champ texte
            Expanded(child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _inputCtrl,
                maxLines: 4, minLines: 1,
                style: const TextStyle(fontSize: 15,
                    color: Color(0xFF0F172A)),
                decoration: const InputDecoration(
                  hintText: 'Message au groupe...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            )),
            const SizedBox(width: 10),
            // Bouton micro (vocal)
            GestureDetector(
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
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _enregistrement
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF15803D),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(
                    color: (_enregistrement
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF15803D)).withOpacity(0.35),
                    blurRadius: 8, offset: const Offset(0, 3),
                  )],
                ),
                child: Icon(
                  _enregistrement ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 8),
            // Bouton envoyer
            GestureDetector(
              onTap: _envoyerTexte,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppPalette.blue,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(
                      color: AppPalette.blue.withOpacity(0.35),
                      blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // WIDGETS
  // ════════════════════════════════════════════════════════════════════════

  Widget _separateurDate(DateTime dt) {
    final now   = DateTime.now();
    final label = _memeJour(dt, now) ? 'Aujourd\'hui'
        : _memeJour(dt, now.subtract(const Duration(days: 1))) ? 'Hier'
        : '${dt.day}/${dt.month}/${dt.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: const TextStyle(fontSize: 12,
            color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
      )),
    );
  }

  Widget _bulleMessage(_MessageGroupe msg) {
    final estMoi = msg.estMoi;

    return GestureDetector(
      onLongPress: () => _reagir(msg.id),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: estMoi
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!estMoi) ...[
              CircleAvatar(
                radius: 18,
                backgroundColor: AppPalette.blue.withOpacity(0.15),
                child: Text(msg.auteur.initiales,
                    style: const TextStyle(fontSize: 12,
                        fontWeight: FontWeight.bold, color: AppPalette.blue)),
              ),
              const SizedBox(width: 8),
            ],

            Flexible(child: Column(
              crossAxisAlignment: estMoi
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!estMoi)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(msg.auteur.prenoms,
                        style: const TextStyle(fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.blue)),
                  ),

                Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  decoration: BoxDecoration(
                    color: estMoi ? AppPalette.blue : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(18),
                      topRight:    const Radius.circular(18),
                      bottomLeft:  Radius.circular(estMoi ? 18 : 4),
                      bottomRight: Radius.circular(estMoi ? 4 : 18),
                    ),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6, offset: const Offset(0, 2))],
                    border: estMoi ? null : Border.all(
                        color: const Color(0xFFE2E8F0)),
                  ),
                  child: _contenuMessage(msg, estMoi),
                ),

                // Heure + réactions
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (msg.reactions.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFE2E8F0)),
                            boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4)],
                          ),
                          child: Text(
                            msg.reactions.keys.join(' '),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        _formatHeure(msg.heure),
                        style: const TextStyle(fontSize: 11,
                            color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            )),

            if (estMoi) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppPalette.yellow,
                child: Text(msg.auteur.initiales,
                    style: const TextStyle(fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.blue)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _contenuMessage(_MessageGroupe msg, bool estMoi) {
    final textColor = estMoi ? Colors.white : const Color(0xFF0F172A);
    final subColor  = estMoi ? Colors.white70 : const Color(0xFF64748B);

    switch (msg.type) {
      case TypeMessage.photo:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 140, width: double.infinity,
            decoration: BoxDecoration(
              color: estMoi
                  ? Colors.white.withOpacity(0.2)
                  : AppPalette.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.photo_outlined, size: 40,
                  color: estMoi ? Colors.white70 : AppPalette.blue),
              const SizedBox(height: 6),
              Text(msg.contenu, style: TextStyle(fontSize: 13,
                  color: subColor, fontWeight: FontWeight.w500)),
            ]),
          ),
        ]);

      case TypeMessage.video:
        return Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(
              color: estMoi
                  ? Colors.white.withOpacity(0.2)
                  : const Color(0xFFDC2626).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.play_circle_outline_rounded, size: 28,
                color: estMoi ? Colors.white : const Color(0xFFDC2626))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(msg.contenu, style: TextStyle(fontSize: 14,
                fontWeight: FontWeight.w600, color: textColor)),
            Text('Vidéo', style: TextStyle(fontSize: 12, color: subColor)),
          ])),
        ]);

      case TypeMessage.document:
        return Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(
              color: estMoi
                  ? Colors.white.withOpacity(0.2)
                  : AppPalette.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.insert_drive_file_rounded, size: 26,
                color: estMoi ? Colors.white : AppPalette.blue)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(msg.contenu, style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: textColor),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text('Document', style: TextStyle(fontSize: 12, color: subColor)),
          ])),
          Icon(Icons.download_outlined, size: 20,
              color: estMoi ? Colors.white70 : AppPalette.blue),
        ]);

      case TypeMessage.vocal:
        return Row(children: [
          Icon(Icons.mic_rounded, size: 22,
              color: estMoi ? Colors.white : const Color(0xFF15803D)),
          const SizedBox(width: 10),
          Expanded(child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: estMoi
                  ? Colors.white.withOpacity(0.4)
                  : const Color(0xFF15803D).withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          const SizedBox(width: 10),
          Text(msg.contenu.replaceAll('vocal_', ''),
              style: TextStyle(fontSize: 13, color: textColor,
                  fontWeight: FontWeight.w600)),
        ]);

      default:
        return Text(msg.contenu,
            style: TextStyle(fontSize: 15, color: textColor, height: 1.5));
    }
  }

  bool _memeJour(DateTime a, DateTime b) =>
      a.day == b.day && a.month == b.month && a.year == b.year;

  String _formatHeure(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

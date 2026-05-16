import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_palette.dart';
import '../models/student_profile.dart';
import 'messages_screen.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLE MESSAGE CANAL
// ════════════════════════════════════════════════════════════════════════════
class _MessageCanal {
  final String id, expediteur, initiales, texte, heure, date, type;
  final Color color;
  Map<String, int> reactions;
  bool epingle;

  _MessageCanal({
    required this.id, required this.expediteur, required this.initiales,
    required this.texte, required this.heure, required this.date,
    required this.type, required this.color,
    Map<String, int>? reactions, this.epingle = false,
  }) : reactions = reactions ?? {};
}

// ════════════════════════════════════════════════════════════════════════════
// CANAL SCREEN — Hub principal
// ════════════════════════════════════════════════════════════════════════════
class CanalScreen extends StatefulWidget {
  final StudentProfile profile;
  const CanalScreen({super.key, required this.profile});
  @override State<CanalScreen> createState() => _CanalScreenState();
}

class _CanalScreenState extends State<CanalScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(child: Column(children: [
        Container(color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(children: [
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Canaux', style: TextStyle(fontSize: 22,
                  fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              Text('${widget.profile.prenoms} ${widget.profile.nom}',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF64748B))),
            ])),
            Container(width: 38, height: 38,
              decoration: BoxDecoration(
                  color: AppPalette.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.notifications_outlined,
                  color: AppPalette.blue, size: 20)),
          ])),
        Container(height: 1, color: const Color(0xFFE2E8F0)),
        Expanded(child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionLabel('📢 Officiels'),
            const SizedBox(height: 8),
            _carteCanal(context, avatar: '🏛️', nom: 'Administration',
                description: 'Annonces officielles et informations pédagogiques',
                couleur: AppPalette.blue, badge: '3', tag: 'Lecture seule',
                type: 'administration'),
            const SizedBox(height: 10),
            _carteCanal(context, avatar: '📢', nom: 'Admin & Filière',
                description: 'Messages ciblés Admin+Délégué → votre filière',
                couleur: const Color(0xFF0891B2), badge: '1', tag: 'Broadcast',
                type: 'admin_filiere'),
            const SizedBox(height: 10),
            _carteCanal(context, avatar: '🎉', nom: 'Bureau des Étudiants',
                description: 'Événements, activités et annonces du BDE',
                couleur: const Color(0xFF7C3AED), badge: '1', tag: 'BDE',
                type: 'bde'),
            const SizedBox(height: 20),
            _sectionLabel('💬 Messages privés'),
            const SizedBox(height: 8),
            _carteCanal(context, avatar: '🔒',
                nom: 'Contacter l\'Administration',
                description: 'Posez une question en privé à l\'administration',
                couleur: const Color(0xFF059669), tag: 'Privé', type: 'prive'),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppPalette.blue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppPalette.blue.withOpacity(0.15))),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded,
                    color: AppPalette.blue, size: 14),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Le groupe filière privé entre étudiants est accessible via l\'accueil → Groupe Filière.',
                  style: TextStyle(fontSize: 11, color: AppPalette.blue,
                      fontWeight: FontWeight.w500))),
              ])),
          ])),
      ])),
    );
  }

  Widget _sectionLabel(String l) => Text(l, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B)));

  Widget _carteCanal(BuildContext context, {
    required String avatar, required String nom, required String description,
    required Color couleur, required String type,
    String? badge, String? tag,
  }) {
    return GestureDetector(
      onTap: () => _ouvrir(context, type),
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
            child: Center(child: Text(avatar,
                style: const TextStyle(fontSize: 22)))),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(nom, style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              if (tag != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: couleur.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(tag, style: TextStyle(fontSize: 9,
                      fontWeight: FontWeight.w700, color: couleur))),
              ],
            ]),
            const SizedBox(height: 3),
            Text(description, style: const TextStyle(
                fontSize: 12, color: Color(0xFF64748B)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          if (badge != null)
            Container(width: 22, height: 22,
              decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
              child: Center(child: Text(badge, style: const TextStyle(
                  fontSize: 11, color: Colors.white,
                  fontWeight: FontWeight.bold))))
          else
            Icon(Icons.chevron_right_rounded,
                color: couleur.withOpacity(0.5)),
        ]),
      ));
  }

  void _ouvrir(BuildContext context, String type) {
    late Widget page;
    // Vérification des droits selon le rôle du profil connecté
    final p = widget.profile;
    final peutEcrireAdminFiliere =
        (p.role == 'delegue' || p.role == 'delegue_adjoint') &&
        (p.filiereRole == p.filiere || p.filiereRole != null);
    final peutEcrireBDE =
        p.role == 'bde_president' || p.role == 'bde_adjoint';

    switch (type) {
      case 'administration':
        page = _CanalDetail(
          profile: p,
          nom: 'Administration', avatar: '🏛️',
          couleur: AppPalette.blue,
          tag: 'Lecture seule',
          filiereCanal: '',
          canWrite: false,  // Jamais — admin seulement
          messages: _msgsAdmin());
        break;
      case 'admin_filiere':
        page = _CanalDetail(
          profile: p,
          nom: 'Admin & Filière', avatar: '📢',
          couleur: const Color(0xFF0891B2),
          tag: peutEcrireAdminFiliere ? 'Broadcast · Vous pouvez écrire' : 'Broadcast',
          filiereCanal: p.filiere,
          canWrite: peutEcrireAdminFiliere,
          messages: _msgsAdminFiliere());
        break;
      case 'bde':
        page = _CanalDetail(
          profile: p,
          nom: 'Bureau des Étudiants', avatar: '🎉',
          couleur: const Color(0xFF7C3AED),
          tag: peutEcrireBDE ? 'BDE · Vous pouvez publier' : 'BDE',
          filiereCanal: '',
          canWrite: peutEcrireBDE,
          messages: _msgsBDE());
        break;
      case 'prive':
        page = _MessagePriveAdmin(profile: p);
        break;
      default:
        page = _CanalDetail(
          profile: p,
          nom: 'Administration', avatar: '🏛️',
          couleur: AppPalette.blue, tag: 'Lecture seule',
          filiereCanal: '', canWrite: false,
          messages: _msgsAdmin());
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  List<_MessageCanal> _msgsAdmin() => [
    _MessageCanal(id: 'A1', expediteur: 'Dir. Pédagogique', initiales: 'DP',
        texte: 'Bonjour à tous.\n\nMerci de recevoir votre nouveau programme.\n\nIST POUR L\'EXCELLENCE 🎓',
        heure: '13:16', date: 'Aujourd\'hui', type: 'texte',
        color: AppPalette.blue, reactions: {'👍': 24, '🙏': 8}),
    _MessageCanal(id: 'A2', expediteur: 'Dir. Pédagogique', initiales: 'DP',
        texte: 'PROGRAMME ST2 DU 27 04 2026.pdf',
        heure: '13:16', date: 'Aujourd\'hui', type: 'pdf',
        color: AppPalette.blue),
    _MessageCanal(id: 'A3', expediteur: 'Scolarité', initiales: 'SC',
        texte: 'Les inscriptions pédagogiques pour le Semestre 4 sont ouvertes jusqu\'au 05 Mai 2026.',
        heure: '10:30', date: 'Aujourd\'hui', type: 'texte',
        color: const Color(0xFF0891B2),
        reactions: {'✅': 15, '👍': 10}),
    _MessageCanal(id: 'A4', expediteur: 'Dir. Pédagogique', initiales: 'DP',
        texte: 'Rappel : La bibliothèque est ouverte de 8h à 20h du lundi au samedi.',
        heure: '08:00', date: 'Hier', type: 'texte',
        color: AppPalette.blue, reactions: {'👍': 12}),
  ];

  List<_MessageCanal> _msgsAdminFiliere() => [
    _MessageCanal(id: 'AF1', expediteur: 'Admin', initiales: 'AD',
        texte: '📢 Rappel : examen de Réseaux & Protocoles le 10 Mai à 8h en salle B2.',
        heure: '14:00', date: 'Aujourd\'hui', type: 'texte',
        color: const Color(0xFF0891B2),
        reactions: {'👍': 12, '✅': 8, '😮': 2}),
    _MessageCanal(id: 'AF2', expediteur: 'Délégué RIT L2', initiales: 'DL',
        texte: 'Confirme ! On se retrouve en salle d\'attente à 7h45.',
        heure: '14:20', date: 'Aujourd\'hui', type: 'texte',
        color: const Color(0xFF7C3AED), reactions: {'👍': 15}),
    _MessageCanal(id: 'AF3', expediteur: 'Admin', initiales: 'AD',
        texte: '↩️ Cours de BDD rattrapé le 08 Mai.',
        heure: '15:00', date: 'Aujourd\'hui', type: 'reponse',
        color: const Color(0xFF059669),
        reactions: {'🙏': 18, '✅': 10}),
  ];

  List<_MessageCanal> _msgsBDE() => [
    _MessageCanal(id: 'B1', expediteur: 'BDE — Aïcha S.', initiales: 'AS',
        texte: '🎵 SOIRÉE ÉTUDIANTE — Vendredi 02 Mai 2026\n\n📍 Campus IST\n🎟️ Entrée : 500 FCFA via Orange Money\n\nVenez nombreux ! 🔥',
        heure: '18:30', date: 'Hier', type: 'texte',
        color: const Color(0xFF7C3AED),
        reactions: {'🔥': 32, '❤️': 18, '🎉': 25}),
    _MessageCanal(id: 'B2', expediteur: 'BDE — Aïcha S.', initiales: 'AS',
        texte: '⚽ JOURNÉE SPORTIVE — Jeudi 01 Mai\n\nFoot · Basket · Athlétisme\n📍 Terrain universitaire',
        heure: '09:00', date: 'Il y a 2 jours', type: 'texte',
        color: const Color(0xFF7C3AED),
        reactions: {'⚽': 20, '👍': 15}),
  ];
}

// ════════════════════════════════════════════════════════════════════════════
// CANAL DÉTAIL — réactions via appui long + bouton hover via StatefulWidget
// ════════════════════════════════════════════════════════════════════════════
class _CanalDetail extends StatefulWidget {
  final StudentProfile profile;
  final String nom, avatar, tag;
  final Color couleur;
  final List<_MessageCanal> messages;
  final bool canWrite;
  final String filiereCanal;

  const _CanalDetail({
    required this.profile, required this.nom, required this.avatar,
    required this.tag, required this.couleur, required this.messages,
    this.canWrite = false, this.filiereCanal = '',
  });
  @override State<_CanalDetail> createState() => _CanalDetailState();
}

class _CanalDetailState extends State<_CanalDetail> {
  late List<_MessageCanal> _msgs;

  @override
  void initState() {
    super.initState();
    _msgs = List.from(widget.messages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBE5DD),
      appBar: AppBar(
        backgroundColor: widget.couleur, foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context)),
        titleSpacing: 0,
        title: Row(children: [
          Container(width: 34, height: 34,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(widget.avatar,
                style: const TextStyle(fontSize: 16)))),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.nom, style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(widget.tag, style: const TextStyle(
                fontSize: 10, color: Colors.white70)),
          ])),
        ]),
        actions: [
          Container(margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8)),
            child: Text('${_msgs.length} msg', style: const TextStyle(
                fontSize: 11, color: Colors.white,
                fontWeight: FontWeight.w600))),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1,
              color: Colors.white.withOpacity(0.2))),
      ),
      body: Column(children: [
        // Bannière dynamique selon le rôle
        Container(
          color: widget.couleur.withOpacity(0.07),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(children: [
            Icon(widget.canWrite
                ? Icons.edit_rounded : Icons.lock_outline_rounded,
                size: 13, color: widget.couleur),
            const SizedBox(width: 8),
            Expanded(child: Text(
              widget.canWrite
                  ? '${widget.profile.roleBadgeEmoji} ${widget.profile.roleLabel} — '
                    'Vous pouvez écrire dans ce canal.'
                  : 'Canal en lecture seule — Appuyez longuement pour réagir.',
              style: TextStyle(fontSize: 11, color: widget.couleur,
                  fontWeight: FontWeight.w500))),
          ])),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          itemCount: _msgs.length,
          itemBuilder: (_, i) {
            final showDate = i == 0 || _msgs[i-1].date != _msgs[i].date;
            return Column(children: [
              if (showDate) _separateur(_msgs[i].date),
              _BulleCanal(
                key: ValueKey(_msgs[i].id),
                message: _msgs[i],
                couleur: widget.couleur,
                onMenu: () => _menuReaction(_msgs[i]),
              ),
            ]);
          })),
        // Zone saisie visible UNIQUEMENT si le rôle autorise l'écriture
        if (widget.canWrite) _zoneSaisie(),
      ]),
    );
  }

  // ── Zone saisie délégué/BDE ───────────────────────────────────────────
  final _inputCtrl = TextEditingController();
  bool _hasText = false;

  Widget _zoneSaisie() {
    return StatefulBuilder(builder: (ctx, setS) =>
      Container(
        color: const Color(0xFFF0EBE3),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          // Badge rôle visible dans la saisie
          Container(
            margin: const EdgeInsets.only(right: 6, bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
                color: widget.couleur.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: widget.couleur.withOpacity(0.3))),
            child: Text(widget.profile.roleBadgeEmoji,
                style: const TextStyle(fontSize: 16))),
          Expanded(child: Container(
            constraints: const BoxConstraints(maxHeight: 100),
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.06), blurRadius: 4)]),
            child: TextField(
              controller: _inputCtrl, maxLines: null,
              onChanged: (v) => setS(() => _hasText = v.trim().isNotEmpty),
              style: const TextStyle(fontSize: 14, color: Color(0xFF111B21)),
              decoration: InputDecoration(
                hintText: 'Message en tant que ${widget.profile.roleLabel}...',
                hintStyle: const TextStyle(
                    fontSize: 13, color: Color(0xFF8696A0)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10))))),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _hasText
                ? GestureDetector(key: const ValueKey('send'),
                    onTap: () => _envoyerMessage(setS),
                    child: Container(width: 42, height: 42,
                      decoration: BoxDecoration(
                          color: widget.couleur, shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 19)))
                : Container(key: const ValueKey('mic'),
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                        color: widget.couleur, shape: BoxShape.circle),
                    child: const Icon(Icons.mic_rounded,
                        color: Colors.white, size: 22))),
        ])));
  }

  void _envoyerMessage(StateSetter setS) {
    final texte = _inputCtrl.text.trim();
    if (texte.isEmpty) return;
    final p = widget.profile;
    setState(() {
      _msgs.add(_MessageCanal(
        id: 'M${DateTime.now().millisecondsSinceEpoch}',
        expediteur: '${p.roleBadgeEmoji} ${p.prenoms} ${p.nom}',
        initiales: '${p.prenoms[0]}${p.nom[0]}',
        texte: texte,
        heure: '${TimeOfDay.now().hour.toString().padLeft(2,'0')}:${TimeOfDay.now().minute.toString().padLeft(2,'0')}',
        date: 'Aujourd\'hui',
        type: 'texte',
        color: widget.couleur,
      ));
    });
    _inputCtrl.clear();
    setS(() => _hasText = false);
  }

  Widget _separateur(String date) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFD9F2E4),
          borderRadius: BorderRadius.circular(8)),
      child: Text(date, style: const TextStyle(fontSize: 12,
          color: Color(0xFF54656F), fontWeight: FontWeight.w500)))));

  void _menuReaction(_MessageCanal msg) {
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
          // Émojis rapides + +
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
          ListTile(dense: true,
            leading: const Icon(Icons.copy_rounded,
                color: Color(0xFF54656F), size: 20),
            title: const Text('Copier le texte',
                style: TextStyle(fontSize: 14, color: Color(0xFF54656F))),
            onTap: () { Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: msg.texte));
              _snack('Texte copié !'); }),
          ListTile(dense: true,
            leading: const Icon(Icons.forward_rounded,
                color: Color(0xFF54656F), size: 20),
            title: const Text('Transférer',
                style: TextStyle(fontSize: 14, color: Color(0xFF54656F))),
            onTap: () { Navigator.pop(context); _transferer(msg); }),
          ListTile(dense: true,
            leading: Icon(msg.epingle
                ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                color: AppPalette.blue, size: 20),
            title: Text(msg.epingle ? 'Désépingler' : 'Épingler',
                style: const TextStyle(fontSize: 14, color: AppPalette.blue)),
            onTap: () { Navigator.pop(context);
              setState(() => msg.epingle = !msg.epingle); }),
          ListTile(dense: true,
            leading: const Icon(Icons.share_rounded,
                color: Color(0xFF54656F), size: 20),
            title: const Text('Partager',
                style: TextStyle(fontSize: 14, color: Color(0xFF54656F))),
            onTap: () { Navigator.pop(context); _snack('📤 Partage...'); }),
          const SizedBox(height: 12),
        ])));
  }

  void _tousEmojis(_MessageCanal msg) {
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

  void _transferer(_MessageCanal msg) {
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
            itemCount: conversationsPrivees.length,
            itemBuilder: (_, i) {
              final c = conversationsPrivees[i];
              return ListTile(
                leading: Container(width: 36, height: 36,
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
                    texte: '↩️ ${msg.texte}',
                    heure: _now(), type: TypeMessagePrive.texte,
                    estMoi: true));
                  _snack('✅ Transféré !'); });
            })),
        ])));
  }

  String _now() {
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
// BULLE CANAL — StatefulWidget séparé pour hover
// ════════════════════════════════════════════════════════════════════════════
class _BulleCanal extends StatefulWidget {
  final _MessageCanal message;
  final Color couleur;
  final VoidCallback onMenu;

  const _BulleCanal({
    super.key,
    required this.message,
    required this.couleur,
    required this.onMenu,
  });

  @override
  State<_BulleCanal> createState() => _BulleCanalState();
}

class _BulleCanalState extends State<_BulleCanal> {
  bool _hovered = false;

  _MessageCanal get msg => widget.message;

  @override
  Widget build(BuildContext context) {
    final isPDF     = msg.type == 'pdf';
    final isReponse = msg.type == 'reponse';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onLongPress: widget.onMenu,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(
                    color: msg.color, shape: BoxShape.circle),
                child: Center(child: Text(msg.initiales,
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)))),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(msg.expediteur, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold,
                      color: msg.color)),
                  const SizedBox(width: 8),
                  Text(msg.heure, style: const TextStyle(
                      fontSize: 10, color: Color(0xFF94A3B8))),
                  if (isReponse) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                          color: const Color(0xFF059669).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4)),
                      child: const Text('↩️ Réponse',
                          style: TextStyle(fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669)))),
                  ],
                  if (msg.epingle) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.push_pin_rounded,
                        size: 11, color: AppPalette.blue),
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
                    color: isReponse
                        ? const Color(0xFF059669).withOpacity(0.06)
                        : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14)),
                    border: isReponse ? Border.all(
                        color: const Color(0xFF059669).withOpacity(0.3))
                        : null,
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4, offset: const Offset(0, 1))]),
                  child: isPDF
                      ? Row(children: [
                          Container(width: 42, height: 42,
                            decoration: BoxDecoration(
                                color: msg.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.picture_as_pdf_rounded,
                                color: msg.color, size: 24)),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(msg.texte, style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A))),
                            const Text('PDF · Appuyer pour télécharger',
                                style: TextStyle(fontSize: 10,
                                    color: Color(0xFF64748B))),
                          ])),
                          Icon(Icons.download_rounded,
                              color: msg.color, size: 18),
                        ])
                      : Text(msg.texte, style: const TextStyle(
                          fontSize: 14, color: Color(0xFF0F172A),
                          height: 1.5))),
                // Réactions + bouton hover
                Row(children: [
                  if (msg.reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(spacing: 5, children: msg.reactions.entries
                          .map((e) => GestureDetector(
                            onTap: () => setState(() =>
                                msg.reactions[e.key] =
                                    (msg.reactions[e.key] ?? 0) + 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0)),
                                  boxShadow: [BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 3)]),
                              child: Text('${e.key} ${e.value}',
                                  style: const TextStyle(
                                      fontSize: 12))))).toList())),
                  if (_hovered)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 6),
                      child: GestureDetector(
                        onTap: widget.onMenu,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0)),
                              boxShadow: [BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 3)]),
                          child: const Row(mainAxisSize: MainAxisSize.min,
                              children: [
                            Text('😊', style: TextStyle(fontSize: 13)),
                            SizedBox(width: 2),
                            Icon(Icons.expand_more_rounded,
                                size: 14, color: Color(0xFF64748B)),
                          ])))),
                ]),
              ])),
            ]))));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// MESSAGE PRIVÉ ADMIN
// ════════════════════════════════════════════════════════════════════════════
class _MessagePriveAdmin extends StatefulWidget {
  final StudentProfile profile;
  const _MessagePriveAdmin({required this.profile});
  @override State<_MessagePriveAdmin> createState() =>
      _MessagePriveAdminState();
}

class _MessagePriveAdminState extends State<_MessagePriveAdmin> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  bool _hasText = false;

  final List<Map<String, dynamic>> _msgs = [
    {'texte': 'Bonjour, je suis disponible pour répondre à vos questions.',
     'estMoi': false, 'heure': '08:00', 'lu': true},
  ];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() =>
        setState(() => _hasText = _ctrl.text.trim().isNotEmpty));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBE5DD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context)),
        title: const Row(children: [
          CircleAvatar(radius: 16, backgroundColor: Colors.white24,
              child: Text('🔒', style: TextStyle(fontSize: 14))),
          SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Administration', style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold)),
            Text('Message privé · Confidentiel', style: TextStyle(
                fontSize: 10, color: Colors.white70)),
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
          controller: _scroll,
          padding: const EdgeInsets.all(12),
          itemCount: _msgs.length,
          itemBuilder: (_, i) {
            final m      = _msgs[i];
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
                            fontWeight: FontWeight.bold,
                            color: Colors.white))),
                    const SizedBox(width: 5),
                  ],
                  Flexible(child: Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.65),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: estMoi ? const Color(0xFFD9FDD3) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(estMoi ? 14 : 0),
                        bottomRight: Radius.circular(estMoi ? 0 : 14)),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 3)]),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                      Text(m['texte'] as String, style: const TextStyle(
                          fontSize: 14, color: Color(0xFF111B21),
                          height: 1.4)),
                      const SizedBox(height: 2),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(m['heure'] as String,
                            style: const TextStyle(fontSize: 9,
                                color: Color(0xFF667781))),
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
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.06), blurRadius: 4)]),
              child: TextField(
                controller: _ctrl, maxLines: null,
                style: const TextStyle(fontSize: 14,
                    color: Color(0xFF111B21)),
                decoration: const InputDecoration(
                  hintText: 'Écrire un message privé...',
                  hintStyle: TextStyle(fontSize: 14,
                      color: Color(0xFF8696A0)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10))))),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _hasText
                  ? GestureDetector(key: const ValueKey('send'),
                      onTap: _envoyer,
                      child: Container(width: 42, height: 42,
                        decoration: const BoxDecoration(
                            color: Color(0xFF059669),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 19)))
                  : Container(key: const ValueKey('mic'),
                      width: 42, height: 42,
                      decoration: const BoxDecoration(
                          color: Color(0xFF059669), shape: BoxShape.circle),
                      child: const Icon(Icons.mic_rounded,
                          color: Colors.white, size: 22))),
          ])),
      ]),
    );
  }

  void _envoyer() {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() {
      _msgs.add({
        'texte': _ctrl.text.trim(), 'estMoi': true,
        'heure': '${TimeOfDay.now().hour.toString().padLeft(2,'0')}:${TimeOfDay.now().minute.toString().padLeft(2,'0')}',
        'lu': false,
      });
    });
    _ctrl.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }
}

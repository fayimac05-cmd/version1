import 'package:flutter/material.dart';
import '../pages/admin_data.dart';
import '../theme/app_palette.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES
// ════════════════════════════════════════════════════════════════════════════
class Annonce {
  final String id, titre, contenu, auteur, date, cible, cibleLabel;
  final List<PieceJointe> fichiers;
  bool lue;

  Annonce({
    required this.id, required this.titre, required this.contenu,
    required this.auteur, required this.date, required this.cible,
    required this.cibleLabel, this.fichiers = const [], this.lue = false,
  });
}

class PieceJointe {
  final String nom, type;
  PieceJointe({required this.nom, required this.type});

  IconData get icon {
    switch (type) {
      case 'pdf':   return Icons.picture_as_pdf_rounded;
      case 'word':  return Icons.description_rounded;
      case 'image': return Icons.image_rounded;
      case 'audio': return Icons.mic_rounded;
      default:      return Icons.attach_file;
    }
  }

  Color get color {
    switch (type) {
      case 'pdf':   return const Color(0xFFDC2626);
      case 'word':  return const Color(0xFF2563EB);
      case 'image': return const Color(0xFF7C3AED);
      case 'audio': return const Color(0xFFD97706);
      default:      return const Color(0xFF64748B);
    }
  }
}

// ── Données ───────────────────────────────────────────────────────────────
List<Annonce> adminAnnonces = [
  Annonce(
    id: 'A001', titre: 'Calendrier des examens — Semestre 3',
    contenu: 'Les examens du Semestre 3 se dérouleront du 15 au 30 mai 2025. Veuillez consulter le calendrier détaillé ci-joint. Tout retard entraînera une note de 0.',
    auteur: 'Direction Pédagogique', date: '28/04/2025',
    cible: 'tous', cibleLabel: 'Tous les étudiants',
    fichiers: [PieceJointe(nom: 'calendrier_examens_S3.pdf', type: 'pdf')],
  ),
  Annonce(
    id: 'A002', titre: 'Réunion des professeurs — Jeudi 02 mai',
    contenu: 'Une réunion pédagogique obligatoire est prévue jeudi 02 mai à 10h00 en salle de conférence. Ordre du jour : résultats S3, planification S4.',
    auteur: 'Direction Pédagogique', date: '27/04/2025',
    cible: 'profs', cibleLabel: 'Tous les professeurs',
    fichiers: [PieceJointe(nom: 'ordre_du_jour.docx', type: 'word')],
  ),
  Annonce(
    id: 'A003', titre: 'Notes RIT L2 — Réseaux & Protocoles disponibles',
    contenu: 'Les notes du module Réseaux & Protocoles (RES301) ont été publiées. Les étudiants peuvent les consulter dans leur espace Notes. Toute réclamation doit être soumise dans les 72h.',
    auteur: 'Scolarité IST', date: '29/04/2025',
    cible: 'filiere:RIT-L2', cibleLabel: 'RIT Licence 2',
    fichiers: [],
  ),
];

// ── Messages de groupe ────────────────────────────────────────────────────
class _GroupeMessage {
  final String texte, auteur, heure;
  final bool estAdmin;
  final PieceJointe? fichier;
  _GroupeMessage({required this.texte, required this.auteur,
      required this.heure, required this.estAdmin, this.fichier});
}

final Map<String, List<_GroupeMessage>> _messagesGroupes = {
  'profs': [
    _GroupeMessage(texte: 'Bonjour à tous ! Les notes du Semestre 3 seront publiées cette semaine.',
        auteur: 'Administration', heure: '09:15', estAdmin: true),
    _GroupeMessage(texte: 'Merci. Est-ce qu\'il y a un calendrier pour les rattrapages ?',
        auteur: 'OUÉDRAOGO Mamadou', heure: '09:22', estAdmin: false),
    _GroupeMessage(texte: 'Oui, le calendrier sera partagé en fin de semaine.',
        auteur: 'Administration', heure: '09:30', estAdmin: true),
  ],
  'delegues': [],
};

// ════════════════════════════════════════════════════════════════════════════
// PAGE PRINCIPALE
// ════════════════════════════════════════════════════════════════════════════
class AdminCommunications extends StatefulWidget {
  const AdminCommunications({super.key});
  @override State<AdminCommunications> createState() => _AdminCommunicationsState();
}

class _AdminCommunicationsState extends State<AdminCommunications>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final nbNonLus = adminAnnonces.where((a) => !a.lue).length;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: AppPalette.blue, foregroundColor: Colors.white, elevation: 0,
        title: const Text('Communications',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                color: Colors.white, letterSpacing: -0.5)),
        actions: [
          IconButton(
            onPressed: () => _dialogNouvelleAnnonce(context),
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            tooltip: 'Nouvelle annonce',
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppPalette.yellow,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Annonces'),
              if (nbNonLus > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: AppPalette.yellow,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('$nbNonLus', style: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ],
            ])),
            const Tab(text: 'Discussions'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabCtrl, children: [
        _tabAnnonces(),
        _tabDiscussions(),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // TAB ANNONCES — style feed
  // ════════════════════════════════════════════════════════════════════════
  Widget _tabAnnonces() {
    return Column(children: [
      // Bouton publier rapide
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: GestureDetector(
          onTap: () => _dialogNouvelleAnnonce(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: const BoxDecoration(
                    color: AppPalette.blue, shape: BoxShape.circle),
                child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Publier une annonce...',
                  style: TextStyle(fontSize: 15, color: Color(0xFF94A3B8))),
            ]),
          ),
        ),
      ),
      Container(height: 8, color: const Color(0xFFF0F2F5)),

      // Liste annonces
      Expanded(
        child: adminAnnonces.isEmpty
            ? const Center(child: Text('Aucune annonce publiée.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15)))
            : ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: adminAnnonces.length,
                separatorBuilder: (_, __) => Container(height: 8, color: const Color(0xFFF0F2F5)),
                itemBuilder: (_, i) => _carteAnnonce(adminAnnonces[i]),
              ),
      ),
    ]);
  }

  Widget _carteAnnonce(Annonce a) {
    Color cibleColor; IconData cibleIcon; String cibleEmoji;
    if (a.cible == 'tous') {
      cibleColor = AppPalette.blue; cibleIcon = Icons.people_rounded; cibleEmoji = '🏫';
    } else if (a.cible == 'profs') {
      cibleColor = const Color(0xFF7C3AED); cibleIcon = Icons.person_pin_rounded; cibleEmoji = '👨‍🏫';
    } else if (a.cible == 'delegues') {
      cibleColor = const Color(0xFF0891B2); cibleIcon = Icons.star_rounded; cibleEmoji = '⭐';
    } else {
      cibleColor = const Color(0xFF15803D); cibleIcon = Icons.school_rounded; cibleEmoji = '🎓';
    }

    return Container(
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // En-tête auteur
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Avatar
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: cibleColor, shape: BoxShape.circle),
              child: Center(child: Text(cibleEmoji,
                  style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.auteur, style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 2),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cibleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(cibleIcon, size: 11, color: cibleColor),
                    const SizedBox(width: 3),
                    Text(a.cibleLabel, style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.bold, color: cibleColor)),
                  ]),
                ),
                const SizedBox(width: 8),
                Text(a.date, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ]),
            ])),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: Color(0xFF94A3B8)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'supprimer',
                    child: Row(children: [
                      Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 18),
                      SizedBox(width: 10),
                      Text('Supprimer', style: TextStyle(color: Color(0xFFDC2626))),
                    ])),
              ],
              onSelected: (v) {
                if (v == 'supprimer') {
                  setState(() => adminAnnonces.remove(a));
                }
              },
            ),
          ]),
        ),

        // Contenu
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.titre, style: const TextStyle(fontSize: 17,
                fontWeight: FontWeight.w800, color: Color(0xFF0F172A), height: 1.3)),
            const SizedBox(height: 8),
            Text(a.contenu, style: const TextStyle(fontSize: 14,
                color: Color(0xFF374151), height: 1.6)),
          ]),
        ),

        // Fichiers joints
        if (a.fichiers.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...a.fichiers.map((f) => Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: f.color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: f.color.withOpacity(0.15)),
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: f.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(f.icon, color: f.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.nom, style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w700, color: f.color),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Appuyer pour télécharger',
                    style: TextStyle(fontSize: 11, color: f.color.withOpacity(0.7))),
              ])),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: f.color, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: f.color.withOpacity(0.3),
                        blurRadius: 8, offset: const Offset(0, 3))]),
                child: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
              ),
            ]),
          )),
        ],

        // Actions like/react
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(children: [
            const Spacer(),
            Text(a.date, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ]),
        ),

        Container(height: 1, color: const Color(0xFFF0F2F5)),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // TAB DISCUSSIONS — style WhatsApp inbox
  // ════════════════════════════════════════════════════════════════════════
  Widget _tabDiscussions() {
    final groupes = [
      {
        'id': 'profs',
        'nom': 'Groupe Professeurs',
        'sous': 'Admin ↔ Tous les professeurs',
        'icon': Icons.person_pin_rounded,
        'color': const Color(0xFF7C3AED),
        'nb': adminProfs.length,
        'dernierMsg': _messagesGroupes['profs']!.isNotEmpty
            ? _messagesGroupes['profs']!.last.texte : 'Aucun message',
        'heure': _messagesGroupes['profs']!.isNotEmpty ? '09:30' : '',
        'nonLus': 0,
      },
      {
        'id': 'delegues',
        'nom': 'Admin & Délégué(e)s',
        'sous': 'Admin ↔ Chefs de filière',
        'icon': Icons.star_rounded,
        'color': const Color(0xFF0891B2),
        'nb': 0,
        'dernierMsg': 'Aucun message pour le moment',
        'heure': '',
        'nonLus': 0,
      },
      ...adminFilieres.map((f) => {
        'id': 'filiere:${f.id}',
        'nom': f.nom,
        'sous': '${f.niveau} · ${adminEtudiants.where((e) => e.filiereId == f.id).length} étudiants',
        'icon': f.domaine.contains('Technologies')
            ? Icons.computer_rounded : Icons.business_center_rounded,
        'color': f.domaine.contains('Technologies')
            ? AppPalette.blue : const Color(0xFF7C3AED),
        'nb': adminEtudiants.where((e) => e.filiereId == f.id).length,
        'dernierMsg': 'Envoyer une annonce à cette filière',
        'heure': '',
        'nonLus': 0,
      }),
    ];

    return Column(children: [
      // Barre de recherche style WhatsApp
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Row(children: [
            Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
            SizedBox(width: 10),
            Text('Rechercher ou démarrer une discussion',
                style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
          ]),
        ),
      ),

      // Liste discussions style WhatsApp
      Expanded(
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: groupes.length,
          itemBuilder: (_, i) => _ligneDiscussion(groupes[i]),
        ),
      ),
    ]);
  }

  Widget _ligneDiscussion(Map<String, dynamic> g) {
    final color = g['color'] as Color;
    final nonLus = g['nonLus'] as int;
    final id = g['id'] as String;

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => _PageChat(
            nomGroupe: g['nom'] as String,
            color: color,
            groupeId: id,
            onAjouterDelegue: id == 'delegues'
                ? () => _dialogAjouterDelegue(context) : null,
          ))),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          // Avatar groupe
          Stack(children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(color: color.withOpacity(0.15),
                  shape: BoxShape.circle),
              child: Icon(g['icon'] as IconData, color: color, size: 26),
            ),
            if ((g['nb'] as int) > 0)
              Positioned(bottom: 0, right: 0,
                child: Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                  child: Center(child: Text('${g['nb']}',
                      style: const TextStyle(fontSize: 8,
                          fontWeight: FontWeight.bold, color: Colors.white))),
                )),
          ]),
          const SizedBox(width: 14),
          // Texte
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(g['nom'] as String,
                  style: TextStyle(fontSize: 16,
                      fontWeight: nonLus > 0 ? FontWeight.w800 : FontWeight.w600,
                      color: const Color(0xFF0F172A)),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              if ((g['heure'] as String).isNotEmpty)
                Text(g['heure'] as String, style: TextStyle(fontSize: 12,
                    color: nonLus > 0 ? color : const Color(0xFF94A3B8),
                    fontWeight: nonLus > 0 ? FontWeight.bold : FontWeight.normal)),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              Expanded(child: Text(g['dernierMsg'] as String,
                  style: TextStyle(fontSize: 13,
                      color: nonLus > 0 ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                      fontWeight: nonLus > 0 ? FontWeight.w600 : FontWeight.normal),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (nonLus > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                  child: Text('$nonLus', style: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.bold, color: Colors.white)),
                ),
            ]),
          ])),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // DIALOG NOUVELLE ANNONCE
  // ════════════════════════════════════════════════════════════════════════
  void _dialogNouvelleAnnonce(BuildContext context) {
    final titreCtrl = TextEditingController();
    final contenuCtrl = TextEditingController();
    String cible = 'tous';
    String cibleLabel = 'Tous les étudiants';
    final List<PieceJointe> fichiers = [];

    final cibles = [
      {'val': 'tous',     'label': 'Tous les étudiants',    'emoji': '🏫'},
      {'val': 'profs',    'label': 'Tous les professeurs',  'emoji': '👨‍🏫'},
      {'val': 'delegues', 'label': 'Délégués uniquement',   'emoji': '⭐'},
      ...adminFilieres.map((f) => {
        'val': 'filiere:${f.id}', 'label': f.nom, 'emoji': '🎓'}),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Handle
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),

                const Text('Nouvelle annonce', style: TextStyle(fontSize: 22,
                    fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                const SizedBox(height: 20),

                // Destinataires
                const Text('Destinataires', style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w700, color: Color(0xFF64748B),
                    letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true, value: cible,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius: BorderRadius.circular(14),
                      items: cibles.map((c) => DropdownMenuItem(
                        value: c['val'],
                        child: Text('${c['emoji']}  ${c['label']}',
                            style: const TextStyle(fontSize: 15)),
                      )).toList(),
                      onChanged: (v) => setS(() {
                        cible = v!;
                        cibleLabel = cibles.firstWhere((c) => c['val'] == v)['label']!;
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Titre
                const Text('Titre', style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5)),
                const SizedBox(height: 8),
                _champSaisie(titreCtrl, 'Titre de l\'annonce', 1),
                const SizedBox(height: 16),

                // Message
                const Text('Message', style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5)),
                const SizedBox(height: 8),
                _champSaisie(contenuCtrl, 'Rédigez votre message...', 5),
                const SizedBox(height: 16),

                // Pièces jointes
                const Text('Pièces jointes', style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Row(children: [
                  _btnFichier('PDF', Icons.picture_as_pdf_rounded,
                      const Color(0xFFDC2626), () => setS(() =>
                          fichiers.add(PieceJointe(nom: 'document.pdf', type: 'pdf')))),
                  const SizedBox(width: 8),
                  _btnFichier('Word', Icons.description_rounded,
                      const Color(0xFF2563EB), () => setS(() =>
                          fichiers.add(PieceJointe(nom: 'document.docx', type: 'word')))),
                  const SizedBox(width: 8),
                  _btnFichier('Image', Icons.image_rounded,
                      const Color(0xFF7C3AED), () => setS(() =>
                          fichiers.add(PieceJointe(nom: 'image.jpg', type: 'image')))),
                  const SizedBox(width: 8),
                  _btnFichier('Vocal', Icons.mic_rounded,
                      const Color(0xFFD97706), () => setS(() =>
                          fichiers.add(PieceJointe(nom: 'audio.mp3', type: 'audio')))),
                ]),
                if (fichiers.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: fichiers.asMap().entries.map((e) =>
                    Chip(
                      label: Text(e.value.nom, style: TextStyle(fontSize: 11, color: e.value.color)),
                      avatar: Icon(e.value.icon, size: 14, color: e.value.color),
                      backgroundColor: e.value.color.withOpacity(0.08),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => setS(() => fichiers.removeAt(e.key)),
                    )).toList()),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (titreCtrl.text.isEmpty || contenuCtrl.text.isEmpty) return;
                      final now = DateTime.now();
                      final date = '${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year}';
                      setState(() {
                        adminAnnonces.insert(0, Annonce(
                          id: 'A${adminAnnonces.length + 1}',
                          titre: titreCtrl.text, contenu: contenuCtrl.text,
                          auteur: 'Administration IST', date: date,
                          cible: cible, cibleLabel: cibleLabel,
                          fichiers: List.from(fichiers),
                        ));
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Annonce publiée ✅'),
                        backgroundColor: Color(0xFF15803D),
                        behavior: SnackBarBehavior.floating,
                      ));
                    },
                    icon: const Icon(Icons.send_rounded, size: 20),
                    label: const Text('Publier l\'annonce',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _champSaisie(TextEditingController ctrl, String hint, int lines) =>
      Container(
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0))),
        child: TextField(controller: ctrl, maxLines: lines,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14))),
      );

  Widget _btnFichier(String label, IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      );

  void _dialogAjouterDelegue(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.star_rounded, color: Color(0xFF0891B2)),
          SizedBox(width: 10),
          Text('Ajouter un délégué', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min,
            children: adminEtudiants.take(4).map((e) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: AppPalette.blue.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: Center(child: Text('${e.prenoms[0]}${e.nom[0]}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                      color: AppPalette.blue)))),
          title: Text('${e.prenoms} ${e.nom}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text(e.filiere, style: const TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF0891B2)),
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${e.prenoms} ${e.nom} ajouté comme délégué.'),
              backgroundColor: const Color(0xFF0891B2),
              behavior: SnackBarBehavior.floating,
            ));
          },
        )).toList()),
        actions: [TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: Color(0xFF64748B))))],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PAGE CHAT GROUPE — style WhatsApp
// ════════════════════════════════════════════════════════════════════════════
class _PageChat extends StatefulWidget {
  final String nomGroupe, groupeId;
  final Color color;
  final VoidCallback? onAjouterDelegue;
  const _PageChat({required this.nomGroupe, required this.color,
      required this.groupeId, this.onAjouterDelegue});
  @override State<_PageChat> createState() => _PageChatState();
}

class _PageChatState extends State<_PageChat> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  PieceJointe? _fichierEnAttente;

  List<_GroupeMessage> get _messages =>
      _messagesGroupes[widget.groupeId] ?? [];

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  void _envoyer() {
    if (_msgCtrl.text.trim().isEmpty && _fichierEnAttente == null) return;
    final msg = _GroupeMessage(
      texte: _msgCtrl.text.trim(),
      auteur: 'Administration', heure: _heureNow(),
      estAdmin: true, fichier: _fichierEnAttente,
    );
    setState(() {
      _messagesGroupes.putIfAbsent(widget.groupeId, () => []);
      _messagesGroupes[widget.groupeId]!.add(msg);
      _msgCtrl.clear(); _fichierEnAttente = null;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  String _heureNow() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2,'0')}:${n.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final msgs = _messages;
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD), // fond style WhatsApp
      appBar: AppBar(
        backgroundColor: widget.color, foregroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle),
              child: Icon(Icons.groups_rounded, color: Colors.white, size: 22)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.nomGroupe, style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.w700, color: Colors.white)),
            Text('${_messages.length} messages',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ])),
        ]),
        actions: [
          if (widget.onAjouterDelegue != null)
            IconButton(
              icon: const Icon(Icons.person_add_rounded, color: Colors.white),
              onPressed: () { Navigator.pop(context); widget.onAjouterDelegue!(); },
              tooltip: 'Ajouter délégué',
            ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(children: [
        // Messages
        Expanded(
          child: msgs.isEmpty
              ? Center(child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 48,
                        color: widget.color.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    const Text('Aucun message.\nCommencez la discussion !',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, height: 1.5)),
                  ]),
                ))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) => _bulle(msgs[i]),
                ),
        ),

        // Fichier en attente
        if (_fichierEnAttente != null)
          Container(
            color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Icon(_fichierEnAttente!.icon, color: _fichierEnAttente!.color, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_fichierEnAttente!.nom,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              IconButton(onPressed: () => setState(() => _fichierEnAttente = null),
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8))),
            ]),
          ),

        // Barre saisie style WhatsApp
        Container(
          color: const Color(0xFFF0F2F5),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: Row(children: [
            // Bouton fichier
            PopupMenuButton<String>(
              icon: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
                        blurRadius: 4)]),
                child: const Icon(Icons.attach_file_rounded, color: Color(0xFF64748B), size: 20),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              itemBuilder: (_) => [
                _popupItem('pdf',   Icons.picture_as_pdf_rounded, 'Document PDF',  const Color(0xFFDC2626)),
                _popupItem('word',  Icons.description_rounded,    'Document Word', const Color(0xFF2563EB)),
                _popupItem('image', Icons.image_rounded,           'Image/Photo',  const Color(0xFF7C3AED)),
                _popupItem('audio', Icons.mic_rounded,             'Message Vocal',const Color(0xFFD97706)),
              ],
              onSelected: (t) => setState(() => _fichierEnAttente = PieceJointe(
                  nom: t == 'pdf' ? 'document.pdf' : t == 'word' ? 'document.docx'
                      : t == 'image' ? 'image.jpg' : 'audio.mp3', type: t)),
            ),
            const SizedBox(width: 8),
            // Champ texte
            Expanded(child: Container(
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]),
              child: TextField(
                controller: _msgCtrl,
                style: const TextStyle(fontSize: 15),
                maxLines: 4, minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Message',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
              ),
            )),
            const SizedBox(width: 8),
            // Bouton envoyer
            GestureDetector(
              onTap: _envoyer,
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: widget.color.withOpacity(0.4),
                        blurRadius: 8, offset: const Offset(0, 3))]),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  PopupMenuItem<String> _popupItem(String val, IconData icon, String label, Color color) =>
      PopupMenuItem(value: val, child: Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ]));

  Widget _bulle(_GroupeMessage m) {
    final isAdmin = m.estAdmin;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 4,
        left: isAdmin ? 60 : 0,
        right: isAdmin ? 0 : 60,
      ),
      child: Column(
        crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isAdmin)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(m.auteur, style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.bold, color: widget.color)),
            ),
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isAdmin ? const Color(0xFFDCF8C6) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isAdmin ? const Radius.circular(16) : const Radius.circular(4),
                bottomRight: isAdmin ? const Radius.circular(4) : const Radius.circular(16),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                  blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (m.texte.isNotEmpty)
                Text(m.texte, style: const TextStyle(fontSize: 15,
                    color: Color(0xFF0F172A), height: 1.4)),
              if (m.fichier != null) ...[
                if (m.texte.isNotEmpty) const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: m.fichier!.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(m.fichier!.icon, color: m.fichier!.color, size: 20),
                    const SizedBox(width: 8),
                    Text(m.fichier!.nom, style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w600, color: m.fichier!.color)),
                    const SizedBox(width: 8),
                    Icon(Icons.download_rounded, color: m.fichier!.color, size: 16),
                  ]),
                ),
              ],
              const SizedBox(height: 2),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(m.heure, style: const TextStyle(fontSize: 10,
                    color: Color(0xFF94A3B8))),
                if (isAdmin) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, size: 14, color: Color(0xFF34B7F1)),
                ],
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

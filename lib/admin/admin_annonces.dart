import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES
// ════════════════════════════════════════════════════════════════════════════
enum TypeAnnonce { important, note, evenement, emploiDuTemps }
enum PorteeAnnonce { tousTesEtudiants, parFiliere, parNiveau }
enum StatutAnnonce { brouillon, publie }

class PieceJointe {
  final String nom, type; // pdf | word | image | video | lien
  final String? url;
  PieceJointe({required this.nom, required this.type, this.url});
}

class Annonce {
  final String id;
  String titre, contenu;
  TypeAnnonce type;
  PorteeAnnonce portee;
  String? filiereId, niveau;
  StatutAnnonce statut;
  final DateTime dateCreation;
  List<PieceJointe> piecesJointes;

  Annonce({
    required this.id, required this.titre, required this.contenu,
    required this.type, required this.portee, required this.statut,
    required this.dateCreation,
    this.filiereId, this.niveau,
    List<PieceJointe>? piecesJointes,
  }) : piecesJointes = piecesJointes ?? [];
}

// ── Données mock ─────────────────────────────────────────────────────────
final List<Annonce> _annonces = [
  Annonce(
    id: 'A001', titre: 'Calendrier des examens S4',
    contenu: 'Le calendrier des examens du Semestre 4 est disponible. '
        'Les examens débuteront le 10 Mai 2026.\n\n'
        'Consultez le planning en pièce jointe.',
    type: TypeAnnonce.important,
    portee: PorteeAnnonce.tousTesEtudiants,
    statut: StatutAnnonce.publie,
    dateCreation: DateTime.now().subtract(const Duration(hours: 2)),
    piecesJointes: [
      PieceJointe(nom: 'Calendrier_Examen_S4.pdf', type: 'pdf'),
    ]),
  Annonce(
    id: 'A002', titre: 'Résultats partiels RIT L2',
    contenu: 'Les notes des partiels de RIT L2 sont disponibles sur la '
        'plateforme ScolarHub. Vérifiez votre espace personnel.',
    type: TypeAnnonce.note,
    portee: PorteeAnnonce.parFiliere,
    filiereId: 'F001',
    statut: StatutAnnonce.publie,
    dateCreation: DateTime.now().subtract(const Duration(days: 1))),
  Annonce(
    id: 'A003', titre: 'Soirée de gala IST 2026',
    contenu: 'L\'IST organise sa soirée annuelle le 15 Mai 2026.\n'
        '📍 Hôtel Azalaï, Ouagadougou\n🎟️ Ticket : 2000 FCFA',
    type: TypeAnnonce.evenement,
    portee: PorteeAnnonce.tousTesEtudiants,
    statut: StatutAnnonce.brouillon,
    dateCreation: DateTime.now().subtract(const Duration(hours: 5))),
  Annonce(
    id: 'A004', titre: 'Emploi du temps L1 — Semaine 18',
    contenu: 'L\'emploi du temps de la semaine 18 pour les L1 '
        'est disponible en pièce jointe.',
    type: TypeAnnonce.emploiDuTemps,
    portee: PorteeAnnonce.parNiveau,
    niveau: 'Licence 1',
    statut: StatutAnnonce.publie,
    dateCreation: DateTime.now().subtract(const Duration(days: 2)),
    piecesJointes: [
      PieceJointe(nom: 'EDT_L1_Semaine18.pdf', type: 'pdf'),
    ]),
];

// ════════════════════════════════════════════════════════════════════════════
// PAGE ADMIN ANNONCES
// ════════════════════════════════════════════════════════════════════════════
class AdminAnnonces extends StatefulWidget {
  const AdminAnnonces({super.key});
  @override State<AdminAnnonces> createState() => _AdminAnnoncesState();
}

class _AdminAnnoncesState extends State<AdminAnnonces>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  List<Annonce> get _filtre {
    var list = List<Annonce>.from(_annonces);
    if (_query.isNotEmpty) {
      list = list.where((a) =>
          a.titre.toLowerCase().contains(_query.toLowerCase()) ||
          a.contenu.toLowerCase().contains(_query.toLowerCase())).toList();
    }
    return list;
  }

  List<Annonce> _par(StatutAnnonce? statut) => statut == null
      ? _filtre
      : _filtre.where((a) => a.statut == statut).toList();

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdminTheme.isDesktop(context);
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      body: Column(children: [
        // Header
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(20, isDesktop ? 20 : 16, 20, 0),
          child: Column(children: [
            Row(children: [
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Annonces', style: TextStyle(fontSize: 22,
                    fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                Text('${_annonces.length} annonce(s) au total',
                    style: const TextStyle(
                        fontSize: 13, color: AdminTheme.textSecondary)),
              ])),
              _boutonNouvelle(),
            ]),
            const SizedBox(height: 12),
            // Barre recherche
            Container(height: 38,
              decoration: BoxDecoration(color: AdminTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AdminTheme.border)),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Rechercher une annonce...',
                  hintStyle: TextStyle(
                      fontSize: 13, color: AdminTheme.textMuted),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AdminTheme.textMuted, size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10)))),
            const SizedBox(height: 10),
            TabBar(controller: _tabs,
              labelColor: AdminTheme.primary,
              unselectedLabelColor: AdminTheme.textSecondary,
              indicatorColor: AdminTheme.primary,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12),
              tabs: [
                Tab(text: 'Toutes (${_filtre.length})'),
                Tab(text: 'Publiées (${_par(StatutAnnonce.publie).length})'),
                Tab(text: 'Brouillons (${_par(StatutAnnonce.brouillon).length})'),
              ]),
          ])),
        Container(height: 1, color: AdminTheme.border),
        Expanded(child: TabBarView(controller: _tabs, children: [
          _liste(_par(null)),
          _liste(_par(StatutAnnonce.publie)),
          _liste(_par(StatutAnnonce.brouillon)),
        ])),
      ]),
    );
  }

  Widget _boutonNouvelle() => GestureDetector(
    onTap: () => _ouvrirFormulaire(),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(color: AdminTheme.primary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(
              color: AdminTheme.primary.withOpacity(0.3),
              blurRadius: 6, offset: const Offset(0, 2))]),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.add_rounded, color: Colors.white, size: 18),
        SizedBox(width: 5),
        Text('Nouvelle', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w700, color: Colors.white)),
      ])));

  Widget _liste(List<Annonce> annonces) {
    if (annonces.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 60, height: 60,
          decoration: BoxDecoration(color: AdminTheme.primaryLight,
              borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.campaign_outlined,
              color: AdminTheme.primary, size: 28)),
        const SizedBox(height: 12),
        const Text('Aucune annonce', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Créez votre première annonce',
            style: TextStyle(fontSize: 13, color: AdminTheme.textSecondary)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: annonces.length,
      itemBuilder: (_, i) => _carteAnnonce(annonces[i]));
  }

  Widget _carteAnnonce(Annonce a) {
    final config = _configType(a.type);
    final porteeLabel = _porteeLabel(a);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AdminTheme.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        // Header carte
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: BoxDecoration(
              color: config['color'].withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14))),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(
                  color: config['color'].withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(config['emoji'],
                  style: const TextStyle(fontSize: 18)))),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.titre, style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: config['color'].withOpacity(0.12),
                      borderRadius: BorderRadius.circular(5)),
                  child: Text(config['label'], style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: config['color']))),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(5)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.people_outline_rounded,
                        size: 9, color: AdminTheme.textSecondary),
                    const SizedBox(width: 3),
                    Text(porteeLabel, style: const TextStyle(
                        fontSize: 9, color: AdminTheme.textSecondary,
                        fontWeight: FontWeight.w600)),
                  ])),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _badgeStatut(a.statut),
              const SizedBox(height: 4),
              Text(_dateFormatee(a.dateCreation), style: const TextStyle(
                  fontSize: 10, color: AdminTheme.textMuted)),
            ]),
          ])),
        // Corps
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Text(a.contenu, style: const TextStyle(
              fontSize: 13, color: AdminTheme.textSecondary,
              height: 1.5),
              maxLines: 2, overflow: TextOverflow.ellipsis)),
        // Pièces jointes
        if (a.piecesJointes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Wrap(spacing: 6, children: a.piecesJointes.map((p) =>
                _chipPJ(p)).toList())),
        // Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Row(children: [
            GestureDetector(
              onTap: () => _ouvrirFormulaire(annonce: a),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: AdminTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.edit_outlined,
                      size: 14, color: AdminTheme.primary),
                  SizedBox(width: 4),
                  Text('Modifier', style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AdminTheme.primary)),
                ]))),
            const SizedBox(width: 8),
            if (a.statut == StatutAnnonce.brouillon)
              GestureDetector(
                onTap: () => setState(() => a.statut = StatutAnnonce.publie),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: AdminTheme.successLight,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.send_rounded,
                        size: 14, color: AdminTheme.success),
                    SizedBox(width: 4),
                    Text('Publier', style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AdminTheme.success)),
                  ]))),
            if (a.statut == StatutAnnonce.publie)
              GestureDetector(
                onTap: () => setState(() => a.statut = StatutAnnonce.brouillon),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.archive_outlined,
                        size: 14, color: Color(0xFFF59E0B)),
                    SizedBox(width: 4),
                    Text('Archiver', style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF59E0B))),
                  ]))),
            const Spacer(),
            GestureDetector(
              onTap: () => _confirmerSuppression(a),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: AdminTheme.dangerLight,
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: AdminTheme.danger))),
          ])),
      ]));
  }

  Widget _chipPJ(PieceJointe p) {
    final cfg = _configPJ(p.type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: (cfg['color'] as Color).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: (cfg['color'] as Color).withOpacity(0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(cfg['icon'] as IconData,
            size: 12, color: cfg['color'] as Color),
        const SizedBox(width: 4),
        Text(p.nom, style: TextStyle(fontSize: 10,
            fontWeight: FontWeight.w600,
            color: cfg['color'] as Color),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]));
  }

  Widget _badgeStatut(StatutAnnonce s) {
    final isPub = s == StatutAnnonce.publie;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: isPub ? AdminTheme.successLight : const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6,
          decoration: BoxDecoration(
              color: isPub ? AdminTheme.success : const Color(0xFFF59E0B),
              shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(isPub ? 'Publié' : 'Brouillon', style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: isPub ? AdminTheme.success : const Color(0xFFF59E0B))),
      ]));
  }

  // ── Formulaire nouvelle/modifier annonce ──────────────────────────────
  void _ouvrirFormulaire({Annonce? annonce}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormulaireAnnonce(
        annonce: annonce,
        onSave: (a, statut) {
          setState(() {
            if (annonce != null) {
              final idx = _annonces.indexWhere((x) => x.id == annonce.id);
              if (idx != -1) {
                _annonces[idx]
                  ..titre = a.titre
                  ..contenu = a.contenu
                  ..type = a.type
                  ..portee = a.portee
                  ..statut = statut
                  ..piecesJointes = a.piecesJointes;
              }
            } else {
              a.statut = statut;
              _annonces.insert(0, a);
            }
          });
        }));
  }

  void _confirmerSuppression(Annonce a) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Supprimer l\'annonce ?'),
      content: Text('« ${a.titre} » sera définitivement supprimée.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () { Navigator.pop(context);
            setState(() => _annonces.removeWhere((x) => x.id == a.id)); },
          style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.danger, foregroundColor: Colors.white),
          child: const Text('Supprimer')),
      ]));
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  Map<String, dynamic> _configType(TypeAnnonce t) {
    switch (t) {
      case TypeAnnonce.important:
        return {'emoji': '🚨', 'label': 'Important',
            'color': const Color(0xFFDC2626)};
      case TypeAnnonce.note:
        return {'emoji': '📊', 'label': 'Note',
            'color': const Color(0xFF0891B2)};
      case TypeAnnonce.evenement:
        return {'emoji': '🎉', 'label': 'Événement',
            'color': const Color(0xFF7C3AED)};
      case TypeAnnonce.emploiDuTemps:
        return {'emoji': '📅', 'label': 'Emploi du temps',
            'color': const Color(0xFF059669)};
    }
  }

  Map<String, dynamic> _configPJ(String type) {
    switch (type) {
      case 'pdf':   return {'icon': Icons.picture_as_pdf_rounded,
          'color': const Color(0xFFDC2626)};
      case 'word':  return {'icon': Icons.article_rounded,
          'color': const Color(0xFF1D4ED8)};
      case 'image': return {'icon': Icons.image_rounded,
          'color': const Color(0xFF059669)};
      case 'video': return {'icon': Icons.videocam_rounded,
          'color': const Color(0xFF7C3AED)};
      case 'lien':  return {'icon': Icons.link_rounded,
          'color': const Color(0xFF0891B2)};
      default:      return {'icon': Icons.attach_file_rounded,
          'color': AdminTheme.textMuted};
    }
  }

  String _porteeLabel(Annonce a) {
    switch (a.portee) {
      case PorteeAnnonce.tousTesEtudiants: return 'Tous les étudiants';
      case PorteeAnnonce.parFiliere:
        return a.filiereId != null ? 'Filière ciblée' : 'Par filière';
      case PorteeAnnonce.parNiveau:
        return a.niveau ?? 'Par niveau';
    }
  }

  String _dateFormatee(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ════════════════════════════════════════════════════════════════════════════
// FORMULAIRE ANNONCE — style MaisonPlus
// ════════════════════════════════════════════════════════════════════════════
class _FormulaireAnnonce extends StatefulWidget {
  final Annonce? annonce;
  final void Function(Annonce, StatutAnnonce) onSave;
  const _FormulaireAnnonce({this.annonce, required this.onSave});
  @override State<_FormulaireAnnonce> createState() =>
      _FormulaireAnnonceState();
}

class _FormulaireAnnonceState extends State<_FormulaireAnnonce> {
  final _titreCtrl   = TextEditingController();
  final _contenuCtrl = TextEditingController();
  final _lienCtrl    = TextEditingController();

  TypeAnnonce _type      = TypeAnnonce.important;
  PorteeAnnonce _portee  = PorteeAnnonce.tousTesEtudiants;
  String? _filiereId, _niveau;
  final List<PieceJointe> _pj = [];

  // Données filières et niveaux mock
  final List<Map<String, String>> _filieres = [
    {'id': 'F001', 'nom': 'Réseaux Informatiques et Télécom (RIT)'},
    {'id': 'F002', 'nom': 'Électrotechnique'},
    {'id': 'F003', 'nom': 'Maintenance Industrielle'},
    {'id': 'F004', 'nom': 'Marketing'},
    {'id': 'F005', 'nom': 'Finance Comptabilité'},
    {'id': 'F006', 'nom': 'Communication'},
  ];
  final List<String> _niveaux = [
    'Licence 1', 'Licence 2', 'Licence 3',
    'BTS 1', 'BTS 2',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.annonce != null) {
      final a = widget.annonce!;
      _titreCtrl.text   = a.titre;
      _contenuCtrl.text = a.contenu;
      _type     = a.type;
      _portee   = a.portee;
      _filiereId = a.filiereId;
      _niveau   = a.niveau;
      _pj.addAll(a.piecesJointes);
    }
  }

  @override
  void dispose() {
    _titreCtrl.dispose(); _contenuCtrl.dispose(); _lienCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        // Handle
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(2))),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(children: [
            Expanded(child: Text(
              widget.annonce == null
                  ? 'Nouvelle annonce' : 'Modifier l\'annonce',
              style: const TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w800))),
            GestureDetector(onTap: () => Navigator.pop(context),
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                    color: AdminTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.close_rounded,
                    color: AdminTheme.textSecondary, size: 18))),
          ])),
        Container(height: 1, margin: const EdgeInsets.only(top: 14),
            color: const Color(0xFFE2E8F0)),
        // Formulaire scrollable
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Titre
            _label('Titre de l\'annonce *'),
            const SizedBox(height: 6),
            _champ(controller: _titreCtrl,
                hint: 'Ex: Calendrier des examens...',
                prefix: const Icon(Icons.title_rounded,
                    size: 16, color: AdminTheme.textMuted)),
            const SizedBox(height: 16),
            // Contenu
            _label('Contenu *'),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                  color: AdminTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AdminTheme.border)),
              child: TextField(
                controller: _contenuCtrl, maxLines: 5,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Rédigez le contenu de votre annonce...',
                  hintStyle: TextStyle(fontSize: 13,
                      color: AdminTheme.textMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14)))),
            const SizedBox(height: 16),
            // TYPE — grille rectangulaire style MaisonPlus
            _label('Type d\'annonce'),
            const SizedBox(height: 8),
            _grilleType(),
            const SizedBox(height: 16),
            // PORTÉE — grille rectangulaire
            _label('Portée'),
            const SizedBox(height: 8),
            _grillePortee(),
            // Sélection filière ou niveau
            if (_portee == PorteeAnnonce.parFiliere) ...[
              const SizedBox(height: 12),
              _label('Filière ciblée'),
              const SizedBox(height: 6),
              _dropdownFiliere(),
            ],
            if (_portee == PorteeAnnonce.parNiveau) ...[
              const SizedBox(height: 12),
              _label('Niveau ciblé'),
              const SizedBox(height: 6),
              _dropdownNiveau(),
            ],
            const SizedBox(height: 16),
            // PIÈCES JOINTES
            _label('Pièces jointes'),
            const SizedBox(height: 8),
            _grillePJ(),
            if (_pj.isNotEmpty) ...[
              const SizedBox(height: 10),
              ..._pj.map((p) => _itemPJ(p)),
            ],
            const SizedBox(height: 24),
          ]))),
        // Boutons footer
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
          child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => _sauvegarder(StatutAnnonce.brouillon),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                    color: AdminTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminTheme.border)),
                child: const Center(child: Text('Brouillon',
                    style: TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AdminTheme.textSecondary)))))),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: GestureDetector(
              onTap: () => _sauvegarder(StatutAnnonce.publie),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                    color: AdminTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(
                        color: AdminTheme.primary.withOpacity(0.3),
                        blurRadius: 6, offset: const Offset(0, 2))]),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Text('📢', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text('Publier maintenant', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Colors.white)),
                ])))),
          ])),
      ]));
  }

  // ── Grille Type (style MaisonPlus) ────────────────────────────────────
  Widget _grilleType() {
    final types = [
      {'val': TypeAnnonce.important,     'emoji': '🚨', 'label': 'Important'},
      {'val': TypeAnnonce.note,          'emoji': '📊', 'label': 'Note'},
      {'val': TypeAnnonce.evenement,     'emoji': '🎉', 'label': 'Événement'},
      {'val': TypeAnnonce.emploiDuTemps, 'emoji': '📅', 'label': 'Emploi du temps'},
    ];
    // Rangées de 3 comme MaisonPlus
    return Column(children: [
      Row(children: types.take(3).map((t) => _btnSelection(
        label: t['label'] as String,
        emoji: t['emoji'] as String,
        selected: _type == t['val'],
        onTap: () => setState(() => _type = t['val'] as TypeAnnonce),
      )).toList()),
      const SizedBox(height: 8),
      Row(children: types.skip(3).map((t) => _btnSelection(
        label: t['label'] as String,
        emoji: t['emoji'] as String,
        selected: _type == t['val'],
        onTap: () => setState(() => _type = t['val'] as TypeAnnonce),
      )).toList()),
    ]);
  }

  // ── Grille Portée ─────────────────────────────────────────────────────
  Widget _grillePortee() {
    final portees = [
      {'val': PorteeAnnonce.tousTesEtudiants, 'emoji': '🌍',
          'label': 'Tous les étudiants'},
      {'val': PorteeAnnonce.parFiliere, 'emoji': '🎓', 'label': 'Par filière'},
      {'val': PorteeAnnonce.parNiveau,  'emoji': '📚', 'label': 'Par niveau'},
    ];
    return Row(children: portees.map((p) => _btnSelection(
      label: p['label'] as String,
      emoji: p['emoji'] as String,
      selected: _portee == p['val'],
      onTap: () => setState(() {
        _portee = p['val'] as PorteeAnnonce;
        _filiereId = null; _niveau = null;
      }),
    )).toList());
  }

  // ── Grille Pièces jointes ─────────────────────────────────────────────
  Widget _grillePJ() {
    final types = [
      {'type': 'pdf',   'label': 'PDF',    'emoji': '📄',
          'color': const Color(0xFFDC2626)},
      {'type': 'word',  'label': 'Word',   'emoji': '📝',
          'color': const Color(0xFF1D4ED8)},
      {'type': 'image', 'label': 'Image',  'emoji': '🖼️',
          'color': const Color(0xFF059669)},
      {'type': 'video', 'label': 'Vidéo',  'emoji': '🎬',
          'color': const Color(0xFF7C3AED)},
      {'type': 'lien',  'label': 'Lien',   'emoji': '🔗',
          'color': const Color(0xFF0891B2)},
    ];
    return Wrap(spacing: 8, runSpacing: 8, children: types.map((t) =>
        GestureDetector(
          onTap: () => _ajouterPJ(t['type'] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.03), blurRadius: 4)]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(t['emoji'] as String,
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(t['label'] as String, style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: Color(0xFF374151))),
            ])))).toList());
  }

  Widget _itemPJ(PieceJointe p) {
    final cfg = _configPJ(p.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: (cfg['color'] as Color).withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: (cfg['color'] as Color).withOpacity(0.2))),
      child: Row(children: [
        Icon(cfg['icon'] as IconData,
            size: 16, color: cfg['color'] as Color),
        const SizedBox(width: 8),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.nom, style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700)),
          if (p.url != null)
            Text(p.url!, style: const TextStyle(
                fontSize: 10, color: AdminTheme.textMuted),
                maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        GestureDetector(
          onTap: () => setState(() => _pj.remove(p)),
          child: const Icon(Icons.close_rounded,
              size: 16, color: AdminTheme.textMuted)),
      ]));
  }

  Map<String, dynamic> _configPJ(String type) {
    switch (type) {
      case 'pdf':   return {'icon': Icons.picture_as_pdf_rounded,
          'color': const Color(0xFFDC2626)};
      case 'word':  return {'icon': Icons.article_rounded,
          'color': const Color(0xFF1D4ED8)};
      case 'image': return {'icon': Icons.image_rounded,
          'color': const Color(0xFF059669)};
      case 'video': return {'icon': Icons.videocam_rounded,
          'color': const Color(0xFF7C3AED)};
      case 'lien':  return {'icon': Icons.link_rounded,
          'color': const Color(0xFF0891B2)};
      default:      return {'icon': Icons.attach_file_rounded,
          'color': AdminTheme.textMuted};
    }
  }

  Widget _dropdownFiliere() => Container(
    decoration: BoxDecoration(color: AdminTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminTheme.border)),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
      value: _filiereId,
      hint: const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text('Choisir une filière',
            style: TextStyle(fontSize: 13, color: AdminTheme.textMuted))),
      isExpanded: true,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      borderRadius: BorderRadius.circular(10),
      items: _filieres.map((f) => DropdownMenuItem(
          value: f['id'],
          child: Text(f['nom']!, style: const TextStyle(fontSize: 13))))
          .toList(),
      onChanged: (v) => setState(() => _filiereId = v))));

  Widget _dropdownNiveau() => Container(
    decoration: BoxDecoration(color: AdminTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminTheme.border)),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
      value: _niveau,
      hint: const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text('Choisir un niveau',
            style: TextStyle(fontSize: 13, color: AdminTheme.textMuted))),
      isExpanded: true,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      borderRadius: BorderRadius.circular(10),
      items: _niveaux.map((n) => DropdownMenuItem(
          value: n, child: Text(n, style: const TextStyle(fontSize: 13))))
          .toList(),
      onChanged: (v) => setState(() => _niveau = v))));

  // ── Helpers ───────────────────────────────────────────────────────────
  // ── Bouton sélection style MaisonPlus ────────────────────────────────
  // Fond blanc + bord gris → sélectionné : fond bleu clair + bord bleu
  Widget _btnSelection({
    required String label,
    required String emoji,
    required bool selected,
    required VoidCallback onTap,
  }) => Expanded(child: GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: selected
                ? const Color(0xFF1D4ED8) : const Color(0xFFD1D5DB),
            width: selected ? 2 : 1)),
      child: Center(child: Text(
        '$emoji  $label',
        style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: selected
              ? const Color(0xFF1D4ED8) : const Color(0xFF374151)),
        textAlign: TextAlign.center,
        maxLines: 1, overflow: TextOverflow.ellipsis)))));

  Widget _label(String text) => Text(text, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151)));

  Widget _champ({required TextEditingController controller,
      required String hint, Widget? prefix}) =>
      Container(
        decoration: BoxDecoration(color: AdminTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AdminTheme.border)),
        child: TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
              hintText: hint, hintStyle: const TextStyle(
                  fontSize: 13, color: AdminTheme.textMuted),
              prefixIcon: prefix, border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12))));

  void _ajouterPJ(String type) {
    if (type == 'lien') {
      _lienCtrl.clear();
      showDialog(context: context, builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ajouter un lien'),
        content: Container(
          decoration: BoxDecoration(color: AdminTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AdminTheme.border)),
          child: TextField(
            controller: _lienCtrl,
            decoration: const InputDecoration(
              hintText: 'https://...',
              hintStyle: TextStyle(color: AdminTheme.textMuted),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final url = _lienCtrl.text.trim();
              if (url.isNotEmpty) {
                setState(() => _pj.add(
                    PieceJointe(nom: url, type: 'lien', url: url)));
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.primary,
                foregroundColor: Colors.white),
            child: const Text('Ajouter')),
        ]));
      return;
    }
    // Simulation upload fichier
    final noms = {
      'pdf':   'document.pdf',
      'word':  'document.docx',
      'image': 'photo.jpg',
      'video': 'video.mp4',
    };
    setState(() => _pj.add(PieceJointe(
        nom: noms[type] ?? 'fichier', type: type)));
  }

  void _sauvegarder(StatutAnnonce statut) {
    final titre   = _titreCtrl.text.trim();
    final contenu = _contenuCtrl.text.trim();
    if (titre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('⚠️ Le titre est requis'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating));
      return;
    }
    if (contenu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('⚠️ Le contenu est requis'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating));
      return;
    }
    final a = Annonce(
      id: widget.annonce?.id ??
          'A${DateTime.now().millisecondsSinceEpoch}',
      titre: titre, contenu: contenu,
      type: _type, portee: _portee,
      filiereId: _filiereId, niveau: _niveau,
      statut: statut,
      dateCreation: widget.annonce?.dateCreation ?? DateTime.now(),
      piecesJointes: List.from(_pj));
    widget.onSave(a, statut);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(statut == StatutAnnonce.publie
          ? '✅ Annonce publiée !' : '💾 Brouillon sauvegardé'),
      backgroundColor: statut == StatutAnnonce.publie
          ? AdminTheme.success : const Color(0xFFF59E0B),
      behavior: SnackBarBehavior.floating));
  }
}

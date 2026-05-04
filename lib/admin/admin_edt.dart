import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES
// ════════════════════════════════════════════════════════════════════════════
class EdtFichier {
  final String id, nom, domaine, niveau, semaine, dateAjout;
  final String taille;
  bool actif;

  EdtFichier({
    required this.id,
    required this.nom,
    required this.domaine,
    required this.niveau,
    required this.semaine,
    required this.dateAjout,
    required this.taille,
    this.actif = true,
  });
}

// ── Données mock ─────────────────────────────────────────────────────────
final List<EdtFichier> adminEdtFichiers = [
  EdtFichier(
    id: 'E001', nom: 'EDT_ST_L1_Semaine18.pdf',
    domaine: 'Sciences & Technologies', niveau: 'Licence 1',
    semaine: 'Semaine 18 — 28 Avr au 02 Mai 2026',
    dateAjout: '27/04/2026', taille: '245 Ko', actif: true,
  ),
  EdtFichier(
    id: 'E002', nom: 'EDT_ST_L2_Semaine18.pdf',
    domaine: 'Sciences & Technologies', niveau: 'Licence 2',
    semaine: 'Semaine 18 — 28 Avr au 02 Mai 2026',
    dateAjout: '27/04/2026', taille: '312 Ko', actif: true,
  ),
  EdtFichier(
    id: 'E003', nom: 'EDT_ST_L3_Semaine18.pdf',
    domaine: 'Sciences & Technologies', niveau: 'Licence 3',
    semaine: 'Semaine 18 — 28 Avr au 02 Mai 2026',
    dateAjout: '27/04/2026', taille: '289 Ko', actif: true,
  ),
  EdtFichier(
    id: 'E004', nom: 'EDT_SG_L1_Semaine18.pdf',
    domaine: 'Sciences de Gestion', niveau: 'Licence 1',
    semaine: 'Semaine 18 — 28 Avr au 02 Mai 2026',
    dateAjout: '27/04/2026', taille: '198 Ko', actif: true,
  ),
  EdtFichier(
    id: 'E005', nom: 'EDT_SG_L2_Semaine18.pdf',
    domaine: 'Sciences de Gestion', niveau: 'Licence 2',
    semaine: 'Semaine 18 — 28 Avr au 02 Mai 2026',
    dateAjout: '27/04/2026', taille: '221 Ko', actif: true,
  ),
  EdtFichier(
    id: 'E006', nom: 'EDT_SG_L3_Semaine18.pdf',
    domaine: 'Sciences de Gestion', niveau: 'Licence 3',
    semaine: 'Semaine 18 — 28 Avr au 02 Mai 2026',
    dateAjout: '27/04/2026', taille: '267 Ko', actif: false,
  ),
  EdtFichier(
    id: 'E007', nom: 'EDT_ST_L1_Semaine17.pdf',
    domaine: 'Sciences & Technologies', niveau: 'Licence 1',
    semaine: 'Semaine 17 — 21 Avr au 25 Avr 2026',
    dateAjout: '20/04/2026', taille: '240 Ko', actif: false,
  ),
  EdtFichier(
    id: 'E008', nom: 'EDT_ST_L2_Semaine17.pdf',
    domaine: 'Sciences & Technologies', niveau: 'Licence 2',
    semaine: 'Semaine 17 — 21 Avr au 25 Avr 2026',
    dateAjout: '20/04/2026', taille: '305 Ko', actif: false,
  ),
];

// ════════════════════════════════════════════════════════════════════════════
// PAGE EMPLOIS DU TEMPS
// ════════════════════════════════════════════════════════════════════════════
class AdminEDT extends StatefulWidget {
  const AdminEDT({super.key});

  @override
  State<AdminEDT> createState() => _AdminEDTState();
}

class _AdminEDTState extends State<AdminEDT>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _filtreDomaine = 'tous';
  String _filtreNiveau  = 'tous';
  String _query         = '';

  final List<String> _domaines = ['tous', 'Sciences & Technologies', 'Sciences de Gestion'];
  final List<String> _niveaux  = ['tous', 'Licence 1', 'Licence 2', 'Licence 3', 'BTS 1', 'BTS 2'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<EdtFichier> get _actifs => adminEdtFichiers.where((e) {
    return e.actif &&
        (_filtreDomaine == 'tous' || e.domaine == _filtreDomaine) &&
        (_filtreNiveau  == 'tous' || e.niveau  == _filtreNiveau)  &&
        (_query.isEmpty || e.nom.toLowerCase().contains(_query.toLowerCase()) ||
            e.niveau.toLowerCase().contains(_query.toLowerCase()));
  }).toList();

  List<EdtFichier> get _archives => adminEdtFichiers.where((e) {
    return !e.actif &&
        (_filtreDomaine == 'tous' || e.domaine == _filtreDomaine) &&
        (_filtreNiveau  == 'tous' || e.niveau  == _filtreNiveau);
  }).toList();

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdminTheme.isDesktop(context);
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      body: Column(children: [
        _buildHeader(isDesktop),
        Container(height: 1, color: AdminTheme.border),
        Expanded(child: TabBarView(controller: _tabs, children: [
          _buildListe(_actifs, actif: true),
          _buildListe(_archives, actif: false),
        ])),
      ]),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDesktop) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, 20, isDesktop ? 24 : 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Emplois du temps', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E))),
            Text('${_actifs.length} EDT actif(s) · ${_archives.length} archivé(s)',
                style: const TextStyle(
                    fontSize: 13, color: AdminTheme.textSecondary)),
          ])),
          GestureDetector(
            onTap: () => _dialogAjouter(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AdminTheme.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(
                    color: AdminTheme.primary.withOpacity(0.3),
                    blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.upload_file_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text('Publier un EDT', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: Colors.white)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Info règle
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: AdminTheme.infoLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AdminTheme.info.withOpacity(0.2))),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, color: AdminTheme.info, size: 14),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Un EDT par domaine + niveau (ex: Sciences & Technologies · L2 = 1 PDF pour '
              'toutes les filières ST L2 : RIT, Électrotechnique, etc.)',
              style: TextStyle(fontSize: 11, color: AdminTheme.info,
                  fontWeight: FontWeight.w500))),
          ]),
        ),
        const SizedBox(height: 12),

        // Recherche + filtres
        if (isDesktop)
          Row(children: [
            Expanded(flex: 3, child: _searchBar()),
            const SizedBox(width: 10),
            Expanded(child: _dropdown('Domaine', _filtreDomaine, _domaines,
                    (v) => setState(() => _filtreDomaine = v!))),
            const SizedBox(width: 10),
            Expanded(child: _dropdown('Niveau', _filtreNiveau, _niveaux,
                    (v) => setState(() => _filtreNiveau = v!))),
          ])
        else
          Column(children: [
            _searchBar(),
            const SizedBox(height: 8),
            SingleChildScrollView(scrollDirection: Axis.horizontal,
              child: Row(children: [
                _filtreChip('Tous', _filtreDomaine == 'tous',
                    () => setState(() { _filtreDomaine = 'tous'; _filtreNiveau = 'tous'; })),
                const SizedBox(width: 6),
                _filtreChip('ST', _filtreDomaine == 'Sciences & Technologies',
                    () => setState(() => _filtreDomaine = 'Sciences & Technologies')),
                const SizedBox(width: 6),
                _filtreChip('SG', _filtreDomaine == 'Sciences de Gestion',
                    () => setState(() => _filtreDomaine = 'Sciences de Gestion')),
                const SizedBox(width: 6),
                _filtreChip('L1', _filtreNiveau == 'Licence 1',
                    () => setState(() => _filtreNiveau = 'Licence 1')),
                const SizedBox(width: 6),
                _filtreChip('L2', _filtreNiveau == 'Licence 2',
                    () => setState(() => _filtreNiveau = 'Licence 2')),
                const SizedBox(width: 6),
                _filtreChip('L3', _filtreNiveau == 'Licence 3',
                    () => setState(() => _filtreNiveau = 'Licence 3')),
              ])),
          ]),
        const SizedBox(height: 12),

        TabBar(
          controller: _tabs,
          labelColor: AdminTheme.primary,
          unselectedLabelColor: AdminTheme.textSecondary,
          indicatorColor: AdminTheme.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'Actifs (${_actifs.length})'),
            Tab(text: 'Archives (${_archives.length})'),
          ],
        ),
      ]),
    );
  }

  // ── Liste ─────────────────────────────────────────────────────────────
  Widget _buildListe(List<EdtFichier> items, {required bool actif}) {
    if (items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 64, height: 64,
          decoration: BoxDecoration(
              color: AdminTheme.primaryLight,
              borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.calendar_month_outlined,
              color: AdminTheme.primary, size: 30)),
        const SizedBox(height: 12),
        Text(actif ? 'Aucun EDT publié' : 'Aucun EDT archivé',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(actif ? 'Publiez un EDT pour qu\'il soit visible par les étudiants.'
            : 'Les EDT remplacés apparaîtront ici.',
            style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary),
            textAlign: TextAlign.center),
        if (actif) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _dialogAjouter(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                  color: AdminTheme.primary,
                  borderRadius: BorderRadius.circular(10)),
              child: const Text('Publier un EDT', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
          ),
        ],
      ]));
    }

    // Grouper par domaine
    final Map<String, List<EdtFichier>> grouped = {};
    for (final e in items) {
      grouped.putIfAbsent(e.domaine, () => []).add(e);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        final domaine = entry.key;
        final fichiers = entry.value;
        final isDomaineST = domaine.contains('Technologies');
        final color = isDomaineST ? AdminTheme.primary : AdminTheme.warning;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre domaine
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(width: 4, height: 20,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text(domaine, style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('${fichiers.length} EDT', style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, color: color))),
              ]),
            ),
            // Grille des EDT
            ...fichiers.map((f) => _carteEDT(f, actif: actif)),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  // ── Carte EDT ─────────────────────────────────────────────────────────
  Widget _carteEDT(EdtFichier f, {required bool actif}) {
    final isDomaineST = f.domaine.contains('Technologies');
    final color = isDomaineST ? AdminTheme.primary : AdminTheme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: actif ? AdminTheme.border : const Color(0xFFE5E7EB)),
        boxShadow: actif ? [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))] : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          // Icône PDF
          Container(width: 48, height: 48,
            decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.picture_as_pdf_rounded,
                color: Color(0xFFDC2626), size: 26)),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(f.nom, style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E)),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (!actif)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(6)),
                  child: const Text('Archivé', style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: Color(0xFF9CA3AF)))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(f.niveau, style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: color))),
              const SizedBox(width: 6),
              Expanded(child: Text(f.semaine, style: const TextStyle(
                  fontSize: 11, color: AdminTheme.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 11, color: AdminTheme.textMuted),
              const SizedBox(width: 3),
              Text('Publié le ${f.dateAjout}', style: const TextStyle(
                  fontSize: 10, color: AdminTheme.textMuted)),
              const SizedBox(width: 10),
              const Icon(Icons.storage_rounded,
                  size: 11, color: AdminTheme.textMuted),
              const SizedBox(width: 3),
              Text(f.taille, style: const TextStyle(
                  fontSize: 10, color: AdminTheme.textMuted)),
            ]),
          ])),
          const SizedBox(width: 8),
          // Actions
          Column(children: [
            GestureDetector(
              onTap: () => _snack('📄 Ouverture de ${f.nom}...'),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                    color: AdminTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.visibility_outlined,
                    color: AdminTheme.primary, size: 16)),
            ),
            const SizedBox(height: 6),
            if (actif)
              GestureDetector(
                onTap: () => _confirmerRemplacement(f),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                      color: AdminTheme.warningLight,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.upload_rounded,
                      color: AdminTheme.warning, size: 16)),
              )
            else
              GestureDetector(
                onTap: () => _confirmerSuppression(f),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                      color: AdminTheme.dangerLight,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AdminTheme.danger, size: 16)),
              ),
          ]),
        ]),
      ),
    );
  }

  // ── Dialog ajouter un EDT ─────────────────────────────────────────────
  void _dialogAjouter({EdtFichier? remplace}) {
    String? domaineChoisi = remplace?.domaine;
    String? niveauChoisi  = remplace?.niveau;
    String? semaine;
    bool fichierSelectionne = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(builder: (ctx, setS) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            // ✅ FIX: Column avec Expanded contenant SingleChildScrollView
            child: Column(children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AdminTheme.border,
                    borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(children: [
                  Expanded(child: Text(
                    remplace != null ? 'Remplacer l\'EDT' : 'Publier un EDT',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(width: 30, height: 30,
                      decoration: BoxDecoration(color: AdminTheme.surfaceAlt,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.close_rounded, size: 16,
                          color: AdminTheme.textSecondary))),
                ]),
              ),
              const Divider(color: Color(0xFFE5E7EB)),
              // ✅ FIX : Expanded ici, pas autour de SingleChildScrollView seul
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info règle
                      if (remplace == null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: AdminTheme.infoLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AdminTheme.info.withOpacity(0.2))),
                          child: const Row(children: [
                            Icon(Icons.info_outline_rounded,
                                color: AdminTheme.info, size: 14),
                            SizedBox(width: 8),
                            Expanded(child: Text(
                              '1 PDF par domaine + niveau. '
                              'Si un EDT existe déjà pour ce domaine+niveau, '
                              'il sera automatiquement archivé.',
                              style: TextStyle(fontSize: 11,
                                  color: AdminTheme.info,
                                  fontWeight: FontWeight.w500))),
                          ]),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Domaine
                      const Text('Domaine', style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: Color(0xFF374151))),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _btnSelection(
                          label: '🔬 Sciences & Tech',
                          selected: domaineChoisi == 'Sciences & Technologies',
                          enabled: remplace == null,
                          onTap: () => setS(() => domaineChoisi = 'Sciences & Technologies'),
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: _btnSelection(
                          label: '📊 Sciences de Gestion',
                          selected: domaineChoisi == 'Sciences de Gestion',
                          enabled: remplace == null,
                          onTap: () => setS(() => domaineChoisi = 'Sciences de Gestion'),
                        )),
                      ]),
                      const SizedBox(height: 16),

                      // Niveau
                      const Text('Niveau', style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: Color(0xFF374151))),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8,
                        children: ['Licence 1', 'Licence 2', 'Licence 3',
                            'BTS 1', 'BTS 2'].map((n) {
                          return GestureDetector(
                            onTap: remplace != null ? null
                                : () => setS(() => niveauChoisi = n),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: niveauChoisi == n
                                    ? const Color(0xFFEFF6FF) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: niveauChoisi == n
                                        ? const Color(0xFF1D4ED8)
                                        : const Color(0xFFD1D5DB),
                                    width: niveauChoisi == n ? 2 : 1),
                              ),
                              child: Text(n, style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: niveauChoisi == n
                                      ? const Color(0xFF1D4ED8)
                                      : const Color(0xFF374151))),
                            ),
                          );
                        }).toList()),
                      const SizedBox(height: 16),

                      // Semaine
                      const Text('Semaine concernée', style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: Color(0xFF374151))),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                            color: AdminTheme.surfaceAlt,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AdminTheme.border)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: semaine,
                            hint: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('Choisir la semaine',
                                    style: TextStyle(fontSize: 13,
                                        color: AdminTheme.textMuted))),
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            borderRadius: BorderRadius.circular(10),
                            items: [
                              'Semaine 18 — 28 Avr au 02 Mai 2026',
                              'Semaine 19 — 05 Mai au 09 Mai 2026',
                              'Semaine 20 — 12 Mai au 16 Mai 2026',
                              'Semaine 21 — 19 Mai au 23 Mai 2026',
                            ].map((s) => DropdownMenuItem(value: s,
                                child: Text(s, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (v) => setS(() => semaine = v),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Upload PDF
                      const Text('Fichier PDF', style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: Color(0xFF374151))),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setS(() => fichierSelectionne = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: double.infinity, height: 110,
                          decoration: BoxDecoration(
                            color: fichierSelectionne
                                ? AdminTheme.successLight : AdminTheme.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: fichierSelectionne
                                    ? AdminTheme.success : AdminTheme.border,
                                width: fichierSelectionne ? 2 : 1),
                          ),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            Icon(
                              fichierSelectionne
                                  ? Icons.check_circle_rounded
                                  : Icons.upload_file_rounded,
                              color: fichierSelectionne
                                  ? AdminTheme.success : AdminTheme.textMuted,
                              size: 32),
                            const SizedBox(height: 8),
                            Text(
                              fichierSelectionne
                                  ? 'EDT_${domaineChoisi ?? "DOMAINE"}_${niveauChoisi ?? "NIVEAU"}.pdf'
                                  : 'Appuyer pour sélectionner le PDF',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: fichierSelectionne
                                      ? AdminTheme.success : AdminTheme.textMuted)),
                            if (!fichierSelectionne)
                              const Text('Format PDF uniquement · Max 10 Mo',
                                  style: TextStyle(fontSize: 10,
                                      color: AdminTheme.textMuted)),
                          ]),
                        ),
                      ),
                      // Espace en bas pour que le footer ne cache pas le contenu
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(color: AdminTheme.border))),
                child: GestureDetector(
                  onTap: () {
                    if (domaineChoisi == null || niveauChoisi == null ||
                        semaine == null || !fichierSelectionne) {
                      _snack('⚠️ Remplissez tous les champs et sélectionnez le PDF');
                      return;
                    }
                    // Archiver l'ancien EDT actif pour ce domaine+niveau
                    for (final e in adminEdtFichiers) {
                      if (e.domaine == domaineChoisi &&
                          e.niveau == niveauChoisi && e.actif) {
                        e.actif = false;
                      }
                    }
                    setState(() {
                      adminEdtFichiers.insert(0, EdtFichier(
                        id: 'E${DateTime.now().millisecondsSinceEpoch}',
                        nom: 'EDT_${domaineChoisi!.contains("Tech") ? "ST" : "SG"}'
                            '_${niveauChoisi!.replaceAll(" ", "")}_S${DateTime.now().millisecondsSinceEpoch % 100}.pdf',
                        domaine: domaineChoisi!,
                        niveau: niveauChoisi!,
                        semaine: semaine!,
                        dateAjout: _dateAujourdhui(),
                        taille: '${250 + (DateTime.now().millisecond % 200)} Ko',
                        actif: true,
                      ));
                    });
                    Navigator.pop(ctx);
                    _snack('✅ EDT publié avec succès ! Les étudiants peuvent le consulter.');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                        color: AdminTheme.primary,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.publish_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Publier l\'emploi du temps', style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                      ],
                    )),
                  ),
                ),
              ),
            ]),
          );
        });
      },
    );
  }

  void _confirmerRemplacement(EdtFichier f) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Remplacer cet EDT ?'),
      content: Text(
          '${f.nom} sera archivé et remplacé par le nouveau fichier.\n\n'
          '${f.domaine} · ${f.niveau}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _dialogAjouter(remplace: f);
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.primary,
              foregroundColor: Colors.white),
          child: const Text('Remplacer')),
      ]));
  }

  void _confirmerSuppression(EdtFichier f) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Supprimer définitivement ?'),
      content: Text('${f.nom} sera supprimé de l\'archive.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            setState(() => adminEdtFichiers.removeWhere((e) => e.id == f.id));
            Navigator.pop(context);
            _snack('🗑️ EDT supprimé');
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.danger,
              foregroundColor: Colors.white),
          child: const Text('Supprimer')),
      ]));
  }

  // ── Widgets helpers ───────────────────────────────────────────────────
  Widget _searchBar() => Container(
    height: 38,
    decoration: BoxDecoration(
        color: AdminTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminTheme.border)),
    child: TextField(
      onChanged: (v) => setState(() => _query = v),
      decoration: const InputDecoration(
        hintText: 'Rechercher un EDT...',
        hintStyle: TextStyle(fontSize: 13, color: AdminTheme.textMuted),
        prefixIcon: Icon(Icons.search_rounded, color: AdminTheme.textMuted, size: 18),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 10))));

  Widget _dropdown(String hint, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
          color: AdminTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AdminTheme.border)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        borderRadius: BorderRadius.circular(10),
        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
        items: items.map((i) => DropdownMenuItem(value: i,
            child: Text(i == 'tous' ? hint : i))).toList(),
        onChanged: onChanged)));
  }

  Widget _filtreChip(String label, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AdminTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: active ? AdminTheme.primary : AdminTheme.border)),
          child: Text(label, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: active ? Colors.white : AdminTheme.textSecondary))));

  Widget _btnSelection({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool enabled = true,
  }) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: selected ? const Color(0xFF1D4ED8) : const Color(0xFFD1D5DB),
            width: selected ? 2 : 1),
      ),
      child: Center(child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: selected ? const Color(0xFF1D4ED8) : const Color(0xFF374151)),
          textAlign: TextAlign.center))));

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AdminTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))));

  String _dateAujourdhui() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2, '0')}/${n.month.toString().padLeft(2, '0')}/${n.year}';
  }
}

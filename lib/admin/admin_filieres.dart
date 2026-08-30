import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../admin/admin_edt.dart';
import '../admin/admin_notes.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_widgets.dart';
import '../models/student_profile.dart';
import '../pages/groupe_filiere_screen.dart';
import '../services/api_service.dart';
import '../services/professor_service.dart';
import '../utils/snackbar_helper.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES
// ════════════════════════════════════════════════════════════════════════════
class Module {
  final String id, nom, code;
  final int coefficient, volumeHoraire;
  String professeur;
  Module({required this.id, required this.nom, required this.code,
      required this.coefficient, required this.volumeHoraire,
      required this.professeur});

  factory Module.fromApi(Map<String, dynamic> json) => Module(
        id: json['id'].toString(),
        nom: json['nom'] as String? ?? '',
        code: '',
        coefficient: ((json['coefficient'] as num?) ?? 1).round(),
        volumeHoraire: (json['volume_horaire'] as num?)?.round() ?? 0,
        professeur: (json['professeur'] as String?)?.trim() ?? '',
      );
}


class Filiere {
  final String id, nom, abreviation, niveau, domaine, anneeAcademique; // Ajout abreviation
  final List<Module> modules;
  int nbEtudiants;
  bool active;
  // id réel de la filière côté backend (utilisé pour persister les modules)
  String? backendId;
  Filiere({required this.id, required this.nom, required this.abreviation, required this.niveau,
      required this.domaine, required this.anneeAcademique,
      required this.modules, this.nbEtudiants = 0, this.active = true, this.backendId});
}

final List<Filiere> adminFilieres = [
  Filiere(
    id: 'F001', 
    nom: 'Réseaux Informatiques et Télécom', 
    abreviation: 'RIT', 
    niveau: 'Licence 2',
    domaine: 'Sciences & Technologies', 
    anneeAcademique: '2024-2025', 
    nbEtudiants: 38,
    modules: [
      Module(id: 'M001', nom: 'Réseaux & Protocoles', code: 'RES301', coefficient: 3, volumeHoraire: 45, professeur: 'OUÉDRAOGO Mamadou'),
      Module(id: 'M002', nom: 'Programmation Web', code: 'WEB302', coefficient: 2, volumeHoraire: 30, professeur: 'SAWADOGO Issa'),
      Module(id: 'M003', nom: 'Base de Données', code: 'BDD303', coefficient: 3, volumeHoraire: 45, professeur: 'OUÉDRAOGO Mamadou'),
      Module(id: 'M004', nom: 'Sécurité Informatique', code: 'SEC304', coefficient: 2, volumeHoraire: 30, professeur: 'TRAORÉ Alassane'),
      Module(id: 'M005', nom: 'Algorithmique Avancée', code: 'ALG305', coefficient: 4, volumeHoraire: 60, professeur: 'SAWADOGO Issa'),
    ],
  ),
  Filiere(
    id: 'F002', 
    nom: 'Électrotechnique', 
    abreviation: 'ELT', 
    niveau: 'Licence 2',
    domaine: 'Sciences & Technologies', 
    anneeAcademique: '2024-2025', 
    nbEtudiants: 24,
    modules: [
      Module(id: 'M006', nom: 'Électronique de Puissance', code: 'EP301', coefficient: 3, volumeHoraire: 45, professeur: 'COMPAORÉ Brahima'),
      Module(id: 'M007', nom: 'Machines Électriques', code: 'ME302', coefficient: 3, volumeHoraire: 45, professeur: 'COMPAORÉ Brahima'),
      Module(id: 'M008', nom: 'Automatisme', code: 'AUT303', coefficient: 2, volumeHoraire: 30, professeur: 'KABORÉ Jean'),
    ],
  ),
  Filiere(
    id: 'F003', 
    nom: 'Marketing & Communication', 
    abreviation: 'MKC', 
    niveau: 'Licence 2',
    domaine: 'Sciences de Gestion', 
    anneeAcademique: '2024-2025', 
    nbEtudiants: 31,
    modules: [
      Module(id: 'M009', nom: 'Marketing Digital', code: 'MKD301', coefficient: 3, volumeHoraire: 45, professeur: 'OUÉDRAOGO Aïcha'),
      Module(id: 'M010', nom: 'Communication Visuelle', code: 'COM302', coefficient: 2, volumeHoraire: 30, professeur: 'ZONGO Marie'),
      Module(id: 'M011', nom: 'Stratégie Commerciale', code: 'STR303', coefficient: 3, volumeHoraire: 45, professeur: 'OUÉDRAOGO Aïcha'),
    ],
  ),
  Filiere(
    id: 'F004', 
    nom: 'Gestion Comptable et Financière', 
    abreviation: 'GCF', 
    niveau: 'Licence 3',
    domaine: 'Sciences de Gestion', 
    anneeAcademique: '2024-2025', 
    nbEtudiants: 19,
    modules: [
      Module(id: 'M012', nom: 'Comptabilité Générale', code: 'CPT301', coefficient: 4, volumeHoraire: 60, professeur: 'TRAORÉ Boubacar'),
      Module(id: 'M013', nom: 'Fiscalité', code: 'FSC302', coefficient: 3, volumeHoraire: 45, professeur: 'TRAORÉ Boubacar'),
    ],
  ),
  Filiere(
    id: 'F005', 
    nom: 'Génie Civil', 
    abreviation: 'GNC', 
    niveau: 'Licence 2',
    domaine: 'Sciences & Technologies', 
    anneeAcademique: '2024-2025', 
    nbEtudiants: 15,
    modules: [
      Module(id: 'M014', nom: 'Résistance des Matériaux', code: 'RDM301', coefficient: 4, volumeHoraire: 60, professeur: 'SANKARA Paul'),
      Module(id: 'M015', nom: 'Topographie', code: 'TOP302', coefficient: 2, volumeHoraire: 30, professeur: 'SANKARA Paul'),
    ],
  ),
];

// ════════════════════════════════════════════════════════════════════════════
// PAGE FILIÈRES & MODULES
// ════════════════════════════════════════════════════════════════════════════
class AdminFilieres extends StatefulWidget {
  const AdminFilieres({super.key});
  @override State<AdminFilieres> createState() => _AdminFilieresState();
}

class _AdminFilieresState extends State<AdminFilieres> {
  String _domaine = 'tous';
  String _query   = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerModulesReels();
  }

  // Rattache chaque filière (mock) à son id réel côté backend et charge ses
  // modules réels, afin que les modules ajoutés ici soient persistés et
  // utilisables par les professeurs (saisie de notes, appel...).
  Future<void> _chargerModulesReels() async {
    final result = await ApiService.getFilieres();
    if (result['success'] != true) return;
    final backendFilieres = result['data'] as List<dynamic>;

    for (final f in adminFilieres) {
      final match = backendFilieres.firstWhere(
        (bf) => (bf['nom'] as String).trim().toLowerCase() == f.nom.trim().toLowerCase(),
        orElse: () => null,
      );
      if (match == null) continue;
      f.backendId = match['id'].toString();

      final modulesResult = await ApiService.getModules(filiereId: f.backendId);
      if (modulesResult['success'] == true) {
        final data = modulesResult['data'] as List<dynamic>;
        f.modules
          ..clear()
          ..addAll(data.map((m) => Module.fromApi(m as Map<String, dynamic>)));
      }
    }
    if (mounted) setState(() {});
  }

  List<Filiere> get _filtered => adminFilieres.where((f) {
    final matchD = _domaine == 'tous' || f.domaine == _domaine;
    final matchQ = _query.isEmpty ||
        f.nom.toLowerCase().contains(_query.toLowerCase()) ||
        f.niveau.toLowerCase().contains(_query.toLowerCase());
    return matchD && matchQ;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdminTheme.isDesktop(context);
    final st = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(children: [
        // ── Header style MaisonPlus ───────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(isDesktop ? 28 : 16, 20, isDesktop ? 28 : 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Filières & Modules',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E), letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('${adminFilieres.length} filières · ${adminFilieres.fold(0, (s, f) => s + f.nbEtudiants)} étudiants inscrits',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              ])),
              // Bouton Nouvelle filière
              GestureDetector(
                onTap: () => _ouvrirCreation(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    color: AdminTheme.iconBgAlt,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: AdminTheme.iconBgAlt.withValues(alpha:0.3),
                        blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, color: AdminTheme.iconFgAlt, size: 18),
                    SizedBox(width: 6),
                    Text('Nouvelle filière', style: TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // Recherche + filtres domaine
            Row(children: [
              Expanded(child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une filière...',
                    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 18),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 16, color: Color(0xFF9CA3AF)),
                            onPressed: () => setState(() { _query = ''; _searchCtrl.clear(); }))
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              )),
              const SizedBox(width: 12),
              // Filtres domaine
              _domaineChip('Tous', 'tous'),
              const SizedBox(width: 6),
              _domaineChip('Sciences & Tech', 'Sciences & Technologies'),
              const SizedBox(width: 6),
              _domaineChip('Sciences Gestion', 'Sciences de Gestion'),
            ]),
            const SizedBox(height: 16),

            // Stats rapides
            Row(children: [
              _statCard('${adminFilieres.where((f) => f.domaine.contains('Technologies')).length}',
                  'Sciences & Tech', const Color(0xFF1A3C34), const Color(0xFFD8F3DC)),
              const SizedBox(width: 10),
              _statCard('${adminFilieres.where((f) => f.domaine.contains('Gestion')).length}',
                  'Sciences Gestion', const Color(0xFF0891B2), const Color(0xFFE0F7FA)),
              const SizedBox(width: 10),
              _statCard('${adminFilieres.fold(0, (s, f) => s + f.modules.length)}',
                  'Modules total', const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
            ]),
            const SizedBox(height: 16),
          ]),
        ),
        adminDivider,

        // ── Grille filières ───────────────────────────────────────────
        Expanded(child: st.isEmpty
            ? _vide()
            : GridView.builder(
                padding: EdgeInsets.all(isDesktop ? 24 : 14),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : 1,
                  mainAxisSpacing: 16, crossAxisSpacing: 16,
                  childAspectRatio: isDesktop ? 1.1 : 0.85,
                ),
                itemCount: st.length,
                itemBuilder: (_, i) => _carteFiliere(st[i]),
              )),
      ]),
    );
  }

  Widget _domaineChip(String label, String value) {
    final active = _domaine == value;
    return GestureDetector(
      onTap: () => setState(() => _domaine = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AdminTheme.iconBg : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AdminTheme.iconBg : const Color(0xFFE5E7EB)),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF6B7280))),
      ),
    );
  }

  Widget _statCard(String value, String label, Color fg, Color bg) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: fg)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(fontSize: 11,
            fontWeight: FontWeight.w600, color: fg.withValues(alpha:0.8)))),
      ]),
    ),
  );

  // ── Carte filière ─────────────────────────────────────────────────────
  Widget _carteFiliere(Filiere f) {
  final isST = f.domaine.contains('Technologies');
  final color = isST ? AdminTheme.primary : AdminTheme.info;
  final lightColor = isST ? AdminTheme.primaryLight : AdminTheme.infoLight;

  return GestureDetector(
    onTap: () => _ouvrirDetail(f),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header coloré avec l'abréviation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: lightColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.abreviation, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
              Text(f.nom, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ),
      ]),
    ),
  );
}

  // ════════════════════════════════════════════════════════════════════════
  // DÉTAIL FILIÈRE
  // ════════════════════════════════════════════════════════════════════════
  void _ouvrirDetail(Filiere f) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailFiliere(
        filiere: f, onEdit: () => setState(() {})),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // CRÉATION FILIÈRE — Stepper 3 étapes
  // ════════════════════════════════════════════════════════════════════════
  void _ouvrirCreation() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreationFiliere(
        onCreated: (f) => setState(() => adminFilieres.add(f))),
    );
  }

  Widget _vide() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 72, height: 72,
      decoration: BoxDecoration(color: AdminTheme.iconBg,
          borderRadius: BorderRadius.circular(18)),
      child: const Icon(Icons.school_outlined, color: AdminTheme.iconFg, size: 36)),
    const SizedBox(height: 16),
    const Text('Aucune filière trouvée', style: TextStyle(fontSize: 17,
        fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
  ]));
}

// ════════════════════════════════════════════════════════════════════════════
// DÉTAIL FILIÈRE — Bottom Sheet
// ════════════════════════════════════════════════════════════════════════════
class _DetailFiliere extends StatefulWidget {
  final Filiere filiere;
  final VoidCallback onEdit;
  const _DetailFiliere({required this.filiere, required this.onEdit});
  @override State<_DetailFiliere> createState() => _DetailFiliereState();
}

class _DetailFiliereState extends State<_DetailFiliere>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _etudiants = [];
  bool _loadingEtudiants = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _chargerEtudiants();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _chargerEtudiants() async {
    var id = widget.filiere.backendId;
    // Filière pas encore rattachée au backend : on tente le rattachement ici.
    if (id == null) {
      final res = await ApiService.getFilieres();
      if (res['success'] == true) {
        final matches = (res['data'] as List<dynamic>).where((bf) =>
            (bf['nom'] as String).trim().toLowerCase() ==
            widget.filiere.nom.trim().toLowerCase());
        if (matches.isNotEmpty) {
          widget.filiere.backendId = matches.first['id'].toString();
          id = widget.filiere.backendId;
        }
      }
    }
    if (id == null) {
      if (mounted) setState(() => _loadingEtudiants = false);
      return;
    }
    final res = await ProfessorService.getStudentsByFiliere(int.parse(id));
    if (!mounted) return;
    setState(() {
      _etudiants = res['success'] == true ? res['data'] as List<dynamic> : [];
      if (_etudiants.isNotEmpty) widget.filiere.nbEtudiants = _etudiants.length;
      _loadingEtudiants = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.filiere;
    final isST = f.domaine.contains('Technologies');
    final color = isST ? AdminTheme.primary : AdminTheme.info;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
        // Header
        Container(color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 42, height: 42,
                decoration: BoxDecoration(color: color.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(isST ? Icons.computer_rounded : Icons.business_center_rounded,
                    color: color, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.nom, style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                Text('${f.niveau} · ${f.anneeAcademique}',
                    style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
              ])),
              IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              _chip('${f.nbEtudiants} étudiants', Icons.people_rounded, color),
              const SizedBox(width: 8),
              _chip('${f.modules.length} modules', Icons.book_rounded, color),
              const SizedBox(width: 8),
              _chip(f.domaine.contains('Technologies') ? 'Sciences & Tech' : 'Sciences Gestion',
                  Icons.category_rounded, color),
            ]),
            const SizedBox(height: 14),
            TabBar(
              controller: _tab,
              labelColor: color, unselectedLabelColor: const Color(0xFF9CA3AF),
              indicatorColor: color,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [Tab(text: 'Modules'), Tab(text: 'Étudiants'), Tab(text: 'Actions')],
            ),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        Expanded(child: TabBarView(controller: _tab, children: [
          _tabModules(f, color),
          _tabEtudiants(f),
          _tabActions(f, color),
        ])),
      ]),
    );
  }

  Widget _tabModules(Filiere f, Color color) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Row(children: [
        Expanded(child: Text('${f.modules.length} modules · Coef total : ${f.modules.fold(0, (s, m) => s + m.coefficient)}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
        GestureDetector(
          onTap: () => _ajouterModule(f),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: color,
                borderRadius: BorderRadius.circular(8)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text('Ajouter module', style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      ...f.modules.map((m) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.03),
                blurRadius: 6, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.nom, style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 3),
            Text('${m.volumeHoraire}h · Coefficient ${m.coefficient}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text('Coef ${m.coefficient}', style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w800, color: color)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
            onPressed: () => _supprimerModule(f, m),
          ),
        ]),
      )),
    ],
  );

  Widget _tabEtudiants(Filiere f) {
    if (_loadingEtudiants) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_etudiants.isEmpty) {
      return Center(child: Text('Aucun étudiant inscrit en ${f.nom}',
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))));
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Row(children: [
          Expanded(child: Text('${_etudiants.length} étudiant(s) inscrit(s)',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
          GestureDetector(
            onTap: () => _exporterListePdf(f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: AdminTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.download_rounded, color: AdminTheme.primary, size: 16),
                SizedBox(width: 6),
                Text('Exporter liste PDF', style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w700, color: AdminTheme.primary)),
              ]),
            ),
          ),
        ]),
      ),
      Expanded(child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _etudiants.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final e = _etudiants[i];
          final prenoms = '${e['prenoms'] ?? ''}';
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            leading: CircleAvatar(
              backgroundColor: AdminTheme.primaryLight,
              child: Text(prenoms.isNotEmpty ? prenoms[0].toUpperCase() : '?',
                  style: const TextStyle(color: AdminTheme.primary, fontWeight: FontWeight.w700)),
            ),
            title: Text('$prenoms ${e['nom'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('${e['matricule'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          );
        },
      )),
    ]);
  }

  Future<void> _exporterListePdf(Filiere f) async {
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      build: (_) => [
        pw.Header(level: 0, text: 'Liste des étudiants — ${f.nom} (${f.niveau})'),
        pw.Paragraph(text: 'Année académique : ${f.anneeAcademique} · ${_etudiants.length} étudiant(s)'),
        pw.TableHelper.fromTextArray(
          headers: ['N°', 'Matricule', 'Nom', 'Prénoms'],
          data: [
            for (var i = 0; i < _etudiants.length; i++)
              [
                '${i + 1}',
                '${_etudiants[i]['matricule'] ?? ''}',
                '${_etudiants[i]['nom'] ?? ''}',
                '${_etudiants[i]['prenoms'] ?? ''}',
              ],
          ],
        ),
      ],
    ));
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  Widget _tabActions(Filiere f, Color color) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      _actionRow(Icons.campaign_rounded, 'Envoyer une annonce à la filière',
          'Cibler uniquement les étudiants de ${f.nom}', color, () => _envoyerAnnonce(f)),
      const SizedBox(height: 12),
      _actionRow(Icons.forum_rounded, 'Ouvrir le groupe de messagerie',
          'Voir le groupe privé de la filière', color, () => _ouvrirGroupe(f)),
      const SizedBox(height: 12),
      _actionRow(Icons.calendar_today_rounded, 'Emploi du temps',
          'Voir ou modifier l\'emploi du temps', color,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminEDT()))),
      const SizedBox(height: 12),
      _actionRow(Icons.grade_rounded, 'Notes de la filière',
          'Voir toutes les notes et moyennes', color,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminNotes()))),
    ]),
  );

  void _envoyerAnnonce(Filiere f) {
    final titreCtrl = TextEditingController();
    final contenuCtrl = TextEditingController();
    bool envoi = false;

    showDialog(context: context, builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Annonce — ${f.nom}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(titreCtrl, 'Titre de l\'annonce', Icons.title_rounded),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB))),
            child: TextField(controller: contenuCtrl, maxLines: 5,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(hintText: 'Contenu du message...',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12))),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton.icon(
            icon: envoi
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 16),
            label: const Text('Envoyer'),
            onPressed: envoi ? null : () async {
              if (titreCtrl.text.trim().isEmpty || contenuCtrl.text.trim().isEmpty) return;
              setDialogState(() => envoi = true);
              final messenger = ScaffoldMessenger.of(context);

              final res = await ApiService.createAnnonce({
                'titre': titreCtrl.text.trim(),
                'contenu': contenuCtrl.text.trim(),
                'filiere': f.backendId ?? f.nom,
                'niveau': f.niveau,
                'cibleRole': 'etudiant',
              });
              if (!dialogCtx.mounted) return;
              if (res['success'] == true) {
                // L'annonce est créée en brouillon : on la publie aussitôt
                // pour qu'elle atteigne les étudiants de la filière.
                final id = res['data']?['id'];
                if (id != null) await ApiService.publierAnnonce(id.toString());
                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                messenger.showSnackBar(SnackBar(
                  content: Text('Annonce envoyée aux étudiants de ${f.nom}.'),
                  backgroundColor: const Color(0xFF1A3C34),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ));
              } else {
                setDialogState(() => envoi = false);
                messenger.showSnackBar(SnackBar(
                  content: Text(res['error'] as String? ?? 'Erreur lors de l\'envoi.'),
                  backgroundColor: AdminTheme.danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary,
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ],
      ),
    ));
  }

  void _ouvrirGroupe(Filiere f) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupeFiliere(
      profile: StudentProfile(
        nom: 'ScolarHub', prenoms: 'Administration', matricule: 'ADMIN',
        email: '', telephone: '', filiere: f.nom, motDePasse: '',
        niveau: f.niveau, role: 'admin',
      ),
    )));
  }

  Widget _actionRow(IconData icon, String titre, String sub, Color color,
      VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titre, style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ])),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
      ]),
    ),
  );

  Widget _chip(String label, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 12),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11,
          fontWeight: FontWeight.w700, color: color)),
    ]),
  );

  void _ajouterModule(Filiere f) {
    final nomCtrl  = TextEditingController();
    final coefCtrl = TextEditingController(text: '2');
    final vhCtrl   = TextEditingController(text: '30');
    bool envoi = false;

    // Liste des professeurs pour l'attribution du module
    final profsFuture = ApiService.getProfesseurs();
    String? profUserId;

    showDialog(context: context, builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ajouter un module',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(nomCtrl, 'Nom du module', Icons.book_rounded),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _field(coefCtrl, 'Coefficient', Icons.numbers_rounded,
                type: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _field(vhCtrl, 'Volume horaire (h)', Icons.schedule_rounded,
                type: TextInputType.number)),
          ]),
          const SizedBox(height: 10),
          // Attribution du module à un professeur (optionnelle)
          FutureBuilder<Map<String, dynamic>>(
            future: profsFuture,
            builder: (_, snap) {
              final profs = (snap.data?['success'] == true)
                  ? List<Map<String, dynamic>>.from(snap.data!['data'] as List)
                  : <Map<String, dynamic>>[];
              return DropdownButtonFormField<String>(
                initialValue: profUserId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Professeur (attribution)',
                  prefixIcon: const Icon(Icons.person_rounded, size: 20),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
                items: [
                  const DropdownMenuItem<String>(
                      value: null, child: Text('— Aucun pour l\'instant —')),
                  ...profs.map((p) => DropdownMenuItem<String>(
                        value: p['user_id'].toString(),
                        child: Text(
                            '${p['prenoms'] ?? ''} ${p['nom'] ?? ''}'.trim(),
                            overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (v) => setDialogState(() => profUserId = v),
              );
            },
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton(
            onPressed: envoi ? null : () async {
              if (nomCtrl.text.trim().isEmpty) return;
              setDialogState(() => envoi = true);
              final messenger = ScaffoldMessenger.of(context);

              if (f.backendId != null) {
                final result = await ApiService.createModule(
                  nom: nomCtrl.text.trim(),
                  coefficient: int.tryParse(coefCtrl.text) ?? 2,
                  volumeHoraire: int.tryParse(vhCtrl.text) ?? 30,
                  filiereId: int.tryParse(f.backendId!),
                  filiereNom: f.nom,
                  professeurUserId: profUserId,
                );
                if (!dialogCtx.mounted) return;
                if (result['success'] == true) {
                  setState(() => f.modules.add(Module.fromApi(result['data'] as Map<String, dynamic>)));
                  Navigator.pop(dialogCtx);
                } else {
                  setDialogState(() => envoi = false);
                  messenger.showSnackBar(SnackBar(
                    content: Text(result['error'] as String? ?? 'Erreur lors de l\'ajout du module.'),
                    backgroundColor: AdminTheme.danger,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ));
                }
              } else {
                // Filière non synchronisée avec le backend (ex: créée hors ligne) : ajout local uniquement.
                setState(() {
                  f.modules.add(Module(
                    id: 'M${f.modules.length + 100}',
                    nom: nomCtrl.text.trim(), code: '',
                    coefficient: int.tryParse(coefCtrl.text) ?? 2,
                    volumeHoraire: int.tryParse(vhCtrl.text) ?? 30,
                    professeur: '',
                  ));
                });
                Navigator.pop(dialogCtx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary,
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: envoi
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Ajouter'),
          ),
        ],
      ),
    ));
  }

  Future<void> _supprimerModule(Filiere f, Module m) async {
    if (f.backendId != null) {
      final result = await ApiService.deleteModule(m.id);
      if (!mounted) return;
      if (result['success'] != true) {
        showAppSnackBar(context, result['error'] as String? ?? 'Erreur lors de la suppression.', backgroundColor: AdminTheme.danger);
        return;
      }
    }
    setState(() => f.modules.removeWhere((mod) => mod.id == m.id));
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text}) =>
      Container(
        decoration: BoxDecoration(color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: TextField(controller: ctrl, keyboardType: type,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 16),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12))),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// CRÉATION FILIÈRE — Stepper 3 étapes
// ════════════════════════════════════════════════════════════════════════════
class _CreationFiliere extends StatefulWidget {
  final Function(Filiere) onCreated;
  const _CreationFiliere({required this.onCreated});
  @override State<_CreationFiliere> createState() => _CreationFiliereState();
}

class _CreationFiliereState extends State<_CreationFiliere> {
  int _step = 0;
  final _nomCtrl    = TextEditingController();
  final _abbrCtrl   = TextEditingController(); // Nouveau contrôleur ajouté
  final _anneeCtrl  = TextEditingController(text: '2024-2025');
  String _niveau    = 'Licence 2';
  String _domaine   = 'Sciences & Technologies';
  final List<Map<String, dynamic>> _modules = [];

  // Méthode snack ajoutée pour éviter l'erreur de compilation
  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AdminTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            const Expanded(child: Text('Créer une filière',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E)))),
            IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                onPressed: () => Navigator.pop(context)),
          ]),
        ),
        // Stepper indicator
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: List.generate(3, (i) {
            final done   = i < _step;
            final active = i == _step;
            return Expanded(child: Row(children: [
              Expanded(child: Column(children: [
                AnimatedContainer(duration: const Duration(milliseconds: 200),
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: done ? AdminTheme.success
                        : active ? AdminTheme.primary : const Color(0xFFE5E7EB),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: done
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : Text('${i + 1}', style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: active ? Colors.white : const Color(0xFF9CA3AF))))),
                const SizedBox(height: 4),
                Text(['Informations', 'Modules', 'Confirmation'][i],
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: active ? AdminTheme.primary : const Color(0xFF9CA3AF))),
              ])),
              if (i < 2) Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 20),
                  color: done ? AdminTheme.success : const Color(0xFFE5E7EB))),
            ]));
          })),
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        

        // Contenu étape
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: [_etape1(), _etape2(), _etape3()][_step],
        )),

        // Navigation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
          child: Row(children: [
            if (_step > 0)
              Expanded(child: GestureDetector(
                onTap: () => setState(() => _step--),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: const Center(child: Text('Retour',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280)))),
                ),
              )),
            if (_step > 0) const SizedBox(width: 12),
            Expanded(flex: 2, child: GestureDetector(
              onTap: _step < 2
                  ? () { if (_validerEtape()) setState(() => _step++); }
                  : _creer,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: AdminTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AdminTheme.primary.withValues(alpha:0.3),
                      blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Center(child: Text(
                  _step < 2 ? 'Continuer →' : '✅ Créer la filière',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: Colors.white))),
              ),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _etape1() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Informations de la filière',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
    const SizedBox(height: 4),
    const Text('Remplissez les informations de base de la filière.',
        style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
    const SizedBox(height: 20),
    _label('Nom de la filière *'),
    _input(_nomCtrl, 'Ex: Réseaux Informatiques et Télécom', Icons.school_rounded),
    const SizedBox(height: 14),
    _label('Abréviation (ex:RIT)*'),
    _input(_abbrCtrl, 'Ex: RIT', Icons.short_text_rounded),
    const SizedBox(height: 14),
    _label('Niveau'),
    _select(_niveau, ['Licence 1', 'Licence 2', 'Licence 3', 'BTS 1', 'BTS 2'],
        (v) => setState(() => _niveau = v!)),
    const SizedBox(height: 14),
    _label('Domaine'),
    _select(_domaine, ['Sciences & Technologies', 'Sciences de Gestion'],
        (v) => setState(() => _domaine = v!)),
    const SizedBox(height: 14),
    _label('Année académique'),
    _input(_anneeCtrl, '2024-2025', Icons.calendar_today_rounded),
  ]);

  Widget _etape2() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Modules de la filière',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        SizedBox(height: 4),
        Text('Ajoutez les modules de cette filière.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
      ])),
      GestureDetector(
        onTap: _ajouterModuleForm,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: AdminTheme.primary,
              borderRadius: BorderRadius.circular(8)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text('Ajouter', style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      ),
    ]),
    const SizedBox(height: 16),
    if (_modules.isEmpty)
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: const Center(child: Text('Aucun module ajouté.\nCliquez sur "Ajouter" pour commencer.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)))))
    else
      ...List.generate(_modules.length, (i) {
        final m = _modules[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(
                color: AdminTheme.primary, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m['nom'] as String, style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              Text('Coef ${m['coef']} · ${m['vh']}h · ${m['prof']}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ])),
            GestureDetector(
              onTap: () => setState(() => _modules.removeAt(i)),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444), size: 18)),
          ]),
        );
      }),
  ]);

  Widget _etape3() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Confirmation',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
    const SizedBox(height: 4),
    const Text('Vérifiez les informations avant de créer la filière.',
        style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
    const SizedBox(height: 20),
    _resumeRow('Nom', _nomCtrl.text),
    _resumeRow('Niveau', _niveau),
    _resumeRow('Domaine', _domaine),
    _resumeRow('Année', _anneeCtrl.text),
    _resumeRow('Modules', '${_modules.length} module(s)'),
    const SizedBox(height: 16),
    Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AdminTheme.successLight,
          borderRadius: BorderRadius.circular(12)),
      child: const Row(children: [
        Icon(Icons.auto_awesome_rounded, color: AdminTheme.success, size: 18),
        SizedBox(width: 10),
        Expanded(child: Text(
          'Un groupe de messagerie privé sera créé automatiquement pour cette filière.',
          style: TextStyle(fontSize: 12, color: AdminTheme.success,
              fontWeight: FontWeight.w600))),
      ])),
  ]);

  Widget _resumeRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
      const SizedBox(width: 12),
      Expanded(child: Text(value, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)))),
    ]),
  );

  bool _validerEtape() {
    if (_step == 0 && _nomCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez saisir le nom de la filière.'),
        backgroundColor: AdminTheme.danger, behavior: SnackBarBehavior.floating));
      return false;
    }
    return true;
  }

  void _ajouterModuleForm() {
    final nomCtrl  = TextEditingController();
    final coefCtrl = TextEditingController(text: '2');
    final vhCtrl   = TextEditingController(text: '30');
    final profCtrl = TextEditingController();

    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Ajouter un module',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _inputSimple(nomCtrl, 'Nom du module'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _inputSimple(coefCtrl, 'Coefficient',
              type: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: _inputSimple(vhCtrl, 'Volume horaire (h)',
              type: TextInputType.number)),
        ]),
        const SizedBox(height: 10),
        _inputSimple(profCtrl, 'Professeur'),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF6B7280)))),
        ElevatedButton(
          onPressed: () {
            if (nomCtrl.text.isEmpty) return;
            setState(() => _modules.add({
              'nom': nomCtrl.text, 'coef': coefCtrl.text, 'vh': vhCtrl.text,
              'prof': profCtrl.text,
            }));
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary,
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Ajouter'),
        ),
      ],
    ));
  }

 
void _creer() {
  if (_nomCtrl.text.isEmpty || _abbrCtrl.text.isEmpty) {
    _snack('Erreur : Nom et Abréviation requis !');
    return;
  }
  final f = Filiere(
    id: 'F${DateTime.now().millisecondsSinceEpoch}',
    nom: _nomCtrl.text,
    abreviation: _abbrCtrl.text, // Ajouté ici
    niveau: _niveau,
    domaine: _domaine,
    anneeAcademique: _anneeCtrl.text,
    modules: _modules.map((m) => Module(
      id: 'M${DateTime.now().millisecondsSinceEpoch}',
      nom: m['nom'] as String, code: '',
      coefficient: int.tryParse(m['coef'] as String) ?? 2,
      volumeHoraire: int.tryParse(m['vh'] as String) ?? 30,
      professeur: m['prof'] as String,
    )).toList(),
  );
  widget.onCreated(f);
  Navigator.pop(context);
}

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 13,
        fontWeight: FontWeight.w700, color: Color(0xFF374151))));

  Widget _input(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text}) =>
      Container(
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: TextField(controller: ctrl, keyboardType: type,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14))),
      );

  Widget _inputSimple(TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text}) =>
      Container(
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: TextField(controller: ctrl, keyboardType: type,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11))),
      );

  Widget _select(String value, List<String> items, ValueChanged<String?> onChanged) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: value, isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
          items: items.map((v) => DropdownMenuItem(value: v,
              child: Text(v, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        )),
      );
}
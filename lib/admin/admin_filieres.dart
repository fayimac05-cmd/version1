import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';

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
}

class Filiere {
  final String id, nom, niveau, domaine, anneeAcademique;
  final List<Module> modules;
  int nbEtudiants;
  bool active;
  Filiere({required this.id, required this.nom, required this.niveau,
      required this.domaine, required this.anneeAcademique,
      required this.modules, this.nbEtudiants = 0, this.active = true});
}

final List<Filiere> adminFilieres = [
  Filiere(id: 'F001', nom: 'Réseaux Informatiques et Télécom', niveau: 'Licence 2',
    domaine: 'Sciences & Technologies', anneeAcademique: '2024-2025', nbEtudiants: 38,
    modules: [
      Module(id: 'M001', nom: 'Réseaux & Protocoles', code: 'RES301', coefficient: 3, volumeHoraire: 45, professeur: 'OUÉDRAOGO Mamadou'),
      Module(id: 'M002', nom: 'Programmation Web', code: 'WEB302', coefficient: 2, volumeHoraire: 30, professeur: 'SAWADOGO Issa'),
      Module(id: 'M003', nom: 'Base de Données', code: 'BDD303', coefficient: 3, volumeHoraire: 45, professeur: 'OUÉDRAOGO Mamadou'),
      Module(id: 'M004', nom: 'Sécurité Informatique', code: 'SEC304', coefficient: 2, volumeHoraire: 30, professeur: 'TRAORÉ Alassane'),
      Module(id: 'M005', nom: 'Algorithmique Avancée', code: 'ALG305', coefficient: 4, volumeHoraire: 60, professeur: 'SAWADOGO Issa'),
    ]),
  Filiere(id: 'F002', nom: 'Électrotechnique', niveau: 'Licence 2',
    domaine: 'Sciences & Technologies', anneeAcademique: '2024-2025', nbEtudiants: 24,
    modules: [
      Module(id: 'M006', nom: 'Électronique de Puissance', code: 'EP301', coefficient: 3, volumeHoraire: 45, professeur: 'COMPAORÉ Brahima'),
      Module(id: 'M007', nom: 'Machines Électriques', code: 'ME302', coefficient: 3, volumeHoraire: 45, professeur: 'COMPAORÉ Brahima'),
      Module(id: 'M008', nom: 'Automatisme', code: 'AUT303', coefficient: 2, volumeHoraire: 30, professeur: 'KABORÉ Jean'),
    ]),
  Filiere(id: 'F003', nom: 'Marketing & Communication', niveau: 'Licence 2',
    domaine: 'Sciences de Gestion', anneeAcademique: '2024-2025', nbEtudiants: 31,
    modules: [
      Module(id: 'M009', nom: 'Marketing Digital', code: 'MKD301', coefficient: 3, volumeHoraire: 45, professeur: 'OUÉDRAOGO Aïcha'),
      Module(id: 'M010', nom: 'Communication Visuelle', code: 'COM302', coefficient: 2, volumeHoraire: 30, professeur: 'ZONGO Marie'),
      Module(id: 'M011', nom: 'Stratégie Commerciale', code: 'STR303', coefficient: 3, volumeHoraire: 45, professeur: 'OUÉDRAOGO Aïcha'),
    ]),
  Filiere(id: 'F004', nom: 'Gestion Comptable et Financière', niveau: 'Licence 3',
    domaine: 'Sciences de Gestion', anneeAcademique: '2024-2025', nbEtudiants: 19,
    modules: [
      Module(id: 'M012', nom: 'Comptabilité Générale', code: 'CPT301', coefficient: 4, volumeHoraire: 60, professeur: 'TRAORÉ Boubacar'),
      Module(id: 'M013', nom: 'Fiscalité', code: 'FSC302', coefficient: 3, volumeHoraire: 45, professeur: 'TRAORÉ Boubacar'),
    ]),
  Filiere(id: 'F005', nom: 'Génie Civil', niveau: 'Licence 2',
    domaine: 'Sciences & Technologies', anneeAcademique: '2024-2025', nbEtudiants: 15,
    modules: [
      Module(id: 'M014', nom: 'Résistance des Matériaux', code: 'RDM301', coefficient: 4, volumeHoraire: 60, professeur: 'SANKARA Paul'),
      Module(id: 'M015', nom: 'Topographie', code: 'TOP302', coefficient: 2, volumeHoraire: 30, professeur: 'SANKARA Paul'),
    ]),
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
                    color: AdminTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: AdminTheme.primary.withOpacity(0.3),
                        blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
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
        Container(height: 1, color: const Color(0xFFE5E7EB)),

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
          color: active ? AdminTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AdminTheme.primary : const Color(0xFFE5E7EB)),
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
            fontWeight: FontWeight.w600, color: fg.withOpacity(0.8)))),
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header coloré
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lightColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              Container(width: 38, height: 38,
                decoration: BoxDecoration(color: color,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(isST ? Icons.computer_rounded : Icons.business_center_rounded,
                    color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.nom, style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${f.niveau} · ${f.anneeAcademique}',
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ])),
            ]),
          ),

          // Infos
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _infoChip(Icons.people_rounded, '${f.nbEtudiants} étudiants',
                    const Color(0xFF6B7280)),
                const SizedBox(width: 8),
                _infoChip(Icons.book_rounded, '${f.modules.length} modules',
                    const Color(0xFF6B7280)),
              ]),
              const SizedBox(height: 10),
              // Modules preview
              ...f.modules.take(3).map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Container(width: 6, height: 6,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(m.nom, style: const TextStyle(fontSize: 11,
                      color: Color(0xFF6B7280)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text('Coef ${m.coefficient}', style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w700, color: color)),
                ]),
              )),
              if (f.modules.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('+${f.modules.length - 3} autres modules',
                      style: TextStyle(fontSize: 11, color: color,
                          fontWeight: FontWeight.w600)),
                ),
            ]),
          ),

          const Spacer(),

          // Footer actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => _ouvrirDetail(f),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: lightColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text('Voir détails',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w700, color: color))),
                ),
              )),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _ouvrirEdition(f),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: Color(0xFF6B7280), size: 16),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _menuFiliere(f),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Icon(Icons.more_vert_rounded,
                      color: Color(0xFF6B7280), size: 16),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 12),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11,
          fontWeight: FontWeight.w600, color: color)),
    ]),
  );

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

  void _ouvrirEdition(Filiere f) {
    _snack('✏️ Modification de ${f.nom}');
  }

  void _menuFiliere(Filiere f) {
    showModalBottomSheet(context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text(f.nom, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Divider(height: 1),
        ListTile(leading: Icon(Icons.visibility_rounded, color: AdminTheme.primary),
            title: const Text('Voir les détails'),
            onTap: () { Navigator.pop(context); _ouvrirDetail(f); }),
        ListTile(leading: const Icon(Icons.edit_rounded, color: Color(0xFF6B7280)),
            title: const Text('Modifier la filière'),
            onTap: () { Navigator.pop(context); _ouvrirEdition(f); }),
        ListTile(
            leading: Icon(Icons.archive_rounded, color: AdminTheme.warning),
            title: Text('Archiver', style: TextStyle(color: AdminTheme.warning)),
            onTap: () { Navigator.pop(context); _snack('Filière archivée.'); }),
        const SizedBox(height: 8),
      ])));
  }

  Widget _vide() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 72, height: 72,
      decoration: BoxDecoration(color: AdminTheme.primaryLight,
          borderRadius: BorderRadius.circular(18)),
      child: const Icon(Icons.school_outlined, color: AdminTheme.primary, size: 36)),
    const SizedBox(height: 16),
    const Text('Aucune filière trouvée', style: TextStyle(fontSize: 17,
        fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
  ]));

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: AdminTheme.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
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
  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

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
                decoration: BoxDecoration(color: color.withOpacity(0.1),
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
                blurRadius: 6, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.nom, style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 3),
            Text('${m.code} · ${m.professeur}', style: const TextStyle(
                fontSize: 12, color: Color(0xFF6B7280))),
            Text('${m.volumeHoraire}h · Coefficient ${m.coefficient}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text('Coef ${m.coefficient}', style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w800, color: color)),
          ),
        ]),
      )),
    ],
  );

  Widget _tabEtudiants(Filiere f) => Center(child: Column(
    mainAxisSize: MainAxisSize.min, children: [
    Text('${f.nbEtudiants} étudiants inscrits en ${f.nom}',
        style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
    const SizedBox(height: 16),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: AdminTheme.primaryLight,
          borderRadius: BorderRadius.circular(10)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.download_rounded, color: AdminTheme.primary, size: 16),
        SizedBox(width: 6),
        Text('Exporter liste PDF', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w700, color: AdminTheme.primary)),
      ]),
    ),
  ]));

  Widget _tabActions(Filiere f, Color color) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      _actionRow(Icons.campaign_rounded, 'Envoyer une annonce à la filière',
          'Cibler uniquement les étudiants de ${f.nom}', color, () {}),
      const SizedBox(height: 12),
      _actionRow(Icons.forum_rounded, 'Ouvrir le groupe de messagerie',
          'Voir le groupe privé de la filière', color, () {}),
      const SizedBox(height: 12),
      _actionRow(Icons.calendar_today_rounded, 'Emploi du temps',
          'Voir ou modifier l\'emploi du temps', color, () {}),
      const SizedBox(height: 12),
      _actionRow(Icons.grade_rounded, 'Notes de la filière',
          'Voir toutes les notes et moyennes', color, () {}),
    ]),
  );

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
          decoration: BoxDecoration(color: color.withOpacity(0.1),
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
    decoration: BoxDecoration(color: color.withOpacity(0.1),
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
    final codeCtrl = TextEditingController();
    final coefCtrl = TextEditingController();
    final vhCtrl   = TextEditingController();
    final profCtrl = TextEditingController();

    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Ajouter un module',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _field(nomCtrl, 'Nom du module', Icons.book_rounded),
        const SizedBox(height: 10),
        _field(codeCtrl, 'Code (ex: RES301)', Icons.tag_rounded),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _field(coefCtrl, 'Coefficient', Icons.numbers_rounded,
              type: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: _field(vhCtrl, 'Volume horaire (h)', Icons.schedule_rounded,
              type: TextInputType.number)),
        ]),
        const SizedBox(height: 10),
        _field(profCtrl, 'Professeur assigné', Icons.person_rounded),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Color(0xFF6B7280)))),
        ElevatedButton(
          onPressed: () {
            if (nomCtrl.text.isEmpty) return;
            setState(() {
              f.modules.add(Module(
                id: 'M${f.modules.length + 100}',
                nom: nomCtrl.text, code: codeCtrl.text,
                coefficient: int.tryParse(coefCtrl.text) ?? 2,
                volumeHoraire: int.tryParse(vhCtrl.text) ?? 30,
                professeur: profCtrl.text,
              ));
            });
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
  final _anneeCtrl  = TextEditingController(text: '2024-2025');
  String _niveau    = 'Licence 2';
  String _domaine   = 'Sciences & Technologies';
  final List<Map<String, dynamic>> _modules = [];

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
                  boxShadow: [BoxShadow(color: AdminTheme.primary.withOpacity(0.3),
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
    if (_nomCtrl.text.isEmpty) return;
    final f = Filiere(
      id: 'F${adminFilieres.length + 1}',
      nom: _nomCtrl.text, niveau: _niveau,
      domaine: _domaine, anneeAcademique: _anneeCtrl.text,
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ Filière "${f.nom}" créée ! Groupe de messagerie généré.'),
      backgroundColor: AdminTheme.success, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
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

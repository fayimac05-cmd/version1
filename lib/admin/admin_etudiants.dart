import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../admin/admin_theme.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLE ÉTUDIANT
// ════════════════════════════════════════════════════════════════════════════
// Rôles possibles :
// 'etudiant'        → étudiant normal
// 'delegue'         → délégué(e) de filière
// 'delegue_adjoint' → adjoint(e) délégué(e) de filière
// 'bde_president'   → Délégué(e) Général(e) BDE (peut publier sur canal BDE)
// 'bde_adjoint'     → Adjoint(e) Délégué(e) Général(e) BDE (peut publier sur canal BDE)
// 'bde_membre'      → membre BDE (étudiant normal côté discussions)

class Etudiant {
  final String matricule, nom, prenoms, filiere, domaine, niveau;
  String email, telephone, dateNaissance, nationalite, adresse;
  final String nomParent, telParent, emailParent;
  String statut;
  String role;           // voir commentaire ci-dessus
  String? filiereRole;   // filière concernée pour delegue / delegue_adjoint
  final List<Map<String, dynamic>> notes;
  final List<String> badges;

  Etudiant({
    required this.matricule, required this.nom, required this.prenoms,
    required this.filiere, required this.domaine, required this.niveau,
    required this.email, required this.telephone,
    required this.dateNaissance, required this.nationalite, required this.adresse,
    required this.nomParent, required this.telParent, required this.emailParent,
    this.statut = 'actif',
    this.role = 'etudiant',
    this.filiereRole,
    this.notes = const [], this.badges = const [],
  });

  // Helpers
  bool get estDelegue =>
      role == 'delegue' || role == 'delegue_adjoint';
  bool get peutPublierBDE =>
      role == 'bde_president' || role == 'bde_adjoint';
  bool get estBDE =>
      role == 'bde_president' || role == 'bde_adjoint' || role == 'bde_membre';

  String get roleLabel {
    switch (role) {
      case 'delegue':         return 'Délégué(e)';
      case 'delegue_adjoint': return 'Adjoint(e) Délégué(e)';
      case 'bde_president':   return 'Délégué(e) Général(e) BDE';
      case 'bde_adjoint':     return 'Adjoint(e) Délégué(e) Général(e) BDE';
      case 'bde_membre':      return 'Membre BDE';
      default:                return 'Étudiant(e)';
    }
  }

  String get roleBadgeEmoji {
    switch (role) {
      case 'delegue':         return '🎖️';
      case 'delegue_adjoint': return '🏅';
      case 'bde_president':   return '👑';
      case 'bde_adjoint':     return '⭐';
      case 'bde_membre':      return '🎉';
      default:                return '';
    }
  }
}

final List<Etudiant> adminEtudiants = [
  Etudiant(
    matricule: '24IST-O2/1851', nom: 'KOURAOGO', prenoms: 'Ibrahim',
    filiere: 'Réseaux Informatiques et Télécom', domaine: 'Sciences & Technologies',
    niveau: 'Licence 2', email: 'ibrahim.kouraogo@ist.bf', telephone: '70000001',
    dateNaissance: '15/03/2004', nationalite: 'Burkinabè', adresse: 'Ouaga 2000, Secteur 15',
    nomParent: 'KOURAOGO Seydou', telParent: '65001234', emailParent: 'seydou@gmail.com',
    statut: 'actif',
    role: 'delegue', filiereRole: 'Réseaux Informatiques et Télécom',
    notes: [
      {'module': 'Réseaux & Protocoles', 'note': 14.5, 'coef': 3},
      {'module': 'Programmation Web', 'note': 16.0, 'coef': 2},
      {'module': 'Base de Données', 'note': 13.0, 'coef': 3},
      {'module': 'Sécurité Informatique', 'note': 15.5, 'coef': 2},
    ],
    badges: ['Major S1', 'Assidu'],
  ),
  Etudiant(
    matricule: '24IST-O2/1234', nom: 'TRAORÉ', prenoms: 'Fatimata',
    filiere: 'Réseaux Informatiques et Télécom', domaine: 'Sciences & Technologies',
    niveau: 'Licence 2', email: 'fatimata.traore@ist.bf', telephone: '70000002',
    dateNaissance: '22/07/2004', nationalite: 'Burkinabè', adresse: 'Pissy, Ouagadougou',
    nomParent: 'TRAORÉ Moussa', telParent: '76000002', emailParent: 'traore@gmail.com',
    statut: 'actif',
    role: 'delegue_adjoint', filiereRole: 'Réseaux Informatiques et Télécom',
    notes: [
      {'module': 'Réseaux & Protocoles', 'note': 17.0, 'coef': 3},
      {'module': 'Programmation Web', 'note': 18.5, 'coef': 2},
      {'module': 'Base de Données', 'note': 16.0, 'coef': 3},
    ],
    badges: ['Major S2', 'Mention TB'],
  ),
  Etudiant(
    matricule: '23IST-O2/0987', nom: 'SAWADOGO', prenoms: 'Moussa',
    filiere: 'Gestion Comptable et Financière', domaine: 'Sciences de Gestion',
    niveau: 'Licence 3', email: 'moussa.sawadogo@ist.bf', telephone: '70000003',
    dateNaissance: '10/01/2003', nationalite: 'Burkinabè', adresse: 'Gounghin, Ouagadougou',
    nomParent: 'SAWADOGO Ali', telParent: '76000003', emailParent: 'sawadogo@gmail.com',
    statut: 'suspendu',
    notes: [
      {'module': 'Comptabilité Générale', 'note': 8.0, 'coef': 3},
      {'module': 'Fiscalité', 'note': 7.5, 'coef': 2},
    ],
    badges: [],
  ),
  Etudiant(
    matricule: '24IST-O2/1456', nom: 'KABORÉ', prenoms: 'Djeneba',
    filiere: 'Marketing & Communication', domaine: 'Sciences de Gestion',
    niveau: 'Licence 2', email: 'djeneba.kabore@ist.bf', telephone: '70000004',
    dateNaissance: '05/11/2004', nationalite: 'Burkinabè', adresse: 'Ouaga 2000, Secteur 53',
    nomParent: 'KABORÉ Jean', telParent: '76000004', emailParent: 'kabore@gmail.com',
    statut: 'actif',
    role: 'bde_president',
    notes: [
      {'module': 'Marketing Digital', 'note': 15.5, 'coef': 3},
      {'module': 'Communication', 'note': 14.0, 'coef': 2},
    ],
    badges: ['Créative'],
  ),
  Etudiant(
    matricule: '24IST-O2/1789', nom: 'OUÉDRAOGO', prenoms: 'Hamidou',
    filiere: 'Électrotechnique', domaine: 'Sciences & Technologies',
    niveau: 'Licence 2', email: 'hamidou.ouedraogo@ist.bf', telephone: '70000005',
    dateNaissance: '18/06/2004', nationalite: 'Burkinabè', adresse: 'Kossodo, Ouagadougou',
    nomParent: 'OUÉDRAOGO Rasmané', telParent: '76000005', emailParent: 'rasma@gmail.com',
    statut: 'actif',
    role: 'bde_adjoint',
    notes: [
      {'module': 'Électronique de Puissance', 'note': 12.0, 'coef': 3},
      {'module': 'Machines Électriques', 'note': 11.5, 'coef': 2},
    ],
    badges: [],
  ),
  Etudiant(
    matricule: '23IST-O2/0654', nom: 'COMPAORÉ', prenoms: 'Aminata',
    filiere: 'Finance Comptabilité', domaine: 'Sciences de Gestion',
    niveau: 'Licence 3', email: 'aminata.compaore@ist.bf', telephone: '70000006',
    dateNaissance: '30/09/2003', nationalite: 'Burkinabè', adresse: 'Tampouy, Ouagadougou',
    nomParent: 'COMPAORÉ Brice', telParent: '76000006', emailParent: 'brice@gmail.com',
    statut: 'renvoye',
    role: 'delegue', filiereRole: 'Finance Comptabilité',
    notes: [], badges: [],
  ),
  Etudiant(
    matricule: '24IST-O2/1320', nom: 'SAWADOGO', prenoms: 'Raïssa',
    filiere: 'Réseaux Informatiques et Télécom', domaine: 'Sciences & Technologies',
    niveau: 'Licence 2', email: 'raissa.sawadogo@ist.bf', telephone: '70000008',
    dateNaissance: '12/04/2004', nationalite: 'Burkinabè', adresse: 'Pissy, Ouagadougou',
    nomParent: 'SAWADOGO Oumar', telParent: '76000008', emailParent: 'oumar@gmail.com',
    statut: 'actif',
    role: 'bde_membre',
    notes: [
      {'module': 'Réseaux & Protocoles', 'note': 13.0, 'coef': 3},
    ],
    badges: [],
  ),
];

// ════════════════════════════════════════════════════════════════════════════
// PAGE ÉTUDIANTS
// ════════════════════════════════════════════════════════════════════════════
class AdminEtudiants extends StatefulWidget {
  const AdminEtudiants({super.key});
  @override State<AdminEtudiants> createState() => _AdminEtudiantsState();
}

class _AdminEtudiantsState extends State<AdminEtudiants>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchCtrl = TextEditingController();
  String _query         = '';
  String _filtreStatut  = 'tous';
  String _filtredomaine = 'tous';
  String _filtreNiveau  = 'tous';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  List<Etudiant> get _filtered => adminEtudiants.where((e) {
    final q = _query.toLowerCase();
    final matchQ = q.isEmpty ||
        e.nom.toLowerCase().contains(q) ||
        e.prenoms.toLowerCase().contains(q) ||
        e.matricule.toLowerCase().contains(q) ||
        e.filiere.toLowerCase().contains(q);
    final matchS = _filtreStatut == 'tous' || e.statut == _filtreStatut;
    final matchD = _filtredomaine == 'tous' || e.domaine == _filtredomaine;
    final matchN = _filtreNiveau == 'tous' || e.niveau == _filtreNiveau;
    return matchQ && matchS && matchD && matchN;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdminTheme.isDesktop(context);
    final liste = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, 20, isDesktop ? 24 : 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Étudiants', style: TextStyle(fontSize: 22,
                    fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                Text('${adminEtudiants.length} inscrits · ${liste.length} affichés',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              ])),
              _statBadge('${adminEtudiants.where((e) => e.statut == 'actif').length} Actifs',
                  AdminTheme.success, AdminTheme.successLight),
              const SizedBox(width: 6),
              _statBadge('${adminEtudiants.where((e) => e.statut == 'suspendu').length} Suspendus',
                  AdminTheme.warning, AdminTheme.warningLight),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _inscrireEtudiant(),
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AdminTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: AdminTheme.primary.withOpacity(0.3),
                        blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.person_add_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Inscrire', style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            TabBar(
              controller: _tabs,
              labelColor: AdminTheme.primary,
              unselectedLabelColor: AdminTheme.textSecondary,
              indicatorColor: AdminTheme.primary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(text: 'Tous (${adminEtudiants.length})'),
                Tab(text: 'Délégués & BDE (${adminEtudiants.where((e) => e.role != 'etudiant').length})'),
              ]),
          ]),
        ),
        Container(height: 1, color: const Color(0xFFE5E7EB)),
        Expanded(child: TabBarView(controller: _tabs, children: [
          // ── Onglet 1 : Liste complète ──────────────────────────────
          Column(children: [
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, 10, isDesktop ? 24 : 16, 10),
              child: isDesktop
                  ? Row(children: [
                      Expanded(flex: 3, child: _searchBar()),
                      const SizedBox(width: 10),
                      Expanded(child: _filtreDropdown('Statut', _filtreStatut,
                          ['tous', 'actif', 'suspendu', 'renvoye'],
                          ['Tous', 'Actif', 'Suspendu', 'Renvoyé'],
                          (v) => setState(() => _filtreStatut = v!))),
                      const SizedBox(width: 10),
                      Expanded(child: _filtreDropdown('Domaine', _filtredomaine,
                          ['tous', 'Sciences & Technologies', 'Sciences de Gestion'],
                          ['Tous', 'Sciences & Tech', 'Gestion'],
                          (v) => setState(() => _filtredomaine = v!))),
                      const SizedBox(width: 10),
                      Expanded(child: _filtreDropdown('Niveau', _filtreNiveau,
                          ['tous', 'Licence 1', 'Licence 2', 'Licence 3'],
                          ['Tous', 'Licence 1', 'Licence 2', 'Licence 3'],
                          (v) => setState(() => _filtreNiveau = v!))),
                    ])
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _searchBar(),
                      const SizedBox(height: 8),
                      SingleChildScrollView(scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          _filtreChip('Tous', _filtreStatut == 'tous',
                              () => setState(() => _filtreStatut = 'tous')),
                          _filtreChip('Actifs', _filtreStatut == 'actif',
                              () => setState(() => _filtreStatut = 'actif'),
                              color: AdminTheme.success),
                          _filtreChip('Suspendus', _filtreStatut == 'suspendu',
                              () => setState(() => _filtreStatut = 'suspendu'),
                              color: AdminTheme.warning),
                          _filtreChip('Renvoyés', _filtreStatut == 'renvoye',
                              () => setState(() => _filtreStatut = 'renvoye'),
                              color: AdminTheme.danger),
                        ])),
                    ]),
            ),
            Container(height: 1, color: const Color(0xFFE5E7EB)),
            Expanded(child: liste.isEmpty
                ? _vide()
                : ListView.separated(
                    padding: EdgeInsets.all(isDesktop ? 20 : 12),
                    itemCount: liste.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _carteEtudiant(liste[i]),
                  )),
          ]),
          // ── Onglet 2 : Délégués & BDE ─────────────────────────────
          _pageDeleguesBDE(isDesktop),
        ])),
      ]),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────
  Widget _searchBar() => Container(
    height: 40,
    decoration: BoxDecoration(color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB))),
    child: TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _query = v),
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Rechercher par nom, matricule, filière...',
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 18),
        suffixIcon: _query.isNotEmpty
            ? IconButton(icon: const Icon(Icons.clear, size: 16, color: Color(0xFF9CA3AF)),
                onPressed: () => setState(() { _query = ''; _searchCtrl.clear(); }))
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 10)),
    ),
  );

  Widget _filtreDropdown(String hint, String value, List<String> values,
      List<String> labels, ValueChanged<String?> onChanged) =>
      Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: value, isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)),
          items: List.generate(values.length, (i) => DropdownMenuItem(
              value: values[i], child: Text(labels[i],
                  style: const TextStyle(fontSize: 13)))),
          onChanged: onChanged,
        )),
      );

  Widget _filtreChip(String label, bool active, VoidCallback onTap, {Color? color}) =>
      GestureDetector(onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? (color ?? AdminTheme.primary) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active
                ? (color ?? AdminTheme.primary) : const Color(0xFFE5E7EB))),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: active ? Colors.white : const Color(0xFF6B7280)))));

  Widget _statBadge(String label, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 11,
        fontWeight: FontWeight.w700, color: fg)));

  Widget _carteEtudiant(Etudiant e) {
    final moy = e.notes.isEmpty ? null : e.notes.fold<double>(0,
        (s, n) => s + (n['note'] as double) * (n['coef'] as int)) /
        e.notes.fold<int>(0, (s, n) => s + (n['coef'] as int));
    Color sc; String sl;
    switch (e.statut) {
      case 'suspendu': sc = AdminTheme.warning; sl = 'Suspendu'; break;
      case 'renvoye':  sc = AdminTheme.danger;  sl = 'Renvoyé';  break;
      default:         sc = AdminTheme.success; sl = 'Actif';
    }
    return GestureDetector(
      onTap: () => _ouvrirFiche(e),
      child: Container(
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2))]),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 46, height: 46,
              decoration: BoxDecoration(
                color: e.domaine.contains('Technologies')
                    ? AdminTheme.primaryLight : AdminTheme.infoLight,
                shape: BoxShape.circle),
              child: Center(child: Text('${e.prenoms[0]}${e.nom[0]}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                      color: e.domaine.contains('Technologies')
                          ? AdminTheme.primary : AdminTheme.info)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('${e.prenoms} ${e.nom}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E)))),
                AdminTheme.badge(sl, sc, sc.withOpacity(0.1)),
              ]),
              const SizedBox(height: 3),
              Text(e.matricule, style: const TextStyle(fontSize: 11,
                  fontFamily: 'monospace', color: AdminTheme.primary)),
              const SizedBox(height: 2),
              Text('${e.filiere} · ${e.niveau}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              if (e.badges.isNotEmpty) ...[
                const SizedBox(height: 5),
                Wrap(spacing: 6, children: e.badges.map((b) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: AdminTheme.accentLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('🏅 $b', style: const TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w600, color: AdminTheme.accent)))).toList()),
              ],
            ])),
            const SizedBox(width: 10),
            Column(mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (moy != null) ...[
                Text(moy.toStringAsFixed(1), style: TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: moy >= 10 ? AdminTheme.primary : AdminTheme.danger)),
                const Text('/20', style: TextStyle(fontSize: 11,
                    color: Color(0xFF9CA3AF))),
              ],
              const SizedBox(height: 8),
              Row(children: [
                _actionIcon(Icons.visibility_rounded, AdminTheme.primary,
                    () => _ouvrirFiche(e)),
                const SizedBox(width: 6),
                _actionIcon(Icons.picture_as_pdf_rounded, AdminTheme.warning,
                    () => _genererCarte(e)),
                const SizedBox(width: 6),
                _actionIcon(Icons.more_vert_rounded, const Color(0xFF9CA3AF),
                    () => _menuActions(e)),
              ]),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
        child: Container(width: 30, height: 30,
          decoration: BoxDecoration(color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, color: color, size: 16)));

  Widget _vide() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 72, height: 72,
      decoration: BoxDecoration(color: AdminTheme.primaryLight,
          borderRadius: BorderRadius.circular(18)),
      child: const Icon(Icons.people_outline, color: AdminTheme.primary, size: 36)),
    const SizedBox(height: 16),
    const Text('Aucun étudiant trouvé', style: TextStyle(fontSize: 17,
        fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
  ]));

  // ════════════════════════════════════════════════════════════════════════
  // ONGLET DÉLÉGUÉS & BDE
  // ════════════════════════════════════════════════════════════════════════
  Widget _pageDeleguesBDE(bool isDesktop) {
    final delegues = adminEtudiants
        .where((e) => e.estDelegue)
        .toList()
      ..sort((a, b) => a.filiere.compareTo(b.filiere));

    final bdePresident = adminEtudiants
        .where((e) => e.role == 'bde_president').toList();
    final bdeAdjoint = adminEtudiants
        .where((e) => e.role == 'bde_adjoint').toList();
    final bdeMembres = adminEtudiants
        .where((e) => e.role == 'bde_membre').toList();

    return ListView(
      padding: EdgeInsets.all(isDesktop ? 20 : 12),
      children: [
        // ── Section Délégués filières ─────────────────────────────────
        _sectionTitre('🎖️ Délégués de filières',
            '${delegues.length} délégué(s)'),
        const SizedBox(height: 10),
        // Explication droits
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AdminTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AdminTheme.primary.withOpacity(0.2))),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded,
                color: AdminTheme.primary, size: 14),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Le Délégué(e) et son Adjoint(e) peuvent écrire dans le canal '
              '"Admin & Filière" de leur filière. Tous les autres étudiants '
              'sont en lecture seule dans ce canal.',
              style: TextStyle(fontSize: 11, color: AdminTheme.primary,
                  fontWeight: FontWeight.w500))),
          ])),
        if (delegues.isEmpty)
          _carteVide('Aucun délégué désigné',
              'Attribuez le rôle Délégué(e) depuis la fiche d\'un étudiant.')
        else
          ...delegues.map((e) => _carteRole(e)),
        const SizedBox(height: 8),
        // Bouton attribuer
        _boutonAjouter('Désigner un délégué',
            Icons.person_add_rounded, AdminTheme.primary,
            () => _attribuerRole(rolesDisponibles: [
              'delegue', 'delegue_adjoint'])),
        const SizedBox(height: 24),

        // ── Section BDE ───────────────────────────────────────────────
        _sectionTitre('🎉 Bureau des Étudiants (BDE)',
            '${bdePresident.length + bdeAdjoint.length + bdeMembres.length} membre(s)'),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF7C3AED).withOpacity(0.2))),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded,
                color: Color(0xFF7C3AED), size: 14),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Seuls le Délégué(e) Général(e) et son Adjoint(e) peuvent publier '
              'sur le Canal BDE. Les autres membres BDE sont des étudiants normaux '
              '(lecture seule sur le canal).',
              style: TextStyle(fontSize: 11, color: Color(0xFF7C3AED),
                  fontWeight: FontWeight.w500))),
          ])),

        // Délégué(e) Général(e)
        if (bdePresident.isNotEmpty) ...[
          _labelSous('👑 Délégué(e) Général(e)'),
          ...bdePresident.map((e) => _carteRole(e)),
          const SizedBox(height: 8),
        ],
        // Adjoint(e)
        if (bdeAdjoint.isNotEmpty) ...[
          _labelSous('⭐ Adjoint(e) Délégué(e) Général(e)'),
          ...bdeAdjoint.map((e) => _carteRole(e)),
          const SizedBox(height: 8),
        ],
        // Membres BDE
        if (bdeMembres.isNotEmpty) ...[
          _labelSous('🎉 Membres BDE (étudiants normaux)'),
          ...bdeMembres.map((e) => _carteRole(e)),
          const SizedBox(height: 8),
        ],
        if (bdePresident.isEmpty && bdeAdjoint.isEmpty && bdeMembres.isEmpty)
          _carteVide('Aucun membre BDE désigné',
              'Attribuez les rôles BDE depuis la fiche d\'un étudiant.'),
        const SizedBox(height: 8),
        _boutonAjouter('Ajouter un membre BDE',
            Icons.celebration_rounded, const Color(0xFF7C3AED),
            () => _attribuerRole(rolesDisponibles: [
              'bde_president', 'bde_adjoint', 'bde_membre'])),
        const SizedBox(height: 20),
      ]);
  }

  Widget _sectionTitre(String titre, String sous) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titre, style: const TextStyle(fontSize: 16,
          fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
      Text(sous, style: const TextStyle(
          fontSize: 12, color: AdminTheme.textSecondary)),
    ])),
  ]);

  Widget _labelSous(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(label, style: const TextStyle(fontSize: 12,
        fontWeight: FontWeight.w700, color: AdminTheme.textSecondary)));

  Widget _carteRole(Etudiant e) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
            blurRadius: 6, offset: const Offset(0, 1))]),
    child: Row(children: [
      Container(width: 42, height: 42,
        decoration: BoxDecoration(
            color: AdminTheme.primaryLight, shape: BoxShape.circle),
        child: Center(child: Text('${e.prenoms[0]}${e.nom[0]}',
            style: const TextStyle(fontSize: 15,
                fontWeight: FontWeight.bold, color: AdminTheme.primary)))),
      const SizedBox(width: 12),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${e.prenoms} ${e.nom}', style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          if (e.roleBadgeEmoji.isNotEmpty)
            Text(e.roleBadgeEmoji, style: const TextStyle(fontSize: 14)),
        ]),
        Text(e.roleLabel, style: const TextStyle(
            fontSize: 11, color: AdminTheme.primary,
            fontWeight: FontWeight.w600)),
        Text('${e.filiere} · ${e.niveau} · ${e.domaine}',
            style: const TextStyle(fontSize: 11,
                color: AdminTheme.textSecondary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(e.matricule, style: const TextStyle(
            fontSize: 10, fontFamily: 'monospace',
            color: AdminTheme.textMuted)),
      ])),
      // Bouton modifier rôle
      GestureDetector(
        onTap: () => _modifierRole(e),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: AdminTheme.warningLight,
              borderRadius: BorderRadius.circular(8)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.swap_horiz_rounded,
                size: 14, color: AdminTheme.warning),
            SizedBox(width: 4),
            Text('Modifier', style: TextStyle(fontSize: 11,
                fontWeight: FontWeight.w700, color: AdminTheme.warning)),
          ]))),
      const SizedBox(width: 6),
      // Bouton retirer rôle
      GestureDetector(
        onTap: () => _retirerRole(e),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: AdminTheme.dangerLight,
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.remove_circle_outline_rounded,
              size: 16, color: AdminTheme.danger))),
    ]));

  Widget _carteVide(String titre, String sous) => Container(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.person_off_outlined,
          color: AdminTheme.textMuted, size: 32),
      const SizedBox(height: 8),
      Text(titre, style: const TextStyle(fontSize: 13,
          fontWeight: FontWeight.w700, color: AdminTheme.textSecondary)),
      Text(sous, style: const TextStyle(
          fontSize: 11, color: AdminTheme.textMuted),
          textAlign: TextAlign.center),
    ])));

  Widget _boutonAjouter(String label, IconData icon, Color color,
      VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w700, color: color)),
      ])));

  // ── Attribuer un rôle ─────────────────────────────────────────────────
  void _attribuerRole({required List<String> rolesDisponibles}) {
    String? roleChoisi = rolesDisponibles.first;
    String? filiereChoisie;
    Etudiant? etudiantChoisi;
    final filieres = adminEtudiants.map((e) => e.filiere).toSet().toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setS) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Attribuer un rôle',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close_rounded, size: 22, color: AdminTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFFE5E7EB)),
                  // Corps scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Choix rôle
                          const Text('Rôle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: rolesDisponibles.map((r) {
                              final isSelected = roleChoisi == r;
                              return GestureDetector(
                                onTap: () => setS(() => roleChoisi = r),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 120),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFD1D5DB),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    _roleLabelMap(r),
                                    style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600,
                                      color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          // Filière si délégué
                          if (roleChoisi == 'delegue' || roleChoisi == 'delegue_adjoint') ...[
                            const SizedBox(height: 16),
                            const Text('Filière concernée', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: filiereChoisie,
                                  hint: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('Choisir une filière', style: TextStyle(fontSize: 13, color: AdminTheme.textMuted)),
                                  ),
                                  isExpanded: true,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  items: filieres.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 13)))).toList(),
                                  onChanged: (v) => setS(() => filiereChoisie = v),
                                ),
                              ),
                            ),
                          ],
                          // Choix étudiant
                          const SizedBox(height: 16),
                          const Text('Étudiant', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          ...adminEtudiants.where((e) => e.statut == 'actif').map((e) {
                            final isSelected = etudiantChoisi?.matricule == e.matricule;
                            return GestureDetector(
                              onTap: () => setS(() => etudiantChoisi = e),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36, height: 36,
                                      decoration: const BoxDecoration(color: AdminTheme.primaryLight, shape: BoxShape.circle),
                                      child: Center(
                                        child: Text('${e.prenoms[0]}${e.nom[0]}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.primary)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${e.prenoms} ${e.nom}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                          Text('${e.filiere} · ${e.niveau}',
                                            style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary),
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                          Text(e.matricule, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AdminTheme.textMuted)),
                                        ],
                                      ),
                                    ),
                                    if (e.role != 'etudiant')
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: AdminTheme.warningLight, borderRadius: BorderRadius.circular(6)),
                                        child: Text('${e.roleBadgeEmoji} ${e.roleLabel}',
                                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AdminTheme.warning)),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  // Bouton confirmer
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: GestureDetector(
                      onTap: () {
                        if (etudiantChoisi == null || roleChoisi == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('⚠️ Choisissez un rôle et un étudiant'),
                            backgroundColor: Color(0xFFDC2626),
                            behavior: SnackBarBehavior.floating,
                          ));
                          return;
                        }
                        if ((roleChoisi == 'delegue' || roleChoisi == 'delegue_adjoint') && filiereChoisie == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('⚠️ Choisissez la filière concernée'),
                            backgroundColor: Color(0xFFDC2626),
                            behavior: SnackBarBehavior.floating,
                          ));
                          return;
                        }
                        setState(() {
                          etudiantChoisi!.role = roleChoisi!;
                          etudiantChoisi!.filiereRole = filiereChoisie ?? etudiantChoisi!.filiere;
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('✅ Rôle ${_roleLabelMap(roleChoisi!)} attribué à ${etudiantChoisi!.prenoms} !'),
                          backgroundColor: AdminTheme.success,
                          behavior: SnackBarBehavior.floating,
                        ));
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(color: AdminTheme.primary, borderRadius: BorderRadius.circular(12)),
                        child: const Center(
                          child: Text('Confirmer l\'attribution',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  // ── Modifier rôle ─────────────────────────────────────────────────────
  void _modifierRole(Etudiant e) {
    final estDelegue = e.role == 'delegue' || e.role == 'delegue_adjoint';
    _attribuerRole(rolesDisponibles: estDelegue
        ? ['delegue', 'delegue_adjoint']
        : ['bde_president', 'bde_adjoint', 'bde_membre']);
  }

  // ── Retirer rôle ──────────────────────────────────────────────────────
  void _retirerRole(Etudiant e) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Retirer le rôle de ${e.prenoms} ?'),
      content: Text('${e.prenoms} ${e.nom} redeviendra un étudiant normal.\n\n'
          'Rôle actuel : ${e.roleLabel}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            setState(() {
              e.role = 'etudiant';
              e.filiereRole = null;
            });
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('✅ Rôle retiré pour ${e.prenoms} ${e.nom}'),
              backgroundColor: AdminTheme.success,
              behavior: SnackBarBehavior.floating));
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.danger,
              foregroundColor: Colors.white),
          child: const Text('Retirer le rôle')),
      ]));
  }

  String _roleLabelMap(String role) {
    switch (role) {
      case 'delegue':         return 'Délégué(e)';
      case 'delegue_adjoint': return 'Adjoint(e) Délégué(e)';
      case 'bde_president':   return 'Délégué(e) Général(e) BDE';
      case 'bde_adjoint':     return 'Adjoint(e) BDE';
      case 'bde_membre':      return 'Membre BDE';
      default:                return 'Étudiant(e)';
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // INSCRIRE ÉTUDIANT
  // ════════════════════════════════════════════════════════════════════════
  void _inscrireEtudiant() {
    final nomCtrl      = TextEditingController();
    final prenomCtrl   = TextEditingController();
    final emailCtrl    = TextEditingController();
    final telCtrl      = TextEditingController();
    final dnCtrl       = TextEditingController();
    final adresseCtrl  = TextEditingController();
    final nomParCtrl   = TextEditingController();
    final telParCtrl   = TextEditingController();
    String filiere     = 'Réseaux Informatiques et Télécom';
    String niveau      = 'Licence 2';
    String domaine     = 'Sciences & Technologies';

    final filieres = [
      'Réseaux Informatiques et Télécom', 'Électrotechnique',
      'Marketing & Communication', 'Gestion Comptable et Financière',
      'Génie Civil',
    ];

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(children: [
                Expanded(child: Text('Inscrire un étudiant',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E)))),
                IconButton(icon: const Icon(Icons.close_rounded,
                    color: Color(0xFF6B7280)),
                    onPressed: () => Navigator.pop(ctx)),
              ])),
            const Divider(color: Color(0xFFE5E7EB)),
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Infos personnelles
                _sectionHeader('Informations personnelles'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _fieldCol('Nom *', nomCtrl, 'KOURAOGO')),
                  const SizedBox(width: 12),
                  Expanded(child: _fieldCol('Prénom *', prenomCtrl, 'Ibrahim')),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _fieldCol('Email', emailCtrl, 'email@ist.bf',
                      type: TextInputType.emailAddress)),
                  const SizedBox(width: 12),
                  Expanded(child: _fieldCol('Téléphone', telCtrl, '70000000',
                      type: TextInputType.phone)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _fieldCol('Date de naissance', dnCtrl, 'JJ/MM/AAAA')),
                  const SizedBox(width: 12),
                  Expanded(child: _fieldCol('Adresse', adresseCtrl, 'Quartier...')),
                ]),
                const SizedBox(height: 16),

                // Scolarité
                _sectionHeader('Informations académiques'),
                const SizedBox(height: 10),
                _label('Filière *'),
                _selectField(filiere, filieres,
                    (v) => setS(() { filiere = v!;
                      domaine = filiere.contains('Marketing') ||
                          filiere.contains('Gestion') || filiere.contains('Finance')
                          ? 'Sciences de Gestion' : 'Sciences & Technologies';
                    })),
                const SizedBox(height: 10),
                _label('Niveau *'),
                _selectField(niveau,
                    ['Licence 1', 'Licence 2', 'Licence 3', 'BTS 1', 'BTS 2'],
                    (v) => setS(() => niveau = v!)),
                const SizedBox(height: 16),

                // Parent
                _sectionHeader('Contact parent / tuteur'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _fieldCol('Nom du parent', nomParCtrl, 'Nom complet')),
                  const SizedBox(width: 12),
                  Expanded(child: _fieldCol('Téléphone parent', telParCtrl, '70000000',
                      type: TextInputType.phone)),
                ]),
              ])),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  if (nomCtrl.text.isEmpty || prenomCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Nom et prénom requis.'),
                      backgroundColor: AdminTheme.danger,
                      behavior: SnackBarBehavior.floating));
                    return;
                  }
                  final annee = DateTime.now().year.toString().substring(2);
                  final num   = (1900 + adminEtudiants.length).toString();
                  final mat   = '${annee}IST-O2/$num';
                  setState(() => adminEtudiants.add(Etudiant(
                    matricule: mat,
                    nom: nomCtrl.text.toUpperCase(),
                    prenoms: prenomCtrl.text,
                    filiere: filiere, domaine: domaine, niveau: niveau,
                    email: emailCtrl.text.isEmpty ? '$num@ist.bf' : emailCtrl.text,
                    telephone: telCtrl.text,
                    dateNaissance: dnCtrl.text,
                    nationalite: 'Burkinabè',
                    adresse: adresseCtrl.text,
                    nomParent: nomParCtrl.text,
                    telParent: telParCtrl.text,
                    emailParent: '',
                  )));
                  Navigator.pop(ctx);
                  _snack('✅ ${prenomCtrl.text} inscrit(e) ! Matricule : $mat');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AdminTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: AdminTheme.primary.withOpacity(0.3),
                        blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Center(child: Text('✅ Inscrire l\'étudiant',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: Colors.white))),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _sectionHeader(String titre) => Container(
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
    child: Text(titre, style: const TextStyle(fontSize: 14,
        fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))));

  Widget _fieldCol(String label, TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        _inputField(ctrl, hint, type: type),
      ]);

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(t, style: const TextStyle(fontSize: 12,
        fontWeight: FontWeight.w700, color: Color(0xFF374151))));

  Widget _inputField(TextEditingController ctrl, String hint,
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
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10))));

  Widget _selectField(String value, List<String> items,
      ValueChanged<String?> onChanged) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: value, isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)),
          items: items.map((v) => DropdownMenuItem(value: v,
              child: Text(v, style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        )));

  // ════════════════════════════════════════════════════════════════════════
  // FICHE INDIVIDUELLE
  // ════════════════════════════════════════════════════════════════════════
  void _ouvrirFiche(Etudiant e) {
    showModalBottomSheet(context: context, isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _FicheEtudiant(
            etudiant: e, onRefresh: () => setState(() {})));
  }

  // ════════════════════════════════════════════════════════════════════════
  // GÉNÉRATION CARTE PDF
  // ════════════════════════════════════════════════════════════════════════
  Future<void> _genererCarte(Etudiant e) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat(85.6 * PdfPageFormat.mm, 54 * PdfPageFormat.mm),
      margin: const pw.EdgeInsets.all(0),
      build: (ctx) => pw.Container(
        decoration: const pw.BoxDecoration(
          gradient: pw.LinearGradient(
            colors: [PdfColor.fromInt(0xFF1A3C34), PdfColor.fromInt(0xFF2D6A4F)],
            begin: pw.Alignment.topLeft, end: pw.Alignment.bottomRight,
          ),
        ),
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Row(children: [
            pw.Expanded(child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(children: [
                  pw.Container(width: 20, height: 20,
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFD8F3DC),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                    child: pw.Center(child: pw.Text('S',
                        style: pw.TextStyle(fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(0xFF1A3C34))))),
                  pw.SizedBox(width: 6),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('ScholARHub', style: pw.TextStyle(fontSize: 9,
                        fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    pw.Text('IST Ouaga 2000', style: const pw.TextStyle(
                        fontSize: 7, color: PdfColors.white)),
                  ]),
                ]),
                pw.SizedBox(height: 6),
                pw.Container(width: 36, height: 36,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0x30FFFFFF),
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.white, width: 1.5)),
                  child: pw.Center(child: pw.Text('${e.prenoms[0]}${e.nom[0]}',
                      style: pw.TextStyle(fontSize: 14,
                          fontWeight: pw.FontWeight.bold, color: PdfColors.white)))),
                pw.SizedBox(height: 6),
                pw.Text('${e.prenoms} ${e.nom}', style: pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                pw.Text(e.filiere, style: const pw.TextStyle(
                    fontSize: 7, color: PdfColors.white)),
                pw.SizedBox(height: 2),
                pw.Text('${e.niveau} · 2024-2025', style: const pw.TextStyle(
                    fontSize: 7, color: PdfColors.white)),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFB7950B),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10))),
                  child: pw.Text(e.matricule, style: pw.TextStyle(
                      fontSize: 8, fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white, font: pw.Font.courier()))),
              ],
            )),
            pw.SizedBox(width: 10),
            pw.Column(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: 'ScholARHub|${e.matricule}|${e.nom}|${e.prenoms}',
                width: 52, height: 52,
                color: PdfColors.white,
                backgroundColor: PdfColor.fromInt(0x20FFFFFF)),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.white, width: 0.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3))),
                child: pw.Text('VALIDE 2024-2025', style: const pw.TextStyle(
                    fontSize: 5, color: PdfColors.white))),
            ]),
          ]),
        ),
      ),
    ));
    await Printing.layoutPdf(
        onLayout: (_) => pdf.save(),
        name: 'Carte_${e.nom}_${e.prenoms}.pdf');
  }

  void _menuActions(Etudiant e) {
    showModalBottomSheet(context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text('${e.prenoms} ${e.nom}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        Text(e.matricule, style: const TextStyle(fontSize: 11,
            color: Color(0xFF9CA3AF), fontFamily: 'monospace')),
        const SizedBox(height: 12),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.visibility_rounded, color: AdminTheme.primary),
            title: const Text('Voir la fiche'),
            onTap: () { Navigator.pop(context); _ouvrirFiche(e); }),
        ListTile(leading: const Icon(Icons.picture_as_pdf_rounded, color: AdminTheme.warning),
            title: const Text('Générer carte PDF'),
            onTap: () { Navigator.pop(context); _genererCarte(e); }),
        if (e.statut == 'actif')
          ListTile(
            leading: const Icon(Icons.block_rounded, color: AdminTheme.warning),
            title: const Text('Suspendre', style: TextStyle(color: AdminTheme.warning)),
            onTap: () { Navigator.pop(context);
              setState(() => e.statut = 'suspendu');
              _snack('${e.prenoms} suspendu(e).'); }),
        if (e.statut == 'suspendu')
          ListTile(
            leading: const Icon(Icons.check_circle_outline, color: AdminTheme.success),
            title: const Text('Réactiver', style: TextStyle(color: AdminTheme.success)),
            onTap: () { Navigator.pop(context);
              setState(() => e.statut = 'actif');
              _snack('${e.prenoms} réactivé(e).'); }),
        const SizedBox(height: 8),
      ])));
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: AdminTheme.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
}

// ════════════════════════════════════════════════════════════════════════════
// FICHE ÉTUDIANT
// ════════════════════════════════════════════════════════════════════════════
class _FicheEtudiant extends StatelessWidget {
  final Etudiant etudiant;
  final VoidCallback onRefresh;
  const _FicheEtudiant({required this.etudiant, required this.onRefresh});

  double get _moyenne {
    if (etudiant.notes.isEmpty) return 0;
    final total = etudiant.notes.fold<double>(0,
        (s, n) => s + (n['note'] as double) * (n['coef'] as int));
    final coefs = etudiant.notes.fold<int>(0, (s, n) => s + (n['coef'] as int));
    return total / coefs;
  }

  @override
  Widget build(BuildContext context) {
    final e = etudiant;
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
        // Header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AdminTheme.primary, AdminTheme.primaryMid],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AdminTheme.elevatedShadow),
          child: Row(children: [
            Container(width: 60, height: 60,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2)),
              child: Center(child: Text('${e.prenoms[0]}${e.nom[0]}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: Colors.white)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${e.prenoms} ${e.nom}', style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 3),
              Text(e.matricule, style: const TextStyle(
                  fontSize: 11, color: Colors.white70, fontFamily: 'monospace')),
              const SizedBox(height: 3),
              Text('${e.filiere} · ${e.niveau}', style: const TextStyle(
                  fontSize: 11, color: Colors.white70)),
              if (e.badges.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(spacing: 6, children: e.badges.map((b) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: AdminTheme.accent.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('🏅 $b', style: const TextStyle(
                      fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)))).toList()),
              ],
            ])),
            Column(children: [
              if (etudiant.notes.isNotEmpty) ...[
                Text(_moyenne.toStringAsFixed(1), style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w900,
                    color: _moyenne >= 10 ? AdminTheme.primaryLight : AdminTheme.danger)),
                const Text('/20', style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ]),
          ]),
        ),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _section('Informations personnelles', [
              _row(Icons.cake_rounded, 'Naissance', e.dateNaissance),
              _row(Icons.flag_rounded, 'Nationalité', e.nationalite),
              _row(Icons.phone_rounded, 'Téléphone', e.telephone),
              _row(Icons.email_rounded, 'Email', e.email),
              _row(Icons.home_rounded, 'Adresse', e.adresse),
            ]),
            const SizedBox(height: 12),
            _section('Contact d\'urgence', [
              _row(Icons.person_rounded, 'Parent', e.nomParent),
              _row(Icons.phone_rounded, 'Téléphone', e.telParent),
            ]),
            if (e.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionNotes(e),
            ],
          ])),
        ),
      ]),
    );
  }

  Widget _section(String titre, List<Widget> rows) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titre, style: const TextStyle(fontSize: 13,
          fontWeight: FontWeight.w700, color: Color(0xFF374151))),
      const SizedBox(height: 8),
      ...rows,
    ]));

  Widget _sectionNotes(Etudiant e) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Notes & Résultats', style: TextStyle(fontSize: 13,
          fontWeight: FontWeight.w700, color: Color(0xFF374151))),
      const SizedBox(height: 8),
      ...e.notes.map((n) {
        final note = n['note'] as double;
        final ok   = note >= 10;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(n['module'] as String, style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)))),
              Text(note.toStringAsFixed(1), style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: ok ? AdminTheme.primary : AdminTheme.danger)),
              const Text('/20', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            ]),
            const SizedBox(height: 4),
            ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (note / 20).clamp(0.0, 1.0), minHeight: 4,
                backgroundColor: const Color(0xFFE5E7EB),
                color: ok ? AdminTheme.primary : AdminTheme.danger)),
          ]));
      }),
    ]));

  Widget _row(IconData icon, String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
      const SizedBox(width: 8),
      Text('$label : ', style: const TextStyle(
          fontSize: 12, color: Color(0xFF6B7280))),
      Expanded(child: Text(val, style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
          overflow: TextOverflow.ellipsis)),
    ]));
}

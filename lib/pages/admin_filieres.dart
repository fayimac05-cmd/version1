import 'package:flutter/material.dart';
import '../pages/admin_data.dart';
import '../theme/app_palette.dart';
import '../pages/admin_comptes.dart';
class AdminFilieres extends StatefulWidget {
  const AdminFilieres({super.key});
  @override State<AdminFilieres> createState() => _AdminFilieresState();
}

class _AdminFilieresState extends State<AdminFilieres>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _filiereSelectee;
  final List<String> _domaines = ['Sciences & Technologies', 'Sciences de Gestion'];

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  List<AdminFiliere> _parDomaine(String domaine) =>
      adminFilieres.where((f) => f.domaine == domaine).toList();

  int _nbEtudiants(String filiereId) =>
      adminEtudiants.where((e) => e.filiereId == filiereId).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text('Filières & Modules',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _dialogCreerFiliere(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nouvelle', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppPalette.blue,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppPalette.blue,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _domaines.map((d) {
            final nb = _parDomaine(d).length;
            return Tab(text: d == 'Sciences & Technologies'
                ? 'S&T ($nb)' : 'SG ($nb)');
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _domaines.map((d) => _listeFilieres(d)).toList(),
      ),
    );
  }

  Widget _listeFilieres(String domaine) {
    final filieres = _parDomaine(domaine);
    if (filieres.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.school_outlined, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text('Aucune filière', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _dialogCreerFiliere(context, domaineDefaut: domaine),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Créer une filière'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filieres.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _carteFiliere(filieres[i]),
    );
  }

  Widget _carteFiliere(AdminFiliere f) {
    final isOpen = _filiereSelectee == f.id;
    final nbEtudiants = _nbEtudiants(f.id);
    final etudiants = adminEtudiants.where((e) => e.filiereId == f.id).toList();
    final color = f.domaine.contains('Technologies') ? AppPalette.blue : const Color(0xFF7C3AED);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpen ? color.withOpacity(0.4) : const Color(0xFFE2E8F0),
          width: isOpen ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── En-tête ──────────────────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _filiereSelectee = isOpen ? null : f.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  f.domaine.contains('Technologies')
                      ? Icons.computer_rounded : Icons.business_center_rounded,
                  color: color, size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.nom, style: const TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Wrap(spacing: 6, children: [
                  _badge(f.niveau, const Color(0xFF0F172A), const Color(0xFFF1F5F9)),
                  _badge('${f.modules.length} modules', color, color.withOpacity(0.1)),
                  _badge('$nbEtudiants étudiants',
                      const Color(0xFF15803D), const Color(0xFFF0FDF4)),
                ]),
              ])),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (_) => [
                  _menuItem('module', Icons.add_circle_outline, 'Ajouter un module', color),
                  _menuItem('groupe', Icons.groups_rounded, 'Voir groupe filière', const Color(0xFF15803D)),
                  _menuItem('supprimer', Icons.delete_outline, 'Supprimer la filière', const Color(0xFFDC2626)),
                ],
                onSelected: (v) {
                  if (v == 'module') _dialogAjouterModule(f);
                  if (v == 'groupe') _voirGroupe(f);
                  if (v == 'supprimer') _confirmerSuppressionFiliere(f);
                },
              ),
              Icon(isOpen ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF94A3B8)),
            ]),
          ),
        ),

        // ── Groupe filière ────────────────────────────────────────────
        if (!isOpen)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF15803D).withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.groups_rounded, size: 13, color: Color(0xFF15803D)),
                  const SizedBox(width: 5),
                  const Text('Groupe créé automatiquement',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: Color(0xFF15803D))),
                ]),
              ),
            ]),
          ),

        // ── Contenu déployé ───────────────────────────────────────────
        if (isOpen) ...[
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          DefaultTabController(
            length: 3,
            child: Column(children: [
              TabBar(
                labelColor: color,
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: color,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: const [
                  Tab(text: 'Modules'),
                  Tab(text: 'Étudiants'),
                  Tab(text: 'Groupe'),
                ],
              ),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              SizedBox(
                height: 280,
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Tab Modules
                    Column(children: [
                      Expanded(child: f.modules.isEmpty
                          ? Center(child: TextButton.icon(
                              onPressed: () => _dialogAjouterModule(f),
                              icon: const Icon(Icons.add),
                              label: const Text('Ajouter un module'),
                            ))
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: f.modules.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, j) => _carteModule(f.modules[j], color),
                            )),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _dialogAjouterModule(f),
                            icon: Icon(Icons.add, color: color, size: 16),
                            label: Text('Ajouter un module',
                                style: TextStyle(color: color, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: color),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                    ]),

                    // Tab Étudiants
                    etudiants.isEmpty
                        ? const Center(child: Text('Aucun étudiant',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: etudiants.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (_, j) => _ligneEtudiant(etudiants[j]),
                          ),

                    // Tab Groupe
                    _tabGroupe(f, nbEtudiants, color),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _tabGroupe(AdminFiliere f, int nbEtudiants, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(children: [
            Container(width: 46, height: 46,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(Icons.groups_rounded, color: Colors.white, size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.nom, style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('$nbEtudiants membres · Groupe privé',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ])),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF15803D).withOpacity(0.2)),
          ),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, color: Color(0xFF15803D), size: 16),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Ce groupe est créé automatiquement lors de la création de la filière. '
              'Les étudiants inscrits y sont ajoutés automatiquement. '
              'L\'admin ne peut pas lire les messages — c\'est 100% privé.',
              style: TextStyle(fontSize: 12, color: Color(0xFF15803D), height: 1.5),
            )),
          ]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Groupe privé — accès non autorisé pour l\'admin'),
                  behavior: SnackBarBehavior.floating)),
            icon: Icon(Icons.lock_outline, color: color, size: 16),
            label: Text('Groupe 100% Privé', style: TextStyle(color: color, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withOpacity(0.08),
              foregroundColor: color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _carteModule(AdminModule m, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(m.code.length >= 2 ? m.code.substring(0, 2) : m.code,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.nom, style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(m.profNom, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _badge('Coef. ${m.coefficient}', color, color.withOpacity(0.1)),
          const SizedBox(height: 4),
          Text('${m.volumeHoraire}h',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ]),
      ]),
    );
  }

  Widget _ligneEtudiant(AdminEtudiant e) {
    Color sc; String sl;
    switch (e.statut) {
      case 'suspendu': sc = const Color(0xFFD97706); sl = 'Suspendu'; break;
      case 'renvoyé':  sc = const Color(0xFFDC2626); sl = 'Renvoyé';  break;
      default:         sc = const Color(0xFF15803D); sl = 'Actif';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(children: [
        Container(width: 32, height: 32,
            decoration: BoxDecoration(color: AppPalette.blue.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Center(child: Text('${e.prenoms[0]}${e.nom[0]}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                    color: AppPalette.blue)))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${e.prenoms} ${e.nom}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(e.matricule, style: const TextStyle(fontSize: 11,
              color: Color(0xFF64748B), fontFamily: 'monospace')),
        ])),
        _badge(sl, sc, sc.withOpacity(0.1)),
      ]),
    );
  }

  Widget _badge(String label, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 11,
        fontWeight: FontWeight.bold, color: color)),
  );

  PopupMenuItem<String> _menuItem(String val, IconData icon, String label, Color color) =>
      PopupMenuItem(value: val, child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ]));

  // ── Créer filière ─────────────────────────────────────────────────────
  void _dialogCreerFiliere(BuildContext context, {String? domaineDefaut}) {
    final nomCtrl    = TextEditingController();
    final niveauCtrl = TextEditingController();
    String domaine   = domaineDefaut ?? 'Sciences & Technologies';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.school_rounded, color: AppPalette.blue),
            SizedBox(width: 10),
            Text('Nouvelle filière',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ]),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Domaine
            const Text('Domaine', style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            Row(children: ['Sciences & Technologies', 'Sciences de Gestion'].map((d) {
              final active = domaine == d;
              final color = d.contains('Technologies') ? AppPalette.blue : const Color(0xFF7C3AED);
              return Expanded(child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setS(() => domaine = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? color : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text(
                      d.contains('Technologies') ? 'S&T' : 'SG',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                          color: active ? Colors.white : const Color(0xFF64748B)),
                    )),
                  ),
                ),
              ));
            }).toList()),
            const SizedBox(height: 14),
            _champDialog(nomCtrl, 'Nom de la filière (ex: Génie Logiciel)', Icons.school_outlined),
            const SizedBox(height: 10),
            _champDialog(niveauCtrl, 'Niveau (ex: Licence 2, BTS 1)', Icons.layers_outlined),
            const SizedBox(height: 12),
            // Info groupe auto
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF15803D).withOpacity(0.2)),
              ),
              child: const Row(children: [
                Icon(Icons.groups_rounded, color: Color(0xFF15803D), size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('Un groupe privé sera créé automatiquement pour cette filière.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF15803D)))),
              ]),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B)))),
            ElevatedButton(
              onPressed: () {
                if (nomCtrl.text.isEmpty || niveauCtrl.text.isEmpty) return;
                final id = nomCtrl.text.toUpperCase().replaceAll(' ', '-').substring(0, 3) +
                    '-' + niveauCtrl.text.replaceAll(' ', '').toUpperCase();
                setState(() {
                  adminFilieres.add(AdminFiliere(
                    id: id, nom: nomCtrl.text, niveau: niveauCtrl.text,
                    domaine: domaine, anneeAcademique: '2024-2025', modules: [],
                  ));
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Filière "${nomCtrl.text}" créée + groupe privé généré ✅'),
                  backgroundColor: const Color(0xFF15803D),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
                // Aller sur le bon onglet
                _tabCtrl.animateTo(domaine.contains('Technologies') ? 0 : 1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Ajouter module ────────────────────────────────────────────────────
  void _dialogAjouterModule(AdminFiliere filiere) {
    final nomCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final coefCtrl = TextEditingController();
    final volCtrl = TextEditingController();
    String? profSelectionne;

    // Liste des profs disponibles depuis adminComptes
    final profs = adminComptes.where((c) => c.role == 'professeur').toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            const Icon(Icons.add_circle_outline, color: AppPalette.blue),
            const SizedBox(width: 10),
            Expanded(child: Text('Module — ${filiere.nom}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                maxLines: 2)),
          ]),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            _champDialog(nomCtrl, 'Nom du module', Icons.book_outlined),
            const SizedBox(height: 10),
            _champDialog(codeCtrl, 'Code (ex: INF301)', Icons.tag_rounded),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _champDialog(coefCtrl, 'Coefficient', Icons.numbers,
                  type: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _champDialog(volCtrl, 'Volume (h)', Icons.access_time,
                  type: TextInputType.number)),
            ]),
            const SizedBox(height: 10),
            // Sélecteur prof
            Container(
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true, value: profSelectionne,
                  hint: const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Assigner un professeur', style: TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 13))),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  borderRadius: BorderRadius.circular(12),
                  items: profs.map((p) => DropdownMenuItem(
                    value: '${p.prenoms} ${p.nom}',
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('${p.prenoms} ${p.nom}',
                            style: const TextStyle(fontSize: 13))),
                  )).toList(),
                  onChanged: (v) => setS(() => profSelectionne = v),
                ),
              ),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B)))),
            ElevatedButton(
              onPressed: () {
                if (nomCtrl.text.isEmpty || codeCtrl.text.isEmpty) return;
                setState(() {
                  (filiere.modules as List).add(AdminModule(
                    id: 'M${filiere.modules.length + 1}',
                    nom: nomCtrl.text,
                    code: codeCtrl.text.toUpperCase(),
                    coefficient: int.tryParse(coefCtrl.text) ?? 1,
                    volumeHoraire: int.tryParse(volCtrl.text) ?? 30,
                    profNom: profSelectionne ?? 'Non assigné',
                  ));
                  // Ajouter ce module au prof si sélectionné
                  if (profSelectionne != null) {
                    final prof = adminComptes.where((c) =>
                        '${c.prenoms} ${c.nom}' == profSelectionne).firstOrNull;
                    if (prof != null && !prof.modules.contains(nomCtrl.text)) {
                      prof.modules = [...prof.modules, nomCtrl.text];
                    }
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Module "${nomCtrl.text}" ajouté à ${filiere.nom}'),
                  backgroundColor: AppPalette.blue,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _champDialog(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text}) =>
      Container(
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12)),
        child: TextField(controller: ctrl, keyboardType: type,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13))),
      );

  void _voirGroupe(AdminFiliere f) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Groupe "${f.nom}" — 100% privé, accès réservé aux étudiants'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _confirmerSuppressionFiliere(AdminFiliere f) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
          SizedBox(width: 10),
          Text('Supprimer la filière',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Text('Supprimer "${f.nom}" ? Cette action est irréversible.',
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () {
              setState(() { adminFilieres.remove(f); _filiereSelectee = null; });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Filière supprimée.'),
                backgroundColor: Color(0xFFDC2626),
                behavior: SnackBarBehavior.floating,
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

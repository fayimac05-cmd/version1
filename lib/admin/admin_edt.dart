import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../utils/snackbar_helper.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES
// ════════════════════════════════════════════════════════════════════════════
class EdtFichier {
  final String id, nom, domaine, niveau, semaine, dateAjout, taille;
  bool actif;

  EdtFichier({
    required this.id, required this.nom, required this.domaine, required this.niveau,
    required this.semaine, required this.dateAjout, required this.taille, this.actif = true,
  });
}

// ── Données mock (Temporaire) ──────────────────────────────────────────────
final List<EdtFichier> adminEdtFichiers = [
  EdtFichier(id: 'E001', nom: 'EDT_ST_L1_Semaine18.pdf', domaine: 'Sciences & Technologies', niveau: 'Licence 1', semaine: 'Semaine 18 — 28 Avr au 02 Mai 2026', dateAjout: '27/04/2026', taille: '245 Ko', actif: true),
  EdtFichier(id: 'E006', nom: 'EDT_SG_L3_Semaine18.pdf', domaine: 'Sciences de Gestion', niveau: 'Licence 3', semaine: 'Semaine 18 — 28 Avr au 02 Mai 2026', dateAjout: '27/04/2026', taille: '267 Ko', actif: false),
];

// ════════════════════════════════════════════════════════════════════════════
// PAGE ADMIN EDT - VERSION MODERNE
// ════════════════════════════════════════════════════════════════════════════
class AdminEDT extends StatefulWidget {
  const AdminEDT({super.key});
  @override State<AdminEDT> createState() => _AdminEDTState();
}

class _AdminEDTState extends State<AdminEDT> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _filtreDomaine = 'tous', _filtreNiveau = 'tous', _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  // Logique filtrage propre
  List<EdtFichier> _getList(bool actif) => adminEdtFichiers.where((e) =>
      e.actif == actif &&
      (_filtreDomaine == 'tous' || e.domaine == _filtreDomaine) &&
      (_filtreNiveau == 'tous' || e.niveau == _filtreNiveau) &&
      (_query.isEmpty || e.nom.toLowerCase().contains(_query.toLowerCase()))
  ).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(children: [
        _buildHeader(),
        Expanded(child: TabBarView(controller: _tabs, children: [
          _buildListe(_getList(true), true),
          _buildListe(_getList(false), false),
        ])),
      ]),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.all(24),
    color: Colors.white,
    child: Column(children: [
      Row(children: [
        const Text('Emplois du temps', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const Spacer(),
        FilledButton.icon(
          onPressed: _dialogAjouter,
          icon: const Icon(Icons.add, color: AdminTheme.iconFgAlt),
          label: const Text('Publier', style: TextStyle(color: AdminTheme.iconFgAlt)),
          style: FilledButton.styleFrom(backgroundColor: AdminTheme.iconBgAlt),
        ),
      ]),
      const SizedBox(height: 16),
      TabBar(controller: _tabs, tabs: const [Tab(text: 'Actifs'), Tab(text: 'Archives')]),
    ]),
  );

  Widget _buildListe(List<EdtFichier> items, bool actif) {
    if (items.isEmpty) return const Center(child: Text("Aucun élément trouvé"));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildCarte(items[i], actif),
    );
  }

  Widget _buildCarte(EdtFichier f, bool actif) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
    child: ListTile(
      leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
      title: Text(f.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${f.domaine} · ${f.niveau}'),
      trailing: IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
    ),
  );

  void _dialogAjouter() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const Text('Publier un EDT', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(decoration: InputDecoration(labelText: 'Domaine', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 16),
        Expanded(child: Container()), // Placeholder pour le contenu
        SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Valider'))),
      ]),
    ));
  }
}
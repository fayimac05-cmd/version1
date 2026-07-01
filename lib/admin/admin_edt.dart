import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_annonces.dart' show istNiveaux;
import '../services/api_service.dart';

// ════════════════════════════════════════════════════════════════════════════
// CONFIGURATION GRILLE
// ════════════════════════════════════════════════════════════════════════════
const List<String> joursSemaine = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];

const List<Map<String, String>> creneauxHoraires = [
  {'debut': '08:00', 'fin': '10:00'},
  {'debut': '10:00', 'fin': '12:00'},
  {'debut': '12:00', 'fin': '14:00'},
  {'debut': '14:00', 'fin': '16:00'},
  {'debut': '16:00', 'fin': '18:00'},
];

const List<Map<String, String>> typeCoursOptions = [
  {'val': 'cours', 'label': 'Cours'},
  {'val': 'td', 'label': 'TD'},
  {'val': 'tp', 'label': 'TP'},
  {'val': 'examen', 'label': 'Examen'},
];

Color couleurPourType(String type) {
  switch (type) {
    case 'td': return const Color(0xFF8B5CF6);
    case 'tp': return const Color(0xFF10B981);
    case 'examen': return AdminTheme.danger;
    default: return AdminTheme.iconBg;
  }
}

String labelPourType(String type) {
  return typeCoursOptions.firstWhere((t) => t['val'] == type, orElse: () => typeCoursOptions[0])['label']!;
}

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES
// ════════════════════════════════════════════════════════════════════════════
class Creneau {
  String jour, heureDebut, heureFin, matiere, salle, type;
  Creneau({
    required this.jour, required this.heureDebut, required this.heureFin,
    required this.matiere, required this.salle, this.type = 'cours',
  });

  factory Creneau.fromJson(Map<String, dynamic> json) => Creneau(
        jour: json['jour'] ?? '',
        heureDebut: json['heureDebut'] ?? '',
        heureFin: json['heureFin'] ?? '',
        matiere: json['matiere'] ?? '',
        salle: json['salle'] ?? '',
        type: json['type'] ?? 'cours',
      );

  Map<String, dynamic> toJson() => {
        'jour': jour, 'heureDebut': heureDebut, 'heureFin': heureFin,
        'matiere': matiere, 'salle': salle, 'type': type,
      };
}

class EdtEntry {
  final String id;
  final String? filiereId;
  final String filiereNom, niveau, anneeAcademique;
  final bool archive;
  final List<Creneau> creneaux;

  EdtEntry({
    required this.id, this.filiereId, required this.filiereNom,
    required this.niveau, required this.anneeAcademique,
    required this.archive, required this.creneaux,
  });

  factory EdtEntry.fromJson(Map<String, dynamic> json) => EdtEntry(
        id: json['id'].toString(),
        filiereId: json['filiere']?.toString(),
        filiereNom: json['filiere_nom'] ?? 'Filière inconnue',
        niveau: json['niveau'] ?? '',
        anneeAcademique: json['anneeAcademique'] ?? '',
        archive: json['archive'] == true,
        creneaux: (json['creneaux'] as List<dynamic>? ?? [])
            .map((c) => Creneau.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// PAGE ADMIN EDT
// ════════════════════════════════════════════════════════════════════════════
class AdminEDT extends StatefulWidget {
  const AdminEDT({super.key});
  @override State<AdminEDT> createState() => _AdminEDTState();
}

class _AdminEDTState extends State<AdminEDT> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<EdtEntry> _entries = [];
  List<Map<String, dynamic>> _filieres = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    final results = await Future.wait([
      ApiService.getEdtAdmin(includeArchives: true),
      ApiService.getFilieres(),
    ]);
    if (!mounted) return;
    final edtResult = results[0];
    final filieresResult = results[1];
    setState(() {
      _isLoading = false;
      if (edtResult['success'] == true) {
        _entries = (edtResult['data'] as List<dynamic>).map((j) => EdtEntry.fromJson(j as Map<String, dynamic>)).toList();
      } else {
        _errorMessage = edtResult['error'] as String?;
      }
      if (filieresResult['success'] == true) {
        _filieres = (filieresResult['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      }
    });
  }

  List<EdtEntry> _getList(bool actif) => _entries.where((e) => e.archive != actif).toList();

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.redAccent : const Color(0xFF1E293B), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? _buildErrorState()
                  : TabBarView(controller: _tabs, children: [
                      _buildListe(_getList(true), true),
                      _buildListe(_getList(false), false),
                    ]),
        ),
      ]),
    );
  }

  Widget _buildErrorState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 32),
          const SizedBox(height: 12),
          Text(_errorMessage ?? 'Erreur', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loadData, child: const Text('Réessayer')),
        ]),
      );

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.all(24),
    color: Colors.white,
    child: Column(children: [
      Row(children: [
        const Text('Emplois du temps', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const Spacer(),
        IconButton(onPressed: _isLoading ? null : _loadData, icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)), tooltip: 'Actualiser'),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _demarrerCreation,
          icon: const Icon(Icons.add, color: AdminTheme.iconFgAlt),
          label: const Text('Créer un emploi du temps', style: TextStyle(color: AdminTheme.iconFgAlt)),
          style: FilledButton.styleFrom(backgroundColor: AdminTheme.iconBgAlt),
        ),
      ]),
      const SizedBox(height: 16),
      TabBar(controller: _tabs, tabs: const [Tab(text: 'Actifs'), Tab(text: 'Archives')]),
    ]),
  );

  Widget _buildListe(List<EdtEntry> items, bool actif) {
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.event_note_outlined, color: Color(0xFF94A3B8), size: 40),
          const SizedBox(height: 12),
          const Text("Aucun emploi du temps trouvé", style: TextStyle(color: Color(0xFF64748B))),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildCarte(items[i]),
    );
  }

  Widget _buildCarte(EdtEntry e) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
    child: ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: AdminTheme.iconBg.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.grid_view_rounded, color: AdminTheme.iconBg, size: 20),
      ),
      title: Text(e.filiereNom, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${e.niveau} · ${e.anneeAcademique} · ${e.creneaux.length} créneau(x)'),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) => _handleAction(value, e),
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'modifier', child: Text('Modifier la grille')),
          PopupMenuItem(value: e.archive ? 'reactiver' : 'archiver', child: Text(e.archive ? 'Réactiver' : 'Archiver')),
          const PopupMenuItem(value: 'supprimer', child: Text('Supprimer', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
      onTap: () => _handleAction('modifier', e),
    ),
  );

  Future<void> _handleAction(String action, EdtEntry e) async {
    if (action == 'modifier') {
      _ouvrirEditeurGrille(filiereId: e.filiereId, filiereNom: e.filiereNom, niveau: e.niveau, existant: e);
      return;
    }
    if (action == 'archiver') {
      final result = await ApiService.archiveEdt(e.id);
      if (result['success'] == true) { _showSnack('Emploi du temps archivé.'); _loadData(); }
      else { _showSnack(result['error'] as String? ?? 'Erreur.', isError: true); }
      return;
    }
    if (action == 'reactiver') {
      final result = await ApiService.updateEdtGrille(e.id, {'archive': false});
      if (result['success'] == true) { _showSnack('Emploi du temps réactivé.'); _loadData(); }
      else { _showSnack(result['error'] as String? ?? 'Erreur.', isError: true); }
      return;
    }
    if (action == 'supprimer') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Confirmer la suppression', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Supprimer l\'emploi du temps de « ${e.filiereNom} - ${e.niveau} » ? Cette action est irréversible.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        final result = await ApiService.deleteEdt(e.id);
        if (result['success'] == true) { _showSnack('Emploi du temps supprimé.'); _loadData(); }
        else { _showSnack(result['error'] as String? ?? 'Erreur.', isError: true); }
      }
    }
  }

  // ── Étape 1 : sélection filière + niveau ──────────────────────────────
  void _demarrerCreation() {
    String? selectedFiliere;
    String? selectedNiveau;
    final anneeController = TextEditingController(text: DateTime.now().year.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nouvel emploi du temps', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Align(alignment: Alignment.centerLeft, child: Text('Filière', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
              const SizedBox(height: 6),
              _buildDropdownContainer(
                child: DropdownButton<String>(
                  value: selectedFiliere,
                  hint: const Text('Choisir la filière', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                  isExpanded: true, underline: const SizedBox(),
                  items: _filieres.map((f) => DropdownMenuItem(value: f['id'].toString(), child: Text(f['nom'], style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setDialogState(() => selectedFiliere = v),
                ),
              ),
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerLeft, child: Text('Niveau', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
              const SizedBox(height: 6),
              _buildDropdownContainer(
                child: DropdownButton<String>(
                  value: selectedNiveau,
                  hint: const Text('Choisir le niveau', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                  isExpanded: true, underline: const SizedBox(),
                  items: istNiveaux.map((n) => DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setDialogState(() => selectedNiveau = v),
                ),
              ),
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerLeft, child: Text('Année académique', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
              const SizedBox(height: 6),
              TextField(
                controller: anneeController,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                if (selectedFiliere == null || selectedNiveau == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('⚠️ Sélectionnez une filière et un niveau.'), backgroundColor: Colors.redAccent),
                  );
                  return;
                }
                final filiereNom = _filieres.firstWhere((f) => f['id'].toString() == selectedFiliere)['nom'] as String;
                Navigator.pop(dialogContext);
                _ouvrirEditeurGrille(
                  filiereId: selectedFiliere,
                  filiereNom: filiereNom,
                  niveau: selectedNiveau!,
                  anneeAcademique: anneeController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.iconBgAlt),
              child: const Text('Continuer', style: TextStyle(color: AdminTheme.iconFgAlt)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownContainer({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: DropdownButtonHideUnderline(child: child),
      );

  // ── Étape 2 : éditeur de grille façon Excel ───────────────────────────
  void _ouvrirEditeurGrille({
    required String? filiereId,
    required String filiereNom,
    required String niveau,
    String anneeAcademique = '',
    EdtEntry? existant,
  }) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _GrilleEdtScreen(
        filiereId: filiereId,
        filiereNom: filiereNom,
        niveau: niveau,
        anneeAcademique: existant?.anneeAcademique ?? (anneeAcademique.isEmpty ? DateTime.now().year.toString() : anneeAcademique),
        creneauxInitiaux: existant?.creneaux ?? [],
        edtId: existant?.id,
      ),
    )).then((saved) {
      if (saved == true) _loadData();
    });
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ÉCRAN GRILLE — FORMAT EXCEL (JOURS × HEURES)
// ════════════════════════════════════════════════════════════════════════════
class _GrilleEdtScreen extends StatefulWidget {
  final String? filiereId;
  final String filiereNom, niveau, anneeAcademique;
  final List<Creneau> creneauxInitiaux;
  final String? edtId;

  const _GrilleEdtScreen({
    required this.filiereId, required this.filiereNom, required this.niveau,
    required this.anneeAcademique, required this.creneauxInitiaux, this.edtId,
  });

  @override State<_GrilleEdtScreen> createState() => _GrilleEdtScreenState();
}

class _GrilleEdtScreenState extends State<_GrilleEdtScreen> {
  late List<Creneau> _creneaux;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _creneaux = List.from(widget.creneauxInitiaux);
  }

  Creneau? _findCreneau(String jour, String debut) {
    for (final c in _creneaux) {
      if (c.jour == jour && c.heureDebut == debut) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text('${widget.filiereNom} — ${widget.niveau}', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildLegende(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildGrilleTable(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _enregistrer,
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.iconBgAlt, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.iconFgAlt))
                : Text(widget.edtId == null ? 'Enregistrer l\'emploi du temps' : 'Mettre à jour l\'emploi du temps', style: const TextStyle(color: AdminTheme.iconFgAlt, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildLegende() => Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Wrap(
          spacing: 14, runSpacing: 8,
          children: typeCoursOptions.map((t) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: couleurPourType(t['val']!), borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 6),
                  Text(t['label']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                ],
              )).toList(),
        ),
      );

  Widget _buildGrilleTable() {
    const double colWidth = 170;
    const double timeColWidth = 100;
    const double rowHeight = 88;

    return Table(
      border: TableBorder.all(color: const Color(0xFFE2E8F0), width: 1),
      columnWidths: {
        0: const FixedColumnWidth(timeColWidth),
        for (int i = 1; i <= joursSemaine.length; i++) i: const FixedColumnWidth(colWidth),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF0A4DA2)),
          children: [
            const SizedBox(height: 44),
            ...joursSemaine.map((j) => Container(
                  height: 44, alignment: Alignment.center,
                  child: Text(j, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                )),
          ],
        ),
        for (final horaire in creneauxHoraires)
          TableRow(
            children: [
              Container(
                height: rowHeight, alignment: Alignment.center,
                color: const Color(0xFFF1F5F9),
                child: Text('${horaire['debut']}\n${horaire['fin']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              ),
              ...joursSemaine.map((jour) => _buildCellule(jour, horaire['debut']!, horaire['fin']!, rowHeight)),
            ],
          ),
      ],
    );
  }

  Widget _buildCellule(String jour, String debut, String fin, double height) {
    final creneau = _findCreneau(jour, debut);
    final couleur = creneau != null ? couleurPourType(creneau.type) : const Color(0xFF94A3B8);

    return InkWell(
      onTap: () => _editerCellule(jour, debut, fin, creneau),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(6),
        color: creneau != null ? couleur.withValues(alpha: 0.10) : Colors.white,
        child: creneau == null
            ? const Center(child: Icon(Icons.add_rounded, color: Color(0xFFCBD5E1), size: 18))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(4)),
                    child: Text(labelPourType(creneau.type), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 4),
                  Text(creneau.matiere, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.room_outlined, size: 11, color: Color(0xFF64748B)),
                    const SizedBox(width: 2),
                    Expanded(child: Text(creneau.salle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                ],
              ),
      ),
    );
  }

  void _editerCellule(String jour, String debut, String fin, Creneau? existant) {
    final matiereController = TextEditingController(text: existant?.matiere ?? '');
    final salleController = TextEditingController(text: existant?.salle ?? '');
    String selectedType = existant?.type ?? 'cours';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('$jour · $debut - $fin', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          content: SizedBox(
            width: 340,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: matiereController,
                decoration: InputDecoration(labelText: 'Matière / Module', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: salleController,
                decoration: InputDecoration(labelText: 'Salle', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 14),
              Align(alignment: Alignment.centerLeft, child: Wrap(
                spacing: 8,
                children: typeCoursOptions.map((t) {
                  final isSelected = selectedType == t['val'];
                  final color = couleurPourType(t['val']!);
                  return ChoiceChip(
                    label: Text(t['label']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : color)),
                    selected: isSelected,
                    selectedColor: color,
                    backgroundColor: color.withValues(alpha: 0.08),
                    onSelected: (_) => setDialogState(() => selectedType = t['val']!),
                  );
                }).toList(),
              )),
            ]),
          ),
          actions: [
            if (existant != null)
              TextButton(
                onPressed: () {
                  setState(() => _creneaux.removeWhere((c) => c.jour == jour && c.heureDebut == debut));
                  Navigator.pop(dialogContext);
                },
                child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
              ),
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                final matiere = matiereController.text.trim();
                final salle = salleController.text.trim();
                if (matiere.isEmpty || salle.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('⚠️ Renseignez la matière et la salle.'), backgroundColor: Colors.redAccent),
                  );
                  return;
                }
                setState(() {
                  _creneaux.removeWhere((c) => c.jour == jour && c.heureDebut == debut);
                  _creneaux.add(Creneau(jour: jour, heureDebut: debut, heureFin: fin, matiere: matiere, salle: salle, type: selectedType));
                });
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.iconBgAlt),
              child: const Text('Valider', style: TextStyle(color: AdminTheme.iconFgAlt)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enregistrer() async {
    if (_creneaux.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Ajoutez au moins un créneau avant d\'enregistrer.'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _isSaving = true);

    final payload = {
      'filiere': widget.filiereId,
      'niveau': widget.niveau,
      'anneeAcademique': widget.anneeAcademique,
      'creneaux': _creneaux.map((c) => c.toJson()).toList(),
    };

    final result = widget.edtId == null
        ? await ApiService.createEdtGrille(payload)
        : await ApiService.updateEdtGrille(widget.edtId!, payload);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Emploi du temps enregistré avec succès.'), backgroundColor: Color(0xFF1E293B), behavior: SnackBarBehavior.floating),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] as String? ?? 'Erreur lors de l\'enregistrement.'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
    }
  }
}

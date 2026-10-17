import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_annonces.dart' show istNiveaux;
import '../services/api_service.dart';

// ════════════════════════════════════════════════════════════════════════════
// CONFIGURATION GRILLE
// ════════════════════════════════════════════════════════════════════════════
const List<String> joursSemaine = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];

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

final DateFormat _formatDateAffichage = DateFormat('dd/MM/yyyy');

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES
// ════════════════════════════════════════════════════════════════════════════
class Creneau {
  String jour, heureDebut, heureFin, matiere, salle, type, prof;
  Creneau({
    required this.jour, required this.heureDebut, required this.heureFin,
    required this.matiere, required this.salle, this.type = 'cours', this.prof = '',
  });

  factory Creneau.fromJson(Map<String, dynamic> json) => Creneau(
        jour: json['jour'] ?? '',
        heureDebut: json['heureDebut'] ?? '',
        heureFin: json['heureFin'] ?? '',
        matiere: json['matiere'] ?? '',
        salle: json['salle'] ?? '',
        type: json['type'] ?? 'cours',
        prof: json['prof'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'jour': jour, 'heureDebut': heureDebut, 'heureFin': heureFin,
        'matiere': matiere, 'salle': salle, 'type': type, 'prof': prof,
      };
}

class EdtEntry {
  final String id;
  final String? filiereId;
  final String filiereNom, niveau, anneeAcademique;
  final bool archive;
  final List<Creneau> creneaux;
  final DateTime? dateDebut;
  final DateTime? dateFin;

  EdtEntry({
    required this.id, this.filiereId, required this.filiereNom,
    required this.niveau, required this.anneeAcademique,
    required this.archive, required this.creneaux,
    this.dateDebut, this.dateFin,
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
        dateDebut: json['dateDebut'] != null ? DateTime.tryParse(json['dateDebut'].toString()) : null,
        dateFin: json['dateFin'] != null ? DateTime.tryParse(json['dateFin'].toString()) : null,
      );

  String get periodeAffichee => (dateDebut != null && dateFin != null)
      ? 'Semaine du ${_formatDateAffichage.format(dateDebut!)} au ${_formatDateAffichage.format(dateFin!)}'
      : '';
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
      subtitle: Text(
        e.periodeAffichee.isNotEmpty
            ? '${e.periodeAffichee} · ${e.niveau} · ${e.creneaux.length} créneau(x)'
            : '${e.niveau} · ${e.anneeAcademique} · ${e.creneaux.length} créneau(x)',
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) => _handleAction(value, e),
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'envoyer',
            child: Row(children: [
              Icon(Icons.send_rounded, size: 18, color: AdminTheme.iconBgAlt),
              SizedBox(width: 10),
              Text('Envoyer aux étudiants'),
            ]),
          ),
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
      _ouvrirEditeurGrille(
        filiereId: e.filiereId,
        filiereNom: e.filiereNom,
        niveau: e.niveau,
        existant: e,
      );
      return;
    }
    if (action == 'envoyer') {
      await _envoyerAuxEtudiants(e.id, e.filiereNom, e.niveau);
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

  // ── Envoyer un EDT aux étudiants (filière + niveau) ───────────────────
  Future<void> _envoyerAuxEtudiants(String id, String filiereNom, String niveau) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(children: [
          Icon(Icons.send_rounded, color: AdminTheme.iconBgAlt),
          SizedBox(width: 10),
          Text('Envoyer aux étudiants', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: Text(
          'Notifier tous les étudiants de « $filiereNom — $niveau » que leur emploi du temps est disponible ?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.iconBgAlt),
            child: const Text('Envoyer', style: TextStyle(color: AdminTheme.iconFgAlt)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    _showSnack('Envoi en cours…');
    final result = await ApiService.envoyerEdt(id);
    if (!mounted) return;
    if (result['success'] == true) {
      final total = result['total'] ?? 0;
      final notifies = result['notifies'] ?? 0;
      _showSnack(total == 0
          ? 'Aucun étudiant trouvé pour cette filière et ce niveau.'
          : 'Emploi du temps envoyé à $notifies étudiant(s).');
    } else {
      _showSnack(result['error'] as String? ?? 'Erreur lors de l\'envoi.', isError: true);
    }
  }

  // ── Étape 1 : sélection filière + niveau + dates de la semaine ────────
  void _demarrerCreation() {
    String? selectedFiliere;
    String? selectedNiveau;
    final anneeController = TextEditingController(text: DateTime.now().year.toString());
    DateTime? dateDebut;
    DateTime? dateFin;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nouvel emploi du temps', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
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
                const SizedBox(height: 16),
                const Align(alignment: Alignment.centerLeft, child: Text('Semaine du programme *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: _boutonDate(
                      label: dateDebut != null ? _formatDateAffichage.format(dateDebut!) : 'Date de début',
                      onTap: () async {
                        final d = await showDatePicker(
                          context: dialogContext,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setDialogState(() => dateDebut = d);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _boutonDate(
                      label: dateFin != null ? _formatDateAffichage.format(dateFin!) : 'Date de fin',
                      onTap: () async {
                        final d = await showDatePicker(
                          context: dialogContext,
                          initialDate: dateDebut ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setDialogState(() => dateFin = d);
                      },
                    ),
                  ),
                ]),
              ]),
            ),
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
                if (dateDebut == null || dateFin == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('⚠️ Indiquez la date de début et de fin de la semaine.'), backgroundColor: Colors.redAccent),
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
                  dateDebut: dateDebut,
                  dateFin: dateFin,
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

  Widget _boutonDate({required String label, required VoidCallback onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)), overflow: TextOverflow.ellipsis)),
          ]),
        ),
      );

  Widget _buildDropdownContainer({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: DropdownButtonHideUnderline(child: child),
      );

  // ── Étape 2 : éditeur de grille ────────────────────────────────────────
  void _ouvrirEditeurGrille({
    required String? filiereId,
    required String filiereNom,
    required String niveau,
    String anneeAcademique = '',
    DateTime? dateDebut,
    DateTime? dateFin,
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
        dateDebutInitiale: existant?.dateDebut ?? dateDebut,
        dateFinInitiale: existant?.dateFin ?? dateFin,
      ),
    )).then((saved) {
      if (saved == true) _loadData();
    });
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ÉCRAN GRILLE
// ════════════════════════════════════════════════════════════════════════════
class _GrilleEdtScreen extends StatefulWidget {
  final String? filiereId;
  final String filiereNom, niveau, anneeAcademique;
  final List<Creneau> creneauxInitiaux;
  final String? edtId;
  final DateTime? dateDebutInitiale;
  final DateTime? dateFinInitiale;

  const _GrilleEdtScreen({
    required this.filiereId, required this.filiereNom, required this.niveau,
    required this.anneeAcademique, required this.creneauxInitiaux, this.edtId,
    this.dateDebutInitiale, this.dateFinInitiale,
  });

  @override State<_GrilleEdtScreen> createState() => _GrilleEdtScreenState();
}

class _GrilleEdtScreenState extends State<_GrilleEdtScreen> {
  late List<Creneau> _creneaux;
  late DateTime? _dateDebut;
  late DateTime? _dateFin;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _creneaux = List.from(widget.creneauxInitiaux);
    _dateDebut = widget.dateDebutInitiale;
    _dateFin = widget.dateFinInitiale;
  }

  /// Cours d'un jour donné, triés chronologiquement.
  List<Creneau> _coursDuJour(String jour) {
    final liste = _creneaux.where((c) => c.jour == jour).toList();
    liste.sort((a, b) => a.heureDebut.compareTo(b.heureDebut));
    return liste;
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
          _buildEnTete(),
          _buildLegende(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildGrilleParJour(),
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

  // ── Bandeau : dates de la semaine + bouton ajouter un cours ───────────
  Widget _buildEnTete() => Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: _choisirDates,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(children: [
                  const Icon(Icons.date_range_rounded, size: 16, color: AdminTheme.iconBgAlt),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (_dateDebut != null && _dateFin != null)
                          ? 'Semaine du ${_formatDateAffichage.format(_dateDebut!)} au ${_formatDateAffichage.format(_dateFin!)}'
                          : 'Définir la semaine (date début / fin)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminTheme.iconBgAlt),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.edit_rounded, size: 14, color: AdminTheme.iconBgAlt),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => _editerCellule(),
            icon: const Icon(Icons.add_rounded, size: 18, color: AdminTheme.iconFgAlt),
            label: const Text('Ajouter un cours', style: TextStyle(color: AdminTheme.iconFgAlt, fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.iconBgAlt, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
          ),
        ]),
      );

  Future<void> _choisirDates() async {
    final debut = await showDatePicker(
      context: context,
      initialDate: _dateDebut ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Date de début de la semaine',
    );
    if (debut == null || !mounted) return;
    final fin = await showDatePicker(
      context: context,
      initialDate: _dateFin ?? debut,
      firstDate: debut,
      lastDate: DateTime(2100),
      helpText: 'Date de fin de la semaine',
    );
    if (fin == null) return;
    setState(() {
      _dateDebut = debut;
      _dateFin = fin;
    });
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

  Widget _buildGrilleParJour() {
    const double colWidth = 200;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : une seule barre continue (pas de séparation entre les
          // jours ici) pour que l'ensemble se lise clairement comme UN SEUL
          // tableau, pas des cases indépendantes les unes des autres.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: joursSemaine.map((jour) => Container(
                  width: colWidth,
                  height: 44,
                  color: const Color(0xFF0A4DA2),
                  alignment: Alignment.center,
                  child: Text(jour, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                )).toList(),
          ),
          // Corps : les colonnes restent indépendantes en hauteur (chaque
          // jour garde ses propres cases), mais un fin séparateur vertical
          // les relie visuellement pour rester UN SEUL tableau.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < joursSemaine.length; i++) ...[
                  if (i > 0) const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                  SizedBox(width: colWidth, child: _corpsJour(joursSemaine[i])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const double _caseHeight = 96;

  /// Contenu empilé d'une colonne jour : cartes de cours, séparées par un
  /// espace proportionnel à l'écart réel entre elles (ex. 2h d'écart entre
  /// deux cours → un vrai blanc visible et étiqueté "2h", pas juste un
  /// simple filet comme avant). Minimum 2 cases si le jour a moins de 2
  /// cours, pour garder un point de départ visuel identique sur toute la
  /// semaine.
  Widget _corpsJour(String jour) {
    final cours = _coursDuJour(jour);
    final children = <Widget>[];

    if (cours.isEmpty) {
      children.add(SizedBox(height: _caseHeight, child: _caseVide(jour)));
      children.add(const Divider(height: 1, color: Color(0xFFE2E8F0)));
      children.add(SizedBox(height: _caseHeight, child: _caseVide(jour)));
    } else {
      for (var i = 0; i < cours.length; i++) {
        children.add(SizedBox(height: _caseHeight, child: _carteCoursRemplie(jour, cours[i])));
        if (i < cours.length - 1) {
          children.add(_spacerEcart(_ecartMinutes(cours[i].heureFin, cours[i + 1].heureDebut)));
        }
      }
      if (cours.length < 2) {
        children.add(const Divider(height: 1, color: Color(0xFFE2E8F0)));
        children.add(SizedBox(height: _caseHeight, child: _caseVide(jour)));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  /// Écart en minutes entre la fin d'un cours et le début du suivant (0 si
  /// horaires invalides ou s'ils s'enchaînent directement).
  int _ecartMinutes(String finA, String debutB) {
    final fa = _parseHeure(finA);
    final db = _parseHeure(debutB);
    if (fa == null || db == null) return 0;
    final diff = (db.hour * 60 + db.minute) - (fa.hour * 60 + fa.minute);
    return diff > 0 ? diff : 0;
  }

  /// Espace entre deux cours du même jour. Hauteur proportionnelle à
  /// l'écart réel (~28px par heure, plafonnée) avec l'écart affiché en
  /// clair ("2h", "45min"...) — pour vraiment "sentir" le vide entre deux
  /// cours plutôt qu'un simple filet de séparation.
  Widget _spacerEcart(int minutes) {
    if (minutes <= 0) {
      return const Divider(height: 1, color: Color(0xFFE2E8F0));
    }
    final hauteur = (minutes / 60 * 28).clamp(22.0, 64.0);
    final heures = minutes / 60.0;
    final label = heures == heures.roundToDouble()
        ? '${heures.toStringAsFixed(0)}h'
        : (minutes < 60 ? '${minutes}min' : '${heures.toStringAsFixed(1)}h');
    return Container(
      height: hauteur,
      width: double.infinity,
      alignment: Alignment.center,
      color: const Color(0xFFF8FAFC),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Container(height: 1, margin: const EdgeInsets.only(right: 6), color: const Color(0xFFE2E8F0))),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
          Expanded(child: Container(height: 1, margin: const EdgeInsets.only(left: 6), color: const Color(0xFFE2E8F0))),
        ],
      ),
    );
  }

  Widget _caseVide(String jour) => InkWell(
        onTap: () => _editerCellule(jourPreselectionne: jour),
        child: const Center(child: Icon(Icons.add_rounded, color: Color(0xFFCBD5E1), size: 20)),
      );

  Widget _carteCoursRemplie(String jour, Creneau creneau) {
    final couleur = couleurPourType(creneau.type);
    return InkWell(
      onTap: () => _editerCellule(jourPreselectionne: jour, existant: creneau),
      child: Container(
        padding: const EdgeInsets.all(8),
        color: couleur.withValues(alpha: 0.10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(4)),
                child: Text(labelPourType(creneau.type), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(width: 6),
              Text('${creneau.heureDebut} - ${creneau.heureFin}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            ]),
            const SizedBox(height: 4),
            Text(creneau.matiere, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), maxLines: 2, overflow: TextOverflow.ellipsis),
            if (creneau.prof.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.person_outline_rounded, size: 11, color: Color(0xFF64748B)),
                const SizedBox(width: 2),
                Expanded(child: Text(creneau.prof, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ],
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

  TimeOfDay? _parseHeure(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatHeure(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Chaque jour étant maintenant une colonne indépendante, jour ET horaires
  /// sont toujours librement modifiables ici (plus de ligne partagée entre
  /// les jours). [existant] non-null == modification d'un cours déjà posé
  /// (l'objet est retiré de la liste par référence puis remplacé) ;
  /// [jourPreselectionne] présélectionne le jour (case vide d'une colonne),
  /// laissé modifiable si l'admin veut finalement le déplacer.
  void _editerCellule({String? jourPreselectionne, Creneau? existant}) {
    final matiereController = TextEditingController(text: existant?.matiere ?? '');
    final salleController = TextEditingController(text: existant?.salle ?? '');
    final profController = TextEditingController(text: existant?.prof ?? '');
    String selectedType = existant?.type ?? 'cours';
    String? selectedJour = existant?.jour ?? jourPreselectionne;
    TimeOfDay? heureDebut = _parseHeure(existant?.heureDebut);
    TimeOfDay? heureFin = _parseHeure(existant?.heureFin);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existant == null ? 'Nouveau cours' : 'Modifier le cours', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Align(alignment: Alignment.centerLeft, child: Text('Jour', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedJour,
                      hint: const Text('Choisir le jour', style: TextStyle(fontSize: 13)),
                      isExpanded: true,
                      items: joursSemaine.map((j) => DropdownMenuItem(value: j, child: Text(j, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) => setDialogState(() => selectedJour = v),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: _champHeure(
                      label: 'Heure début',
                      valeur: heureDebut,
                      onTap: () async {
                        final t = await showTimePicker(context: dialogContext, initialTime: heureDebut ?? const TimeOfDay(hour: 8, minute: 0));
                        if (t != null) setDialogState(() => heureDebut = t);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _champHeure(
                      label: 'Heure fin',
                      valeur: heureFin,
                      onTap: () async {
                        final t = await showTimePicker(context: dialogContext, initialTime: heureFin ?? const TimeOfDay(hour: 10, minute: 0));
                        if (t != null) setDialogState(() => heureFin = t);
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                TextField(
                  controller: matiereController,
                  decoration: InputDecoration(labelText: 'Matière / Module', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: profController,
                  decoration: InputDecoration(labelText: 'Professeur', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
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
          ),
          actions: [
            if (existant != null)
              TextButton(
                onPressed: () {
                  setState(() => _creneaux.remove(existant));
                  Navigator.pop(dialogContext);
                },
                child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
              ),
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                final matiere = matiereController.text.trim();
                final salle = salleController.text.trim();
                final prof = profController.text.trim();

                if (selectedJour == null || heureDebut == null || heureFin == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('⚠️ Choisissez le jour et les horaires.'), backgroundColor: Colors.redAccent),
                  );
                  return;
                }
                if (matiere.isEmpty || salle.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('⚠️ Renseignez la matière et la salle.'), backgroundColor: Colors.redAccent),
                  );
                  return;
                }

                setState(() {
                  if (existant != null) _creneaux.remove(existant);
                  _creneaux.add(Creneau(
                    jour: selectedJour!,
                    heureDebut: _formatHeure(heureDebut!),
                    heureFin: _formatHeure(heureFin!),
                    matiere: matiere, salle: salle, type: selectedType, prof: prof,
                  ));
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

  Widget _champHeure({required String label, required TimeOfDay? valeur, required VoidCallback onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(children: [
            const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(valeur != null ? _formatHeure(valeur) : label, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
          ]),
        ),
      );

  Future<void> _enregistrer() async {
    if (_creneaux.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Ajoutez au moins un créneau avant d\'enregistrer.'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_dateDebut == null || _dateFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Indiquez la date de début et de fin de la semaine.'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _isSaving = true);

    final payload = {
      'filiere': widget.filiereId,
      'niveau': widget.niveau,
      'anneeAcademique': widget.anneeAcademique,
      'creneaux': _creneaux.map((c) => c.toJson()).toList(),
      'dateDebut': _dateDebut!.toIso8601String().split('T').first,
      'dateFin': _dateFin!.toIso8601String().split('T').first,
    };

    final result = widget.edtId == null
        ? await ApiService.createEdtGrille(payload)
        : await ApiService.updateEdtGrille(widget.edtId!, payload);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      final newId = (widget.edtId ??
              (result['data'] is Map ? result['data']['id'] : null))
          ?.toString();

      if (newId != null && mounted) {
        final envoyer = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: const Text('Emploi du temps enregistré',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            content: Text(
                'Envoyer une notification aux étudiants de ${widget.filiereNom} — ${widget.niveau} ?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Plus tard')),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.iconBgAlt),
                icon: const Icon(Icons.send_rounded, size: 18, color: AdminTheme.iconFgAlt),
                label: const Text('Envoyer aux étudiants',
                    style: TextStyle(color: AdminTheme.iconFgAlt)),
              ),
            ],
          ),
        ) ?? false;

        if (envoyer && mounted) {
          final env = await ApiService.envoyerEdt(newId);
          if (mounted) {
            final msg = env['success'] == true
                ? ((env['total'] ?? 0) == 0
                    ? 'Aucun étudiant trouvé pour cette filière et ce niveau.'
                    : 'Emploi du temps envoyé à ${env['notifies'] ?? 0} étudiant(s).')
                : (env['error'] as String? ?? 'Erreur lors de l\'envoi.');
            await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                content: Text(msg),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK')),
                ],
              ),
            );
          }
        }
      }

      if (!mounted) return;
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
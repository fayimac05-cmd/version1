import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/student_profile.dart';
import '../services/professor_service.dart';
import '../theme/app_palette.dart';
import 'appel_qr_screen.dart';

class AppelTab extends StatefulWidget {
  const AppelTab({super.key, required this.profile, this.initialClasse});

  final StudentProfile profile;

  /// Classe présélectionnée depuis l'onglet "Mes Classes".
  final Map<String, dynamic>? initialClasse;

  @override
  State<AppelTab> createState() => _AppelTabState();
}

class _AppelTabState extends State<AppelTab> {
  static const Color _navyText = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _faint = Color(0xFF94A3B8);
  static const Color _border = Color(0xFFE5EBF3);
  static const Color _vert = Color(0xFF10B981);
  static const Color _rouge = Color(0xFFEF4444);
  static const Color _ambre = Color(0xFFF59E0B);

  List<dynamic> _classes = [];
  List<dynamic> _modules = [];
  List<dynamic> _students = [];
  List<dynamic> _historique = [];
  bool _loading = true;
  bool _loadingStudents = false;
  bool _saving = false;
  bool _exporting = false;
  String _searchQuery = '';
  String _searchEleve = '';
  int _tabInterne = 0; // 0 = Appel, 1 = Historique
  String _filtreFiliereTronc = 'Toutes les filières';

  // Clé du groupe de module sélectionné : "nom|niveau|semestre".
  String? _groupeKey;

  // matricule -> statut (present/absent/retard)
  final Map<String, String> _statuts = {};

  List<dynamic> get _historiqueFiltre {
    if (_searchQuery.isEmpty) return _historique;
    final q = _searchQuery.toLowerCase();
    return _historique.where((a) {
      final mod = (a['module_nom'] ?? '').toString().toLowerCase();
      final fil = (a['filiere_nom'] ?? '').toString().toLowerCase();
      final date = (a['date_appel'] ?? '').toString().toLowerCase();
      return mod.contains(q) || fil.contains(q) || date.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    final classesResult = await ProfessorService.getClasses();
    final modulesResult = await ProfessorService.getModules();
    final histResult = await ProfessorService.getAppels();
    if (!mounted) return;
    setState(() {
      _classes = classesResult['success'] == true ? classesResult['data'] as List<dynamic> : [];
      _modules = modulesResult['success'] == true ? modulesResult['data'] as List<dynamic> : [];
      _historique = histResult['success'] == true ? histResult['data'] as List<dynamic> : [];
      _loading = false;
    });
    _appliquerPreselection();
  }

  bool _preselectionAppliquee = false;

  void _appliquerPreselection() {
    final init = widget.initialClasse;
    if (init == null || _groupeKey != null || _preselectionAppliquee) return;
    _preselectionAppliquee = true;
    final matches = _modules.where((m) => m['filiere_id'].toString() == init['id'].toString());
    if (matches.isEmpty) return;
    _selectionnerGroupe(_cleGroupe(matches.first));
  }

  // ── Regroupement "tronc commun" ────────────────────────────────────────
  // Un module n'appartient qu'à UNE filière dans le schéma (modules.filiere_id).
  // Le "tronc commun" se détecte donc par nom+niveau+semestre identiques,
  // répartis sur plusieurs filiere_id — pas par un id de module partagé.
  String _cleGroupe(dynamic m) =>
      '${(m['nom'] ?? '').toString().trim().toLowerCase()}|${m['niveau']}|${m['semestre']}';

  Map<String, List<dynamic>> get _groupesModules {
    final groupes = <String, List<dynamic>>{};
    for (final m in _modules) {
      groupes.putIfAbsent(_cleGroupe(m), () => []).add(m);
    }
    return groupes;
  }

  List<dynamic>? get _groupeSelectionne => _groupeKey == null ? null : _groupesModules[_groupeKey];

  bool get _estTroncCommun {
    final g = _groupeSelectionne;
    if (g == null) return false;
    return g.map((m) => m['filiere_id'].toString()).toSet().length > 1;
  }

  List<String> get _filieresDuGroupe {
    final g = _groupeSelectionne;
    if (g == null) return [];
    return g.map((m) => m['filiere_nom']?.toString() ?? '').where((n) => n.isNotEmpty).toSet().toList();
  }

  void _selectionnerGroupe(String key) {
    setState(() {
      _groupeKey = key;
      _filtreFiliereTronc = 'Toutes les filières';
      _tabInterne = 0;
    });
    _chargerEtudiantsPourGroupe();
  }

  Future<void> _chargerEtudiantsPourGroupe() async {
    final groupe = _groupeSelectionne;
    if (groupe == null) return;
    setState(() {
      _loadingStudents = true;
      _students = [];
      _statuts.clear();
    });
    final merged = <dynamic>[];
    for (final m in groupe) {
      final res = await ProfessorService.getStudentsByFiliere(
        int.parse(m['filiere_id'].toString()),
        niveau: m['niveau']?.toString(),
      );
      if (res['success'] == true) {
        for (final s in (res['data'] as List<dynamic>)) {
          final tagged = Map<String, dynamic>.from(s as Map);
          tagged['_filiereId'] = m['filiere_id'].toString();
          tagged['_filiereNom'] = m['filiere_nom']?.toString() ?? '';
          tagged['_moduleId'] = m['id'].toString();
          merged.add(tagged);
          _statuts[tagged['matricule']] = 'present';
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _students = merged;
      _loadingStudents = false;
    });
  }

  List<dynamic> get _studentsFiltres {
    var list = _students;
    if (_estTroncCommun && _filtreFiliereTronc != 'Toutes les filières') {
      list = list.where((s) => s['_filiereNom'] == _filtreFiliereTronc).toList();
    }
    if (_searchEleve.trim().isNotEmpty) {
      final q = _searchEleve.trim().toLowerCase();
      list = list.where((s) => '${s['prenoms']} ${s['nom']}'.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Map<String, int> get _compteStatuts {
    final counts = {'present': 0, 'absent': 0, 'retard': 0};
    for (final s in _students) {
      final st = _statuts[s['matricule']] ?? 'present';
      counts[st] = (counts[st] ?? 0) + 1;
    }
    return counts;
  }

  String get _titreSession {
    if (_estTroncCommun) return 'Tronc commun';
    final g = _groupeSelectionne;
    if (g == null || g.isEmpty) return '';
    return g.first['filiere_nom']?.toString() ?? '';
  }

  String get _sousTitreSession {
    final g = _groupeSelectionne;
    if (g == null || g.isEmpty) return '';
    if (_estTroncCommun) {
      return '${_filieresDuGroupe.join(' + ')} • ${g.first['niveau'] ?? ''} • ${g.first['nom'] ?? ''}';
    }
    return '${g.first['nom'] ?? ''} • ${g.first['niveau'] ?? ''}';
  }

  Future<void> _enregistrerAppel() async {
    final groupe = _groupeSelectionne;
    if (groupe == null) return;
    setState(() => _saving = true);

    var toutOk = true;
    final echecs = <String>[];
    for (final m in groupe) {
      final filiereId = m['filiere_id'].toString();
      final sousListe = _students.where((s) => s['_filiereId'] == filiereId).toList();
      if (sousListe.isEmpty) continue;
      final presences = sousListe
          .map((s) => {'matricule': s['matricule'], 'statut': _statuts[s['matricule']] ?? 'present'})
          .toList();
      final res = await ProfessorService.createAppel({
        'filiere_id': int.parse(filiereId),
        'filiere_nom': m['filiere_nom'],
        'niveau': m['niveau'],
        'module_id': int.parse(m['id'].toString()),
        'presences': presences,
      });
      if (res['success'] != true) {
        toutOk = false;
        echecs.add(m['filiere_nom']?.toString() ?? filiereId);
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (toutOk) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_estTroncCommun ? 'Appel enregistré pour toutes les filières.' : 'Appel enregistré avec succès.'),
        backgroundColor: _vert,
      ));
      setState(() {
        _students = [];
        _groupeKey = null;
      });
      _chargerDonnees();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Échec pour : ${echecs.join(', ')}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _exporterPdf() async {
    final g = _groupeSelectionne;
    if (g == null) return;
    // En tronc commun, l'export PDF (par filière côté serveur) nécessite
    // d'avoir filtré sur UNE filière précise — pas de PDF combiné.
    dynamic module;
    if (_estTroncCommun) {
      if (_filtreFiliereTronc == 'Toutes les filières') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Sélectionne une filière précise dans le filtre pour exporter (tronc commun).')));
        return;
      }
      module = g.firstWhere((m) => m['filiere_nom']?.toString() == _filtreFiliereTronc, orElse: () => g.first);
    } else {
      module = g.first;
    }
    setState(() => _exporting = true);
    final res = await ProfessorService.telechargerListeEtudiantsPdf(
      int.parse(module['filiere_id'].toString()),
      niveau: module['niveau']?.toString(),
      filiereNom: module['filiere_nom']?.toString(),
    );
    if (!mounted) return;
    setState(() => _exporting = false);
    if (res['success'] == true) {
      final bytes = res['bytes'] as Uint8List;
      await Printing.sharePdf(bytes: bytes, filename: 'liste_${module['filiere_nom'] ?? 'classe'}.pdf');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error']?.toString() ?? 'Échec de l\'export.'), backgroundColor: Colors.red));
    }
  }

  Future<void> _showAppelDetail(dynamic appel) async {
    final modified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AppelDetailSheet(appelId: appel['id'].toString()),
    );
    if (modified == true) {
      _chargerDonnees();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F7FB),
      child: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1380),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopRow(),
                        const SizedBox(height: 22),
                        if (_groupeKey == null) ...[
                          const Text('Appel', style: TextStyle(color: _navyText, fontSize: 24, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          const Text('Choisis un module pour démarrer l\'appel.', style: TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 18),
                          _buildSelecteurModule(),
                          if (_historique.isNotEmpty) ...[
                            const SizedBox(height: 26),
                            _buildHistoriqueStandalone(),
                          ],
                        ] else
                          _buildSession(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTopRow() {
    final photoUrl = widget.profile.photoUrl?.trim();
    final nomComplet = '${widget.profile.prenoms} ${widget.profile.nom}'.trim();
    return Row(children: [
      Expanded(
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
          child: Row(children: [
            const Icon(Icons.search_rounded, size: 19, color: _faint),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Rechercher une classe, un module...', style: TextStyle(color: _faint, fontSize: 13)),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 16),
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _border)),
        child: const Icon(Icons.notifications_none_rounded, color: _navyText, size: 22),
      ),
      const SizedBox(width: 12),
      Row(children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: AppPalette.blue.withValues(alpha: 0.14),
          backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl == null || photoUrl.isEmpty
              ? Text(nomComplet.isNotEmpty ? nomComplet[0].toUpperCase() : 'P', style: const TextStyle(color: AppPalette.blue, fontWeight: FontWeight.w900))
              : null,
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nomComplet.isEmpty ? 'Professeur' : nomComplet, style: const TextStyle(color: _navyText, fontSize: 13.5, fontWeight: FontWeight.w800)),
          Text('Professeur${widget.profile.matricule.isNotEmpty ? " • ${widget.profile.matricule}" : ""}', style: const TextStyle(color: _faint, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ]),
    ]);
  }

  Widget _buildSelecteurModule() {
    final groupes = _groupesModules.entries.toList()
      ..sort((a, b) => (a.value.first['nom'] ?? '').toString().compareTo((b.value.first['nom'] ?? '').toString()));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Mes modules', style: TextStyle(color: _navyText, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (groupes.isEmpty)
          const Text('Aucun module affecté pour l\'instant.', style: TextStyle(color: _faint, fontSize: 12))
        else
          for (final entry in groupes) _moduleRow(entry.key, entry.value),
      ]),
    );
  }

  Widget _moduleRow(String key, List<dynamic> groupe) {
    final tronc = groupe.map((m) => m['filiere_id'].toString()).toSet().length > 1;
    final filieres = groupe.map((m) => m['filiere_nom']?.toString() ?? '').toSet().join(' + ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectionnerGroupe(key),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: AppPalette.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.menu_book_rounded, color: AppPalette.blue, size: 18),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text('${groupe.first['nom'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _navyText, fontSize: 13, fontWeight: FontWeight.w800))),
                    if (tronc) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                        child: const Text('Tronc commun', style: TextStyle(color: Color(0xFF7C3AED), fontSize: 9, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text('$filieres • ${groupe.first['niveau'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _faint, fontSize: 11, fontWeight: FontWeight.w500)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildSession() {
    return LayoutBuilder(builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 980;
      final gauche = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextButton.icon(
          onPressed: () => setState(() { _groupeKey = null; _students = []; }),
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: const Text('Retour aux modules', style: TextStyle(fontWeight: FontWeight.w700)),
          style: TextButton.styleFrom(foregroundColor: AppPalette.blue, padding: EdgeInsets.zero),
        ),
        const SizedBox(height: 10),
        _buildHeaderCard(),
        const SizedBox(height: 16),
        _buildTabsInternes(),
        const SizedBox(height: 14),
        if (_tabInterne == 0) _buildAppelContenu() else _buildHistoriqueDeCetteSession(),
      ]);
      final droite = _buildPanneauDroit();
      if (!desktop) {
        return Column(children: [gauche, const SizedBox(height: 16), droite]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 7, child: gauche),
        const SizedBox(width: 16),
        Expanded(flex: 3, child: droite),
      ]);
    });
  }

  Widget _buildHeaderCard() {
    final g = _groupeSelectionne;
    final now = DateTime.now();
    const jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    const mois = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    final dateLabel = '${jours[now.weekday - 1][0].toUpperCase()}${jours[now.weekday - 1].substring(1)} ${now.day} ${mois[now.month - 1]} ${now.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 10,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppPalette.blue, borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_titreSession, style: const TextStyle(color: _navyText, fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(_sousTitreSession, style: const TextStyle(color: _muted, fontSize: 11.5, fontWeight: FontWeight.w600)),
            ]),
          ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: _faint),
            const SizedBox(width: 6),
            Text(dateLabel, style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
          if (g != null && _estTroncCommun)
            SizedBox(
              width: 240,
              child: _dropdown(_filtreFiliereTronc, ['Toutes les filières', ..._filieresDuGroupe],
                  (v) => setState(() => _filtreFiliereTronc = v!), Icons.filter_alt_outlined),
            ),
        ],
      ),
    );
  }

  Widget _dropdown(String value, List<String> options, ValueChanged<String?> onChanged, IconData icon) {
    final safeValue = options.contains(value) ? value : (options.isNotEmpty ? options.first : value);
    return Container(
      height: 40,
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
      child: PopupMenuButton<String>(
        initialValue: safeValue,
        onSelected: onChanged,
        tooltip: '',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) => options.map((o) => PopupMenuItem<String>(value: o, child: Text(o, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))).toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: AppPalette.blue),
            const SizedBox(width: 6),
            Flexible(child: Text(safeValue, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _navyText, fontSize: 12, fontWeight: FontWeight.w700))),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, color: _faint, size: 16),
          ]),
        ),
      ),
    );
  }

  Widget _buildTabsInternes() {
    return Row(children: [
      _tabBouton('Appel', 0),
      const SizedBox(width: 6),
      _tabBouton('QR code', 2),
    ]);
  }

  Widget _tabBouton(String label, int index) {
    final actif = _tabInterne == index;
    if (index == 2) {
      // Le QR code ouvre un écran dédié, ce n'est pas un onglet interne.
      return OutlinedButton.icon(
        onPressed: () {
          final g = _groupeSelectionne;
          if (g == null) return;
          final module = _estTroncCommun && _filtreFiliereTronc != 'Toutes les filières'
              ? g.firstWhere((m) => m['filiere_nom']?.toString() == _filtreFiliereTronc, orElse: () => g.first)
              : g.first;
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => AppelQrScreen(
              filiereId: int.parse(module['filiere_id'].toString()),
              filiereNom: module['filiere_nom'] ?? '',
              niveau: module['niveau'],
              moduleId: int.parse(module['id'].toString()),
              moduleNom: module['nom'] ?? '',
            ),
          )).then((_) => _chargerDonnees());
        },
        icon: const Icon(Icons.qr_code_2_rounded, size: 16),
        label: const Text('QR code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(foregroundColor: AppPalette.blue, side: const BorderSide(color: AppPalette.blue)),
      );
    }
    return GestureDetector(
      onTap: () => setState(() => _tabInterne = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: actif ? AppPalette.blue : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: actif ? AppPalette.blue : _border),
        ),
        child: Text(label, style: TextStyle(color: actif ? Colors.white : _muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildAppelContenu() {
    if (_loadingStudents) {
      return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Liste des élèves', style: TextStyle(color: _navyText, fontSize: 14.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final wrap = constraints.maxWidth < 760;
          final champ = Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
            child: Row(children: [
              const Icon(Icons.search_rounded, size: 17, color: _faint),
              const SizedBox(width: 6),
              Expanded(child: TextField(
                onChanged: (v) => setState(() => _searchEleve = v),
                decoration: const InputDecoration(hintText: 'Rechercher un élève...', hintStyle: TextStyle(color: _faint, fontSize: 12.5), border: InputBorder.none, isDense: true),
              )),
            ]),
          );
          final boutons = Row(mainAxisSize: MainAxisSize.min, children: [
            _actionRapide('Tout présent', Icons.check_rounded, AppPalette.blue, () => setState(() {
              for (final s in _studentsFiltres) { _statuts[s['matricule']] = 'present'; }
            })),
            const SizedBox(width: 8),
            _actionRapide('Tout absent', Icons.close_rounded, _rouge, () => setState(() {
              for (final s in _studentsFiltres) { _statuts[s['matricule']] = 'absent'; }
            })),
          ]);
          if (wrap) {
            return Column(children: [champ, const SizedBox(height: 10), boutons]);
          }
          return Row(children: [Expanded(child: champ), const SizedBox(width: 10), boutons]);
        }),
        const SizedBox(height: 14),
        if (_studentsFiltres.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: Text('Aucun élève à afficher.', style: TextStyle(color: _faint, fontSize: 12.5))),
          )
        else
          for (var i = 0; i < _studentsFiltres.length; i++)
            _EtudiantPresenceRow(
              numero: i + 1,
              etudiant: _studentsFiltres[i],
              statut: _statuts[_studentsFiltres[i]['matricule']] ?? 'present',
              onChanged: (v) => setState(() => _statuts[_studentsFiltres[i]['matricule']] = v),
            ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save_rounded, size: 18),
            label: Text(_saving ? 'Enregistrement...' : 'Enregistrer l\'appel', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: (_saving || _students.isEmpty) ? null : _enregistrerAppel,
          ),
        ),
      ]),
    );
  }

  Widget _actionRapide(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(side: BorderSide(color: color.withValues(alpha: 0.4)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
    );
  }

  Widget _buildHistoriqueDeCetteSession() {
    final g = _groupeSelectionne;
    if (g == null) return const SizedBox.shrink();
    final moduleIds = g.map((m) => m['id'].toString()).toSet();
    final items = _historique.where((a) => moduleIds.contains(a['module_id']?.toString())).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Historique de ce module', style: TextStyle(color: _navyText, fontSize: 14.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const Text('Aucun appel enregistré pour ce module.', style: TextStyle(color: _faint, fontSize: 12.5))
        else
          for (final a in items) _AppelHistoriqueCard(appel: a, onTap: () => _showAppelDetail(a)),
      ]),
    );
  }

  Widget _buildHistoriqueStandalone() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Historique des appels', style: TextStyle(color: _navyText, fontSize: 14.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
          child: Row(children: [
            const Icon(Icons.search_rounded, size: 17, color: _faint),
            const SizedBox(width: 6),
            Expanded(child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(hintText: 'Rechercher par module, filière, ou date...', hintStyle: TextStyle(color: _faint, fontSize: 12.5), border: InputBorder.none, isDense: true),
            )),
          ]),
        ),
        const SizedBox(height: 10),
        for (final a in _historiqueFiltre) _AppelHistoriqueCard(appel: a, onTap: () => _showAppelDetail(a)),
      ]),
    );
  }

  Widget _buildPanneauDroit() {
    return Column(children: [
      _buildResumeAppel(),
      const SizedBox(height: 14),
      _buildBonASavoir(),
      const SizedBox(height: 14),
      _buildActionsRapides(),
    ]);
  }

  Widget _buildResumeAppel() {
    final counts = _compteStatuts;
    final total = _students.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Résumé de l\'appel', style: TextStyle(color: _navyText, fontSize: 13.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        if (total == 0)
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('En attente des élèves...', style: TextStyle(color: _faint, fontSize: 11.5))))
        else ...[
          Center(
            child: SizedBox(
              width: 130, height: 130,
              child: Stack(alignment: Alignment.center, children: [
                CustomPaint(
                  size: const Size(130, 130),
                  painter: _DonutAppelPainter(valeurs: [counts['present']!, counts['absent']!, counts['retard']!], couleurs: const [_vert, _rouge, _ambre]),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${counts['present']}/$total', style: const TextStyle(color: _navyText, fontSize: 19, fontWeight: FontWeight.w900)),
                  const Text('présents', style: TextStyle(color: _faint, fontSize: 10, fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          _legendeLigne('Présents', counts['present']!, _vert),
          const SizedBox(height: 8),
          _legendeLigne('Absents', counts['absent']!, _rouge),
          const SizedBox(height: 8),
          _legendeLigne('Retards', counts['retard']!, _ambre),
        ],
      ]),
    );
  }

  Widget _legendeLigne(String label, int value, Color color) {
    return Row(children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: const TextStyle(color: _navyText, fontSize: 12, fontWeight: FontWeight.w600))),
      Text('$value', style: const TextStyle(color: _navyText, fontSize: 12.5, fontWeight: FontWeight.w800)),
    ]);
  }

  Widget _buildBonASavoir() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppPalette.lightBlue, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.lightbulb_outline_rounded, color: AppPalette.blue, size: 18),
          SizedBox(width: 7),
          Text('Bon à savoir', style: TextStyle(color: _navyText, fontSize: 13, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 8),
        const Text(
          'Une fois enregistré, l\'appel est ajouté à l\'historique de la classe et les étudiants marqués absents reçoivent une notification.',
          style: TextStyle(color: _muted, fontSize: 11.5, height: 1.4, fontWeight: FontWeight.w500),
        ),
      ]),
    );
  }

  Widget _buildActionsRapides() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Actions rapides', style: TextStyle(color: _navyText, fontSize: 13.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        _actionRapideLigne(Icons.history_rounded, 'Voir l\'historique de ce module', () => setState(() => _tabInterne = 1)),
        _actionRapideLigne(
          _exporting ? Icons.hourglass_top_rounded : Icons.download_rounded,
          _exporting ? 'Export en cours...' : 'Exporter la liste (PDF)',
          _exporting ? null : _exporterPdf,
        ),
      ]),
    );
  }

  Widget _actionRapideLigne(IconData icon, String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          Container(width: 30, height: 30, decoration: BoxDecoration(color: AppPalette.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: AppPalette.blue, size: 15)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: _navyText, fontSize: 12, fontWeight: FontWeight.w700))),
        ]),
      ),
    );
  }
}

// ── Ligne étudiant — vraie photo (photo_url) avec repli sur initiales ──────
class _EtudiantPresenceRow extends StatelessWidget {
  const _EtudiantPresenceRow({required this.numero, required this.etudiant, required this.statut, required this.onChanged});
  final int numero;
  final dynamic etudiant;
  final String statut;
  final ValueChanged<String> onChanged;

  static const _options = [
    {'value': 'present', 'label': 'Présent', 'color': Color(0xFF10B981)},
    {'value': 'absent', 'label': 'Absent', 'color': Color(0xFFEF4444)},
    {'value': 'retard', 'label': 'Retard', 'color': Color(0xFFF59E0B)},
  ];

  @override
  Widget build(BuildContext context) {
    final prenoms = '${etudiant['prenoms'] ?? ''}';
    final photoUrl = etudiant['photo_url']?.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EEF5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(width: 20, child: Text('$numero', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700))),
          const SizedBox(width: 4),
          ClipOval(
            child: (photoUrl != null && photoUrl.isNotEmpty)
                ? Image.network(photoUrl, width: 32, height: 32, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarInitiale(prenoms))
                : _avatarInitiale(prenoms),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$prenoms ${etudiant['nom'] ?? ''}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            Row(children: [
              Text('${etudiant['matricule'] ?? ''}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
              if ((etudiant['_filiereNom'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(width: 6),
                Text('• ${etudiant['_filiereNom']}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
              ],
              if ((etudiant['total_absences'] ?? 0) > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFFECACA))),
                  child: Text('${etudiant['total_absences']} abs.',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                ),
              ],
            ]),
          ])),
        ]),
        const SizedBox(height: 8),
        Row(children: _options.map((o) {
          final isActive = statut == o['value'];
          final color = o['color'] as Color;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o['value'] as String),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: isActive ? color : color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Text(o['label'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isActive ? Colors.white : color)),
              ),
            ),
          );
        }).toList()),
      ]),
    );
  }

  Widget _avatarInitiale(String prenoms) {
    return Container(
      width: 32, height: 32,
      decoration: const BoxDecoration(color: AppPalette.lightBlue, shape: BoxShape.circle),
      child: Center(child: Text(prenoms.isNotEmpty ? prenoms[0] : '?', style: const TextStyle(color: AppPalette.blue, fontWeight: FontWeight.w700, fontSize: 12))),
    );
  }
}

// ── Donut résumé de l'appel ─────────────────────────────────────────────
class _DonutAppelPainter extends CustomPainter {
  const _DonutAppelPainter({required this.valeurs, required this.couleurs});
  final List<int> valeurs;
  final List<Color> couleurs;

  @override
  void paint(Canvas canvas, Size size) {
    final total = valeurs.fold<int>(0, (a, b) => a + b);
    if (total <= 0) return;
    final rect = Offset.zero & size;
    const largeurAnneau = 15.0;
    var angleDepart = -1.5707963267948966; // -pi/2
    for (var i = 0; i < valeurs.length; i++) {
      if (valeurs[i] <= 0) continue;
      final sweep = (valeurs[i] / total) * 6.283185307179586;
      final espace = valeurs.where((v) => v > 0).length > 1 ? 0.035 : 0.0;
      final paint = Paint()
        ..color = couleurs[i % couleurs.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = largeurAnneau;
      canvas.drawArc(rect.deflate(largeurAnneau / 2), angleDepart + espace / 2, (sweep - espace).clamp(0.0, 6.283185307179586), false, paint);
      angleDepart += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutAppelPainter oldDelegate) =>
      oldDelegate.valeurs != valeurs || oldDelegate.couleurs != couleurs;
}

class _AppelHistoriqueCard extends StatelessWidget {
  const _AppelHistoriqueCard({required this.appel, required this.onTap});
  final dynamic appel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = (appel['date_appel'] ?? '').toString().split('T').first;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.fact_check_rounded, color: Color(0xFF0EA5E9), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${appel['module_nom'] ?? ''} · ${appel['filiere_nom'] ?? ''} - ${appel['niveau'] ?? ''}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ])),
          _pill('${appel['nb_presents'] ?? 0}P', const Color(0xFF10B981)),
          const SizedBox(width: 4),
          _pill('${appel['nb_absents'] ?? 0}A', const Color(0xFFEF4444)),
        ]),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _AppelDetailSheet extends StatefulWidget {
  const _AppelDetailSheet({required this.appelId});
  final String appelId;

  @override
  State<_AppelDetailSheet> createState() => _AppelDetailSheetState();
}

class _AppelDetailSheetState extends State<_AppelDetailSheet> {
  bool _loading = true;
  bool _saving = false;
  bool _editMode = false;
  dynamic _appel;
  List<dynamic> _presences = [];

  @override
  void initState() {
    super.initState();
    _chargerDetails();
  }

  Future<void> _chargerDetails() async {
    final res = await ProfessorService.getAppelDetail(widget.appelId);
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        _appel = res['data'];
        _presences = res['data']['presences'] ?? [];
      }
      _loading = false;
    });
  }

  Future<void> _sauvegarder() async {
    setState(() => _saving = true);
    final presences = _presences.map((p) => {'matricule': p['matricule'], 'statut': p['statut']}).toList();
    final res = await ProfessorService.updateAppel(widget.appelId, presences);
    if (!mounted) return;
    setState(() => _saving = false);
    if (res['success'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'] ?? 'Erreur'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Détails de l\'appel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                if (_appel != null) Text('${_appel['module_nom'] ?? ''} - ${_appel['filiere_nom'] ?? ''} (${_appel['niveau'] ?? ''})', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ]),
            ),
            if (!_loading && _presences.isNotEmpty && !_editMode)
              TextButton.icon(onPressed: () => setState(() => _editMode = true), icon: const Icon(Icons.edit_rounded, size: 18), label: const Text('Modifier')),
          ]),
        ),
        const SizedBox(height: 12),
        const Divider(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _presences.isEmpty
                  ? const Center(child: Text('Aucun détail trouvé'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _presences.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final p = _presences[i];
                        if (_editMode) {
                          return _EtudiantPresenceRow(
                            numero: i + 1,
                            etudiant: p,
                            statut: p['statut'] ?? 'present',
                            onChanged: (val) => setState(() => p['statut'] = val),
                          );
                        }
                        final isPresent = p['statut'] == 'present';
                        final isAbs = p['statut'] == 'absent';
                        final color = isPresent ? const Color(0xFF10B981) : (isAbs ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('${p['prenoms']} ${p['nom']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('${p['matricule']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: Text((p['statut'] ?? '').toString().toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        );
                      },
                    ),
        ),
        if (_editMode) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(children: [
              Expanded(child: TextButton(
                onPressed: _saving ? null : () { setState(() => _editMode = false); _chargerDetails(); },
                child: const Text('Annuler'),
              )),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _saving ? null : _sauvegarder,
                  child: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}
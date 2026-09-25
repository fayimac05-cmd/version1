import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../services/professor_service.dart';
import '../theme/app_palette.dart';

// Mêmes constantes que côté admin (admin_notes.dart) — cohérence des
// valeurs enregistrées en base (sessions_notes.semestre / notes.mention).
const List<String> semestresDisponibles = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'S9', 'S10'];

// Correspondance niveau → semestres possibles. Une Licence 2 ne peut avoir
// que S3 ou S4, jamais S1 ni S5 par exemple — évite les erreurs de saisie.
const Map<String, List<String>> semestresParNiveau = {
  'Licence 1': ['S1', 'S2'],
  'Licence 2': ['S3', 'S4'],
  'Licence 3': ['S5', 'S6'],
  'Master 1': ['S7', 'S8'],
  'Master 2': ['S9', 'S10'],
};

List<String> semestresPourNiveau(String? niveau) =>
    semestresParNiveau[niveau] ?? semestresDisponibles;

// ── Appréciation calculée automatiquement à partir de la note /20 — plus de
// choix manuel : la couleur et le libellé suivent directement la valeur,
// comme dans la maquette.
({String label, Color color}) appreciationPourNote(double? note) {
  if (note == null) return (label: '—', color: const Color(0xFF94A3B8));
  if (note >= 17) return (label: 'Très bien', color: const Color(0xFF10B981));
  if (note >= 15) return (label: 'Bien', color: const Color(0xFF10B981));
  if (note >= 13) return (label: 'Assez bien', color: const Color(0xFF0891B2));
  if (note >= 12) return (label: 'Passable', color: const Color(0xFFF59E0B));
  return (label: 'Faible', color: const Color(0xFFEF4444));
}

class NotesTab extends StatefulWidget {
  const NotesTab({super.key, required this.profile, this.initialClasse});

  final StudentProfile profile;

  /// Classe présélectionnée depuis l'onglet "Mes Classes".
  final Map<String, dynamic>? initialClasse;

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  static const Color _navyText = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _faint = Color(0xFF94A3B8);
  static const Color _border = Color(0xFFE5EBF3);

  int _tabInterne = 0; // 0 = Saisie des notes, 1 = Mes sessions

  List<dynamic> _classes = [];
  List<dynamic> _modules = [];
  List<dynamic> _students = [];
  List<dynamic> _sessions = [];
  bool _loading = true;
  bool _loadingStudents = false;
  bool _saving = false;

  // Clé composite "filiereId|niveau" — une filière peut apparaître
  // plusieurs fois dans _classes (une ligne par niveau enseigné par ce
  // prof), donc l'id de filière seul ne suffit pas à identifier la
  // sélection dans le dropdown.
  String? _classeKey;
  String? _classeId;
  String? _classeNom;
  String? _niveau;
  String? _moduleId;

  String? _semestre;
  final _anneeCtrl = TextEditingController(text: '${DateTime.now().year}-${DateTime.now().year + 1}');

  // matricule -> texte brut saisi (permet une note vide ou partielle sans
  // planter le parseur — le calcul se fait via _noteValeur()).
  final Map<String, String> _notes = {};

  double? _noteValeur(String matricule) => double.tryParse((_notes[matricule] ?? '').replaceAll(',', '.'));

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  @override
  void dispose() {
    _anneeCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    final classesResult = await ProfessorService.getClasses();
    final modulesResult = await ProfessorService.getModules();
    final sessionsResult = await ProfessorService.getGradeSessions();
    if (!mounted) return;
    setState(() {
      _classes = classesResult['success'] == true ? classesResult['data'] as List<dynamic> : [];
      // ⚠️ CORRIGÉ — plantage "[DropdownButton]'s value: X ... zero or 2 or
      // more items detected with the same value" : le backend peut renvoyer
      // un même module plusieurs fois (ex. rattaché à plusieurs filières via
      // une jointure), et DropdownButtonFormField exige EXACTEMENT une
      // correspondance par valeur. On déduplique par id juste après réception.
      final rawModules = modulesResult['success'] == true ? modulesResult['data'] as List<dynamic> : [];
      final idsVus = <String>{};
      _modules = rawModules.where((m) => idsVus.add(m['id'].toString())).toList();
      _sessions = sessionsResult['success'] == true ? sessionsResult['data'] as List<dynamic> : [];
      _loading = false;
    });
    _appliquerPreselection();
  }

  bool _preselectionAppliquee = false;

  void _appliquerPreselection() {
    final init = widget.initialClasse;
    if (init == null || _classeId != null || _preselectionAppliquee) return;
    _preselectionAppliquee = true;
    final matches = _classes.where((c) => c['id'].toString() == init['id'].toString());
    if (matches.isEmpty) return;
    final c = matches.first;
    setState(() {
      _tabInterne = 0;
      _classeKey = '${c['id']}|${c['niveau']}';
      _classeId = c['id'].toString();
      _classeNom = c['nom'];
      _niveau = c['niveau'];
    });
    _chargerEtudiants();
  }

  Future<void> _chargerEtudiants() async {
    if (_classeId == null) return;
    setState(() {
      _loadingStudents = true;
      _students = [];
      _notes.clear();
    });
    final result = await ProfessorService.getStudentsByFiliere(int.parse(_classeId!), niveau: _niveau);
    if (!mounted) return;
    setState(() {
      _students = result['success'] == true ? result['data'] as List<dynamic> : [];
      _loadingStudents = false;
    });
  }

  Future<void> _enregistrerSession() async {
    if (_classeId == null || _moduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une classe et un module.')));
      return;
    }
    if (_semestre == null || _anneeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez indiquer le semestre et l\'année académique.')));
      return;
    }
    setState(() => _saving = true);

    final notesData = _students
        .map((s) => {'matricule': s['matricule'], 'valeur': _noteValeur(s['matricule']) ?? 0.0})
        .toList();

    final res = await ProfessorService.createGradeSession({
      'filiere_id': int.parse(_classeId!),
      'filiere_nom': _classeNom,
      'niveau': _niveau,
      'module_id': int.parse(_moduleId!),
      'notes': notesData,
      'semestre': _semestre,
      'annee_academique': _anneeCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _saving = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes saisies avec succès.'), backgroundColor: Color(0xFF10B981)));
      setState(() {
        _students = [];
        _classeKey = null;
        _classeId = null;
        _moduleId = null;
        _semestre = null;
        _tabInterne = 1;
      });
      _chargerDonnees();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error'] ?? 'Erreur lors de la sauvegarde.'), backgroundColor: Colors.red));
    }
  }

  Future<void> _envoyerAAdmin(String sessionId) async {
    final res = await ProfessorService.markSessionSent(sessionId);
    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session transmise à l\'administration.'), backgroundColor: Color(0xFF10B981)));
      _chargerDonnees();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error'] ?? 'Erreur lors de l\'envoi.'), backgroundColor: Colors.red));
    }
  }

  Future<void> _modifierSession(dynamic session) async {
    final detail = await ProfessorService.getSessionDetail(session['id'].toString());
    if (!mounted) return;
    if (detail['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(detail['error'] ?? 'Erreur lors du chargement de la session.'), backgroundColor: Colors.red));
      return;
    }
    final data = detail['data'];
    final notes = (data['notes'] as List<dynamic>? ?? []);

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSessionSheet(session: data, notes: notes),
    );

    if (updated == true) _chargerDonnees();
  }

  // ── Stats en direct de la saisie en cours ──────────────────────────────
  int get _nbAdmis => _students.where((s) => (_noteValeur(s['matricule']) ?? -1) >= 10).length;
  int get _nbEchec => _students.where((s) {
        final v = _noteValeur(s['matricule']);
        return v != null && v < 10;
      }).length;
  int get _nbEnAttente => _students.length - _students.where((s) => _noteValeur(s['matricule']) != null).length;

  Map<String, int> get _repartitionMoyennes {
    final buckets = {'16-20': 0, '12-15': 0, '8-11': 0, '0-7': 0};
    for (final s in _students) {
      final v = _noteValeur(s['matricule']);
      if (v == null) continue;
      if (v >= 16) buckets['16-20'] = buckets['16-20']! + 1;
      else if (v >= 12) buckets['12-15'] = buckets['12-15']! + 1;
      else if (v >= 8) buckets['8-11'] = buckets['8-11']! + 1;
      else buckets['0-7'] = buckets['0-7']! + 1;
    }
    return buckets;
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
                        Row(children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: AppPalette.blue, borderRadius: BorderRadius.circular(13)),
                            child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Saisie des notes', style: TextStyle(color: _navyText, fontSize: 22, fontWeight: FontWeight.w900)),
                            Text('Gérez et suivez les notes de vos étudiants.', style: TextStyle(color: _muted, fontSize: 12.5, fontWeight: FontWeight.w500)),
                          ]),
                        ]),
                        const SizedBox(height: 18),
                        _buildTabsInternes(),
                        const SizedBox(height: 16),
                        if (_tabInterne == 0) _buildSaisieView() else _buildSessionsView(),
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
          child: Row(children: const [
            Icon(Icons.search_rounded, size: 19, color: _faint),
            SizedBox(width: 8),
            Expanded(child: Text('Rechercher un étudiant, une classe, un module...', style: TextStyle(color: _faint, fontSize: 13))),
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

  Widget _buildTabsInternes() {
    return Row(children: [
      _tabBouton('Saisie des notes', 0),
      const SizedBox(width: 8),
      _tabBouton('Mes sessions (${_sessions.length})', 1),
    ]);
  }

  Widget _tabBouton(String label, int index) {
    final actif = _tabInterne == index;
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

  Widget _buildSaisieView() {
    return LayoutBuilder(builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 980;
      final gauche = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _selectionCard(),
        const SizedBox(height: 14),
        if (_loadingStudents) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
        if (!_loadingStudents && _classeId != null && _students.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
              SizedBox(width: 10),
              Expanded(child: Text(
                'Aucun étudiant inscrit dans cette classe/niveau. Vérifiez que les étudiants ont bien une filière et un niveau affectés (Admin → Étudiants).',
                style: TextStyle(fontSize: 12, color: Color(0xFF92400E)))),
            ]),
          ),
        if (!_loadingStudents && _students.isNotEmpty) _buildListeEtudiants(),
      ]);
      if (_classeId == null || _students.isEmpty) return gauche;
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

  Widget _selectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(children: [
        DropdownButtonFormField<String>(
          initialValue: _classeKey,
          hint: const Text('Sélectionner une classe'),
          decoration: InputDecoration(
            labelText: 'Classe / Filière',
            prefixIcon: const Icon(Icons.groups_outlined, color: AppPalette.blue),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: _classes.map<DropdownMenuItem<String>>((c) {
            final key = '${c['id']}|${c['niveau']}';
            return DropdownMenuItem(value: key, child: Text('${c['nom']} — ${c['niveau']}', overflow: TextOverflow.ellipsis));
          }).toList(),
          onChanged: (v) {
            if (v == null) return;
            final parts = v.split('|');
            final c = _classes.firstWhere((x) => '${x['id']}|${x['niveau']}' == v);
            setState(() {
              _classeKey = v;
              _classeId = parts[0];
              _niveau = parts.length > 1 ? parts[1] : null;
              _classeNom = c['nom'];
              if (_semestre != null && !semestresPourNiveau(_niveau).contains(_semestre)) {
                _semestre = null;
              }
            });
            _chargerEtudiants();
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _moduleId,
          hint: const Text('Sélectionner un module'),
          decoration: InputDecoration(
            labelText: 'Module',
            prefixIcon: const Icon(Icons.menu_book_outlined, color: AppPalette.blue),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: _modules.map<DropdownMenuItem<String>>((m) => DropdownMenuItem(
              value: m['id'].toString(), child: Text('${m['nom']}', overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => setState(() => _moduleId = v),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _semestre,
              hint: Text(_niveau == null ? 'Choisir d\'abord une classe' : 'Semestre'),
              decoration: InputDecoration(
                labelText: 'Semestre',
                prefixIcon: const Icon(Icons.calendar_view_week_outlined, color: AppPalette.blue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: semestresPourNiveau(_niveau).map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: _niveau == null ? null : (v) => setState(() => _semestre = v),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _anneeCtrl,
              decoration: InputDecoration(
                labelText: 'Année académique',
                prefixIcon: const Icon(Icons.event_outlined, color: AppPalette.blue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildListeEtudiants() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Liste des étudiants', style: TextStyle(color: _navyText, fontSize: 14.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        for (var i = 0; i < _students.length; i++)
          _NoteRow(
            numero: i + 1,
            etudiant: _students[i],
            initialNote: _notes[_students[i]['matricule']],
            onNoteChanged: (v) => setState(() => _notes[_students[i]['matricule']] = v),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save_rounded),
            label: Text(_saving ? 'Enregistrement...' : 'Enregistrer les notes', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: _saving ? null : _enregistrerSession,
          ),
        ),
      ]),
    );
  }

  Widget _buildPanneauDroit() {
    return Column(children: [
      _buildResume(),
      const SizedBox(height: 14),
      _buildRepartition(),
      const SizedBox(height: 14),
      _buildActionsRapides(),
    ]);
  }

  Widget _buildResume() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Résumé de la saisie', style: TextStyle(color: _navyText, fontSize: 13.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _miniStat('${_students.length}', 'Étudiants', AppPalette.blue, Icons.groups_rounded),
          _miniStat('$_nbAdmis', 'Admis', const Color(0xFF10B981), Icons.check_circle_rounded),
          _miniStat('$_nbEnAttente', 'En attente', const Color(0xFFF59E0B), Icons.hourglass_top_rounded),
          _miniStat('$_nbEchec', 'Échec', const Color(0xFFEF4444), Icons.cancel_rounded),
        ]),
      ]),
    );
  }

  Widget _miniStat(String value, String label, Color color, IconData icon) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  Widget _buildRepartition() {
    final buckets = _repartitionMoyennes;
    final total = _students.length - _nbEnAttente;
    const couleurs = [Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFFB923C), Color(0xFFEF4444)];
    final valeurs = [buckets['16-20']!, buckets['12-15']!, buckets['8-11']!, buckets['0-7']!];
    final labels = ['16 – 20', '12 – 15', '8 – 11', '0 – 7'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Répartition des notes', style: TextStyle(color: _navyText, fontSize: 13.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        if (total == 0)
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('Saisis au moins une note pour voir la répartition.', style: TextStyle(color: _faint, fontSize: 11.5), textAlign: TextAlign.center)))
        else ...[
          Center(
            child: SizedBox(
              width: 120, height: 120,
              child: Stack(alignment: Alignment.center, children: [
                CustomPaint(size: const Size(120, 120), painter: _DonutNotesPainter(valeurs: valeurs, couleurs: couleurs)),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$total', style: const TextStyle(color: _navyText, fontSize: 18, fontWeight: FontWeight.w900)),
                  const Text('notées', style: TextStyle(color: _faint, fontSize: 9.5, fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == labels.length - 1 ? 0 : 7),
              child: Row(children: [
                Container(width: 9, height: 9, decoration: BoxDecoration(color: couleurs[i], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(labels[i], style: const TextStyle(color: _navyText, fontSize: 12, fontWeight: FontWeight.w600))),
                Text('${valeurs[i]}', style: const TextStyle(color: _navyText, fontSize: 12.5, fontWeight: FontWeight.w800)),
              ]),
            ),
        ],
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
        _actionLigne(Icons.add_circle_outline_rounded, 'Nouvelle session (autre classe)', () => setState(() {
          _classeKey = null; _classeId = null; _moduleId = null; _semestre = null; _students = []; _notes.clear();
        })),
        _actionLigne(Icons.fact_check_outlined, 'Voir mes sessions', () => setState(() => _tabInterne = 1)),
      ]),
    );
  }

  Widget _actionLigne(IconData icon, String label, VoidCallback onTap) {
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

  Widget _buildSessionsView() {
    if (_sessions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.fact_check_outlined, size: 56, color: Color(0xFFCBD5E1)),
          SizedBox(height: 12),
          Text('Aucune session de notes', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
        ])),
      );
    }
    return Column(
      children: _sessions.map((s) => _SessionCard(
        session: s,
        onEnvoyer: () => _envoyerAAdmin(s['id'].toString()),
        onModifier: () => _modifierSession(s),
      )).toList(),
    );
  }
}

// ── Ligne étudiant — vraie photo, matricule masqué, note colorée en
// direct, appréciation calculée automatiquement à partir de la valeur.
class _NoteRow extends StatefulWidget {
  const _NoteRow({required this.numero, required this.etudiant, required this.initialNote, required this.onNoteChanged});
  final int numero;
  final dynamic etudiant;
  final String? initialNote;
  final ValueChanged<String> onNoteChanged;

  @override
  State<_NoteRow> createState() => _NoteRowState();
}

class _NoteRowState extends State<_NoteRow> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  double? get _valeur => double.tryParse(_ctrl.text.replaceAll(',', '.'));

  Color get _couleurNote {
    final v = _valeur;
    if (v == null) return const Color(0xFF94A3B8);
    if (v >= 16) return const Color(0xFF10B981);
    if (v >= 12) return const Color(0xFFF59E0B);
    if (v >= 10) return const Color(0xFFFB923C);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.etudiant['photo_url']?.toString();
    final prenoms = '${widget.etudiant['prenoms'] ?? ''}';
    final appreciation = appreciationPourNote(_valeur);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EEF5))),
      child: Row(children: [
        SizedBox(width: 20, child: Text('${widget.numero}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700))),
        const SizedBox(width: 4),
        ClipOval(
          child: (photoUrl != null && photoUrl.isNotEmpty)
              ? Image.network(photoUrl, width: 34, height: 34, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initiale(prenoms))
              : _initiale(prenoms),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text('$prenoms ${widget.etudiant['nom'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 62,
          child: TextField(
            controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            onChanged: (v) { setState(() {}); widget.onNoteChanged(v); },
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _couleurNote),
            decoration: InputDecoration(
              hintText: '/20',
              hintStyle: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
              filled: true,
              fillColor: _couleurNote.withValues(alpha: 0.08),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(color: appreciation.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            alignment: Alignment.center,
            child: Text(appreciation.label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: appreciation.color)),
          ),
        ),
      ]),
    );
  }

  Widget _initiale(String prenoms) => Container(
        width: 34, height: 34,
        decoration: const BoxDecoration(color: AppPalette.lightBlue, shape: BoxShape.circle),
        child: Center(child: Text(prenoms.isNotEmpty ? prenoms[0] : '?', style: const TextStyle(color: AppPalette.blue, fontWeight: FontWeight.w700, fontSize: 12))),
      );
}

// ── Donut de répartition des notes ─────────────────────────────────────
class _DonutNotesPainter extends CustomPainter {
  const _DonutNotesPainter({required this.valeurs, required this.couleurs});
  final List<int> valeurs;
  final List<Color> couleurs;

  @override
  void paint(Canvas canvas, Size size) {
    final total = valeurs.fold<int>(0, (a, b) => a + b);
    if (total <= 0) return;
    final rect = Offset.zero & size;
    const largeurAnneau = 14.0;
    var angleDepart = -1.5707963267948966;
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
  bool shouldRepaint(covariant _DonutNotesPainter oldDelegate) =>
      oldDelegate.valeurs != valeurs || oldDelegate.couleurs != couleurs;
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onEnvoyer, required this.onModifier});
  final dynamic session;
  final VoidCallback onEnvoyer;
  final VoidCallback onModifier;

  @override
  Widget build(BuildContext context) {
    final statut = session['statut'] ?? 'en_attente';
    final isSent = session['is_sent'] == true;
    final motif = session['motif_rejet'];
    final date = (session['date_session'] ?? '').toString().split('T').first;
    final semestre = session['semestre'] as String?;
    final annee = session['annee_academique'] as String?;

    Color statutColor;
    String statutLabel;
    switch (statut) {
      case 'validee':
        statutColor = const Color(0xFF10B981); statutLabel = 'Validée'; break;
      case 'rejetee':
        statutColor = const Color(0xFFEF4444); statutLabel = 'Rejetée par l\'administration'; break;
      default:
        statutColor = const Color(0xFFF59E0B); statutLabel = 'En attente';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5EBF3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${session['module_nom'] ?? ''} · ${session['filiere_nom'] ?? ''} - ${session['niveau'] ?? ''}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 2),
              Text('$date${semestre != null ? " • $semestre" : ""}${annee != null ? " • $annee" : ""}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statutColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(statutLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statutColor)),
          ),
        ]),
        if (statut == 'rejetee' && motif != null && motif.toString().isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.report_problem_outlined, color: Color(0xFFEF4444), size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Motif : $motif', style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)))),
            ]),
          ),
        ],
        const SizedBox(height: 10),
        Row(children: [
          if (statut == 'rejetee')
            Expanded(child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Modifier'),
              style: OutlinedButton.styleFrom(foregroundColor: AppPalette.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: onModifier,
            ))
          else if (!isSent)
            Expanded(child: ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Envoyer à l\'administration'),
              style: ElevatedButton.styleFrom(backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: onEnvoyer,
            ))
          else
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10)),
              child: const Text('Transmise à l\'administration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
            )),
        ]),
      ]),
    );
  }
}

class _EditSessionSheet extends StatefulWidget {
  const _EditSessionSheet({required this.session, required this.notes});
  final dynamic session;
  final List<dynamic> notes;

  @override
  State<_EditSessionSheet> createState() => _EditSessionSheetState();
}

class _EditSessionSheetState extends State<_EditSessionSheet> {
  late Map<String, TextEditingController> _ctrls;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrls = {
      for (final n in widget.notes)
        n['matricule']: TextEditingController(text: '${n['valeur'] ?? ''}')
    };
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _resoumettre() async {
    setState(() => _saving = true);
    final notesData = widget.notes
        .map((n) => {'matricule': n['matricule'], 'valeur': double.tryParse((_ctrls[n['matricule']]?.text ?? '').replaceAll(',', '.')) ?? 0.0})
        .toList();

    final res = await ProfessorService.updateGradeSession(widget.session['id'].toString(), {'notes': notesData});
    if (!mounted) return;
    setState(() => _saving = false);

    if (res['success'] == true) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session corrigée et retransmise pour validation.'), backgroundColor: Color(0xFF10B981)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error'] ?? 'Erreur lors de la mise à jour.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final motif = widget.session['motif_rejet'];
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Modifier les notes — ${widget.session['module_nom'] ?? ''}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            if (motif != null && motif.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                child: Text('Motif du rejet : $motif', style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C))),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        const Divider(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: widget.notes.length,
            itemBuilder: (_, i) {
              final n = widget.notes[i];
              final matricule = n['matricule'];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Expanded(flex: 3, child: Text('${n['prenoms']} ${n['nom']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  SizedBox(width: 70, child: TextField(
                    controller: _ctrls[matricule],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '/20',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  )),
                ]),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            onPressed: _saving ? null : _resoumettre,
            style: ElevatedButton.styleFrom(backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Retransmettre à l\'administration', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          )),
        ),
      ]),
    );
  }
}
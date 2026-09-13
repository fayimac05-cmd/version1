import 'package:flutter/material.dart';
import '../services/professor_service.dart';
import '../theme/app_palette.dart';

// Mêmes constantes que côté admin (admin_notes.dart) — cohérence des
// valeurs enregistrées en base (sessions_notes.semestre / notes.mention).
const List<String> semestresDisponibles = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'S9', 'S10'];
const List<String> mentionsModule = [
  'Très Bien', 'Bien', 'Assez Bien', 'Passable', 'Insuffisant',
];

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

class NotesTab extends StatefulWidget {
  const NotesTab({super.key, this.initialClasse});

  /// Classe présélectionnée depuis l'onglet "Mes Classes".
  final Map<String, dynamic>? initialClasse;

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  int _segment = 0; // 0 = nouvelle session, 1 = mes sessions

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

  // Chaque étudiant a désormais sa PROPRE note ET sa propre mention (tous
  // les étudiants d'une classe n'ont pas la même performance) — plus un
  // seul champ mention global pour toute la session.
  final Map<String, String> _notes = {};
  final Map<String, String?> _mentionsParEtudiant = {};

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
      _modules = modulesResult['success'] == true ? modulesResult['data'] as List<dynamic> : [];
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
      _segment = 0;
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
      _mentionsParEtudiant.clear();
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
        .map((s) => {
              'matricule': s['matricule'],
              'valeur': double.tryParse(_notes[s['matricule']] ?? '') ?? 0.0,
              if (_mentionsParEtudiant[s['matricule']] != null) 'mention': _mentionsParEtudiant[s['matricule']],
            })
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
        _segment = 1;
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

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0A3D91), Color(0xFF1565C0)]),
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        ),
        child: SafeArea(bottom: false, child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Notes & Réclamations', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            Text('${_sessions.length} session(s) de notes', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75))),
            const SizedBox(height: 14),
            _segmentedControl(),
          ]),
        )),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_segment == 0 ? _nouvelleSessionView() : _mesSessionsView()),
      ),
    ]);
  }

  Widget _segmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: _segButton('Saisir les notes', 0)),
        Expanded(child: _segButton('Mes sessions', 1)),
      ]),
    );
  }

  Widget _segButton(String label, int index) {
    final isActive = _segment == index;
    return GestureDetector(
      onTap: () => setState(() => _segment = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: isActive ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: isActive ? const Color(0xFF0A3D91) : Colors.white)),
      ),
    );
  }

  Widget _nouvelleSessionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _selectionCard(),
        if (_loadingStudents) const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
        if (!_loadingStudents && _classeId != null && _students.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 14),
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
        if (!_loadingStudents && _students.isNotEmpty) ...[
          const SizedBox(height: 14),
          ..._students.map((s) => _NoteRow(
                etudiant: s,
                initialNote: _notes[s['matricule']],
                initialMention: _mentionsParEtudiant[s['matricule']],
                onNoteChanged: (v) => _notes[s['matricule']] = v,
                onMentionChanged: (v) => setState(() => _mentionsParEtudiant[s['matricule']] = v),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Enregistrement...' : 'Enregistrer les notes',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _saving ? null : _enregistrerSession,
            ),
          ),
        ],
      ]),
    );
  }

  Widget _selectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
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
          // Une entrée par (filière, niveau) — pas juste par filière, sinon
          // deux niveaux de la même filière partageraient la même valeur.
          items: _classes.map<DropdownMenuItem<String>>((c) {
            final key = '${c['id']}|${c['niveau']}';
            return DropdownMenuItem(
              value: key,
              child: Text('${c['nom']} — ${c['niveau']}', overflow: TextOverflow.ellipsis),
            );
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
              // Le semestre sélectionné peut ne plus être valide pour ce
              // nouveau niveau (ex. S1 choisi puis passage à Licence 2) :
              // on le réinitialise si besoin.
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
              // Restreint aux semestres réels du niveau choisi (ex. Licence 2
              // → S3/S4 uniquement) — évite les erreurs de saisie.
              items: semestresPourNiveau(_niveau)
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
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
        // La mention n'est plus saisie ici globalement : elle se choisit
        // désormais individuellement, ligne par ligne, pour chaque étudiant
        // ci-dessous (voir _NoteRow).
      ]),
    );
  }

  Widget _mesSessionsView() {
    if (_sessions.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.fact_check_outlined, size: 60, color: Color(0xFFCBD5E1)),
        SizedBox(height: 12),
        Text('Aucune session de notes', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sessions.length,
      itemBuilder: (_, i) => _SessionCard(
        session: _sessions[i],
        onEnvoyer: () => _envoyerAAdmin(_sessions[i]['id'].toString()),
        onModifier: () => _modifierSession(_sessions[i]),
      ),
    );
  }
}

class _NoteRow extends StatefulWidget {
  const _NoteRow({
    required this.etudiant,
    required this.initialNote,
    required this.initialMention,
    required this.onNoteChanged,
    required this.onMentionChanged,
  });
  final dynamic etudiant;
  final String? initialNote;
  final String? initialMention;
  final ValueChanged<String> onNoteChanged;
  final ValueChanged<String?> onMentionChanged;

  @override
  State<_NoteRow> createState() => _NoteRowState();
}

class _NoteRowState extends State<_NoteRow> {
  late TextEditingController _ctrl;
  String? _mention;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialNote ?? '');
    _mention = widget.initialMention;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 18, backgroundColor: AppPalette.lightBlue,
              child: Text('${widget.etudiant['prenoms']}'.isNotEmpty ? '${widget.etudiant['prenoms']}'[0] : '?',
                  style: const TextStyle(color: AppPalette.blue, fontWeight: FontWeight.w700, fontSize: 13))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${widget.etudiant['prenoms']} ${widget.etudiant['nom']}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
            // Matricule volontairement masqué côté professeur.
          ])),
          SizedBox(
            width: 70,
            child: TextField(
              controller: _ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                hintText: '/20',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: widget.onNoteChanged,
            ),
          ),
        ]),
        const SizedBox(height: 8),
        // Mention individuelle — facultative, propre à cet étudiant.
        Padding(
          padding: const EdgeInsets.only(left: 46),
          child: DropdownButtonFormField<String>(
            initialValue: _mention,
            isDense: true,
            hint: const Text('Mention (facultatif)', style: TextStyle(fontSize: 12)),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
            items: mentionsModule
                .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12))))
                .toList(),
            onChanged: (v) {
              setState(() => _mention = v);
              widget.onMentionChanged(v);
            },
          ),
        ),
      ]),
    );
  }
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${session['module_nom'] ?? ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text('${session['filiere_nom'] ?? ''} · ${session['niveau'] ?? ''}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 2),
            Text(
              [
                if (semestre != null && semestre.isNotEmpty) semestre,
                if (annee != null && annee.isNotEmpty) annee,
                date,
              ].join(' · '),
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ])),
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
  late Map<String, String?> _mentions;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrls = {
      for (final n in widget.notes)
        n['matricule']: TextEditingController(text: '${n['valeur'] ?? ''}')
    };
    _mentions = {
      for (final n in widget.notes) n['matricule']: n['mention'] as String?,
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
        .map((n) => {
              'matricule': n['matricule'],
              'valeur': double.tryParse(_ctrls[n['matricule']]?.text ?? '') ?? 0.0,
              if (_mentions[n['matricule']] != null) 'mention': _mentions[n['matricule']],
            })
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${n['prenoms']} ${n['nom']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      // Matricule volontairement masqué côté professeur.
                    ])),
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
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _mentions[matricule],
                    isDense: true,
                    hint: const Text('Mention (facultatif)', style: TextStyle(fontSize: 12)),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                    items: mentionsModule
                        .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (v) => setState(() => _mentions[matricule] = v),
                  ),
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

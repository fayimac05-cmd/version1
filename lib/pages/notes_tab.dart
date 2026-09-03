import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';

// ── Modèle : un module avec tous ses devoirs réels ────────────────────────
// Remplace l'ancien modèle TD/Exam inventé : chaque module regroupe le
// nombre réel de devoirs (sessions de notes validées) reçus pour ce module.
// La moyenne du module est la moyenne simple de tous ses devoirs ; la
// moyenne générale est pondérée par le coefficient du module.
//
// TODO(backend) : aucune distinction de type d'évaluation (devoir/examen/
// TP...) n'existe encore en base — quand ce champ sera ajouté à la table
// notes / vue_notes_etudiants, on pourra afficher le type de chaque devoir
// au lieu d'une simple liste de valeurs.
class _NoteModule {
  final String module;
  final String prof;
  final int coefficient;
  final List<double> devoirs;
  final Color color;

  const _NoteModule({
    required this.module,
    required this.prof,
    required this.coefficient,
    required this.devoirs,
    required this.color,
  });

  double? get note {
    if (devoirs.isEmpty) return null;
    return devoirs.reduce((a, b) => a + b) / devoirs.length;
  }

  String get statut => note == null ? 'en_attente' : note! >= 10 ? 'valide' : note! >= 5 ? 'danger' : 'blamable';

  Color get couleurStatut {
    switch (statut) {
      case 'valide':   return const Color(0xFF15803D);
      case 'danger':   return const Color(0xFFD97706);
      case 'blamable': return const Color(0xFFC62828);
      default:         return const Color(0xFF64748B);
    }
  }

  String get labelStatut {
    switch (statut) {
      case 'valide':   return ' Validé';
      case 'danger':   return ' En danger';
      case 'blamable': return ' Blâmable';
      default:         return ' En attente';
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
class NotesTab extends StatefulWidget {
  final bool isSecondaryPage;
  const NotesTab({super.key, this.isSecondaryPage = false});
  @override State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  List<_NoteModule> _notes = [];
  bool _loading = true;
  bool _erreur = false;

  static const _colors = [
    AppPalette.blue, Color(0xFF7C3AED), Color(0xFF0891B2),
    Color(0xFF15803D), Color(0xFFD97706), Color(0xFFE11D48),
    Color(0xFF0369A1),
  ];

  int get _nbValides  => _notes.where((n) => n.statut == 'valide').length;
  int get _nbDanger   => _notes.where((n) => n.statut == 'danger').length;
  int get _nbBlamable => _notes.where((n) => n.statut == 'blamable').length;
  int get _nbAttente  => _notes.where((n) => n.statut == 'en_attente').length;

  // ⚠️ IMPORTANT : la moyenne générale n'est PAS affichée automatiquement.
  // Même si l'étudiant voit toutes ses notes de modules (publiées une à
  // une par l'administration), la moyenne générale est une publication
  // séparée et distincte (le futur "Bulletin"). Tant que ce mécanisme de
  // publication n'existe pas, on ne calcule ni n'affiche aucune moyenne
  // générale ici — pour ne pas montrer une donnée que l'admin n'a pas
  // encore choisi de publier.

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _fetchNotesBackend();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  /// Charge les notes réelles de l'étudiant connecté via le backend
  /// (ApiService.getMesNotes) — plus aucun accès direct à Supabase. La
  /// table `etudiants` a RLS activé sans politique, bloquant en silence
  /// toute lecture directe avec la clé publique (découvert le 03/09).
  /// Le backend scope déjà par le JWT (req.user.id) — chaque étudiant ne
  /// reçoit que ses propres notes, sessions validées uniquement.
  Future<void> _fetchNotesBackend() async {
    try {
      final result = await ApiService.getMesNotes();
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Erreur');
      }

      final list = List<Map<String, dynamic>>.from(result['data'] as List);

      // Regroupement par module : chaque ligne = un devoir réel.
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final n in list) {
        final mod = n['module_nom'] as String? ?? 'Module';
        grouped.putIfAbsent(mod, () => []).add(n);
      }

      final modules = grouped.entries.toList();
      if (!mounted) return;
      setState(() {
        _notes = List.generate(modules.length, (i) {
          final rows = modules[i].value;
          final devoirs = rows
              .map((r) => (r['note'] as num?)?.toDouble())
              .whereType<double>()
              .toList();
          final coef = (rows.first['coefficient'] as num?)?.toInt() ?? 1;
          final profNom = (rows.first['prof_nom'] as String? ?? '').trim();
          final profPrenoms = (rows.first['prof_prenoms'] as String? ?? '').trim();
          final prof = [profPrenoms, profNom].where((s) => s.isNotEmpty).join(' ');
          return _NoteModule(
            module: modules[i].key,
            prof: prof.isNotEmpty ? prof : 'Professeur non renseigné',
            coefficient: coef,
            devoirs: devoirs,
            color: _colors[i % _colors.length],
          );
        });
        _loading = false;
        _erreur = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notes = [];
        _loading = false;
        _erreur = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(children: [

      // ── Header gradient bleu ──────────────────────────────────────
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0A3D91), Color(0xFF1565C0)]),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Stack(children: [
          Positioned(top: -20, right: -20,
            child: Container(width: 100, height: 100,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06)))),
          Positioned(bottom: 0, right: 70,
            child: Container(width: 50, height: 50,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppPalette.yellow.withValues(alpha: 0.12)))),
          Column(children: [

           Row(children: [
            if (widget.isSecondaryPage) ...[
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
            ],
            Container(width: 32, height: 32,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.grade_rounded, color: Colors.white, size: 18)),
            const SizedBox(width: 8),
            const Expanded(child: Text('Mes Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                color: Colors.white, letterSpacing: -0.3))),
            // Le bouton "Contester la moyenne" est retiré : tant que la
            // moyenne générale n'est pas un concept publié par l'admin
            // (futur Bulletin), il n'y a rien de fiable à contester ici.
          ]),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha:0.15)),
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.lock_outline_rounded, color: Colors.white.withValues(alpha: 0.85), size: 14),
                    const SizedBox(width: 5),
                    const Expanded(
                      child: Text('Moyenne générale — pas encore publiée',
                          style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  const Text('Disponible dans ton Bulletin une fois publié par l\'administration.',
                      style: TextStyle(fontSize: 9.5, color: Colors.white54)),
                ]),
              ),
              Container(width: 1, height: 32, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 12)),
              Expanded(child: Row(children: [
                _stat('$_nbValides',  'Validés',  const Color(0xFF86EFAC)),
                _div(), _stat('$_nbDanger',   'Danger',   const Color(0xFFFDE68A)),
                _div(), _stat('$_nbBlamable', 'Blâmables',const Color(0xFFFCA5A5)),
                _div(), _stat('$_nbAttente',  'Attente',  Colors.white54),
              ])),
            ]),
          ),

          const SizedBox(height: 2),

          TabBar(controller: _tabCtrl,
            indicatorColor: AppPalette.yellow,
            indicatorWeight: 2,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: const [Tab(text: 'Toutes les notes'), Tab(text: 'Par statut')],
          ),
        ]),
        ]),
      ),

      // ── Contenu ────────────────────────────────────────────────────
      Expanded(
        child: _erreur
            ? _etatErreur()
            : _notes.isEmpty
                ? _etatVide()
                : TabBarView(controller: _tabCtrl, children: [
                    _ListeNotes(notes: _notes, onReclamer: _ouvrirReclamation),
                    _NotesParStatut(notes: _notes, onReclamer: _ouvrirReclamation),
                  ]),
      ),
    ]);
  }

  Widget _etatVide() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72,
          decoration: BoxDecoration(color: AppPalette.lightBlue, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.grade_outlined, color: AppPalette.blue, size: 34)),
        const SizedBox(height: 18),
        const Text('Aucune note publiée pour l\'instant',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        const Text('Dès que l\'administration validera et publiera tes notes, elles apparaîtront ici.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5)),
      ]),
    ),
  );

  Widget _etatErreur() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 32),
        const SizedBox(height: 12),
        const Text('Impossible de charger tes notes pour le moment.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () { setState(() => _loading = true); _fetchNotesBackend(); },
          child: const Text('Réessayer'),
        ),
      ]),
    ),
  );

  void _ouvrirReclamation(_NoteModule note) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _ReclamationNoteSheet(note: note),
  );

  Widget _stat(String val, String label, Color color) => Expanded(child: Column(children: [
    Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: const TextStyle(fontSize: 8, color: Colors.white60), maxLines: 1, overflow: TextOverflow.ellipsis),
  ]));

  Widget _div() => Container(width: 1, height: 16, color: Colors.white24);
}

// ── Liste toutes notes ──────────────────────────────────────────────────────
class _ListeNotes extends StatelessWidget {
  final List<_NoteModule> notes;
  final void Function(_NoteModule) onReclamer;
  const _ListeNotes({required this.notes, required this.onReclamer});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
    itemCount: notes.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (_, i) => _NoteCard(note: notes[i], onReclamer: onReclamer),
  );
}

// ── Notes par statut ────────────────────────────────────────────────────────
class _NotesParStatut extends StatelessWidget {
  final List<_NoteModule> notes;
  final void Function(_NoteModule) onReclamer;
  const _NotesParStatut({required this.notes, required this.onReclamer});

  @override
  Widget build(BuildContext context) {
    final groupes = [
      {'label': '🚨 Blâmables',  'statut': 'blamable',   'bg': Color(0xFFFFEBEE), 'border': Color(0xFFEF9A9A)},
      {'label': '⚠️ En danger',  'statut': 'danger',     'bg': Color(0xFFFFFBEB), 'border': Color(0xFFFDE68A)},
      {'label': '✅ Validés',    'statut': 'valide',     'bg': Color(0xFFF0FDF4), 'border': Color(0xFF86EFAC)},
      {'label': '⏳ En attente', 'statut': 'en_attente', 'bg': Color(0xFFF8FAFC), 'border': Color(0xFFE2E8F0)},
    ];
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: groupes.map((g) {
      final filtered = notes.where((n) => n.statut == g['statut']).toList();
      if (filtered.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: g['bg'] as Color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: g['border'] as Color)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 10), child: Row(children: [
            Text(g['label'] as String, style: const TextStyle(fontSize: 15,
                fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: (g['border'] as Color).withValues(alpha:0.3),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${filtered.length}', style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
          ])),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          ...filtered.map((n) => _NoteCard(note: n, onReclamer: onReclamer, compact: true)),
        ]),
      );
    }).toList());
  }
}

// ── Carte note ──────────────────────────────────────────────────────────────
class _NoteCard extends StatelessWidget {
  final _NoteModule note;
  final void Function(_NoteModule) onReclamer;
  final bool compact;
  const _NoteCard({required this.note, required this.onReclamer, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final sc = note.couleurStatut;
    String cleanStatus = note.labelStatut.replaceAll(RegExp(r'[^a-zA-Zéèêà ]'), '').trim();

    return Container(
      margin: compact ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6) : EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      decoration: compact ? null : BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: note.statut == 'blamable' ? const Color(0xFFEF9A9A) : const Color(0xFFE2E8F0),
            width: note.statut == 'blamable' ? 1.5 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  note.module,
                  style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: sc.withValues(alpha:0.12), borderRadius: BorderRadius.circular(12)),
                child: Text(cleanStatus, style: TextStyle(color: sc, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(note.prof, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildScoreBox('Coefficient', note.coefficient, false),
              const SizedBox(width: 8),
              _buildScoreBox('Devoirs', note.devoirs.length, false),
              const SizedBox(width: 8),
              _buildScoreBox('Moyenne', note.note, true),
            ],
          ),
          if (note.devoirs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: note.devoirs.map((d) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(d.toStringAsFixed(1), style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              )).toList(),
            ),
          ],
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => onReclamer(note),
            child: const Align(
              alignment: Alignment.centerRight,
              child: Text('Contester cette note',
                  style: TextStyle(fontSize: 12, color: AppPalette.blue, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBox(String label, dynamic value, bool isMoyenne) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isMoyenne ? const Color(0xFFF0FDF4) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isMoyenne ? const Color(0xFF15803D) : const Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value != null ? (value is double ? value.toStringAsFixed(2) : value.toString()) : '—',
              style: TextStyle(
                color: isMoyenne ? const Color(0xFF15803D) : const Color(0xFF111827),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Réclamation note (UI seule — pas encore connectée au backend, voir note) ─
// TODO(backend) : aucun endpoint de réclamation n'a été fourni/trouvé côté
// ApiService. Le bouton "Envoyer" simule actuellement un délai réseau sans
// appel réel. À connecter dès qu'un endpoint (ex. ApiService.creerReclamation)
// existera côté backend.
class _ReclamationNoteSheet extends StatefulWidget {
  final _NoteModule note;
  const _ReclamationNoteSheet({required this.note});
  @override State<_ReclamationNoteSheet> createState() => _ReclamationNoteSheetState();
}

class _ReclamationNoteSheetState extends State<_ReclamationNoteSheet> {
  String? _typeNote;
  final _partiesCtrl = TextEditingController();
  final _justifCtrl  = TextEditingController();
  bool _loading = false, _envoye = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final _types = ['Devoir sur table','Travaux Pratiques (TP)','Examen partiel','Examen final'];

  @override void dispose() { _partiesCtrl.dispose(); _justifCtrl.dispose(); super.dispose(); }

  Future<void> _pickImageSource() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Ajouter une pièce jointe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFFF0FDF4), shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Color(0xFF15803D)),
              ),
              title: const Text('Prendre une photo'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                child: const Icon(Icons.photo_library, color: AppPalette.blue),
              ),
              title: const Text('Choisir depuis la galerie'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
            ),
            const SizedBox(height: 10),
          ]
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erreur lors de la sélection de l\'image'),
          backgroundColor: Color(0xFFC62828),
        ));
      }
    }
  }

  Future<void> _envoyer() async {
    if (_typeNote == null || _partiesCtrl.text.isEmpty || _justifCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires.'),
          backgroundColor: Color(0xFFC62828)));
      return;
    }
    setState(() => _loading = true);
    // TODO(backend) : remplacer par un vrai appel ApiService une fois
    // l'endpoint de réclamation disponible.
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() { _loading = false; _envoye = true; });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
        child: _envoye ? _confirmation() : SingleChildScrollView(padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Réclamation de note', style: TextStyle(fontSize: 20,
                fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.3)),
            const SizedBox(height: 6),
            const Text('Votre réclamation sera transmise à l\'administration.',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4)),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppPalette.blue.withValues(alpha:0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppPalette.blue.withValues(alpha:0.2))),
              child: Column(children: [
                _infoLigne('Module',     widget.note.module),
                const SizedBox(height: 8),
                _infoLigne('Professeur', widget.note.prof),
                const SizedBox(height: 8),
                _infoLigne('Moyenne', widget.note.note != null ? '${widget.note.note!.toStringAsFixed(1)} / 20 — ${widget.note.labelStatut}' : 'Non disponible'),
              ]),
            ),
            const SizedBox(height: 20),
            _lbl('Type de note *'),
            Wrap(spacing: 8, runSpacing: 8, children: _types.map((t) {
              final sel = _typeNote == t;
              return GestureDetector(onTap: () => setState(() => _typeNote = t),
                child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppPalette.blue : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? AppPalette.blue : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : const Color(0xFF0F172A)))),
              );
            }).toList()),
            const SizedBox(height: 18),
            _lbl('Parties contestées *'),
            _champ(_partiesCtrl, 'Ex: Question 3 et 4, exercice 2...', maxLines: 2),
            const SizedBox(height: 18),
            _lbl('Justification *'),
            _champ(_justifCtrl, 'Pourquoi pensez-vous que la note est incorrecte ?', maxLines: 3),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _pickImageSource,
              child: Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(children: [
                  _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_imageFile!, width: 40, height: 40, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.attach_file, color: Color(0xFF64748B), size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_imageFile != null ? 'Image sélectionnée' : 'Pièce jointe (optionnel)', style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(_imageFile != null ? 'Appuyez pour modifier' : 'Photo de votre copie', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ])),
                  if (_imageFile != null)
                    GestureDetector(
                      onTap: () => setState(() => _imageFile = null),
                      child: const Icon(Icons.close, color: Color(0xFFC62828), size: 20),
                    )
                  else
                    const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 20),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            _fluxProcessus(),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 54,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _envoyer,
                icon: _loading ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Icon(Icons.send_rounded, size: 20),
                label: Text(_loading ? 'Envoi en cours...' : 'Envoyer la réclamation',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppPalette.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0, disabledBackgroundColor: const Color(0xFFE2E8F0)),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget _infoLigne(String lbl, String val) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 90, child: Text(lbl, style: const TextStyle(fontSize: 12,
        color: Color(0xFF64748B), fontWeight: FontWeight.w500))),
    Expanded(child: Text(val, style: const TextStyle(fontSize: 13,
        color: Color(0xFF0F172A), fontWeight: FontWeight.w600))),
  ]);

  Widget _confirmation() => Padding(padding: const EdgeInsets.all(40),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 72, height: 72,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1DB954)),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 40)),
      const SizedBox(height: 20),
      const Text('Réclamation envoyée !', style: TextStyle(fontSize: 20,
          fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      const SizedBox(height: 10),
      const Text('Votre réclamation a été transmise à l\'administration.\nVous serez notifié de la réponse.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 15,
              color: Color(0xFF64748B), height: 1.55)),
    ]),
  );
}

// ── Helpers ──────────────────────────────────────────────────────────────────
Widget _lbl(String text) => Padding(padding: const EdgeInsets.only(bottom: 10),
  child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
      color: Color(0xFF0F172A))));

Widget _champ(TextEditingController ctrl, String hint, {int maxLines = 1}) =>
    Container(
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: TextField(controller: ctrl, maxLines: maxLines,
        style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
        decoration: InputDecoration(hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            border: InputBorder.none, contentPadding: const EdgeInsets.all(14))),
    );

Widget _fluxProcessus() {
  final steps = [
    'Vous soumettez la réclamation',
    'L\'administration reçoit et examine',
    'Transmise au professeur concerné',
    'Le professeur répond via l\'app',
    'Vous recevez une notification',
  ];
  return Container(padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Processus de traitement', style: TextStyle(fontSize: 13,
          fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      const SizedBox(height: 10),
      ...steps.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 7),
        child: Row(children: [
          Container(width: 22, height: 22, decoration: const BoxDecoration(
              color: AppPalette.blue, shape: BoxShape.circle),
              child: Center(child: Text('${e.key + 1}', style: const TextStyle(fontSize: 11,
                  fontWeight: FontWeight.bold, color: Colors.white)))),
          const SizedBox(width: 10),
          Text(e.value, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
        ]),
      )),
    ]),
  );
}

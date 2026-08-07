import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';

// ── Modèle note ──────────────────────────────────────────────────────────────
class _NoteModule {
  final String module, code, prof;
  final double? td, exam;
  final double coefTd, coefExam;
  final int coefficient;
  final Color color;

  const _NoteModule({
    required this.module, 
    required this.code, 
    required this.prof,
    this.td, 
    this.exam, 
    this.coefTd = 1.0, 
    this.coefExam = 2.0, 
    required this.coefficient, 
    required this.color
  });

  double? get note {
    if (td != null && exam != null) {
      return (td! * coefTd + exam! * coefExam) / (coefTd + coefExam);
    } else if (exam != null) {
      return exam;
    } else if (td != null) {
      return td;
    }
    return null;
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

  String get effetIA {
    switch (statut) {
      case 'valide':   return 'Chat IA vous félicite !';
      case 'danger':   return 'Chat IA propose un plan de révision.';
      case 'blamable': return 'Alerte envoyée — Chat IA intervient.';
      default:         return 'Note pas encore disponible.';
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
  bool _fromBackend = false;

  // Couleurs par index pour les modules backend
  static const _colors = [
    AppPalette.blue, Color(0xFF7C3AED), Color(0xFF0891B2),
    Color(0xFF15803D), Color(0xFFD97706), Color(0xFFE11D48),
    Color(0xFF0369A1),
  ];

  double get _moyenne {
    final notees = _notes.where((n) => n.note != null).toList();
    if (notees.isEmpty) return 0;
    final pts = notees.fold(0.0, (s, n) => s + n.note! * n.coefficient);
    final cff = notees.fold(0,   (s, n) => s + n.coefficient);
    return cff == 0 ? 0 : pts / cff;
  }

  int get _nbValides  => _notes.where((n) => n.statut == 'valide').length;
  int get _nbDanger   => _notes.where((n) => n.statut == 'danger').length;
  int get _nbBlamable => _notes.where((n) => n.statut == 'blamable').length;
  int get _nbAttente  => _notes.where((n) => n.statut == 'en_attente').length;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _fetchNotesBackend();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _fetchNotesBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/notes/etudiant'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'] ?? [];

        if (list.isNotEmpty) {
          // Grouper par module_nom et calculer la note moyenne
          final Map<String, List<double>> grouped = {};
          final Map<String, String> typeMap = {};
          for (final n in list) {
            final mod = n['module_nom'] as String? ?? 'Module';
            final note = (n['note'] as num?)?.toDouble();
            final type = n['type_eval'] as String? ?? 'DS';
            if (note != null) {
              grouped.putIfAbsent(mod, () => []).add(note);
              typeMap[mod] = type;
            }
          }

          final modules = grouped.entries.toList();
          setState(() {
            _notes = List.generate(modules.length, (i) {
              final entry = modules[i];
              final notes = entry.value;
              final avg = notes.reduce((a, b) => a + b) / notes.length;
              final type = typeMap[entry.key] ?? 'DS';
              return _NoteModule(
                module: entry.key,
                code: 'MOD${(i + 1).toString().padLeft(3, '0')}',
                prof: 'Professeur assigné',
                td: type == 'TP' || type == 'Contrôle Continu' ? avg : null,
                exam: type == 'DS' || type == 'Examen Final' ? avg : avg,
                coefTd: 1, coefExam: 2, coefficient: 3,
                color: _colors[i % _colors.length],
              );
            });
            _loading = false;
            _fromBackend = true;
          });
          return;
        }
      }
    } catch (_) {}

    // Fallback : données de démonstration
    setState(() {
      _notes = [
        _NoteModule(module: 'Algorithmique & Structures', code: 'INFO101',
            prof: 'Prof Ouédraogo', td: 14.0, exam: 16.0, coefTd: 1, coefExam: 2, coefficient: 3, color: AppPalette.blue),
        _NoteModule(module: 'Bases de Données', code: 'INFO102',
            prof: 'Prof Traoré', td: 12.0, exam: 14.0, coefTd: 1, coefExam: 2, coefficient: 3, color: const Color(0xFF7C3AED)),
        _NoteModule(module: 'Réseaux informatiques', code: 'INFO103',
            prof: 'Prof Sawadogo', td: 5.0, exam: 4.0, coefTd: 1, coefExam: 2, coefficient: 2, color: const Color(0xFF0891B2)),
        _NoteModule(module: 'Maths Discrètes', code: 'MATH201',
            prof: 'Prof Kaboré', td: 11.0, exam: 13.0, coefTd: 1, coefExam: 2, coefficient: 2, color: const Color(0xFF15803D)),
        _NoteModule(module: 'Anglais Technique', code: 'ANG101',
            prof: 'Prof Johnson', td: 16.0, exam: 17.0, coefTd: 1, coefExam: 2, coefficient: 1, color: const Color(0xFFD97706)),
        _NoteModule(module: 'Programmation OO', code: 'INFO104',
            prof: 'Prof Ouédraogo', td: 10.0, exam: 9.0, coefTd: 1, coefExam: 2, coefficient: 3, color: AppPalette.blue),
        _NoteModule(module: 'Systèmes d\'exploitation', code: 'INFO105',
            prof: 'Prof Traoré', td: null, exam: null, coefTd: 1, coefExam: 2, coefficient: 2, color: const Color(0xFF7C3AED)),
      ];
      _loading = false;
      _fromBackend = false;
    });
  }

  bool _isDownloading = false;

  Future<void> _telechargerBulletin() async {
    setState(() => _isDownloading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final etudiantId = prefs.getString('user_id') ?? '1';
      final url = Uri.parse('${ApiService.baseUrl}/notes/bulletin/$etudiantId');
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final Uint8List pdfBytes = response.bodyBytes;
        await Printing.layoutPdf(
          onLayout: (_) => pdfBytes,
          name: 'Bulletin_Semestre_3.pdf',
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur serveur: impossible de générer le bulletin.'),
            backgroundColor: const Color(0xFFC62828),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur de connexion au serveur API.'),
          backgroundColor: const Color(0xFFC62828),
        ));
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
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
          // Bulles décoratives
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
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Mes Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                  color: Colors.white, letterSpacing: -0.3)),
              const Text('Semestre 3 — 2024/2025',
                  style: TextStyle(fontSize: 11, color: Colors.white70)),
              if (!_fromBackend)
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppPalette.yellow.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Données de démonstration',
                      style: TextStyle(fontSize: 9, color: AppPalette.yellow, fontWeight: FontWeight.w700)),
                ),
            ])),
            if (_isDownloading)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              )
            else
              GestureDetector(
                onTap: _telechargerBulletin,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha:0.25))),
                  child: const Row(children: [
                    Icon(Icons.picture_as_pdf, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text('Bulletin', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            GestureDetector(
              onTap: () => showModalBottomSheet(context: context,
                  isScrollControlled: true, backgroundColor: Colors.transparent,
                  builder: (_) => _ReclamationMoyenneSheet(notes: _notes, moyenne: _moyenne)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha:0.25))),
                child: const Text('Contester', style: TextStyle(fontSize: 11,
                    color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),

          const SizedBox(height: 8),

          // Moyenne + stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha:0.15)),
            ),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                  Text(_moyenne.toStringAsFixed(2), style: const TextStyle(fontSize: 26,
                      fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1)),
                  const Text(' / 20', style: TextStyle(fontSize: 12, color: Colors.white70)),
                ]),
                const Text('Moyenne générale',
                    style: TextStyle(fontSize: 10, color: Colors.white70)),
              ]),
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
        ]),  // closes Stack children
      ),

      // ── Contenu ────────────────────────────────────────────────────
      Expanded(child: TabBarView(controller: _tabCtrl, children: [
        _ListeNotes(notes: _notes, onReclamer: _ouvrirReclamation),
        _NotesParStatut(notes: _notes, onReclamer: _ouvrirReclamation),
      ])),
    ]);
  }

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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sc.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  cleanStatus,
                  style: TextStyle(
                    color: sc,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note.module,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildScoreBox('Coefficient', note.coefficient, false),
              const SizedBox(width: 8),
              _buildScoreBox('TD', note.td, false),
              const SizedBox(width: 8),
              _buildScoreBox('Exam', note.exam, false),
              const SizedBox(width: 8),
              _buildScoreBox('Moy.', note.note, true),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Semestre 3',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
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

// ── Réclamation note ────────────────────────────────────────────────────────
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
                _infoLigne('Note reçue', widget.note.note != null ? '${widget.note.note!.toStringAsFixed(1)} / 20 — ${widget.note.labelStatut}' : 'Non disponible'),
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

// ── Réclamation moyenne ──────────────────────────────────────────────────────
class _ReclamationMoyenneSheet extends StatefulWidget {
  final List<_NoteModule> notes;
  final double moyenne;
  const _ReclamationMoyenneSheet({required this.notes, required this.moyenne});
  @override State<_ReclamationMoyenneSheet> createState() => _ReclamationMoyenneSheetState();
}

class _ReclamationMoyenneSheetState extends State<_ReclamationMoyenneSheet> {
  final Set<String> _modulesContestes = {};
  final _justifCtrl = TextEditingController();
  bool _loading = false, _envoye = false;

  @override void dispose() { _justifCtrl.dispose(); super.dispose(); }

  Future<void> _envoyer() async {
    if (_modulesContestes.isEmpty || _justifCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sélectionnez au moins un module et ajoutez une justification.'),
          backgroundColor: Color(0xFFC62828)));
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() { _loading = false; _envoye = true; });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final notees = widget.notes.where((n) => n.note != null).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
        child: _envoye
            ? Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 72, height: 72, decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFF1DB954)),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 40)),
                const SizedBox(height: 20),
                const Text('Réclamation envoyée !', style: TextStyle(fontSize: 20,
                    fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                const Text('Votre contestation de moyenne a été transmise à l\'administration.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 15,
                        color: Color(0xFF64748B), height: 1.55)),
              ]))
            : SingleChildScrollView(padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  const Text('Contester ma moyenne', style: TextStyle(fontSize: 20,
                      fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.3)),
                  const SizedBox(height: 6),
                  const Text('Envoyée UNIQUEMENT à l\'administration.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4)),
                  const SizedBox(height: 20),
                  Container(padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppPalette.lightBlue,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppPalette.blue.withValues(alpha:0.2))),
                    child: Row(children: [
                      const Icon(Icons.info_outline, color: AppPalette.blue, size: 20),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Semestre 3 — 2024/2025',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text('Moyenne actuelle : ${widget.moyenne.toStringAsFixed(2)} / 20',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                                color: AppPalette.blue)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  _lbl('Modules contestés *'),
                  ...notees.map((n) {
                    final sel = _modulesContestes.contains(n.module);
                    return GestureDetector(
                      onTap: () => setState(() => sel
                          ? _modulesContestes.remove(n.module)
                          : _modulesContestes.add(n.module)),
                      child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: sel ? AppPalette.lightBlue : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sel ? AppPalette.blue : const Color(0xFFE2E8F0),
                              width: sel ? 1.5 : 1),
                        ),
                        child: Row(children: [
                          Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle,
                              color: sel ? AppPalette.blue : Colors.white,
                              border: Border.all(color: sel ? AppPalette.blue : const Color(0xFFE2E8F0), width: 1.5)),
                              child: sel ? const Icon(Icons.check, size: 14, color: Colors.white) : null),
                          const SizedBox(width: 12),
                          Expanded(child: Text(n.module, style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sel ? AppPalette.blue : const Color(0xFF0F172A)))),
                          Text('${n.note!.toStringAsFixed(1)} / 20',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                                  color: n.couleurStatut)),
                        ]),
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                  _lbl('Justification *'),
                  _champ(_justifCtrl, 'Pourquoi contestez-vous cette moyenne ?', maxLines: 3),
                  const SizedBox(height: 20),
                  Container(padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A))),
                    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 10),
                      Expanded(child: Text(
                        'Cette réclamation est envoyée UNIQUEMENT à l\'administration. '
                        'Elle ne sera pas transmise aux professeurs.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF0F172A), height: 1.5),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(width: double.infinity, height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _envoyer,
                      icon: _loading ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Icon(Icons.send_rounded, size: 20),
                      label: Text(_loading ? 'Envoi en cours...' : 'Envoyer la contestation',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppPalette.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0),
                    ),
                  ),
                  const SizedBox(height: 8),
                ]),
            ),
      ),
    );
  }
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

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_profile.dart';

class PlanningTab extends StatefulWidget {
  const PlanningTab({super.key, required this.profile});
  final StudentProfile profile;

  @override
  State<PlanningTab> createState() => _PlanningTabState();
}

class _PlanningTabState extends State<PlanningTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _bgGlobal = Color(0xFFF8FAFC);
  static const Color _textMain = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _brandBlue = Color(0xFF1E40AF);
  static const Color _jaune = Color(0xFFF59E0B);
  static const Color _jauneFond = Color(0xFFFFF7E6);

  final List<String> _joursSemaine = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'
  ];

  // ── Programme actif (table edt, archive = false) ─────────────────────────
  bool _loadingProgramme = true;
  Map<String, dynamic>? _edtActif;
  List<Map<String, dynamic>> _creneaux = [];

  // ── Historique (table edt, archive = true) ────────────────────────────────
  bool _loadingHistorique = true;
  List<Map<String, dynamic>> _historique = [];

  // ── Dates importantes (table calendrier, inchangé) ───────────────────────
  List<Map<String, dynamic>> _eventsCalendrier = [
    {'titre': 'Rentrée académique 2024-2025', 'date': '15 septembre 2024', 'description': 'Début officiel de l\'année.', 'type': 'Académique'},
    {'titre': 'Début des examens S3', 'date': '04 Nov. → 15 Nov. 2024', 'description': 'Examens écrits de fin de semestre.', 'type': 'Examens'},
    {'titre': 'Délibérations S3', 'date': '25 novembre 2024', 'description': 'Publication des résultats du S3.', 'type': 'Résultats'},
    {'titre': 'Vacances académiques', 'date': '23 Déc. 2024 → 05 Jan. 2025', 'description': 'Vacances de fin d\'année.', 'type': 'Vacances'},
    {'titre': 'Inscriptions pédagogiques S4', 'date': 'Avant le 05 Mai 2026', 'description': 'Régularisation administrative obligatoire.', 'type': 'Urgent'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchProgrammeActif();
    _fetchHistorique();
    _fetchCalendrier();
  }

  // ── Récupère le programme actif (non archivé) de la filière/niveau ───────
  Future<void> _fetchProgrammeActif() async {
    try {
      final row = await Supabase.instance.client
          .from('edt')
          .select()
          .eq('filiere_nom', widget.profile.filiere)
          .eq('niveau', widget.profile.niveau)
          .eq('archive', false)
          .order('createdAt', ascending: false)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _edtActif = row;
        _creneaux = row != null ? _parseCreneaux(row['creneaux']) : [];
        _loadingProgramme = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingProgramme = false);
    }
  }

  // ── Récupère les programmes archivés (semaines précédentes) ──────────────
  Future<void> _fetchHistorique() async {
    try {
      final rows = await Supabase.instance.client
          .from('edt')
          .select()
          .eq('filiere_nom', widget.profile.filiere)
          .eq('niveau', widget.profile.niveau)
          .eq('archive', true)
          .order('archivedAt', ascending: false);

      if (!mounted) return;
      setState(() {
        _historique = List<Map<String, dynamic>>.from(rows as List);
        _loadingHistorique = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingHistorique = false);
    }
  }

  Future<void> _fetchCalendrier() async {
    try {
      final data = await Supabase.instance.client
          .from('calendrier')
          .select()
          .order('date_debut');
      final list = data as List;
      if (list.isNotEmpty && mounted) {
        setState(() {
          _eventsCalendrier = list.map((e) => {
            'titre': e['titre'] ?? '',
            'date': e['date_debut']?.toString() ?? '',
            'description': e['description'] ?? '',
            'type': e['type'] ?? 'Académique',
          }).toList();
        });
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> _parseCreneaux(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Couleur par type de créneau. Les examens ET les devoirs sont mis en
  /// évidence en jaune, comme demandé.
  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'cours': return const Color(0xFF3B82F6);
      case 'tp': return const Color(0xFF10B981);
      case 'td': return const Color(0xFF8B5CF6);
      case 'examen':
      case 'devoir': return _jaune;
      default: return _brandBlue;
    }
  }

  bool _estImportant(String type) {
    final t = type.toLowerCase();
    return t == 'examen' || t == 'devoir';
  }

  String _typeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'cours': return 'Cours';
      case 'tp': return 'TP';
      case 'td': return 'TD';
      case 'examen': return 'Examen';
      case 'devoir': return 'Devoir';
      default: return type;
    }
  }

  Future<void> _genererEtTelechargerPDF(
      BuildContext context, List<Map<String, dynamic>> creneaux) async {
    if (creneaux.isEmpty) return;
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('INSTITUT SUPÉRIEUR DE TECHNOLOGIES (IST)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text(widget.profile.filiere, style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    pw.Text('Emploi du Temps — ${widget.profile.niveau}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 16),
                pw.Center(
                  child: pw.Text('PLANNING HEBDOMADAIRE DES ENSEIGNEMENTS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1E40AF))),
                ),
                pw.SizedBox(height: 16),
                pw.TableHelper.fromTextArray(
                  headers: ['Jour', 'Horaire', 'Intitulé du Cours / Module', 'Type', 'Salle'],
                  data: creneaux.map((c) => [
                    c['jour']?.toString() ?? '',
                    '${c['heureDebut'] ?? ''} - ${c['heureFin'] ?? ''}',
                    c['matiere']?.toString() ?? '',
                    _typeLabel(c['type']?.toString() ?? ''),
                    c['salle']?.toString() ?? '',
                  ]).toList(),
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E40AF)),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellPadding: const pw.EdgeInsets.all(6),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                ),
                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Document numérique certifié scolarité — Génération ScolarHub', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                )
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Emploi_du_Temps.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGlobal,
      body: SafeArea(
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Column(children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _brandBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.date_range_rounded, color: _brandBlue, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Planning & Salles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textMain, letterSpacing: -0.5)),
                    const SizedBox(height: 2),
                    Text(
                      widget.profile.niveau.isNotEmpty
                          ? 'Filière : ${widget.profile.filiere} (${widget.profile.niveau})'
                          : 'Filière : ${widget.profile.filiere}',
                      style: const TextStyle(fontSize: 12, color: _textMuted, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )),
                if (_creneaux.isNotEmpty)
                  IconButton(
                    onPressed: () => _genererEtTelechargerPDF(context, _creneaux),
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444)),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFEF2F2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
              ]),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                labelColor: _brandBlue,
                unselectedLabelColor: _textMuted,
                indicatorColor: _brandBlue,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'Cette semaine'),
                  Tab(text: 'Dates importantes'),
                  Tab(text: 'Historique'),
                ],
              ),
            ]),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProgrammeActifTab(),
                _buildDatesImportantesTab(),
                _buildHistoriqueTab(),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ── Onglet 1 : programme actif (réel, non archivé) ───────────────────────

  Widget _buildProgrammeActifTab() {
    if (_loadingProgramme) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_edtActif == null || _creneaux.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                  color: _brandBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.event_busy_rounded,
                  color: _brandBlue, size: 34),
            ),
            const SizedBox(height: 18),
            const Text('Programme non disponible',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: _textMain)),
            const SizedBox(height: 8),
            const Text(
              'Le programme de cette semaine n\'a pas encore été publié pour ta filière. Reviens un peu plus tard.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _textMuted, height: 1.5),
            ),
          ]),
        ),
      );
    }

    return _buildGrilleSemaine(_creneaux);
  }

  Widget _buildGrilleSemaine(List<Map<String, dynamic>> creneaux) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: _joursSemaine.length,
      itemBuilder: (context, jIdx) {
        final jour = _joursSemaine[jIdx];
        final coursDuJour = creneaux.where((c) => c['jour'] == jour).toList();
        final jourImportant = coursDuJour.any(
            (c) => _estImportant(c['type']?.toString() ?? ''));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 8, bottom: 10),
              child: Row(children: [
                Text(
                  jour.toUpperCase(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _brandBlue, letterSpacing: 0.6),
                ),
                if (jourImportant) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: _jauneFond,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: _jaune.withValues(alpha: 0.4))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.warning_amber_rounded, size: 11, color: _jaune),
                      const SizedBox(width: 4),
                      Text('Examen/Devoir',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _jaune.withValues(alpha: 0.9))),
                    ]),
                  ),
                ],
              ]),
            ),
            if (coursDuJour.isEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
                child: const Text('Aucun cours programmé', style: TextStyle(fontSize: 13, color: _textMuted, fontStyle: FontStyle.italic)),
              )
            else
              ...coursDuJour.map((cours) {
                final type = cours['type']?.toString() ?? '';
                final Color typeColor = _getTypeColor(type);
                final important = _estImportant(type);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: important ? _jauneFond : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: important ? _jaune.withValues(alpha: 0.35) : _border),
                  ),
                  child: IntrinsicHeight(
                    child: Row(children: [
                      Container(
                        width: 6,
                        decoration: BoxDecoration(
                          color: typeColor,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18)),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Row(children: [
                                  const Icon(Icons.access_time_filled_rounded, size: 14, color: _textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                      '${cours['heureDebut'] ?? ''} - ${cours['heureFin'] ?? ''}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textMain)),
                                ]),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    if (important)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 3),
                                        child: Icon(Icons.warning_amber_rounded, size: 11, color: _jaune),
                                      ),
                                    Text(_typeLabel(type), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: typeColor)),
                                  ]),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              Text(cours['matiere']?.toString() ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textMain)),
                              const SizedBox(height: 8),
                              Row(children: [
                                const Icon(Icons.room_rounded, size: 14, color: _brandBlue),
                                const SizedBox(width: 4),
                                Text(cours['salle']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: _brandBlue, fontWeight: FontWeight.w600)),
                              ]),
                            ],
                          ),
                        ),
                      )
                    ]),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  // ── Onglet 2 : dates importantes (inchangé) ───────────────────────────────

  Widget _buildDatesImportantesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _eventsCalendrier.length,
      itemBuilder: (context, index) {
        final item = _eventsCalendrier[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
          child: Row(children: [
            Container(width: 4, height: 40, decoration: BoxDecoration(color: _brandBlue, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(item['titre']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textMain)),
                Text(item['date']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textMuted)),
              ]),
              const SizedBox(height: 4),
              Text(item['description']!, style: const TextStyle(fontSize: 12, color: _textMuted)),
            ]))
          ]),
        );
      },
    );
  }

  // ── Onglet 3 : historique des semaines archivées ──────────────────────────

  Widget _buildHistoriqueTab() {
    if (_loadingHistorique) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_historique.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            const Text('Aucun programme archivé pour l\'instant',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _textMuted)),
          ]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historique.length,
      itemBuilder: (context, index) {
        final edt = _historique[index];
        final archivedAt = edt['archivedAt']?.toString();
        final createdAt = edt['createdAt']?.toString();
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                  color: _brandBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.history_rounded, color: _brandBlue, size: 20),
            ),
            title: Text(
                'Programme ${edt['anneeAcademique'] ?? ''}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textMain)),
            subtitle: Text(
                archivedAt != null
                    ? 'Archivé le ${archivedAt.split('T').first}'
                    : (createdAt != null ? 'Créé le ${createdAt.split('T').first}' : ''),
                style: const TextStyle(fontSize: 11, color: _textMuted)),
            trailing: const Icon(Icons.chevron_right_rounded, color: _textMuted),
            onTap: () => _ouvrirHistoriqueDetail(edt),
          ),
        );
      },
    );
  }

  void _ouvrirHistoriqueDetail(Map<String, dynamic> edt) {
    final creneaux = _parseCreneaux(edt['creneaux']);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 10),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                Expanded(
                  child: Text('Programme ${edt['anneeAcademique'] ?? ''}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _textMain)),
                ),
                if (creneaux.isNotEmpty)
                  IconButton(
                    onPressed: () => _genererEtTelechargerPDF(context, creneaux),
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444)),
                  ),
              ]),
            ),
            Expanded(
              child: creneaux.isEmpty
                  ? const Center(child: Text('Aucun créneau enregistré.'))
                  : _buildGrilleSemaine(creneaux),
            ),
          ]),
        ),
      ),
    );
  }
}

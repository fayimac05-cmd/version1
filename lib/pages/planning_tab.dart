import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/etablissement_config.dart';
import '../models/student_profile.dart';
import '../services/api_service.dart';
import 'edt_officiel_view.dart';

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

  // ── Programme actif (table edt, semaine en cours) ─────────────────────────
  bool _loadingProgramme = true;
  Map<String, dynamic>? _edtActif;
  List<Map<String, dynamic>> _creneaux = [];
  // Filière réelle de l'étudiant (nom + département) renvoyée par le serveur.
  Map<String, dynamic> _filiereInfo = {};

  // ── Historique (table edt : archivés OU dateFin dépassée) ─────────────────
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
    _fetchProgrammes();
    _fetchCalendrier();
  }

  String get _aujourdhuiIso => DateTime.now().toIso8601String().split('T').first;

  // ── Programme actif + historique, résolus CÔTÉ SERVEUR à partir de la
  // vraie filière de l'étudiant (filiere_id) dans SON établissement. Évite de
  // chercher par nom de filière : deux établissements peuvent avoir une
  // filière et un niveau de même nom, et l'étudiant ne doit voir que le sien.
  Future<void> _fetchProgrammes() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/edt/mon-programme'),
        headers: await ApiService.getHeaders(),
      );
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final data = (body['data'] as Map?) ?? {};
      final actif = data['actif'] is Map ? Map<String, dynamic>.from(data['actif'] as Map) : null;
      final histo = (data['historique'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        _filiereInfo = data['filiere'] is Map ? Map<String, dynamic>.from(data['filiere'] as Map) : {};
        _edtActif = actif;
        _creneaux = actif != null ? _parseCreneaux(actif['creneaux']) : [];
        _historique = histo;
        _loadingProgramme = false;
        _loadingHistorique = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingProgramme = false;
          _loadingHistorique = false;
        });
      }
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

  String _formatDateAffichage(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
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
                        pw.Text(EtablissementConfig.instance.nom.isNotEmpty ? EtablissementConfig.instance.nom.toUpperCase() : 'ÉTABLISSEMENT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
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
                  headers: ['Jour', 'Horaire', 'Intitulé du Cours / Module', 'Professeur', 'Type', 'Salle'],
                  data: creneaux.map((c) => [
                    c['jour']?.toString() ?? '',
                    '${c['heureDebut'] ?? ''} - ${c['heureFin'] ?? ''}',
                    c['matiere']?.toString() ?? '',
                    c['prof']?.toString() ?? '',
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

  // ── Onglet 1 : programme de la semaine en cours ───────────────────────────

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

    return _buildGrilleSemaine(
      _creneaux,
      dateDebut: _edtActif?['dateDebut']?.toString(),
      dateFin: _edtActif?['dateFin']?.toString(),
      edt: _edtActif,
    );
  }

  // ── Tableau semaine : EXACTEMENT le même rendu que le programme officiel
  // côté administration (en-tête avec logo/établissement, horaires, pause…).

  DateTime? _dateDe(String? iso) => iso == null ? null : DateTime.tryParse(iso);

  Widget _buildGrilleSemaine(List<Map<String, dynamic>> creneaux,
      {String? dateDebut, String? dateFin, Map<String, dynamic>? edt}) {
    final cfg = EtablissementConfig.instance;
    final filNom = (_filiereInfo['nom'] ?? edt?['filiere_nom'] ?? widget.profile.filiere).toString();
    final dept = (_filiereInfo['domaine'] ?? widget.profile.domaine).toString();
    final niv = (edt?['niveau'] ?? widget.profile.niveau).toString();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: EdtOfficielView(
        creneaux: creneaux,
        etabNom: cfg.nom,
        etabLogo: cfg.logoUrl,
        departement: dept,
        filiereNom: filNom,
        niveau: niv,
        annee: (edt?['anneeAcademique'] ?? '').toString(),
        dateDebut: _dateDe(dateDebut),
        dateFin: _dateDe(dateFin),
      ),
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

  // ── Onglet 3 : historique (archivés ou semaine terminée) ──────────────────

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
        final dateDebut = edt['dateDebut']?.toString();
        final dateFin = edt['dateFin']?.toString();
        final archivedAt = edt['archivedAt']?.toString();
        final sousTitre = (dateDebut != null && dateFin != null)
            ? 'Semaine du ${_formatDateAffichage(dateDebut)} au ${_formatDateAffichage(dateFin)}'
            : (archivedAt != null ? 'Archivé le ${archivedAt.split('T').first}' : '');
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
            subtitle: Text(sousTitre, style: const TextStyle(fontSize: 11, color: _textMuted)),
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
                  : _buildGrilleSemaine(
                      creneaux,
                      dateDebut: edt['dateDebut']?.toString(),
                      dateFin: edt['dateFin']?.toString(),
                      edt: edt,
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}
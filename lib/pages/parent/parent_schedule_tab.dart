import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'parent_styles.dart';

class ParentScheduleTab extends StatefulWidget {
  final String nomEnfant;
  final String filiere;
  final String niveau;

  const ParentScheduleTab({
    super.key,
    required this.nomEnfant,
    required this.filiere,
    required this.niveau,
  });

  @override
  State<ParentScheduleTab> createState() => _ParentScheduleTabState();
}

class _ParentScheduleTabState extends State<ParentScheduleTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _joursSemaine = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'
  ];

  bool _loadingProgramme = true;
  Map<String, dynamic>? _edtActif;
  List<Map<String, dynamic>> _creneaux = [];

  bool _loadingHistorique = true;
  List<Map<String, dynamic>> _historique = [];

  List<Map<String, dynamic>> _eventsCalendrier = [];
  bool _loadingCalendrier = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchProgrammeActif();
    _fetchHistorique();
    _fetchCalendrier();
  }

  @override
  void didUpdateWidget(covariant ParentScheduleTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filiere != widget.filiere || oldWidget.niveau != widget.niveau) {
      _fetchProgrammeActif();
      _fetchHistorique();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _aujourdhuiIso => DateTime.now().toIso8601String().split('T').first;

  Future<void> _fetchProgrammeActif() async {
    setState(() => _loadingProgramme = true);
    try {
      var row = await Supabase.instance.client
          .from('edt')
          .select()
          .eq('filiere_nom', widget.filiere)
          .eq('niveau', widget.niveau)
          .eq('archive', false)
          .lte('dateDebut', _aujourdhuiIso)
          .gte('dateFin', _aujourdhuiIso)
          .order('dateDebut', ascending: false)
          .limit(1)
          .maybeSingle();

      row ??= await Supabase.instance.client
          .from('edt')
          .select()
          .eq('filiere_nom', widget.filiere)
          .eq('niveau', widget.niveau)
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

  Future<void> _fetchHistorique() async {
    setState(() => _loadingHistorique = true);
    try {
      final rows = await Supabase.instance.client
          .from('edt')
          .select()
          .eq('filiere_nom', widget.filiere)
          .eq('niveau', widget.niveau)
          .or('archive.eq.true,dateFin.lt.$_aujourdhuiIso')
          .order('dateFin', ascending: false);

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
      if (!mounted) return;
      setState(() {
        _eventsCalendrier = list.map((e) => {
          'titre': e['titre'] ?? '',
          'date': e['date_debut']?.toString() ?? '',
          'description': e['description'] ?? '',
          'type': e['type'] ?? 'Académique',
        }).toList();
        _loadingCalendrier = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCalendrier = false);
    }
  }

  List<Map<String, dynamic>> _parseCreneaux(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'cours': return const Color(0xFF3B82F6);
      case 'tp': return const Color(0xFF10B981);
      case 'td': return const Color(0xFF8B5CF6);
      case 'examen':
      case 'devoir': return ParentStyles.warning;
      default: return ParentStyles.primary;
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

  Future<void> _genererEtTelechargerPDF(List<Map<String, dynamic>> creneaux) async {
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
                        pw.Text(widget.filiere, style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    pw.Text('Emploi du Temps — ${widget.niveau}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 16),
                pw.Center(
                  child: pw.Text('PLANNING HEBDOMADAIRE — ${widget.nomEnfant.toUpperCase()}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1E40AF))),
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

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Emploi_du_Temps_${widget.nomEnfant.replaceAll(' ', '_')}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParentStyles.bgLight,
      body: SafeArea(
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: ParentStyles.borderLight)),
            ),
            child: Column(children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: ParentStyles.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.date_range_rounded, color: ParentStyles.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Planning — ${widget.nomEnfant}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ParentStyles.textDark, letterSpacing: -0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${widget.filiere} (${widget.niveau})', style: const TextStyle(fontSize: 12, color: ParentStyles.textMuted, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                )),
                if (_creneaux.isNotEmpty)
                  IconButton(
                    onPressed: () => _genererEtTelechargerPDF(_creneaux),
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444)),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFEF2F2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
              ]),
              const SizedBox(height: 14),
              TabBar(
                controller: _tabController,
                labelColor: ParentStyles.primary,
                unselectedLabelColor: ParentStyles.textMuted,
                indicatorColor: ParentStyles.primary,
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
              decoration: BoxDecoration(color: ParentStyles.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.event_busy_rounded, color: ParentStyles.primary, size: 34),
            ),
            const SizedBox(height: 18),
            const Text('Programme non disponible', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ParentStyles.textDark)),
            const SizedBox(height: 8),
            Text(
              'Le programme de cette semaine n\'a pas encore été publié pour la filière de ${widget.nomEnfant}.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: ParentStyles.textMuted, height: 1.5),
            ),
          ]),
        ),
      );
    }
    return _buildGrilleSemaine(
      _creneaux,
      dateDebut: _edtActif?['dateDebut']?.toString(),
      dateFin: _edtActif?['dateFin']?.toString(),
    );
  }

  Widget _buildGrilleSemaine(List<Map<String, dynamic>> creneaux, {String? dateDebut, String? dateFin}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dateDebut != null && dateFin != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(children: [
                const Icon(Icons.date_range_rounded, size: 16, color: ParentStyles.primary),
                const SizedBox(width: 8),
                Text(
                  'Semaine du ${_formatDateAffichage(dateDebut)} au ${_formatDateAffichage(dateFin)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ParentStyles.primary),
                ),
              ]),
            ),
            const SizedBox(height: 14),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildTableauJours(creneaux),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _coursDuJour(List<Map<String, dynamic>> creneaux, String jour) {
    final liste = creneaux.where((c) => c['jour'] == jour).toList();
    liste.sort((a, b) => (a['heureDebut']?.toString() ?? '').compareTo(b['heureDebut']?.toString() ?? ''));
    return liste;
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

  int _ecartMinutes(String? finA, String? debutB) {
    final fa = _parseHeure(finA);
    final db = _parseHeure(debutB);
    if (fa == null || db == null) return 0;
    final diff = (db.hour * 60 + db.minute) - (fa.hour * 60 + fa.minute);
    return diff > 0 ? diff : 0;
  }

  Widget _spacerEcart(int minutes) {
    if (minutes <= 0) {
      return const Divider(height: 1, color: ParentStyles.borderLight);
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
          Expanded(child: Container(height: 1, margin: const EdgeInsets.only(right: 6), color: ParentStyles.borderLight)),
          Text(label, style: const TextStyle(fontSize: 10, color: ParentStyles.textMuted, fontWeight: FontWeight.w600)),
          Expanded(child: Container(height: 1, margin: const EdgeInsets.only(left: 6), color: ParentStyles.borderLight)),
        ],
      ),
    );
  }

  Widget _carteCoursTableau(Map<String, dynamic> c) {
    final type = c['type']?.toString() ?? '';
    final couleur = _getTypeColor(type);
    final important = _estImportant(type);
    final prof = c['prof']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(8),
      color: important ? ParentStyles.warningLight : couleur.withValues(alpha: 0.10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(4)),
              child: Text(_typeLabel(type), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(width: 6),
            if (important) const Padding(padding: EdgeInsets.only(right: 3), child: Icon(Icons.warning_amber_rounded, size: 11, color: ParentStyles.warning)),
            Expanded(
              child: Text('${c['heureDebut'] ?? ''} - ${c['heureFin'] ?? ''}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ParentStyles.textDark),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 4),
          Text(c['matiere']?.toString() ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ParentStyles.textDark), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (prof.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.person_outline_rounded, size: 11, color: ParentStyles.textMuted),
              const SizedBox(width: 2),
              Expanded(child: Text(prof, style: const TextStyle(fontSize: 10.5, color: ParentStyles.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ],
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.room_outlined, size: 11, color: ParentStyles.primary),
            const SizedBox(width: 2),
            Expanded(child: Text(c['salle']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: ParentStyles.primary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ],
      ),
    );
  }

  Widget _corpsJourTableau(List<Map<String, dynamic>> creneaux, String jour) {
    const double caseHeight = 100;
    final cours = _coursDuJour(creneaux, jour);

    if (cours.isEmpty) {
      return const SizedBox(
        height: caseHeight,
        child: Center(child: Text('Aucun cours', style: TextStyle(fontSize: 11, color: ParentStyles.textMuted, fontStyle: FontStyle.italic))),
      );
    }

    final children = <Widget>[];
    for (var i = 0; i < cours.length; i++) {
      children.add(SizedBox(height: caseHeight, child: _carteCoursTableau(cours[i])));
      if (i < cours.length - 1) {
        children.add(_spacerEcart(_ecartMinutes(cours[i]['heureFin']?.toString(), cours[i + 1]['heureDebut']?.toString())));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  Widget _buildTableauJours(List<Map<String, dynamic>> creneaux) {
    const double colWidth = 180;

    return Container(
      decoration: BoxDecoration(border: Border.all(color: ParentStyles.borderLight), borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: _joursSemaine.map((j) => Container(
                  width: colWidth,
                  height: 40,
                  color: ParentStyles.primary,
                  alignment: Alignment.center,
                  child: Text(j, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                )).toList(),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < _joursSemaine.length; i++) ...[
                  if (i > 0) const VerticalDivider(width: 1, thickness: 1, color: ParentStyles.borderLight),
                  SizedBox(width: colWidth, child: _corpsJourTableau(creneaux, _joursSemaine[i])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesImportantesTab() {
    if (_loadingCalendrier) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_eventsCalendrier.isEmpty) {
      return const Center(
        child: Text('Aucune date importante publiée pour le moment.', style: TextStyle(fontSize: 13, color: ParentStyles.textMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _eventsCalendrier.length,
      itemBuilder: (context, index) {
        final item = _eventsCalendrier[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: ParentStyles.borderLight)),
          child: Row(children: [
            Container(width: 4, height: 40, decoration: BoxDecoration(color: ParentStyles.primary, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(item['titre'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ParentStyles.textDark)),
                Text(item['date'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ParentStyles.textMuted)),
              ]),
              const SizedBox(height: 4),
              Text(item['description'] ?? '', style: const TextStyle(fontSize: 12, color: ParentStyles.textMuted)),
            ]))
          ]),
        );
      },
    );
  }

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
            const Text('Aucun programme archivé pour l\'instant', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: ParentStyles.textMuted)),
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: ParentStyles.borderLight)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: ParentStyles.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.history_rounded, color: ParentStyles.primary, size: 20),
            ),
            title: Text('Programme ${edt['anneeAcademique'] ?? ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ParentStyles.textDark)),
            subtitle: Text(sousTitre, style: const TextStyle(fontSize: 11, color: ParentStyles.textMuted)),
            trailing: const Icon(Icons.chevron_right_rounded, color: ParentStyles.textMuted),
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
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                Expanded(
                  child: Text('Programme ${edt['anneeAcademique'] ?? ''}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ParentStyles.textDark)),
                ),
                if (creneaux.isNotEmpty)
                  IconButton(
                    onPressed: () => _genererEtTelechargerPDF(creneaux),
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444)),
                  ),
              ]),
            ),
            Expanded(
              child: creneaux.isEmpty
                  ? const Center(child: Text('Aucun créneau enregistré.'))
                  : _buildGrilleSemaine(creneaux, dateDebut: edt['dateDebut']?.toString(), dateFin: edt['dateFin']?.toString()),
            ),
          ]),
        ),
      ),
    );
  }
}
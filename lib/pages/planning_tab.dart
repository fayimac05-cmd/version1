import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../config/etablissement_config.dart';
import '../models/student_profile.dart';
import '../services/api_service.dart';
import 'edt_officiel_view.dart';

class PlanningTab extends StatefulWidget {
  const PlanningTab({super.key, required this.profile, this.etudiantId, this.nomEnfant});
  final StudentProfile profile;

  /// Espace parent : id de l'enfant dont on affiche le planning (même modèle que l'étudiant).
  final String? etudiantId;
  final String? nomEnfant;

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

  // ── Dates importantes (calendrier académique de MON établissement, via le serveur) ──
  bool _loadingCalendrier = true;
  bool _erreurCalendrier = false;
  List<Map<String, dynamic>> _eventsCalendrier = [];

  // Affichage de la semaine sur petit écran : false = « par jour », true = tableau officiel.
  final ValueNotifier<bool> _vueTableau = ValueNotifier<bool>(false);

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
        Uri.parse(widget.etudiantId != null
            ? '${ApiService.baseUrl}/parents/enfant/${widget.etudiantId}/programme'
            : '${ApiService.baseUrl}/edt/mon-programme'),
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

  static const List<String> _moisCourts = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  String _jolieDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_moisCourts[d.month - 1]} ${d.year}';

  DateTime? _parseJour(String? iso) =>
      (iso == null || iso.length < 10) ? null : DateTime.tryParse(iso.substring(0, 10));

  /// « 04 nov. 2026 » ou « 04 nov. 2026 → 15 nov. 2026 ».
  String _libelleDate(String? debut, String? fin) {
    final d = _parseJour(debut);
    if (d == null) return '';
    final f = _parseJour(fin);
    if (f == null || f == d) return _jolieDate(d);
    return '${_jolieDate(d)} → ${_jolieDate(f)}';
  }

  Future<void> _fetchCalendrier() async {
    try {
      final r = await http.get(
        Uri.parse('${ApiService.baseUrl}/calendrier'),
        headers: await ApiService.getHeaders(),
      );
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      final list = (body['data'] as List? ?? []);
      final now = DateTime.now();
      final aujourdhui = DateTime(now.year, now.month, now.day);
      final events = list.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final debut = m['date_debut']?.toString();
        final fin = m['date_fin']?.toString();
        final dernier = _parseJour(fin) ?? _parseJour(debut);
        return {
          'titre': (m['titre'] ?? '').toString(),
          'date': _libelleDate(debut, fin),
          'description': (m['description'] ?? '').toString(),
          'type': (m['type'] ?? 'Académique').toString(),
          'passee': dernier != null && dernier.isBefore(aujourdhui),
        };
      }).toList();
      if (!mounted) return;
      setState(() {
        _eventsCalendrier = events;
        _loadingCalendrier = false;
        _erreurCalendrier = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingCalendrier = false;
        _erreurCalendrier = true;
      });
    }
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
    _vueTableau.dispose();
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
                if (Navigator.of(context).canPop()) ...[
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'Retour',
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _textMain),
                    style: IconButton.styleFrom(
                      backgroundColor: _bgGlobal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _brandBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.date_range_rounded, color: _brandBlue, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.nomEnfant != null ? 'Planning — ${widget.nomEnfant}' : 'Planning & Salles',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textMain, letterSpacing: -0.5),
                    ),
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
    final tableau = SingleChildScrollView(
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
    // Téléphone en portrait : le grand tableau ne tient pas (il fallait tourner l'écran).
    // On affiche donc la semaine JOUR PAR JOUR, lisible d'un coup d'œil, avec la
    // possibilité de basculer sur le tableau officiel.
    return LayoutBuilder(builder: (ctx, box) {
      if (box.maxWidth >= 700) return tableau;
      return ValueListenableBuilder<bool>(
        valueListenable: _vueTableau,
        builder: (_, enTableau, __) => Column(children: [
          _selecteurVue(enTableau),
          Expanded(
            child: enTableau
                ? tableau
                : _buildSemaineParJour(creneaux, dateDebut: dateDebut, dateFin: dateFin),
          ),
        ]),
      );
    });
  }

  Widget _selecteurVue(bool enTableau) {
    Widget bouton(String label, IconData ic, bool actif, bool versTableau) => Expanded(
      child: GestureDetector(
        onTap: () => _vueTableau.value = versTableau,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: actif ? _brandBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(ic, size: 15, color: actif ? Colors.white : _textMuted),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: actif ? Colors.white : _textMuted)),
          ]),
        ),
      ),
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFEEF2F7), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        bouton('Par jour', Icons.view_agenda_rounded, !enTableau, false),
        bouton('Tableau', Icons.grid_on_rounded, enTableau, true),
      ]),
    );
  }

  /// Minutes depuis minuit, pour trier « 8h00 », « 08:00 », « 14H30 »…
  int _minutes(dynamic heure) {
    final m = RegExp(r'(\d{1,2})\D*(\d{2})?').firstMatch((heure ?? '').toString());
    if (m == null) return 0;
    return int.parse(m.group(1)!) * 60 + (m.group(2) == null ? 0 : int.parse(m.group(2)!));
  }

  // Semaine vue jour par jour : un bloc par jour, les créneaux dans l'ordre de l'horloge.
  Widget _buildSemaineParJour(List<Map<String, dynamic>> creneaux, {String? dateDebut, String? dateFin}) {
    final aujourdhui = DateTime.now().weekday <= _joursSemaine.length ? _joursSemaine[DateTime.now().weekday - 1] : '';
    final debut = _dateDe(dateDebut);
    final fin = _dateDe(dateFin);

    final blocs = <Widget>[];
    for (final jour in _joursSemaine) {
      final duJour = creneaux
          .where((c) => (c['jour'] ?? '').toString().trim().toLowerCase() == jour.toLowerCase())
          .toList()
        ..sort((a, b) => _minutes(a['heureDebut']).compareTo(_minutes(b['heureDebut'])));
      if (duJour.isEmpty) continue;
      final estAujourdhui = jour == aujourdhui;
      blocs.add(Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: Row(children: [
          Text(jour.toUpperCase(), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: estAujourdhui ? _brandBlue : _textMuted)),
          if (estAujourdhui) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: _brandBlue, borderRadius: BorderRadius.circular(20)),
              child: const Text("Aujourd'hui", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ]),
      ));
      for (final c in duJour) {
        blocs.add(_carteCreneau(c));
      }
    }

    if (blocs.isEmpty) {
      return const Center(child: Text('Aucun créneau cette semaine.', style: TextStyle(fontSize: 13, color: _textMuted)));
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (debut != null && fin != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('Semaine du ${_formatDateAffichage(dateDebut)} au ${_formatDateAffichage(dateFin)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textMuted)),
          ),
        ...blocs,
      ],
    );
  }

  Widget _carteCreneau(Map<String, dynamic> c) {
    final type = (c['type'] ?? 'cours').toString();
    final couleur = _getTypeColor(type);
    final important = _estImportant(type);
    final salle = (c['salle'] ?? '').toString().trim();
    final prof = (c['prof'] ?? '').toString().trim();
    final debut = (c['heureDebut'] ?? '').toString();
    final fin = (c['heureFin'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: important ? _jauneFond : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: important ? _jaune.withValues(alpha: 0.5) : _border),
      ),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            width: 5,
            decoration: BoxDecoration(
              color: couleur,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            ),
          ),
          SizedBox(
            width: 70,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(debut, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _textMain)),
                const SizedBox(height: 2),
                Text(fin, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _textMuted)),
              ]),
            ),
          ),
          Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 10), color: _border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text((c['matiere'] ?? '').toString(), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _textMain))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: couleur.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
                    child: Text(_typeLabel(type), style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: couleur)),
                  ),
                ]),
                if (salle.isNotEmpty || prof.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(spacing: 14, runSpacing: 4, children: [
                    if (salle.isNotEmpty)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.meeting_room_outlined, size: 14, color: _textMuted),
                        const SizedBox(width: 4),
                        Text(salle, style: const TextStyle(fontSize: 12, color: _textMuted)),
                      ]),
                    if (prof.isNotEmpty)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.person_outline_rounded, size: 14, color: _textMuted),
                        const SizedBox(width: 4),
                        Flexible(child: Text(prof, style: const TextStyle(fontSize: 12, color: _textMuted), overflow: TextOverflow.ellipsis)),
                      ]),
                  ]),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Onglet 2 : dates importantes (données réelles de l'établissement) ─────

  Color _couleurDate(String type) {
    switch (type) {
      case 'Examens': return const Color(0xFF7C3AED);
      case 'Résultats': return const Color(0xFF10B981);
      case 'Vacances': return _jaune;
      case 'Urgent': return const Color(0xFFEF4444);
      default: return _brandBlue;
    }
  }

  Widget _carteDate(Map<String, dynamic> item) {
    final passee = item['passee'] == true;
    final couleur = _couleurDate((item['type'] ?? '').toString());
    final desc = (item['description'] ?? '').toString();
    return Opacity(
      opacity: passee ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
        child: Row(children: [
          Container(width: 4, height: 40, decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(item['titre'].toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textMain))),
              const SizedBox(width: 8),
              Flexible(child: Text(item['date'].toString(), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textMuted))),
            ]),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(fontSize: 12, color: _textMuted)),
            ],
          ])),
        ]),
      ),
    );
  }

  Widget _buildDatesImportantesTab() {
    if (_loadingCalendrier) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_erreurCalendrier) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded, size: 36, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            const Text('Impossible de charger les dates pour le moment.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _textMuted)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                setState(() { _loadingCalendrier = true; _erreurCalendrier = false; });
                _fetchCalendrier();
              },
              child: const Text('Réessayer'),
            ),
          ]),
        ),
      );
    }
    if (_eventsCalendrier.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.event_busy_rounded, size: 40, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            const Text('Aucune date publiée pour le moment',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textMain)),
            const SizedBox(height: 6),
            const Text('Les dates de la rentrée, des examens et des vacances apparaîtront ici dès que l\'administration les aura ajoutées.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: _textMuted, height: 1.5)),
          ]),
        ),
      );
    }

    final avenir = _eventsCalendrier.where((e) => e['passee'] != true).toList();
    final passees = _eventsCalendrier.where((e) => e['passee'] == true).toList().reversed.toList();
    return RefreshIndicator(
      onRefresh: _fetchCalendrier,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (avenir.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('À venir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _textMuted, letterSpacing: 0.3)),
            ),
            for (final e in avenir) _carteDate(e),
          ],
          if (passees.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 6, bottom: 8),
              child: Text('Passées', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _textMuted, letterSpacing: 0.3)),
            ),
            for (final e in passees) _carteDate(e),
          ],
        ],
      ),
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
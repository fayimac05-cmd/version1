import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/student_profile.dart';
import '../services/api_service.dart';
import '../admin/admin_theme.dart';

class AdminDashboard extends StatefulWidget {
  final StudentProfile profile;
  const AdminDashboard({super.key, required this.profile});
  @override State<AdminDashboard> createState() => _AdminDashboardState();
}
class _AdminDashboardState extends State<AdminDashboard> {
  bool _loadingKpis = true;
  int _nbEtudiants = 0;
  int _nbProfesseurs = 0;
  int _nbFilieres = 0;
  int _nbSciencesTech = 0;
  int _nbSciencesGestion = 0;
  int _nbSuspendus = 0;

  bool _loadingRecl = true;
  List<dynamic> _reclamations = [];

  bool _loadingEvents = true;
  List<dynamic> _evenements = [];

  bool _loadingMajors = true;
  List<dynamic> _majors = [];

  bool _loadingBlamables = true;
  int _nbNotesBlamables = 0;

  bool _loadingInscriptions = true;
  List<dynamic> _inscriptions = [];

  @override
  void initState() {
    super.initState();
    _chargerKpis();
    _chargerReclamations();
    _chargerEvenements();
    _chargerMajors();
    _chargerNotesBlamables();
    _chargerInscriptions();
  }

  Future<void> _chargerNotesBlamables() async {
    final res = await ApiService.getNotesBlamables();
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        final data = res['data'] as List<dynamic>;
        _nbNotesBlamables = data.length;
      }
      _loadingBlamables = false;
    });
  }

  Future<void> _chargerInscriptions() async {
    final res = await ApiService.getInscriptionsParMois();
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        _inscriptions = res['data'] as List<dynamic>;
      }
      _loadingInscriptions = false;
    });
  }

  Future<void> _chargerMajors() async {
    final res = await ApiService.getMoyennesAdmin();
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        final data = res['data'] as List<dynamic>;
        _majors = data.take(3).toList();
      }
      _loadingMajors = false;
    });
  }

  Future<void> _chargerReclamations() async {
    final res = await ApiService.getReclamations();
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        _reclamations = res['data'] as List<dynamic>;
      }
      _loadingRecl = false;
    });
  }

  int get _nbReclamationsEnAttente =>
      _reclamations.where((r) => (r['statut'] ?? '') == 'en_attente').length;

  Future<void> _chargerEvenements() async {
    final res = await ApiService.getEvenements();
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        _evenements = res['data'] as List<dynamic>;
      }
      _loadingEvents = false;
    });
  }

  List<dynamic> get _evenementsAVenir {
    final maintenant = DateTime.now();
    final list = _evenements.where((e) {
      if (e['statut'] != 'approuve') return false;
      final d = DateTime.tryParse(e['date_debut']?.toString() ?? '');
      return d != null && d.isAfter(maintenant);
    }).toList();
    list.sort((a, b) {
      final da = DateTime.tryParse(a['date_debut']?.toString() ?? '') ?? maintenant;
      final db = DateTime.tryParse(b['date_debut']?.toString() ?? '') ?? maintenant;
      return da.compareTo(db);
    });
    return list;
  }

  List<dynamic> get _evenementsEnAttente =>
      _evenements.where((e) => e['statut'] == 'en_attente').toList();

  Future<void> _validerEvenement(dynamic id, String statut) async {
    final res = await ApiService.updateEvenementStatut(id.toString(), statut);
    if (!mounted) return;
    if (res['success'] == true) {
      _chargerEvenements();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['error']?.toString() ?? 'Erreur lors de la mise à jour.')),
      );
    }
  }

  Future<void> _chargerKpis() async {
    final results = await Future.wait([
      ApiService.getEtudiants(),
      ApiService.getProfesseurs(),
      ApiService.getFilieres(),
    ]);

    final etudiantsRes = results[0];
    final professeursRes = results[1];
    final filieresRes = results[2];

    if (!mounted) return;
    setState(() {
      if (etudiantsRes['success'] == true) {
        final data = etudiantsRes['data'] as List<dynamic>;
        _nbEtudiants = data.where((e) => (e['statut'] ?? 'actif') == 'actif').length;
        // Répartition par domaine — calculée à partir de la même liste,
        // pas d'appel réseau supplémentaire.
        _nbSciencesTech = data.where((e) => (e['domaine'] ?? '') == 'Sciences & Technologies').length;
        _nbSciencesGestion = data.where((e) => (e['domaine'] ?? '') == 'Sciences de Gestion').length;
        _nbSuspendus = data.where((e) => (e['statut'] ?? '') == 'suspendu').length;
      }
      if (professeursRes['success'] == true) {
        final data = professeursRes['data'] as List<dynamic>;
        _nbProfesseurs = data.length;
      }
      if (filieresRes['success'] == true) {
        final data = filieresRes['data'] as List<dynamic>;
        _nbFilieres = data.length;
      }
      _loadingKpis = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdminTheme.isDesktop(context);
    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 28 : 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Salutation ──────────────────────────────────────────────
          _greeting(),
          const SizedBox(height: 20),

          // ── Alertes prioritaires ────────────────────────────────────
          _alertsBanner(),
          const SizedBox(height: 24),

          // ── KPI Cards ───────────────────────────────────────────────
          _kpiRow(isDesktop),
          const SizedBox(height: 28),

          // ── Ligne widgets ────────────────────────────────────────────
          isDesktop
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: _reclamationsWidget()),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _eventsWidget()),
                ])
              : Column(children: [
                  _reclamationsWidget(),
                  const SizedBox(height: 16),
                  _eventsWidget(),
                ]),
          const SizedBox(height: 28),

          // ── Graphiques ───────────────────────────────────────────────
          isDesktop
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: _inscriptionsChart()),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _donutFilieres()),
                ])
              : Column(children: [
                  _inscriptionsChart(),
                  const SizedBox(height: 16),
                  _donutFilieres(),
                ]),
          const SizedBox(height: 28),

          // ── Publications BDE en attente ──────────────────────────────
          _bdeWidget(),
          const SizedBox(height: 28),

          // ── Majors de promo ──────────────────────────────────────────
          _majorsWidget(),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  // ── Salutation ────────────────────────────────────────────────────────
  Widget _greeting() => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Bonjour, ${widget.profile.prenoms} 👋',
          style: AdminTheme.headingLarge),
      const SizedBox(height: 4),
      Text('Voici un aperçu de votre établissement aujourd\'hui.',
          style: AdminTheme.bodyMedium),
    ])),
    if (widget.profile.filtreParDomaine) ...[
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(AdminTheme.radiusButton),
          border: Border.all(color: const Color(0xFFBAE6FD)),
        ),
        child: Row(children: [
          const Icon(Icons.school_rounded, color: Color(0xFF0284C7), size: 14),
          const SizedBox(width: 6),
          Text(
            widget.profile.domaineAdmin == 'Sciences & Technologies' ? 'Sciences & Tech' : 'Sciences Gestion',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
          ),
        ]),
      ),
      const SizedBox(width: 10),
    ],
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: AdminTheme.primaryLight,
          borderRadius: BorderRadius.circular(AdminTheme.radiusButton)),
      child: Row(children: [
        const Icon(Icons.calendar_today_rounded, color: AdminTheme.primary, size: 14),
        const SizedBox(width: 6),
        Text('Année 2024-2025', style: const TextStyle(fontSize: 12,
            fontWeight: FontWeight.w700, color: AdminTheme.primary)),
      ]),
    ),
  ]);

  // ── Bannière alertes ─────────────────────────────────────────────────
  Widget _alertsBanner() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [
        Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(AdminTheme.radiusCard),
      border: Border.all(color: AdminTheme.accent.withValues(alpha:0.3)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: AdminTheme.accentLight,
            borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.warning_amber_rounded,
            color: AdminTheme.accent, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Alertes prioritaires', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w800, color: AdminTheme.accent)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _alertChip(
            _loadingRecl
                ? 'Chargement des réclamations...'
                : '$_nbReclamationsEnAttente réclamation${_nbReclamationsEnAttente > 1 ? 's' : ''} non traitée${_nbReclamationsEnAttente > 1 ? 's' : ''}',
            Icons.report_problem_rounded,
          ),
          _alertChip(
            _loadingEvents
                ? 'Chargement des publications...'
                : '${_evenementsEnAttente.length} publication${_evenementsEnAttente.length > 1 ? 's' : ''} BDE en attente',
            Icons.celebration_rounded,
          ),
          if (!_loadingKpis && _nbSuspendus > 0)
            _alertChip(
              '$_nbSuspendus étudiant${_nbSuspendus > 1 ? 's' : ''} suspendu${_nbSuspendus > 1 ? 's' : ''}',
              Icons.person_off_rounded,
            ),
          if (!_loadingBlamables && _nbNotesBlamables > 0)
            _alertChip(
              '$_nbNotesBlamables note${_nbNotesBlamables > 1 ? 's' : ''} blâmable${_nbNotesBlamables > 1 ? 's' : ''} cette semaine',
              Icons.warning_rounded,
            ),
        ]),
      ])),
    ]),
  );

  Widget _alertChip(String label, IconData icon) => GestureDetector(
    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En cours de développement...'))),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminTheme.accent.withValues(alpha:0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04),
            blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AdminTheme.accent, size: 12),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11,
            fontWeight: FontWeight.w600, color: AdminTheme.accent)),
      ]),
    ),
  );

  // ── KPI Cards ─────────────────────────────────────────────────────────
  Widget _kpiRow(bool isDesktop) {
    final kpis = [
      {'label': 'Étudiants actifs', 'value': _loadingKpis ? '…' : '$_nbEtudiants',
       'sub': 'Total actifs',
       'icon': Icons.school_rounded, 'color': AdminTheme.iconFg,
       'bg': AdminTheme.iconBg, 'trend': false},
      {'label': 'Professeurs', 'value': _loadingKpis ? '…' : '$_nbProfesseurs',
       'sub': 'Total inscrits',
       'icon': Icons.person_pin_rounded, 'color': AdminTheme.iconFgAlt,
       'bg': AdminTheme.iconBgAlt, 'trend': false},
      {'label': 'Filières ouvertes', 'value': _loadingKpis ? '…' : '$_nbFilieres',
       'sub': 'Total',
       'icon': Icons.school_rounded, 'color': AdminTheme.iconFg,
       'bg': AdminTheme.iconBg, 'trend': false},
      // TODO: brancher sur le schéma evenements/inscriptions quand disponible
      // (quel événement afficher — le prochain à venir ? tous cumulés ?)
    ];

    if (isDesktop) {
      return Row(children: kpis.map((k) =>
          Expanded(child: Padding(
            padding: EdgeInsets.only(right: kpis.indexOf(k) < kpis.length - 1 ? 16 : 0),
            child: _kpiCard(k),
          ))).toList());
    }

    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, mainAxisSpacing: 12,
      crossAxisSpacing: 12, childAspectRatio: 1.3,
      physics: const NeverScrollableScrollPhysics(),
      children: kpis.map((k) => _kpiCard(k)).toList(),
    );
  }

  Widget _kpiCard(Map<String, dynamic> k) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radiusCard),
        border: Border.all(color: AdminTheme.border),
        boxShadow: AdminTheme.cardShadow),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 38, height: 38,
          decoration: BoxDecoration(color: k['bg'] as Color,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(k['icon'] as IconData, color: k['color'] as Color, size: 20)),
        const Spacer(),
        if (k['trend'] as bool)
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AdminTheme.successLight,
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.trending_up_rounded,
                  color: AdminTheme.success, size: 12),
              const SizedBox(width: 2),
              const Text('+', style: TextStyle(fontSize: 10,
                  fontWeight: FontWeight.bold, color: AdminTheme.success)),
            ])),
      ]),
      const SizedBox(height: 12),
      Text(k['value'] as String, style: const TextStyle(fontSize: 26,
          fontWeight: FontWeight.w800, color: AdminTheme.textPrimary)),
      const SizedBox(height: 2),
      Text(k['label'] as String, style: AdminTheme.headingSmall),
      const SizedBox(height: 2),
      Text(k['sub'] as String, style: AdminTheme.caption),
    ]),
  );

  // ── Réclamations récentes ─────────────────────────────────────────────
  Widget _reclamationsWidget() {
    if (_loadingRecl) {
      return _card(
        title: 'Réclamations récentes',
        icon: Icons.report_problem_rounded,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_reclamations.isEmpty) {
      return _card(
        title: 'Réclamations récentes',
        icon: Icons.report_problem_rounded,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('Aucune réclamation pour le moment.',
              style: AdminTheme.caption),
        ),
      );
    }
    final recentes = _reclamations.take(5).toList();
    return _card(
      title: 'Réclamations récentes',
      icon: Icons.report_problem_rounded,
      action: 'Voir tout',
      child: Column(
        children: recentes.map((r) {
          final nom = '${r['prenoms'] ?? ''} ${r['nom'] ?? ''}'.trim();
          final module = r['module_nom'] ?? r['type'] ?? '';
          final statut = r['statut'] ?? 'en_attente';
          final date = _formaterDateCourte(r['created_at']?.toString());
          return _reclItem(nom.isEmpty ? '—' : nom, module.toString(), statut, date);
        }).toList(),
      ),
    );
  }

  String _formaterDateCourte(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Widget _reclItem(String nom, String module, String statut, String date) {
    Color sc; String sl;
    switch (statut) {
      case 'transmise': sc = AdminTheme.info;    sl = 'Transmise'; break;
      case 'resolue':   sc = AdminTheme.success; sl = 'Résolue';   break;
      case 'rejetee':   sc = AdminTheme.textMuted; sl = 'Rejetée'; break;
      default:          sc = AdminTheme.warning; sl = 'En attente';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(width: 34, height: 34,
          decoration: BoxDecoration(color: AdminTheme.iconBg,
              shape: BoxShape.circle),
          child: Center(child: Text(
            '${nom.isNotEmpty ? nom[0] : ''}${nom.split(' ').length > 1 ? nom.split(' ')[1][0] : ''}'.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                color: AdminTheme.iconFg)))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nom, style: AdminTheme.headingSmall.copyWith(fontSize: 13)),
          Text(module, style: AdminTheme.caption),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          AdminTheme.badge(sl, sc, sc.withValues(alpha:0.1)),
          const SizedBox(height: 3),
          Text(date, style: AdminTheme.caption),
        ]),
      ]),
    );
  }

  // ── Événements à venir ────────────────────────────────────────────────
  Widget _eventsWidget() {
    if (_loadingEvents) {
      return _card(
        title: 'Prochains événements',
        icon: Icons.calendar_today_rounded,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final aVenir = _evenementsAVenir.take(3).toList();
    if (aVenir.isEmpty) {
      return _card(
        title: 'Prochains événements',
        icon: Icons.calendar_today_rounded,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('Aucun événement à venir.', style: AdminTheme.caption),
        ),
      );
    }
    final colors = [AdminTheme.warning, AdminTheme.primary, AdminTheme.success];
    return _card(
      title: 'Prochains événements',
      icon: Icons.calendar_today_rounded,
      action: 'Calendrier',
      child: Column(
        children: List.generate(aVenir.length, (i) {
          final e = aVenir[i];
          final titre = e['titre']?.toString() ?? '';
          final date = _formaterDateLongue(e['date_debut']?.toString());
          final capacite = int.tryParse('${e['capacite'] ?? 0}') ?? 0;
          final inscrits = int.tryParse('${e['inscrits'] ?? 0}') ?? 0;
          final prix = num.tryParse('${e['prix'] ?? 0}') ?? 0;
          String sousTitre;
          if (capacite > 0) {
            sousTitre = '$inscrits/$capacite billets';
          } else if (prix == 0) {
            sousTitre = 'Gratuit';
          } else {
            sousTitre = 'Places illimitées';
          }
          return Column(children: [
            _eventItem(titre, date, sousTitre, colors[i % colors.length]),
            if (i < aVenir.length - 1)
              const Divider(height: 20, color: AdminTheme.border),
          ]);
        }),
      ),
    );
  }

  String _formaterDateLongue(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      const mois = ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'];
      return '${d.day.toString().padLeft(2, '0')} ${mois[d.month - 1]} ${d.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _eventItem(String titre, String date, String billets, Color color) =>
      Row(children: [
        Container(width: 4, height: 48,
            decoration: BoxDecoration(color: color,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titre, style: AdminTheme.headingSmall.copyWith(fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text('$date · $billets', style: AdminTheme.caption),
        ])),
      ]);

  // ── Graphique inscriptions ────────────────────────────────────────────
  Widget _inscriptionsChart() {
    if (_loadingInscriptions) {
      return _card(
        title: 'Évolution des inscriptions',
        icon: Icons.show_chart_rounded,
        child: const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_inscriptions.isEmpty) {
      return _card(
        title: 'Évolution des inscriptions',
        icon: Icons.show_chart_rounded,
        child: SizedBox(
          height: 80,
          child: Center(child: Text('Aucune donnée disponible.', style: AdminTheme.caption)),
        ),
      );
    }

    const moisAbrege = ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'];
    final spots = <FlSpot>[];
    final labels = <String>[];
    for (var i = 0; i < _inscriptions.length; i++) {
      final row = _inscriptions[i];
      final cumule = (num.tryParse('${row['cumule'] ?? 0}') ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), cumule));
      final moisStr = row['mois']?.toString() ?? ''; // 'YYYY-MM'
      final parts = moisStr.split('-');
      final moisIdx = parts.length == 2 ? (int.tryParse(parts[1]) ?? 1) - 1 : 0;
      labels.add(moisAbrege[moisIdx.clamp(0, 11)]);
    }
    final maxY = spots.map((s) => s.y).fold<double>(0, (a, b) => a > b ? a : b);
    final minY = spots.map((s) => s.y).fold<double>(maxY, (a, b) => a < b ? a : b);

    return _card(
      title: 'Évolution des inscriptions',
      icon: Icons.show_chart_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 200, child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true, drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
                color: AdminTheme.border, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                    style: AdminTheme.caption))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox();
                  return Text(labels[i], style: AdminTheme.caption);
                })),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true, color: AdminTheme.primary,
              barWidth: 2.5,
              belowBarData: BarAreaData(show: true,
                  color: AdminTheme.primaryLight.withValues(alpha:0.5)),
              dotData: const FlDotData(show: false),
            ),
          ],
          minX: 0, maxX: (spots.length - 1).toDouble(),
          minY: (minY - 5).clamp(0, double.infinity), maxY: maxY + 10,
        ),
      )),
          const SizedBox(height: 8),
          Text(
            "Historique détaillé disponible à partir de la mise en place du suivi des inscriptions — "
            "les inscriptions antérieures apparaissent regroupées sur le premier mois.",
            style: AdminTheme.caption,
          ),
        ],
      ),
    );
  }

  // ── Donut filières ────────────────────────────────────────────────────
  Widget _donutFilieres() {
    final total = _nbSciencesTech + _nbSciencesGestion;
    if (_loadingKpis) {
      return _card(
        title: 'Répartition par domaine',
        icon: Icons.donut_large_rounded,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (total == 0) {
      return _card(
        title: 'Répartition par domaine',
        icon: Icons.donut_large_rounded,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('Aucun étudiant enregistré.', style: AdminTheme.caption),
        ),
      );
    }
    final pctTech = (_nbSciencesTech / total * 100).round();
    final pctGestion = 100 - pctTech;
    return _card(
      title: 'Répartition par domaine',
      icon: Icons.donut_large_rounded,
      child: Column(children: [
        SizedBox(height: 160, child: PieChart(
          PieChartData(
            sectionsSpace: 3, centerSpaceRadius: 45,
            sections: [
              PieChartSectionData(value: _nbSciencesTech.toDouble(), color: AdminTheme.primary,
                  title: '$pctTech%', radius: 55, titleStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              PieChartSectionData(value: _nbSciencesGestion.toDouble(), color: AdminTheme.info,
                  title: '$pctGestion%', radius: 55, titleStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        )),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _legend(AdminTheme.primary, 'Sciences & Technologies', '$_nbSciencesTech étudiants'),
          const SizedBox(width: 20),
          _legend(AdminTheme.info, 'Sciences de Gestion', '$_nbSciencesGestion étudiants'),
        ]),
      ]),
    );
  }

  Widget _legend(Color color, String label, String sub) => Row(
    mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: AdminTheme.textPrimary)),
      Text(sub, style: AdminTheme.caption),
    ]),
  ]);

  // ── Publications BDE ──────────────────────────────────────────────────
  Widget _bdeWidget() {
    if (_loadingEvents) {
      return _card(
        title: 'Publications BDE en attente',
        icon: Icons.celebration_rounded,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final enAttente = _evenementsEnAttente;
    if (enAttente.isEmpty) {
      return _card(
        title: 'Publications BDE en attente',
        icon: Icons.celebration_rounded,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('Aucune publication en attente.', style: AdminTheme.caption),
        ),
      );
    }
    return _card(
      title: 'Publications BDE en attente',
      icon: Icons.celebration_rounded,
      action: 'Voir tout',
      child: Column(
        children: enAttente.map((e) {
          final titre = e['titre']?.toString() ?? '';
          final auteur = '${e['auteur_prenoms'] ?? ''} ${e['auteur_nom'] ?? ''}'.trim();
          final date = _formaterDateCourte(e['createdAt']?.toString() ?? e['date_debut']?.toString());
          return _bdeItem(titre, auteur.isEmpty ? 'Auteur inconnu' : auteur, date, e['id']);
        }).toList(),
      ),
    );
  }

  Widget _bdeItem(String titre, String auteur, String date, dynamic id) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: AdminTheme.iconBgAlt,
            borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.celebration_outlined,
            color: AdminTheme.iconFgAlt, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titre, style: AdminTheme.headingSmall.copyWith(fontSize: 13)),
        Text('$auteur · $date', style: AdminTheme.caption),
      ])),
      const SizedBox(width: 8),
      Row(children: [
        _actionBtn('Approuver', AdminTheme.success, AdminTheme.successLight,
            onTap: () => _validerEvenement(id, 'approuve')),
        const SizedBox(width: 6),
        _actionBtn('Rejeter', AdminTheme.danger, AdminTheme.dangerLight,
            onTap: () => _validerEvenement(id, 'annule')),
      ]),
    ]),
  );

  Widget _actionBtn(String label, Color fg, Color bg, {VoidCallback? onTap}) => GestureDetector(
    onTap: onTap ?? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En cours de développement...'))),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg,
          borderRadius: BorderRadius.circular(AdminTheme.radiusSmall),
          border: Border.all(color: fg.withValues(alpha:0.3))),
      child: Text(label, style: TextStyle(fontSize: 11,
          fontWeight: FontWeight.w700, color: fg)),
    ),
  );

  // ── Majors de promo ───────────────────────────────────────────────────
  Widget _majorsWidget() {
    if (_loadingMajors) {
      return _card(
        title: 'Majors de promotion',
        icon: Icons.emoji_events_rounded,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_majors.isEmpty) {
      return _card(
        title: 'Majors de promotion',
        icon: Icons.emoji_events_rounded,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('Aucune note validée pour le moment.', style: AdminTheme.caption),
        ),
      );
    }
    const medailles = ['🥇', '🥈', '🥉'];
    return _card(
      title: 'Majors de promotion',
      icon: Icons.emoji_events_rounded,
      child: Column(
        children: List.generate(_majors.length, (i) {
          final m = _majors[i];
          final nom = '${m['prenoms'] ?? ''} ${m['nom'] ?? ''}'.trim();
          final filiereNiveau = '${m['filiere_nom'] ?? ''} ${m['niveau'] ?? ''}'.trim();
          final moyenne = num.tryParse('${m['moyenne'] ?? 0}') ?? 0;
          return _majorItem(i + 1, nom.isEmpty ? '—' : nom, filiereNiveau,
              '${moyenne.toStringAsFixed(1)}/20', medailles[i % medailles.length]);
        }),
      ),
    );
  }

  Widget _majorItem(int rank, String nom, String filiere, String moy, String medal) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Text(medal, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nom, style: AdminTheme.headingSmall.copyWith(fontSize: 13)),
            Text(filiere, style: AdminTheme.caption),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AdminTheme.iconBgAlt,
                borderRadius: BorderRadius.circular(20)),
            child: Text(moy, style: const TextStyle(fontSize: 12,
                fontWeight: FontWeight.w800, color: AdminTheme.iconFgAlt))),
        ]));

  // ── Card template ─────────────────────────────────────────────────────
  Widget _card({required String title, required IconData icon,
      required Widget child, String? action}) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AdminTheme.surface,
            borderRadius: BorderRadius.circular(AdminTheme.radiusCard),
            border: Border.all(color: AdminTheme.border),
            boxShadow: AdminTheme.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 32, height: 32,
              decoration: BoxDecoration(color: AdminTheme.iconBg,
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: AdminTheme.iconFg, size: 17)),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: AdminTheme.headingSmall)),
            if (action != null)
              TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En cours de développement...'))),
                  child: Text(action, style: const TextStyle(
                      fontSize: 12, color: AdminTheme.primary,
                      fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 4),
          const Divider(color: AdminTheme.border),
          const SizedBox(height: 4),
          child,
        ]),
      );
}
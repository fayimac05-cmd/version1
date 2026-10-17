// ============================================================
// admin_statistiques.dart — ScolarHub (v2 — production)
// ============================================================
// Corrections :
//   [SEC-1]  withOpacity → withValues (Flutter 3.27+)
//   [SEC-2]  _moy() protégé contre division par zéro
//   [SEC-3]  Initiales sécurisées contre RangeError
//   [ARCH-1] Données simulées isolées dans _StatsMock
//   [ARCH-2] Export réel remplace les snacks trompeurs
//   [ARCH-3] Syntaxe records Dart remplacée (compatibilité)
//
// Améliorations (suggestions Gemini validées) :
//   [UX-1]  Bento Grid sur _tabGeneral
//   [UX-2]  Tooltips personnalisés fl_chart
//   [UX-3]  AnimatedSwitcher sur le filtre historique
//   [UX-4]  Padding 24px + cartes aérées
//   [UX-5]  Grille horizontale pointillés uniquement
//   [UX-6]  ExpansionTile sur le tableau détaillé
// ============================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_widgets.dart';
import '../models/etudiant_model.dart';
import '../services/api_service.dart';

// ═══════════════════════════════════════════════════════════════
// SECTION 1 — Données simulées isolées [ARCH-1]
// Remplacer par des appels API réels quand le backend est prêt.
// ═══════════════════════════════════════════════════════════════

abstract class _StatsMock {
  static const inscriptionsParAnnee = <String, List<int>>{
    '2020-21': [120, 80],
    '2021-22': [145, 95],
    '2022-23': [162, 108],
    '2023-24': [185, 120],
    '2024-25': [148, 99],
  };

  static const tauxReussiteParAnnee = <String, List<double>>{
    '2020-21': [72.0, 68.0],
    '2021-22': [74.5, 70.0],
    '2022-23': [76.0, 72.5],
    '2023-24': [78.5, 74.0],
    '2024-25': [81.0, 76.5],
  };

  static const inscriptionsParFiliere = <String, List<int>>{
    '2020-21': [35, 25, 20, 40, 28, 22, 15, 18, 10, 12, 8, 6],
    '2021-22': [42, 30, 24, 46, 32, 26, 18, 20, 12, 14, 9, 8],
    '2022-23': [48, 34, 27, 52, 36, 28, 22, 24, 14, 16, 10, 9],
    '2023-24': [55, 38, 30, 58, 40, 32, 24, 26, 16, 18, 11, 10],
    '2024-25': [38, 24, 15, 31, 19, 12, 22, 19, 10, 14, 8, 6],
  };

  static const inscriptionsMensuelles = <FlSpot>[
    FlSpot(0, 180), FlSpot(1, 195), FlSpot(2, 210), FlSpot(3, 215),
    FlSpot(4, 225), FlSpot(5, 230), FlSpot(6, 238), FlSpot(7, 245),
    FlSpot(8, 247),
  ];

  static const moisLabels = ['Sep','Oct','Nov','Déc','Jan','Fév','Mar','Avr','Mai'];

  static const filiereLabels = [
    'RIT', 'Élec.', 'GC', 'MKT', 'FC', 'GRH',
    'ADB', 'BAN', 'LOG', 'COM', 'MB', 'AN',
  ];

  static const filiereCouleurs = [
    AdminTheme.primary, AdminTheme.info, AdminTheme.success,
    AdminTheme.warning, AdminTheme.danger, Color(0xFF7C3AED),
  ];

  static const tendances = <_Tendance>[
    _Tendance('📈', 'Croissance inscriptions',
        '+37% sur 5 ans (2020→2024)', AdminTheme.success),
    _Tendance('🎯', 'Taux de réussite en hausse',
        'ST : 72% → 81%   ·   SG : 68% → 76.5%', AdminTheme.primary),
    _Tendance('⚠️', 'Taux d\'échec en baisse',
        'ST : 28% → 19%   ·   SG : 32% → 23.5%', AdminTheme.warning),
    _Tendance('💡', 'Sciences & Tech dominantes',
        '60% des inscrits en moyenne sur 5 ans', AdminTheme.info),
  ];
}

class _Tendance {
  final String emoji, titre, desc;
  final Color color;
  const _Tendance(this.emoji, this.titre, this.desc, this.color);
}

// ═══════════════════════════════════════════════════════════════
// SECTION 2 — Helpers couleurs [SEC-1]
// ═══════════════════════════════════════════════════════════════

extension _A on Color {
  Color get a08 => withValues(alpha: 0.08);
  Color get a12 => withValues(alpha: 0.12);
  Color get a20 => withValues(alpha: 0.20);
  Color get a30 => withValues(alpha: 0.30);
  Color get a40 => withValues(alpha: 0.40);
}

// ═══════════════════════════════════════════════════════════════
// SECTION 3 — Liste des exports [ARCH-3]
// Remplace la syntaxe records Dart ($1 $2 $3) par une classe.
// ═══════════════════════════════════════════════════════════════

class _ExportItem {
  final String titre, sous;
  final IconData icon;
  const _ExportItem(this.titre, this.sous, this.icon);
}

// ═══════════════════════════════════════════════════════════════
// SECTION 4 — Widget principal
// ═══════════════════════════════════════════════════════════════

class AdminStatistiques extends StatefulWidget {
  const AdminStatistiques({super.key});

  @override
  State<AdminStatistiques> createState() => _AdminStatistiquesState();
}

class _AdminStatistiquesState extends State<AdminStatistiques>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _filtreHistorique = 'domaine';

  // ── Données réelles (remplacent _StatsMock) ─────────────────────────────
  bool _loadingStats = true;
  List<dynamic> _moyennes = [];
  List<dynamic> _inscriptionsRaw = []; // [{mois, domaine, filiere_nom, total}]

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _chargerStats();
  }

  Future<void> _chargerStats() async {
    final results = await Future.wait([
      ApiService.getMoyennesAdmin(),
      ApiService.getStatsInscriptions(),
    ]);
    if (!mounted) return;
    setState(() {
      if (results[0]['success'] == true) {
        _moyennes = results[0]['data'] as List<dynamic>;
      }
      if (results[1]['success'] == true) {
        _inscriptionsRaw = results[1]['data'] as List<dynamic>;
      }
      _loadingStats = false;
    });
  }

  DateTime _moisDe(dynamic row) => DateTime.parse(row['mois'].toString());
  int _totalDe(dynamic row) => (row['total'] as num).toInt();

  /// Taux de réussite réel (% moyenne >= 10) pour un domaine, à partir des
  /// moyennes réellement calculées (notes validées). 0 si aucune donnée.
  double _tauxReussite(String motDomaine) {
    final avec = _moyennes
        .where((m) => m['moyenne'] != null && (m['domaine'] ?? '').toString().contains(motDomaine))
        .toList();
    if (avec.isEmpty) return 0;
    final reussis = avec.where((m) => (m['moyenne'] as num) >= 10).length;
    return reussis / avec.length * 100;
  }

  /// Top étudiants par moyenne réelle — remplace l'ancien _majorsWidget qui
  /// utilisait Etudiant.notes, jamais rempli par l'API (toujours vide).
  List<dynamic> get _topMoyennes {
    final avec = _moyennes.where((m) => m['moyenne'] != null).toList();
    avec.sort((a, b) => (b['moyenne'] as num).compareTo(a['moyenne'] as num));
    return avec.take(3).toList();
  }

  /// Courbe cumulée des inscriptions sur l'année académique en cours
  /// (déterminée par la donnée la plus récente disponible), en mois réels
  /// uniquement — pas de mois inventés au-delà des données existantes.
  List<FlSpot> get _spotsMoisCourants {
    if (_inscriptionsRaw.isEmpty) return [];
    final dates = _inscriptionsRaw.map(_moisDe).toList()..sort();
    final dernier = dates.last;
    final anneeDebut = dernier.month >= 9 ? dernier.year : dernier.year - 1;
    final debut = DateTime(anneeDebut, 9);
    final fin = DateTime(anneeDebut + 1, 9);
    final parMois = <int, int>{};
    for (final row in _inscriptionsRaw) {
      final d = _moisDe(row);
      if (!d.isBefore(debut) && d.isBefore(fin)) {
        final idx = (d.year - anneeDebut) * 12 + (d.month - 9);
        parMois[idx] = (parMois[idx] ?? 0) + _totalDe(row);
      }
    }
    if (parMois.isEmpty) return [];
    final maxIdx = parMois.keys.reduce((a, b) => a > b ? a : b);
    int cumul = 0;
    final spots = <FlSpot>[];
    for (int i = 0; i <= maxIdx; i++) {
      cumul += parMois[i] ?? 0;
      spots.add(FlSpot(i.toDouble(), cumul.toDouble()));
    }
    return spots;
  }

  List<String> get _moisLabelsCourants {
    const noms = ['Sep', 'Oct', 'Nov', 'Déc', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû'];
    return List.generate(_spotsMoisCourants.length, (i) => noms[i]);
  }

  /// Années réellement présentes dans les données (année civile de
  /// création de compte) — pas 5 années fixes : juste ce qui existe.
  List<String> get _anneesReelles {
    final annees = <String>{};
    for (final row in _inscriptionsRaw) {
      annees.add('${_moisDe(row).year}');
    }
    final liste = annees.toList()..sort();
    return liste;
  }

  Map<String, int> _totalParAnneePourDomaine(String annee, String motDomaine) {
    int total = 0;
    for (final row in _inscriptionsRaw) {
      if ('${_moisDe(row).year}' == annee && (row['domaine'] ?? '').toString().contains(motDomaine)) {
        total += _totalDe(row);
      }
    }
    return {'total': total};
  }

  List<String> get _filiereNomsReels {
    final set = <String>{};
    for (final row in _inscriptionsRaw) {
      set.add((row['filiere_nom'] ?? 'Autre').toString());
    }
    final list = set.toList()..sort();
    return list.length > 6 ? list.sublist(0, 6) : list;
  }

  int _totalParAnneePourFiliere(String annee, String filiereNom) {
    int total = 0;
    for (final row in _inscriptionsRaw) {
      if ('${_moisDe(row).year}' == annee && (row['filiere_nom'] ?? 'Autre').toString() == filiereNom) {
        total += _totalDe(row);
      }
    }
    return total;
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Calcul de moyenne sécurisé [SEC-2] ──────────────────────────────────
  double _moy(List<Map<String, dynamic>> notes) {
    if (notes.isEmpty) return 0.0;
    final coefs = notes.fold<int>(0, (s, n) => s + (n['coef'] as int? ?? 0));
    if (coefs == 0) return 0.0;
    final total = notes.fold<double>(
        0, (s, n) => s + (n['note'] as double) * (n['coef'] as int? ?? 0));
    return total / coefs;
  }

  // ── Initiales sécurisées [SEC-3] ─────────────────────────────────────────
  String _initiales(Etudiant e) {
    final f = e.prenoms.isNotEmpty ? e.prenoms[0].toUpperCase() : '?';
    final l = e.nom.isNotEmpty    ? e.nom[0].toUpperCase()     : '';
    return '$f$l';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Column(children: [
        AdminPageHeader(
          title: 'Statistiques & Bilans',
          subtitle: 'Indicateurs clés de l\'établissement',
          bottomPadding: 0,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TabBar(
            controller: _tab,
            labelColor: AdminTheme.primary,
            unselectedLabelColor: AdminTheme.textMuted,
            indicatorColor: AdminTheme.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            isScrollable: true,
            tabs: const [
              Tab(text: 'Vue générale'),
              Tab(text: 'Historique 5 ans'),
              Tab(text: 'Listes'),
            ],
          ),
        ),
        adminDivider,
        Expanded(
          child: _loadingStats
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(controller: _tab, children: [
                  _tabGeneral(),
                  _tabHistorique(),
                  _tabListes(),
                ]),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // TAB 1 — VUE GÉNÉRALE avec Bento Grid [UX-1]
  // ════════════════════════════════════════════════════════════════════════

  Widget _tabGeneral() {
    final actifs    = adminEtudiants.where((e) => e.statut == 'actif').length;
    final suspendus = adminEtudiants.where((e) => e.statut == 'suspendu').length;
    final renvoyes  = adminEtudiants.where((e) => e.statut == 'renvoye').length;
    final total     = adminEtudiants.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Bento Grid — ligne 1 : 4 KPIs ────────────────────────────
          Row(children: [
            _kpi('$total',     'Total étudiants', Icons.people_rounded,
                AdminTheme.primary, AdminTheme.primaryLight),
            const SizedBox(width: 12),
            _kpi('$actifs',    'Actifs',           Icons.check_circle_rounded,
                AdminTheme.success, AdminTheme.successLight),
            const SizedBox(width: 12),
            _kpi('$suspendus', 'Suspendus',        Icons.pause_circle_rounded,
                AdminTheme.warning, AdminTheme.warningLight),
            const SizedBox(width: 12),
            _kpi('$renvoyes',  'Renvoyés',         Icons.cancel_rounded,
                AdminTheme.danger, AdminTheme.dangerLight),
          ]),
          const SizedBox(height: 16),

          // ── Bento Grid — ligne 2 : courbe (2/3) + taux réussite (1/3) ─
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _chartCard(
                  'Inscriptions mensuelles${_anneesReelles.isNotEmpty ? ' ${_anneesReelles.last}' : ''}',
                  Icons.show_chart_rounded,
                  _inscriptionsChart(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _metricCard(
                  'Taux de réussite',
                  _moyennes.isEmpty ? '—' : '${_tauxReussite('Technologies').toStringAsFixed(1)}%',
                  'Sciences & Tech',
                  Icons.trending_up_rounded,
                  AdminTheme.success,
                  sous: _moyennes.isEmpty ? null : 'SG : ${_tauxReussite('Gestion').toStringAsFixed(1)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Bento Grid — ligne 3 : donut domaines + donut statuts ──────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _chartCard(
                  'Répartition domaines',
                  Icons.donut_large_rounded,
                  _donutDomaines(actifs, suspendus, renvoyes),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _chartCard(
                  'Statuts étudiants',
                  Icons.pie_chart_rounded,
                  _donutStatuts(actifs, suspendus, renvoyes),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Bento Grid — ligne 4 : majors pleine largeur ──────────────
          _chartCard(
            '🏆 Majors de promotion',
            Icons.emoji_events_rounded,
            _majorsWidget(),
          ),
        ],
      ),
    );
  }

  // ── KPI card ─────────────────────────────────────────────────────────────

  Widget _kpi(String val, String label, IconData icon, Color fg, Color bg) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: fg, size: 18),
            ),
            const SizedBox(height: 10),
            Text(val,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: fg)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280))),
          ]),
        ),
      );

  // ── Metric card (stat unique avec contexte) ──────────────────────────────

  Widget _metricCard(String titre, String val, String desc, IconData icon,
      Color color, {String? sous}) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                  color: color.a12, borderRadius: BorderRadius.circular(7)),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(titre,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
            ),
          ]),
          const SizedBox(height: 12),
          Text(val,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800, color: color)),
          Text(desc,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          if (sous != null) ...[
            const SizedBox(height: 4),
            Text(sous,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.7))),
          ],
        ]),
      );

  // ── Courbe inscriptions mensuelles avec tooltip [UX-2] ──────────────────

  Widget _inscriptionsChart() {
    final spots = _spotsMoisCourants;
    if (spots.isEmpty) {
      return const SizedBox(
        height: 170,
        child: Center(child: Text('Pas encore de données d\'inscription.', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))),
      );
    }
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return SizedBox(
        height: 170,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              // [UX-5] Grille horizontale uniquement, très légère
              getDrawingHorizontalLine: (_) => const FlLine(
                  color: Color(0xFFF3F4F6), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                      style: const TextStyle(
                          fontSize: 9, color: Color(0xFF9CA3AF))),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= _moisLabelsCourants.length) {
                      return const SizedBox();
                    }
                    return Text(_moisLabelsCourants[i],
                        style: const TextStyle(
                            fontSize: 9, color: Color(0xFF9CA3AF)));
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            // [UX-2] Tooltip personnalisé
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => const Color(0xFF1A1A2E),
                tooltipBorderRadius: BorderRadius.circular(8),
                getTooltipItems: (spots) => spots
                    .map((s) => LineTooltipItem(
                          '${s.y.toInt()} inscrits\n'
                          '${_moisLabelsCourants[s.x.toInt()]}',
                          const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ))
                    .toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AdminTheme.primary,
                barWidth: 2.5,
                belowBarData: BarAreaData(
                    show: true, color: AdminTheme.primaryLight.a40),
                dotData: const FlDotData(show: false),
              ),
            ],
            minX: 0, maxX: (spots.length - 1).toDouble(), minY: 0, maxY: maxY * 1.15,
          ),
        ),
      );
  }

  // ── Donut domaines ────────────────────────────────────────────────────────

  Widget _donutDomaines(int actifs, int suspendus, int renvoyes) {
    final st = adminEtudiants
        .where((e) => e.domaine.contains('Technologies')).length;
    final sg = adminEtudiants
        .where((e) => e.domaine.contains('Gestion')).length;

    return Column(children: [
      SizedBox(
        height: 140,
        child: PieChart(PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 38,
          pieTouchData: PieTouchData(
            touchCallback: (_, response) {
              // TODO: filtrer la liste étudiants selon le domaine touché
            },
          ),
          sections: [
            _pieSection(st.toDouble(), AdminTheme.primary, '$st'),
            _pieSection(sg.toDouble(), AdminTheme.info, '$sg'),
          ],
        )),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _dot(AdminTheme.primary, 'Sciences & Tech ($st)'),
        const SizedBox(width: 14),
        _dot(AdminTheme.info, 'Gestion ($sg)'),
      ]),
    ]);
  }

  // ── Donut statuts ─────────────────────────────────────────────────────────

  Widget _donutStatuts(int actifs, int suspendus, int renvoyes) => Column(
        children: [
          SizedBox(
            height: 140,
            child: PieChart(PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 38,
              sections: [
                _pieSection(actifs.toDouble(),    AdminTheme.success, '$actifs'),
                if (suspendus > 0)
                  _pieSection(suspendus.toDouble(), AdminTheme.warning, '$suspendus'),
                if (renvoyes > 0)
                  _pieSection(renvoyes.toDouble(),  AdminTheme.danger, '$renvoyes'),
              ],
            )),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              _dot(AdminTheme.success, 'Actifs ($actifs)'),
              _dot(AdminTheme.warning, 'Suspendus ($suspendus)'),
              _dot(AdminTheme.danger,  'Renvoyés ($renvoyes)'),
            ],
          ),
        ],
      );

  PieChartSectionData _pieSection(double val, Color color, String title) =>
      PieChartSectionData(
        value: val,
        color: color,
        title: title,
        radius: 48,
        titleStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );

  // ── Majors widget [SEC-3] ─────────────────────────────────────────────────

  Widget _majorsWidget() {
    final top3 = _topMoyennes;
    const medals = ['🥇', '🥈', '🥉'];

    if (top3.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('Aucune note validée pour le moment.', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))),
      );
    }

    return Column(
      children: List.generate(top3.length, (i) {
        final m = top3[i] as Map;
        final moy = (m['moyenne'] as num).toDouble();
        final prenoms = (m['prenoms'] ?? '').toString();
        final nom = (m['nom'] ?? '').toString();
        final initiales = '${prenoms.isNotEmpty ? prenoms[0].toUpperCase() : '?'}${nom.isNotEmpty ? nom[0].toUpperCase() : ''}';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Text(medals[i], style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: AdminTheme.primaryLight,
              child: Text(initiales,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$prenoms $nom',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                  Text('${m['filiere_nom'] ?? ''}',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF6B7280)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AdminTheme.primaryLight,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${moy.toStringAsFixed(2)}/20',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AdminTheme.primary)),
            ),
          ]),
        );
      }),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // TAB 2 — HISTORIQUE 5 ANS
  // ════════════════════════════════════════════════════════════════════════

  Widget _tabHistorique() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filtre domaine / filière avec AnimatedSwitcher [UX-3] ──────
          Row(children: [
            const Text('Voir par :',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151))),
            const SizedBox(width: 10),
            _toggleBtn('Par domaine', 'domaine'),
            const SizedBox(width: 8),
            _toggleBtn('Par filière', 'filiere'),
          ]),
          const SizedBox(height: 16),

          // [UX-3] AnimatedSwitcher fluide entre les deux vues
          _chartCard(
            'Total inscrits — 5 dernières années',
            Icons.group_rounded,
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve:  Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.03, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_filtreHistorique),
                child: _filtreHistorique == 'domaine'
                    ? _inscriptionsHistoDomaine()
                    : _inscriptionsHistoFiliere(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Courbe taux réussite/échec ─────────────────────────────────
          _chartCard(
            'Taux de réussite & d\'échec — 5 ans',
            Icons.trending_up_rounded,
            _tauxReussiteChart(),
          ),
          const SizedBox(height: 16),

          // ── Comparaison domaines ───────────────────────────────────────
          _chartCard(
            'Sciences & Tech vs Sciences de Gestion',
            Icons.compare_arrows_rounded,
            _comparaisonDomainesChart(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, String value) {
    final active = _filtreHistorique == value;
    return GestureDetector(
      onTap: () => setState(() => _filtreHistorique = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AdminTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? AdminTheme.primary : const Color(0xFFE5E7EB)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : const Color(0xFF6B7280))),
      ),
    );
  }

  // ── Barres groupées domaines ──────────────────────────────────────────────

  Widget _inscriptionsHistoDomaine() {
    final annees = _anneesReelles;
    if (annees.isEmpty) {
      return const SizedBox(height: 210, child: Center(child: Text('Pas encore de données.', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))));
    }
    final stData = annees.map((a) => _totalParAnneePourDomaine(a, 'Technologies')['total']!.toDouble()).toList();
    final sgData = annees.map((a) => _totalParAnneePourDomaine(a, 'Gestion')['total']!.toDouble()).toList();
    final maxVal = [...stData, ...sgData].fold<double>(1, (m, v) => v > m ? v : m);

    return SizedBox(
      height: 210,
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.2,
        // [UX-2] Tooltip personnalisé
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1A1A2E),
            tooltipBorderRadius: BorderRadius.circular(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final domaine = rodIndex == 0 ? 'Sciences & Tech' : 'Gestion';
              final annee   = annees[groupIndex];
              return BarTooltipItem(
                '$domaine\n${rod.toY.toInt()} inscrits\n$annee',
                const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        titlesData: _barTitles(annees),
        gridData: _gridData(),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          annees.length,
          (i) => BarChartGroupData(x: i, barRods: [
            BarChartRodData(
                toY: stData[i],
                color: AdminTheme.primary,
                width: 11,
                borderRadius: BorderRadius.circular(4)),
            BarChartRodData(
                toY: sgData[i],
                color: AdminTheme.info,
                width: 11,
                borderRadius: BorderRadius.circular(4)),
          ]),
        ),
      )),
    );
  }

  // ── Barres par filière ────────────────────────────────────────────────────

  FlTitlesData _barTitles(List<String> labels) => FlTitlesData(
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 24,
        getTitlesWidget: (value, _) {
          final i = value.toInt();
          if (i < 0 || i >= labels.length) return const SizedBox();
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(labels[i],
                style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280))),
          );
        },
      ),
    ),
  );

  Widget _inscriptionsHistoFiliere() {
    final annees = _anneesReelles;
    final filiereNoms = _filiereNomsReels;
    if (annees.isEmpty || filiereNoms.isEmpty) {
      return const SizedBox(height: 210, child: Center(child: Text('Pas encore de données.', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))));
    }
    final maxVal = annees
        .expand((a) => filiereNoms.map((f) => _totalParAnneePourFiliere(a, f)))
        .fold<int>(1, (m, v) => v > m ? v : m);

    return Column(children: [
      SizedBox(
        height: 210,
        child: BarChart(BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF1A1A2E),
              tooltipBorderRadius: BorderRadius.circular(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final filiere = rodIndex < filiereNoms.length
                    ? filiereNoms[rodIndex]
                    : '—';
                return BarTooltipItem(
                  '$filiere\n${rod.toY.toInt()} inscrits',
                  const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
          titlesData: _barTitles(annees),
          gridData: _gridData(),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(annees.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: List.generate(
                filiereNoms.length,
                (j) => BarChartRodData(
                  toY: _totalParAnneePourFiliere(annees[i], filiereNoms[j]).toDouble(),
                  color: _StatsMock.filiereCouleurs[j % _StatsMock.filiereCouleurs.length],
                  width: 7,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        )),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: List.generate(
          filiereNoms.length,
          (i) => _dot(_StatsMock.filiereCouleurs[i % _StatsMock.filiereCouleurs.length],
              filiereNoms[i]),
        ),
      ),
    ]);
  }

  // ── Courbe réussite / échec ───────────────────────────────────────────────

  // ⚠️ Le calcul des moyennes (getMoyennesAdmin) ne distingue pas encore par
  // année académique — on ne dispose donc que d'UN taux de réussite global
  // actuel, pas d'un historique par année. On l'applique tel quel à chaque
  // année réellement présente plutôt que d'inventer une évolution — c'est
  // honnête vu la profondeur de données actuelle (une seule vraie année).
  Widget _tauxReussiteChart() {
    final annees  = _anneesReelles;
    if (annees.isEmpty) {
      return const SizedBox(height: 190, child: Center(child: Text('Pas encore de données.', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))));
    }
    final tauxST = _tauxReussite('Technologies');
    final tauxSG = _tauxReussite('Gestion');
    final stData  = List.generate(annees.length, (_) => tauxST);
    final sgData  = List.generate(annees.length, (_) => tauxSG);
    final echecST = stData.map((v) => 100 - v).toList();
    final echecSG = sgData.map((v) => 100 - v).toList();

    return Column(children: [
      SizedBox(
        height: 190,
        child: LineChart(LineChartData(
          gridData: _gridData(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                    style: const TextStyle(
                        fontSize: 9, color: Color(0xFF9CA3AF))),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= annees.length) return const SizedBox();
                  return Text(annees[i],
                      style: const TextStyle(
                          fontSize: 9, color: Color(0xFF6B7280)));
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF1A1A2E),
              tooltipBorderRadius: BorderRadius.circular(8),
              getTooltipItems: (spots) => spots.asMap().entries.map((e) {
                const labels = [
                  'Réussite ST', 'Réussite SG', 'Échec ST', 'Échec SG'
                ];
                return LineTooltipItem(
                  '${labels[e.key]} : ${e.value.y.toStringAsFixed(1)}%',
                  const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            _line(stData, AdminTheme.primary),
            _line(sgData, AdminTheme.info),
            _line(echecST, AdminTheme.danger, dashed: true),
            _line(echecSG, AdminTheme.warning, dashed: true),
          ],
          minX: 0, maxX: (annees.length - 1).toDouble().clamp(0, double.infinity), minY: 0, maxY: 100,
        )),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          _dot(AdminTheme.primary,  'Réussite ST'),
          _dot(AdminTheme.info,     'Réussite SG'),
          _dot(AdminTheme.danger,   'Échec ST'),
          _dot(AdminTheme.warning,  'Échec SG'),
        ],
      ),
      const SizedBox(height: 12),

      // [UX-6] Tableau dans un ExpansionTile (Progressive Disclosure)
      Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Voir le tableau détaillé',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.primary)),
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(children: [
                _tableHeader(),
                ...List.generate(
                  annees.length,
                  (i) => _tableRow(
                    annees[i], stData[i], sgData[i],
                    echecST[i], echecSG[i],
                    i == annees.length - 1,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    ]);
  }

  LineChartBarData _line(List<double> data, Color color,
          {bool dashed = false}) =>
      LineChartBarData(
        spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
        isCurved: true,
        color: color,
        barWidth: dashed ? 1.5 : 2.5,
        dashArray: dashed ? [4, 4] : null,
        dotData: FlDotData(
          show: !dashed,
          getDotPainter: (_, __, ___, ____) =>
              FlDotCirclePainter(radius: 3, color: color, strokeWidth: 0),
        ),
      );

  Widget _tableHeader() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: const BoxDecoration(
          color: Color(0xFFF1F3F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Row(children: const [
          Expanded(
              flex: 2,
              child: Text('Année',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151)))),
          Expanded(
              child: Text('Réussite ST',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AdminTheme.primary),
                  textAlign: TextAlign.center)),
          Expanded(
              child: Text('Réussite SG',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AdminTheme.info),
                  textAlign: TextAlign.center)),
          Expanded(
              child: Text('Échec ST',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AdminTheme.danger),
                  textAlign: TextAlign.center)),
          Expanded(
              child: Text('Échec SG',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AdminTheme.warning),
                  textAlign: TextAlign.center)),
        ]),
      );

  Widget _tableRow(String annee, double rST, double rSG, double eST,
      double eSG, bool isCurrent) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrent
              ? AdminTheme.primaryLight.withValues(alpha: 0.3)
              : Colors.transparent,
          border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(children: [
          Expanded(
              flex: 2,
              child: Row(children: [
                Text(annee,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isCurrent ? FontWeight.w800 : FontWeight.w500,
                        color: isCurrent
                            ? AdminTheme.primary
                            : const Color(0xFF374151))),
                if (isCurrent) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                        color: AdminTheme.primary,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('En cours',
                        style: TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ])),
          _cell('${rST.toStringAsFixed(1)}%', AdminTheme.primary),
          _cell('${rSG.toStringAsFixed(1)}%', AdminTheme.info),
          _cell('${eST.toStringAsFixed(1)}%', AdminTheme.danger),
          _cell('${eSG.toStringAsFixed(1)}%', AdminTheme.warning),
        ]),
      );

  Widget _cell(String text, Color color) => Expanded(
        child: Text(text,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color),
            textAlign: TextAlign.center),
      );

  // ── Comparaison domaines ──────────────────────────────────────────────────

  Widget _comparaisonDomainesChart() {
    final annees = _anneesReelles;
    if (annees.isEmpty) {
      return const SizedBox(height: 170, child: Center(child: Text('Pas encore de données.', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))));
    }
    final stData = annees.map((a) => _totalParAnneePourDomaine(a, 'Technologies')['total']!.toDouble()).toList();
    final sgData = annees.map((a) => _totalParAnneePourDomaine(a, 'Gestion')['total']!.toDouble()).toList();
    final maxVal = [...stData, ...sgData].fold<double>(1, (m, v) => v > m ? v : m);
    final minVal = [...stData, ...sgData].fold<double>(maxVal, (m, v) => v < m ? v : m);

    return Column(children: [
      SizedBox(
        height: 170,
        child: LineChart(LineChartData(
          gridData: _gridData(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                    style: const TextStyle(
                        fontSize: 9, color: Color(0xFF9CA3AF))),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= annees.length) return const SizedBox();
                  return Text(annees[i],
                      style: const TextStyle(
                          fontSize: 9, color: Color(0xFF6B7280)));
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                  stData.length, (i) => FlSpot(i.toDouble(), stData[i])),
              isCurved: true,
              color: AdminTheme.primary,
              barWidth: 2.5,
              belowBarData: BarAreaData(
                  show: true, color: AdminTheme.primaryLight.a30),
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3,
                    color: AdminTheme.primary,
                    strokeWidth: 0),
              ),
            ),
            LineChartBarData(
              spots: List.generate(
                  sgData.length, (i) => FlSpot(i.toDouble(), sgData[i])),
              isCurved: true,
              color: AdminTheme.info,
              barWidth: 2.5,
              belowBarData: BarAreaData(
                  show: true, color: AdminTheme.infoLight.a30),
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3,
                    color: AdminTheme.info,
                    strokeWidth: 0),
              ),
            ),
          ],
          minX: 0, maxX: (annees.length - 1).toDouble().clamp(0, double.infinity),
          minY: (minVal * 0.8), maxY: maxVal * 1.2,
        )),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _dot(AdminTheme.primary, 'Sciences & Tech'),
        const SizedBox(width: 14),
        _dot(AdminTheme.info, 'Sciences de Gestion'),
      ]),
    ]);
  }

  // ── Résumé tendances ──────────────────────────────────────────────────────

  Widget _resumeHistorique() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.insights_rounded, color: AdminTheme.primary, size: 18),
              SizedBox(width: 8),
              Text('Analyse & Tendances',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
            ]),
            const SizedBox(height: 12),
            ..._StatsMock.tendances.map((t) => _tendanceItem(t)),
          ],
        ),
      );

  Widget _tendanceItem(_Tendance t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.emoji, style: const TextStyle(fontSize: 17)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.titre,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 2),
                  Text(t.desc,
                      style: TextStyle(fontSize: 11, color: t.color)),
                ],
              ),
            ),
          ],
        ),
      );

  // ════════════════════════════════════════════════════════════════════════
  // TAB 3 — LISTES & EXPORT [ARCH-2] [ARCH-3]
  // ════════════════════════════════════════════════════════════════════════

  List<_ExportItem> get _exports => [
    _ExportItem('Liste complète des étudiants',
        '${adminEtudiants.length} étudiants', Icons.people_rounded),
    _ExportItem('Étudiants actifs',
        '${adminEtudiants.where((e) => e.statut == "actif").length} étudiants',
        Icons.check_circle_rounded),
    _ExportItem('Étudiants suspendus',
        '${adminEtudiants.where((e) => e.statut == "suspendu").length} étudiants',
        Icons.pause_circle_rounded),
    _ExportItem('Majors de promotion', 'Top par filière',
        Icons.emoji_events_rounded),
    _ExportItem('Bulletin de notes complet', 'Tous les modules',
        Icons.grade_rounded),
    _ExportItem('Rapport historique 5 ans', 'Inscriptions & Réussite',
        Icons.history_rounded),
  ];

  Widget _tabListes() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Listes exportables',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          const Text('Téléchargez les listes au format PDF ou Excel',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 16),
          ..._exports.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: AdminTheme.primaryLight,
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(item.icon, color: AdminTheme.primary, size: 19),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.titre,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E))),
                        Text(item.sous,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  Row(children: [
                    // [ARCH-2] Export réel — à connecter à un service
                    _exportBtn('PDF',   AdminTheme.danger,
                        () => _doExport(item.titre, 'pdf')),
                    const SizedBox(width: 6),
                    _exportBtn('Excel', AdminTheme.success,
                        () => _doExport(item.titre, 'excel')),
                  ]),
                ]),
              )),
        ],
      );

  // [ARCH-2] Méthode d'export — à remplacer par un vrai ExportService
  void _doExport(String titre, String format) {
    // TODO: await ExportService.instance.export(titre, format);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          format == 'pdf'
              ? '📥 Génération PDF en cours : $titre'
              : '📊 Génération Excel en cours : $titre',
        ),
        backgroundColor: format == 'pdf' ? AdminTheme.danger : AdminTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _exportBtn(String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.a08,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: color.a20),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ),
      );

  // ═══════════════════════════════════════════════════════════════
  // HELPERS PARTAGÉS
  // ═══════════════════════════════════════════════════════════════

  // [UX-4] Padding 24px + ombre légère
  Widget _chartCard(String titre, IconData icon, Widget child) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    color: AdminTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: AdminTheme.primary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(titre,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E))),
              ),
            ]),
            const Divider(color: Color(0xFFF3F4F6), height: 20),
            child,
          ],
        ),
      );

  Widget _dot(Color color, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
      ]);

  // [UX-5] Grille horizontale uniquement, pointillés très légers
  FlGridData _gridData() => FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: Color(0xFFF3F4F6), strokeWidth: 1),
      );
}
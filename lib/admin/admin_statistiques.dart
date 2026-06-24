import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_etudiants.dart';

class AdminStatistiques extends StatefulWidget {
  const AdminStatistiques({super.key});
  @override State<AdminStatistiques> createState() => _AdminStatistiquesState();
}

class _AdminStatistiquesState extends State<AdminStatistiques>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _filtreHistorique = 'domaine'; // domaine | filiere

  // ── Données historiques simulées 5 ans ───────────────────────────────
  final Map<String, List<int>> _inscriptionsParAnnee = {
    '2020-21': [120, 80],   // [ST, SG]
    '2021-22': [145, 95],
    '2022-23': [162, 108],
    '2023-24': [185, 120],
    '2024-25': [148, 99],   // année en cours
  };

  final Map<String, List<double>> _tauxReussiteParAnnee = {
    '2020-21': [72.0, 68.0],  // [ST%, SG%]
    '2021-22': [74.5, 70.0],
    '2022-23': [76.0, 72.5],
    '2023-24': [78.5, 74.0],
    '2024-25': [81.0, 76.5],
  };

  final Map<String, List<int>> _inscriptionsParFiliere = {
    '2020-21': [35, 25, 20, 40, 28, 22, 15, 18, 10, 12, 8, 6],
    '2021-22': [42, 30, 24, 46, 32, 26, 18, 20, 12, 14, 9, 8],
    '2022-23': [48, 34, 27, 52, 36, 28, 22, 24, 14, 16, 10, 9],
    '2023-24': [55, 38, 30, 58, 40, 32, 24, 26, 16, 18, 11, 10],
    '2024-25': [38, 24, 15, 31, 19, 12, 22, 19, 10, 14, 8, 6],
  };

  final _filiereLabels = [
    'RIT', 'Élec.', 'GC', 'MKT', 'FC', 'GRH',
    'ADB', 'BAN', 'LOG', 'COM', 'MB', 'AN',
  ];

  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Statistiques & Bilans', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
            const Text('Indicateurs clés de l\'établissement',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            TabBar(
              controller: _tab,
              labelColor: AdminTheme.primary,
              unselectedLabelColor: const Color(0xFF9CA3AF),
              indicatorColor: AdminTheme.primary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              isScrollable: true,
              tabs: const [
                Tab(text: 'Vue générale'),
                Tab(text: 'Historique 5 ans'),
                Tab(text: 'Listes'),
              ],
            ),
          ]),
        ),
        Container(height: 1, color: const Color(0xFFE5E7EB)),
        Expanded(child: TabBarView(controller: _tab, children: [
          _tabGeneral(),
          _tabHistorique(),
          _tabListes(),
        ])),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // TAB 1 — VUE GÉNÉRALE
  // ════════════════════════════════════════════════════════════════════════
  Widget _tabGeneral() {
    final actifs    = adminEtudiants.where((e) => e.statut == 'actif').length;
    final suspendus = adminEtudiants.where((e) => e.statut == 'suspendu').length;
    final renvoyes  = adminEtudiants.where((e) => e.statut == 'renvoye').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── KPI row compact (style MaisonPlus) ─────────────────────────
        Row(children: [
          _kpi('${adminEtudiants.length}', 'Total', Icons.people_rounded,
              AdminTheme.primary, AdminTheme.primaryLight),
          const SizedBox(width: 10),
          _kpi('$actifs', 'Actifs', Icons.check_circle_rounded,
              AdminTheme.success, AdminTheme.successLight),
          const SizedBox(width: 10),
          _kpi('$suspendus', 'Suspendus', Icons.pause_circle_rounded,
              AdminTheme.warning, AdminTheme.warningLight),
          const SizedBox(width: 10),
          _kpi('$renvoyes', 'Renvoyés', Icons.cancel_rounded,
              AdminTheme.danger, AdminTheme.dangerLight),
        ]),
        const SizedBox(height: 16),

        // ── Courbe inscriptions année en cours ─────────────────────────
        _chartCard('Inscriptions 2024-2025 (mensuel)',
            Icons.show_chart_rounded, _inscriptionsChart()),
        const SizedBox(height: 14),

        // ── Donut répartition domaines ─────────────────────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _chartCard('Répartition domaines',
              Icons.donut_large_rounded,
              _donutDomaines(actifs, suspendus, renvoyes))),
          const SizedBox(width: 14),
          Expanded(child: _chartCard('Statuts étudiants',
              Icons.pie_chart_rounded,
              _donutStatuts(actifs, suspendus, renvoyes))),
        ]),
        const SizedBox(height: 14),

        // ── Majors ─────────────────────────────────────────────────────
        _chartCard('🏆 Majors de promotion',
            Icons.emoji_events_rounded, _majorsWidget()),
      ]),
    );
  }

  Widget _kpi(String val, String label, IconData icon, Color fg, Color bg) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 6, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 30, height: 30,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: fg, size: 16)),
          const SizedBox(height: 8),
          Text(val, style: TextStyle(fontSize: 22,
              fontWeight: FontWeight.w800, color: fg)),
          Text(label, style: const TextStyle(fontSize: 11,
              fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        ])));

  Widget _inscriptionsChart() => SizedBox(height: 160, child: LineChart(
    LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0xFFE5E7EB), strokeWidth: 1)),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
            getTitlesWidget: (v, _) {
              const m = ['Sep','Oct','Nov','Déc','Jan','Fév','Mar','Avr','Mai'];
              final i = v.toInt();
              if (i < 0 || i >= m.length) return const SizedBox();
              return Text(m[i], style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF)));
            })),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [LineChartBarData(
        spots: const [FlSpot(0,180), FlSpot(1,195), FlSpot(2,210), FlSpot(3,215),
          FlSpot(4,225), FlSpot(5,230), FlSpot(6,238), FlSpot(7,245), FlSpot(8,247)],
        isCurved: true, color: AdminTheme.primary, barWidth: 2.5,
        belowBarData: BarAreaData(show: true,
            color: AdminTheme.primaryLight.withOpacity(0.4)),
        dotData: const FlDotData(show: false))],
      minX: 0, maxX: 8, minY: 150, maxY: 270,
    )));

  Widget _donutDomaines(int actifs, int suspendus, int renvoyes) {
    final st = adminEtudiants.where((e) => e.domaine.contains('Technologies')).length;
    final sg = adminEtudiants.where((e) => e.domaine.contains('Gestion')).length;
    return Column(children: [
      SizedBox(height: 130, child: PieChart(PieChartData(
        sectionsSpace: 3, centerSpaceRadius: 35,
        sections: [
          PieChartSectionData(value: st.toDouble(), color: AdminTheme.primary,
              title: '$st', radius: 45, titleStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(value: sg.toDouble(), color: AdminTheme.info,
              title: '$sg', radius: 45, titleStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
        ]))),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _dot(AdminTheme.primary, 'Sciences & Tech ($st)'),
        const SizedBox(width: 12),
        _dot(AdminTheme.info, 'Gestion ($sg)'),
      ]),
    ]);
  }

  Widget _donutStatuts(int actifs, int suspendus, int renvoyes) => Column(children: [
    SizedBox(height: 130, child: PieChart(PieChartData(
      sectionsSpace: 3, centerSpaceRadius: 35,
      sections: [
        PieChartSectionData(value: actifs.toDouble(), color: AdminTheme.success,
            title: '$actifs', radius: 45, titleStyle: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
        if (suspendus > 0) PieChartSectionData(value: suspendus.toDouble(),
            color: AdminTheme.warning, title: '$suspendus', radius: 45,
            titleStyle: const TextStyle(fontSize: 11,
                fontWeight: FontWeight.bold, color: Colors.white)),
        if (renvoyes > 0) PieChartSectionData(value: renvoyes.toDouble(),
            color: AdminTheme.danger, title: '$renvoyes', radius: 45,
            titleStyle: const TextStyle(fontSize: 11,
                fontWeight: FontWeight.bold, color: Colors.white)),
      ]))),
    const SizedBox(height: 8),
    Wrap(alignment: WrapAlignment.center, spacing: 10, children: [
      _dot(AdminTheme.success, 'Actifs ($actifs)'),
      _dot(AdminTheme.warning, 'Suspendus ($suspendus)'),
      _dot(AdminTheme.danger, 'Renvoyés ($renvoyes)'),
    ]),
  ]);

  Widget _majorsWidget() {
    final avecNotes = adminEtudiants.where((e) => e.notes.isNotEmpty).toList();
    avecNotes.sort((a, b) => _moy(b.notes).compareTo(_moy(a.notes)));
    final top3 = avecNotes.take(3).toList();
    const medals = ['🥇', '🥈', '🥉'];
    return Column(children: List.generate(top3.length, (i) {
      final e   = top3[i];
      final moy = _moy(e.notes);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Text(medals[i], style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Container(width: 34, height: 34,
            decoration: BoxDecoration(color: AdminTheme.primaryLight, shape: BoxShape.circle),
            child: Center(child: Text('${e.prenoms[0]}${e.nom[0]}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                    color: AdminTheme.primary)))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${e.prenoms} ${e.nom}', style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            Text(e.filiere, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AdminTheme.primaryLight,
                borderRadius: BorderRadius.circular(20)),
            child: Text('${moy.toStringAsFixed(2)}/20', style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: AdminTheme.primary))),
        ]));
    }));
  }

  // ════════════════════════════════════════════════════════════════════════
  // TAB 2 — HISTORIQUE 5 ANS
  // ════════════════════════════════════════════════════════════════════════
  Widget _tabHistorique() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Sélecteur domaine/filière ───────────────────────────────────
        Row(children: [
          const Text('Voir par :', style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: Color(0xFF374151))),
          const SizedBox(width: 10),
          _toggleBtn('Par domaine', 'domaine'),
          const SizedBox(width: 8),
          _toggleBtn('Par filière', 'filiere'),
        ]),
        const SizedBox(height: 16),

        // ── Graphique inscriptions historiques ─────────────────────────
        _chartCard(
          'Total inscrits — 5 dernières années vs 2024-2025',
          Icons.group_rounded,
          _filtreHistorique == 'domaine'
              ? _inscriptionsHistoDomaine()
              : _inscriptionsHistoFiliere(),
        ),
        const SizedBox(height: 14),

        // ── Taux réussite/échec 5 ans ──────────────────────────────────
        _chartCard(
          'Taux de réussite & d\'échec — 5 ans',
          Icons.trending_up_rounded,
          _tauxReussiteChart(),
        ),
        const SizedBox(height: 14),

        // ── Comparaison ST vs SG ───────────────────────────────────────
        _chartCard(
          'Évolution inscriptions : Sciences & Tech vs Sciences de Gestion',
          Icons.compare_arrows_rounded,
          _comparaisonDomainesChart(),
        ),
        const SizedBox(height: 14),

        // ── Résumé texte ───────────────────────────────────────────────
        _resumeHistorique(),
      ]),
    );
  }

  Widget _toggleBtn(String label, String value) {
    final active = _filtreHistorique == value;
    return GestureDetector(
      onTap: () => setState(() => _filtreHistorique = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AdminTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AdminTheme.primary : const Color(0xFFE5E7EB))),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF6B7280)))));
  }

  // Graphique barres groupées inscriptions par domaine
  Widget _inscriptionsHistoDomaine() {
    final annees  = _inscriptionsParAnnee.keys.toList();
    final stData  = annees.map((a) => _inscriptionsParAnnee[a]![0].toDouble()).toList();
    final sgData  = annees.map((a) => _inscriptionsParAnnee[a]![1].toDouble()).toList();

    return SizedBox(height: 200, child: BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 220,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= annees.length) return const SizedBox();
                return Padding(padding: const EdgeInsets.only(top: 4),
                  child: Text(annees[i].substring(0, 4),
                      style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280))));
              })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                  style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))))),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
                color: Color(0xFFE5E7EB), strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(annees.length, (i) => BarChartGroupData(
          x: i, barRods: [
            BarChartRodData(toY: stData[i], color: AdminTheme.primary,
                width: 10, borderRadius: BorderRadius.circular(3)),
            BarChartRodData(toY: sgData[i], color: AdminTheme.info,
                width: 10, borderRadius: BorderRadius.circular(3)),
          ])),
      )));
  }

  // Graphique barres horizontales par filière
  Widget _inscriptionsHistoFiliere() {
    final annees   = _inscriptionsParFiliere.keys.toList();
    final couleurs = [
      AdminTheme.primary, AdminTheme.info, AdminTheme.success,
      AdminTheme.warning, AdminTheme.danger, const Color(0xFF7C3AED),
    ];

    return Column(children: [
      SizedBox(height: 200, child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 70,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= annees.length) return const SizedBox();
                  return Padding(padding: const EdgeInsets.only(top: 4),
                    child: Text(annees[i].substring(0, 4),
                        style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280))));
                })),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                    style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))))),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(
                  color: Color(0xFFE5E7EB), strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(annees.length, (i) {
            final data = _inscriptionsParFiliere[annees[i]]!;
            return BarChartGroupData(
              x: i,
              barRods: List.generate(data.length > 6 ? 6 : data.length, (j) =>
                  BarChartRodData(toY: data[j].toDouble(),
                      color: couleurs[j % couleurs.length],
                      width: 6, borderRadius: BorderRadius.circular(2))),
            );
          }),
        ))),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 4, children: List.generate(
          _filiereLabels.length > 6 ? 6 : _filiereLabels.length, (i) =>
          _dot(couleurs[i % couleurs.length], _filiereLabels[i]))),
    ]);
  }

  // Graphique courbes taux réussite/échec
  Widget _tauxReussiteChart() {
    final annees = _tauxReussiteParAnnee.keys.toList();
    final stData = annees.map((a) => _tauxReussiteParAnnee[a]![0]).toList();
    final sgData = annees.map((a) => _tauxReussiteParAnnee[a]![1]).toList();
    final echecST = stData.map((v) => 100 - v).toList();
    final echecSG = sgData.map((v) => 100 - v).toList();

    return Column(children: [
      SizedBox(height: 180, child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(
                  color: Color(0xFFE5E7EB), strokeWidth: 1)),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                    style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= annees.length) return const SizedBox();
                  return Text(annees[i].substring(0, 4),
                      style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)));
                })),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // Réussite ST
            LineChartBarData(
              spots: List.generate(stData.length, (i) => FlSpot(i.toDouble(), stData[i])),
              isCurved: true, color: AdminTheme.primary, barWidth: 2.5,
              dotData: FlDotData(show: true,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 3, color: AdminTheme.primary, strokeWidth: 0))),
            // Réussite SG
            LineChartBarData(
              spots: List.generate(sgData.length, (i) => FlSpot(i.toDouble(), sgData[i])),
              isCurved: true, color: AdminTheme.info, barWidth: 2.5,
              dotData: FlDotData(show: true,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 3, color: AdminTheme.info, strokeWidth: 0))),
            // Échec ST (pointillés)
            LineChartBarData(
              spots: List.generate(echecST.length, (i) => FlSpot(i.toDouble(), echecST[i])),
              isCurved: true, color: AdminTheme.danger, barWidth: 1.5,
              dashArray: [4, 4],
              dotData: const FlDotData(show: false)),
            // Échec SG (pointillés)
            LineChartBarData(
              spots: List.generate(echecSG.length, (i) => FlSpot(i.toDouble(), echecSG[i])),
              isCurved: true, color: AdminTheme.warning, barWidth: 1.5,
              dashArray: [4, 4],
              dotData: const FlDotData(show: false)),
          ],
          minX: 0, maxX: 4, minY: 0, maxY: 100,
        ))),
      const SizedBox(height: 10),
      Wrap(spacing: 12, runSpacing: 6, alignment: WrapAlignment.center, children: [
        _dot(AdminTheme.primary, 'Réussite ST'),
        _dot(AdminTheme.info, 'Réussite SG'),
        _dot(AdminTheme.danger, 'Échec ST'),
        _dot(AdminTheme.warning, 'Échec SG'),
      ]),
      const SizedBox(height: 8),
      // Tableau résumé
      Container(
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(children: [
          _tableHeader(),
          ...List.generate(annees.length, (i) =>
              _tableRow(annees[i], stData[i], sgData[i],
                  echecST[i], echecSG[i], i == annees.length - 1)),
        ])),
    ]);
  }

  Widget _tableHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: const BoxDecoration(color: Color(0xFFF1F3F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
    child: Row(children: const [
      Expanded(flex: 2, child: Text('Année', style: TextStyle(fontSize: 11,
          fontWeight: FontWeight.w700, color: Color(0xFF374151)))),
      Expanded(child: Text('Réussite ST', style: TextStyle(fontSize: 10,
          fontWeight: FontWeight.w700, color: AdminTheme.primary), textAlign: TextAlign.center)),
      Expanded(child: Text('Réussite SG', style: TextStyle(fontSize: 10,
          fontWeight: FontWeight.w700, color: AdminTheme.info), textAlign: TextAlign.center)),
      Expanded(child: Text('Échec ST', style: TextStyle(fontSize: 10,
          fontWeight: FontWeight.w700, color: AdminTheme.danger), textAlign: TextAlign.center)),
      Expanded(child: Text('Échec SG', style: TextStyle(fontSize: 10,
          fontWeight: FontWeight.w700, color: AdminTheme.warning), textAlign: TextAlign.center)),
    ]));

  Widget _tableRow(String annee, double rST, double rSG,
      double eST, double eSG, bool isCurrent) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrent ? AdminTheme.primaryLight.withOpacity(0.3) : Colors.transparent,
          border: const Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
        child: Row(children: [
          Expanded(flex: 2, child: Row(children: [
            Text(annee, style: TextStyle(fontSize: 11,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                color: isCurrent ? AdminTheme.primary : const Color(0xFF374151))),
            if (isCurrent) ...[
              const SizedBox(width: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: AdminTheme.primary,
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('En cours', style: TextStyle(fontSize: 8,
                    color: Colors.white, fontWeight: FontWeight.bold))),
            ],
          ])),
          Expanded(child: Text('${rST.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: AdminTheme.primary), textAlign: TextAlign.center)),
          Expanded(child: Text('${rSG.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: AdminTheme.info), textAlign: TextAlign.center)),
          Expanded(child: Text('${eST.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: AdminTheme.danger), textAlign: TextAlign.center)),
          Expanded(child: Text('${eSG.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: AdminTheme.warning), textAlign: TextAlign.center)),
        ]));

  Widget _comparaisonDomainesChart() {
    final annees = _inscriptionsParAnnee.keys.toList();
    final stData = annees.map((a) => _inscriptionsParAnnee[a]![0].toDouble()).toList();
    final sgData = annees.map((a) => _inscriptionsParAnnee[a]![1].toDouble()).toList();

    return SizedBox(height: 160, child: LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
                color: Color(0xFFE5E7EB), strokeWidth: 1)),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                  style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= annees.length) return const SizedBox();
                return Text(annees[i].substring(0, 4),
                    style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)));
              })),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(stData.length, (i) => FlSpot(i.toDouble(), stData[i])),
            isCurved: true, color: AdminTheme.primary, barWidth: 2.5,
            belowBarData: BarAreaData(show: true,
                color: AdminTheme.primaryLight.withOpacity(0.3)),
            dotData: FlDotData(show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3, color: AdminTheme.primary, strokeWidth: 0))),
          LineChartBarData(
            spots: List.generate(sgData.length, (i) => FlSpot(i.toDouble(), sgData[i])),
            isCurved: true, color: AdminTheme.info, barWidth: 2.5,
            belowBarData: BarAreaData(show: true,
                color: AdminTheme.infoLight.withOpacity(0.3)),
            dotData: FlDotData(show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3, color: AdminTheme.info, strokeWidth: 0))),
        ],
        minX: 0, maxX: 4, minY: 60, maxY: 200,
      )));
  }

  Widget _resumeHistorique() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.insights_rounded, color: AdminTheme.primary, size: 16),
        SizedBox(width: 8),
        Text('Analyse & Tendances', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
      ]),
      const SizedBox(height: 10),
      _tendanceItem('📈', 'Croissance inscriptions', '+37% sur 5 ans (2020→2024)',
          AdminTheme.success),
      _tendanceItem('🎯', 'Taux de réussite en hausse',
          'ST : 72% → 81% · SG : 68% → 76.5%', AdminTheme.primary),
      _tendanceItem('⚠️', 'Taux d\'échec en baisse',
          'ST : 28% → 19% · SG : 32% → 23.5%', AdminTheme.warning),
      _tendanceItem('💡', 'Sciences & Tech dominantes',
          '60% des inscrits en moyenne sur 5 ans', AdminTheme.info),
    ]));

  Widget _tendanceItem(String emoji, String titre, String desc, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titre, style: const TextStyle(fontSize: 12,
            fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        Text(desc, style: TextStyle(fontSize: 11, color: color)),
      ])),
    ]));

  // ════════════════════════════════════════════════════════════════════════
  // TAB 3 — LISTES
  // ════════════════════════════════════════════════════════════════════════
  Widget _tabListes() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text('Listes exportables', style: TextStyle(fontSize: 15,
          fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
      const SizedBox(height: 4),
      const Text('Téléchargez les listes au format PDF ou Excel',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
      const SizedBox(height: 16),
      ...[
        ('Liste complète des étudiants', Icons.people_rounded,
            '${adminEtudiants.length} étudiants'),
        ('Étudiants actifs', Icons.check_circle_rounded,
            '${adminEtudiants.where((e) => e.statut == 'actif').length} étudiants'),
        ('Étudiants suspendus', Icons.pause_circle_rounded,
            '${adminEtudiants.where((e) => e.statut == 'suspendu').length} étudiants'),
        ('Majors de promotion', Icons.emoji_events_rounded, 'Top par filière'),
        ('Bulletin de notes complet', Icons.grade_rounded, 'Tous les modules'),
        ('Rapport historique 5 ans', Icons.history_rounded, 'Inscriptions & Réussite'),
      ].map((item) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: AdminTheme.primaryLight,
                borderRadius: BorderRadius.circular(8)),
            child: Icon(item.$2, color: AdminTheme.primary, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.$1, style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            Text(item.$3, style: const TextStyle(
                fontSize: 11, color: Color(0xFF6B7280))),
          ])),
          Row(children: [
            _exportBtn('PDF', AdminTheme.danger,
                () => _snack('📥 Export PDF...')),
            const SizedBox(width: 6),
            _exportBtn('Excel', AdminTheme.success,
                () => _snack('📊 Export Excel...')),
          ]),
        ]))),
    ]);

  // ── Helpers ───────────────────────────────────────────────────────────
  Widget _chartCard(String titre, IconData icon, Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 28, height: 28,
          decoration: BoxDecoration(color: AdminTheme.primaryLight,
              borderRadius: BorderRadius.circular(7)),
          child: Icon(icon, color: AdminTheme.primary, size: 15)),
        const SizedBox(width: 8),
        Expanded(child: Text(titre, style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)))),
      ]),
      const SizedBox(height: 4),
      const Divider(color: Color(0xFFE5E7EB)),
      child,
    ]));

  Widget _dot(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
  ]);

  Widget _exportBtn(String label, Color color, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.3))),
          child: Text(label, style: TextStyle(fontSize: 11,
              fontWeight: FontWeight.w700, color: color))));

  double _moy(List<Map<String, dynamic>> notes) {
    if (notes.isEmpty) return 0;
    final total = notes.fold<double>(0,
        (s, n) => s + (n['note'] as double) * (n['coef'] as int));
    final coefs = notes.fold<int>(0, (s, n) => s + (n['coef'] as int));
    return total / coefs;
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: AdminTheme.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
}

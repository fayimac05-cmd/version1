import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/student_profile.dart';
import '../admin/admin_theme.dart';

class AdminDashboard extends StatefulWidget {
  final StudentProfile profile;
  const AdminDashboard({super.key, required this.profile});
  @override State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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
      border: Border.all(color: AdminTheme.accent.withOpacity(0.3)),
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
          _alertChip('3 réclamations non traitées', Icons.report_problem_rounded),
          _alertChip('5 publications BDE en attente', Icons.celebration_rounded),
          _alertChip('2 notes blâmables cette semaine', Icons.warning_rounded),
          _alertChip('1 étudiant suspendu', Icons.person_off_rounded),
        ]),
      ])),
    ]),
  );

  Widget _alertChip(String label, IconData icon) => GestureDetector(
    onTap: () {},
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminTheme.accent.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
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
      {'label': 'Étudiants actifs', 'value': '247', 'sub': '+12 ce mois',
       'icon': Icons.school_rounded, 'color': AdminTheme.primary,
       'bg': AdminTheme.primaryLight, 'trend': true},
      {'label': 'Professeurs actifs', 'value': '18', 'sub': 'Stable',
       'icon': Icons.person_pin_rounded, 'color': AdminTheme.info,
       'bg': AdminTheme.infoLight, 'trend': true},
      {'label': 'Filières ouvertes', 'value': '8', 'sub': '2024-2025',
       'icon': Icons.school_rounded, 'color': Color(0xFF7C3AED),
       'bg': Color(0xFFF5F3FF), 'trend': false},
      {'label': 'Tickets vendus', 'value': '340/500', 'sub': '68% vendus',
       'icon': Icons.confirmation_number_rounded, 'color': AdminTheme.warning,
       'bg': AdminTheme.warningLight, 'trend': true},
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
      Text(k['value'] as String, style: TextStyle(fontSize: 26,
          fontWeight: FontWeight.w800, color: k['color'] as Color)),
      const SizedBox(height: 2),
      Text(k['label'] as String, style: AdminTheme.headingSmall),
      const SizedBox(height: 2),
      Text(k['sub'] as String, style: AdminTheme.caption),
    ]),
  );

  // ── Réclamations récentes ─────────────────────────────────────────────
  Widget _reclamationsWidget() => _card(
    title: 'Réclamations récentes',
    icon: Icons.report_problem_rounded,
    action: 'Voir tout',
    child: Column(children: [
      _reclItem('KOURAOGO Ibrahim', 'RES301 — Note TD', 'en_attente', '28/04'),
      _reclItem('TRAORÉ Fatimata', 'POO302 — Moyenne', 'transmise', '27/04'),
      _reclItem('KABORÉ Djeneba', 'MKS301 — Note examen', 'resolue', '26/04'),
      _reclItem('SAWADOGO Aminata', 'BDA303 — Note TP', 'en_attente', '25/04'),
      _reclItem('OUÉDRAOGO Issouf', 'EP301 — Moyenne', 'rejetee', '24/04'),
    ]),
  );

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
          decoration: BoxDecoration(color: AdminTheme.primaryLight,
              shape: BoxShape.circle),
          child: Center(child: Text(
            '${nom.split(' ')[0][0]}${nom.split(' ').length > 1 ? nom.split(' ')[1][0] : ''}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                color: AdminTheme.primary)))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nom, style: AdminTheme.headingSmall.copyWith(fontSize: 13)),
          Text(module, style: AdminTheme.caption),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          AdminTheme.badge(sl, sc, sc.withOpacity(0.1)),
          const SizedBox(height: 3),
          Text(date, style: AdminTheme.caption),
        ]),
      ]),
    );
  }

  // ── Événements à venir ────────────────────────────────────────────────
  Widget _eventsWidget() => _card(
    title: 'Prochains événements',
    icon: Icons.calendar_today_rounded,
    action: 'Calendrier',
    child: Column(children: [
      _eventItem('Soirée étudiante BDE', '02 Mai 2025', '340/500 billets', AdminTheme.warning),
      const Divider(height: 20, color: AdminTheme.border),
      _eventItem('Cérémonie de remise des diplômes', '15 Juin 2025', 'Non ouvert', AdminTheme.primary),
      const Divider(height: 20, color: AdminTheme.border),
      _eventItem('Journée sportive', '01 Mai 2025', 'Gratuit', AdminTheme.success),
    ]),
  );

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
  Widget _inscriptionsChart() => _card(
    title: 'Évolution des inscriptions',
    icon: Icons.show_chart_rounded,
    action: 'Détails',
    child: SizedBox(height: 200, child: LineChart(
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
                const months = ['Sep','Oct','Nov','Déc','Jan','Fév',
                    'Mar','Avr','Mai','Jun','Jul','Aoû'];
                final i = v.toInt();
                if (i < 0 || i >= months.length) return const SizedBox();
                return Text(months[i], style: AdminTheme.caption);
              })),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 180), FlSpot(1, 195), FlSpot(2, 200), FlSpot(3, 205),
              FlSpot(4, 210), FlSpot(5, 215), FlSpot(6, 220), FlSpot(7, 235),
              FlSpot(8, 240), FlSpot(9, 245), FlSpot(10, 247), FlSpot(11, 247),
            ],
            isCurved: true, color: AdminTheme.primary,
            barWidth: 2.5,
            belowBarData: BarAreaData(show: true,
                color: AdminTheme.primaryLight.withOpacity(0.5)),
            dotData: const FlDotData(show: false),
          ),
        ],
        minX: 0, maxX: 11, minY: 150, maxY: 270,
      ),
    )),
  );

  // ── Donut filières ────────────────────────────────────────────────────
  Widget _donutFilieres() => _card(
    title: 'Répartition par domaine',
    icon: Icons.donut_large_rounded,
    child: Column(children: [
      SizedBox(height: 160, child: PieChart(
        PieChartData(
          sectionsSpace: 3, centerSpaceRadius: 45,
          sections: [
            PieChartSectionData(value: 60, color: AdminTheme.primary,
                title: '60%', radius: 55, titleStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            PieChartSectionData(value: 40, color: AdminTheme.info,
                title: '40%', radius: 55, titleStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      )),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _legend(AdminTheme.primary, 'Sciences & Technologies', '148 étudiants'),
        const SizedBox(width: 20),
        _legend(AdminTheme.info, 'Sciences de Gestion', '99 étudiants'),
      ]),
    ]),
  );

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
  Widget _bdeWidget() => _card(
    title: 'Publications BDE en attente',
    icon: Icons.celebration_rounded,
    action: 'Voir tout',
    child: Column(children: [
      _bdeItem('Soirée étudiante vendredi 02 Mai !', 'BDE — Aïcha S.', '28/04'),
      _bdeItem('Tournoi de foot inter-filières', 'BDE — Sport', '27/04'),
    ]),
  );

  Widget _bdeItem(String titre, String auteur, String date) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: AdminTheme.warningLight,
            borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.celebration_outlined,
            color: AdminTheme.warning, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titre, style: AdminTheme.headingSmall.copyWith(fontSize: 13)),
        Text('$auteur · $date', style: AdminTheme.caption),
      ])),
      const SizedBox(width: 8),
      Row(children: [
        _actionBtn('Approuver', AdminTheme.success, AdminTheme.successLight),
        const SizedBox(width: 6),
        _actionBtn('Rejeter', AdminTheme.danger, AdminTheme.dangerLight),
      ]),
    ]),
  );

  Widget _actionBtn(String label, Color fg, Color bg) => GestureDetector(
    onTap: () {},
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg,
          borderRadius: BorderRadius.circular(AdminTheme.radiusSmall),
          border: Border.all(color: fg.withOpacity(0.3))),
      child: Text(label, style: TextStyle(fontSize: 11,
          fontWeight: FontWeight.w700, color: fg)),
    ),
  );

  // ── Majors de promo ───────────────────────────────────────────────────
  Widget _majorsWidget() => _card(
    title: 'Majors de promotion',
    icon: Icons.emoji_events_rounded,
    child: Column(children: [
      _majorItem(1, 'TRAORÉ Fatimata', 'RIT L2', '17.8/20', '🥇'),
      _majorItem(2, 'SAWADOGO Aminata', 'RIT L2', '16.2/20', '🥈'),
      _majorItem(3, 'KABORÉ Djeneba', 'Marketing L2', '15.9/20', '🥉'),
    ]),
  );

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
            decoration: BoxDecoration(color: AdminTheme.primaryLight,
                borderRadius: BorderRadius.circular(20)),
            child: Text(moy, style: const TextStyle(fontSize: 12,
                fontWeight: FontWeight.w800, color: AdminTheme.primary))),
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
              decoration: BoxDecoration(color: AdminTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: AdminTheme.primary, size: 17)),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: AdminTheme.headingSmall)),
            if (action != null)
              TextButton(onPressed: () {},
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

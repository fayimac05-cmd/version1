import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_dashboard.dart';
import '../admin/admin_annonces.dart';
import '../admin/admin_edt.dart';
import '../admin/admin_filieres.dart';
import '../admin/admin_notes.dart';
import '../admin/admin_reclamations.dart';
import '../admin/admin_etudiants.dart';
import '../admin/admin_professeurs.dart';
import '../admin/admin_parents.dart';
import '../admin/admin_membres.dart';
import '../admin/admin_messages.dart';
import '../admin/admin_bde.dart';
import '../admin/admin_statistiques.dart';
import '../admin/admin_evaluations.dart';
import '../pages/splash_screen.dart';

class _MenuItem {
  final IconData icon, iconActive;
  final String label, group;
  final String? badge;
  const _MenuItem({required this.icon, required this.iconActive,
      required this.label, required this.group, this.badge});
}

const _menuGroups = [
  {'key': 'GÉNÉRAL',    'items': [0, 1]},
  {'key': 'ACADÉMIQUE', 'items': [2, 3, 4, 5]},
  {'key': 'PERSONNES',  'items': [6, 7, 8, 9]},
  {'key': 'MESSAGERIE', 'items': [10]},
  {'key': 'ÉVÉNEMENTS', 'items': [11]},
  {'key': 'RAPPORTS',   'items': [12, 13]},
];

const _items = <_MenuItem>[
  _MenuItem(icon: Icons.dashboard_outlined, iconActive: Icons.dashboard_rounded, label: 'Tableau de bord', group: 'GÉNÉRAL'),
  _MenuItem(icon: Icons.campaign_outlined, iconActive: Icons.campaign_rounded, label: 'Annonces', group: 'GÉNÉRAL'),
  _MenuItem(icon: Icons.school_outlined, iconActive: Icons.school_rounded, label: 'Filières & Modules', group: 'ACADÉMIQUE'),
  _MenuItem(icon: Icons.calendar_today_outlined, iconActive: Icons.calendar_today_rounded, label: 'Emplois du Temps', group: 'ACADÉMIQUE'),
  _MenuItem(icon: Icons.grade_outlined, iconActive: Icons.grade_rounded, label: 'Notes & Moyennes', group: 'ACADÉMIQUE', badge: '3'),
  _MenuItem(icon: Icons.report_problem_outlined, iconActive: Icons.report_problem_rounded, label: 'Réclamations', group: 'ACADÉMIQUE', badge: '2'),
  _MenuItem(icon: Icons.people_outline, iconActive: Icons.people_rounded, label: 'Étudiants', group: 'PERSONNES'),
  _MenuItem(icon: Icons.person_pin_outlined, iconActive: Icons.person_pin_rounded, label: 'Professeurs', group: 'PERSONNES'),
  _MenuItem(icon: Icons.family_restroom_outlined, iconActive: Icons.family_restroom_rounded, label: 'Parents', group: 'PERSONNES'),
  _MenuItem(icon: Icons.shield_outlined, iconActive: Icons.shield_rounded, label: 'Membres & Rôles', group: 'PERSONNES'),
  _MenuItem(icon: Icons.forum_outlined, iconActive: Icons.forum_rounded, label: 'Groupes & Messages', group: 'MESSAGERIE'),
  _MenuItem(icon: Icons.celebration_outlined, iconActive: Icons.celebration_rounded, label: 'BDE & Événements', group: 'ÉVÉNEMENTS'),
  _MenuItem(icon: Icons.bar_chart_outlined, iconActive: Icons.bar_chart_rounded, label: 'Statistiques', group: 'RAPPORTS'),
  _MenuItem(icon: Icons.star_outline_rounded, iconActive: Icons.star_rounded, label: 'Éval. Professeurs', group: 'RAPPORTS'),
];

class AdminShell extends StatefulWidget {
  final StudentProfile profile;
  final VoidCallback onLogout;
  const AdminShell({super.key, required this.profile, required this.onLogout});
  @override State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _idx = 0;
  bool _compact = false;

  Widget _page(int i) {
    switch (i) {
      case 0:  return AdminDashboard(profile: widget.profile);
      case 1:  return const AdminAnnonces();
      case 2:  return const AdminFilieres();
      case 3:  return const AdminEDT();
      case 4:  return const AdminNotes();
      case 5:  return const AdminReclamations();
      case 6:  return const AdminEtudiants();
      case 7:  return const AdminProfesseurs();
      case 8:  return const AdminParents();
      case 9:  return const AdminMembres();
      case 10: return const AdminMessages();
      case 11: return const AdminBDE();
      case 12: return const AdminStatistiques();
      case 13: return const AdminEvaluations();
      default: return _Placeholder(label: _items[i].label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AdminTheme.isMobile(context);
    return Scaffold(
      backgroundColor: AdminTheme.background,
      drawer: mobile ? Drawer(backgroundColor: AdminTheme.sidebarBg,
          child: _sidebar()) : null,
      body: Row(children: [
        if (!mobile) AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: _compact ? AdminTheme.sidebarWidthCompact : AdminTheme.sidebarWidth,
          child: _sidebar(),
        ),
        Expanded(child: Column(children: [
          _topbar(context, mobile),
          Expanded(child: _page(_idx)),
        ])),
      ]),
    );
  }

  Widget _sidebar() {
    final c = _compact;
    return Container(
      color: AdminTheme.sidebarBg,
      child: Column(children: [
        // Header
        Container(height: AdminTheme.topbarHeight,
          padding: EdgeInsets.symmetric(horizontal: c ? 16 : 20),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(color: AdminTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('S', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: AdminTheme.primary)))),
            if (!c) ...[
              const SizedBox(width: 12),
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('ScholARHub', style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                Text('IST Ouaga 2000', style: TextStyle(fontSize: 10,
                    color: AdminTheme.sidebarText)),
              ])),
            ],
          ]),
        ),
        Container(height: 1, color: AdminTheme.primaryMid),
        // Avatar
        if (!c) Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: const BoxDecoration(color: AdminTheme.accent, shape: BoxShape.circle),
              child: Center(child: Text(
                '${widget.profile.prenoms[0]}${widget.profile.nom[0]}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                    color: Colors.white)))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${widget.profile.prenoms} ${widget.profile.nom}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
              Container(margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: AdminTheme.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4)),
                child: const Text('Super Admin', style: TextStyle(fontSize: 9,
                    fontWeight: FontWeight.w700, color: AdminTheme.accent, letterSpacing: 0.5))),
            ])),
          ]),
        ),
        Container(height: 1, color: AdminTheme.primaryMid.withOpacity(0.4)),
        // Menu
        Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (final g in _menuGroups) ...[
              if (!c) AdminTheme.sectionLabel(g['key'] as String)
              else const SizedBox(height: 8),
              for (final i in (g['items'] as List))
                _menuItem(_items[i], i, _idx == i, c),
            ],
          ],
        )),
        Container(height: 1, color: AdminTheme.primaryMid.withOpacity(0.4)),
        // Footer
        Padding(
          padding: EdgeInsets.symmetric(horizontal: c ? 8 : 12, vertical: 10),
          child: c ? Column(children: [
            _sideBtn(Icons.dark_mode_outlined, 'Mode sombre', () {}),
            const SizedBox(height: 6),
            _sideBtn(Icons.logout_rounded, 'Déconnexion', _logout,
                color: AdminTheme.danger),
          ]) : Row(children: [
            _sideBtn(Icons.dark_mode_outlined, 'Mode sombre', () {}),
            const SizedBox(width: 8),
            Expanded(child: GestureDetector(
              onTap: _logout,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                    color: AdminTheme.danger.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AdminTheme.radiusButton)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.logout_rounded, color: AdminTheme.danger, size: 16),
                  SizedBox(width: 6),
                  Text('Déconnexion', style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600, color: AdminTheme.danger)),
                ]),
              ),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _menuItem(_MenuItem item, int i, bool active, bool compact) =>
      Tooltip(message: compact ? item.label : '',
        child: GestureDetector(
          onTap: () => setState(() => _idx = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 2),
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 0 : 10, vertical: 9),
            decoration: BoxDecoration(
              color: active ? AdminTheme.sidebarActive : Colors.transparent,
              borderRadius: BorderRadius.circular(AdminTheme.radiusButton),
            ),
            child: Row(mainAxisAlignment: compact
                ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Stack(children: [
                  Icon(active ? item.iconActive : item.icon,
                      color: active ? Colors.white : AdminTheme.sidebarIcon, size: 20),
                  if (item.badge != null)
                    Positioned(top: -2, right: -4,
                      child: Container(width: 13, height: 13,
                        decoration: const BoxDecoration(
                            color: AdminTheme.danger, shape: BoxShape.circle),
                        child: Center(child: Text(item.badge!,
                            style: const TextStyle(fontSize: 7,
                                color: Colors.white, fontWeight: FontWeight.bold))))),
                ]),
                if (!compact) ...[
                  const SizedBox(width: 10),
                  Expanded(child: Text(item.label, style: TextStyle(fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? Colors.white : AdminTheme.sidebarText))),
                  if (item.badge != null) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AdminTheme.danger,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(item.badge!, style: const TextStyle(fontSize: 10,
                        color: Colors.white, fontWeight: FontWeight.bold))),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _sideBtn(IconData icon, String tip, VoidCallback onTap,
      {Color color = AdminTheme.sidebarIcon}) =>
      Tooltip(message: tip, child: GestureDetector(onTap: onTap,
        child: Container(width: 34, height: 34,
          decoration: BoxDecoration(color: AdminTheme.sidebarHover,
              borderRadius: BorderRadius.circular(AdminTheme.radiusButton)),
          child: Icon(icon, color: color, size: 17))));

  Widget _topbar(BuildContext context, bool mobile) => Container(
    height: AdminTheme.topbarHeight,
    decoration: BoxDecoration(color: AdminTheme.surface,
      border: const Border(bottom: BorderSide(color: AdminTheme.border)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
          blurRadius: 4, offset: const Offset(0, 1))],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(children: [
      if (mobile)
        IconButton(icon: const Icon(Icons.menu_rounded, color: AdminTheme.textPrimary, size: 22),
            onPressed: () => Scaffold.of(context).openDrawer())
      else
        IconButton(
          icon: Icon(_compact ? Icons.menu_open_rounded : Icons.menu_rounded,
              color: AdminTheme.textSecondary, size: 20),
          onPressed: () => setState(() => _compact = !_compact),
        ),
      const SizedBox(width: 4),
      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_items[_idx].label, style: AdminTheme.headingSmall),
        Text('Administration · ${_items[_idx].group}', style: AdminTheme.caption),
      ])),
      if (!mobile) GestureDetector(
        onTap: () => showDialog(context: context,
            builder: (_) => _SearchDialog()),
        child: Container(width: 200, height: 34,
          decoration: BoxDecoration(color: AdminTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(AdminTheme.radiusButton),
              border: Border.all(color: AdminTheme.border)),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(children: [
            const Icon(Icons.search, color: AdminTheme.textMuted, size: 15),
            const SizedBox(width: 8),
            const Expanded(child: Text('Rechercher...',
                style: TextStyle(fontSize: 12, color: AdminTheme.textMuted))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: AdminTheme.border,
                  borderRadius: BorderRadius.circular(4)),
              child: const Text('⌘K', style: TextStyle(fontSize: 9,
                  color: AdminTheme.textMuted, fontWeight: FontWeight.w600))),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      Stack(children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: AdminTheme.textSecondary, size: 22),
          onPressed: () => showModalBottomSheet(context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => _NotifsPanel()),
        ),
        Positioned(top: 8, right: 8, child: Container(width: 14, height: 14,
          decoration: const BoxDecoration(color: AdminTheme.danger, shape: BoxShape.circle),
          child: const Center(child: Text('5',
              style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold))))),
      ]),
      const SizedBox(width: 4),
      GestureDetector(onTap: _logout,
        child: Container(width: 32, height: 32,
          decoration: BoxDecoration(color: AdminTheme.accent, shape: BoxShape.circle,
              border: Border.all(color: AdminTheme.primary, width: 2)),
          child: Center(child: Text(
            '${widget.profile.prenoms[0]}${widget.profile.nom[0]}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                color: Colors.white))))),
    ]),
  );

  void _logout() => showDialog(context: context, builder: (_) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: const Row(children: [
      Icon(Icons.logout_rounded, color: AdminTheme.danger),
      SizedBox(width: 10),
      Text('Déconnexion', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
    ]),
    content: const Text('Voulez-vous vous déconnecter ?',
        style: TextStyle(fontSize: 14, color: AdminTheme.textSecondary)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Annuler',
              style: TextStyle(color: AdminTheme.textSecondary))),
      ElevatedButton(onPressed: () {
        Navigator.pop(context);
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SplashScreen()), (_) => false);
      }, style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.danger,
          foregroundColor: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: const Text('Déconnecter')),
    ],
  ));
}

class _Placeholder extends StatelessWidget {
  final String label;
  const _Placeholder({required this.label});
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min, children: [
    Container(width: 72, height: 72,
      decoration: BoxDecoration(color: AdminTheme.primaryLight,
          borderRadius: BorderRadius.circular(18)),
      child: const Icon(Icons.construction_rounded, color: AdminTheme.primary, size: 36)),
    const SizedBox(height: 16),
    Text(label, style: AdminTheme.headingMedium),
    const SizedBox(height: 8),
    const Text('Section en développement.', style: TextStyle(
        fontSize: 14, color: AdminTheme.textSecondary)),
  ]));
}

class _SearchDialog extends StatelessWidget {
  final _s = const [
    {'icon': Icons.people_rounded, 'l': 'Ibrahim KOURAOGO', 's': 'Étudiant · RIT L2'},
    {'icon': Icons.people_rounded, 'l': 'Fatimata TRAORÉ', 's': 'Étudiant · RIT L2'},
    {'icon': Icons.person_pin_rounded, 'l': 'OUÉDRAOGO Mamadou', 's': 'Professeur'},
    {'icon': Icons.school_rounded, 'l': 'Réseaux & Télécom', 's': 'Filière · L2'},
  ];
  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Container(width: 480, constraints: const BoxConstraints(maxHeight: 380),
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          decoration: BoxDecoration(color: AdminTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AdminTheme.border)),
          child: const TextField(autofocus: true,
            decoration: InputDecoration(hintText: 'Rechercher...',
                hintStyle: TextStyle(color: AdminTheme.textMuted),
                prefixIcon: Icon(Icons.search, color: AdminTheme.textMuted, size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12))),
        ),
        const SizedBox(height: 10),
        Flexible(child: ListView.separated(shrinkWrap: true,
          itemCount: _s.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: AdminTheme.border),
          itemBuilder: (_, i) => ListTile(
            leading: Container(width: 34, height: 34,
                decoration: BoxDecoration(color: AdminTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(_s[i]['icon'] as IconData,
                    color: AdminTheme.primary, size: 16)),
            title: Text(_s[i]['l'] as String, style: AdminTheme.headingSmall),
            subtitle: Text(_s[i]['s'] as String, style: AdminTheme.bodyMedium),
            onTap: () => Navigator.pop(context)),
        )),
      ]),
    ),
  );
}

class _NotifsPanel extends StatelessWidget {
  final _n = const [
    {'icon': Icons.report_problem_rounded, 'c': AdminTheme.warning,
     't': 'Nouvelle réclamation', 'b': 'KOURAOGO Ibrahim — RES301', 'h': '5 min'},
    {'icon': Icons.grade_rounded, 'c': AdminTheme.info,
     't': 'Notes soumises', 'b': 'OUÉDRAOGO Mamadou — RIT L2', 'h': '20 min'},
    {'icon': Icons.person_add_rounded, 'c': AdminTheme.success,
     't': 'Nouvel étudiant', 'b': 'TRAORÉ Fatimata inscrite', 'h': '1h'},
    {'icon': Icons.celebration_rounded, 'c': AdminTheme.danger,
     't': 'Événement BDE', 'b': 'Publication en attente', 'h': '2h'},
    {'icon': Icons.warning_amber_rounded, 'c': AdminTheme.accent,
     't': 'Note blâmable', 'b': '2 étudiants sous 5/20', 'h': '3h'},
  ];
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: AdminTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 8),
      Container(width: 40, height: 4, decoration: BoxDecoration(
          color: AdminTheme.border, borderRadius: BorderRadius.circular(2))),
      Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
        child: Row(children: [
          Text('Notifications', style: AdminTheme.headingMedium),
          const Spacer(),
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Tout lire',
                  style: TextStyle(color: AdminTheme.primary, fontSize: 12))),
        ])),
      const Divider(height: 1, color: AdminTheme.border),
      ListView.separated(shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _n.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AdminTheme.border),
        itemBuilder: (_, i) => ListTile(
          leading: Container(width: 38, height: 38,
              decoration: BoxDecoration(
                  color: (_n[i]['c'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(_n[i]['icon'] as IconData,
                  color: _n[i]['c'] as Color, size: 18)),
          title: Text(_n[i]['t'] as String,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          subtitle: Text(_n[i]['b'] as String, style: AdminTheme.bodyMedium),
          trailing: Text(_n[i]['h'] as String, style: AdminTheme.caption))),
      const SizedBox(height: 16),
    ]),
  );
}

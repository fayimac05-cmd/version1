import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import 'courses_tab.dart';
import 'home_tab.dart';
import 'notes_tab.dart';
import 'planning_tab.dart';
import 'profile_tab.dart';
import 'chat_ia_screen.dart';
import 'messages_screen.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({
    super.key,
    required this.profile,
    required this.onLogout,
  });

  final StudentProfile profile;
  final VoidCallback onLogout;

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _currentTab = 0;

  // ── Notifications ─────────────────────────────────────────────────────
  final List<AppNotification> _notifs = [
    AppNotification(id: '1', type: NotifType.examen,
        titre: 'Examen de mi-parcours',
        corps: 'Algorithmes & Structures de données — dans 48h',
        temps: 'Il y a 12 min'),
    AppNotification(id: '2', type: NotifType.note,
        titre: 'Note publiée',
        corps: 'Analyse numérique : 16.5/20',
        temps: 'Il y a 2h'),
    AppNotification(id: '3', type: NotifType.cours,
        titre: 'Nouveau cours disponible',
        corps: 'Pr. Koanda a posté — Réseaux informatiques',
        temps: 'Il y a 5h'),
    AppNotification(id: '4', type: NotifType.inscription,
        titre: 'Inscription validée',
        corps: 'Votre inscription en Master 2 Génie Logiciel a été validée',
        temps: 'Hier, 14:30', lu: true),
  ];

  int get _nonLus => _notifs.where((n) => !n.lu).length;

  final GlobalKey _clochKey = GlobalKey();
  OverlayEntry?   _overlayEntry;
  bool            _panelOuvert = false;

  void _togglePanel() => _panelOuvert ? _fermerPanel() : _ouvrirPanel();

  void _ouvrirPanel() {
    final box = _clochKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos  = box.localToGlobal(Offset.zero);
    final size = box.size;
    setState(() => _panelOuvert = true);

    _overlayEntry = OverlayEntry(builder: (ctx) => _NotifPanel(
      top:    pos.dy + size.height + 8,
      right:  MediaQuery.of(ctx).size.width - pos.dx - size.width,
      notifs: _notifs,
      onLu: (id) {
        setState(() => _notifs.firstWhere((n) => n.id == id).lu = true);
        _overlayEntry?.markNeedsBuild();
      },
      onToutLu: () {
        setState(() { for (final n in _notifs) n.lu = true; });
        _overlayEntry?.markNeedsBuild();
      },
      onFermer: _fermerPanel,
    ));
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _fermerPanel() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _panelOuvert = false);
  }

  @override
  void dispose() {
    _fermerPanel();
    super.dispose();
  }

  // ── Messages badge ────────────────────────────────────────────────────
  int get _totalNonLus =>
      conversationsPrivees.fold(0, (s, c) => s + c.nbNonLus);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(profile: widget.profile),
      const CoursesTab(),
      const NotesTab(),
      const PlanningTab(),
      MessagesScreen(profile: widget.profile),
      ChatIAScreen(profile: widget.profile),
      ProfileTab(profile: widget.profile, onLogout: widget.onLogout),
    ];

    // Titres par onglet
    const titres = ['Accueil', 'Cours', 'Notes', 'Planning',
        'Messages', 'Chat IA', 'Profil'];

    return Scaffold(
      // ── AppBar global avec cloche ────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0xFFE2E8F0),
        title: Text(titres[_currentTab],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              key: _clochKey,
              onTap: _togglePanel,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _panelOuvert
                      ? AppPalette.blue.withOpacity(0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _panelOuvert
                        ? AppPalette.blue.withOpacity(0.4)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Stack(alignment: Alignment.center, children: [
                  Icon(
                    _panelOuvert
                        ? Icons.notifications_rounded
                        : Icons.notifications_outlined,
                    color: _panelOuvert
                        ? AppPalette.blue
                        : const Color(0xFF64748B),
                    size: 22,
                  ),
                  if (_nonLus > 0)
                    Positioned(top: 7, right: 7,
                        child: _BadgePulse(count: _nonLus)),
                ]),
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey(_currentTab),
            child: pages[_currentTab],
          ),
        ),
      ),

      bottomNavigationBar: NavigationBar(
        backgroundColor: AppPalette.white,
        indicatorColor: AppPalette.yellow.withOpacity(0.45),
        selectedIndex: _currentTab,
        onDestinationSelected: (index) => setState(() => _currentTab = index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Cours',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grading_outlined),
            selectedIcon: Icon(Icons.grading_rounded),
            label: 'Notes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Planning',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _totalNonLus > 0,
              label: Text('$_totalNonLus'),
              child: const Icon(Icons.chat_bubble_outline_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: _totalNonLus > 0,
              label: Text('$_totalNonLus'),
              child: const Icon(Icons.chat_bubble_rounded),
            ),
            label: 'Messages',
          ),
          const NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy_rounded),
            label: 'IA',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BADGE PULSANT
// ════════════════════════════════════════════════════════════════════════════

class _BadgePulse extends StatefulWidget {
  const _BadgePulse({required this.count});
  final int count;

  @override
  State<_BadgePulse> createState() => _BadgePulseState();
}

class _BadgePulseState extends State<_BadgePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.35)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    child: Container(width: 8, height: 8,
      decoration: BoxDecoration(color: const Color(0xFFE24B4A),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5))),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// PANEL NOTIFICATIONS
// ════════════════════════════════════════════════════════════════════════════

class _NotifPanel extends StatelessWidget {
  const _NotifPanel({
    required this.top, required this.right, required this.notifs,
    required this.onLu, required this.onToutLu, required this.onFermer,
  });

  final double top, right;
  final List<AppNotification> notifs;
  final void Function(String) onLu;
  final VoidCallback onToutLu, onFermer;

  @override
  Widget build(BuildContext context) {
    final nonLus = notifs.where((n) => !n.lu).length;
    return Stack(children: [
      Positioned.fill(child: GestureDetector(
          onTap: onFermer, behavior: HitTestBehavior.opaque,
          child: const ColoredBox(color: Colors.transparent))),
      Positioned(top: top, right: right,
        child: Material(elevation: 8,
          borderRadius: BorderRadius.circular(16),
          shadowColor: Colors.black.withOpacity(0.12),
          child: Container(width: 320,
            constraints: const BoxConstraints(maxHeight: 480),
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // En-tête
              Padding(padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                child: Row(children: [
                  const Expanded(child: Text('Notifications',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A)))),
                  if (nonLus > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('$nonLus nouvelle${nonLus > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 11,
                              color: Color(0xFFB91C1C), fontWeight: FontWeight.w600))),
                    const SizedBox(width: 8),
                    TextButton(onPressed: onToutLu,
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: const Text('Tout lire', style: TextStyle(
                          fontSize: 12, color: Color(0xFF0A4DA2)))),
                  ],
                ])),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              // Liste
              Flexible(child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: notifs.length,
                separatorBuilder: (_, __) => const Divider(
                    height: 1, color: Color(0xFFF1F5F9), indent: 60),
                itemBuilder: (_, i) => _NotifItem(
                    notif: notifs[i], onTap: () => onLu(notifs[i].id)),
              )),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              TextButton(onPressed: onFermer,
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 0),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16)))),
                child: const Text('Voir toutes les notifications',
                    style: TextStyle(fontSize: 13, color: Color(0xFF0A4DA2),
                        fontWeight: FontWeight.w600))),
            ]),
          )),
      ),
    ]);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ITEM NOTIFICATION
// ════════════════════════════════════════════════════════════════════════════

class _NotifItem extends StatelessWidget {
  const _NotifItem({required this.notif, required this.onTap});
  final AppNotification notif;
  final VoidCallback onTap;

  (Color, Color, IconData) get _style {
    switch (notif.type) {
      case NotifType.examen:
        return (const Color(0xFFFCEBEB), const Color(0xFFA32D2D), Icons.alarm_outlined);
      case NotifType.note:
        return (const Color(0xFFFAEEDA), const Color(0xFF854F0B), Icons.star_outline_rounded);
      case NotifType.cours:
        return (const Color(0xFFE6F1FB), const Color(0xFF185FA5), Icons.menu_book_outlined);
      case NotifType.inscription:
        return (const Color(0xFFEAF3DE), const Color(0xFF3B6D11), Icons.check_circle_outline);
      case NotifType.message:
        return (const Color(0xFFEEEDFE), const Color(0xFF534AB7), Icons.chat_bubble_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, ic, icone) = _style;
    return InkWell(
      onTap: notif.lu ? null : onTap,
      child: Container(
        color: notif.lu ? Colors.transparent : const Color(0xFFF8FAFF),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 18, right: 6),
            child: Container(width: 6, height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: notif.lu ? Colors.transparent : const Color(0xFF0A4DA2)))),
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icone, color: ic, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(notif.titre, style: TextStyle(fontSize: 13,
                fontWeight: notif.lu ? FontWeight.w500 : FontWeight.bold,
                color: const Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(notif.corps, style: const TextStyle(fontSize: 12,
                color: Color(0xFF64748B), height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(notif.temps, style: const TextStyle(
                fontSize: 11, color: Color(0xFF94A3B8))),
          ])),
        ]),
      ),
    );
  }
}

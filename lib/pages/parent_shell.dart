import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import 'paiement_scolarite_screen.dart';
import 'parent/parent_home_tab.dart';
import 'parent/parent_grades_tab.dart';
import 'parent/parent_schedule_tab.dart';
import 'parent/parent_profile_tab.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({
    super.key,
    required this.nomEnfant,
    required this.onLogout,
  });

  final String nomEnfant;
  final VoidCallback onLogout;

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ParentHomeTab(
        nomEnfant: widget.nomEnfant,
        onNavigateToTab: (index) => setState(() => _currentTab = index),
      ),
      ParentGradesTab(nomEnfant: widget.nomEnfant),
      const ParentScheduleTab(),
      ParentProfileTab(
        nomEnfant: widget.nomEnfant,
        onLogout: widget.onLogout,
      ),
      const PaiementScolariteScreen(),
    ];

    return Scaffold(
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.grading_outlined),
            selectedIcon: Icon(Icons.grading_rounded),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Planning',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
          NavigationDestination(
            icon: Icon(Icons.payment_outlined),
            selectedIcon: Icon(Icons.payment_rounded),
            label: 'Paiements',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import 'courses_tab.dart';
import 'home_tab.dart';
import 'notes_tab.dart';
import 'planning_tab.dart';
import 'profile_tab.dart';
import 'chat_ia_screen.dart';
import 'bulletin_screen.dart';
import 'paiement_scolarite_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final isParent = widget.profile.role == 'parent';
    final isStudent = widget.profile.role == 'etudiant';
    final showBulletins = isStudent || isParent;

    // Construire les listes de manière synchronisée
    final pages = <Widget>[];
    final destinations = <NavigationDestination>[];

    // 0. Accueil
    pages.add(HomeTab(profile: widget.profile));
    destinations.add(
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Accueil',
      ),
    );

    // 1. Cours
    pages.add(const CoursesTab());
    destinations.add(
      const NavigationDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book_rounded),
        label: 'Cours',
      ),
    );

    // 2. Notes
    pages.add(const NotesTab());
    destinations.add(
      const NavigationDestination(
        icon: Icon(Icons.grading_outlined),
        selectedIcon: Icon(Icons.grading_rounded),
        label: 'Notes',
      ),
    );

    // 3. Bulletins (si étudiant ou parent)
    if (showBulletins) {
      pages.add(const BulletinScreen());
      destinations.add(
        const NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment_rounded),
          label: 'Bulletins',
        ),
      );
    }

    // 4. Paiements (si parent)
    if (isParent) {
      pages.add(const PaiementScolariteScreen());
      destinations.add(
        const NavigationDestination(
          icon: Icon(Icons.payment_outlined),
          selectedIcon: Icon(Icons.payment_rounded),
          label: 'Paiements',
        ),
      );
    }

    // 5/6. Planning
    pages.add(const PlanningTab());
    destinations.add(
      const NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month_rounded),
        label: 'Planning',
      ),
    );

    // 6/7. IA
    pages.add(ChatIAScreen(profile: widget.profile));
    destinations.add(
      const NavigationDestination(
        icon: Icon(Icons.smart_toy_outlined),
        selectedIcon: Icon(Icons.smart_toy_rounded),
        label: 'IA',
      ),
    );

    // 7/8. Profil
    pages.add(ProfileTab(profile: widget.profile, onLogout: widget.onLogout));
    destinations.add(
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profil',
      ),
    );

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
        destinations: destinations,
      ),
    );
  }
}

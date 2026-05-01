import 'package:flutter/material.dart';

import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import 'courses_tab.dart';
import 'home_tab.dart';
import 'notes_tab.dart';
import 'planning_tab.dart';
import 'profile_tab.dart';

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
    final pages = [
      HomeTab(profile: widget.profile),
      const CoursesTab(),
      const NotesTab(),
      const PlanningTab(),
      ProfileTab(profile: widget.profile, onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(
            key: ValueKey(_currentTab),
            child: pages[_currentTab],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppPalette.white,
        indicatorColor: AppPalette.yellow.withValues(alpha: 0.45),
        selectedIndex: _currentTab,
        onDestinationSelected: (index) {
          setState(() {
            _currentTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Cours',
          ),
          NavigationDestination(
            icon: Icon(Icons.grading_outlined),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Planning',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

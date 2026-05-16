import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import 'courses_tab.dart';
import 'home_tab.dart';
import 'notes_tab.dart';
import 'planning_tab.dart';
import 'profile_tab.dart';
import 'chat_ia_screen.dart';

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

  // Historique des onglets visités (pour revenir en arrière)
  final List<int> _historique = [0];

  void _onTabSelected(int index) {
    if (index == _currentTab) return;
    setState(() {
      _historique.add(index);
      _currentTab = index;
    });
  }

  // Retour à l'onglet précédent
  Future<bool> _onWillPop() async {
    if (_historique.length > 1) {
      setState(() {
        _historique.removeLast();
        _currentTab = _historique.last;
      });
      return false; // ne pas quitter l'app
    }

    // Si on est déjà sur l'accueil, demander confirmation pour quitter
    final quitter = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Quitter l\'application',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
        content: const Text('Voulez-vous vraiment quitter ScolarHub ?',
            style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler',
                style: TextStyle(fontSize: 15, color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Quitter',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return quitter ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(profile: widget.profile),
      const CoursesTab(),
      const NotesTab(),
      const PlanningTab(),
      ChatIAScreen(profile: widget.profile),
      ProfileTab(profile: widget.profile, onLogout: widget.onLogout),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
          onDestinationSelected: _onTabSelected,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Cours',
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
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy_rounded),
              label: 'IA',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
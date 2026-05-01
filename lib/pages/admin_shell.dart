import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../pages/admin_dashboard.dart';
import '../pages/admin_etudiants.dart';
import '../pages/admin_filieres.dart';
import '../pages/admin_reclamations.dart';
import '../pages/admin_comptes.dart';
import '../pages/admin_notes.dart';
import '../pages/admin_communications.dart';
import '../pages/splash_screen.dart';
import '../theme/app_palette.dart';

class AdminShell extends StatefulWidget {
  final StudentProfile profile;
  final VoidCallback onLogout;
  const AdminShell({super.key, required this.profile, required this.onLogout});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      AdminDashboard(profile: widget.profile),
      const AdminEtudiants(),
      const AdminNotes(),
      const AdminCommunications(),
      const AdminReclamations(),
      const AdminFilieres(),
      const AdminComptes(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppPalette.blue,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 9),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined, size: 22),
              activeIcon: Icon(Icons.dashboard_rounded, size: 22),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline, size: 22),
              activeIcon: Icon(Icons.people_rounded, size: 22),
              label: 'Étudiants',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grade_outlined, size: 22),
              activeIcon: Icon(Icons.grade_rounded, size: 22),
              label: 'Notes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined, size: 22),
              activeIcon: Icon(Icons.campaign_rounded, size: 22),
              label: 'Comms',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem_outlined, size: 22),
              activeIcon: Icon(Icons.report_problem_rounded, size: 22),
              label: 'Réclamations',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined, size: 22),
              activeIcon: Icon(Icons.school_rounded, size: 22),
              label: 'Filières',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts_outlined, size: 22),
              activeIcon: Icon(Icons.manage_accounts_rounded, size: 22),
              label: 'Comptes',
            ),
          ],
        ),
      ),
    );
  }
}

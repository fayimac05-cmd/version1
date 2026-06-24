import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import 'home_tab.dart';
import 'profile_tab.dart';
import 'notifications_page.dart';

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
    // Détection de la largeur de l'écran
    final double width = MediaQuery.of(context).size.width;
    final bool isLargeScreen = width >= 768; // Mode Tablette / PC

    // Liste des pages principales
    final pages = [
      HomeTab(profile: widget.profile),
      NotificationsPage(),
      const CoursesTab(),
      ProfileTab(profile: widget.profile, onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey(_currentTab),
          child: pages[_currentTab],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, Icons.home_rounded,
                    'Accueil', 0),
                _buildNavItem(
                    Icons.notifications_outlined,
                    Icons.notifications_rounded,
                    'Notifications',
                    1,
                    badge: 3),
                // Center home button (elevated)
                _buildCenterButton(),
                _buildNavItem(Icons.person_outline, Icons.person_rounded,
                    'Profil', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, IconData activeIcon, String label, int index,
      {int? badge}) {
    final isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? AppPalette.blue : AppPalette.grey,
                  size: 24,
                ),
                if (badge != null)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('$badge',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? AppPalette.blue : AppPalette.grey,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: () => setState(() => _currentTab = 0),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppPalette.blue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppPalette.blue.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.home_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}
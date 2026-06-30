import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import 'home_tab.dart';
import 'planning_tab.dart';
import 'profile_tab.dart';
import 'canal_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(profile: widget.profile),
      CanalScreen(profile: widget.profile),
      const PlanningTab(),
      ChatIAScreen(profile: widget.profile, showBack: false),
      ProfileTab(profile: widget.profile, onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey(_currentTab),
          child: pages[_currentTab],
        ),
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _navItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Accueil',
                index: 0,
                activeColor: AppPalette.blue,
              ),
              _navItem(
                icon: Icons.forum_outlined,
                activeIcon: Icons.forum_rounded,
                label: 'Canaux',
                index: 1,
                activeColor: AppPalette.yellow,
              ),
              _centerBtn(),
              _navItem(
                icon: Icons.smart_toy_outlined,
                activeIcon: Icons.smart_toy_rounded,
                label: 'Chat IA',
                index: 3,
                activeColor: AppPalette.blue,
              ),
              _navItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
                index: 4,
                activeColor: const Color(0xFF42A5F5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required Color activeColor,
    int? badge,
  }) {
    final isActive = _currentTab == index;
    final bgColor = isActive
        ? activeColor.withValues(alpha: 0.13)
        : const Color(0xFFF4F5F7);

    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 36,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      isActive ? activeIcon : icon,
                      size: 22,
                      color: isActive ? activeColor : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppPalette.yellow,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text('$badge',
                            style: const TextStyle(
                                color: Color(0xFF3A2A00),
                                fontSize: 8,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : const Color(0xFF9CA3AF),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centerBtn() {
    final isActive = _currentTab == 2;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isActive ? AppPalette.darkBlue : const Color(0xFF1A3F6F),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppPalette.blue.withValues(alpha: 0.40),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.calendar_month_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _currentTab == 2
                  ? const Color(0xFF1A3F6F)
                  : const Color(0xFF9CA3AF),
            ),
            child: const Text('Planning'),
          ),
        ],
      ),
    );
  }
}

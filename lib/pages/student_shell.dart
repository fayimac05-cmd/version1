import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import 'home_tab.dart';
import 'profile_tab.dart';
import 'canal_screen.dart';
import 'chat_ia_screen.dart';
import 'app_drawer.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Copie mutable du profil, tenue à jour après un changement de photo/
  // couverture (voir _onPhotoChanged) — propage la nouvelle photo à TOUTE
  // l'app (accueil, canaux, drawer...), pas seulement à l'écran Profil.
  late StudentProfile _profile = widget.profile;

  void _onPhotoChanged(String? photoUrl, String? coverUrl) {
    setState(() {
      _profile = _profile.copyWith(photoUrl: photoUrl, coverUrl: coverUrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(
        profile: _profile,
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      CanalScreen(profile: _profile),
      ChatIAScreen(profile: _profile, showBack: false),
      ProfileTab(profile: _profile, onLogout: widget.onLogout, onPhotoChanged: _onPhotoChanged),
    ];

    return Scaffold(
      key: _scaffoldKey,
      // Menu latéral : regroupe Planning, Chat IA, Révisions IA, Tickets
      drawer: AppDrawer(profile: _profile),
      // ✅ CORRIGÉ — IndexedStack au lieu d'AnimatedSwitcher+KeyedSubtree :
      // l'ancienne version détruisait et recréait entièrement l'écran de
      // l'onglet à chaque changement (clé différente à chaque fois), ce qui
      // effaçait l'état local de ProfileHeaderCover (photo/couverture tout
      // juste changées) dès qu'on quittait l'onglet Profil puis y revenait —
      // elles redémarraient alors depuis widget.profile.photoUrl, jamais mis
      // à jour. IndexedStack garde tous les onglets vivants en mémoire, donc
      // cet état survit — même comportement que ParentShell, où ça
      // fonctionnait déjà.
      body: IndexedStack(
        index: _currentTab,
        children: pages,
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
              _navItem(
                icon: Icons.smart_toy_outlined,
                activeIcon: Icons.smart_toy_rounded,
                label: 'Chat IA',
                index: 2,
                activeColor: AppPalette.blue,
              ),
              _navItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
                index: 3,
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
}
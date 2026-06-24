import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import 'home_tab.dart';
import 'courses_tab.dart';
import 'notes_tab.dart';
import 'planning_tab.dart';
import 'profile_tab.dart';
import 'chat_ia_screen.dart';
import 'bulletin_screen.dart';
import 'groupe_filiere_screen.dart';
import 'tickets_screen.dart';
import 'canal_screen.dart';

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
      const CoursesTab(),
      const NotesTab(),
      const PlanningTab(),
      ProfileTab(profile: widget.profile, onLogout: widget.onLogout),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      
      // Menu Tiroir : Uniquement sur Mobile
      drawer: isLargeScreen ? null : _buildMobileDrawer(context),
      
      // Barre supérieure : Uniquement sur Mobile
      appBar: isLargeScreen 
        ? null 
        : AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'ScolarHub',
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
            actions: [
              GestureDetector(
                onTap: () => setState(() => _currentTab = 4),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppPalette.blue.withOpacity(0.1),
                    child: Text(
                      '${widget.profile.prenoms.isNotEmpty ? widget.profile.prenoms[0] : ''}${widget.profile.nom.isNotEmpty ? widget.profile.nom[0] : ''}'.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppPalette.blue),
                    ),
                  ),
                ),
              )
            ],
          ),

      body: Row(
        children: [
          // ÉCRAN LARGE : Barre latérale corrigée (Sidebar)
          if (isLargeScreen) _buildSidebar(context),

          // Contenu principal de l'onglet actif
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(_currentTab),
                child: pages[_currentTab],
              ),
            ),
          ),
        ],
      ),
      
      // ÉCRAN MOBILE : Barre basse simplifiée (Texte synchronisé sur "Programme")
      bottomNavigationBar: isLargeScreen
          ? null 
          : Container(
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, -4)),
                ],
                border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMobileTabItem(0, 'Accueil', Icons.home_rounded, Icons.home_outlined),
                  _buildMobileTabItem(1, 'Cours', Icons.menu_book_rounded, Icons.menu_book_outlined),
                  _buildMobileTabItem(2, 'Notes', Icons.grading_rounded, Icons.grading_outlined),
                  _buildMobileTabItem(3, 'Programme', Icons.calendar_month_rounded, Icons.calendar_month_outlined), // Mis à jour ici aussi !
                ],
              ),
            ),
    );
  }

  // ── DESIGN MOBILE : Onglet bas ──
  Widget _buildMobileTabItem(int index, String label, IconData iconActive, IconData iconInactive) {
    final bool isActive = _currentTab == index;
    final Color itemColor = isActive ? AppPalette.blue : const Color(0xFF94A3B8);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? iconActive : iconInactive, size: 22, color: itemColor),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: itemColor),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 3, width: isActive ? 12 : 0,
              decoration: BoxDecoration(color: AppPalette.yellow, borderRadius: BorderRadius.circular(2)),
            )
          ],
        ),
      ),
    );
  }

  // ── DESIGN MOBILE : Tiroir latéral ──
  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1E40AF)),
            accountName: Text('${widget.profile.prenoms} ${widget.profile.nom}', style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(widget.profile.filiere.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.white70)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                '${widget.profile.prenoms.isNotEmpty ? widget.profile.prenoms[0] : ''}'.toUpperCase(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
              ),
            ),
          ),
          _buildDrawerItem(Icons.smart_toy_rounded, 'Assistant IA', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatIAScreen(profile: widget.profile)));
          }),
          _buildDrawerItem(Icons.assignment_rounded, 'Mes Bulletins', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BulletinScreen()));
          }),
          _buildDrawerItem(Icons.diversity_3_rounded, 'Ma Classe', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => GroupeFiliere(profile: widget.profile)));
          }),
          _buildDrawerItem(Icons.receipt_long_rounded, 'Scolarité & Finances', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => TicketsScreen(profile: widget.profile)));
          }),
          _buildDrawerItem(Icons.chat_bubble_outline_rounded, 'Canaux de discussion', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => CanalScreen(profile: widget.profile)));
          }),
          const Divider(height: 30, color: Color(0xFFE2E8F0)),
          _buildDrawerItem(Icons.person_outline_rounded, 'Mon Profil', () {
            Navigator.pop(context);
            setState(() => _currentTab = 4);
          }),
          const Spacer(),
          _buildDrawerItem(Icons.logout_rounded, 'Déconnexion', widget.onLogout, iconColor: Colors.redAccent),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color iconColor = const Color(0xFF64748B)}) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  // ── DESIGN PC & TABLETTE : Barre latérale corrigée ──
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Correction de l'icône : Remplacement de l'emoji chapeau par une icône matérielle
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Row(
              children: [
                Icon(Icons.school_rounded, color: AppPalette.blue, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'ScolarHub',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppPalette.blue, letterSpacing: -0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildSidebarItem(0, 'Tableau de bord', Icons.grid_view_rounded),
          _buildSidebarItem(1, 'Mes Cours', Icons.menu_book_rounded),
          _buildSidebarItem(2, 'Notes & Évaluations', Icons.grading_rounded),
          _buildSidebarItem(3, 'Programme hebdomadaire', Icons.calendar_month_rounded),
          _buildSidebarItem(4, 'Mon Profil étudiant', Icons.person_rounded),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Divider(color: Color(0xFFE2E8F0)),
          ),
          _buildSidebarShortcut('Assistant IA', Icons.smart_toy_rounded, const Color(0xFF6366F1), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatIAScreen(profile: widget.profile)));
          }),
          _buildSidebarShortcut('Bulletins de notes', Icons.assignment_rounded, const Color(0xFF0EA5E9), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BulletinScreen()));
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: widget.onLogout,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    SizedBox(width: 12),
                    Text('Déconnexion', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, String label, IconData icon) {
    final bool isActive = _currentTab == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _currentTab = index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppPalette.blue.withOpacity(0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: isActive ? AppPalette.blue : const Color(0xFF64748B), size: 22),
              const SizedBox(width: 14),
              // CORRECTION DES OVERFLOWS : Utilisation de Expanded + TextOverflow.ellipsis
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? AppPalette.blue : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarShortcut(String label, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 14),
              // CORRECTION DES OVERFLOWS ICI AUSSI AU CAS OÙ
              Expanded(
                child: Text(
                  label, 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
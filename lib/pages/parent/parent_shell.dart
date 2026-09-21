import 'package:flutter/material.dart';
import '../../models/student_profile.dart';
import '../../models/enfant_apercu.dart';
import '../../services/parent_service.dart';
import 'parent_styles.dart';
import 'parent_home_tab.dart';
import 'parent_grades_tab.dart';
import 'parent_bulletins_tab.dart';
import 'parent_schedule_tab.dart';
import 'parent_profile_tab.dart';

class ParentShell extends StatefulWidget {
  final StudentProfile profile;
  final VoidCallback onLogout;

  const ParentShell({
    super.key,
    required this.profile,
    required this.onLogout,
  });

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _tabIndex = 0;
  bool _loading = true;
  String? _error;
  List<EnfantApercu> _enfants = [];
  String? _selectedEtudiantId;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ParentService.getMesEnfants();
    if (!mounted) return;
    if (result['success'] == true) {
      final data = (result['data'] as List<dynamic>)
          .map((e) => EnfantApercu.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      setState(() {
        _enfants = data;
        _selectedEtudiantId ??= data.isNotEmpty ? data.first.etudiantId : null;
        _loading = false;
      });
    } else {
      setState(() {
        _error = result['error']?.toString() ?? 'Impossible de charger vos enfants.';
        _loading = false;
      });
    }
  }

  EnfantApercu? get _selected =>
      _enfants.where((e) => e.etudiantId == _selectedEtudiantId).firstOrNull;

  void _selectionnerEnfant(String etudiantId) {
    setState(() => _selectedEtudiantId = etudiantId);
  }

  void _naviguerVersOnglet(int index) {
    setState(() => _tabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _enfants.isEmpty) {
      return Scaffold(
        backgroundColor: ParentStyles.bgLight,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.family_restroom_rounded, size: 56, color: Color(0xFFD1D5DB)),
                  const SizedBox(height: 12),
                  Text(
                    _error ?? 'Aucun enfant rattaché à ce compte.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: ParentStyles.textMuted),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _charger,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Réessayer'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(onPressed: widget.onLogout, child: const Text('Se déconnecter')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final selected = _selected;

    return Scaffold(
      backgroundColor: ParentStyles.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            if (_enfants.length > 1) _selecteurEnfants(),
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  ParentHomeTab(
                    enfants: _enfants,
                    selectedEtudiantId: _selectedEtudiantId,
                    onSelectEnfant: _selectionnerEnfant,
                    onNavigateToTab: _naviguerVersOnglet,
                  ),
                  if (selected != null)
                    ParentGradesTab(
                      key: ValueKey('notes-${selected.etudiantId}'),
                      nomEnfant: selected.nomComplet,
                      etudiantId: selected.etudiantId,
                    )
                  else
                    const SizedBox.shrink(),
                  if (selected != null)
                    ParentBulletinsTab(
                      key: ValueKey('bulletins-${selected.etudiantId}'),
                      nomEnfant: selected.nomComplet,
                      etudiantId: selected.etudiantId,
                    )
                  else
                    const SizedBox.shrink(),
                  if (selected != null)
                    ParentScheduleTab(
                      key: ValueKey('planning-${selected.etudiantId}'),
                      nomEnfant: selected.nomComplet,
                      filiere: selected.filiere,
                      niveau: selected.niveau,
                    )
                  else
                    const SizedBox.shrink(),
                  ParentProfileTab(
                    enfants: _enfants,
                    onLogout: widget.onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) {
          setState(() => _tabIndex = i);
          if (selected != null) {
            if (i == 1) ParentService.marquerConsulte(selected.etudiantId, 'notes');
            if (i == 2) ParentService.marquerConsulte(selected.etudiantId, 'bulletins');
          }
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Accueil'),
          NavigationDestination(
            icon: _iconAvecBadge(Icons.grading_outlined, _enfants.any((e) => e.notesNonLues > 0)),
            selectedIcon: const Icon(Icons.grading_rounded),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: _iconAvecBadge(Icons.workspace_premium_outlined, _enfants.any((e) => e.bulletinsNonLus > 0)),
            selectedIcon: const Icon(Icons.workspace_premium_rounded),
            label: 'Bulletins',
          ),
          const NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Planning'),
          const NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _iconAvecBadge(IconData icon, bool afficherBadge) => Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon),
          if (afficherBadge)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
              ),
            ),
        ],
      );

  Widget _selecteurEnfants() => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: ParentStyles.borderLight)),
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _enfants.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final e = _enfants[i];
            final actif = e.etudiantId == _selectedEtudiantId;
            final aDuNouveau = e.notesNonLues > 0 || e.bulletinsNonLus > 0;
            return GestureDetector(
              onTap: () => _selectionnerEnfant(e.etudiantId),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: actif ? ParentStyles.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: actif ? ParentStyles.primary : ParentStyles.borderLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.prenoms.isNotEmpty ? e.prenoms : e.nomComplet,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: actif ? Colors.white : ParentStyles.textDark,
                      ),
                    ),
                    if (aDuNouveau) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: actif ? Colors.white : Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      );
}
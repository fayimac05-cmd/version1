import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import '../models/student_profile.dart';

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
      _ParentAccueilTab(nomEnfant: widget.nomEnfant),
      _ParentNotesTab(nomEnfant: widget.nomEnfant),
      _ParentPlanningTab(),
      _ParentProfilTab(onLogout: widget.onLogout),
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
        onDestinationSelected: (index) =>
            setState(() => _currentTab = index),
        labelBehavior:
            NavigationDestinationLabelBehavior.alwaysShow,
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
        ],
      ),
    );
  }
}

// ─── ONGLET ACCUEIL ───────────────────────────────────────
class _ParentAccueilTab extends StatelessWidget {
  const _ParentAccueilTab({required this.nomEnfant});
  final String nomEnfant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bonjour 👋',
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text('Espace Parent',
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPalette.yellow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppPalette.yellow.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_rounded,
                    size: 40, color: AppPalette.yellow),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enfant suivi',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey)),
                    Text(nomEnfant,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const Text('IST Campus Ouaga 2000',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Résumé',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                  icon: Icons.grading_rounded,
                  label: 'Notes',
                  value: 'Voir',
                  color: Colors.blue),
              const SizedBox(width: 12),
              _StatCard(
                  icon: Icons.calendar_month_rounded,
                  label: 'Planning',
                  value: 'Voir',
                  color: Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: const [
                Icon(Icons.notifications_active_rounded,
                    color: Colors.red),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aucune alerte pour le moment.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

// ─── ONGLET NOTES ─────────────────────────────────────────
class _ParentNotesTab extends StatelessWidget {
  const _ParentNotesTab({required this.nomEnfant});
  final String nomEnfant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notes de l\'enfant',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Suivi académique de $nomEnfant',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: const [
                _NoteCard(
                    matiere: 'Mathématiques',
                    note: 15.5,
                    status: 'validé'),
                _NoteCard(
                    matiere: 'Réseaux',
                    note: 12.0,
                    status: 'validé'),
                _NoteCard(
                    matiere: 'Programmation',
                    note: 8.0,
                    status: 'danger'),
                _NoteCard(
                    matiere: 'Anglais',
                    note: 6.5,
                    status: 'blâmable'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard(
      {required this.matiere,
      required this.note,
      required this.status});
  final String matiere;
  final double note;
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    if (status == 'validé') {
      color = Colors.green;
      icon = Icons.check_circle_rounded;
    } else if (status == 'danger') {
      color = Colors.orange;
      icon = Icons.warning_rounded;
    } else {
      color = Colors.red;
      icon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Text(matiere,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          Text('$note / 20',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16)),
        ],
      ),
    );
  }
}

// ─── ONGLET PLANNING ──────────────────────────────────────
class _ParentPlanningTab extends StatelessWidget {
  const _ParentPlanningTab();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Emploi du temps',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Center(
            child: Text('Planning de la semaine\n(à venir)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

// ─── ONGLET PROFIL ────────────────────────────────────────
class _ParentProfilTab extends StatelessWidget {
  const _ParentProfilTab({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mon Profil',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppPalette.yellow,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text('Parent / Tuteur',
              style: TextStyle(color: Colors.grey)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Se déconnecter',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
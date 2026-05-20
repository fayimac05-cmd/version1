import 'package:flutter/material.dart';

import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import '../pages/class_detail_screen.dart';
import '../pages/splash_screen.dart';
import '../pages/professor_course_detail_screen.dart';

class ProfessorShell extends StatefulWidget {
  const ProfessorShell({
    super.key,
    required this.profile,
    required this.onLogout,
  });

  final StudentProfile profile;
  final VoidCallback onLogout;

  @override
  State<ProfessorShell> createState() => _ProfessorShellState();
}

class _ProfessorShellState extends State<ProfessorShell> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _ClassTab(),
      const _CoursesTab(),
      const _SendGradesTab(),
      _ProfessorProfileTab(profile: widget.profile, onLogout: widget.onLogout),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey(_currentTab),
            child: pages[_currentTab],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppPalette.white,
        indicatorColor: const Color(0xFFDDEBFF),
        selectedIndex: _currentTab,
        onDestinationSelected: (index) => setState(() => _currentTab = index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Classes',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Cours',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Notes',
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

class _ProfessorPage extends StatelessWidget {
  const _ProfessorPage({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    );
  }
}

class _ClassTab extends StatelessWidget {
  const _ClassTab();

  @override
  Widget build(BuildContext context) {
    return _ProfessorPage(
      title: 'Mes classes',
      subtitle: 'Suivez les effectifs et le détail de vos classes actives.',
      children: [
        const _MetricRow(),
        const SizedBox(height: 16),
        _InfoCard(
          icon: Icons.school_rounded,
          title: 'Licence 2 Réseaux & Telecom',
          subtitle: '38 étudiants inscrits, 4 groupes de TD',
          tag: 'Gérer',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ClassDetailScreen(
                  className: 'Licence 2 Réseaux & Telecom',
                  studentCount: 38,
                ),
              ),
            );
          },
        ),
        _InfoCard(
          icon: Icons.school_rounded,
          title: 'Licence 3 Informatique',
          subtitle: '45 étudiants inscrits, 5 groupes de TD',
          tag: 'Gérer',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ClassDetailScreen(
                  className: 'Licence 3 Informatique',
                  studentCount: 45,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CoursesTab extends StatelessWidget {
  const _CoursesTab();

  @override
  Widget build(BuildContext context) {
    final courses = [
      {
        'name': 'Réseaux Informatiques',
        'class': 'Licence 2 Réseaux & Telecom',
        'students': '38 étudiants',
      },
      {
        'name': 'Architecture Réseau',
        'class': 'Licence 2 Réseaux & Telecom',
        'students': '38 étudiants',
      },
      {
        'name': 'Administration Linux',
        'class': 'Licence 3 Informatique',
        'students': '45 étudiants',
      },
    ];

    return _ProfessorPage(
      title: 'Mes cours',
      subtitle: 'Sélectionnez un cours pour gérer et publier les supports.',
      children: courses.map((course) {
        return _InfoCard(
          icon: Icons.menu_book_rounded,
          title: course['name']!,
          subtitle: '${course['class']} • ${course['students']}',
          tag: 'Détail',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfessorCourseDetailScreen(
                  courseName: course['name']!,
                  className: course['class']!,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

class _SendGradesTab extends StatefulWidget {
  const _SendGradesTab();

  @override
  State<_SendGradesTab> createState() => _SendGradesTabState();
}

class _SendGradesTabState extends State<_SendGradesTab> {
  final _courseCtrl = TextEditingController(text: 'Réseaux informatiques');
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _courseCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _send() {
    if (_notesCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir des notes ou commentaires.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notes envoyées avec succès au secrétariat académique !'),
        backgroundColor: Color(0xFF15803D),
      ),
    );
    _notesCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return _ProfessorPage(
      title: 'Saisie des notes',
      subtitle:
          'Formulaire de saisie et de transmission des notes des étudiants.',
      children: [
        _FormCard(
          children: [
            _Input(
              controller: _courseCtrl,
              label: 'Module ou Matière',
              icon: Icons.menu_book_outlined,
            ),
            const SizedBox(height: 14),
            _Input(
              controller: _notesCtrl,
              label: 'Notes (ex: Alexandre: 15/20, Marie: 18/20...)',
              icon: Icons.edit_note_rounded,
              maxLines: 5,
            ),
            const SizedBox(height: 18),
            _PrimaryButton(
              label: 'Transmettre au secrétariat',
              icon: Icons.send_rounded,
              onPressed: _send,
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfessorProfileTab extends StatelessWidget {
  const _ProfessorProfileTab({required this.profile, required this.onLogout});

  final StudentProfile profile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return _ProfessorPage(
      title: 'Mon Profil',
      subtitle: 'Espace Enseignant Universitaire',
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppPalette.yellow, width: 3),
                ),
                child: const CircleAvatar(
                  radius: 40,
                  backgroundColor: AppPalette.blue,
                  child: Icon(Icons.school, size: 48, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Dr. ${profile.prenoms} ${profile.nom}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Text(
                'Enseignant - Chercheur',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Divider(color: Color(0xFFE2E8F0)),
        const SizedBox(height: 16),
        const Text(
          'Détails Professionnels',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        _infoLigne(
          Icons.alternate_email,
          'Email Académique',
          '${profile.prenoms.toLowerCase()}.${profile.nom.toLowerCase()}@ist.bf',
        ),
        const SizedBox(height: 12),
        _infoLigne(Icons.phone_outlined, 'Téléphone', '+226 75 00 00 00'),
        const SizedBox(height: 12),
        _infoLigne(Icons.domain_rounded, 'Département', profile.filiere),
        const SizedBox(height: 12),
        _infoLigne(
          Icons.class_outlined,
          'Responsabilité',
          'Responsable de la filière R&T',
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.red),
                      SizedBox(width: 10),
                      Text(
                        'Déconnexion',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    'Voulez-vous vous déconnecter ?',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const SplashScreen(),
                          ),
                          (_) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Déconnecter'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoLigne(IconData icon, String lbl, String val) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lbl,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              val,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppPalette.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppPalette.blue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              tag,
              style: const TextStyle(
                fontSize: 12,
                color: AppPalette.blue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _MetricCard(value: '38', label: 'Etudiants'),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MetricCard(value: '4', label: 'Groupes'),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MetricCard(value: '92%', label: 'Presence'),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppPalette.blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(children: children),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = AppPalette.blue,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

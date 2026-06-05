import 'package:flutter/material.dart';

import '../models/class_model.dart';
import '../models/student_profile.dart';
import '../pages/professor_course_detail_screen.dart';
import '../theme/app_palette.dart';
import 'class_detail_screen.dart';
import 'mock_data.dart';

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
      const _ClassesTab(),
      const _CoursesTab(),
      const _GradesTab(),
      _ProfessorProfileTab(profile: widget.profile, onLogout: widget.onLogout),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(child: pages[_currentTab]),
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

class _ClassesTab extends StatelessWidget {
  const _ClassesTab();

  @override
  Widget build(BuildContext context) {
    return _ProfessorPage(
      title: 'Mes classes',
      subtitle: 'Suivez les effectifs et ouvrez le detail de chaque classe.',
      children: [
        const _MetricRow(),
        const SizedBox(height: 16),
        ...mockClasses.map((classData) => _ClassCard(classData: classData)),
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.classData});

  final ClassModel classData;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.school_rounded,
      title: classData.name,
      subtitle: '${classData.students.length} etudiants - ${classData.level}',
      tag: 'Gerer',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClassDetailScreen(classData: classData),
          ),
        );
      },
    );
  }
}

class _CoursesTab extends StatelessWidget {
  const _CoursesTab();

  static const _courses = [
    {'name': 'Reseaux informatiques', 'class': 'Licence 2 R&T'},
    {'name': 'Bases de donnees', 'class': 'Licence 2 Informatique'},
    {'name': 'Developpement mobile', 'class': 'Licence 3 Informatique'},
  ];

  @override
  Widget build(BuildContext context) {
    return _ProfessorPage(
      title: 'Supports de cours',
      subtitle: 'Publiez et consultez les supports disponibles par classe.',
      children: [
        ..._courses.map(
          (course) => _InfoCard(
            icon: Icons.menu_book_rounded,
            title: course['name']!,
            subtitle: course['class']!,
            tag: 'Ouvrir',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfessorCourseDetailScreen(
                    courseName: course['name']!,
                    className: course['class']!,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GradesTab extends StatefulWidget {
  const _GradesTab();

  @override
  State<_GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends State<_GradesTab> {
  final _moduleCtrl = TextEditingController(text: 'Reseaux informatiques');

  @override
  void dispose() {
    _moduleCtrl.dispose();
    super.dispose();
  }

  void _createSession() {
    final classData = mockClasses.first;
    final session = GradeSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      classId: classData.id,
      className: classData.name,
      date: DateTime.now(),
      moduleName: _moduleCtrl.text.trim().isEmpty
          ? 'Module sans titre'
          : _moduleCtrl.text.trim(),
      grades: classData.students
          .map(
            (student) => StudentGrade(
              matricule: student.matricule,
              name: '${student.prenoms} ${student.nom}',
            ),
          )
          .toList(),
    );

    setState(() => GlobalStore.gradeSessions.insert(0, session));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session de notes creee.'),
        backgroundColor: Color(0xFF15803D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessions = GlobalStore.gradeSessions;

    return _ProfessorPage(
      title: 'Notes',
      subtitle: 'Preparez les sessions de notes et suivez leur statut.',
      children: [
        _FormCard(
          children: [
            TextField(
              controller: _moduleCtrl,
              decoration: const InputDecoration(
                labelText: 'Module ou matiere',
                prefixIcon: Icon(Icons.menu_book_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _PrimaryButton(
              label: 'Creer une session',
              icon: Icons.add_task_rounded,
              onPressed: _createSession,
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (sessions.isEmpty)
          const _EmptyState()
        else
          ...sessions.map(
            (session) => _InfoCard(
              icon: session.isSent
                  ? Icons.verified_rounded
                  : Icons.pending_actions_rounded,
              title: session.className,
              subtitle:
                  '${session.moduleName} - ${session.date.day}/${session.date.month}/${session.date.year}',
              tag: session.isSent ? 'Envoye' : 'Pret',
              onTap: () => setState(() => session.isSent = true),
            ),
          ),
      ],
    );
  }
}

// ── Onglet Profil ─────────────────────────────────────────────────────────────
class _ProfessorProfileTab extends StatelessWidget {
  const _ProfessorProfileTab({required this.profile, required this.onLogout});

  final StudentProfile profile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return _ProfessorPage(
      title: 'Mon profil',
      subtitle: 'Espace enseignant',
      children: [
        Center(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: AppPalette.blue,
                child: Icon(Icons.school, size: 46, color: Colors.white),
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
              Text(
                profile.filiere,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const Text('Enseignant - Chercheur', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _ProfileLine(
          icon: Icons.alternate_email,
          label: 'Email',
          value:
              '${profile.prenoms.toLowerCase()}.${profile.nom.toLowerCase()}@ist.bf',
        ),
        _ProfileLine(
          icon: Icons.badge_outlined,
          label: 'Matricule',
          value: profile.matricule,
        ),
        _ProfileLine(
          icon: Icons.domain_rounded,
          label: 'Departement',
          value: profile.filiere,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'Se deconnecter',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Widgets partagés ──────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 5),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(tag, style: const TextStyle(fontSize: 12, color: AppPalette.blue, fontWeight: FontWeight.w700)),
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
    final students = mockClasses.fold<int>(
      0,
      (sum, classData) => sum + classData.students.length,
    );

    return Row(
      children: [
        Expanded(
          child: _MetricCard(value: '$students', label: 'Etudiants'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(value: '${mockClasses.length}', label: 'Classes'),
        ),
        const SizedBox(width: 12),
        const Expanded(
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
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppPalette.blue)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

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
          backgroundColor: AppPalette.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_rounded, size: 60, color: Color(0xFFCBD5E1)),
          SizedBox(height: 16),
          Text(
            'Aucune note en attente',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
          ),
        ],
      ),
    );
  }
}

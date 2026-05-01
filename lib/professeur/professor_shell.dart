import 'package:flutter/material.dart';

import '../models/student_profile.dart';
import '../theme/app_palette.dart';

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
      _ProgramTab(profile: widget.profile),
      const _ClassTab(),
      const _UploadCourseTab(),
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
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Programme',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Classe',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_file_outlined),
            selectedIcon: Icon(Icons.upload_file_rounded),
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

class _ProgramTab extends StatelessWidget {
  const _ProgramTab({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    return _ProfessorPage(
      title: 'Mon programme',
      subtitle:
          'Bienvenue ${profile.prenoms}. Voici vos cours et seances de la semaine.',
      children: const [
        _InfoCard(
          icon: Icons.computer_rounded,
          title: 'Lundi, 08:00 - 10:00',
          subtitle: 'Reseaux informatiques - Licence 2',
          tag: 'Salle B12',
        ),
        _InfoCard(
          icon: Icons.hub_rounded,
          title: 'Mercredi, 10:15 - 12:15',
          subtitle: 'Architecture reseau - Licence 2',
          tag: 'Labo 2',
        ),
        _InfoCard(
          icon: Icons.assignment_rounded,
          title: 'Vendredi, 14:00 - 16:00',
          subtitle: 'Travaux diriges et evaluation continue',
          tag: 'Salle A04',
        ),
      ],
    );
  }
}

class _ClassTab extends StatelessWidget {
  const _ClassTab();

  @override
  Widget build(BuildContext context) {
    return _ProfessorPage(
      title: 'Ma classe',
      subtitle:
          'Suivez les effectifs, les groupes et les derniers points de classe.',
      children: const [
        _MetricRow(),
        SizedBox(height: 16),
        _InfoCard(
          icon: Icons.school_rounded,
          title: 'Licence 2 Reseaux & Telecom',
          subtitle: '38 etudiants inscrits, 4 groupes de TD',
          tag: 'Classe active',
        ),
        _InfoCard(
          icon: Icons.group_work_rounded,
          title: 'Groupes de travail',
          subtitle: 'Groupe A, B, C et D disponibles pour les devoirs.',
          tag: '4 groupes',
        ),
        _InfoCard(
          icon: Icons.warning_amber_rounded,
          title: 'Suivi pedagogique',
          subtitle: '3 etudiants a accompagner sur les derniers exercices.',
          tag: 'A verifier',
        ),
      ],
    );
  }
}

class _UploadCourseTab extends StatefulWidget {
  const _UploadCourseTab();

  @override
  State<_UploadCourseTab> createState() => _UploadCourseTabState();
}

class _UploadCourseTabState extends State<_UploadCourseTab> {
  final _titleCtrl = TextEditingController();
  final _chapterCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _chapterCtrl.dispose();
    super.dispose();
  }

  void _publish() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cours televerse et rendu disponible pour la classe.'),
        backgroundColor: Color(0xFF15803D),
      ),
    );
    _titleCtrl.clear();
    _chapterCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return _ProfessorPage(
      title: 'Televerser un cours',
      subtitle: 'Ajoutez un support de cours pour vos etudiants.',
      children: [
        _FormCard(
          children: [
            _Input(
              controller: _titleCtrl,
              label: 'Titre du cours',
              icon: Icons.title,
            ),
            const SizedBox(height: 14),
            _Input(
              controller: _chapterCtrl,
              label: 'Chapitre ou description',
              icon: Icons.notes,
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPalette.lightBlue,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppPalette.blue.withOpacity(0.18)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.attach_file_rounded, color: AppPalette.blue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Selection du fichier PDF, Word ou PowerPoint',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _PrimaryButton(
              label: 'Televerser le cours',
              icon: Icons.cloud_upload_rounded,
              onPressed: _publish,
            ),
          ],
        ),
      ],
    );
  }
}

class _SendGradesTab extends StatefulWidget {
  const _SendGradesTab();

  @override
  State<_SendGradesTab> createState() => _SendGradesTabState();
}

class _SendGradesTabState extends State<_SendGradesTab> {
  final _courseCtrl = TextEditingController(text: 'Reseaux informatiques');
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _courseCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _send() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notes envoyees a l administration.'),
        backgroundColor: Color(0xFF15803D),
      ),
    );
    _notesCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return _ProfessorPage(
      title: 'Envoyer les notes',
      subtitle: 'Transmettez les notes finalisees au service administratif.',
      children: [
        _FormCard(
          children: [
            _Input(
              controller: _courseCtrl,
              label: 'Matiere',
              icon: Icons.menu_book_outlined,
            ),
            const SizedBox(height: 14),
            _Input(
              controller: _notesCtrl,
              label: 'Notes ou commentaire',
              icon: Icons.edit_note_rounded,
              maxLines: 5,
            ),
            const SizedBox(height: 18),
            _PrimaryButton(
              label: 'Envoyer a l administration',
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
      title: 'Profil professeur',
      subtitle: 'Compte de demonstration professeur.',
      children: [
        _InfoCard(
          icon: Icons.person_rounded,
          title: '${profile.prenoms} ${profile.nom}',
          subtitle: profile.filiere,
          tag: 'Professeur',
        ),
        const SizedBox(height: 12),
        _PrimaryButton(
          label: 'Se deconnecter',
          icon: Icons.logout_rounded,
          onPressed: onLogout,
          color: const Color(0xFFDC2626),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
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

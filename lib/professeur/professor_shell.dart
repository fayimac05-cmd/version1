import 'package:flutter/material.dart';

import '../models/student_profile.dart';
import '../models/class_model.dart';
import '../theme/app_palette.dart';
import 'class_detail_screen.dart';
import 'confirm_screens.dart';
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
      _ProgramTab(profile: widget.profile),
      const _ClassTab(),
      const _UploadCourseTab(),
      _SendGradesTab(onNavigateToTab: (i) => setState(() => _currentTab = i)),
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
      title: 'Mes classes',
      subtitle:
          'Sélectionnez une classe pour faire l\'appel et gérer les notes.',
      children: [
        const _MetricRow(),
        const SizedBox(height: 16),
        ...mockClasses.asMap().entries.map(
          (entry) =>
              _AnimatedClassCard(classData: entry.value, index: entry.key),
        ),
      ],
    );
  }
}

class _AnimatedClassCard extends StatelessWidget {
  const _AnimatedClassCard({required this.classData, required this.index});

  final ClassModel classData;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Interval(
        (index * 0.1).clamp(0.0, 1.0),
        1.0,
        curve: Curves.easeOutQuart,
      ),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: _ClassCard(classData: classData),
    );
  }
}

class _ClassCard extends StatefulWidget {
  const _ClassCard({required this.classData});

  final ClassModel classData;

  @override
  State<_ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<_ClassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        Future.delayed(const Duration(milliseconds: 150), () {
          Navigator.of(context).push(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (context, animation, secondaryAnimation) {
                return FadeTransition(
                  opacity: animation,
                  child: ClassDetailScreen(classData: widget.classData),
                );
              },
            ),
          );
        });
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: AppPalette.blue.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Hero(
                  tag: 'class_icon_${widget.classData.id}',
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEAF2FF), Color(0xFFD3E4FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: AppPalette.blue,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'class_title_${widget.classData.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            widget.classData.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.classData.level} • ${widget.classData.students.length} étudiants',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppPalette.blue,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
  const _SendGradesTab({required this.onNavigateToTab});

  final void Function(int) onNavigateToTab;

  @override
  State<_SendGradesTab> createState() => _SendGradesTabState();
}

class _SendGradesTabState extends State<_SendGradesTab> {
  void _verifyAndSend(GradeSession session) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: GradeConfirmScreen(
            session: session,
            onConfirm: () {
              setState(() {
                session.isSent = true;
              });
              // After confirmation, navigate to Programme tab (index 0)
              Future.delayed(const Duration(milliseconds: 300), () {
                if (!mounted) return;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Notes envoyées !',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Vos notes ont été transmises avec succès à l\'administration.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPalette.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              widget.onNavigateToTab(0); // Retour au Programme
                            },
                            child: const Text(
                              'Retour au Programme',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessions = GlobalStore.gradeSessions;

    return _ProfessorPage(
      title: 'Notes en attente',
      subtitle: 'Vérifiez et envoyez vos notes à l\'administration.',
      children: [
        if (sessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(30),
            alignment: Alignment.center,
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
          )
        else
          ...sessions.reversed.map((session) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          session.className,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: session.isSent
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          session.isSent ? 'Envoyé' : 'À vérifier',
                          style: TextStyle(
                            color: session.isSent
                                ? const Color(0xFF166534)
                                : const Color(0xFF92400E),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Module : ${session.moduleName}',
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  Text(
                    'Date : ${session.date.day}/${session.date.month}/${session.date.year}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!session.isSent)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _verifyAndSend(session),
                        icon: const Icon(Icons.checklist_rtl_rounded),
                        label: const Text('Vérifier et envoyer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppPalette.blue,
                          side: const BorderSide(color: AppPalette.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
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

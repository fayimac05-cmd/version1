import 'package:flutter/material.dart';

import '../models/student_profile.dart';
import '../services/professor_service.dart';
import '../theme/app_palette.dart';
import 'edit_profile_screen.dart';
import 'grade_session_screen.dart';
import 'upload_course_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
      _ProfessorProfileTab(onLogout: widget.onLogout),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(child: pages[_currentTab]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: AppPalette.blue.withOpacity(0.15),
          selectedIndex: _currentTab,
          onDestinationSelected: (index) => setState(() => _currentTab = index),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded, color: AppPalette.blue),
              label: 'Classes',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded, color: AppPalette.blue),
              label: 'Cours',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check_rounded, color: AppPalette.blue),
              label: 'Notes',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded, color: AppPalette.blue),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfessorPage extends StatelessWidget {
  const _ProfessorPage({
    required this.title,
    required this.subtitle,
    this.action,
    required this.children,
  });

  final String title;
  final String subtitle;
  final Widget? action;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          ...children,
        ],
      ),
    );
  }
}

// ── Classes ────────────────────────────────────────────────────────────────
class _ClassesTab extends StatefulWidget {
  const _ClassesTab();

  @override
  State<_ClassesTab> createState() => _ClassesTabState();
}

class _ClassesTabState extends State<_ClassesTab> {
  List<dynamic> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    final result = await ProfessorService.getAssignedClasses();
    if (mounted) {
      setState(() {
        _classes = result['success'] == true ? (result['data'] as List<dynamic>) : [];
        _isLoading = false;
      });
      if (result['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Erreur inconnue'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ProfessorPage(
      title: 'Mes Classes',
      subtitle: 'Suivez les effectifs et consultez vos classes assignées.',
      children: [
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_classes.isEmpty)
          const _EmptyState(icon: Icons.school, message: 'Aucune classe assignée.')
        else
          ..._classes.map((c) => _ClassCard(classData: c)),
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.classData});
  final dynamic classData;

  @override
  Widget build(BuildContext context) {
    return _AnimatedCard(
      icon: Icons.school_rounded,
      iconColor: Colors.deepPurple,
      title: classData['nom'] ?? 'Classe sans nom',
      subtitle: classData['niveau'] ?? 'Tous niveaux',
      tag: 'Voir',
      onTap: () {
        // En attendant d'adapter ClassDetailScreen aux données réelles
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Détail de la classe en cours de construction')));
      },
    );
  }
}

// ── Cours ──────────────────────────────────────────────────────────────────
class _CoursesTab extends StatefulWidget {
  const _CoursesTab();

  @override
  State<_CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends State<_CoursesTab> {
  List<dynamic> _cours = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCours();
  }

  Future<void> _fetchCours() async {
    final result = await ProfessorService.getCours();
    if (mounted) {
      setState(() {
        _cours = result['success'] == true ? (result['data'] as List<dynamic>) : [];
        _isLoading = false;
      });
      if (result['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Erreur inconnue'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ProfessorPage(
      title: 'Mes Supports',
      subtitle: 'Publiez et gérez les documents de cours pour vos étudiants.',
      action: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppPalette.blue, Colors.blueAccent]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () async {
            final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadCourseScreen()));
            if (res == true) _fetchCours();
          },
        ),
      ),
      children: [
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_cours.isEmpty)
          const _EmptyState(icon: Icons.menu_book, message: 'Aucun cours publié.')
        else
          ..._cours.map((c) => _AnimatedCard(
                icon: Icons.picture_as_pdf_rounded,
                iconColor: Colors.redAccent,
                title: c['titre'] ?? 'Sans titre',
                subtitle: '${c['module_nom']} - ${c['filiere_nom']}',
                tag: 'Ouvrir',
                onTap: () async {
                  final url = Uri.parse(c['fichier_url']);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              )),
      ],
    );
  }
}

// ── Notes ──────────────────────────────────────────────────────────────────
class _GradesTab extends StatefulWidget {
  const _GradesTab();

  @override
  State<_GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends State<_GradesTab> {
  List<dynamic> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    final result = await ProfessorService.getGradeSessions();
    if (mounted) {
      setState(() {
        _sessions = result['success'] == true ? (result['data'] as List<dynamic>) : [];
        _isLoading = false;
      });
      if (result['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Erreur inconnue'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ProfessorPage(
      title: 'Évaluations',
      subtitle: 'Créez et envoyez les sessions de notes.',
      action: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () async {
            final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const GradeSessionScreen()));
            if (res == true) _fetchSessions();
          },
        ),
      ),
      children: [
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_sessions.isEmpty)
          const _EmptyState(icon: Icons.assignment_turned_in, message: 'Aucune session de notes.')
        else
          ..._sessions.map((s) => _AnimatedCard(
                icon: s['is_sent'] == true ? Icons.verified_rounded : Icons.pending_actions_rounded,
                iconColor: s['is_sent'] == true ? Colors.green : Colors.orange,
                title: '${s['module_nom']} (${s['filiere_nom']})',
                subtitle: 'Créé le ${DateTime.parse(s['date_session']).toLocal().toString().split(' ')[0]}',
                tag: s['is_sent'] == true ? 'Envoyé' : 'Envoyer',
                onTap: s['is_sent'] == true
                    ? () {}
                    : () async {
                        final result = await ProfessorService.markSessionSent(s['id'].toString());
                        if (result['success'] == true) {
                          _fetchSessions();
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['error'] ?? 'Erreur inconnue'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
              )),
      ],
    );
  }
}

// ── Profil ─────────────────────────────────────────────────────────────────
class _ProfessorProfileTab extends StatefulWidget {
  const _ProfessorProfileTab({required this.onLogout});
  final VoidCallback onLogout;

  @override
  State<_ProfessorProfileTab> createState() => _ProfessorProfileTabState();
}

class _ProfessorProfileTabState extends State<_ProfessorProfileTab> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final result = await ProfessorService.getProfile();
    if (mounted) {
      setState(() {
        _profile = result['success'] == true ? (result['data'] as Map<String, dynamic>) : null;
        _isLoading = false;
      });
      if (result['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Erreur inconnue'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profile == null) {
      return Center(
        child: ElevatedButton(
          onPressed: widget.onLogout,
          child: const Text('Erreur de profil - Déconnexion'),
        ),
      );
    }

    return _ProfessorPage(
      title: 'Mon Profil',
      subtitle: 'Espace personnel enseignant',
      action: IconButton(
        icon: const Icon(Icons.edit_rounded, color: AppPalette.blue),
        onPressed: () async {
          final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(currentProfile: _profile!)));
          if (res == true) _fetchProfile();
        },
      ),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [AppPalette.blue, Colors.blueAccent]),
              boxShadow: [
                BoxShadow(color: AppPalette.blue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
              ],
            ),
            child: const CircleAvatar(
              radius: 46,
              backgroundColor: Colors.white,
              child: Icon(Icons.school_rounded, size: 48, color: AppPalette.blue),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Text(
                '${_profile!['nom']?.toUpperCase()} ${_profile!['prenoms']}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppPalette.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _profile!['specialite'] ?? 'Professeur',
                  style: const TextStyle(color: AppPalette.blue, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              _ProfileLine(icon: Icons.alternate_email, label: 'Email', value: _profile!['email'] ?? 'Non renseigné'),
              const Divider(height: 1, indent: 56),
              _ProfileLine(icon: Icons.phone_rounded, label: 'Téléphone', value: _profile!['tel'] ?? 'Non renseigné'),
              const Divider(height: 1, indent: 56),
              _ProfileLine(icon: Icons.domain_rounded, label: 'Département', value: _profile!['departement'] ?? 'Non renseigné'),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            label: const Text('Se déconnecter', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Widgets partagés ───────────────────────────────────────────────────────
class _AnimatedCard extends StatelessWidget {
  const _AnimatedCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(tag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: iconColor)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 64, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppPalette.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppPalette.blue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

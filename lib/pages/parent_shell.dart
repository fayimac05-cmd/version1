import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import '../widgets/profile_header_cover.dart';
import 'splash_screen.dart';
import 'parent/parent_grades_tab.dart';
import 'parent/parent_assistant_ia_screen.dart';
import 'parent/parent_paiements_screen.dart';
import '../../services/parent_service.dart';
import '../../services/api_service.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({
    super.key,
    required this.profile,
    required this.nomEnfant,
    required this.onLogout,
    this.etudiantId,
  });

  final StudentProfile profile;
  final String nomEnfant;
  final VoidCallback onLogout;
  final String? etudiantId;

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _ParentAccueilTab(
        profile: widget.profile,
        nomEnfant: widget.nomEnfant,
        etudiantId: widget.etudiantId,
        onNavigateToTab: (index) => setState(() => _currentTab = index),
      ),
      ParentGradesTab(
        nomEnfant: widget.nomEnfant,
        etudiantId: widget.etudiantId,
      ),
      _ParentPlanningTab(
        nomEnfant: widget.nomEnfant,
        filiere: widget.profile.filiere,
      ),
      _ParentPresencesTab(etudiantId: widget.etudiantId),
      _ParentProfilTab(
        profile: widget.profile,
        nomEnfant: widget.nomEnfant,
        etudiantId: widget.etudiantId,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: const Color(0xFFD97706).withValues(alpha: 0.15),
        selectedIndex: _currentTab,
        onDestinationSelected: (index) => setState(() => _currentTab = index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFFD97706)),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.grading_outlined),
            selectedIcon: Icon(Icons.grading_rounded, color: Color(0xFFD97706)),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded, color: Color(0xFFD97706)),
            label: 'Programme',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt_rounded, color: Color(0xFFD97706)),
            label: 'Présences',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFFD97706)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ─── ONGLET ACCUEIL ───────────────────────────────────────

class _ParentAccueilTab extends StatefulWidget {
  const _ParentAccueilTab({
    required this.profile,
    required this.nomEnfant,
    this.etudiantId,
    required this.onNavigateToTab,
  });

  final StudentProfile profile;
  final String nomEnfant;
  final String? etudiantId;
  final Function(int) onNavigateToTab;

  @override
  State<_ParentAccueilTab> createState() => _ParentAccueilTabState();
}

class _ParentAccueilTabState extends State<_ParentAccueilTab> {
  String _moyenne = '14.5';
  String _presence = '98%';
  bool _loadingStats = true;
  late String _nomEnfantActuel;
  late String _matriculeEnfantActuel;
  late String _filiereEnfantActuelle;

  @override
  void initState() {
    super.initState();
    _nomEnfantActuel = widget.nomEnfant;
    _matriculeEnfantActuel = widget.etudiantId ?? '';
    _filiereEnfantActuelle = widget.profile.filiere;
    _loadLiveStats();
  }

  Future<void> _loadLiveStats() async {
    // 1. Charger les informations directes de l'enfant rattaché via /parents/mon-enfant
    try {
      final enfRes = await ParentService.getMonEnfant();
      if (enfRes['success'] == true && enfRes['data'] != null) {
        final data = enfRes['data'] as Map<String, dynamic>;
        final nomComplet = (data['nomComplet'] ?? '${data['prenoms'] ?? ''} ${data['nom'] ?? ''}').toString().trim();
        if (nomComplet.isNotEmpty && mounted) {
          setState(() {
            _nomEnfantActuel = nomComplet;
            if (data['matricule'] != null && data['matricule'].toString().isNotEmpty) {
              _matriculeEnfantActuel = data['matricule'].toString();
            }
            if (data['filiere'] != null && data['filiere'].toString().isNotEmpty) {
              _filiereEnfantActuelle = data['filiere'].toString();
            }
          });
        }
      }
    } catch (_) {}

    // 2. Si le nom de l'enfant n'a pas été trouvé, tenter la résolution par lookupMatricule
    if (_nomEnfantActuel.isEmpty || _nomEnfantActuel == 'Étudiant suivi') {
      String candidateMat = _matriculeEnfantActuel;
      if (candidateMat.isEmpty) {
        candidateMat = (widget.profile.matriculeEnfant ?? widget.profile.matricule).trim();
      }

      if (candidateMat.isNotEmpty && !candidateMat.startsWith('PAR-') && !candidateMat.startsWith('PARENT-')) {
        try {
          final etuRes = await ApiService.lookupMatricule(candidateMat);
          if (etuRes['success'] == true && etuRes['user'] != null) {
            final eu = etuRes['user'] as Map;
            final nom = '${eu['prenoms'] ?? ''} ${eu['nom'] ?? ''}'.trim();
            if (nom.isNotEmpty && mounted) {
              setState(() {
                _nomEnfantActuel = nom;
                _matriculeEnfantActuel = candidateMat;
                if (eu['filiere_nom'] != null && eu['filiere_nom'].toString().isNotEmpty) {
                  _filiereEnfantActuelle = eu['filiere_nom'].toString();
                } else if (eu['filiere'] != null && eu['filiere'].toString().isNotEmpty) {
                  _filiereEnfantActuelle = eu['filiere'].toString();
                }
              });
            }
          }
        } catch (_) {}
      }
    }

    final targetEtuId = _matriculeEnfantActuel.isNotEmpty ? _matriculeEnfantActuel : widget.etudiantId;
    if (targetEtuId != null && targetEtuId.isNotEmpty && !targetEtuId.startsWith('PAR-')) {
      try {
        final presRes = await ParentService.getEnfantPresences(targetEtuId);
        if (presRes['success'] == true && presRes['stats'] != null) {
          final stats = presRes['stats'] as Map<String, dynamic>;
          final total = stats['total'] ?? 0;
          final presentes = stats['presentes'] ?? 0;
          if (total > 0 && mounted) {
            setState(() {
              _presence = '${(presentes / total * 100).toStringAsFixed(0)}%';
            });
          }
        }
      } catch (_) {}

      try {
        final notesRes = await ParentService.getEnfantNotes(targetEtuId);
        if (notesRes['success'] == true && notesRes['data'] != null) {
          final List notes = notesRes['data'] as List;
          if (notes.isNotEmpty) {
            double sum = 0;
            int count = 0;
            for (var n in notes) {
              final val = double.tryParse(n['valeur']?.toString() ?? '');
              if (val != null) {
                sum += val;
                count++;
              }
            }
            if (count > 0 && mounted) {
              setState(() {
                _moyenne = (sum / count).toStringAsFixed(1);
              });
            }
          }
        }
      } catch (_) {}
    }

    if (mounted) setState(() => _loadingStats = false);
  }

  @override
  Widget build(BuildContext context) {
    final parentNom = '${widget.profile.prenoms} ${widget.profile.nom}'.trim();
    final filiereAffichee = _filiereEnfantActuelle.isNotEmpty
        ? _filiereEnfantActuelle
        : (widget.profile.filiere.isNotEmpty ? widget.profile.filiere : 'Institut Supérieur de Technologies');
    final enfantNomAffiche = _nomEnfantActuel.isNotEmpty && _nomEnfantActuel != 'Étudiant suivi'
        ? _nomEnfantActuel
        : 'Enfant rattaché';

    return RefreshIndicator(
      onRefresh: _loadLiveStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête avec nom réel du parent ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parentNom.isNotEmpty ? 'Bonjour, $parentNom 👋' : 'Bonjour 👋',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Espace Parent',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => widget.onNavigateToTab(4),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD97706), Color(0xFFB45309)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD97706).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${widget.profile.prenoms.isNotEmpty ? widget.profile.prenoms[0] : "P"}${widget.profile.nom.isNotEmpty ? widget.profile.nom[0] : "L"}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Carte Enfant Suivi ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'Enfant suivi',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '● Inscrit',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    enfantNomAffiche,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _matriculeEnfantActuel.isNotEmpty
                        ? 'Matricule : $_matriculeEnfantActuel'
                        : filiereAffichee,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  if (_matriculeEnfantActuel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      filiereAffichee,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Résumé Académique ──
            const Text(
              'Résumé Académique',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatCard(
                  icon: Icons.grading_rounded,
                  label: 'Moyenne générale',
                  value: '$_moyenne / 20',
                  color: const Color(0xFF2563EB),
                  onTap: () => widget.onNavigateToTab(1),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Assiduité',
                  value: '$_presence Présence',
                  color: const Color(0xFF16A34A),
                  onTap: () => widget.onNavigateToTab(3),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Services & Outils ──
            const Text(
              'Services & Outils',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ServiceCard(
                  icon: Icons.smart_toy_rounded,
                  label: 'Assistant IA',
                  description: 'Conseils & analyse personnalisée',
                  color: const Color(0xFF7C3AED),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentAssistantIAScreen(nomEnfant: widget.nomEnfant),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _ServiceCard(
                  icon: Icons.credit_card_rounded,
                  label: 'Paiements',
                  description: 'Scolarité, cantine et transport',
                  color: const Color(0xFF0891B2),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentPaiementsScreen(nomEnfant: widget.nomEnfant),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ServiceCard(
                  icon: Icons.calendar_month_rounded,
                  label: 'Planning',
                  description: 'Emploi du temps des cours',
                  color: const Color(0xFFEA580C),
                  onTap: () => widget.onNavigateToTab(2),
                ),
                const SizedBox(width: 12),
                _ServiceCard(
                  icon: Icons.assignment_turned_in_rounded,
                  label: 'Bulletins',
                  description: 'Notes et relevés semestriels',
                  color: const Color(0xFF059669),
                  onTap: () => widget.onNavigateToTab(1),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Alertes & Notifications ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Alertes et Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '2 nouvelles',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _AlerteItem(
              icon: Icons.info_outline_rounded,
              couleur: const Color(0xFF2563EB),
              titre: 'Espace parent activé',
              description: 'Votre compte est prêt. Vous suivez désormais le parcours de ${widget.nomEnfant}.',
              date: 'Aujourd\'hui',
            ),
            const SizedBox(height: 10),
            const _AlerteItem(
              icon: Icons.event_note_rounded,
              couleur: Color(0xFFD97706),
              titre: 'Réunion des parents',
              description: 'Rencontre générale ce samedi à 09h00 au campus principal.',
              date: 'Cette semaine',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── WIDGETS DE L'ACCUEIL ───────────────────────────────────

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlerteItem extends StatelessWidget {
  const _AlerteItem({
    required this.icon,
    required this.couleur,
    required this.titre,
    required this.description,
    required this.date,
  });

  final IconData icon;
  final Color couleur;
  final String titre;
  final String description;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: couleur, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      titre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.4,
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
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ONGLET PLANNING ──────────────────────────────────────

class _ParentPlanningTab extends StatelessWidget {
  const _ParentPlanningTab({
    required this.nomEnfant,
    required this.filiere,
  });

  final String nomEnfant;
  final String filiere;

  @override
  Widget build(BuildContext context) {
    final scheduleDays = [
      {'jour': 'Lundi', 'cours': 'Algorithmique & Programmation', 'horaire': '08h00 - 12h00', 'salle': 'Amphi 2', 'prof': 'M. Ouédraogo'},
      {'jour': 'Mardi', 'cours': 'Bases de Données & SQL', 'horaire': '14h00 - 17h00', 'salle': 'Labo Info 1', 'prof': 'Mme Traoré'},
      {'jour': 'Mercredi', 'cours': 'Réseaux Informatiques & Télécoms', 'horaire': '08h00 - 12h00', 'salle': 'Salle B3', 'prof': 'M. Kaboré'},
      {'jour': 'Jeudi', 'cours': 'Anglais Technique & Communication', 'horaire': '08h00 - 11h00', 'salle': 'Salle C1', 'prof': 'M. Sawadogo'},
      {'jour': 'Vendredi', 'cours': 'Systèmes d\'Exploitation Linux', 'horaire': '14h00 - 17h00', 'salle': 'Labo Info 2', 'prof': 'M. Zongo'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Emploi du temps',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF0F172A),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_rounded, color: Color(0xFF1D4ED8), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Planning de : $nomEnfant',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        filiere.isNotEmpty ? filiere : 'Semestre en cours',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...scheduleDays.map((day) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        day['jour']!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day['cours']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              day['horaire']!,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.place_outlined, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              day['salle']!,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── ONGLET PROFIL ────────────────────────────────────────

class _ParentProfilTab extends StatelessWidget {
  const _ParentProfilTab({
    required this.profile,
    required this.nomEnfant,
    this.etudiantId,
    required this.onLogout,
  });

  final StudentProfile profile;
  final String nomEnfant;
  final String? etudiantId;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final parentNom = '${profile.prenoms} ${profile.nom}'.trim();
    final initiales = '${profile.prenoms.isNotEmpty ? profile.prenoms[0] : "P"}${profile.nom.isNotEmpty ? profile.nom[0] : "L"}';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Mon Profil Parent',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 20),

        ProfileHeaderCover(
          matricule: profile.matricule.isNotEmpty ? profile.matricule : 'PARENT',
          nomComplet: parentNom.isNotEmpty ? parentNom : 'Parent d\'élève',
          roleLabel: "Parent d'élève",
          initiales: initiales,
          badgeText: 'Responsable Légal',
          badgeColor: const Color(0xFFD97706),
          accentColor: const Color(0xFFD97706),
          bannerGradient: const [Color(0xFF78350F), Color(0xFFB45309), Color(0xFFD97706)],
        ),
        const SizedBox(height: 24),

        const Text(
          'Informations du Compte',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _infoLigne(
                Icons.person_outline_rounded,
                'Nom & Prénom',
                parentNom.isNotEmpty ? parentNom : 'Non renseigné',
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _infoLigne(
                Icons.phone_outlined,
                'Téléphone',
                profile.telephone.isNotEmpty ? profile.telephone : 'Non renseigné',
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _infoLigne(
                Icons.email_outlined,
                'Email',
                profile.email.isNotEmpty ? profile.email : 'Non renseigné',
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _infoLigne(
                Icons.child_care_rounded,
                'Enfant à charge',
                '$nomEnfant ${etudiantId != null && etudiantId!.isNotEmpty ? "($etudiantId)" : ""}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Déconnexion', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  content: const Text(
                    'Voulez-vous vous déconnecter de votre espace parent ?',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const SplashScreen()),
                          (_) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Déconnecter'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            label: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF64748B), size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lbl,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                val,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── ONGLET PRÉSENCES ─────────────────────────────────────

class _ParentPresencesTab extends StatefulWidget {
  const _ParentPresencesTab({this.etudiantId});
  final String? etudiantId;

  @override
  State<_ParentPresencesTab> createState() => _ParentPresencesTabState();
}

class _ParentPresencesTabState extends State<_ParentPresencesTab> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<Map<String, dynamic>> _fetch() async {
    if (widget.etudiantId == null || widget.etudiantId!.isEmpty) {
      return {'success': false, 'error': 'Identifiant étudiant non disponible.'};
    }
    return ParentService.getEnfantPresences(widget.etudiantId!);
  }

  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'present': return const Color(0xFF15803D);
      case 'absent': return const Color(0xFFC62828);
      case 'retard': return const Color(0xFFD97706);
      default: return Colors.grey;
    }
  }

  String _libelleStatut(String statut) {
    switch (statut) {
      case 'present': return 'Présent';
      case 'absent': return 'Absent';
      case 'retard': return 'Retard';
      default: return statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Suivi des Présences',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!['success'] != true) {
            final error = snapshot.data?['error'] ?? 'Impossible de charger les présences.';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_alt_outlined, size: 56, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 12),
                    Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() => _future = _fetch()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Actualiser'),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<dynamic> presences = snapshot.data!['data'] ?? [];
          final stats = snapshot.data!['stats'] as Map<String, dynamic>? ?? {};
          final total = stats['total'] ?? 0;
          final presentes = stats['presentes'] ?? 0;
          final absentes = stats['absentes'] ?? 0;
          final retards = stats['retards'] ?? 0;
          final tauxPresence = total > 0 ? (presentes / total * 100).toStringAsFixed(1) : '100';

          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _fetch()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Carte statistiques
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF0EA5E9)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Taux de présence globale', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        '$tauxPresence%',
                        style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statBadge('Présences', presentes.toString(), Colors.white),
                          _statBadge('Absences', absentes.toString(), Colors.red.shade200),
                          _statBadge('Retards', retards.toString(), Colors.orange.shade200),
                          _statBadge('Total séances', total.toString(), Colors.white70),
                        ],
                      ),
                    ],
                  ),
                ),

                if (presences.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 56, color: Colors.green),
                          SizedBox(height: 12),
                          Text('Aucune absence enregistrée.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('L\'étudiant est à jour de ses présences.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                else
                  ...presences.map((p) {
                    final statut = p['presence_statut']?.toString() ?? 'inconnu';
                    final module = p['module_nom'] ?? 'Module';
                    final prof = '${p['prof_prenoms'] ?? ''} ${p['prof_nom'] ?? ''}'.trim();
                    final dateStr = p['date_appel'] != null
                        ? DateTime.tryParse(p['date_appel'].toString())
                            ?.toLocal()
                            .toString()
                            .substring(0, 10)
                        : null;

                    final color = _couleurStatut(statut);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(module, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                                if (prof.isNotEmpty)
                                  Text('Prof. $prof', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                if (dateStr != null)
                                  Text(dateStr, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _libelleStatut(statut),
                              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statBadge(String label, String value, Color textColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 11)),
      ],
    );
  }
}

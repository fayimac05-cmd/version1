import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import '../widgets/profile_header_cover.dart';
import 'splash_screen.dart';
import 'parent/parent_grades_tab.dart';
import 'parent/parent_assistant_ia_screen.dart';
import 'parent/parent_paiements_screen.dart';
import '../../services/parent_service.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({
    super.key,
    required this.nomEnfant,
    required this.onLogout,
    this.etudiantId,
  });

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
      _ParentAccueilTab(nomEnfant: widget.nomEnfant),
      ParentGradesTab(nomEnfant: widget.nomEnfant, etudiantId: widget.etudiantId),
      _ParentPlanningTab(),
      _ParentPresencesTab(etudiantId: widget.etudiantId),
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
        indicatorColor: AppPalette.yellow.withValues(alpha:0.45),
        selectedIndex: _currentTab,
        onDestinationSelected: (index) => setState(() => _currentTab = index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
            label: 'Programme',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt_rounded),
            label: 'Présences',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour 👋',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Espace Parent',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppPalette.blue),
                  ),
                ],
              ),
              const CircleAvatar(
                backgroundColor: AppPalette.softYellow,
                child: Icon(Icons.family_restroom, color: AppPalette.blue),
              )
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPalette.yellow.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppPalette.yellow.withValues(alpha:0.35)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.school_rounded,
                  size: 40,
                  color: AppPalette.blue,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enfant suivi',
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        nomEnfant,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.blue,
                        ),
                      ),
                      const Text(
                        'IST Campus Ouaga 2000 (Licence Informatique)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Résumé Académique',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                icon: Icons.grading_rounded,
                label: 'Moyenne générale',
                value: '14.5 / 20',
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.check_circle_outline_rounded,
                label: 'Assiduité',
                value: '98% Présence',
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Services',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ServiceCard(
                icon: Icons.smart_toy_rounded,
                label: 'Assistant IA',
                description: 'Analyse des notes et alertes en temps réel',
                color: const Color(0xFF7C3AED),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ParentAssistantIAScreen(nomEnfant: nomEnfant),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _ServiceCard(
                icon: Icons.credit_card_rounded,
                label: 'Paiements',
                description: 'Scolarité, cantine et bus scolaire',
                color: const Color(0xFF0891B2),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ParentPaiementsScreen(nomEnfant: nomEnfant),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Alertes et Notifications (2)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          _AlerteItem(
            icon: Icons.warning_amber_rounded,
            couleur: Colors.orange,
            titre: 'Note à surveiller',
            description: 'Une note de 9.5/20 a été enregistrée en Programmation pour $nomEnfant.',
            date: 'Aujourd\'hui',
          ),
          const SizedBox(height: 10),
          _AlerteItem(
            icon: Icons.info_outline_rounded,
            couleur: AppPalette.blue,
            titre: 'Réunion des parents',
            description: 'Rencontre annuelle ce samedi à 09h00 au grand amphithéâtre.',
            date: 'Hier',
          ),
        ],
      ),
    );
  }
}

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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.3),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withValues(alpha:0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: couleur, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(titre, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: couleur)),
                    Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.3)),
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
  });
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
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha:0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ONGLET NOTES ─────────────────────────────────────────



// ─── ONGLET PLANNING ──────────────────────────────────────
class _ParentPlanningTab extends StatelessWidget {
  const _ParentPlanningTab();

  @override
  Widget build(BuildContext context) {
    final scheduleDays = [
      {'jour': 'Lundi', 'cours': 'Algorithmique & Structures', 'horaire': '08h00 - 12h00', 'salle': 'Salle A4'},
      {'jour': 'Mardi', 'cours': 'Bases de données SQL', 'horaire': '14h00 - 17h00', 'salle': 'Labo Informatique 2'},
      {'jour': 'Mercredi', 'cours': 'Réseaux Informatiques', 'horaire': '08h00 - 12h00', 'salle': 'Salle A4'},
      {'jour': 'Jeudi', 'cours': 'Anglais Technique', 'horaire': '08h00 - 11h00', 'salle': 'Salle C1'},
      {'jour': 'Vendredi', 'cours': 'Mathématiques Discrètes', 'horaire': '14h00 - 17h00', 'salle': 'Salle A3'},
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emploi du temps de l\'enfant',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppPalette.blue),
          ),
          const SizedBox(height: 8),
          const Text(
            'Horaire hebdomadaire de cours et d\'activités',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFC62828), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '⚠️ EDT de l\'enfant (À compléter / En attente de validation administrative)',
                    style: TextStyle(fontSize: 12, color: Color(0xFFC62828), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: scheduleDays.length,
              itemBuilder: (_, i) {
                final day = scheduleDays[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 90,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppPalette.blue.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            day['jour']!,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppPalette.blue, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              day['cours']!,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  day['horaire']!,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.place_outlined, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  day['salle']!,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
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
          const Text(
            'Mon Profil Parent',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppPalette.blue),
          ),
          const SizedBox(height: 20),
          ProfileHeaderCover(
            matricule: 'PARENT-OD001',
            nomComplet: 'M. Ousmane Diallo',
            roleLabel: "Parent / Tuteur Légal",
            initiales: 'OD',
            badgeText: 'Tuteur Légal',
            badgeColor: AppPalette.blue,
            accentColor: AppPalette.blue,
            bannerGradient: const [Color(0xFF0D3B5E), Color(0xFF1B5E8A), Color(0xFF2E86C1)],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          const Text(
            'Informations de Contact',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          _infoLigne(Icons.email_outlined, 'Email', 'parent.diallo@gmail.com'),
          const SizedBox(height: 12),
          _infoLigne(Icons.phone_outlined, 'Téléphone', '+226 70 00 00 00'),
          const SizedBox(height: 12),
          _infoLigne(Icons.child_care_rounded, 'Enfant à charge', 'Fatimata Diallo'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Row(children: [
                      Icon(Icons.logout_rounded, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Déconnexion', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ]),
                    content: const Text('Voulez-vous vous déconnecter ?',
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const SplashScreen()), (_) => false);
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
      ),
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
            Text(lbl, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          ],
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
          'Présences',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E293B)),
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
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(error, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() => _future = _fetch()),
                      child: const Text('Réessayer'),
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
          final tauxPresence = total > 0 ? (presentes / total * 100).toStringAsFixed(1) : '-';

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
                      const Text('Taux de présence', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        '$tauxPresence%',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statBadge('Présent', presentes.toString(), Colors.white),
                          _statBadge('Absent', absentes.toString(), Colors.red.shade200),
                          _statBadge('Retard', retards.toString(), Colors.orange.shade200),
                          _statBadge('Total', total.toString(), Colors.white70),
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
                          Icon(Icons.people_alt_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Aucune présence enregistrée.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                else
                  ...presences.map((p) {
                    final statut = p['presence_statut']?.toString() ?? 'inconnu';
                    final module = p['module_nom'] ?? 'Module inconnu';
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
                            width: 10,
                            height: 50,
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
        Text(value, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 22)),
        Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 11)),
      ],
    );
  }
}

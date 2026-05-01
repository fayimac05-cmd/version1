import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../pages/admin_data.dart';
import '../pages/splash_screen.dart';
import '../theme/app_palette.dart';

class AdminDashboard extends StatelessWidget {
  final StudentProfile profile;
  const AdminDashboard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final stats = getAdminStats();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── AppBar ────────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: AppPalette.blue,
              expandedHeight: 140,
              floating: false,
              pinned: true,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () => _confirmLogout(context),
                  tooltip: 'Déconnexion',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppPalette.blue, Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(children: [
                        Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${profile.prenoms[0]}${profile.nom[0]}',
                              style: const TextStyle(fontSize: 18,
                                  fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour, ${profile.prenoms} 👋',
                              style: const TextStyle(fontSize: 18,
                                  fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              profile.filiere,
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        )),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppPalette.yellow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('ADMIN', style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold,
                              color: AppPalette.black)),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Alertes urgentes ─────────────────────────────────────
                  if ((stats['reclamationsEnAttente'] as int) > 0) ...[
                    _alerteBandeau(
                      '${stats['reclamationsEnAttente']} réclamation(s) en attente de traitement',
                      Icons.warning_amber_rounded,
                      const Color(0xFFFEF3C7),
                      const Color(0xFFD97706),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if ((stats['suspendus'] as int) > 0) ...[
                    _alerteBandeau(
                      '${stats['suspendus']} étudiant(s) suspendu(s)',
                      Icons.person_off_outlined,
                      const Color(0xFFFEE2E2),
                      const Color(0xFFDC2626),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Titre section ────────────────────────────────────────
                  const Text('Vue d\'ensemble',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 14),

                  // ── Grille stats ─────────────────────────────────────────
                  Row(children: [
                    Expanded(child: _statCard('Étudiants', '${stats['totalEtudiants']}',
                        Icons.people_rounded, AppPalette.blue, const Color(0xFFEFF6FF))),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('Filières', '${stats['totalFilieres']}',
                        Icons.school_rounded, const Color(0xFF7C3AED), const Color(0xFFF5F3FF))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _statCard('Professeurs', '${stats['totalProfs']}',
                        Icons.person_pin_rounded, const Color(0xFF0891B2), const Color(0xFFECFEFF))),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('Réclamations', '${stats['reclamationsEnAttente']}',
                        Icons.report_problem_rounded,
                        (stats['reclamationsEnAttente'] as int) > 0
                            ? const Color(0xFFD97706) : const Color(0xFF15803D),
                        (stats['reclamationsEnAttente'] as int) > 0
                            ? const Color(0xFFFEF3C7) : const Color(0xFFF0FDF4))),
                    ]),

                  const SizedBox(height: 24),

                  // ── Répartition étudiants ────────────────────────────────
                  const Text('Statut des étudiants',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                          blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(children: [
                      _statutLigne('Actifs', stats['actifs'], stats['totalEtudiants'],
                          const Color(0xFF15803D), const Color(0xFFF0FDF4)),
                      const SizedBox(height: 10),
                      _statutLigne('Suspendus', stats['suspendus'], stats['totalEtudiants'],
                          const Color(0xFFD97706), const Color(0xFFFEF3C7)),
                      const SizedBox(height: 10),
                      _statutLigne('Renvoyés', stats['renvoyes'], stats['totalEtudiants'],
                          const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
                    ]),
                  ),

                  const SizedBox(height: 24),

                  // ── Filières actives ──────────────────────────────────────
                  const Text('Filières actives',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 14),

                  ...adminFilieres.map((f) {
                    final nb = adminEtudiants.where((e) => e.filiereId == f.id).length;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: f.domaine.contains('Technologies')
                                ? const Color(0xFFEFF6FF) : const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            f.domaine.contains('Technologies')
                                ? Icons.computer_rounded : Icons.business_center_rounded,
                            color: f.domaine.contains('Technologies')
                                ? AppPalette.blue : const Color(0xFF7C3AED),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.nom, style: const TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                            Text('${f.niveau} · ${f.modules.length} modules',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        )),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('$nb étudiants',
                              style: const TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.bold, color: AppPalette.blue)),
                        ),
                      ]),
                    );
                  }),

                  const SizedBox(height: 24),

                  // ── Info IST ──────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppPalette.blue.withOpacity(0.08), AppPalette.yellow.withOpacity(0.08)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppPalette.blue.withOpacity(0.15)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline, color: AppPalette.blue, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('IST Campus Ouaga 2000',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                                  color: AppPalette.blue)),
                          SizedBox(height: 2),
                          Text('Année académique 2024-2025',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      )),
                    ]),
                  ),

                  const SizedBox(height: 30),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alerteBandeau(String msg, IconData icon, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: fg, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg))),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: fg, size: 22),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: fg)),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ]),
      ]),
    );
  }

  Widget _statutLigne(String label, int val, int total, Color fg, Color bg) {
    final pct = total == 0 ? 0.0 : val / total;
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.bold, color: fg)),
      ),
      const SizedBox(width: 12),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pct,
          backgroundColor: const Color(0xFFF1F5F9),
          color: fg,
          minHeight: 8,
        ),
      )),
      const SizedBox(width: 10),
      Text('$val', style: TextStyle(fontSize: 14,
          fontWeight: FontWeight.bold, color: fg)),
    ]);
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.logout, color: Color(0xFFDC2626)),
          SizedBox(width: 10),
          Text('Déconnexion', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
        content: const Text('Voulez-vous vous déconnecter ?',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}

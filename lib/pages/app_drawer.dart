import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import 'chat_ia_screen.dart';
import 'revision_ia_screen.dart';
import 'tickets_screen.dart';
import 'evaluations_a_faire_page.dart';
import '../widgets/guide_utilisation.dart';
import '../widgets/session_settings_sheet.dart';

/// Menu latéral accessible via l'icône ☰ du header de HomeTab.
/// Regroupe les fonctionnalités retirées de l'écran d'accueil
/// (Chat IA, Révisions IA, Tickets) tout en restant
/// accessibles en un tap.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.profile, this.onProfil});
  final StudentProfile profile;

  /// Appelé quand on touche l'en-tête (nom) : ouvre l'onglet Profil.
  final VoidCallback? onProfil;

  @override
  Widget build(BuildContext context) {
    final initiales =
        '${profile.prenoms.isNotEmpty ? profile.prenoms[0] : ''}'
        '${profile.nom.isNotEmpty ? profile.nom[0] : ''}'
            .toUpperCase();

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── En-tête profil ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0A3D91), Color(0xFF1565C0)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onProfil == null
                        ? null
                        : () {
                            Navigator.pop(context); // ferme le drawer
                            onProfil!();
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppPalette.yellow, width: 2),
                    image: profile.photoUrl != null &&
                            profile.photoUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(profile.photoUrl!),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: (profile.photoUrl == null || profile.photoUrl!.isEmpty)
                      ? Center(
                          child: Text(initiales,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0A3D91))))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${profile.prenoms} ${profile.nom}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      Text(
                        profile.niveau.isNotEmpty
                            ? '${profile.niveau} · ${profile.filiere}'
                            : profile.filiere,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),
              ]),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            _item(
              context,
              icon: Icons.smart_toy_outlined,
              label: 'Chat IA',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ChatIAScreen(profile: profile))),
            ),
            _item(
              context,
              icon: Icons.auto_awesome_rounded,
              label: 'Révisions IA',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RevisionIAScreen())),
            ),
            _item(
              context,
              icon: Icons.confirmation_number_outlined,
              label: 'Tickets',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TicketsScreen(profile: profile))),
            ),
            _item(
              context,
              icon: Icons.rate_review_outlined,
              label: 'Évaluer mes profs',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EvaluationsAFairePage())),
            ),
            _item(
              context,
              icon: Icons.help_outline_rounded,
              label: "Guide d'utilisation",
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const GuideUtilisationPage(role: GuideRole.etudiant))),
            ),
            _item(
              context,
              icon: Icons.lock_clock_rounded,
              label: 'Session et sécurité',
              onTap: () => showSessionSettings(context, role: profile.role),
            ),

            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Divider(color: Color(0xFFE2E8F0)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
            color: AppPalette.lightBlue, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppPalette.blue, size: 19),
      ),
      title: Text(label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2A3A))),
      onTap: () {
        Navigator.pop(context); // ferme le drawer
        onTap();
      },
    );
  }
}
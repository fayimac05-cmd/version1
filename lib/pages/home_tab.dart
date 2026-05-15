import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import '../widgets/banner_widget.dart';
import '../widgets/fil_actualite_widget.dart';
import '../pages/canal_screen.dart';
import '../widgets/weekly_program_quick_widget.dart';
import 'groupe_filiere_screen.dart';
import 'tickets_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.profile});
  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Bonjour ──────────────────────────────────────────────────
        Text('Bienvenue ${profile.prenoms}',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                color: Color(0xFF121212), letterSpacing: -0.4)),
        const SizedBox(height: 4),
        const Text('Institut Supérieur de Technologies — Espace étudiant',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),

        const SizedBox(height: 24),

        // ── Bandeau événements ────────────────────────────────────────
        const Text('Événements cette semaine',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: Color(0xFF121212), letterSpacing: -0.2)),
        const SizedBox(height: 12),
        const BannerWidget(),

        const SizedBox(height: 20),
        const WeeklyProgramQuickWidget(),

        const SizedBox(height: 28),

        // ── Accès rapide ──────────────────────────────────────────────
        const Text('Accès rapide',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: Color(0xFF121212), letterSpacing: -0.2)),
        const SizedBox(height: 12),

        // Ligne 1 — Groupe filière + Tickets
        Row(children: [
          // Groupe Filière privé
          Expanded(child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => GroupeFiliere(profile: profile))),
            child: _carteAcces(
              icon: Icons.groups_rounded,
              couleur: AppPalette.blue,
              titre: 'Groupe\nFilière',
              sousTitre: '🔒 100% Privé',
            ))),
          const SizedBox(width: 14),
          // Tickets
          Expanded(child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => TicketsScreen(profile: profile))),
            child: _carteAcces(
              icon: Icons.confirmation_number_outlined,
              couleur: const Color(0xFFFF6B00),
              titre: 'Tickets\nÉvénements',
              sousTitre: '🟠 Orange Money',
            ))),
        ]),

        const SizedBox(height: 14),

        // Ligne 2 — Canaux (pleine largeur)
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CanalScreen(profile: profile))),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                  blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(
                    color: AppPalette.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.forum_rounded,
                    color: AppPalette.blue, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Canaux & Messages',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Row(children: [
                  _miniTag('🏛️ Admin', AppPalette.blue),
                  const SizedBox(width: 6),
                  _miniTag('🎉 BDE', const Color(0xFF7C3AED)),
                  const SizedBox(width: 6),
                  _miniTag('🔒 Privé', const Color(0xFF059669)),
                ]),
              ])),
              // Badge non lus
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppPalette.blue,
                    borderRadius: BorderRadius.circular(12)),
                child: const Text('5', style: TextStyle(fontSize: 11,
                    color: Colors.white, fontWeight: FontWeight.bold))),
            ]),
          )),

        const SizedBox(height: 28),

        // ── Fil d'actualité ───────────────────────────────────────────
        const Text('Fil d\'actualité',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: Color(0xFF121212), letterSpacing: -0.2)),
        const SizedBox(height: 12),
        FilActualiteWidget(profile: profile),

        const SizedBox(height: 28),

        // ── Résumé rapide ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppPalette.blue, Color(0xFF0E6CD3)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Résumé rapide',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppPalette.white, fontSize: 17)),
            const SizedBox(height: 10),
            const Text(
              'Consultez vos programmes, vos notes et vos ressources depuis un seul espace.',
              style: TextStyle(color: AppPalette.white, fontSize: 14, height: 1.5),
            ),
          ]),
        ),
        const SizedBox(height: 28),
      ]),
    );
  }

  Widget _carteAcces({
    required IconData icon, required Color couleur,
    required String titre, required String sousTitre,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 44, height: 44,
        decoration: BoxDecoration(color: couleur.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: couleur, size: 24)),
      const SizedBox(height: 12),
      Text(titre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A), height: 1.2)),
      const SizedBox(height: 6),
      Text(sousTitre, style: const TextStyle(fontSize: 11,
          color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
    ]));

  Widget _miniTag(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(fontSize: 10,
        fontWeight: FontWeight.w600, color: color)));
}

import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import '../widgets/banner_widget.dart';
import '../widgets/fil_actualite_widget.dart';
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

        const SizedBox(height: 28),

        // ── Accès rapide ──────────────────────────────────────────────
        const Text('Accès rapide',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: Color(0xFF121212), letterSpacing: -0.2)),
        const SizedBox(height: 12),

        Row(children: [

          // Groupe Filière — blanc avec bordure bleue
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => GroupeFiliere(profile: profile))),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Container(width: 44, height: 44,
                    decoration: BoxDecoration(
                        color: AppPalette.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.groups_rounded,
                        color: AppPalette.blue, size: 24)),
                  const SizedBox(height: 12),
                  const Text('Groupe\nFilière',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A), height: 1.2)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.lock_outline,
                        color: Color(0xFF64748B), size: 11),
                    const SizedBox(width: 4),
                    const Text('100% Privé', style: TextStyle(
                        fontSize: 11, color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500)),
                  ]),
                ]),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Tickets — blanc avec bordure simple
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => TicketsScreen(profile: profile))),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Container(width: 44, height: 44,
                    decoration: BoxDecoration(
                        color: const Color(0xFFFF6B00).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.confirmation_number_outlined,
                        color: Color(0xFFFF6B00), size: 24)),
                  const SizedBox(height: 12),
                  const Text('Tickets\nÉvénements',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A), height: 1.2)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Text('🟠', style: TextStyle(fontSize: 10)),
                    const SizedBox(width: 4),
                    const Text('Orange Money', style: TextStyle(
                        fontSize: 11, color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500)),
                  ]),
                ]),
              ),
            ),
          ),
        ]),

        const SizedBox(height: 28),

        // ── Fil d'actualité ───────────────────────────────────────────
        const Text('Fil d\'actualité',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: Color(0xFF121212), letterSpacing: -0.2)),
        const SizedBox(height: 12),
        const FilActualiteWidget(),

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
}

import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import '../widgets/emploi_du_temps_widget.dart';

class PlanningTab extends StatelessWidget {
  const PlanningTab({super.key});

  static const List<Map<String, dynamic>> _events = [
    {
      'titre': 'Rentrée académique 2024-2025',
      'date': '15 septembre 2024',
      'description': 'Début de l\'année académique 2024-2025.',
      'type': 'Académique',
    },
    {
      'titre': 'Début des examens S3',
      'date': '4 nov. 2024 → 15 nov. 2024',
      'description': 'Examens de fin du semestre 3.',
      'type': 'Examens',
    },
    {
      'titre': 'Délibérations S3',
      'date': '25 novembre 2024',
      'description': 'Publication des résultats du semestre 3.',
      'type': 'Résultats',
    },
    {
      'titre': 'Vacances académiques',
      'date': '23 déc. 2024 → 5 jan. 2025',
      'description': 'Vacances académiques de fin d\'année.',
      'type': 'Vacances',
    },
    {
      'titre': 'Reprise des cours S4',
      'date': '6 janvier 2025',
      'description': 'Début du semestre 4.',
      'type': 'Académique',
    },
    {
      'titre': 'Inscriptions pédagogiques S4',
      'date': 'Avant le 05 Mai 2026',
      'description': 'Tous les étudiants doivent se régulariser avant cette date.',
      'type': 'Urgent',
    },
  ];

  Color _typeCouleur(String type) {
    switch (type) {
      case 'Examens':   return const Color(0xFFC62828);
      case 'Résultats': return const Color(0xFF15803D);
      case 'Vacances':  return const Color(0xFF0891B2);
      case 'Urgent':    return const Color(0xFFD97706);
      default:          return AppPalette.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [

      // ── Header ────────────────────────────────────────────────────
      Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [AppPalette.blue, Color(0xFF1565C0)],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Row(children: [
          Container(width: 46, height: 46,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.calendar_month_outlined,
                color: Colors.white, size: 24)),
          const SizedBox(width: 14),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Planning', style: TextStyle(fontSize: 22,
                  fontWeight: FontWeight.bold, color: Colors.white,
                  letterSpacing: -0.3)),
              SizedBox(height: 2),
              Text('Année académique 2024-2025',
                  style: TextStyle(fontSize: 13, color: Colors.white70)),
            ],
          )),
        ]),
      ),

      // ── Contenu scrollable ────────────────────────────────────────
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Zone 1 : Emploi du temps PDF ──────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Emploi du temps',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A), letterSpacing: -0.2)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppPalette.lightBlue,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppPalette.blue.withOpacity(0.2)),
                  ),
                  child: const Text('27 Avr — 02 Mai',
                      style: TextStyle(fontSize: 12, color: AppPalette.blue,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const EmploiDuTempsWidget(),

            const SizedBox(height: 28),

            // ── Zone 2 : Calendrier académique ────────────────────
            const Row(children: [
              Icon(Icons.event_outlined, color: AppPalette.blue, size: 20),
              SizedBox(width: 10),
              Text('Calendrier académique',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A), letterSpacing: -0.2)),
            ]),
            const SizedBox(height: 12),

            ...List.generate(_events.length, (index) {
              final e     = _events[index];
              final color = _typeCouleur(e['type']);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(children: [
                  Container(
                    width: 5, height: 90,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(16)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(e['titre'],
                              style: const TextStyle(fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A)))),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(e['type'],
                                style: TextStyle(fontSize: 11,
                                    fontWeight: FontWeight.bold, color: color)),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.calendar_today, size: 13, color: color),
                          const SizedBox(width: 6),
                          Text(e['date'], style: TextStyle(fontSize: 13,
                              color: color, fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 4),
                        Text(e['description'],
                            style: const TextStyle(fontSize: 13,
                                color: Color(0xFF64748B), height: 1.4)),
                      ]),
                    ),
                  ),
                ]),
              );
            }),
          ]),
        ),
      ),
    ]);
  }
}

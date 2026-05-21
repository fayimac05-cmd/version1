import 'package:flutter/material.dart';
import '../../widgets/emploi_du_temps_widget.dart';
import 'parent_styles.dart';

class ParentScheduleTab extends StatelessWidget {
  const ParentScheduleTab({super.key});

  // Reusing academic calendar events for parent tracking consistency
  static const List<Map<String, dynamic>> _events = [
    {
      'title': 'Rentrée académique 2024-2025',
      'date': '15 septembre 2024',
      'description': 'Début de l\'année académique 2024-2025 pour toutes les filières.',
      'type': 'Académique',
    },
    {
      'title': 'Début des examens S3',
      'date': '04 nov. 2024 → 15 nov. 2024',
      'description': 'Examens de fin du semestre 3.',
      'type': 'Examens',
    },
    {
      'title': 'Délibérations S3',
      'date': '25 novembre 2024',
      'description': 'Publication officielle des résultats du semestre 3.',
      'type': 'Résultats',
    },
    {
      'title': 'Vacances académiques',
      'date': '23 déc. 2024 → 05 jan. 2025',
      'description': 'Vacances scolaires de fin d\'année.',
      'type': 'Vacances',
    },
    {
      'title': 'Inscriptions pédagogiques S4',
      'date': 'Avant le 05 Mai 2026',
      'description': 'Régularisation administrative et pédagogique requise.',
      'type': 'Urgent',
    },
  ];

  Color _getEventTypeColor(String type) {
    switch (type) {
      case 'Examens':
        return ParentStyles.danger;
      case 'Résultats':
        return ParentStyles.success;
      case 'Vacances':
        return const Color(0xFF0891B2);
      case 'Urgent':
        return ParentStyles.warning;
      default:
        return ParentStyles.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParentStyles.bgLight,
      body: SafeArea(
        child: ParentResponsiveBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── HEADER DE SECTION ─────────────────────────────────────────
              const ParentSectionHeader(
                title: 'Emploi du temps & Planning',
                subtitle: 'Planning hebdomadaire et calendrier officiel',
                icon: Icons.calendar_month_outlined,
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── PARTIE 1 : EMPLOIS DU TEMPS (PDF) ─────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Emploi du temps hebdomadaire',
                            style: ParentStyles.sectionTitle(context),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: ParentStyles.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: ParentStyles.primary.withOpacity(0.15)),
                            ),
                            child: const Text(
                              'En cours',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: ParentStyles.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Using the shared platform timetable downloader widget
                      const EmploiDuTempsWidget(),
                      const SizedBox(height: 28),

                      // ─── PARTIE 2 : CALENDRIER ACADÉMIQUE ──────────────────
                      Row(
                        children: [
                          const Icon(
                            Icons.event_note_rounded,
                            color: ParentStyles.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Calendrier scolaire',
                            style: ParentStyles.sectionTitle(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // List of planning events
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _events.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          final Color color = _getEventTypeColor(event['type'] as String);

                          return Container(
                            decoration: ParentStyles.cardDecoration(),
                            child: Row(
                              children: [
                                // Side color indicator bar
                                Container(
                                  width: 5,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(ParentStyles.borderRadiusCards),
                                      bottomLeft: Radius.circular(ParentStyles.borderRadiusCards),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                event['title'] as String,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: ParentStyles.textDark,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: color.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                event['type'] as String,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: color,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              size: 12,
                                              color: color,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              event['date'] as String,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: color,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          event['description'] as String,
                                          style: ParentStyles.mutedText.copyWith(fontSize: 12),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

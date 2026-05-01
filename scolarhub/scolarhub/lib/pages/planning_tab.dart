import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class PlanningTab extends StatelessWidget {
  const PlanningTab({super.key});

  @override
  Widget build(BuildContext context) {
    const events = [
      _EventItem(
        titre: 'Rentree academique 2024-2025',
        date: '15 septembre 2024',
        description: 'Debut de l annee academique 2024-2025.',
      ),
      _EventItem(
        titre: 'Debut des examens S3',
        date: '4 novembre 2024 -> 15 novembre 2024',
        description: 'Examens de fin du semestre 3.',
      ),
      _EventItem(
        titre: 'Deliberations S3',
        date: '25 novembre 2024',
        description: 'Publication des resultats du semestre 3.',
      ),
      _EventItem(
        titre: 'Vacances',
        date: '23 decembre 2024 -> 5 janvier 2025',
        description: 'Vacances academiques.',
      ),
      _EventItem(
        titre: 'Reprise des cours S4',
        date: '6 janvier 2025',
        description: 'Debut du semestre 4.',
      ),
    ];

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppPalette.blue,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
          child: Text(
            'Calendrier',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppPalette.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          color: AppPalette.blue,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: const Row(
            children: [
              Icon(Icons.event_outlined, color: AppPalette.yellow),
              SizedBox(width: 10),
              Text(
                'Calendrier Academique 2024-2025',
                style: TextStyle(
                  color: AppPalette.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final borderColor = index.isEven
                  ? AppPalette.blue
                  : AppPalette.yellow;
              return Container(
                decoration: BoxDecoration(
                  color: AppPalette.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.blue.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 96,
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(16),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    events[index].titre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppPalette.softYellow,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Academique',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              events[index].date,
                              style: const TextStyle(
                                color: AppPalette.blue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              events[index].description,
                              style: const TextStyle(color: Colors.black54),
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
        ),
      ],
    );
  }
}

class _EventItem {
  const _EventItem({
    required this.titre,
    required this.date,
    required this.description,
  });

  final String titre;
  final String date;
  final String description;
}

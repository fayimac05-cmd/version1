import 'package:flutter/material.dart';

import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import '../widgets/info_ticker.dart';
import '../widgets/weekly_program_quick_widget.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenue ${profile.prenoms}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Institut Superieur des Technologies - Espace etudiant'),
          const SizedBox(height: 16),
          const InfoTicker(),
          const SizedBox(height: 16),
          const WeeklyProgramQuickWidget(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppPalette.blue, Color(0xFF0E6CD3)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resume rapide',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppPalette.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Consultez vos programmes, vos notes et vos ressources depuis un seul espace.',
                    style: TextStyle(color: AppPalette.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

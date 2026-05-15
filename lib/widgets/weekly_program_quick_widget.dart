import 'package:flutter/material.dart';

import '../pages/program_image_page.dart';
import '../theme/app_palette.dart';

class WeeklyProgramQuickWidget extends StatelessWidget {
  const WeeklyProgramQuickWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final percent = _academicYearProgress();
    final percentLabel = (percent * 100).toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.lightBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppPalette.blue, width: 1.6),
                backgroundColor: AppPalette.softYellow,
                foregroundColor: AppPalette.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProgramImagePage()),
                );
              },
              icon: const Icon(Icons.calendar_view_week_outlined),
              label: const Text(
                'Mon programme',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Progression annee academique: $percentLabel%',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppPalette.blue,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: percent,
              backgroundColor: AppPalette.lightBlue,
              color: AppPalette.yellow,
            ),
          ),
        ],
      ),
    );
  }

  double _academicYearProgress() {
    final now = DateTime.now();
    final start = DateTime(2025, 9, 15);
    final end = DateTime(2026, 7, 31);
    if (now.isBefore(start)) {
      return 0;
    }
    if (now.isAfter(end)) {
      return 1;
    }
    final total = end.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds;
    return elapsed / total;
  }
}

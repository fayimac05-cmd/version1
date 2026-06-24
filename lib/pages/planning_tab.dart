import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class PlanningTab extends StatelessWidget {
  const PlanningTab({super.key});

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
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15),
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
        child: Container(
          color: AppPalette.white,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Emploi du temps hebdomadaire',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.zoom_in, color: AppPalette.blue, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Pincez pour zoomer',
                        style: TextStyle(fontSize: 12, color: AppPalette.blue, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: Image.asset(
                        'assets/programme_semaine.png',
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}

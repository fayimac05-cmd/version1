import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

/// Programme complet de la semaine du professeur (créneaux donnés par
/// l'administration dans les emplois du temps).
class MonProgrammeSemaine extends StatelessWidget {
  const MonProgrammeSemaine({super.key, required this.creneaux});
  final List<Map<String, dynamic>> creneaux;

  static const _jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

  @override
  Widget build(BuildContext context) {
    final aujourdhui = _jours[DateTime.now().weekday - 1];
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: AppPalette.blue,
        foregroundColor: Colors.white,
        title: const Text('Mon programme de la semaine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
      body: creneaux.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "L'administration ne vous a pas encore attribué de cours dans les emplois du temps.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final jour in _jours)
                  if (creneaux.any((c) => c['jour']?.toString().trim() == jour))
                    _jourCarte(jour, jour == aujourdhui),
              ],
            ),
    );
  }

  Widget _jourCarte(String jour, bool estAujourdhui) {
    final liste = creneaux.where((c) => c['jour']?.toString().trim() == jour).toList()
      ..sort((a, b) => (a['heureDebut']?.toString() ?? '').compareTo(b['heureDebut']?.toString() ?? ''));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: estAujourdhui ? AppPalette.blue : const Color(0xFFE2E8F0), width: estAujourdhui ? 1.6 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(jour, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            if (estAujourdhui) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppPalette.blue, borderRadius: BorderRadius.circular(8)),
                child: const Text("Aujourd'hui", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ],
          ]),
          const SizedBox(height: 10),
          for (final c in liste) _ligne(c),
        ],
      ),
    );
  }

  Widget _ligne(Map<String, dynamic> c) {
    final classe = [c['filiere_nom'], c['niveau']].where((e) => e != null && e.toString().isNotEmpty).join(' · ');
    final salle = c['salle']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          width: 74,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: AppPalette.blue.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Text('${c['heureDebut'] ?? '--'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppPalette.blue)),
            Text('${c['heureFin'] ?? '--'}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${c['matiere'] ?? 'Cours'}', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text([if (classe.isNotEmpty) classe, if (salle.isNotEmpty) 'Salle $salle'].join('  ·  '),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ]),
        ),
      ]),
    );
  }
}

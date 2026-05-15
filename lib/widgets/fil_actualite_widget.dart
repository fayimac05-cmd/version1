import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import '../pages/canal_screen.dart';

class FilActualiteWidget extends StatelessWidget {
  const FilActualiteWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _CanalCard(
        titre: 'Administration',
        icon: Icons.account_balance_outlined,
        color: AppPalette.blue,
        nbNonLus: 3,
        lastMessage: 'Programme ST2 publié pour la semaine du 27 Avr.',
        lastTime: '13:16',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const CanalScreen(
            canal: 'Administration',
            color: AppPalette.blue,
            icon: Icons.account_balance_outlined,
          ),
        )),
      )),
      const SizedBox(width: 14),
      Expanded(child: _CanalCard(
        titre: 'Bureau des Étudiants',
        icon: Icons.groups_outlined,
        color: Color(0xFF7C3AED),
        nbNonLus: 1,
        lastMessage: 'Soirée étudiante vendredi 02 Mai ! Tickets dispo.',
        lastTime: 'Hier',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const CanalScreen(
            canal: 'Bureau des Étudiants',
            color: Color(0xFF7C3AED),
            icon: Icons.groups_outlined,
          ),
        )),
      )),
    ]);
  }
}

class _CanalCard extends StatelessWidget {
  final String titre;
  final IconData icon;
  final Color color;
  final int nbNonLus;
  final String lastMessage;
  final String lastTime;
  final VoidCallback onTap;

  const _CanalCard({
    required this.titre, required this.icon, required this.color,
    required this.nbNonLus, required this.lastMessage,
    required this.lastTime, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: nbNonLus > 0 ? color.withOpacity(0.35) : const Color(0xFFE2E8F0),
            width: nbNonLus > 0 ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            if (nbNonLus > 0)
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(child: Text('$nbNonLus',
                    style: const TextStyle(fontSize: 12, color: Colors.white,
                        fontWeight: FontWeight.bold))),
              ),
          ]),
          const SizedBox(height: 12),
          Text(titre,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A), letterSpacing: -0.1),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 5),
          Text(lastMessage,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight,
              child: Text(lastTime,
                  style: TextStyle(fontSize: 11,
                    color: nbNonLus > 0 ? color : const Color(0xFF64748B),
                    fontWeight: nbNonLus > 0 ? FontWeight.bold : FontWeight.normal,
                  ))),
        ]),
      ),
    );
  }
}

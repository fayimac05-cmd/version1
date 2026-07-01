import 'package:flutter/material.dart';
import '../widgets/app_bubble_bg.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'title': 'Examen mi-parcours',
        'body': 'Demain à 14h00 - Salle C101',
        'time': 'Il y a 2h',
        'icon': Icons.assignment,
        'color': Color(0xFFFCEBEB),
        'iconColor': Color(0xFFA32D2D),
      },
      {
        'title': 'Note publiée',
        'body': 'Base de données : 18.0/20',
        'time': 'Hier',
        'icon': Icons.grade,
        'color': Color(0xFFFAEEDA),
        'iconColor': Color(0xFF854F0B),
      },
      {
        'title': 'Nouveau cours disponible',
        'body': 'Pr. Koanda a posté un nouveau cours - Réseaux',
        'time': 'Il y a 2 jours',
        'icon': Icons.menu_book_outlined,
        'color': Color(0xFFE6F1FB),
        'iconColor': Color(0xFF185FA5),
      },
      {
        'title': 'Message de la filière',
        'body': 'Réunion BDE vendredi 15h - Amphi A',
        'time': 'Il y a 3 jours',
        'icon': Icons.group_outlined,
        'color': Color(0xFFEEEDFE),
        'iconColor': Color(0xFF534AB7),
      },
      {
        'title': 'Bulletin disponible',
        'body': 'Votre bulletin du semestre 2 est prêt',
        'time': 'Il y a 1 semaine',
        'icon': Icons.description_outlined,
        'color': Color(0xFFEAF3DE),
        'iconColor': Color(0xFF3B6D11),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFEEF4FB),
      body: Column(
        children: [
          AppPageHeader(
            title: 'Notifications',
            subtitle: '${notifications.length} non lues',
            onBack: () => Navigator.of(context).pop(),
            trailing: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Tout lire',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final n = notifications[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: n['color'] as Color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  n['icon'] as IconData,
                  color: n['iconColor'] as Color,
                  size: 22,
                ),
              ),
              title: Text(
                n['title'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    n['body'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n['time'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {'title': 'Examen mi-parcours', 'body': 'Demain à 14h00 - Salle C101', 'time': 'Il y a 2h', 'icon': Icons.assignment},
      {'title': 'Note publiée', 'body': 'Base de données : 18.0/20', 'time': 'Hier', 'icon': Icons.grade},
      {'title': 'Nouveau cours', 'body': 'Algorithmique - Salle B204', 'time': 'Il y a 2 jours', 'icon': Icons.book},
      {'title': 'Message de la filière', 'body': 'Réunion BDE vendredi 15h', 'time': 'Il y a 3 jours', 'icon': Icons.group},
      {'title': 'Bulletin disponible', 'body': 'Votre bulletin S2 est prêt', 'time': 'Il y a 1 semaine', 'icon': Icons.description},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF64748B),
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final n = notifications[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFEFF6FF),
              child: Icon(n['icon'] as IconData, color: const Color(0xFF1D4ED8), size: 20),
            ),
            title: Text(n['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(n['body'] as String,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            trailing: Text(n['time'] as String,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          );
        },
      ),
    );
  }
}
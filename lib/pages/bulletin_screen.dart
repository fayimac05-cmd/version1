import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'pdf_viewer_screen.dart';

class BulletinScreen extends StatelessWidget {
  const BulletinScreen({super.key});

  static const List<Map<String, dynamic>> bulletins = [
    {
      'semestre': 'Semestre 1 - 2024',
      'moyenne': 14.5,
      'fichier': 'bulletin_s1_2024.pdf',
      'color': Color(0xFF3B82F6),
      'sigle': 'IST',
    },
    {
      'semestre': 'Semestre 2 - 2024',
      'moyenne': 15.2,
      'fichier': 'bulletin_s2_2024.pdf',
      'color': Color(0xFF10B981),
      'sigle': 'IST',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.white,
      appBar: AppBar(
        title: const Text('Bulletins scolaires'),
        backgroundColor: AppPalette.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bulletins.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final bulletin = bulletins[index];
          return Card(
            child: ListTile(
              leading: Icon(Icons.picture_as_pdf, color: bulletin['color']),
              title: Text(bulletin['semestre']),
              subtitle: Text('Moyenne : ${bulletin['moyenne']}/20'),
              trailing: const Icon(Icons.visibility_outlined),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(pdf: bulletin),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

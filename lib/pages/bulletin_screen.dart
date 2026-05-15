import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import 'pdf_viewer_screen.dart';

class BulletinScreen extends StatelessWidget {
  const BulletinScreen({super.key});

  final List<Map<String, dynamic>> bulletins = const [
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
      appBar: AppBar(title: const Text('Bulletins Scolaires')),
      body: ListView.builder(
        itemCount: bulletins.length,
        itemBuilder: (context, i) {
          final b = bulletins[i];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: Icon(Icons.picture_as_pdf, color: b['color']),
              title: Text(b['semestre']),
              subtitle: Text('Moyenne : ${b['moyenne']}/20'),
              trailing: IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PdfViewerScreen(pdf: b)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

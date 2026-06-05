import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import 'pdf_viewer_screen.dart';

class BulletinScreen extends StatelessWidget {
  final String studentName;
  final String semester;

  const BulletinScreen({
    super.key,
    required this.studentName,
    required this.semester,
  });

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
        backgroundColor: AppPalette.blue,
        elevation: 0,
        title: const Text(
          "Bulletin de Notes",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('En cours de développement...')),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de l'étudiant
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppPalette.lightBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppPalette.blue,
                    child: Text(
                      studentName.substring(0, 1),
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.blue,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          semester,
                          style: TextStyle(
                            color: AppPalette.black.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Moyenne Générale
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.blue.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: AppPalette.yellow, width: 4),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '14.85',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.blue,
                        ),
                      ),
                      Text(
                        'Moy. Générale',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Liste des bulletins
            ...bulletins.map((b) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf, color: b['color']),
                    title: Text(b['semestre']),
                    subtitle: Text('Moyenne : ${b['moyenne']}/20'),
                    trailing: IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfViewerScreen(pdf: b),
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

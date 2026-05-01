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
      'pages': '12',
      'taille': '1.1 Mo',
      'color': Color(0xFF3B82F6),
      'sigle': 'IST',
      'titre': 'IST — Bulletin Scolaire S1',
      'date': 'Juin 2024',
      'credits': 30,
      'mention': 'Assez bien',
    },
    {
      'semestre': 'Semestre 2 - 2024',
      'moyenne': 15.2,
      'fichier': 'bulletin_s2_2024.pdf',
      'pages': '14',
      'taille': '1.3 Mo',
      'color': Color(0xFF10B981),
      'sigle': 'IST',
      'titre': 'IST — Bulletin Scolaire S2',
      'date': 'Décembre 2024',
      'credits': 32,
      'mention': 'Bien',
    },
  ];

  String _getMention(double moyenne) {
    if (moyenne >= 16) return 'Très bien';
    if (moyenne >= 14) return 'Bien';
    if (moyenne >= 12) return 'Assez bien';
    if (moyenne >= 10) return 'Passable';
    return 'Insuffisant';
  }

  Color _getMentionColor(double moyenne) {
    if (moyenne >= 16) return Colors.green;
    if (moyenne >= 14) return Colors.lightGreen;
    if (moyenne >= 12) return Colors.orange;
    if (moyenne >= 10) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Bulletins Scolaires',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppPalette.blue, AppPalette.blue.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Section info élève (à personnaliser)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppPalette.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school,
                    color: AppPalette.blue,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Étudiant',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const Text(
                        'John DOE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Classe: Licence 3 Informatique',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '2024-2025',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppPalette.blue,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Statistiques générales
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Moyenne Générale',
                  '${(bulletins.fold<double>(0, (sum, b) => sum + (b['moyenne'] as double)) / bulletins.length).toStringAsFixed(1)}/20',
                  Icons.auto_graph,
                  AppPalette.blue,
                ),
                Container(height: 40, width: 1, color: Colors.grey[200]),
                _buildStatCard(
                  'Crédits Validés',
                  '${bulletins.fold<int>(0, (sum, b) => sum + (b['credits'] as int))}',
                  Icons.verified,
                  Colors.green,
                ),
                Container(height: 40, width: 1, color: Colors.grey[200]),
                _buildStatCard(
                  'Semestres',
                  '${bulletins.length}',
                  Icons.menu_book,
                  Colors.orange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Liste des bulletins
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Logique de rafraîchissement
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bulletins.length,
                itemBuilder: (context, index) {
                  final bulletin = bulletins[index];
                  final moyenne = bulletin['moyenne'] as double;
                  final mention = _getMention(moyenne);
                  final mentionColor = _getMentionColor(moyenne);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdfViewerScreen(pdf: bulletin),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: (bulletin['color'] as Color)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.picture_as_pdf_rounded,
                                      color: bulletin['color'],
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bulletin['semestre'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 12,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              bulletin['date'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.credit_card,
                                              size: 12,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${bulletin['credits']} crédits',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: mentionColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 14,
                                          color: mentionColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          mention,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: mentionColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (bulletin['color'] as Color)
                                            .withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Moyenne',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${bulletin['moyenne']}',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                '/20',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                          LinearProgressIndicator(
                                            value: moyenne / 20,
                                            backgroundColor: Colors.grey[200],
                                            color: mentionColor,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            minHeight: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (bulletin['color'] as Color)
                                            .withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildInfoChip(
                                            Icons.description,
                                            '${bulletin['pages']} pages',
                                            Colors.blue,
                                          ),
                                          Container(
                                            height: 20,
                                            width: 1,
                                            color: Colors.grey[300],
                                          ),
                                          _buildInfoChip(
                                            Icons.storage,
                                            bulletin['taille'],
                                            Colors.purple,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PdfViewerScreen(pdf: bulletin),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppPalette.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.visibility, size: 18),
                                  label: const Text(
                                    'Consulter le bulletin',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Logique pour télécharger tous les bulletins
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Téléchargement de tous les bulletins...'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        backgroundColor: AppPalette.blue,
        icon: const Icon(Icons.download),
        label: const Text('Tout télécharger'),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

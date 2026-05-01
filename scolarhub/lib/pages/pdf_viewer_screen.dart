import 'package:flutter/material.dart';

class PdfViewerScreen extends StatelessWidget {
  final Map<String, dynamic> pdf;
  const PdfViewerScreen({super.key, required this.pdf});

  @override
  Widget build(BuildContext context) {
    final color = pdf['color'] as Color;
    final sigle = pdf['sigle'] as String;

    // Déterminer le type de document (bulletin ou planning)
    final isBulletin = pdf.containsKey('moyenne') || pdf['semestre'] != null;
    final titre = isBulletin
        ? (pdf['titre'] as String? ?? '$sigle — Bulletin Scolaire')
        : (pdf['titre'] as String? ?? '$sigle — Emploi du temps');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          titre,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.download_rounded, size: 26),
              onPressed: () => showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => _DownloadDialog(pdf: pdf),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Bandeau fichier
          Container(
            color: color.withOpacity(0.12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isBulletin
                      ? Icons.picture_as_pdf_rounded
                      : Icons.calendar_month,
                  color: color,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pdf['fichier'],
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${pdf['pages']} • ${pdf['taille']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // AFFICHAGE CONDITIONNEL
          Expanded(
            child: isBulletin
                ? _buildBulletinContent(context, color, sigle)
                : _buildPlanningContent(context, color, sigle),
          ),

          // Bouton télécharger
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => _DownloadDialog(pdf: pdf),
                ),
                icon: const Icon(Icons.download_rounded, size: 22),
                label: Text(
                  isBulletin
                      ? 'Télécharger le bulletin'
                      : 'Télécharger le planning',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== BULLETIN UNIVERSITAIRE PROFESSIONNEL ==========
  Widget _buildBulletinContent(
    BuildContext context,
    Color color,
    String sigle,
  ) {
    final moyenne = pdf['moyenne'] as double;
    final mention = _getMention(moyenne);
    final mentionColor = _getMentionColor(moyenne);
    final semestre = pdf['semestre'] ?? 'Semestre 1';
    final annee = pdf['date'] ?? '2024';
    final creditsTotal = pdf['credits'] ?? 30;
    final creditsObtenus = (creditsTotal * (moyenne / 20)).toInt();
    final rang = 12;
    final totalEtudiants = 128;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // EN-TÊTE UNIVERSITAIRE
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UNIVERSITÉ',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.7),
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            sigle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          annee,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'RELEVÉ DE NOTES',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    semestre.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // INFORMATIONS ÉTUDIANT
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.person, color: color, size: 24),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ÉTUDIANT',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const Text(
                            'DOE John',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        'Matricule',
                        'IST-2024-001',
                        Icons.numbers,
                        color,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        'Filière',
                        'Informatique de Gestion',
                        Icons.computer,
                        color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        'Niveau',
                        'Licence 3',
                        Icons.school,
                        color,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        'Année académique',
                        '2024-2025',
                        Icons.calendar_today,
                        color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // RÉSULTATS PRINCIPAUX
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'RÉSULTATS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Divider(height: 20, thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResultCard(
                      'MOYENNE',
                      '${moyenne.toStringAsFixed(2)}',
                      '/20',
                      mentionColor,
                      Icons.auto_graph,
                    ),
                    Container(height: 50, width: 1, color: Colors.grey[200]),
                    _buildResultCard(
                      'MENTION',
                      mention,
                      '',
                      mentionColor,
                      Icons.star,
                    ),
                    Container(height: 50, width: 1, color: Colors.grey[200]),
                    _buildResultCard(
                      'RANG',
                      '$rang${_getOrdinal(rang)}',
                      '/$totalEtudiants',
                      Colors.orange,
                      Icons.leaderboard,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: moyenne / 20,
                  backgroundColor: Colors.grey[100],
                  color: mentionColor,
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 10,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progression',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '${((moyenne / 20) * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: mentionColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // TABLEAU DÉTAILLÉ DES NOTES
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.menu_book, color: color, size: 20),
                      const SizedBox(width: 10),
                      const Text(
                        'RELEVÉ DÉTAILLÉ DES NOTES',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const _NotesTable(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildLegend(color),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Crédits validés :',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '$creditsObtenus / $creditsTotal',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: creditsObtenus >= creditsTotal * 0.6
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // STATISTIQUES PROMOTION
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'STATISTIQUES DE LA PROMOTION',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatRow(
                        'Moyenne de la classe',
                        '12.8/20',
                        Icons.people,
                      ),
                    ),
                    Expanded(
                      child: _buildStatRow(
                        'Meilleure note',
                        '18.5/20',
                        Icons.emoji_events,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatRow(
                        'Taux de réussite',
                        '85%',
                        Icons.analytics,
                      ),
                    ),
                    Expanded(
                      child: _buildStatRow(
                        'Médiane',
                        '13.2/20',
                        Icons.show_chart,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // SIGNATURES
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Container(width: 120, height: 2, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Le Chef de département',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Container(width: 120, height: 2, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Le Secrétaire général',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Affichage du PLANNING
  Widget _buildPlanningContent(
    BuildContext context,
    Color color,
    String sigle,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: _Tableau(sigle: sigle, color: color),
    );
  }

  // ========== MÉTHODES UTILITAIRES ==========

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(
    String label,
    String value,
    String suffix,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (suffix.isNotEmpty)
          Text(suffix, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(Color color) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(Colors.green, '≥ 16', 'Très bien'),
          const SizedBox(width: 16),
          _buildLegendItem(Colors.lightGreen, '14-16', 'Bien'),
          const SizedBox(width: 16),
          _buildLegendItem(Colors.orange, '12-14', 'Assez bien'),
          const SizedBox(width: 16),
          _buildLegendItem(Colors.amber, '10-12', 'Passable'),
          const SizedBox(width: 16),
          _buildLegendItem(Colors.red, '< 10', 'Insuffisant'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String range, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              range,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
            Text(label, style: TextStyle(fontSize: 8, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

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

  String _getOrdinal(int number) {
    if (number == 1) return 'er';
    return 'ème';
  }
}

// ========== TABLEAU DES NOTES ==========
class _NotesTable extends StatelessWidget {
  const _NotesTable();

  @override
  Widget build(BuildContext context) {
    const matieres = [
      {
        'code': 'INF301',
        'matiere': 'Programmation Mobile',
        'credit': 4,
        'note': 15.5,
        'coeff': 3,
      },
      {
        'code': 'INF302',
        'matiere': 'Base de données avancée',
        'credit': 4,
        'note': 14.0,
        'coeff': 3,
      },
      {
        'code': 'INF303',
        'matiere': 'Génie logiciel',
        'credit': 3,
        'note': 16.0,
        'coeff': 2,
      },
      {
        'code': 'INF304',
        'matiere': 'Réseaux et sécurité',
        'credit': 3,
        'note': 13.5,
        'coeff': 2,
      },
      {
        'code': 'INF305',
        'matiere': 'Intelligence artificielle',
        'credit': 4,
        'note': 14.5,
        'coeff': 3,
      },
      {
        'code': 'ANG101',
        'matiere': 'Anglais technique',
        'credit': 2,
        'note': 12.0,
        'coeff': 1,
      },
      {
        'code': 'COM201',
        'matiere': 'Communication',
        'credit': 2,
        'note': 13.0,
        'coeff': 1,
      },
      {
        'code': 'PROJET',
        'matiere': 'Projet de fin semestre',
        'credit': 4,
        'note': 15.0,
        'coeff': 4,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
        columns: const [
          DataColumn(
            label: Text(
              'Code',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          DataColumn(
            label: Text(
              'Matière',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          DataColumn(
            label: Text(
              'Crédits',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          DataColumn(
            label: Text(
              'Note /20',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          DataColumn(
            label: Text(
              'Coeff',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          DataColumn(
            label: Text(
              'Moy.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
        rows: matieres.map((matiere) {
          final note = matiere['note'] as double;
          final coeff = matiere['coeff'] as int;
          final moyennePondere = note * coeff;
          final colorNote = note >= 10 ? Colors.green : Colors.red;

          return DataRow(
            cells: [
              DataCell(
                Text(
                  matiere['code'] as String,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              DataCell(
                Text(
                  matiere['matiere'] as String,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              DataCell(
                Text(
                  '${matiere['credit']}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              DataCell(
                Text(
                  '${note.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorNote,
                  ),
                ),
              ),
              DataCell(Text('$coeff', style: const TextStyle(fontSize: 11))),
              DataCell(
                Text(
                  '${moyennePondere.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ========== TABLEAU PLANNING ==========
class _Tableau extends StatelessWidget {
  final String sigle;
  final Color color;
  const _Tableau({required this.sigle, required this.color});

  Map<String, String> get _data => sigle == 'ST'
      ? {
          'MERCREDI-07H30-10H30': 'Devoir\nLabo Analyses\nMédicales\n9H-12H',
          'MERCREDI-10H30-12H30': 'Devoir\nLabo Analyses\nMédicales\n9H-12H',
          'SAMEDI-07H30-10H30': 'VISITE\nHOPITAL\nZINIARE',
          'SAMEDI-10H30-12H30': 'VISITE\nHOPITAL\nZINIARE',
        }
      : {
          'LUNDI-07H30-10H30': 'Comptabilité\nGénérale\nSalle A01',
          'LUNDI-10H30-12H30': 'Droit\nCommercial\nSalle B03',
          'MARDI-07H30-10H30': 'Gestion\nSalle C02',
          'JEUDI-14H00-18H00': 'Fiscalité\nSalle A04',
        };

  @override
  Widget build(BuildContext context) {
    const jours = ['LUNDI', 'MARDI', 'MERCREDI', 'JEUDI', 'VENDREDI', 'SAMEDI'];
    const horaires = ['07H30-10H30', '10H30-12H30', 'PAUSE', '14H00-18H00'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'SEMAINE DU 27 AU 02 AVRIL 2026',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  'PROGRAMME $sigle — ANNÉE ACADÉMIQUE 2025-2026',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              border: TableBorder.all(
                color: const Color(0xFFE2E8F0),
                width: 0.5,
              ),
              defaultColumnWidth: const FixedColumnWidth(95),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: color.withOpacity(0.12)),
                  children: ['HORAIRES', ...jours]
                      .map(
                        (j) => TableCell(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Text(
                              j,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                ...horaires.map((h) {
                  if (h == 'PAUSE') {
                    return TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFE5E7EB)),
                      children: List.generate(
                        7,
                        (_) => TableCell(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: const Text(
                              'PAUSE',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return TableRow(
                    children: [
                      TableCell(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 4,
                          ),
                          color: color.withOpacity(0.06),
                          child: Text(
                            h,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      ...jours.map((j) {
                        final content = _data['$j-$h'];
                        return TableCell(
                          child: Container(
                            height: 85,
                            padding: const EdgeInsets.all(5),
                            color: content != null
                                ? const Color(0xFFFBBF24).withOpacity(0.28)
                                : Colors.white,
                            child: content != null
                                ? Text(
                                    content,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                : const SizedBox(),
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========== DIALOG DE TÉLÉCHARGEMENT ==========
class _DownloadDialog extends StatefulWidget {
  final Map<String, dynamic> pdf;
  const _DownloadDialog({required this.pdf});

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  double _progress = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _simuler();
  }

  Future<void> _simuler() async {
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      setState(() => _progress = i / 10);
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _done = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.pdf['color'] as Color;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _done
                  ? Container(
                      key: const ValueKey('d'),
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1DB954),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    )
                  : Container(
                      key: const ValueKey('l'),
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          value: _progress,
                          color: color,
                          strokeWidth: 4,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              _done ? 'Téléchargé !' : 'Téléchargement en cours...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _done
                    ? const Color(0xFF15803D)
                    : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.pdf['fichier'],
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (_done) ...[
              const SizedBox(height: 10),
              const Text(
                'Enregistré dans vos dossiers',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1DB954),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (!_done) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: color,
                  minHeight: 7,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${(_progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

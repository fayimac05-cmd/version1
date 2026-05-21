import 'package:flutter/material.dart';
import 'parent_styles.dart';

class ParentGradeItem {
  final String subject;
  final String code;
  final String professor;
  final double? grade;
  final double? cc;
  final double? tp;
  final double? exam;
  final int coefficient;
  final String remarks;

  const ParentGradeItem({
    required this.subject,
    required this.code,
    required this.professor,
    required this.grade,
    this.cc,
    this.tp,
    this.exam,
    required this.coefficient,
    required this.remarks,
  });

  String get status {
    if (grade == null) return 'attente';
    if (grade! >= 10.0) return 'valide';
    if (grade! >= 8.0) return 'danger';
    return 'blamable';
  }

  Color get statusColor {
    switch (status) {
      case 'valide':
        return ParentStyles.success;
      case 'danger':
        return ParentStyles.warning;
      case 'blamable':
        return ParentStyles.danger;
      default:
        return ParentStyles.textMuted;
    }
  }

  Color get statusBgColor {
    switch (status) {
      case 'valide':
        return ParentStyles.successLight;
      case 'danger':
        return ParentStyles.warningLight;
      case 'blamable':
        return ParentStyles.dangerLight;
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  String get statusLabel {
    switch (status) {
      case 'valide':
        return 'Validé';
      case 'danger':
        return 'En danger';
      case 'blamable':
        return 'Blâmable';
      default:
        return 'En attente';
    }
  }
}

class ParentGradesTab extends StatelessWidget {
  final String nomEnfant;

  const ParentGradesTab({
    super.key,
    required this.nomEnfant,
  });

  // Simulated list of child grades matching the real school system
  static const List<ParentGradeItem> _grades = [
    ParentGradeItem(
      subject: 'Algorithmique & Structures de Données',
      code: 'INFO101',
      professor: 'Prof. Ouédraogo',
      grade: 15.10,
      cc: 14.0,
      tp: 15.0,
      exam: 16.0,
      coefficient: 3,
      remarks: 'Excellent travail, très bonne compréhension des algorithmes.',
    ),
    ParentGradeItem(
      subject: 'Bases de Données Relationnelles',
      code: 'INFO102',
      professor: 'Mme. Traoré',
      grade: 13.10,
      cc: 12.0,
      tp: 13.0,
      exam: 14.0,
      coefficient: 3,
      remarks: 'Bonne participation aux séances pratiques de requêtes SQL.',
    ),
    ParentGradeItem(
      subject: 'Mathématiques Discrètes',
      code: 'MATH201',
      professor: 'Prof. Kaboré',
      grade: 12.20,
      cc: 11.0,
      exam: 13.0,
      coefficient: 2,
      remarks: 'Travail régulier. Bon niveau en logique et graphes.',
    ),
    ParentGradeItem(
      subject: 'Programmation Orientée Objet',
      code: 'INFO104',
      professor: 'Prof. Ouédraogo',
      grade: 9.50,
      cc: 10.0,
      exam: 9.0,
      coefficient: 3,
      remarks: 'Des difficultés sur la programmation Dart. Doit s\'exercer.',
    ),
    ParentGradeItem(
      subject: 'Réseaux Informatiques',
      code: 'INFO103',
      professor: 'M. Sawadogo',
      grade: 4.50,
      cc: 5.0,
      exam: 4.0,
      coefficient: 2,
      remarks: 'Résultats insuffisants. Manque de rigueur dans les devoirs.',
    ),
    ParentGradeItem(
      subject: 'Anglais Technique',
      code: 'ANG101',
      professor: 'M. Johnson',
      grade: 16.60,
      cc: 16.0,
      exam: 17.0,
      coefficient: 1,
      remarks: 'Excellente maîtrise de la langue, très dynamique à l\'oral.',
    ),
    ParentGradeItem(
      subject: 'Systèmes d\'Exploitation',
      code: 'INFO105',
      professor: 'Mme. Traoré',
      grade: null,
      cc: null,
      coefficient: 2,
      remarks: 'Notes en attente de publication par le secrétariat.',
    ),
  ];

  double get _weightedAverage {
    final gradedItems = _grades.where((g) => g.grade != null).toList();
    if (gradedItems.isEmpty) return 0;
    double totalPoints = 0;
    int totalCoeffs = 0;
    for (var item in gradedItems) {
      totalPoints += item.grade! * item.coefficient;
      totalCoeffs += item.coefficient;
    }
    return totalCoeffs == 0 ? 0 : totalPoints / totalCoeffs;
  }

  int get _countValide => _grades.where((g) => g.status == 'valide').length;
  int get _countDanger => _grades.where((g) => g.status == 'danger').length;
  int get _countBlamable => _grades.where((g) => g.status == 'blamable').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParentStyles.bgLight,
      body: SafeArea(
        child: ParentResponsiveBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── HEADER DE SECTION ─────────────────────────────────────────
              ParentSectionHeader(
                title: 'Notes académiques',
                subtitle: 'Suivi des évaluations de $nomEnfant',
                icon: Icons.grade_rounded,
              ),

              // ─── RÉSUMÉ ACADÉMIQUE DE L'ENFANT ─────────────────────────────
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), ParentStyles.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(ParentStyles.borderRadiusCards),
                  boxShadow: ParentStyles.cardShadow,
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Moyenne Générale',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _weightedAverage.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            const Text(
                              ' / 20',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Semestre 3 · En cours',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Small indicators grid
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildStatusIndicator('$_countValide', 'Validés', const Color(0xFF86EFAC)),
                        const SizedBox(height: 6),
                        _buildStatusIndicator('$_countDanger', 'En danger', const Color(0xFFFDE68A)),
                        const SizedBox(height: 6),
                        _buildStatusIndicator('$_countBlamable', 'Blâmables', const Color(0xFFFCA5A5)),
                      ],
                    ),
                  ],
                ),
              ),

              // ─── LISTE DES ÉVALUATIONS ─────────────────────────────────────
              Text(
                'Détail des modules',
                style: ParentStyles.sectionTitle(context),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _grades.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _grades[index];
                    return _buildGradeCard(context, item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String count, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          '$count $label',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildGradeCard(BuildContext context, ParentGradeItem item) {
    return GestureDetector(
      onTap: () => _showGradeDetailsSheet(context, item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: ParentStyles.cardDecoration(
          border: Border.all(
            color: item.status == 'blamable'
                ? ParentStyles.danger.withOpacity(0.3)
                : ParentStyles.borderLight,
            width: item.status == 'blamable' ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ParentStyles.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.code,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: ParentStyles.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.statusLabel,
                    style: ParentStyles.badgeText.copyWith(color: item.statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.subject,
              style: ParentStyles.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Professeur : ${item.professor}',
              style: ParentStyles.mutedText,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildGradeMiniBox('CC', item.cc),
                const SizedBox(width: 8),
                _buildGradeMiniBox('TP', item.tp),
                const SizedBox(width: 8),
                _buildGradeMiniBox('Examen', item.exam),
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 32,
                  color: ParentStyles.borderLight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Moyenne Module',
                        style: TextStyle(
                          fontSize: 10,
                          color: ParentStyles.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.grade != null ? '${item.grade!.toStringAsFixed(2)} / 20' : 'À venir',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: item.statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeMiniBox(String label, double? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: ParentStyles.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value != null ? value.toStringAsFixed(1) : '—',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: ParentStyles.textDark,
            ),
          ),
        ],
      ),
    );
  }

  void _showGradeDetailsSheet(BuildContext context, ParentGradeItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ParentStyles.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.subject,
                          style: ParentStyles.sectionTitle(context),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.code} · Coefficient ${item.coefficient}',
                          style: ParentStyles.mutedText,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: item.statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.statusLabel,
                      style: ParentStyles.badgeText.copyWith(color: item.statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Detailed Table
              Container(
                padding: const EdgeInsets.all(14),
                decoration: ParentStyles.cardDecoration(
                  color: const Color(0xFFF8FAFC),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Contrôle Continu (CC)', item.cc),
                    const Divider(height: 16),
                    _buildDetailRow('Travaux Pratiques (TP)', item.tp),
                    const Divider(height: 16),
                    _buildDetailRow('Examen Final', item.exam),
                    const Divider(height: 16),
                    _buildDetailRow('Moyenne Calculée', item.grade, isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Professor Remarks
              const Text(
                'Remarques du professeur',
                style: ParentStyles.cardTitle,
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.statusBgColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: item.statusColor.withOpacity(0.15)),
                ),
                child: Text(
                  item.remarks,
                  style: TextStyle(
                    fontSize: 13,
                    color: item.statusColor == ParentStyles.textMuted
                        ? ParentStyles.textDark
                        : item.statusColor,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Formulaire de contestation envoyé à l\'administration'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.report_problem_outlined),
                      label: const Text('Contester note'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ParentStyles.danger,
                        side: const BorderSide(color: ParentStyles.danger),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Contact initié avec ${item.professor}'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Contacter Prof'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ParentStyles.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, double? value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: ParentStyles.textDark,
          ),
        ),
        Text(
          value != null ? '${value.toStringAsFixed(1)} / 20' : 'Non évalué',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isBold ? ParentStyles.primary : ParentStyles.textDark,
          ),
        ),
      ],
    );
  }
}

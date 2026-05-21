import 'package:flutter/material.dart';
import 'parent_styles.dart';

class ParentHomeTab extends StatelessWidget {
  final String nomEnfant;
  final Function(int) onNavigateToTab;

  const ParentHomeTab({
    super.key,
    required this.nomEnfant,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    // Extract child initials for avatar
    final String initials = nomEnfant.isNotEmpty
        ? nomEnfant
            .split(' ')
            .where((word) => word.isNotEmpty)
            .map((word) => word[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'E';

    return Scaffold(
      backgroundColor: ParentStyles.bgLight,
      body: SafeArea(
        child: ParentResponsiveBody(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── HEADER DE BIENVENUE ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bonjour 👋',
                          style: ParentStyles.mutedText,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Espace Parent',
                          style: ParentStyles.headerTitle(context),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ParentStyles.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ParentStyles.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 14,
                            color: ParentStyles.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Tuteur légal',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: ParentStyles.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ─── CARTE ENFANT SUIVI ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ParentStyles.primary, Color(0xFF1E3A8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(ParentStyles.borderRadiusCards),
                    boxShadow: [
                      BoxShadow(
                        color: ParentStyles.primary.withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Child initials logo in gradient circle
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enfant suivi',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              nomEnfant,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 12,
                                  color: ParentStyles.accent,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'IST Campus Ouaga 2000',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.school_rounded,
                        color: Colors.white30,
                        size: 36,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ─── SECTION RÉSUMÉ ACADÉMIQUE ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Résumé académique',
                      style: ParentStyles.sectionTitle(context),
                    ),
                    TextButton.icon(
                      onPressed: () => onNavigateToTab(1), // Nav to Grades
                      icon: const Text('Détails'),
                      label: const Icon(Icons.arrow_forward_rounded, size: 16),
                      style: TextButton.styleFrom(
                        foregroundColor: ParentStyles.primary,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Stats Cards
                Row(
                  children: [
                    _buildStatCard(
                      context: context,
                      icon: Icons.analytics_rounded,
                      label: 'Moyenne Générale',
                      value: '12.85 / 20',
                      subtext: 'Semestre 3',
                      color: ParentStyles.success,
                      bgColor: ParentStyles.successLight,
                      onTap: () => onNavigateToTab(1),
                    ),
                    const SizedBox(width: 14),
                    _buildStatCard(
                      context: context,
                      icon: Icons.how_to_reg_rounded,
                      label: 'Présence globale',
                      value: '95.5 %',
                      subtext: '0 absence injustifiée',
                      color: ParentStyles.primary,
                      bgColor: const Color(0xFFEAF2FF),
                      onTap: () => onNavigateToTab(2), // Nav to Schedule
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ─── SECTION ALERTES ─────────────────────────────────────────
                Text(
                  'Alertes & Informations',
                  style: ParentStyles.sectionTitle(context),
                ),
                const SizedBox(height: 12),

                // Alerts list
                _buildAlertCard(
                  title: 'Scolarité administrative',
                  message: 'Reste à payer : 0 FCFA (Scolarité entièrement réglée !)',
                  type: 'success',
                ),
                const SizedBox(height: 10),
                _buildAlertCard(
                  title: 'Inscriptions pédagogiques',
                  message: 'Veuillez vérifier que l\'inscription pédagogique du S4 est finalisée.',
                  type: 'warning',
                ),
                const SizedBox(height: 10),
                _buildAlertCard(
                  title: 'Suivi de l\'assiduité',
                  message: 'Aucun retard ni absence injustifiée à signaler cette semaine.',
                  type: 'info',
                ),
                const SizedBox(height: 24),

                // ─── ACCÈS RAPIDES ───────────────────────────────────────────
                Text(
                  'Accès rapides',
                  style: ParentStyles.sectionTitle(context),
                ),
                const SizedBox(height: 12),

                // Quick links row
                Row(
                  children: [
                    _buildQuickLink(
                      icon: Icons.calendar_month_rounded,
                      label: 'Planning',
                      color: const Color(0xFF7C3AED),
                      onTap: () => onNavigateToTab(2),
                    ),
                    const SizedBox(width: 12),
                    _buildQuickLink(
                      icon: Icons.credit_card_rounded,
                      label: 'Paiements',
                      color: const Color(0xFF0891B2),
                      onTap: () => onNavigateToTab(4),
                    ),
                    const SizedBox(width: 12),
                    _buildQuickLink(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Messages',
                      color: const Color(0xFF0D9488),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Messagerie bientôt disponible pour les parents !'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required String subtext,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: ParentStyles.cardDecoration(
            color: bgColor,
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: ParentStyles.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                style: const TextStyle(
                  fontSize: 10,
                  color: ParentStyles.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String message,
    required String type,
  }) {
    Color primaryColor;
    Color bgColor;
    IconData icon;

    switch (type) {
      case 'success':
        primaryColor = ParentStyles.success;
        bgColor = ParentStyles.successLight;
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'warning':
        primaryColor = ParentStyles.warning;
        bgColor = ParentStyles.warningLight;
        icon = Icons.error_outline_rounded;
        break;
      case 'danger':
        primaryColor = ParentStyles.danger;
        bgColor = ParentStyles.dangerLight;
        icon = Icons.report_problem_outlined;
        break;
      default:
        primaryColor = ParentStyles.primary;
        bgColor = const Color(0xFFF1F5F9);
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ParentStyles.cardDecoration(
        color: bgColor,
        border: Border.all(color: primaryColor.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryColor == ParentStyles.primary
                        ? ParentStyles.textDark
                        : primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ParentStyles.textDark,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLink({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: ParentStyles.cardDecoration(),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ParentStyles.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

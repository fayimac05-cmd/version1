import 'package:flutter/material.dart';
import 'parent_styles.dart';

class ParentProfileTab extends StatelessWidget {
  final String nomEnfant;
  final VoidCallback onLogout;

  const ParentProfileTab({
    super.key,
    required this.nomEnfant,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the child's matricule and field of study based on known demo data
    final String childMatricule = nomEnfant.contains('Ibrahim') ? '24IST-O2/1851' : '24IST-O2/1234';
    final String childFiliere = nomEnfant.contains('Ibrahim')
        ? 'Réseaux Informatiques & Télécom (RIT)'
        : 'Licence Informatique (L.I.)';
    final String childNiveau = 'Licence 2';

    return Scaffold(
      backgroundColor: ParentStyles.bgLight,
      body: SafeArea(
        child: ParentResponsiveBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── HEADER DE SECTION ─────────────────────────────────────────
              const ParentSectionHeader(
                title: 'Profil & Paramètres',
                subtitle: 'Gérer vos coordonnées et les accès de l\'établissement',
                icon: Icons.person_rounded,
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── CARTE PARENT (TEXTUELLE, SANS AVATAR) ─────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: ParentStyles.cardDecoration(
                          border: Border.all(color: ParentStyles.primary.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.badge_outlined,
                                  color: ParentStyles.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'COMPTE PARENT / TUTEUR',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: ParentStyles.primary.withOpacity(0.8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            _buildInfoTextRow('Nom complet', 'KOURAOGO Seydou'),
                            const SizedBox(height: 10),
                            _buildInfoTextRow('Adresse email', 'parent@ist.bf'),
                            const SizedBox(height: 10),
                            _buildInfoTextRow('Téléphone tuteur', '+226 65 00 12 34'),
                            const SizedBox(height: 10),
                            _buildInfoTextRow('Statut de liaison', 'Validé par l\'établissement'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ─── CARTE ENFANT RATTACHÉ ──────────────────────────────
                      Text(
                        'Enfant rattaché',
                        style: ParentStyles.sectionTitle(context),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: ParentStyles.cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.school_outlined,
                                  color: ParentStyles.accent,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  nomEnfant,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: ParentStyles.textDark,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            _buildInfoTextRow('Matricule étudiant', childMatricule),
                            const SizedBox(height: 10),
                            _buildInfoTextRow('Filière / Programme', childFiliere),
                            const SizedBox(height: 10),
                            _buildInfoTextRow('Niveau actuel', childNiveau),
                            const SizedBox(height: 10),
                            _buildInfoTextRow('Campus pédagogique', 'IST Ouaga 2000'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ─── BOUTONS DE PARAMÈTRES ET ACTIONS ──────────────────
                      Text(
                        'Options de sécurité & support',
                        style: ParentStyles.sectionTitle(context),
                      ),
                      const SizedBox(height: 12),
                      
                      _buildSettingsTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Modifier le mot de passe',
                        subtitle: 'Sécuriser votre espace de connexion',
                        color: Colors.blue,
                        onTap: () => _showDialogSimulated(context, 'Modification de mot de passe'),
                      ),
                      const SizedBox(height: 10),
                      _buildSettingsTile(
                        icon: Icons.support_agent_rounded,
                        title: 'Contacter le secrétariat',
                        subtitle: 'Service de scolarité pédagogique',
                        color: Colors.green,
                        onTap: () => _showDialogSimulated(context, 'Contact Secrétariat'),
                      ),
                      const SizedBox(height: 10),
                      _buildSettingsTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Assistance technique',
                        subtitle: 'Signaler un problème sur l\'application',
                        color: Colors.orange,
                        onTap: () => _showDialogSimulated(context, 'Support Technique'),
                      ),
                      const SizedBox(height: 32),

                      // ─── DECONNEXION BUTTON ────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: onLogout,
                          icon: const Icon(Icons.logout_rounded, color: ParentStyles.danger, size: 20),
                          label: const Text(
                            'Se déconnecter',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: ParentStyles.danger,
                              letterSpacing: 0.2,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: ParentStyles.danger, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: ParentStyles.danger.withOpacity(0.02),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTextRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: ParentStyles.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: ParentStyles.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: ParentStyles.cardDecoration(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ParentStyles.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: ParentStyles.mutedText.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: ParentStyles.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _showDialogSimulated(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            action,
            style: const TextStyle(fontWeight: FontWeight.bold, color: ParentStyles.textDark),
          ),
          content: Text(
            'L\'action "$action" a été simulée avec succès.\nCette fonctionnalité sera pleinement opérationnelle en production.',
            style: const TextStyle(fontSize: 14, color: ParentStyles.textDark, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Fermer',
                style: TextStyle(fontWeight: FontWeight.bold, color: ParentStyles.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}

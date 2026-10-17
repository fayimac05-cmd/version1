import 'package:flutter/material.dart';
import 'parent_styles.dart';
import '../../models/enfant_apercu.dart';
import 'parent_paiements_screen.dart';

class ParentHomeTab extends StatelessWidget {
  final List<EnfantApercu> enfants;
  final String? selectedEtudiantId;
  final ValueChanged<String> onSelectEnfant;
  final ValueChanged<int> onNavigateToTab;

  const ParentHomeTab({
    super.key,
    required this.enfants,
    required this.selectedEtudiantId,
    required this.onSelectEnfant,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParentStyles.bgLight,
      body: SafeArea(
        child: ParentResponsiveBody(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bonjour 👋', style: ParentStyles.mutedText),
                        const SizedBox(height: 4),
                        Text('Espace Parent', style: ParentStyles.headerTitle(context)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ParentStyles.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ParentStyles.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, size: 14, color: ParentStyles.primary),
                          const SizedBox(width: 4),
                          Text(
                            enfants.length > 1 ? '${enfants.length} enfants' : 'Tuteur légal',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ParentStyles.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  enfants.length > 1 ? 'Vos enfants' : 'Enfant suivi',
                  style: ParentStyles.sectionTitle(context),
                ),
                const SizedBox(height: 12),
                ...enfants.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _carteEnfant(context, e),
                    )),
                const SizedBox(height: 10),

                // ─── ACCÈS RAPIDES ───────────────────────────────────────────
                Text('Accès rapides', style: ParentStyles.sectionTitle(context)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildQuickLink(
                      icon: Icons.credit_card_rounded,
                      label: 'Paiements',
                      color: const Color(0xFF0891B2),
                      onTap: () {
                        final enfantActif = enfants.where((e) => e.etudiantId == selectedEtudiantId).firstOrNull ??
                            (enfants.isNotEmpty ? enfants.first : null);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ParentPaiementsScreen(nomEnfant: enfantActif?.nomComplet ?? ''),
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

  String _initiales(EnfantApercu e) {
    final p = e.prenoms.isNotEmpty ? e.prenoms[0] : '';
    final n = e.nom.isNotEmpty ? e.nom[0] : '';
    return '$p$n'.toUpperCase().isEmpty ? 'E' : '$p$n'.toUpperCase();
  }

  Widget _carteEnfant(BuildContext context, EnfantApercu e) {
    final estSelectionne = e.etudiantId == selectedEtudiantId;
    final aDuNouveau = e.notesNonLues > 0 || e.bulletinsNonLus > 0;

    return GestureDetector(
      onTap: () => onSelectEnfant(e.etudiantId),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ParentStyles.primary, Color(0xFF1E3A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(ParentStyles.borderRadiusCards),
          border: estSelectionne ? Border.all(color: ParentStyles.accent, width: 2) : null,
          boxShadow: [
            BoxShadow(color: ParentStyles.primary.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          _initiales(e),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                        ),
                      ),
                    ),
                    if (aDuNouveau)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.nomComplet,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${e.filiere} · ${e.niveau}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _miniStat(
                    icon: Icons.analytics_rounded,
                    label: 'Moyenne',
                    value: e.moyenne != null ? '${e.moyenne!.toStringAsFixed(2)}/20' : '—',
                    onTap: () {
                      onSelectEnfant(e.etudiantId);
                      onNavigateToTab(1);
                    },
                    badge: e.notesNonLues > 0 ? e.notesNonLues : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _miniStat(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Bulletins',
                    value: e.bulletinsNonLus > 0 ? '${e.bulletinsNonLus} nouveau(x)' : 'À jour',
                    onTap: () {
                      onSelectEnfant(e.etudiantId);
                      onNavigateToTab(2);
                    },
                    badge: e.bulletinsNonLus > 0 ? e.bulletinsNonLus : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _miniStat(
                    icon: Icons.how_to_reg_rounded,
                    label: 'Présence',
                    value: e.tauxPresence != null ? '${e.tauxPresence!.toStringAsFixed(1)}%' : '—',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLink({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: ParentStyles.cardDecoration(),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ParentStyles.textDark)),
              ],
            ),
          ),
        ),
      );

  Widget _miniStat({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    int? badge,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
              const SizedBox(height: 2),
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
}
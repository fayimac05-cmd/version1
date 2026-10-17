import 'package:flutter/material.dart';
import 'parent_styles.dart';
import '../../models/enfant_apercu.dart';
import '../../services/parent_service.dart';
import '../../widgets/profile_header_cover.dart';

class ParentProfileTab extends StatefulWidget {
  final List<EnfantApercu> enfants;
  final VoidCallback onLogout;

  const ParentProfileTab({
    super.key,
    required this.enfants,
    required this.onLogout,
  });

  @override
  State<ParentProfileTab> createState() => _ParentProfileTabState();
}

class _ParentProfileTabState extends State<ParentProfileTab> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ParentService.getMonProfil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParentStyles.bgLight,
      body: SafeArea(
        child: ParentResponsiveBody(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final profil = snapshot.data?['success'] == true
                  ? Map<String, dynamic>.from(snapshot.data!['data'] as Map)
                  : <String, dynamic>{};
              final nom = profil['nom'] ?? '';
              final prenoms = profil['prenoms'] ?? '';
              final email = profil['email'] ?? '';
              final tel = profil['tel'] ?? '';
              final nomComplet = '$prenoms $nom'.trim();
              final initiales = (prenoms.isNotEmpty ? prenoms[0] : '') + (nom.isNotEmpty ? nom[0] : '');

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ParentSectionHeader(
                    title: 'Profil & Paramètres',
                    subtitle: "Gérer vos coordonnées et les accès de l'établissement",
                    icon: Icons.person_rounded,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileHeaderCover(
                            matricule: profil['id']?.toString() ?? '',
                            nomComplet: nomComplet.isNotEmpty ? nomComplet : 'Tuteur',
                            roleLabel: "Parent d'élève",
                            initiales: initiales.toUpperCase().isEmpty ? 'T' : initiales.toUpperCase(),
                            badgeText: 'Tuteur Légal',
                            badgeColor: ParentStyles.primary,
                            accentColor: ParentStyles.primary,
                            bannerGradient: const [Color(0xFF0D3B5E), Color(0xFF1B5E8A), Color(0xFF2E86C1)],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: ParentStyles.cardDecoration(
                              border: Border.all(color: ParentStyles.primary.withValues(alpha: 0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.badge_outlined, color: ParentStyles.primary, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      'COMPTE PARENT / TUTEUR',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: ParentStyles.primary.withValues(alpha: 0.8),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                _ligneInfo('Adresse email', email.isNotEmpty ? email : '—'),
                                const SizedBox(height: 10),
                                _ligneInfo('Téléphone', tel.isNotEmpty ? tel : '—'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            widget.enfants.length > 1 ? 'Enfants rattachés' : 'Enfant rattaché',
                            style: ParentStyles.sectionTitle(context),
                          ),
                          const SizedBox(height: 12),
                          ...widget.enfants.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _carteEnfant(e),
                              )),
                          const SizedBox(height: 12),
                          Text('Options de sécurité & support', style: ParentStyles.sectionTitle(context)),
                          const SizedBox(height: 12),
                          _tuileParametre(
                            icon: Icons.lock_outline_rounded,
                            titre: 'Modifier le mot de passe',
                            sousTitre: 'Sécuriser votre espace de connexion',
                            couleur: Colors.blue,
                            onTap: () => _dialogueSimule('Modification de mot de passe'),
                          ),
                          const SizedBox(height: 10),
                          _tuileParametre(
                            icon: Icons.support_agent_rounded,
                            titre: 'Contacter le secrétariat',
                            sousTitre: 'Service de scolarité pédagogique',
                            couleur: Colors.green,
                            onTap: () => _dialogueSimule('Contact Secrétariat'),
                          ),
                          const SizedBox(height: 10),
                          _tuileParametre(
                            icon: Icons.help_outline_rounded,
                            titre: 'Assistance technique',
                            sousTitre: "Signaler un problème sur l'application",
                            couleur: Colors.orange,
                            onTap: () => _dialogueSimule('Support Technique'),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: widget.onLogout,
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: ParentStyles.danger.withValues(alpha: 0.02),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _carteEnfant(EnfantApercu e) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: ParentStyles.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school_outlined, color: ParentStyles.accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.nomComplet,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ParentStyles.textDark),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _ligneInfo('Matricule étudiant', e.matricule),
            const SizedBox(height: 10),
            _ligneInfo('Filière / Programme', e.filiere),
            const SizedBox(height: 10),
            _ligneInfo('Niveau actuel', e.niveau),
          ],
        ),
      );

  Widget _ligneInfo(String label, String valeur) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 13, color: ParentStyles.textMuted, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(valeur, style: const TextStyle(fontSize: 13, color: ParentStyles.textDark, fontWeight: FontWeight.w600)),
          ),
        ],
      );

  Widget _tuileParametre({
    required IconData icon,
    required String titre,
    required String sousTitre,
    required Color couleur,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: ParentStyles.cardDecoration(),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: couleur.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: couleur, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ParentStyles.textDark)),
                    const SizedBox(height: 2),
                    Text(sousTitre, style: ParentStyles.mutedText.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: ParentStyles.textMuted),
            ],
          ),
        ),
      );

  void _dialogueSimule(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(action, style: const TextStyle(fontWeight: FontWeight.bold, color: ParentStyles.textDark)),
        content: Text(
          'Cette fonctionnalité sera bientôt disponible.',
          style: const TextStyle(fontSize: 14, color: ParentStyles.textDark, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.bold, color: ParentStyles.primary)),
          ),
        ],
      ),
    );
  }
}
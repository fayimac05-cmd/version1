import 'package:flutter/material.dart';
import '../services/annuel_service.dart';
import 'archives_page.dart';

/// Écran affiché à la place de l'application tant que l'étudiant n'est pas réinscrit
/// pour l'année en cours, ou lorsqu'il est diplômé. Dans les deux cas, l'accès à ses
/// archives (années passées, bulletins) reste ouvert en lecture seule.
class ReinscriptionPage extends StatefulWidget {
  final Map<String, dynamic> statut;
  final VoidCallback onLogout;
  final Future<void> Function() onActualiser;
  const ReinscriptionPage({
    super.key,
    required this.statut,
    required this.onLogout,
    required this.onActualiser,
  });
  @override
  State<ReinscriptionPage> createState() => _ReinscriptionPageState();
}

class _ReinscriptionPageState extends State<ReinscriptionPage> {
  static const Color _texte = Color(0xFF0F172A);
  static const Color _gris = Color(0xFF64748B);
  bool _envoi = false;

  Map<String, dynamic> get _s => widget.statut;
  Map<String, dynamic>? get _re => _s['reinscription'] == null ? null : Map<String, dynamic>.from(_s['reinscription'] as Map);

  String _montant(dynamic v) {
    final n = num.tryParse('${v ?? ''}');
    if (n == null) return '';
    final s = n.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return '$b FCFA';
  }

  Future<void> _demander() async {
    setState(() => _envoi = true);
    final r = await AnnuelService.demanderReinscription();
    if (!mounted) return;
    setState(() => _envoi = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(r['success'] == true ? (r['message']?.toString() ?? 'Demande envoyée.') : (r['error']?.toString() ?? 'Erreur.')),
    ));
    if (r['success'] == true) await widget.onActualiser();
  }

  @override
  Widget build(BuildContext context) {
    final parcours = '${_s['parcours']}';
    final diplome = parcours == 'diplome';
    final abandon = parcours == 'abandon';
    final re = _re;
    final statutRe = '${re?['statut'] ?? ''}';
    final annee = '${_s['annee_courante'] ?? ''}';

    String titre;
    String corps;
    IconData icone;
    Color couleur;
    if (diplome) {
      titre = 'Félicitations, tu es diplômé(e) !';
      corps = 'Ton parcours est terminé. Tu gardes l\'accès à tes bulletins et à tes archives, en lecture seule.';
      icone = Icons.workspace_premium_rounded;
      couleur = const Color(0xFF1D4ED8);
    } else if (abandon) {
      titre = 'Dossier clos';
      corps = 'Ton dossier est clos. Tu peux consulter tes archives. Pour toute question, contacte l\'administration.';
      icone = Icons.folder_off_outlined;
      couleur = const Color(0xFF64748B);
    } else if (statutRe == 'demandee') {
      titre = 'Demande envoyée';
      corps = 'Présente-toi à la caisse pour payer tes frais de réinscription, puis garde ton reçu : '
          'l\'administration validera ta réinscription et ton accès sera rétabli.';
      icone = Icons.hourglass_top_rounded;
      couleur = const Color(0xFFD97706);
    } else {
      final decision = '${re?['decision_precedente'] ?? ''}';
      titre = 'Réinscription $annee';
      corps = decision == 'redoublant'
          ? 'Tu redoubles ton année : tu seras réinscrit(e) en ${re?['niveau_cible'] ?? _s['niveau_actuel']}.'
          : 'Bravo, tu passes en ${re?['niveau_cible'] ?? 'niveau supérieur'} ! Réinscris-toi pour reprendre tes cours.';
      icone = Icons.how_to_reg_rounded;
      couleur = const Color(0xFF15803D);
    }

    final aPayer = _montant(re?['montant_a_payer']);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icone, size: 64, color: couleur),
                const SizedBox(height: 16),
                Text(titre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _texte)),
                const SizedBox(height: 10),
                Text(corps, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.45, color: _gris)),
                if (!diplome && !abandon && aPayer.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Frais de réinscription', style: TextStyle(fontSize: 13, color: _gris)),
                      Text(aPayer, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _texte)),
                    ]),
                  ),
                ],
                if (statutRe == 'refusee' && '${re?['motif_refus'] ?? ''}'.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Demande refusée : ${re!['motif_refus']}',
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFFC62828))),
                ],
                const SizedBox(height: 22),
                if (!diplome && !abandon && (statutRe == 'a_faire' || statutRe == 'refusee'))
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _envoi ? null : _demander,
                      icon: _envoi
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send_rounded),
                      label: Text(statutRe == 'refusee' ? 'Refaire ma demande' : 'Demander ma réinscription'),
                    ),
                  ),
                if (statutRe == 'demandee')
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: widget.onActualiser,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Vérifier si c\'est validé'),
                    ),
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ArchivesPage())),
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Mes archives'),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(onPressed: widget.onLogout, child: const Text('Se déconnecter')),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

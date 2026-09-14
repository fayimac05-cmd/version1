import 'package:flutter/material.dart';

/// Couleur associée à un niveau d'étude, pour différencier visuellement les
/// badges délégué/adjoint selon leur niveau (Licence 1 ≠ Licence 3, etc.).
/// Utilisée à la fois dans la gestion admin des délégués, sur le profil
/// étudiant, et sur les bulles de message dans les canaux de discussion.
Color couleurNiveauDelegue(String? niveau) {
  switch (niveau) {
    case 'Licence 1':
      return const Color(0xFF10B981); // vert
    case 'Licence 2':
      return const Color(0xFF3B82F6); // bleu
    case 'Licence 3':
      return const Color(0xFF8B5CF6); // violet
    case 'Master 1':
      return const Color(0xFFF59E0B); // ambre
    case 'Master 2':
      return const Color(0xFFEF4444); // rouge
    default:
      return const Color(0xFF64748B); // gris (niveau inconnu)
  }
}

/// Badge "Délégué" (plein) ou "Adjoint" (contour) — n'affiche rien si
/// [role] n'est ni l'un ni l'autre (élève normal, BDE, etc.).
///
/// Usage :
///   DelegueBadge(role: etudiant['etudiant_role'], niveau: etudiant['niveau'])
class DelegueBadge extends StatelessWidget {
  const DelegueBadge({
    super.key,
    required this.role,
    required this.niveau,
    this.compact = false,
  });

  /// Valeur brute de `users.etudiant_role` : 'delegue', 'delegue_adjoint',
  /// ou toute autre valeur (null, 'etudiant', rôles BDE...) → badge masqué.
  final String? role;
  final String? niveau;

  /// Version réduite pour les bulles de chat (moins de place qu'une carte
  /// de profil).
  final bool compact;

  bool get _estDelegue => role == 'delegue';
  bool get _estAdjoint => role == 'delegue_adjoint';

  @override
  Widget build(BuildContext context) {
    if (!_estDelegue && !_estAdjoint) return const SizedBox.shrink();

    final couleur = couleurNiveauDelegue(niveau);
    final label = _estDelegue ? 'Délégué' : 'Adjoint';
    final icon = _estDelegue ? Icons.star_rounded : Icons.star_border_rounded;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 9,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        // Délégué = badge plein (pleine autorité) ; Adjoint = contour
        // seulement (autorité déléguée) — même couleur de niveau pour les
        // deux, mais le remplissage marque la différence de rang.
        color: _estDelegue ? couleur : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleur, width: _estDelegue ? 0 : 1.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 10 : 12, color: _estDelegue ? Colors.white : couleur),
          SizedBox(width: compact ? 3 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 9 : 10.5,
              fontWeight: FontWeight.w800,
              color: _estDelegue ? Colors.white : couleur,
            ),
          ),
        ],
      ),
    );
  }
}

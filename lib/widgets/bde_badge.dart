import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════════════════
// BADGE BDE — pastille pour président(e)/adjoint(e)/membre du Bureau des
// Étudiants, visuellement cohérente avec DelegueBadge (widgets/delegue_badge.dart)
// mais séparée car le BDE n'a pas de notion de niveau (établissement entier).
// ════════════════════════════════════════════════════════════════════════════
class BdeBadge extends StatelessWidget {
  final String? role; // 'bde_president' | 'bde_adjoint' | 'bde_membre'
  final bool compact;
  const BdeBadge({super.key, required this.role, this.compact = false});

  static const _couleurPresident = Color(0xFF7C3AED); // violet
  static const _couleurAdjoint = Color(0xFF9333EA);   // violet clair
  static const _couleurMembre = Color(0xFFA855F7);    // mauve

  String get _label {
    switch (role) {
      case 'bde_president': return 'Délégué(e) Général(e) BDE';
      case 'bde_adjoint':   return 'Adjoint(e) Délégué(e) Général(e) BDE';
      case 'bde_membre':    return 'Membre BDE';
      default:              return '';
    }
  }

  String get _emoji {
    switch (role) {
      case 'bde_president': return '👑';
      case 'bde_adjoint':   return '⭐';
      case 'bde_membre':    return '🎉';
      default:              return '';
    }
  }

  Color get _couleur {
    switch (role) {
      case 'bde_president': return _couleurPresident;
      case 'bde_adjoint':   return _couleurAdjoint;
      default:              return _couleurMembre;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (role != 'bde_president' && role != 'bde_adjoint' && role != 'bde_membre') {
      return const SizedBox.shrink();
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 9, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: _couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(color: _couleur.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(_emoji, style: TextStyle(fontSize: compact ? 10 : 12)),
        SizedBox(width: compact ? 3 : 4),
        Text(
          compact ? (role == 'bde_president' ? 'Prés. BDE' : role == 'bde_adjoint' ? 'Adj. BDE' : 'BDE') : _label,
          style: TextStyle(fontSize: compact ? 9.5 : 11, fontWeight: FontWeight.w700, color: _couleur),
        ),
      ]),
    );
  }
}

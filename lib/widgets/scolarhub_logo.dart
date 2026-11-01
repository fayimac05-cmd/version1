import 'package:flutter/material.dart';

/// Logo de l'application ScolarHub (distinct du logo de l'établissement).
///
/// Deux fichiers dans assets/images/ :
///  - logo_scolarhub.png         : pour les fonds clairs
///  - logo_scolarhub_sombre.png  : pour les fonds foncés
/// Les deux sont des PNG à fond transparent : le logo s'affiche seul, sans
/// carré ni pastille. Pour le changer, il suffit de remplacer ces fichiers.
class ScolarHubLogo extends StatelessWidget {
  const ScolarHubLogo({
    super.key,
    this.size = 40,
    this.surFondSombre = false,
  });

  final double size;
  final bool surFondSombre;

  static const String assetClair = 'assets/images/logo_scolarhub.png';
  static const String assetSombre = 'assets/images/logo_scolarhub_sombre.png';

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      surFondSombre ? assetSombre : assetClair,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Icon(Icons.school_rounded, size: size * 0.7, color: const Color(0xFFF8C400)),
    );
    return SizedBox(width: size, height: size, child: image);
  }
}

/// Logo « vivant » : il respire doucement (zoom léger qui monte puis revient),
/// en boucle. Utilisé sur les écrans de démarrage.
class ScolarHubLogoVivant extends StatefulWidget {
  const ScolarHubLogoVivant({
    super.key,
    this.size = 150,
    this.surFondSombre = false,
    this.amplitude = 0.08,
  });

  final double size;
  final bool surFondSombre;

  /// Zoom maximal en plus de la taille normale (0.08 = +8 %).
  final double amplitude;

  @override
  State<ScolarHubLogoVivant> createState() => _ScolarHubLogoVivantState();
}

class _ScolarHubLogoVivantState extends State<ScolarHubLogoVivant>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _zoom = Tween<double>(begin: 1.0, end: 1.0 + widget.amplitude)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _zoom,
      child: ScolarHubLogo(size: widget.size, surFondSombre: widget.surFondSombre),
    );
  }
}

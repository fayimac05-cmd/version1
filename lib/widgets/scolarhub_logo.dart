import 'package:flutter/material.dart';

/// Logo de l'application ScolarHub (distinct du logo de l'établissement).
///
/// Deux fichiers dans assets/images/ :
///  - logo_scolarhub.png         : pour les fonds clairs
///  - logo_scolarhub_sombre.png  : pour les fonds foncés (affiché en rond)
/// Pour changer de logo (version à fond transparent), il suffit de remplacer
/// ces deux fichiers : aucun autre changement de code n'est nécessaire.
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
    return SizedBox(
      width: size,
      height: size,
      child: surFondSombre ? ClipOval(child: image) : image,
    );
  }
}

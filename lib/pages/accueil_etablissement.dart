import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import 'choose_school_page.dart' show Etablissement;

/// Page « Bienvenue à … » affichée une fois l'établissement reconnu (par son
/// code, par le matricule ou par l'espace choisi), avant la saisie du mot de
/// passe. Se ferme avec `true` (« Continuer ») ou `false` (« Ce n'est pas mon
/// établissement » / retour).
class AccueilEtablissement extends StatelessWidget {
  final Etablissement etablissement;
  const AccueilEtablissement({super.key, required this.etablissement});

  void _fermer(BuildContext context, bool continuer) => Navigator.of(context).pop(continuer);

  Widget _initiales(Etablissement e) {
    final t = (e.abreviation.isNotEmpty ? e.abreviation : e.nom).trim();
    final ini = t.length <= 4 ? t.toUpperCase() : t.substring(0, 3).toUpperCase();
    return Container(
      color: AppPalette.blue,
      alignment: Alignment.center,
      child: Text(ini,
          style: const TextStyle(
              color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = etablissement;
    if (e.photoAccueilUrl.isNotEmpty) return _avecPhoto(context, e);
    return _sansPhoto(context, e);
  }

  Widget _avecPhoto(BuildContext context, Etablissement e) {
    final h = MediaQuery.of(context).size.height;
    final lieu = [e.ville, e.campus].where((x) => x.trim().isNotEmpty).join(' · ');
    return Scaffold(
      backgroundColor: const Color(0xFF0B1E4D),
      body: Stack(fit: StackFit.expand, children: [
        Image.network(e.photoAccueilUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF0B1E4D))),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  builder: (_, v, child) => Opacity(
                    opacity: v,
                    child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 36,
                              offset: const Offset(0, 14)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          e.photoAccueilUrl,
                          height: (h * 0.58).clamp(240.0, 620.0),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              SizedBox(width: 240, height: 240, child: _initiales(e)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text('Bienvenue à', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 6),
                    Text(e.nom,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.25,
                            letterSpacing: -0.3)),
                    if (lieu.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(lieu,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Colors.white70)),
                    ],
                    const SizedBox(height: 24),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _fermer(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppPalette.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('Continuer',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _fermer(context, false),
                      child: const Text("Ce n'est pas mon établissement",
                          style: TextStyle(color: Colors.white70)),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sansPhoto(BuildContext context, Etablissement e) {
    final lieu = [e.ville, e.campus].where((x) => x.trim().isNotEmpty).join(' · ');
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOut,
                builder: (_, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
                ),
                child: Column(children: [
                  Container(
                    width: 132,
                    height: 132,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: _initiales(e),
                  ),
                  const SizedBox(height: 24),
                  const Text('Bienvenue à',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Text(e.nom,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          height: 1.25,
                          letterSpacing: -0.3)),
                  if (lieu.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(lieu,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _fermer(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Continuer',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _fermer(context, false),
                    child: const Text("Ce n'est pas mon établissement",
                        style: TextStyle(color: Color(0xFF64748B))),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Scène de félicitations : deux diplômés qui lèvent / lancent leur toque.
///
/// Pour utiliser une vraie photo à la place du dessin : ajouter l'image
/// assets/images/diplomes.png (et la déclarer dans pubspec.yaml) ; elle
/// remplace automatiquement le dessin.
class CelebrationDiplomes extends StatefulWidget {
  const CelebrationDiplomes({super.key, this.height = 180});

  final double height;
  static const String assetPhoto = 'assets/images/diplomes.png';

  @override
  State<CelebrationDiplomes> createState() => _CelebrationDiplomesState();
}

class _CelebrationDiplomesState extends State<CelebrationDiplomes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    return SizedBox(
      width: h * 1.7,
      height: h,
      child: Image.asset(
        CelebrationDiplomes.assetPhoto,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(painter: _DiplomesPainter(_c.value)),
        ),
      ),
    );
  }
}

class _DiplomesPainter extends CustomPainter {
  _DiplomesPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / 190;
    final u = s * 0.78;
    final by = size.height - 4 * s;
    _figure(canvas, size.width * 0.32, by, u,
        gown: const Color(0xFF083B87), skin: const Color(0xFF6B3E26), lance: false, phase: 0);
    _figure(canvas, size.width * 0.68, by, u,
        gown: const Color(0xFF1769E0), skin: const Color(0xFF8D5524), lance: true, phase: 1.3);
  }

  void _figure(Canvas canvas, double cx, double by, double u,
      {required Color gown, required Color skin, required bool lance, required double phase}) {
    // ombre au sol
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, by + 2 * u), width: 76 * u, height: 10 * u),
      Paint()..color = const Color(0x22083B87),
    );

    final sway = t > 0.25 ? math.sin((t - 0.25) * math.pi * 10 + phase) * 3 * u : 0.0;
    final armUp = Curves.easeOutBack.transform((t * 2.5).clamp(0.0, 1.0));

    // robe
    final robe = Path()
      ..moveTo(cx - 22 * u, by - 80 * u)
      ..quadraticBezierTo(cx, by - 88 * u, cx + 22 * u, by - 80 * u)
      ..lineTo(cx + 34 * u, by)
      ..lineTo(cx - 34 * u, by)
      ..close();
    canvas.drawPath(robe, Paint()..color = gown);

    // étole dorée
    final etole = Paint()..color = const Color(0xFFF8C400);
    canvas.drawPath(
      Path()
        ..moveTo(cx - 13 * u, by - 84 * u)
        ..lineTo(cx - 5 * u, by - 84 * u)
        ..lineTo(cx - 8 * u, by - 8 * u)
        ..lineTo(cx - 17 * u, by - 8 * u)
        ..close(),
      etole,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + 13 * u, by - 84 * u)
        ..lineTo(cx + 5 * u, by - 84 * u)
        ..lineTo(cx + 8 * u, by - 8 * u)
        ..lineTo(cx + 17 * u, by - 8 * u)
        ..close(),
      etole,
    );

    // bras levés
    final shoulderL = Offset(cx - 20 * u, by - 76 * u);
    final shoulderR = Offset(cx + 20 * u, by - 76 * u);
    final handL = shoulderL + Offset(-20 * u * armUp, -46 * u * armUp + sway);
    final handR = shoulderR + Offset(20 * u * armUp, -46 * u * armUp - sway);
    final bras = Paint()
      ..color = gown
      ..strokeWidth = 11 * u
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(shoulderL, handL, bras);
    canvas.drawLine(shoulderR, handR, bras);
    final peau = Paint()..color = skin;
    canvas.drawCircle(handL, 6.5 * u, peau);
    canvas.drawCircle(handR, 6.5 * u, peau);

    // cou + tête
    canvas.drawRect(Rect.fromLTWH(cx - 5 * u, by - 90 * u, 10 * u, 9 * u), peau);
    final tete = Offset(cx, by - 101 * u);
    canvas.drawCircle(tete, 15 * u, peau);
    canvas.drawArc(Rect.fromCircle(center: tete, radius: 15 * u), math.pi, math.pi, true,
        Paint()..color = const Color(0xFF1B1B1B));
    canvas.drawCircle(Offset(cx - 5.5 * u, by - 100 * u), 1.5 * u, Paint()..color = const Color(0xFF1B1B1B));
    canvas.drawCircle(Offset(cx + 5.5 * u, by - 100 * u), 1.5 * u, Paint()..color = const Color(0xFF1B1B1B));
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, by - 96 * u), width: 11 * u, height: 8 * u),
      0.2,
      math.pi - 0.4,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7 * u
        ..strokeCap = StrokeCap.round,
    );

    // toque
    if (!lance) {
      final angle = t > 0.3 ? math.sin(t * math.pi * 8) * 0.12 : 0.0;
      _toque(canvas, handR + Offset(0, -13 * u), u * 0.9, angle);
    } else {
      final p = ((t - 0.15) / 0.6).clamp(0.0, 1.0);
      final monte = Curves.easeOut.transform(p) * 50 * u;
      final bob = p >= 1 ? math.sin(t * math.pi * 6) * 2 * u : 0.0;
      _toque(canvas, handR + Offset(8 * u * p, -13 * u - monte + bob), u * 0.9, p * 6.0);
    }
  }

  void _toque(Canvas canvas, Offset c, double u, double angle) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, 6 * u), width: 24 * u, height: 12 * u),
        Radius.circular(3 * u),
      ),
      Paint()..color = const Color(0xFF0B1E4D),
    );
    final plateau = Path()
      ..moveTo(-26 * u, 0)
      ..lineTo(0, -10 * u)
      ..lineTo(26 * u, 0)
      ..lineTo(0, 10 * u)
      ..close();
    canvas.drawPath(plateau, Paint()..color = const Color(0xFF123875));
    canvas.drawPath(
      plateau,
      Paint()
        ..color = const Color(0xFF1769E0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * u,
    );
    final gland = Paint()
      ..color = const Color(0xFFF8C400)
      ..strokeWidth = 1.8 * u
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(20 * u, 4 * u), gland);
    canvas.drawLine(Offset(20 * u, 4 * u), Offset(21 * u, 14 * u), gland);
    canvas.drawCircle(Offset(21 * u, 15 * u), 2.6 * u, Paint()..color = const Color(0xFFF8C400));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DiplomesPainter old) => old.t != t;
}

// ═════════════════════════════════════════════════════════════════════════
// Confettis qui jaillissent + ballons qui montent (plein écran, sans clic)
// ═════════════════════════════════════════════════════════════════════════
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _Particule {
  const _Particule(this.angle, this.vitesse, this.taille, this.couleur, this.rotation, this.delai);
  final double angle, vitesse, taille, rotation, delai;
  final Color couleur;
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  static const double _dureeSec = 4.2;
  late final AnimationController _c;
  late final List<_Particule> _particules;

  @override
  void initState() {
    super.initState();
    final r = math.Random(11);
    const couleurs = [
      Color(0xFF1769E0),
      Color(0xFFF8C400),
      Color(0xFFFFFFFF),
      Color(0xFFEF4444),
      Color(0xFF18B879),
      Color(0xFF8257E5),
    ];
    _particules = List.generate(
      90,
      (i) => _Particule(
        -math.pi * (0.15 + 0.7 * r.nextDouble()),
        0.45 + 0.7 * r.nextDouble(),
        6 + 6 * r.nextDouble(),
        couleurs[r.nextInt(couleurs.length)],
        (r.nextDouble() - 0.5) * 14,
        0.2 + 0.25 * r.nextDouble(),
      ),
    );
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: (_dureeSec * 1000).round()))..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_c.value, _particules, _dureeSec),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.particules, this.dureeSec);
  final double t, dureeSec;
  final List<_Particule> particules;

  static const _couleursBallons = [
    Color(0xFFF8C400),
    Color(0xFF1769E0),
    Color(0xFFEF4444),
    Color(0xFF18B879),
    Color(0xFF8257E5),
  ];
  static const _xBallons = [0.10, 0.24, 0.78, 0.90, 0.16];

  @override
  void paint(Canvas canvas, Size size) {
    final secs = t * dureeSec;
    final alpha = 1 - ((t - 0.82) / 0.18).clamp(0.0, 1.0);
    if (alpha <= 0) return;

    // ballons
    for (var i = 0; i < _xBallons.length; i++) {
      final delai = 0.1 + i * 0.12;
      final tt = secs - delai;
      if (tt <= 0) continue;
      final x = size.width * _xBallons[i] + math.sin(secs * 2 + i) * 8;
      final y = size.height + 60 - tt * size.height * (0.26 + 0.03 * (i % 3));
      final c = _couleursBallons[i % _couleursBallons.length].withValues(alpha: alpha);
      canvas.drawLine(
        Offset(x, y + 24),
        Offset(x + math.sin(secs * 2 + i) * 4, y + 72),
        Paint()
          ..color = const Color(0xFF94A3B8).withValues(alpha: alpha)
          ..strokeWidth = 1.2,
      );
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 36, height: 46), Paint()..color = c);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x - 7, y - 10), width: 8, height: 13),
        Paint()..color = Colors.white.withValues(alpha: 0.35 * alpha),
      );
    }

    // confettis
    final origine = Offset(size.width / 2, size.height * 0.58);
    final g = size.height * 1.1;
    for (final p in particules) {
      final tt = secs - p.delai;
      if (tt <= 0) continue;
      final v = p.vitesse * size.height;
      final x = origine.dx + math.cos(p.angle) * v * tt * 0.9;
      final y = origine.dy + math.sin(p.angle) * v * tt + 0.5 * g * tt * tt;
      if (y > size.height + 20) continue;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation * tt);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.taille, height: p.taille * 0.55),
        Paint()..color = p.couleur.withValues(alpha: alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

import 'package:flutter/material.dart';
import 'choose_school_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _sloganCtrl;
  late AnimationController _citationCtrl;
  late AnimationController _btnCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _sloganOpacity;
  late Animation<double> _citationOpacity;
  late Animation<double> _btnOpacity;
  late Animation<Offset> _btnSlide;

  // ── Couleurs adaptées au projet bleu + jaune ──────────────────────────
  static const Color _bg1 = Color(0xFF041A4D); // bleu très foncé
  static const Color _bg2 = Color(0xFF0A4DA2); // bleu principal
  static const Color _bg3 = Color(0xFF0D3A8A); // bleu intermédiaire
  static const Color _yellow = Color(0xFFF8C400); // jaune accent
  static const Color _yellowL = Color(0xFFFFF5CC); // jaune clair
  static const Color _blueMid = Color(0xFF1565C0); // bleu cercles déco

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _sloganCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _sloganOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _sloganCtrl, curve: Curves.easeIn));

    _citationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _citationOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _citationCtrl, curve: Curves.easeIn));

    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _btnOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn));
    _btnSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _sloganCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _citationCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _btnCtrl.forward();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _sloganCtrl.dispose();
    _citationCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  void _goNext() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ChooseSchoolPage(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final mobile = size.width < 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bg1, _bg2, _bg3],
          ),
        ),
        child: Stack(
          children: [
            // ── Cercles décoratifs bleu + jaune ──────────────────────
            Positioned(top: -80, left: -80, child: _circle(260, _blueMid, 0.3)),
            Positioned(
              bottom: -100,
              right: -100,
              child: _circle(320, _blueMid, 0.25),
            ),
            Positioned(
              top: size.height * 0.35,
              right: -50,
              child: _circle(160, _yellow, 0.08),
            ),
            Positioned(
              bottom: size.height * 0.3,
              left: -40,
              child: _circle(130, _yellow, 0.06),
            ),
            Positioned(
              top: size.height * 0.1,
              right: size.width * 0.1,
              child: _circle(50, _yellow, 0.18),
            ),
            Positioned(
              bottom: size.height * 0.18,
              left: size.width * 0.12,
              child: _circle(30, Colors.white, 0.07),
            ),

            // ── Contenu centré ────────────────────────────────────────
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: mobile ? 32 : 48,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),

                          // ① Logo animé
                          AnimatedBuilder(
                            animation: _logoCtrl,
                            builder: (_, __) => Opacity(
                              opacity: _logoOpacity.value,
                              child: Transform.scale(
                                scale: _logoScale.value,
                                child: _buildLogo(mobile),
                              ),
                            ),
                          ),

                          const SizedBox(height: 44),

                          // ② Titre
                          FadeTransition(
                            opacity: _textOpacity,
                            child: SlideTransition(
                              position: _textSlide,
                              child: _buildTitre(mobile),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ③ Slogan
                          FadeTransition(
                            opacity: _sloganOpacity,
                            child: _buildSlogan(mobile),
                          ),

                          const SizedBox(height: 32),

                          // ④ Citation burkinabè
                          FadeTransition(
                            opacity: _citationOpacity,
                            child: _buildCitation(mobile),
                          ),

                          const SizedBox(height: 32),

                          // ⑤ Bouton
                          FadeTransition(
                            opacity: _btnOpacity,
                            child: SlideTransition(
                              position: _btnSlide,
                              child: _buildBouton(),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double s, Color c, double op) => Container(
    width: s,
    height: s,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: c.withValues(alpha: op),
    ),
  );

  Widget _buildLogo(bool mobile) => Stack(
    alignment: Alignment.center,
    children: [
      // Halo jaune derrière
      Container(
        width: mobile ? 130 : 148,
        height: mobile ? 130 : 148,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _yellow.withValues(alpha: 0.18),
        ),
      ),
      // Cercle bleu principal
      Container(
        width: mobile ? 108 : 122,
        height: mobile ? 108 : 122,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _yellow,
          boxShadow: [
            BoxShadow(
              color: _yellow.withValues(alpha: 0.5),
              blurRadius: 40,
              spreadRadius: 6,
            ),
          ],
        ),
        child: Icon(Icons.school_rounded, color: _bg2, size: mobile ? 56 : 64),
      ),
    ],
  );

  Widget _buildTitre(bool mobile) => Text(
    'ScolarHub',
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: mobile ? 44 : 52,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: 1.5,
    ),
  );

  Widget _buildSlogan(bool mobile) => Text(
    'Votre réussite académique, centralisée.',
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: mobile ? 16 : 18,
      color: _yellowL,
      fontStyle: FontStyle.italic,
      height: 1.55,
      letterSpacing: 0.3,
    ),
  );

  Widget _buildCitation(bool mobile) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    decoration: BoxDecoration(
      border: const Border(left: BorderSide(color: _yellow, width: 3)),
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(10),
        bottomRight: Radius.circular(10),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '« Qui apprend quelque chose n\'est jamais perdu. »',
          style: TextStyle(
            fontSize: mobile ? 14 : 16,
            color: Colors.white.withValues(alpha: 0.85),
            fontStyle: FontStyle.italic,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '— Proverbe burkinabè',
          style: TextStyle(
            fontSize: mobile ? 12 : 14,
            color: _yellow,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );

  Widget _buildBouton() => SizedBox(
    width: double.infinity,
    height: 58,
    child: ElevatedButton(
      onPressed: _goNext,
      style: ElevatedButton.styleFrom(
        backgroundColor: _yellow,
        foregroundColor: _bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        shadowColor: _yellow.withValues(alpha: 0.4),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Commencer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(width: 12),
          Icon(Icons.arrow_forward_rounded, size: 24),
        ],
      ),
    ),
  );
}

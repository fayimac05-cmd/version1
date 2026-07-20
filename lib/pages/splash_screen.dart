import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import 'auth_choice_page.dart';
import 'choose_school_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ───────────────────────────────────────────────────────────
  late AnimationController _bgCtrl;       // background circles
  late AnimationController _logoCtrl;     // logo pop-in
  late AnimationController _textCtrl;     // title + subtitle slide
  late AnimationController _cardsCtrl;    // feature cards stagger
  late AnimationController _btnCtrl;      // buttons fade-up
  late AnimationController _pulseCtrl;    // logo ring pulse (loop)

  // ── Animations ────────────────────────────────────────────────────────────
  late Animation<double> _bgScale;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _ringPulse;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _btnOpacity;
  late Animation<Offset> _btnSlide;

  // Feature card animations (staggered)
  final List<Animation<double>> _cardOpacities = [];
  final List<Animation<Offset>> _cardSlides = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // Background
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _bgScale = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOutExpo);

    // Logo
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl,
            curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));

    // Pulse ring (loops)
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _ringPulse = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Title
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _titleSlide = Tween<Offset>(
            begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));
    _subtitleSlide = Tween<Offset>(
            begin: const Offset(0, 0.8), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _textCtrl,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut)));
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _textCtrl,
            curve: const Interval(0.2, 1.0, curve: Curves.easeIn)));

    // Feature card (1 citation)
    _cardsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    for (int i = 0; i < 1; i++) {
      final start = i * 0.2;
      final end = (start + 0.6).clamp(0.0, 1.0);
      _cardOpacities.add(Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
              parent: _cardsCtrl,
              curve: Interval(start, end, curve: Curves.easeOut))));
      _cardSlides.add(Tween<Offset>(
              begin: const Offset(0, 0.5), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _cardsCtrl,
              curve: Interval(start, end, curve: Curves.easeOut))));
    }

    // Buttons
    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _btnOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn));
    _btnSlide = Tween<Offset>(
            begin: const Offset(0, 1.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut));
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _bgCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _cardsCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    _btnCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _cardsCtrl.dispose();
    _btnCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _goAuthChoice() {
    Navigator.of(context).push(_slideRoute(const AuthChoicePage()));
  }

  void _goChooseSchool() {
    Navigator.of(context).push(_slideRoute(const ChooseSchoolPage()));
  }

  Route _slideRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeInOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      );

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.white,
      body: Stack(
        children: [
          // ── Animated background circles ──────────────────────────────────
          ScaleTransition(
            scale: _bgScale,
            alignment: Alignment.topLeft,
            child: Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.blue,
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -80,
            child: ScaleTransition(
              scale: _bgScale,
              alignment: Alignment.topLeft,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.blue,
                ),
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -50,
            child: ScaleTransition(
              scale: _bgScale,
              alignment: Alignment.topRight,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.midBlue.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          // Yellow dot top-right
          Positioned(
            top: 90,
            right: 80,
            child: FadeTransition(
              opacity: _bgScale,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppPalette.yellow),
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 44),

                  // Logo badge
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _ringPulse,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppPalette.yellow,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppPalette.yellow.withValues(alpha: 0.4),
                                blurRadius: 16,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: AppPalette.blue, size: 30),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Title
                  SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _titleOpacity,
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scholar',
                              style: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  color: AppPalette.black,
                                  height: 1.1)),
                          Text('Hub',
                              style: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  color: AppPalette.yellow,
                                  height: 1.1)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  SlideTransition(
                    position: _subtitleSlide,
                    child: FadeTransition(
                      opacity: _subtitleOpacity,
                      child: Text(
                        'Votre plateforme tout-en-un\npour la gestion académique',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            height: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Citation
                  ..._buildFeatureCards(),

                  const SizedBox(height: 24),

                  // Buttons
                  SlideTransition(
                    position: _btnSlide,
                    child: FadeTransition(
                      opacity: _btnOpacity,
                      child: Column(
                        children: [
                          _buildPrimaryBtn(),
                          const SizedBox(height: 12),
                          _buildSchoolBtn(),
                          const SizedBox(height: 12),
                          const Text('Version 1.0.0',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppPalette.grey)),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _citation = (
    '"La jeunesse d\'un pays est sa richesse la plus précieuse. Investir dans son éducation, c\'est construire l\'avenir de la nation tout entière."',
    'Thomas Sankara',
    'Président du Burkina Faso',
  );

  List<Widget> _buildFeatureCards() {
    final (citation, auteur, titre) = _citation;
    return [
      SlideTransition(
        position: _cardSlides[0],
        child: FadeTransition(
          opacity: _cardOpacities[0],
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A3D91), Color(0xFF1565C0)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF0A3D91).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: Stack(children: [
              // Bulle déco haut-droite
              Positioned(top: -18, right: -18,
                child: Container(width: 80, height: 80,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07)))),
              // Bulle jaune bas-gauche
              Positioned(bottom: -10, left: 30,
                child: Container(width: 50, height: 50,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: AppPalette.yellow.withValues(alpha: 0.15)))),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grand guillemet
                  const Text('"',
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: AppPalette.yellow,
                        height: 0.8,
                        letterSpacing: -2)),
                  const SizedBox(height: 4),
                  Text(citation,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        height: 1.45,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  // Séparateur jaune
                  Container(width: 36, height: 2,
                    decoration: BoxDecoration(
                        color: AppPalette.yellow,
                        borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 10),
                  Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(auteur,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppPalette.yellow)),
                      Text(titre,
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.65))),
                    ]),
                  ]),
                ],
              ),
            ]),
          ),
        ),
      ),
    ];
  }

  Widget _buildPrimaryBtn() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _goAuthChoice,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Commencer',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolBtn() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: _goChooseSchool,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.blue,
          side: const BorderSide(color: AppPalette.blue, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_rounded, size: 20),
            SizedBox(width: 10),
            Text('Sélectionner mon école',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

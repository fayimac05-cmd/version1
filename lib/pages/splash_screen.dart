import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import 'choose_school_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ============================================================
  // DONNÉES PARTAGÉES
  // ============================================================
  // Extrait ici (au lieu d'être recopié dans _buildFeatureRow ET
  // _buildMobileFeatures) pour éviter toute désynchronisation entre
  // les versions desktop et mobile si une icône/couleur change un jour.
  static const List<(IconData, String, Color)> _features = [
    (Icons.menu_book_rounded, 'Cours', Color(0xFF1769E0)),
    (Icons.bar_chart_rounded, 'Résultats', Color(0xFF18B879)),
    (Icons.person_rounded, 'Présence', Color(0xFF8257E5)),
    (Icons.calendar_month_rounded, 'Planning', Color(0xFFFFA800)),
    (Icons.description_rounded, 'Notes', Color(0xFF3E8AF5)),
  ];

  // ============================================================
  // ANIMATIONS
  // ============================================================

  late AnimationController _pageController;
  late AnimationController _imageController;
  late AnimationController _contentController;
  late AnimationController _buttonController;

  late Animation<double> _pageFade;
  late Animation<double> _imageScale;
  late Animation<Offset> _imageSlide;

  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  late Animation<double> _buttonFade;
  late Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _imageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _pageFade = CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeOut,
    );

    _imageScale = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _imageController,
        curve: Curves.easeOutBack,
      ),
    );

    _imageSlide = Tween<Offset>(
      begin: const Offset(0.12, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _imageController,
        curve: Curves.easeOutCubic,
      ),
    );

    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(-0.08, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeOutCubic,
      ),
    );

    _buttonFade = CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOut,
    );

    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeOutCubic,
      ),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    _pageController.forward();

    await Future.delayed(
      const Duration(milliseconds: 180),
    );

    if (!mounted) return;
    _contentController.forward();

    await Future.delayed(
      const Duration(milliseconds: 250),
    );

    if (!mounted) return;
    _imageController.forward();

    await Future.delayed(
      const Duration(milliseconds: 350),
    );

    if (!mounted) return;
    _buttonController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _imageController.dispose();
    _contentController.dispose();
    _buttonController.dispose();

    super.dispose();
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _goChooseSchool() {
    Navigator.of(context).push(
      _slideRoute(
        const ChooseSchoolPage(),
      ),
    );
  }

  Route _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
        );

        return SlideTransition(
          position: slide,
          child: child,
        );
      },
      transitionDuration: const Duration(
        milliseconds: 450,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
      body: FadeTransition(
        opacity: _pageFade,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            // --------------------------------------------------
            // MOBILE
            // --------------------------------------------------
            // Seuil relevé de 700 à 900 : une tablette portrait
            // (768-834px, très courante) tombait auparavant dans la
            // branche "desktop" à deux colonnes serrées, avec un
            // titre à 40-44px risquant l'overflow horizontal. Elle
            // profite maintenant du layout mobile, scrollable et à
            // une colonne, mieux adapté à ces largeurs.

            if (width < 900) {
              return _buildMobileLayout(
                width,
                height,
              );
            }

            // --------------------------------------------------
            // TABLET / DESKTOP
            // --------------------------------------------------

            return _buildDesktopLayout(
              width,
              height,
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // DESKTOP / TABLET
  // ============================================================

  Widget _buildDesktopLayout(
    double width,
    double height,
  ) {
    final isTablet = width < 1050;

    final horizontalPadding = isTablet ? 42.0 : 7.0;

    return Stack(
      children: [
        // ======================================================
        // BACKGROUND DECORATIONS
        // ======================================================

        Positioned(
          top: -220,
          left: -150,
          child: Container(
            width: isTablet ? 420 : 560,
            height: isTablet ? 420 : 560,
            decoration: const BoxDecoration(
              color: Color(0xFFE7EEF9),
              shape: BoxShape.circle,
            ),
          ),
        ),

        Positioned(
          right: -180,
          top: -180,
          child: Container(
            width: 520,
            height: 520,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF2FF),
              shape: BoxShape.circle,
            ),
          ),
        ),

        Positioned(
          right: -120,
          bottom: -260,
          child: Container(
            width: 500,
            height: 500,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FC),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // ======================================================
        // ======================================================
        // CONTENU PRINCIPAL
        // ======================================================

        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 32,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ==================================================
                // PARTIE GAUCHE
                // ==================================================

                Expanded(
                  flex: isTablet ? 5 : 6,
                  child: _buildLeftContent(
                    isTablet: isTablet,
                  ),
                ),

                // ==================================================
                // PARTIE DROITE
                // ==================================================

                Expanded(
                  flex: isTablet ? 5 : 6,
                  child: _buildStudentSection(
                    isTablet: isTablet,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LEFT CONTENT
  // ============================================================

  Widget _buildLeftContent({
    required bool isTablet,
  }) {
    return SlideTransition(
      position: _contentSlide,
      child: FadeTransition(
        opacity: _contentFade,
        child: Padding(
          padding: EdgeInsets.only(
            left: isTablet ? 20 : 90,
            right: isTablet ? 15 : 35,
            top: 20,
            bottom: 20,
          ),
          // ✅ CORRIGÉ — ce Column n'était pas scrollable : sur un
          // écran desktop bas en hauteur (petite fenêtre, tablette
          // en 900-1050px de large), le contenu (logo + titre +
          // description + features + citation + bouton + version)
          // pouvait dépasser la hauteur disponible et provoquer un
          // "RenderFlex overflowed". Le Spacer() a aussi été
          // remplacé par un espacement fixe, incompatible avec un
          // parent scrollable (hauteur non bornée).
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // LOGO
                // ==================================================

                _buildLogo(),

                const SizedBox(
                  height: 58,
                ),

                // ==================================================
                // GRAND TITRE
                // ==================================================

                _buildMainTitle(
                  isTablet: isTablet,
                ),

                const SizedBox(
                  height: 12,
                ),

                // ==================================================
                // TRAIT JAUNE
                // ==================================================

                Container(
                  width: 105,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppPalette.yellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                // ==================================================
                // DESCRIPTION
                // ==================================================

                Text(
                  'Cours, résultats, présence, planning et bien plus,\n'
                  'réunis au même endroit.',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 20,
                    height: 1.55,
                    color: const Color(0xFF7890B2),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                // ==================================================
                // SERVICES
                // ==================================================

                _buildFeatureRow(
                  isTablet: isTablet,
                ),

                const SizedBox(
                  height: 28,
                ),

                // ==================================================
                // CITATION
                // ==================================================

                _buildCitationCard(
                  isTablet: isTablet,
                ),

                const SizedBox(
                  height: 40,
                ),

                // ==================================================
                // BOUTON
                // ==================================================

                _buildStartButton(
                  isTablet: isTablet,
                ),

                const SizedBox(
                  height: 18,
                ),

                // ==================================================
                // VERSION
                // ==================================================

                SizedBox(
                  width: isTablet ? 390 : 450,
                  child: const Text(
                    'Version 1.0.0',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7185A5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGO
  // ============================================================

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppPalette.blue,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppPalette.blue.withValues(
                  alpha: 0.20,
                ),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            color: AppPalette.yellow,
            size: 39,
          ),
        ),

        const SizedBox(
          width: 22,
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Scholar',
                    style: TextStyle(
                      fontSize: 31,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF083B87),
                    ),
                  ),
                  TextSpan(
                    text: 'Hub',
                    style: TextStyle(
                      fontSize: 31,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1769E0),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 3,
            ),

            const Text(
              'La plateforme académique tout-en-un',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF7185A5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // MAIN TITLE
  // ============================================================

  Widget _buildMainTitle({
    required bool isTablet,
  }) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Ton parcours académique,\n',
            style: TextStyle(
              fontSize: isTablet ? 40 : 52,
              height: 1.08,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF123875),
              letterSpacing: -1.2,
            ),
          ),
          TextSpan(
            text: 'commence ici.',
            style: TextStyle(
              fontSize: isTablet ? 44 : 58,
              height: 1.08,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1769E0),
              letterSpacing: -1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FEATURE ROW
  // ============================================================

  Widget _buildFeatureRow({
    required bool isTablet,
  }) {
    return Wrap(
      spacing: isTablet ? 16 : 26,
      runSpacing: 15,
      children: _features.map((feature) {
        return _buildFeatureItem(
          icon: feature.$1,
          label: feature.$2,
          color: feature.$3,
          isTablet: isTablet,
        );
      }).toList(),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isTablet,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isTablet ? 58 : 66,
          height: isTablet ? 58 : 66,
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: 0.08,
            ),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: color.withValues(
                alpha: 0.10,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: isTablet ? 28 : 32,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0B3C88),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CITATION CARD
  // ============================================================

  Widget _buildCitationCard({
    required bool isTablet,
  }) {
    return Container(
      width: isTablet ? double.infinity : 560,
      padding: EdgeInsets.all(
        isTablet ? 20 : 26,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFDCEAFF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // CITATION COURTE
          // ------------------------------------------------------

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '“',
                style: TextStyle(
                  fontSize: 48,
                  height: 0.8,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1769E0),
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  'La jeunesse d’un pays est sa richesse la plus précieuse.',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 19,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF073D91),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          // ------------------------------------------------------
          // AUTEUR
          // ------------------------------------------------------

          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFD7E8FF),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF0A4DA2),
                  size: 23,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Thomas Sankara',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0751AF),
                    ),
                  ),
                  SizedBox(
                    height: 3,
                  ),
                  Text(
                    'Président du Burkina Faso',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7185A5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // START BUTTON
  // ============================================================

  Widget _buildStartButton({
    required bool isTablet,
  }) {
    return SlideTransition(
      position: _buttonSlide,
      child: FadeTransition(
        opacity: _buttonFade,
        child: SizedBox(
          width: isTablet ? 390 : 450,
          height: 70,
          child: ElevatedButton(
            onPressed: _goChooseSchool,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D55B0),
              foregroundColor: Colors.white,
              elevation: 10,
              shadowColor: const Color(0xFF0D55B0).withValues(
                alpha: 0.28,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Commencer',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(
                  width: 20,
                ),

                Icon(
                  Icons.arrow_forward_rounded,
                  size: 27,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STUDENT SECTION
  // ============================================================

  Widget _buildStudentSection({
    required bool isTablet,
  }) {
    return SlideTransition(
      position: _imageSlide,
      child: ScaleTransition(
        scale: _imageScale,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ==================================================
            // GRAND CERCLE BLEU CLAIR
            // ==================================================

            Positioned(
              right: isTablet ? 0 : 30,
              top: isTablet ? 150 : 120,
              child: Container(
                width: isTablet ? 390 : 570,
                height: isTablet ? 390 : 570,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFDDEAFB),
                ),
              ),
            ),

            // ==================================================
            // CERCLE BLANC
            // ==================================================

            Positioned(
              right: isTablet ? 35 : 75,
              top: isTablet ? 185 : 160,
              child: Container(
                width: isTablet ? 340 : 500,
                height: isTablet ? 340 : 500,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFDFEFF),
                ),
              ),
            ),

            // ==================================================
            // IMAGE ETUDIANT
            // ==================================================

            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: ClipPath(
                  clipper: StudentImageClipper(),
                  child: SizedBox(
                    width: isTablet ? 430 : 650,
                    height: isTablet ? 530 : 680,
                    child: Image.asset(
                      'assets/images/etudiant_ist.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F1FC),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              size: 60,
                              color: Color(0xFF1769E0),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // ==================================================
            // PETITS POINTS
            // ==================================================

            Positioned(
              top: isTablet ? 175 : 125,
              right: isTablet ? 100 : 150,
              child: _buildYellowDot(
                size: 17,
              ),
            ),

            Positioned(
              top: isTablet ? 215 : 165,
              right: isTablet ? 125 : 180,
              child: _buildBlueDot(
                size: 10,
              ),
            ),

            // ==================================================
            // ==================================================
            // MESSAGE ECRIT EN HAUT
            // (seul message conservé côté desktop — la pastille jaune
            // répétait la même phrase juste en dessous, cf. maquette
            // qui n'affiche le message qu'une seule fois ici)
            // ==================================================

            Positioned(
              top: isTablet ? 80 : 55,
              right: isTablet ? 30 : 80,
              child: Transform.rotate(
                angle: -0.08,
                child: Text(
                  'Étudier aujourd’hui,\nréussir demain !',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 25,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF1769E0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STUDENT MESSAGE
  // ============================================================

  Widget _buildStudentMessage({
    required bool isTablet,
  }) {
    return Container(
      width: isTablet ? 210 : 270,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 20,
        vertical: isTablet ? 13 : 16,
      ),
      decoration: BoxDecoration(
        color: AppPalette.yellow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppPalette.yellow.withValues(
              alpha: 0.35,
            ),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 42 : 48,
            height: isTablet ? 42 : 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1769E0).withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF0751AF),
              size: 27,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Text(
              'Étudier aujourd’hui,\nréussir demain !',
              style: TextStyle(
                fontSize: isTablet ? 11 : 13,
                height: 1.25,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF064092),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE LAYOUT
  // ============================================================

  Widget _buildMobileLayout(
    double width,
    double height,
  ) {
    return Stack(
      children: [
        // ------------------------------------------------------
        // BACKGROUND
        // ------------------------------------------------------

        Positioned(
          top: -160,
          left: -120,
          child: Container(
            width: 330,
            height: 330,
            decoration: const BoxDecoration(
              color: Color(0xFFE7EEF9),
              shape: BoxShape.circle,
            ),
          ),
        ),

        Positioned(
          right: -130,
          bottom: -150,
          child: Container(
            width: 330,
            height: 330,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FC),
              shape: BoxShape.circle,
            ),
          ),
        ),

        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              24,
              25,
              24,
              30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------
                // LOGO
                // ------------------------------------------------

                _buildMobileLogo(),

                const SizedBox(
                  height: 38,
                ),

                // ------------------------------------------------
                // TITRE
                // ------------------------------------------------

                SlideTransition(
                  position: _contentSlide,
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: _buildMainTitle(
                      isTablet: true,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                Container(
                  width: 85,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppPalette.yellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                const Text(
                  'Cours, résultats, présence,\n'
                  'planning et bien plus,\n'
                  'réunis au même endroit.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Color(0xFF7185A5),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                // ------------------------------------------------
                // IMAGE
                // ------------------------------------------------

                SizedBox(
                  height: 340,
                  child: _buildMobileStudentImage(),
                ),

                const SizedBox(
                  height: 10,
                ),

                // ------------------------------------------------
                // SERVICES
                // ------------------------------------------------

                _buildMobileFeatures(),

                const SizedBox(
                  height: 25,
                ),

                // ------------------------------------------------
                // CITATION
                // ------------------------------------------------

                _buildCitationCard(
                  isTablet: true,
                ),

                const SizedBox(
                  height: 25,
                ),

                // ------------------------------------------------
                // BOUTON
                // ------------------------------------------------

                _buildMobileButton(),

                const SizedBox(
                  height: 14,
                ),

                const Center(
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7185A5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE LOGO
  // ============================================================

  Widget _buildMobileLogo() {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppPalette.blue,
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: AppPalette.blue.withValues(
                  alpha: 0.20,
                ),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            color: AppPalette.yellow,
            size: 31,
          ),
        ),

        const SizedBox(
          width: 14,
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Scholar',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF083B87),
                    ),
                  ),
                  TextSpan(
                    text: 'Hub',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1769E0),
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'Ton parcours, notre priorité',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF7185A5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE IMAGE
  // ============================================================

  Widget _buildMobileStudentImage() {
    return SlideTransition(
      position: _imageSlide,
      child: ScaleTransition(
        scale: _imageScale,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                color: Color(0xFFDDEAFB),
                shape: BoxShape.circle,
              ),
            ),

            Container(
              width: 265,
              height: 265,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),

            ClipPath(
              clipper: StudentImageClipper(),
              child: SizedBox(
                width: 320,
                height: 330,
                child: Image.asset(
                  'assets/images/etudiant_ist.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return const Center(
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        size: 50,
                        color: Color(0xFF1769E0),
                      ),
                    );
                  },
                ),
              ),
            ),

            Positioned(
              right: 5,
              bottom: 30,
              child: Transform.rotate(
                angle: -0.07,
                child: _buildStudentMessage(
                  isTablet: true,
                ),
              ),
            ),

            Positioned(
              top: 15,
              right: 25,
              child: _buildYellowDot(
                size: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE FEATURES
  // ============================================================

  Widget _buildMobileFeatures() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _features.map((feature) {
          return Padding(
            padding: const EdgeInsets.only(
              right: 18,
            ),
            child: _buildFeatureItem(
              icon: feature.$1,
              label: feature.$2,
              color: feature.$3,
              isTablet: true,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // MOBILE BUTTON
  // ============================================================

  Widget _buildMobileButton() {
    return SlideTransition(
      position: _buttonSlide,
      child: FadeTransition(
        opacity: _buttonFade,
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _goChooseSchool,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D55B0),
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: const Color(0xFF0D55B0).withValues(
                alpha: 0.25,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Commencer',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(
                  width: 14,
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DECORATIONS
  // ============================================================

  Widget _buildYellowDot({
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppPalette.yellow,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildBlueDot({
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF4B8FEF),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ================================================================
// CLIPPER POUR DONNER UNE FORME ORGANIQUE À L'IMAGE
// ================================================================

class StudentImageClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(
      size.width * 0.30,
      size.height * 0.08,
    );

    path.cubicTo(
      size.width * 0.52,
      size.height * 0.00,
      size.width * 0.82,
      size.height * 0.06,
      size.width * 0.91,
      size.height * 0.28,
    );

    path.cubicTo(
      size.width * 1.00,
      size.height * 0.50,
      size.width * 0.88,
      size.height * 0.82,
      size.width * 0.67,
      size.height * 0.94,
    );

    path.cubicTo(
      size.width * 0.46,
      size.height * 1.02,
      size.width * 0.18,
      size.height * 0.88,
      size.width * 0.13,
      size.height * 0.65,
    );

    path.cubicTo(
      size.width * 0.07,
      size.height * 0.42,
      size.width * 0.12,
      size.height * 0.16,
      size.width * 0.30,
      size.height * 0.08,
    );

    path.close();

    return path;
  }

  @override
  bool shouldReclip(
    covariant CustomClipper<Path> oldClipper,
  ) {
    return false;
  }
}
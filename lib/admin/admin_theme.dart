// ============================================================
// admin_theme.dart — ScolarHub Admin Theme (v2 — production)
// ============================================================
// Corrections :
//   [SEC-1]  withOpacity → withValues (Flutter 3.27+)
//   [SEC-2]  sectionLabel() découplé de sidebarText
//   [ARCH-1] ColorScheme complet → Theme.of(context) fonctionne
//   [ARCH-2] Dark mode via buildTheme(brightness)
//
// Améliorations (suggestions Gemini validées) :
//   [UX-1]  Durées d'animation standardisées
//   [UX-2]  cardDecoration + helpers complets
//   [UX-3]  Échelle de gris neutres (Slate) ajoutée
//   [UX-4]  ThemeData Flutter natif complet
//   [UX-5]  Structure police Google Fonts prête (Inter)
// ============================================================

import 'package:flutter/material.dart';
// TODO: décommenter après `flutter pub add google_fonts`
// import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════
// SECTION 1 — Palette de couleurs
// ═══════════════════════════════════════════════════════════════

class AdminColors {
  AdminColors._();

  // ── Bleu principal (brand — identique à AppPalette) ──────────────────
  static const green900 = Color(0xFF041A4D); // darkBlue
  static const green800 = Color(0xFF0A4DA2); // blue — primary — sidebar, accents
  static const green700 = Color(0xFF0D3E85); // hover sidebar
  static const green600 = Color(0xFF1565C0); // midBlue — boutons
  static const green400 = Color(0xFF4D8FD6); // icônes actives
  static const green200 = Color(0xFFADD1F5); // textes sidebar
  static const green100 = Color(0xFFEAF2FF); // lightBlue — fond chips
  static const green50  = Color(0xFFE8F0FE); // bgBlue — fond cards légères

  // ── Or / Jaune (accent — identique à AppPalette) ─────────────────────
  static const amber700 = Color(0xFFB89200);
  static const amber600 = Color(0xFFF8C400); // yellow — accent principal
  static const amber100 = Color(0xFFFFF5CC); // softYellow
  static const amber50  = Color(0xFFFFFBE6); // accentLight

  // ── Statuts ───────────────────────────────────────────────────────────
  static const red600   = Color(0xFFDC2626);
  static const red50    = Color(0xFFFFEBEB);
  static const blue600  = Color(0xFF1565C0);
  static const blue50   = Color(0xFFEAF2FF);

  // ── [UX-3] Échelle de gris neutres (Slate) ───────────────────────────
  // S'accordent parfaitement avec le vert foncé du brand.
  static const slate950 = Color(0xFF020617);
  static const slate900 = Color(0xFF0F172A);
  static const slate800 = Color(0xFF1E293B);
  static const slate700 = Color(0xFF334155);
  static const slate600 = Color(0xFF475569);
  static const slate500 = Color(0xFF64748B);
  static const slate400 = Color(0xFF94A3B8);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate50  = Color(0xFFF8FAFC);

  // ── Surfaces ──────────────────────────────────────────────────────────
  static const white     = Color(0xFFFFFFFF);
  static const darkSurf  = Color(0xFF1E293B); // surface dark mode
  static const darkSurf2 = Color(0xFF0F172A); // fond dark mode
}

// ═══════════════════════════════════════════════════════════════
// SECTION 2 — AdminTheme principal
// ═══════════════════════════════════════════════════════════════

class AdminTheme {

  // ── Alias sémantiques (rétrocompatibles) ──────────────────────────────
  static const Color primary      = AdminColors.green800;
  static const Color primaryMid   = AdminColors.green600;
  static const Color primaryLight = AdminColors.green100;
  static const Color accent       = AdminColors.amber600;
  static const Color accentLight  = AdminColors.amber50;
  static const Color background   = AdminColors.slate50;
  static const Color surface      = AdminColors.white;
  static const Color surfaceAlt   = AdminColors.slate100;
  static const Color border       = AdminColors.slate200;

  // ── Textes ────────────────────────────────────────────────────────────
  static const Color textPrimary   = AdminColors.slate900;
  static const Color textSecondary = AdminColors.slate500;
  static const Color textMuted     = AdminColors.slate400;

  // ── Statuts ───────────────────────────────────────────────────────────
  static const Color success      = AdminColors.green600;
  static const Color successLight = AdminColors.green100;
  static const Color warning      = AdminColors.amber600;
  static const Color warningLight = AdminColors.amber50;
  static const Color danger       = AdminColors.red600;
  static const Color dangerLight  = AdminColors.red50;
  static const Color info         = AdminColors.blue600;
  static const Color infoLight    = AdminColors.blue50;

  // ── Sidebar ───────────────────────────────────────────────────────────
  static const Color sidebarBg     = AdminColors.green800;
  static const Color sidebarText   = AdminColors.green200;
  static const Color sidebarActive = AdminColors.green600;
  static const Color sidebarHover  = AdminColors.green700;
  static const Color sidebarIcon   = AdminColors.green400;

  // ── Dimensions ────────────────────────────────────────────────────────
  static const double radiusCard   = 12.0;
  static const double radiusButton = 8.0;
  static const double radiusSmall  = 6.0;
  static const double radiusPill   = 20.0;

  static const double sidebarWidth        = 270.0;
  static const double sidebarWidthCompact = 72.0;
  static const double topbarHeight        = 70.0;

  // ── Breakpoints ───────────────────────────────────────────────────────
  static const double breakpointMobile  = 600.0;
  static const double breakpointTablet  = 900.0;
  static const double breakpointDesktop = 1200.0;

  static bool isMobile(BuildContext ctx)  =>
      MediaQuery.of(ctx).size.width < breakpointMobile;
  static bool isTablet(BuildContext ctx)  =>
      MediaQuery.of(ctx).size.width < breakpointTablet;
  static bool isDesktop(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= breakpointTablet;

  // ── [UX-1] Durées d'animation standardisées ───────────────────────────
  static const Duration durationInstant = Duration(milliseconds: 80);
  static const Duration durationFast    = Duration(milliseconds: 150);
  static const Duration durationNormal  = Duration(milliseconds: 250);
  static const Duration durationSlow    = Duration(milliseconds: 400);

  static const Curve curveDefault  = Curves.easeOut;
  static const Curve curveSpring   = Curves.easeInOutCubic;
  static const Curve curveBounce   = Curves.elasticOut;

  // ── [SEC-1] Ombres (withValues remplace withOpacity) ──────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  // ── [UX-2] Décorations de cartes prêtes à l'emploi ────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusCard),
    border: Border.all(color: border),
    boxShadow: cardShadow,
  );

  static BoxDecoration get cardDecorationElevated => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusCard),
    border: Border.all(color: border),
    boxShadow: elevatedShadow,
  );

  static BoxDecoration get cardDecorationFlat => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusCard),
    border: Border.all(color: border),
  );

  /// Carte avec fond coloré (pour les KPIs, alertes, etc.)
  static BoxDecoration chipDecoration(Color fg, Color bg) => BoxDecoration(
    color: bg,
    borderRadius: BorderRadius.circular(radiusPill),
    border: Border.all(color: fg.withValues(alpha: 0.20)),
  );

  // ── [UX-5] TextStyles ─────────────────────────────────────────────────
  // Structure prête pour Google Fonts Inter.
  // Remplacer `_baseStyle()` par `GoogleFonts.inter()` quand la police est ajoutée.

  static TextStyle _base({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = textPrimary,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        // TODO: remplacer par GoogleFonts.inter(...) après `flutter pub add google_fonts`
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle get headingLarge => _base(
      size: 24, weight: FontWeight.w700, letterSpacing: -0.5);

  static TextStyle get headingMedium => _base(
      size: 18, weight: FontWeight.w700, letterSpacing: -0.3);

  static TextStyle get headingSmall => _base(
      size: 15, weight: FontWeight.w600);

  static TextStyle get bodyLarge => _base(
      size: 15, height: 1.6);

  static TextStyle get bodyMedium => _base(
      size: 13, color: textSecondary, height: 1.5);

  static TextStyle get labelBold => _base(
      size: 12, weight: FontWeight.w700,
      color: textSecondary, letterSpacing: 0.5);

  static TextStyle get caption => _base(
      size: 11, weight: FontWeight.w500, color: textMuted);

  static TextStyle get sidebarLabel => _base(
      size: 10, weight: FontWeight.w800,
      color: AdminColors.green200, letterSpacing: 1.0);

  // Alias vers AppPalette pour cohérence
  static const Color appBlue     = AdminColors.green800;
  static const Color appDarkBlue = AdminColors.green900;
  static const Color appYellow   = AdminColors.amber600;

  // ── Styles d'icônes standardisés ─────────────────────────────────────
  /// Fond bleu mid (#1565C0) + icône blanche — usage général
  static const Color iconBg    = AdminColors.green600;  // #1565C0
  static const Color iconFg    = AdminColors.white;

  /// Fond bleu (#0A4DA2) + icône jaune (#F8C400) — boutons d'action principaux
  static const Color iconBgAlt = AdminColors.green800;  // #0A4DA2
  static const Color iconFgAlt = AdminColors.amber600;  // #F8C400

  // ── Widget helpers ────────────────────────────────────────────────────

  /// Badge pill coloré. [SEC-2] plus de hardcode sidebarText.
  static Widget badge(
    String label,
    Color fg,
    Color bg, {
    double fontSize = 11,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  }) =>
      Container(
        padding: padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: fg)),
      );

  /// Label de section — [SEC-2] couleur paramétrable, plus hardcodée.
  static Widget sectionLabel(String label, {Color color = textMuted}) =>
      Padding(
        padding: const EdgeInsets.only(left: 12, bottom: 5, top: 16),
        child: Row(children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 1.0)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 1, color: color.withValues(alpha: 0.15)),
          ),
        ]),
      );

  /// Bouton primaire standard.
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AdminColors.green800,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusButton)),
    textStyle:
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
  );

  /// Bouton secondaire (outline).
  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: AdminColors.green800,
    side: const BorderSide(color: AdminColors.green800, width: 1.5),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusButton)),
    textStyle:
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
  );

  /// Bouton danger (déconnexion, suppression).
  static ButtonStyle get dangerButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: danger,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusButton)),
    textStyle:
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
  );

  // ═══════════════════════════════════════════════════════════════════════
  // [ARCH-1] [ARCH-2] [UX-4] — ThemeData Flutter natif complet
  // Usage dans main.dart :
  //   MaterialApp(
  //     theme:      AdminTheme.buildTheme(Brightness.light),
  //     darkTheme:  AdminTheme.buildTheme(Brightness.dark),
  //     themeMode:  themeNotifier.mode,   // depuis admin_shell.dart
  //   )
  // ═══════════════════════════════════════════════════════════════════════

  static ThemeData buildTheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;

    // ── Couleurs adaptées au mode ────────────────────────────────────────
    final bg        = dark ? AdminColors.darkSurf2 : AdminColors.slate50;
    final surf      = dark ? AdminColors.darkSurf  : AdminColors.white;
    final onSurf    = dark ? AdminColors.slate100  : AdminColors.slate900;
    final onSurfSub = dark ? AdminColors.slate400  : AdminColors.slate500;
    final bord      = dark ? AdminColors.slate700  : AdminColors.slate200;

    final colorScheme = ColorScheme(
      brightness:       brightness,
      primary:          AdminColors.green800,   // blue 0xFF0A4DA2
      onPrimary:        AdminColors.white,
      primaryContainer: AdminColors.green100,   // lightBlue
      onPrimaryContainer: AdminColors.green900, // darkBlue
      secondary:        AdminColors.amber600,   // yellow 0xFFF8C400
      onSecondary:      AdminColors.slate900,
      secondaryContainer: AdminColors.amber100, // softYellow
      onSecondaryContainer: AdminColors.amber700,
      error:            AdminColors.red600,
      onError:          AdminColors.white,
      errorContainer:   AdminColors.red50,
      onErrorContainer: AdminColors.red600,
      surface:          surf,
      onSurface:        onSurf,
      surfaceContainerHighest: dark ? AdminColors.slate800 : AdminColors.slate100,
      outline:          bord,
      outlineVariant:   dark ? AdminColors.slate700 : AdminColors.slate300,
      shadow:           Colors.black,
      scrim:            Colors.black,
      inverseSurface:   dark ? AdminColors.slate100 : AdminColors.slate800,
      onInverseSurface: dark ? AdminColors.slate800 : AdminColors.slate100,
      inversePrimary:   AdminColors.green400,
    );

    return ThemeData(
      useMaterial3:  true,
      brightness:    brightness,
      colorScheme:   colorScheme,
      scaffoldBackgroundColor: bg,

      // ── [UX-5] Police (Inter via Google Fonts quand disponible) ────────
      // textTheme: GoogleFonts.interTextTheme(ThemeData(brightness: brightness).textTheme),
      textTheme: _buildTextTheme(onSurf, onSurfSub, brightness),

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:  surf,
        foregroundColor:  onSurf,
        elevation:        0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: onSurf),
        toolbarHeight: topbarHeight,
        shape: Border(bottom: BorderSide(color: bord, width: 1.5)),
      ),

      // ── Cards ───────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:        surf,
        elevation:    0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: bord),
        ),
        margin: const EdgeInsets.all(0),
      ),

      // ── ElevatedButton ──────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.green800,
          foregroundColor: Colors.white,
          elevation:       0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusButton)),
          textStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 12),
        ),
      ),

      // ── OutlinedButton ──────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminColors.green800,
          side: const BorderSide(color: AdminColors.green800, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusButton)),
          textStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 12),
        ),
      ),

      // ── TextButton ──────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AdminColors.green800,
          textStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),

      // ── InputDecoration (champs de formulaire) ──────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   dark ? AdminColors.slate800 : AdminColors.slate50,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusButton),
          borderSide: BorderSide(color: bord),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusButton),
          borderSide: BorderSide(color: bord),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusButton),
          borderSide: const BorderSide(
              color: AdminColors.green800, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusButton),
          borderSide: const BorderSide(color: AdminColors.red600),
        ),
        hintStyle: TextStyle(
            fontSize: 13, color: onSurfSub),
        labelStyle: TextStyle(
            fontSize: 13, color: onSurfSub),
      ),

      // ── Divider ─────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color:     bord,
        thickness: 1,
        space:     1,
      ),

      // ── Dialog ──────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: surf,
        elevation:       8,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: onSurf),
        contentTextStyle: TextStyle(
            fontSize: 14, color: onSurfSub, height: 1.5),
      ),

      // ── SnackBar ────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? AdminColors.slate700 : AdminColors.slate900,
        contentTextStyle: const TextStyle(
            color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ── TabBar ──────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor:          AdminColors.green800,
        unselectedLabelColor: onSurfSub,
        indicatorColor:      AdminColors.amber600,
        indicatorSize:       TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500, fontSize: 13),
        dividerColor: bord,
      ),

      // ── Chip ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:  dark ? AdminColors.slate700 : AdminColors.slate100,
        selectedColor:    AdminColors.green100,
        labelStyle: TextStyle(fontSize: 12, color: onSurf),
        side: BorderSide(color: bord),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // ── Tooltip ─────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? AdminColors.slate600 : AdminColors.slate900,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(
            color: Colors.white, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        waitDuration: const Duration(milliseconds: 600),
      ),

      // ── ListTile ────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        iconColor:     onSurfSub,
        textColor:     onSurf,
        subtitleTextStyle: TextStyle(fontSize: 12, color: onSurfSub),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall)),
      ),

      // ── Switch ──────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AdminColors.white
                : AdminColors.slate400),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AdminColors.green800
                : (dark ? AdminColors.slate700 : AdminColors.slate300)),
      ),

      // ── PageTransitions ─────────────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS:   CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux:   CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ── TextTheme interne ─────────────────────────────────────────────────

  static TextTheme _buildTextTheme(
      Color primary, Color secondary, Brightness brightness) {
    return TextTheme(
      displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: primary, letterSpacing: -1.0),
      displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.5),
      displaySmall:  TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.3),
      headlineLarge:  TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: primary),
      headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.3),
      headlineSmall:  TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      titleLarge:  TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primary),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      titleSmall:  TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primary),
      bodyLarge:   TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: primary,   height: 1.6),
      bodyMedium:  TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: secondary, height: 1.5),
      bodySmall:   TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: secondary, height: 1.4),
      labelLarge:  TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primary),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondary),
      labelSmall:  TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: secondary, letterSpacing: 0.8),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SECTION 3 — Constantes de design system partagées
// ═══════════════════════════════════════════════════════════════

/// Espacements cohérents dans toute l'app.
/// Usage : SizedBox(height: Spacing.md)
class Spacing {
  Spacing._();
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
}

/// Padding de page standard.
class AppPadding {
  AppPadding._();
  static const page    = EdgeInsets.all(20.0);
  static const pageMd  = EdgeInsets.all(16.0);
  static const card    = EdgeInsets.all(20.0);
  static const cardSm  = EdgeInsets.all(14.0);
  static const section = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
}

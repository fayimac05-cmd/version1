import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════════════════
// ADMIN THEME — Palette ScholARHub Administration
// ════════════════════════════════════════════════════════════════════════════

class AdminTheme {
  // ── Couleurs principales ──────────────────────────────────────────────
  static const Color primary     = Color(0xFF1A3C34); // Vert foncé
  static const Color primaryMid  = Color(0xFF2D6A4F); // Vert moyen
  static const Color primaryLight= Color(0xFFD8F3DC); // Vert clair
  static const Color accent      = Color(0xFFB7950B); // Or — alertes
  static const Color accentLight = Color(0xFFFFF8DC); // Or clair
  static const Color background  = Color(0xFFF8F9FA); // Blanc cassé
  static const Color surface     = Color(0xFFFFFFFF); // Blanc pur
  static const Color surfaceAlt  = Color(0xFFF1F3F5); // Gris très clair
  static const Color border      = Color(0xFFE9ECEF); // Bordure

  // ── Textes ────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1A1A2E); // Noir profond
  static const Color textSecondary = Color(0xFF6C757D); // Gris moyen
  static const Color textMuted     = Color(0xFFADB5BD); // Gris clair

  // ── Statuts ───────────────────────────────────────────────────────────
  static const Color success     = Color(0xFF2D6A4F);
  static const Color successLight= Color(0xFFD8F3DC);
  static const Color warning     = Color(0xFFB7950B);
  static const Color warningLight= Color(0xFFFFF8DC);
  static const Color danger      = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFFEBEB);
  static const Color info        = Color(0xFF0891B2);
  static const Color infoLight   = Color(0xFFE0F7FA);

  // ── Sidebar ───────────────────────────────────────────────────────────
  static const Color sidebarBg       = Color(0xFF1A3C34);
  static const Color sidebarText     = Color(0xFFB7E4C7);
  static const Color sidebarActive   = Color(0xFF2D6A4F);
  static const Color sidebarHover    = Color(0xFF234D3F);
  static const Color sidebarIcon     = Color(0xFF74C69D);

  // ── Ombres ────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: Colors.black.withOpacity(0.06),
        blurRadius: 8, offset: const Offset(0, 2))
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(color: Colors.black.withOpacity(0.1),
        blurRadius: 16, offset: const Offset(0, 4))
  ];

  // ── Radius ────────────────────────────────────────────────────────────
  static const double radiusCard   = 12.0;
  static const double radiusButton = 8.0;
  static const double radiusSmall  = 6.0;

  // ── Sidebar width ─────────────────────────────────────────────────────
  static const double sidebarWidth        = 260.0;
  static const double sidebarWidthCompact = 72.0;
  static const double topbarHeight        = 64.0;

  // ── Breakpoints ───────────────────────────────────────────────────────
  static const double breakpointMobile  = 600.0;
  static const double breakpointTablet  = 900.0;
  static const double breakpointDesktop = 1200.0;

  static bool isMobile(BuildContext ctx)  => MediaQuery.of(ctx).size.width < breakpointMobile;
  static bool isTablet(BuildContext ctx)  => MediaQuery.of(ctx).size.width < breakpointTablet;
  static bool isDesktop(BuildContext ctx) => MediaQuery.of(ctx).size.width >= breakpointTablet;

  // ── TextStyles ────────────────────────────────────────────────────────
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w700,
    color: textPrimary, letterSpacing: -0.5,
  );
  static const TextStyle headingMedium = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700,
    color: textPrimary, letterSpacing: -0.3,
  );
  static const TextStyle headingSmall = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: textPrimary, height: 1.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: textSecondary, height: 1.4,
  );
  static const TextStyle labelBold = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w700,
    color: textSecondary, letterSpacing: 0.5,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: textMuted,
  );

  // ── Widget helpers ────────────────────────────────────────────────────
  static Widget badge(String label, Color fg, Color bg, {double fontSize = 11}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(fontSize: fontSize,
            fontWeight: FontWeight.w700, color: fg)),
      );

  static Widget sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 16, bottom: 6, top: 20),
    child: Text(label.toUpperCase(), style: const TextStyle(
        fontSize: 10, fontWeight: FontWeight.w700,
        color: sidebarText, letterSpacing: 1.2)),
  );
}

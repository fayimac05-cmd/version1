import 'package:flutter/material.dart';
import '../../theme/app_palette.dart';

/// Centralized style guidelines and utility widgets for the Parent space.
/// Ensures consistent colors, paddings, margins, fonts, and responsiveness.
class ParentStyles {
  // ─── COULEURS DE STATUT & DESIGN ───────────────────────────────────────────
  static const Color primary = AppPalette.blue;
  static const Color accent = AppPalette.yellow;
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color borderLight = Color(0xFFE2E8F0);
  
  static const Color success = Color(0xFF15803D);
  static const Color successLight = Color(0xFFF0FDF4);
  
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFFBEB);
  
  static const Color danger = Color(0xFFC62828);
  static const Color dangerLight = Color(0xFFFFEBEE);

  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  // ─── ESPACEMENTS ET BORDURES ──────────────────────────────────────────────
  static const double paddingStandard = 16.0;
  static const double paddingLarge = 24.0;
  
  static const double borderRadiusCards = 16.0;
  static const double borderRadiusSmall = 8.0;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(16, 20, 16, 24);

  // ─── TEXT STYLES (TYPOGRAPHIE UNIFORME) ────────────────────────────────────
  static TextStyle headerTitle(BuildContext context) {
    final double size = MediaQuery.of(context).size.width > 600 ? 26 : 22;
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: textDark,
      letterSpacing: -0.5,
    );
  }

  static TextStyle sectionTitle(BuildContext context) {
    final double size = MediaQuery.of(context).size.width > 600 ? 20 : 18;
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: textDark,
      letterSpacing: -0.3,
    );
  }

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textDark,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    color: textDark,
    height: 1.5,
  );

  static const TextStyle mutedText = TextStyle(
    fontSize: 13,
    color: textMuted,
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
  );

  // ─── BOÎTES D'OMBRES MODERNES ──────────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static BoxDecoration cardDecoration({
    Color color = Colors.white,
    Border? border,
    double radius = borderRadiusCards,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(color: borderLight),
      boxShadow: cardShadow,
    );
  }
}

/// A responsive body wrapper that ensures the layout looks beautiful
/// and well-proportioned on mobile, tablet, and desktop screens.
class ParentResponsiveBody extends StatelessWidget {
  final Widget child;
  final bool usePadding;

  const ParentResponsiveBody({
    super.key,
    required this.child,
    this.usePadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // On screen sizes larger than 768px (tablets and desktops),
    // we center the content and restrict its maximum width.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: usePadding
              ? EdgeInsets.symmetric(
                  horizontal: screenWidth > 800 ? 32.0 : 16.0,
                  vertical: 16.0,
                )
              : EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

/// Helper section header for a clean, unified structure.
class ParentSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const ParentSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: ParentStyles.primary, size: 24),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title,
                style: ParentStyles.headerTitle(context),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: ParentStyles.mutedText,
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

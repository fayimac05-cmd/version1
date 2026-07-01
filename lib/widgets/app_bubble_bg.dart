import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

/// AppBar bleue dégradée réutilisable avec bouton retour
AppBar blueAppBar(String title, {BuildContext? context, List<Widget>? actions}) {
  return AppBar(
    title: Text(title,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3)),
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    elevation: 0,
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A3D91), Color(0xFF1565C0)],
        ),
      ),
      child: Stack(children: [
        Positioned(
          top: -20,
          right: -20,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 70,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.yellow.withValues(alpha: 0.1)),
          ),
        ),
      ]),
    ),
    leading: context != null
        ? GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          )
        : null,
    actions: actions,
  );
}

/// Fond avec bulles bleues et dégradé — design commun à toutes les pages
class AppBubbleBg extends StatelessWidget {
  const AppBubbleBg({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Grande bulle bleue haut-gauche
        Positioned(
          top: -90,
          left: -90,
          child: Container(
            width: 280,
            height: 280,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A4DA2), Color(0xFF1565C0)],
              ),
            ),
          ),
        ),
        // Bulle bleue haut-droit
        Positioned(
          top: -50,
          right: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.midBlue.withValues(alpha: 0.55),
            ),
          ),
        ),
        // Petite bulle jaune
        Positioned(
          top: 80,
          right: 90,
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.yellow,
            ),
          ),
        ),
        // Petite bulle bleue claire bas-gauche
        Positioned(
          bottom: 120,
          left: -30,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.blue.withValues(alpha: 0.08),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Header commun réutilisable pour toutes les pages internes
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
    this.bottomWidget,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;
  final Widget? bottomWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A4DA2), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          // Bulle déco haut-droit
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            right: 60,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.yellow.withValues(alpha: 0.12),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (onBack != null)
                        GestureDetector(
                          onTap: onBack,
                          child: Container(
                            width: 38,
                            height: 38,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                            if (subtitle != null)
                              Text(subtitle!,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          Colors.white.withValues(alpha: 0.75))),
                          ],
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  if (bottomWidget != null) ...[
                    const SizedBox(height: 14),
                    Material(color: Colors.transparent, child: bottomWidget!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

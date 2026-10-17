import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un thème de discussion complet : fond d'écran (dégradé + motif) ET
/// couleurs des bulles de message envoyées/reçues — comme sur WhatsApp, où
/// changer de thème change aussi "la couleur de la discussion".
class ChatThemeData {
  final String id;
  final String nom;
  final List<Color> gradient;
  final Color motifColor;
  final IconData motifIcon;
  final bool sombre;
  final Color bulleMoi;
  final Color texteMoi;
  final Color bulleAutre;
  final Color texteAutre;

  const ChatThemeData({
    required this.id,
    required this.nom,
    required this.gradient,
    required this.motifColor,
    required this.motifIcon,
    required this.bulleMoi,
    required this.texteMoi,
    required this.bulleAutre,
    required this.texteAutre,
    this.sombre = false,
  });
}

class ChatThemes {
  // ── Classiques ───────────────────────────────────────────────────────
  static const classique = ChatThemeData(
    id: 'classique',
    nom: 'Classique',
    gradient: [Color(0xFFEFF3FA), Color(0xFFE1E9F7)],
    motifColor: Color(0x14185FA5),
    motifIcon: Icons.chat_bubble_outline_rounded,
    bulleMoi: Color(0xFF1565C0),
    texteMoi: Colors.white,
    bulleAutre: Colors.white,
    texteAutre: Color(0xFF0F172A),
  );

  static const nuit = ChatThemeData(
    id: 'nuit',
    nom: 'Nuit',
    gradient: [Color(0xFF0F1B33), Color(0xFF1C2E52)],
    motifColor: Color(0x1AFFFFFF),
    motifIcon: Icons.nightlight_round,
    bulleMoi: Color(0xFF6D5AE0),
    texteMoi: Colors.white,
    bulleAutre: Color(0xFF243252),
    texteAutre: Colors.white,
    sombre: true,
  );

  static const pastel = ChatThemeData(
    id: 'pastel',
    nom: 'Pastel',
    gradient: [Color(0xFFFDF2F8), Color(0xFFF1E6FF)],
    motifColor: Color(0x18D946EF),
    motifIcon: Icons.favorite_rounded,
    bulleMoi: Color(0xFFD946EF),
    texteMoi: Colors.white,
    bulleAutre: Colors.white,
    texteAutre: Color(0xFF0F172A),
  );

  static const nature = ChatThemeData(
    id: 'nature',
    nom: 'Nature',
    gradient: [Color(0xFFEAFBF1), Color(0xFFCFF3E0)],
    motifColor: Color(0x1810B981),
    motifIcon: Icons.eco_rounded,
    bulleMoi: Color(0xFF10B981),
    texteMoi: Colors.white,
    bulleAutre: Colors.white,
    texteAutre: Color(0xFF0F172A),
  );

  // ── Informatique ─────────────────────────────────────────────────────
  static const code = ChatThemeData(
    id: 'code',
    nom: 'Code',
    gradient: [Color(0xFF0A0F0A), Color(0xFF0F1F14)],
    motifColor: Color(0x2600FF66),
    motifIcon: Icons.terminal_rounded,
    bulleMoi: Color(0xFF00C853),
    texteMoi: Color(0xFF06210F),
    bulleAutre: Color(0xFF16241A),
    texteAutre: Color(0xFFB9F6CA),
    sombre: true,
  );

  static const circuit = ChatThemeData(
    id: 'circuit',
    nom: 'Circuit',
    gradient: [Color(0xFF0B1622), Color(0xFF12263B)],
    motifColor: Color(0x2200E5FF),
    motifIcon: Icons.memory_rounded,
    bulleMoi: Color(0xFF00B8D4),
    texteMoi: Color(0xFF00232A),
    bulleAutre: Color(0xFF17293B),
    texteAutre: Color(0xFFB2EBF2),
    sombre: true,
  );

  // ── Fonds "photo" (dans l'esprit des fonds WhatsApp) ─────────────────
  // Dégradés à plusieurs teintes, motif quasi invisible, pour se
  // rapprocher du rendu d'une photo/texture plutôt que d'un motif répété.
  static const marbre = ChatThemeData(
    id: 'marbre',
    nom: 'Marbré',
    gradient: [Color(0xFFEFE6F7), Color(0xFFE0C9EC), Color(0xFFF3D9E6)],
    motifColor: Color(0x08000000),
    motifIcon: Icons.circle,
    bulleMoi: Color(0xFF8E44AD),
    texteMoi: Colors.white,
    bulleAutre: Colors.white,
    texteAutre: Color(0xFF0F172A),
  );

  static const floral = ChatThemeData(
    id: 'floral',
    nom: 'Floral',
    gradient: [Color(0xFFFDE2EC), Color(0xFFFBC7D4), Color(0xFFF7A8B8)],
    motifColor: Color(0x08000000),
    motifIcon: Icons.circle,
    bulleMoi: Color(0xFFE0568A),
    texteMoi: Colors.white,
    bulleAutre: Colors.white,
    texteAutre: Color(0xFF0F172A),
  );

  static const coucherDeSoleil = ChatThemeData(
    id: 'coucher_de_soleil',
    nom: 'Coucher de soleil',
    gradient: [Color(0xFFFFE0B2), Color(0xFFFFAB6E), Color(0xFFEE7752)],
    motifColor: Color(0x08000000),
    motifIcon: Icons.circle,
    bulleMoi: Color(0xFFE65100),
    texteMoi: Colors.white,
    bulleAutre: Colors.white,
    texteAutre: Color(0xFF3A1F0A),
  );

  static const ocean = ChatThemeData(
    id: 'ocean',
    nom: 'Océan',
    gradient: [Color(0xFFDFF6F5), Color(0xFFA6E3E0), Color(0xFF6FBFD9)],
    motifColor: Color(0x08000000),
    motifIcon: Icons.circle,
    bulleMoi: Color(0xFF0277BD),
    texteMoi: Colors.white,
    bulleAutre: Colors.white,
    texteAutre: Color(0xFF0F172A),
  );

  static const all = [
    classique, nuit, pastel, nature,
    code, circuit,
    marbre, floral, coucherDeSoleil, ocean,
  ];

  static ChatThemeData byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => classique);
}

/// Sauvegarde locale (SharedPreferences) du thème choisi — un réglage
/// global, éventuellement écrasé par une conversation précise.
class ChatThemeService {
  static const _cleGlobale = 'chat_theme_global';
  static String _cleConversation(String id) => 'chat_theme_conv_$id';

  /// Thème effectif pour une conversation : sa propre préférence si elle en
  /// a une, sinon le thème global, sinon le thème par défaut.
  static Future<String> getThemeFor(String? conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    if (conversationId != null) {
      final override = prefs.getString(_cleConversation(conversationId));
      if (override != null) return override;
    }
    return prefs.getString(_cleGlobale) ?? ChatThemes.classique.id;
  }

  static Future<void> setGlobalTheme(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cleGlobale, themeId);
  }

  static Future<void> setConversationTheme(String conversationId, String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cleConversation(conversationId), themeId);
  }
}

/// Fond d'écran appliqué derrière une conversation : dégradé + motif répété
/// en filigrane, dans l'esprit d'un fond de discussion WhatsApp.
class ChatWallpaper extends StatelessWidget {
  const ChatWallpaper({super.key, required this.theme, required this.child});
  final ChatThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.gradient,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _MotifPainter(icon: theme.motifIcon, color: theme.motifColor),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _MotifPainter extends CustomPainter {
  final IconData icon;
  final Color color;
  _MotifPainter({required this.icon, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double pas = 56;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final glyphe = String.fromCharCode(icon.codePoint);

    var ligne = 0;
    for (double y = -pas; y < size.height + pas; y += pas) {
      final decalage = ligne.isOdd ? pas / 2 : 0.0;
      for (double x = -pas; x < size.width + pas; x += pas) {
        textPainter.text = TextSpan(
          text: glyphe,
          style: TextStyle(
            fontSize: 22,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: color,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x + decalage, y));
      }
      ligne++;
    }
  }

  @override
  bool shouldRepaint(covariant _MotifPainter oldDelegate) =>
      oldDelegate.icon != icon || oldDelegate.color != color;
}
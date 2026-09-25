import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import 'chat_theme.dart';

/// Choix du thème de discussion — petits ronds de couleur, dans l'esprit du
/// sélecteur "Couleur de la discussion" de WhatsApp : un rond = un thème
/// complet (fond + couleur des bulles), on tape pour choisir.
class ChatThemePickerSheet extends StatefulWidget {
  const ChatThemePickerSheet({
    super.key,
    required this.currentThemeId,
    this.conversationId,
  });

  final String currentThemeId;
  /// null → pas de conversation précise à cibler, seul "toutes mes
  /// discussions" est proposé.
  final String? conversationId;

  @override
  State<ChatThemePickerSheet> createState() => _ChatThemePickerSheetState();
}

class _ChatThemePickerSheetState extends State<ChatThemePickerSheet> {
  late String _selection = widget.currentThemeId;
  bool _envoi = false;

  Future<void> _appliquer({required bool global}) async {
    setState(() => _envoi = true);
    if (global) {
      await ChatThemeService.setGlobalTheme(_selection);
    } else if (widget.conversationId != null) {
      await ChatThemeService.setConversationTheme(widget.conversationId!, _selection);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChatThemes.byId(_selection);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Text('Thème de discussion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Le fond et la couleur de vos messages changent ensemble.', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
          const SizedBox(height: 14),

          // Aperçu du thème actuellement survolé/sélectionné.
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 70,
              width: double.infinity,
              child: ChatWallpaper(
                theme: theme,
                child: Stack(children: [
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: theme.bulleAutre, borderRadius: BorderRadius.circular(10)),
                      child: const Text('Salut !', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  Positioned(
                    bottom: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: theme.bulleMoi, borderRadius: BorderRadius.circular(10)),
                      child: Text('Ça marche', style: TextStyle(fontSize: 11, color: theme.texteMoi)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _sectionTitre('Classiques'),
          const SizedBox(height: 10),
          _ligneRonds(const [ChatThemes.classique, ChatThemes.nuit, ChatThemes.pastel, ChatThemes.nature]),
          const SizedBox(height: 16),
          _sectionTitre('Informatique'),
          const SizedBox(height: 10),
          _ligneRonds(const [ChatThemes.code, ChatThemes.circuit]),
          const SizedBox(height: 16),
          _sectionTitre('Fonds'),
          const SizedBox(height: 10),
          _ligneRonds(const [ChatThemes.marbre, ChatThemes.floral, ChatThemes.coucherDeSoleil, ChatThemes.ocean]),

          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _envoi ? null : () => _appliquer(global: true),
              style: ElevatedButton.styleFrom(backgroundColor: AppPalette.blue, padding: const EdgeInsets.symmetric(vertical: 13)),
              child: const Text('Appliquer à toutes mes discussions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
          if (widget.conversationId != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _envoi ? null : () => _appliquer(global: false),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
                child: const Text('Appliquer à cette discussion uniquement', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitre(String texte) => Text(
        texte,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.3),
      );

  Widget _ligneRonds(List<ChatThemeData> themes) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: themes.map(_rond).toList(),
    );
  }

  Widget _rond(ChatThemeData t) {
    final selectionne = _selection == t.id;
    return GestureDetector(
      onTap: () => setState(() => _selection = t.id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selectionne ? AppPalette.blue : Colors.transparent, width: 2.5),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.bulleMoi,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: selectionne
                  ? Icon(Icons.check_rounded, color: t.texteMoi, size: 22)
                  : null,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 60,
            child: Text(
              t.nom,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
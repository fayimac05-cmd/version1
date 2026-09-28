import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import 'emoji_data.dart';

/// Panneau complet emojis / GIF / stickers, façon WhatsApp — réutilisable
/// dans n'importe quel écran de discussion.
///
/// - Emoji sélectionné → [onEmoji] (insertion dans le champ de texte).
/// - GIF ou sticker sélectionné → [onEnvoiDirect] (envoyé comme message,
///   comme sur WhatsApp — pas d'insertion dans le texte).
class EmojiGifStickerPicker extends StatefulWidget {
  const EmojiGifStickerPicker({
    super.key,
    required this.onEmoji,
    required this.onEnvoiDirect,
    this.emojiOnly = false,
  });

  final void Function(String emoji) onEmoji;
  final void Function(String type, String urlOuChemin) onEnvoiDirect; // type: 'gif' | 'sticker'
  /// true → n'affiche que l'onglet Emoji (masque GIF/Stickers), pour les
  /// contextes où seul un emoji a du sens (ex. réaction à un message).
  final bool emojiOnly;

  @override
  State<EmojiGifStickerPicker> createState() => _EmojiGifStickerPickerState();
}

class _EmojiGifStickerPickerState extends State<EmojiGifStickerPicker> {
  int _ongletPrincipal = 0; // 0 = Emoji, 1 = GIF, 2 = Sticker

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.emojiOnly ? 300 : 340,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Expanded(
            child: widget.emojiOnly
                ? _OngletEmoji(onEmoji: widget.onEmoji)
                : IndexedStack(
              index: _ongletPrincipal,
              children: [
                _OngletEmoji(onEmoji: widget.onEmoji),
                _OngletGif(onGif: (url) => widget.onEnvoiDirect('gif', url)),
                _OngletSticker(onSticker: (chemin) => widget.onEnvoiDirect('sticker', chemin)),
              ],
            ),
          ),
          if (!widget.emojiOnly)
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Row(
              children: [
                _ongletBtn('😊', 'Emoji', 0),
                _ongletBtn('GIF', 'GIF', 1, texte: true),
                _ongletBtn('🏷️', 'Stickers', 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ongletBtn(String label, String tooltip, int index, {bool texte = false}) {
    final actif = _ongletPrincipal == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _ongletPrincipal = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: actif ? AppPalette.blue.withValues(alpha: 0.06) : Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              texte
                  ? Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: actif ? AppPalette.blue : const Color(0xFF94A3B8)))
                  : Text(label, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(tooltip, style: TextStyle(fontSize: 9.5, color: actif ? AppPalette.blue : const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// ONGLET EMOJI
// ════════════════════════════════════════════════════════════════════════
class _OngletEmoji extends StatefulWidget {
  const _OngletEmoji({required this.onEmoji});
  final void Function(String) onEmoji;

  @override
  State<_OngletEmoji> createState() => _OngletEmojiState();
}

class _OngletEmojiState extends State<_OngletEmoji> {
  String _categorie = 'Smileys';
  String _recherche = '';
  List<String> _recents = [];

  @override
  void initState() {
    super.initState();
    _chargerRecents();
  }

  Future<void> _chargerRecents() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _recents = prefs.getStringList('emojis_recents') ?? []);
  }

  Future<void> _choisir(String emoji) async {
    widget.onEmoji(emoji);
    final prefs = await SharedPreferences.getInstance();
    final liste = prefs.getStringList('emojis_recents') ?? [];
    liste.remove(emoji);
    liste.insert(0, emoji);
    if (liste.length > 32) liste.removeRange(32, liste.length);
    await prefs.setStringList('emojis_recents', liste);
    if (mounted) setState(() => _recents = liste);
  }

  List<String> get _emojisAffiches {
    if (_recherche.isNotEmpty) {
      return EmojiData.categories.values.expand((e) => e).toSet().toList();
    }
    if (_categorie == 'Récents') return _recents;
    return EmojiData.categories[_categorie] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          child: Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
            child: TextField(
              onChanged: (v) => setState(() => _recherche = v.trim()),
              decoration: const InputDecoration(
                hintText: 'Rechercher un emoji',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        if (_recherche.isEmpty)
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _chip('Récents', '🕐'),
                ...EmojiData.ordreCategories.map((c) => _chip(c, EmojiData.icones[c]!)),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Expanded(
          child: _emojisAffiches.isEmpty
              ? const Center(child: Text('Aucun emoji récent.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))))
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, mainAxisSpacing: 0, crossAxisSpacing: 0, childAspectRatio: 1),
                  itemCount: _emojisAffiches.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _choisir(_emojisAffiches[i]),
                    child: Center(child: Text(_emojisAffiches[i], style: const TextStyle(fontSize: 24))),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _chip(String nom, String icone) {
    final actif = _categorie == nom;
    return GestureDetector(
      onTap: () => setState(() => _categorie = nom),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: actif ? AppPalette.blue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text(icone, style: const TextStyle(fontSize: 16))),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// ONGLET GIF (nécessite GIPHY_API_KEY côté backend)
// ════════════════════════════════════════════════════════════════════════
class _OngletGif extends StatefulWidget {
  const _OngletGif({required this.onGif});
  final void Function(String url) onGif;

  @override
  State<_OngletGif> createState() => _OngletGifState();
}

class _OngletGifState extends State<_OngletGif> {
  bool _chargement = true;
  String? _erreur;
  List<Map<String, dynamic>> _gifs = [];
  final _rechercheCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger([String? q]) async {
    setState(() { _chargement = true; _erreur = null; });
    final result = await ApiService.rechercherGifs(q);
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        _gifs = List<Map<String, dynamic>>.from(result['data'] as List);
      } else {
        _erreur = result['error']?.toString() ?? 'Erreur lors du chargement des GIF.';
      }
      _chargement = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          child: Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
            child: TextField(
              controller: _rechercheCtrl,
              onSubmitted: (v) => _charger(v.trim().isEmpty ? null : v.trim()),
              decoration: InputDecoration(
                hintText: 'Rechercher un GIF',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppPalette.blue),
                  onPressed: () => _charger(_rechercheCtrl.text.trim().isEmpty ? null : _rechercheCtrl.text.trim()),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        Expanded(
          child: _chargement
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _erreur != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(_erreur!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8))),
                      ),
                    )
                  : _gifs.isEmpty
                      ? const Center(child: Text('Aucun résultat.', style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8))))
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4, mainAxisSpacing: 3, crossAxisSpacing: 3,
                          ),
                          itemCount: _gifs.length,
                          itemBuilder: (_, i) {
                            final g = _gifs[i];
                            return GestureDetector(
                              onTap: () => widget.onGif(g['url'].toString()),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(g['preview'].toString(), fit: BoxFit.cover),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// ONGLET STICKERS — création depuis la galerie + enregistrement de reçus
// ════════════════════════════════════════════════════════════════════════
class _OngletSticker extends StatefulWidget {
  const _OngletSticker({required this.onSticker});
  final void Function(String chemin) onSticker;

  @override
  State<_OngletSticker> createState() => _OngletStickerState();
}

class _OngletStickerState extends State<_OngletSticker> {
  List<String> _stickers = [];
  bool _import = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final chemins = await StickerStore.lister();
    if (mounted) setState(() => _stickers = chemins);
  }

  Future<void> _creer() async {
    setState(() => _import = true);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        final chemin = await StickerStore.enregistrerDepuisFichier(picked.path, picked.name);
        if (chemin != null) await _charger();
      }
    } finally {
      if (mounted) setState(() => _import = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _import ? null : _creer,
              icon: _import
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Créer un sticker (photo/vidéo)'),
            ),
          ),
        ),
        Expanded(
          child: _stickers.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Aucun sticker pour l\'instant.\nCréez-en un, ou enregistrez-en un depuis un message reçu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8,
                  ),
                  itemCount: _stickers.length,
                  itemBuilder: (_, i) {
                    final chemin = _stickers[i];
                    return GestureDetector(
                      onTap: () => widget.onSticker(chemin),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: kIsWeb
                            ? Image.network(chemin, fit: BoxFit.cover)
                            : Image.file(File(chemin), fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Bibliothèque locale de stickers de l'utilisateur — enregistrés sur
/// l'appareil (pas de synchronisation entre appareils pour l'instant).
class StickerStore {
  static Future<Directory> _dossier() async {
    final base = await getApplicationDocumentsDirectory();
    final dossier = Directory('${base.path}/stickers');
    if (!await dossier.exists()) await dossier.create(recursive: true);
    return dossier;
  }

  static Future<List<String>> lister() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('stickers_web') ?? [];
    }
    final dossier = await _dossier();
    final fichiers = dossier.listSync().whereType<File>().toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return fichiers.map((f) => f.path).toList();
  }

  /// Crée un sticker à partir d'un fichier choisi dans la galerie.
  static Future<String?> enregistrerDepuisFichier(String cheminSource, String nomOriginal) async {
    if (kIsWeb) return null; // Web : pas d'accès fichiers locaux persistants ici.
    final dossier = await _dossier();
    final nom = 'sticker_${DateTime.now().millisecondsSinceEpoch}_$nomOriginal';
    final cible = File('${dossier.path}/$nom');
    await cible.writeAsBytes(await File(cheminSource).readAsBytes());
    return cible.path;
  }

  /// Enregistre un sticker reçu en message (URL réseau) dans la
  /// bibliothèque locale — télécharge l'image et la sauvegarde.
  static Future<bool> enregistrerDepuisUrl(String url) async {
    try {
      final result = await ApiService.telechargerFichier(url);
      if (result == null) return false;
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final liste = prefs.getStringList('stickers_web') ?? [];
        if (!liste.contains(url)) {
          liste.insert(0, url);
          await prefs.setStringList('stickers_web', liste);
        }
        return true;
      }
      final dossier = await _dossier();
      final nom = 'sticker_${DateTime.now().millisecondsSinceEpoch}.png';
      final cible = File('${dossier.path}/$nom');
      await cible.writeAsBytes(result);
      return true;
    } catch (_) {
      return false;
    }
  }
}
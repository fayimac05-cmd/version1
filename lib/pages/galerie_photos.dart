import 'package:flutter/material.dart';
import 'message_actions.dart';

// ════════════════════════════════════════════════════════════════════════
// PHOTOS GROUPÉES « façon WhatsApp » — commun à TOUTES les messageries
//  • calculerLotsPhotos : repère les photos envoyées d'affilée par la même
//    personne (≤ 2 min d'écart) pour les afficher dans UNE seule bulle
//  • GrillePhotos       : grille 1 / 2 / 3 / 4 photos, « +N » au-delà de 4
//  • VisionneuseGalerie : plein écran, balayage entre les photos du lot
// Un lot est représenté par un contenu « [GALERIE]url1\nurl2\n… » (jamais
// envoyé au serveur : construit seulement pour l'affichage).
// ════════════════════════════════════════════════════════════════════════

const String kPrefixeGalerie = '[GALERIE]';

/// Écart maximal (minutes) entre deux photos consécutives pour les regrouper.
const int kEcartPhotosMinutes = 2;

/// URL de la photo si le contenu est « [FICHIER]image|url|nom », sinon null.
String? urlPhotoMessage(String contenu) {
  final f = lireFichierMessage(contenu);
  if (f == null || f.type != 'image') return null;
  return f.url;
}

bool estGalerie(String contenu) => contenu.startsWith(kPrefixeGalerie);

/// Vrai si le message n'affiche que des photos (une seule ou un lot).
bool estMessagePhotos(String contenu) => estGalerie(contenu) || urlPhotoMessage(contenu) != null;

String contenuGalerie(List<String> urls) => '$kPrefixeGalerie${urls.join('\n')}';

List<String> urlsGalerie(String contenu) {
  if (estGalerie(contenu)) {
    return contenu.substring(kPrefixeGalerie.length).split('\n').where((u) => u.isNotEmpty).toList();
  }
  final u = urlPhotoMessage(contenu);
  return u == null ? <String>[] : <String>[u];
}

/// Pour chaque message de [msgs] :
///  • null       → message affiché tel quel ;
///  • liste vide → photo absorbée par le lot qui précède (à ne pas afficher) ;
///  • liste ≥ 2  → premier d'un lot : indices de toutes les photos du lot.
/// Deux photos sont du même lot si elles sont consécutives, du même auteur
/// (non nul), du même jour, à moins de [kEcartPhotosMinutes] minutes d'écart.
List<List<int>?> calculerLotsPhotos<T>(
  List<T> msgs, {
  required String Function(T) contenu,
  required String? Function(T) auteur,
  required String Function(T) jour,
  required int Function(T) minutes,
}) {
  final res = List<List<int>?>.filled(msgs.length, null);
  var i = 0;
  while (i < msgs.length) {
    if (urlPhotoMessage(contenu(msgs[i])) == null || auteur(msgs[i]) == null) {
      i++;
      continue;
    }
    final lot = <int>[i];
    var j = i + 1;
    while (j < msgs.length) {
      final prec = msgs[lot.last];
      final cur = msgs[j];
      final memeLot = urlPhotoMessage(contenu(cur)) != null &&
          auteur(cur) == auteur(prec) &&
          jour(cur) == jour(prec) &&
          (minutes(cur) - minutes(prec)).abs() <= kEcartPhotosMinutes;
      if (!memeLot) break;
      lot.add(j);
      j++;
    }
    if (lot.length >= 2) {
      res[i] = lot;
      for (final k in lot.skip(1)) {
        res[k] = <int>[];
      }
    }
    i = j;
  }
  return res;
}

/// Grille de photos dans une bulle : 1, 2, 3 ou 4 vignettes ; au-delà de 4,
/// la 4e porte « +N » (N = photos restantes). L'heure est posée sur l'image.
class GrillePhotos extends StatelessWidget {
  const GrillePhotos({super.key, required this.urls, this.heure = ''});

  final List<String> urls;
  final String heure;

  static const double _ecart = 2;

  void _ouvrir(BuildContext context, int index) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => VisionneuseGalerie(urls: urls, indexInitial: index),
      ),
    );
  }

  Widget _vignette(BuildContext context, int i, double w, double h, {int restant = 0}) {
    return GestureDetector(
      onTap: () => _ouvrir(context, i),
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(fit: StackFit.expand, children: [
          Image.network(
            urls[i],
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : Container(
                    color: const Color(0xFFE9EDF0),
                    alignment: Alignment.center,
                    child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFCCD0D5),
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined, color: Color(0xFF8696A0)),
            ),
          ),
          if (restant > 0)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Text('+$restant',
                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w600)),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, c) {
      final dispo = c.maxWidth.isFinite ? c.maxWidth : 280.0;
      final w = dispo < 280.0 ? dispo : 280.0;
      final demi = (w - _ecart) / 2;
      final n = urls.length;
      final restant = n > 4 ? n - 4 : 0;

      final Widget corps;
      if (n == 1) {
        corps = _vignette(context, 0, w, w * 0.75);
      } else if (n == 2) {
        corps = Row(mainAxisSize: MainAxisSize.min, children: [
          _vignette(context, 0, demi, demi * 1.2),
          const SizedBox(width: _ecart),
          _vignette(context, 1, demi, demi * 1.2),
        ]);
      } else if (n == 3) {
        corps = Column(mainAxisSize: MainAxisSize.min, children: [
          _vignette(context, 0, w, w * 0.62),
          const SizedBox(height: _ecart),
          Row(mainAxisSize: MainAxisSize.min, children: [
            _vignette(context, 1, demi, demi * 0.9),
            const SizedBox(width: _ecart),
            _vignette(context, 2, demi, demi * 0.9),
          ]),
        ]);
      } else {
        corps = Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            _vignette(context, 0, demi, demi * 0.9),
            const SizedBox(width: _ecart),
            _vignette(context, 1, demi, demi * 0.9),
          ]),
          const SizedBox(height: _ecart),
          Row(mainAxisSize: MainAxisSize.min, children: [
            _vignette(context, 2, demi, demi * 0.9),
            const SizedBox(width: _ecart),
            _vignette(context, 3, demi, demi * 0.9, restant: restant),
          ]),
        ]);
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: w,
          child: Stack(children: [
            corps,
            if (heure.isNotEmpty)
              Positioned(
                right: 6,
                bottom: 5,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(heure, style: const TextStyle(color: Colors.white, fontSize: 10.5)),
                  ),
                ),
              ),
          ]),
        ),
      );
    });
  }
}

/// Plein écran : balayer pour passer d'une photo à l'autre, pincer pour zoomer,
/// bouton pour télécharger la photo affichée.
class VisionneuseGalerie extends StatefulWidget {
  const VisionneuseGalerie({super.key, required this.urls, this.indexInitial = 0});

  final List<String> urls;
  final int indexInitial;

  @override
  State<VisionneuseGalerie> createState() => _VisionneuseGalerieState();
}

class _VisionneuseGalerieState extends State<VisionneuseGalerie> {
  late final PageController _ctrl = PageController(initialPage: widget.indexInitial);
  late int _index = widget.indexInitial;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.urls.length;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _ctrl,
          itemCount: n,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Image.network(
                widget.urls[i],
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator(color: Colors.white70)),
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Center(
                  child: n > 1
                      ? Text('${_index + 1} / $n',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))
                      : const SizedBox.shrink(),
                ),
              ),
              IconButton(
                tooltip: 'Télécharger',
                icon: const Icon(Icons.download_rounded, color: Colors.white, size: 24),
                onPressed: () => telechargerMessage(
                    context, '[FICHIER]image|${widget.urls[_index]}|photo_${_index + 1}.jpg'),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

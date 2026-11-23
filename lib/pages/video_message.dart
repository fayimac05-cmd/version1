import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

// ════════════════════════════════════════════════════════════════════════
// MESSAGES VIDÉO / DOCUMENT façon WhatsApp
//  • VideoMessageCard   : vignette (1re image) + bouton ▶, appui = lecteur plein écran
//  • VisionneuseVideo   : lecteur plein écran (lecture/pause, barre de progression,
//                         bouton télécharger)
//  • FichierDocumentCard: carte document cliquable (ouvre / télécharge le fichier)
// Utilise video_player + url_launcher  →  flutter pub add video_player url_launcher
// ════════════════════════════════════════════════════════════════════════

/// Vignette Cloudinary : 1re image de la vidéo (…/video/upload/x.mp4 → so_0 + .jpg).
String? _vignetteUrl(String url) {
  if (!url.contains('/video/upload/')) return null;
  final sansQuery = url.split('?').first;
  final point = sansQuery.lastIndexOf('.');
  final base = point > sansQuery.lastIndexOf('/') ? sansQuery.substring(0, point) : sansQuery;
  return base.replaceFirst('/video/upload/', '/video/upload/so_0,w_640,c_limit/') + '.jpg';
}

/// Nom de fichier sûr pour Cloudinary : sans extension (Cloudinary la remet),
/// accents retirés, tout caractère spécial remplacé par « _ ».
String _nomPourTelechargement(String nom) {
  var n = nom.trim();
  final point = n.lastIndexOf('.');
  if (point > 0 && n.length - point <= 6) n = n.substring(0, point);
  const accents = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'î': 'i', 'ï': 'i',
    'ô': 'o', 'ö': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c',
    'À': 'A', 'Â': 'A', 'É': 'E', 'È': 'E', 'Ê': 'E', 'Ô': 'O', 'Ç': 'C',
  };
  n = n.split('').map((c) => accents[c] ?? c).join();
  n = n.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_').replaceAll(RegExp(r'_+'), '_');
  n = n.replaceAll(RegExp(r'^_+|_+$'), '');
  return n;
}

/// URL qui force le téléchargement (Cloudinary : drapeau fl_attachment).
/// Avec un nom, le fichier enregistré porte ce nom (et non « 1795…-nom.pdf »).
String _urlTelechargement(String url, [String? nom]) {
  if (!url.contains('/upload/')) return url;
  final propre = nom == null ? '' : _nomPourTelechargement(nom);
  final drapeau = propre.isEmpty ? 'fl_attachment' : 'fl_attachment:$propre';
  return url.replaceFirst('/upload/', '/upload/$drapeau/');
}

Future<void> ouvrirFichier(BuildContext context, String url, {bool telecharger = false, String? nom}) async {
  final cible = telecharger ? _urlTelechargement(url, nom) : url;
  try {
    final ok = await launchUrl(Uri.parse(cible), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir ce fichier.')));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir ce fichier.')));
    }
  }
}

// ── Carte vidéo dans la bulle ───────────────────────────────────────────
class VideoMessageCard extends StatelessWidget {
  const VideoMessageCard({super.key, required this.url, required this.nom});
  final String url;
  final String nom;

  @override
  Widget build(BuildContext context) {
    final vignette = _vignetteUrl(url);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(fullscreenDialog: true, builder: (_) => VisionneuseVideo(url: url, nom: nom)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 260,
          height: 160,
          child: Stack(fit: StackFit.expand, children: [
            Container(color: const Color(0xFF1F2937)),
            if (vignette != null)
              Image.network(vignette, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            Container(color: Colors.black.withValues(alpha: 0.18)),
            Center(
              child: Container(
                width: 58, height: 58,
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 38),
              ),
            ),
            Positioned(
              left: 8, bottom: 8, right: 8,
              child: Row(children: [
                const Icon(Icons.videocam_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 5),
                Expanded(child: Text(nom, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Lecteur plein écran ─────────────────────────────────────────────────
class VisionneuseVideo extends StatefulWidget {
  const VisionneuseVideo({super.key, required this.url, required this.nom});
  final String url;
  final String nom;
  @override
  State<VisionneuseVideo> createState() => _VisionneuseVideoState();
}

class _VisionneuseVideoState extends State<VisionneuseVideo> {
  late final VideoPlayerController _ctrl;
  bool _pret = false;
  bool _erreur = false;
  bool _controles = true;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _ctrl.initialize().then((_) {
      if (!mounted) return;
      setState(() => _pret = true);
      _ctrl.play();
    }).catchError((_) {
      if (mounted) setState(() => _erreur = true);
    });
    _ctrl.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final lecture = _pret && _ctrl.value.isPlaying;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _controles = !_controles),
        child: Stack(children: [
          Center(
            child: _erreur
                ? Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.error_outline, color: Colors.white54, size: 52),
                    const SizedBox(height: 10),
                    const Text('Lecture impossible dans l\'appli.', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => ouvrirFichier(context, widget.url),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Ouvrir dans le navigateur'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                    ),
                  ])
                : !_pret
                    ? const CircularProgressIndicator(color: Colors.white)
                    : AspectRatio(aspectRatio: _ctrl.value.aspectRatio, child: VideoPlayer(_ctrl)),
          ),
          if (_controles) ...[
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  _rond(Icons.close_rounded, () => Navigator.pop(context)),
                  const Spacer(),
                  _rond(Icons.download_rounded, () => ouvrirFichier(context, widget.url, telecharger: true, nom: widget.nom)),
                ]),
              ),
            ),
            if (_pret)
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 6, 12, 10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent]),
                    ),
                    child: Row(children: [
                      IconButton(
                        icon: Icon(lecture ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 30),
                        onPressed: () => lecture ? _ctrl.pause() : _ctrl.play(),
                      ),
                      Text(_fmt(_ctrl.value.position), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: VideoProgressIndicator(_ctrl, allowScrubbing: true,
                            colors: const VideoProgressColors(playedColor: Colors.white, bufferedColor: Colors.white30, backgroundColor: Colors.white24)),
                      ),
                      const SizedBox(width: 8),
                      Text(_fmt(_ctrl.value.duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ]),
                  ),
                ),
              ),
          ],
        ]),
      ),
    );
  }

  Widget _rond(IconData icone, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
          child: Icon(icone, color: Colors.white, size: 22),
        ),
      );
}

// ── Carte document cliquable (PDF, Word…) ───────────────────────────────
class FichierDocumentCard extends StatelessWidget {
  const FichierDocumentCard({super.key, required this.url, required this.nom, required this.texteColor});
  final String url;
  final String nom;
  final Color texteColor;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      // Appui sur le document : l'ouvrir sans le télécharger.
      Flexible(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => ouvrirFichier(context, url),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: const Color(0xFF7F66FF).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.insert_drive_file_rounded, size: 20, color: Color(0xFF7F66FF)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nom, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: texteColor)),
            Text('Document · appuyer pour ouvrir', style: TextStyle(fontSize: 11.5, color: texteColor.withValues(alpha: 0.7))),
          ]),
        ),
          ]),
        ),
      ),
      // Flèche : télécharger sur l'appareil, avec le vrai nom du fichier.
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Téléchargement de $nom…'),
            duration: const Duration(seconds: 2),
          ));
          ouvrirFichier(context, url, telecharger: true, nom: nom);
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.download_rounded, size: 22, color: texteColor.withValues(alpha: 0.8)),
        ),
      ),
    ]);
  }
}

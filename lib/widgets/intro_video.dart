import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Vidéo plein écran (sans son) jouée une fois, au démarrage de l'application.
///
/// - [onTermine] est appelé à la fin de la vidéo.
/// - [onErreur] est appelé si la vidéo ne peut pas être lue (plateforme non
///   prise en charge, fichier absent…) : l'appelant affiche alors une solution
///   de repli.
class IntroVideo extends StatefulWidget {
  const IntroVideo({super.key, required this.onTermine, required this.onErreur});

  final VoidCallback onTermine;
  final VoidCallback onErreur;

  static const String asset = 'assets/videos/diplomes.mp4';

  @override
  State<IntroVideo> createState() => _IntroVideoState();
}

class _IntroVideoState extends State<IntroVideo> {
  VideoPlayerController? _c;
  bool _pret = false;
  bool _fini = false;

  @override
  void initState() {
    super.initState();
    _demarrer();
  }

  Future<void> _demarrer() async {
    try {
      final c = VideoPlayerController.asset(
        IntroVideo.asset,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _c = c;
      await c.initialize();
      if (!mounted) return;
      await c.setVolume(0); // obligatoire pour la lecture automatique sur le web
      await c.setLooping(false);
      c.addListener(_surChangement);
      await c.play();
      if (!mounted) return;
      setState(() => _pret = true);
    } catch (_) {
      if (mounted) widget.onErreur();
    }
  }

  void _surChangement() {
    final c = _c;
    if (c == null || _fini) return;
    final v = c.value;
    if (v.hasError) {
      _fini = true;
      widget.onErreur();
      return;
    }
    if (v.isInitialized && v.duration > Duration.zero && v.position >= v.duration - const Duration(milliseconds: 120)) {
      _fini = true;
      widget.onTermine();
    }
  }

  @override
  void dispose() {
    _c?.removeListener(_surChangement);
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (!_pret || c == null) {
      return const ColoredBox(color: Color(0xFF0B1E4D));
    }
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: c.value.size.width,
          height: c.value.size.height,
          child: VideoPlayer(c),
        ),
      ),
    );
  }
}

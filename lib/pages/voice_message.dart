// ════════════════════════════════════════════════════════════════════════════
// VOICE MESSAGE — enregistrement réel (package `record`) + lecture (package
// `audioplayers`) des messages vocaux, partagé par canal_screen.dart,
// admin_messages.dart et groupe_filiere_screen.dart.
//
// Convention de contenu (identique au pattern [FICHIER] déjà utilisé pour les
// autres pièces jointes) : "[FICHIER]vocal|<url>|<mm:ss>"
// ════════════════════════════════════════════════════════════════════════════
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

/// Encapsule le cycle de vie d'un enregistrement vocal réel : démarrage,
/// pause/reprise, annulation, arrêt+récupération des octets. Une seule
/// instance par écran de chat (créée dans le State, disposée dans dispose()).
class VoiceRecorderController {
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;
  bool isRecording = false;
  bool isPaused = false;

  /// Flux du niveau sonore réellement capté par le micro (en dB, ~-45 pour
  /// un silence à ~0 pour un son fort), interrogé toutes les 100ms pendant
  /// l'enregistrement — sert à dessiner une vraie courbe d'onde réactive.
  Stream<Amplitude> get amplitudeStream =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 100));

  /// Vérifie/demande la permission micro puis démarre l'enregistrement.
  /// Retourne false si la permission est refusée (l'appelant doit alors
  /// afficher un message et ne pas basculer l'UI en mode "enregistrement").
  Future<bool> start() async {
    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) return false;

    if (kIsWeb) {
      _path = 'voice_message.m4a'; // ignoré sur web, record gère le blob
    } else {
      final dir = await getTemporaryDirectory();
      _path = '${dir.path}/vocal_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
      path: _path ?? '',
    );
    isRecording = true;
    isPaused = false;
    return true;
  }

  Future<void> pauseOuReprendre() async {
    if (!isRecording) return;
    if (isPaused) {
      await _recorder.resume();
      isPaused = false;
    } else {
      await _recorder.pause();
      isPaused = true;
    }
  }

  /// Arrête et jette l'enregistrement en cours (bouton "supprimer").
  Future<void> annuler() async {
    if (!isRecording) return;
    try {
      final path = await _recorder.stop();
      isRecording = false;
      isPaused = false;
      if (!kIsWeb && path != null) {
        final f = File(path);
        if (await f.exists()) await f.delete();
      }
    } catch (_) {
      isRecording = false;
      isPaused = false;
    }
  }

  /// Arrête l'enregistrement et retourne les octets du fichier audio (prêts
  /// pour ApiService.uploaderFichierMessage), ou null en cas d'échec.
  Future<List<int>?> arreterEtRecuperer() async {
    if (!isRecording) return null;
    try {
      final path = await _recorder.stop();
      isRecording = false;
      isPaused = false;
      if (path == null) return null;
      if (kIsWeb) {
        // Sur web, `record` retourne un blob URL ; on le récupère via
        // package:http (fonctionne côté navigateur, contrairement à
        // dart:io HttpClient qui n'est pas supporté sur Flutter Web).
        final resp = await http.get(Uri.parse(path));
        if (resp.statusCode != 200) return null;
        return resp.bodyBytes;
      }
      final f = File(path);
      if (!await f.exists()) return null;
      return await f.readAsBytes();
    } catch (_) {
      isRecording = false;
      isPaused = false;
      return null;
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}

/// Lecteur inline pour une bulle de message vocal reçu/envoyé — bouton
/// play/pause + barre de progression + durée, façon WhatsApp.
class VoiceMessagePlayer extends StatefulWidget {
  final String url;
  final String dureeLabel;
  final Color couleur;
  final Color texteColor;
  const VoiceMessagePlayer({
    super.key,
    required this.url,
    required this.dureeLabel,
    required this.couleur,
    required this.texteColor,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final AudioPlayer _player = AudioPlayer();
  Duration _position = Duration.zero;
  Duration? _duration;
  bool _isPlaying = false;
  StreamSubscription? _posSub, _durSub, _stateSub, _completeSub;

  @override
  void initState() {
    super.initState();
    _posSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _isPlaying = s == PlayerState.playing);
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _isPlaying = false; _position = Duration.zero; });
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.setVolume(1.0);
      await _player.play(UrlSource(widget.url));
    }
  }

  Future<void> _seekVers(double ratio) async {
    final total = _duration;
    if (total == null || total == Duration.zero) return;
    await _player.seek(total * ratio.clamp(0.0, 1.0));
    if (!_isPlaying) {
      await _player.setVolume(1.0);
      await _player.play(UrlSource(widget.url));
    }
  }

  String _fmt(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final total = _duration ?? Duration.zero;
    final progress = total.inMilliseconds > 0 ? _position.inMilliseconds / total.inMilliseconds : 0.0;
    // Icône du bouton play/pause contrastée automatiquement avec le fond du
    // cercle (utile quand `couleur` == blanc sur une bulle "moi" solide).
    final iconColor = widget.couleur.computeLuminance() > 0.5 ? const Color(0xFF111B21) : Colors.white;
    return SizedBox(
      width: 230,
      child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: widget.couleur, shape: BoxShape.circle),
            child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: iconColor, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            _WaveformStatique(
              progres: progress.clamp(0.0, 1.0),
              couleur: widget.couleur,
              seed: widget.url,
              onSeek: _seekVers,
            ),
            const SizedBox(height: 3),
            Text(
              _isPlaying || _position > Duration.zero ? _fmt(_position) : widget.dureeLabel,
              style: TextStyle(fontSize: 11.5, color: widget.texteColor.withValues(alpha: 0.7)),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Onde façon WhatsApp pour un message vocal déjà enregistré : barres de
/// hauteurs variées (dérivées de l'URL, donc stables entre les rebuilds),
/// avec la portion déjà lue mise en évidence.
class _WaveformStatique extends StatelessWidget {
  final double progres;
  final Color couleur;
  final String seed;
  final ValueChanged<double> onSeek;
  const _WaveformStatique({required this.progres, required this.couleur, required this.seed, required this.onSeek});

  List<double> get _hauteurs {
    // Génère des hauteurs pseudo-aléatoires mais stables (dérivées du hash
    // de l'URL), pour que la même bulle vocale garde toujours le même
    // "dessin" d'onde plutôt que de changer à chaque reconstruction.
    final rnd = math.Random(seed.hashCode);
    return List.generate(26, (_) => 0.25 + rnd.nextDouble() * 0.75);
  }

  @override
  Widget build(BuildContext context) {
    final hauteurs = _hauteurs;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final ratio = (details.localPosition.dx / box.size.width).clamp(0.0, 1.0);
        onSeek(ratio);
      },
      child: SizedBox(
        height: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(hauteurs.length, (i) {
            final lu = (i / hauteurs.length) < progres;
            return Container(
              width: 2.5,
              height: 4 + hauteurs[i] * 16,
              decoration: BoxDecoration(
                color: lu ? couleur : couleur.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BARRE D'ENREGISTREMENT — bouton supprimer, point clignotant, chrono, onde
// animée, pause/reprendre, envoyer. Style WhatsApp, partagé par les 3 écrans
// de chat (canal_screen.dart utilise sa propre copie déjà existante ;
// admin_messages.dart aussi ; groupe_filiere_screen.dart s'appuie sur celle-ci).
// ════════════════════════════════════════════════════════════════════════════
class VoiceRecordingBar extends StatelessWidget {
  final bool paused;
  final int secondes;
  final Color couleur;
  final VoidCallback onCancel;
  final VoidCallback onPauseResume;
  final VoidCallback onSend;
  final Color backgroundColor;
  final VoiceRecorderController controller;

  const VoiceRecordingBar({
    super.key,
    required this.paused,
    required this.secondes,
    required this.couleur,
    required this.onCancel,
    required this.onPauseResume,
    required this.onSend,
    required this.controller,
    this.backgroundColor = const Color(0xFFF8FAFC),
  });

  static String fmtDuree(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        GestureDetector(
          onTap: onCancel,
          child: Container(width: 42, height: 42,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 22)),
        ),
        const SizedBox(width: 8),
        VoiceBlinkingDot(paused: paused),
        const SizedBox(width: 6),
        Text(fmtDuree(secondes), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111B21))),
        const SizedBox(width: 10),
        Expanded(child: VoiceWaveform(paused: paused, couleur: couleur, controller: controller)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onPauseResume,
          child: Container(width: 38, height: 38,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: const Color(0xFF54656F), size: 22)),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onSend,
          child: Container(width: 42, height: 42,
            decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 19)),
        ),
      ]),
    );
  }
}

/// Point rouge clignotant pendant l'enregistrement.
class VoiceBlinkingDot extends StatefulWidget {
  final bool paused;
  const VoiceBlinkingDot({super.key, required this.paused});
  @override
  State<VoiceBlinkingDot> createState() => _VoiceBlinkingDotState();
}

class _VoiceBlinkingDotState extends State<VoiceBlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.paused) {
      return const Icon(Icons.circle, color: Color(0xFFDC2626), size: 10);
    }
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_ctrl),
      child: const Icon(Icons.circle, color: Color(0xFFDC2626), size: 10),
    );
  }
}

/// Onde sonore RÉELLE — chaque barre reflète l'amplitude effectivement
/// captée par le micro (via `controller.amplitudeStream`), défilant de
/// droite à gauche comme un vrai enregistreur vocal. En silence, les barres
/// retombent à une hauteur minimale (comme des points) ; sur une voix forte,
/// elles montent nettement plus haut.
class VoiceWaveform extends StatefulWidget {
  final bool paused;
  final Color couleur;
  final VoiceRecorderController controller;
  const VoiceWaveform({super.key, required this.paused, required this.controller, this.couleur = const Color(0xFF15803D)});
  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform> {
  static const int _barCount = 28;
  // Niveaux normalisés (0.0 = silence, 1.0 = son fort), le plus récent en
  // dernier — nouvelle barre ajoutée à droite, les anciennes défilent.
  // `List.generate` (contrairement à `List.filled`) crée une liste
  // redimensionnable, nécessaire pour removeAt/add ci-dessous.
  final List<double> _niveaux = List.generate(_barCount, (_) => 0.04);
  StreamSubscription<Amplitude>? _sub;

  @override
  void initState() {
    super.initState();
    _ecouter();
  }

  @override
  void didUpdateWidget(covariant VoiceWaveform old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) _ecouter();
  }

  void _ecouter() {
    _sub?.cancel();
    _sub = widget.controller.amplitudeStream.listen((amp) {
      if (!mounted || widget.paused) return;
      // `current` est en dBFS négatif. Recalibré sur des mesures réelles de
      // micro d'ordinateur portable (silence ≈ -60/-65 dB, voix ≈ -35/-15 dB).
      final normalise = ((amp.current + 65) / 50).clamp(0.0, 1.0);
      setState(() {
        _niveaux.removeAt(0);
        _niveaux.add(normalise);
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _niveaux.map((niveau) {
          final h = 4.0 + niveau * 20.0;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            width: 2.5,
            height: h,
            decoration: BoxDecoration(color: widget.couleur.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(2)),
          );
        }).toList(),
      ),
    );
  }
}
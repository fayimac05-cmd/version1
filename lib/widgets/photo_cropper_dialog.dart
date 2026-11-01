import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Fenêtre de cadrage d'une photo AVANT envoi : l'utilisateur déplace et zoome
/// l'image dans un cadre (rond pour un avatar, rectangulaire pour une
/// couverture), puis valide. Retourne l'image recadrée (PNG) ou null si annulé.
/// Aucune dépendance externe : fonctionne sur le web et sur mobile.
class PhotoCropperDialog extends StatefulWidget {
  const PhotoCropperDialog({
    super.key,
    required this.bytes,
    required this.aspectRatio,
    required this.title,
    this.circle = false,
    this.outputWidth = 800,
  });

  final Uint8List bytes;
  final double aspectRatio; // largeur / hauteur du cadre
  final String title;
  final bool circle;
  final int outputWidth; // largeur en pixels de l'image produite

  static Future<Uint8List?> show(
    BuildContext context, {
    required Uint8List bytes,
    required double aspectRatio,
    required String title,
    bool circle = false,
    int outputWidth = 800,
  }) {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PhotoCropperDialog(
        bytes: bytes,
        aspectRatio: aspectRatio,
        title: title,
        circle: circle,
        outputWidth: outputWidth,
      ),
    );
  }

  @override
  State<PhotoCropperDialog> createState() => _PhotoCropperDialogState();
}

class _PhotoCropperDialogState extends State<PhotoCropperDialog> {
  final TransformationController _ctrl = TransformationController();
  final GlobalKey _captureKey = GlobalKey();
  Size? _imgSize;
  bool _busy = false;
  bool _initialise = false;

  @override
  void initState() {
    super.initState();
    _lireTaille();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _lireTaille() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.bytes);
      final frame = await codec.getNextFrame();
      final s = Size(frame.image.width.toDouble(), frame.image.height.toDouble());
      frame.image.dispose();
      if (mounted) setState(() => _imgSize = s);
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _valider(double frameW) async {
    setState(() => _busy = true);
    try {
      final boundary = _captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: widget.outputWidth / frameW);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted) return;
      Navigator.of(context).pop(data?.buffer.asUint8List());
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final largeurEcran = MediaQuery.of(context).size.width;
    final frameW = (largeurEcran - 64).clamp(240.0, widget.circle ? 340.0 : 520.0);
    final frameH = frameW / widget.aspectRatio;

    Widget zone;
    if (_imgSize == null) {
      zone = SizedBox(width: frameW, height: frameH, child: const Center(child: CircularProgressIndicator()));
    } else {
      // Taille de l'image qui recouvre tout le cadre (comme BoxFit.cover).
      final scale = (frameW / _imgSize!.width) > (frameH / _imgSize!.height)
          ? frameW / _imgSize!.width
          : frameH / _imgSize!.height;
      final coverW = _imgSize!.width * scale;
      final coverH = _imgSize!.height * scale;
      if (!_initialise) {
        // Image centrée au départ.
        _ctrl.value = Matrix4.translationValues(-(coverW - frameW) / 2, -(coverH - frameH) / 2, 0);
        _initialise = true;
      }
      zone = SizedBox(
        width: frameW,
        height: frameH,
        child: Stack(children: [
          RepaintBoundary(
            key: _captureKey,
            child: ClipRect(
              child: InteractiveViewer(
                transformationController: _ctrl,
                constrained: false,
                minScale: 1,
                maxScale: 6,
                boundaryMargin: EdgeInsets.zero,
                child: SizedBox(
                  width: coverW,
                  height: coverH,
                  child: Image.memory(widget.bytes, fit: BoxFit.fill, gaplessPlayback: true),
                ),
              ),
            ),
          ),
          // Repère visuel (non capturé) : assombrit l'extérieur du cercle, ou encadre le rectangle.
          IgnorePointer(child: CustomPaint(size: Size(frameW, frameH), painter: _MasquePainter(widget.circle))),
        ]),
      );
    }

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 6),
          const Text(
            'Glissez pour cadrer, pincez ou utilisez la molette pour zoomer.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          ClipRRect(borderRadius: BorderRadius.circular(widget.circle ? 0 : 12), child: zone),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: (_busy || _imgSize == null) ? null : () => _valider(frameW),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Valider', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _MasquePainter extends CustomPainter {
  _MasquePainter(this.circle);
  final bool circle;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (circle) {
      final path = Path()
        ..addRect(rect)
        ..addOval(Rect.fromCircle(center: rect.center, radius: size.shortestSide / 2))
        ..fillType = PathFillType.evenOdd;
      canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.55));
      canvas.drawCircle(rect.center, size.shortestSide / 2,
          Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white);
    } else {
      canvas.drawRect(rect.deflate(1), Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white70);
    }
  }

  @override
  bool shouldRepaint(covariant _MasquePainter old) => old.circle != circle;
}

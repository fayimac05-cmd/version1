import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ════════════════════════════════════════════════════════════════════════
// GLISSER POUR RÉPONDRE — façon WhatsApp
// On tire un message vers la droite : une icône « répondre » apparaît, et au
// bon seuil (petite vibration) le message est cité dans la zone de saisie.
// S'utilise en enveloppant la bulle :
//   SwipeToReply(onReply: () => _repondreA(msg), child: bulle)
// ════════════════════════════════════════════════════════════════════════
class SwipeToReply extends StatefulWidget {
  const SwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onReply;

  /// Désactivé (ex. mode sélection de messages) : la bulle ne bouge pas.
  final bool enabled;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> with SingleTickerProviderStateMixin {
  static const double _seuil = 64;
  static const double _max = 84;

  double _decalage = 0;
  bool _declenche = false;
  late final AnimationController _retour =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
  Animation<double>? _anim;

  @override
  void dispose() {
    _retour.dispose();
    super.dispose();
  }

  void _maj(DragUpdateDetails d) {
    if (!widget.enabled) return;
    _retour.stop();
    setState(() {
      _decalage = (_decalage + d.delta.dx).clamp(0.0, _max);
      if (_decalage >= _seuil && !_declenche) {
        _declenche = true;
        HapticFeedback.mediumImpact();
      } else if (_decalage < _seuil) {
        _declenche = false;
      }
    });
  }

  void _fin(DragEndDetails d) {
    if (!widget.enabled) return;
    if (_declenche) widget.onReply();
    _declenche = false;
    final depart = _decalage;
    _anim = Tween<double>(begin: depart, end: 0)
        .animate(CurvedAnimation(parent: _retour, curve: Curves.easeOut))
      ..addListener(() => setState(() => _decalage = _anim!.value));
    _retour.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final progres = (_decalage / _seuil).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _maj,
      onHorizontalDragEnd: _fin,
      onHorizontalDragCancel: () => _fin(DragEndDetails()),
      child: Stack(children: [
        if (_decalage > 6)
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 8 + (_decalage * 0.15)),
                child: Opacity(
                  opacity: progres,
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * progres,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF64748B).withValues(alpha: _declenche ? 0.28 : 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.reply_rounded, size: 19, color: Color(0xFF475569)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Transform.translate(offset: Offset(_decalage, 0), child: widget.child),
      ]),
    );
  }
}

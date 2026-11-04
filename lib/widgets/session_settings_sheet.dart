import 'package:flutter/material.dart';
import '../services/session_service.dart';

/// Fenêtre « Session et sécurité » : l'utilisateur choisit combien de temps
/// il reste connecté sur cet appareil.
Future<void> showSessionSettings(BuildContext context, {required String role}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => _SessionSheet(role: role),
  );
}

class _SessionSheet extends StatefulWidget {
  const _SessionSheet({required this.role});
  final String role;
  @override
  State<_SessionSheet> createState() => _SessionSheetState();
}

class _SessionSheetState extends State<_SessionSheet> {
  SessionMode? _mode;

  @override
  void initState() {
    super.initState();
    SessionService.mode(widget.role).then((m) {
      if (mounted) setState(() => _mode = m);
    });
  }

  Future<void> _choisir(SessionMode m) async {
    setState(() => _mode = m);
    await SessionService.definirMode(m);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Préférence enregistrée sur cet appareil.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = SessionService.choix(widget.role);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Session et sécurité',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            const Text('Choisissez combien de temps vous restez connecté sur cet appareil.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
            const SizedBox(height: 10),
            if (_mode == null)
              const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
            else
              for (final m in options)
                RadioListTile<SessionMode>(
                  value: m,
                  groupValue: _mode,
                  onChanged: (v) => v == null ? null : _choisir(v),
                  contentPadding: EdgeInsets.zero,
                  title: Text(SessionService.libelle(m), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  subtitle: Text(SessionService.description(m), style: const TextStyle(fontSize: 12)),
                ),
            const SizedBox(height: 6),
            const Text(
              'Le bouton « Se déconnecter » met toujours fin à la session. Sur un téléphone partagé, '
              'choisissez « Toujours demander » ou la déconnexion après inactivité.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

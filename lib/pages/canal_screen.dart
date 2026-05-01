import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import '../pages/admin_communications.dart';

class CanalScreen extends StatefulWidget {
  final String canal;
  final Color color;
  final IconData icon;
  final String filiereId;

  const CanalScreen({
    super.key,
    required this.canal,
    required this.color,
    required this.icon,
    this.filiereId = '',
  });

  @override
  State<CanalScreen> createState() => _CanalScreenState();
}

class _CanalScreenState extends State<CanalScreen> {
  final Map<int, String> _reactions = {};

  List<Map<String, dynamic>> get _messages {
    if (widget.canal == 'Administration') {
      final annonces = adminAnnonces.where((a) =>
          a.cible == 'tous' ||
          a.cible == 'filiere:${widget.filiereId}').toList();

      final result = <Map<String, dynamic>>[];
      for (final a in annonces) {
        // Message texte principal
        result.add({
          'auteur': a.auteur,
          'initiales': a.auteur.length >= 2
              ? a.auteur.substring(0, 2).toUpperCase() : 'AD',
          'heure': '',
          'date': a.date,
          'texte': '${a.titre}\n\n${a.contenu}',
          'type': 'texte',
          'color': AppPalette.blue,
        });
        // Fichiers joints
        for (final f in a.fichiers) {
          result.add({
            'auteur': a.auteur,
            'initiales': a.auteur.length >= 2
                ? a.auteur.substring(0, 2).toUpperCase() : 'AD',
            'heure': '',
            'date': a.date,
            'texte': f.nom,
            'type': f.type,
            'detail': 'Télécharger',
            'color': AppPalette.blue,
            'fichierColor': f.color,
            'fichierIcon': f.icon,
          });
        }
      }
      return result;
    } else {
      return [
        {
          'auteur': 'BDE — Aïcha S.', 'initiales': 'AS',
          'heure': '18:30', 'date': 'Hier',
          'texte': '🎵 SOIRÉE ÉTUDIANTE — Vendredi 02 Mai 2026\n\n📍 Campus IST\n🎟️ Entrée : 500 FCFA via Orange Money\n\nVenez nombreux ! 🔥',
          'type': 'texte', 'color': const Color(0xFF7C3AED),
        },
        {
          'auteur': 'BDE — Aïcha S.', 'initiales': 'AS',
          'heure': '09:00', 'date': 'Il y a 2 jours',
          'texte': '⚽ JOURNÉE SPORTIVE — Jeudi 01 Mai\n\nFoot · Basket · Athlétisme\n📍 Terrain universitaire',
          'type': 'texte', 'color': const Color(0xFF7C3AED),
        },
      ];
    }
  }

  void _afficherPickerEmoji(int index) {
    const emojis = ['❤️', '👍', '😂', '😮', '😢', '🙏'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Réagir au message',
              style: TextStyle(fontSize: 15, color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: emojis.map((e) => GestureDetector(
              onTap: () {
                setState(() => _reactions[index] = e);
                Navigator.of(context).pop();
              },
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(e, style: const TextStyle(fontSize: 28))),
              ),
            )).toList(),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.canal,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    letterSpacing: -0.2)),
            const Text('Lecture seule — réactions uniquement',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${messages.length} msg',
                style: const TextStyle(fontSize: 12, color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(children: [
        // Bandeau info
        Container(
          color: widget.color.withOpacity(0.08),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(children: [
            Icon(Icons.lock_outline, size: 16, color: widget.color),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Canal en lecture seule. Appuyez longuement sur un message pour réagir.',
              style: TextStyle(fontSize: 13, color: widget.color,
                  fontWeight: FontWeight.w500),
            )),
          ]),
        ),

        // Liste messages
        Expanded(
          child: messages.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.campaign_outlined, size: 48,
                      color: widget.color.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  const Text('Aucune annonce pour le moment.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final showDate = i == 0 || messages[i - 1]['date'] != msg['date'];
                    return Column(children: [
                      if (showDate) _dateLabel(msg['date']),
                      _bubble(msg, i),
                    ]);
                  },
                ),
        ),
      ]),
    );
  }

  Widget _dateLabel(String date) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(date, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B),
          fontWeight: FontWeight.w500)),
    )),
  );

  Widget _bubble(Map<String, dynamic> msg, int index) {
    final color = msg['color'] as Color;
    final isFichier = ['pdf', 'word', 'image', 'audio'].contains(msg['type']);

    return GestureDetector(
      onLongPress: () => _afficherPickerEmoji(index),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(child: Text(msg['initiales'],
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                    color: Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Auteur + heure
            Row(children: [
              Text(msg['auteur'],
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
              if ((msg['heure'] as String).isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(msg['heure'],
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ]),
            const SizedBox(height: 5),
            // Bulle
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                    blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: isFichier
                  ? Row(children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: (msg['fichierColor'] as Color? ?? AppPalette.blue)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          msg['fichierIcon'] as IconData? ?? Icons.attach_file,
                          color: msg['fichierColor'] as Color? ?? AppPalette.blue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(msg['texte'], style: const TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                          const SizedBox(height: 4),
                          Text(msg['detail'] ?? '',
                              style: const TextStyle(fontSize: 12,
                                  color: Color(0xFF64748B))),
                        ],
                      )),
                      Icon(Icons.download_rounded,
                          color: msg['fichierColor'] as Color? ?? AppPalette.blue,
                          size: 22),
                    ])
                  : Text(msg['texte'], style: const TextStyle(fontSize: 15,
                      color: Color(0xFF0F172A), height: 1.55)),
            ),
            // Réaction
            if (_reactions.containsKey(index))
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                        blurRadius: 4)],
                  ),
                  child: Text(_reactions[index]!,
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
          ])),
        ]),
      ),
    );
  }
}

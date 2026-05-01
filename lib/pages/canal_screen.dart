import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class CanalScreen extends StatefulWidget {
  final String canal;
  final Color color;
  final IconData icon;

  const CanalScreen({super.key, required this.canal, required this.color, required this.icon});

  @override
  State<CanalScreen> createState() => _CanalScreenState();
}

class _CanalScreenState extends State<CanalScreen> {
  final Map<int, String> _reactions = {};

  List<Map<String, dynamic>> get _messages {
    if (widget.canal == 'Administration') {
      return [
        {'auteur': 'Dir. Pédagogique', 'initiales': 'DP', 'heure': '13:16', 'date': 'Aujourd\'hui',
          'texte': 'Bonjour à tous.\n\nMerci de recevoir votre nouveau programme.\n\nIST/UBS POUR L\'EXCELLENCE 🎓\nIci c\'est plus qu\'une école 💯',
          'type': 'texte', 'color': AppPalette.blue},
        {'auteur': 'Dir. Pédagogique', 'initiales': 'DP', 'heure': '13:16', 'date': 'Aujourd\'hui',
          'texte': 'PROGRAMME ST2 DU 27 04 2026.pdf', 'type': 'pdf',
          'detail': '7 pages • PDF • 264 Ko', 'color': AppPalette.blue},
        {'auteur': 'Scolarité', 'initiales': 'SC', 'heure': '10:30', 'date': 'Aujourd\'hui',
          'texte': 'Les inscriptions pédagogiques pour le Semestre 4 sont ouvertes jusqu\'au 05 Mai 2026. Tous les étudiants sont priés de se régulariser avant cette date.',
          'type': 'texte', 'color': Color(0xFF0891B2)},
        {'auteur': 'Dir. Pédagogique', 'initiales': 'DP', 'heure': '08:00', 'date': 'Hier',
          'texte': 'Rappel : La bibliothèque est ouverte de 8h à 20h du lundi au samedi.',
          'type': 'texte', 'color': AppPalette.blue},
      ];
    } else {
      return [
        {'auteur': 'BDE — Aïcha S.', 'initiales': 'AS', 'heure': '18:30', 'date': 'Hier',
          'texte': '🎵 SOIRÉE ÉTUDIANTE — Vendredi 02 Mai 2026\n\n📍 Campus IST\n🎟️ Entrée : 500 FCFA via Orange Money\n\nVenez nombreux ! 🔥',
          'type': 'texte', 'color': Color(0xFF7C3AED)},
        {'auteur': 'BDE — Aïcha S.', 'initiales': 'AS', 'heure': '09:00', 'date': 'Il y a 2 jours',
          'texte': '⚽ JOURNÉE SPORTIVE — Jeudi 01 Mai\n\nFoot · Basket · Athlétisme\n📍 Terrain universitaire',
          'type': 'texte', 'color': Color(0xFF7C3AED)},
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24)]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Réagir au message',
              style: TextStyle(fontSize: 15, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: emojis.map((e) => GestureDetector(
                onTap: () { setState(() => _reactions[index] = e); Navigator.of(context).pop(); },
                child: Container(width: 52, height: 52,
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Text(e, style: const TextStyle(fontSize: 28)))),
              )).toList()),
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
        backgroundColor: widget.color, foregroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.of(context).pop()),
        title: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(widget.icon, color: Colors.white, size: 20)),
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
          Container(margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: Text('${messages.length} msg',
                  style: const TextStyle(fontSize: 12, color: Colors.white,
                      fontWeight: FontWeight.w600))),
        ],
      ),
      body: Column(children: [
        Container(
          color: widget.color.withOpacity(0.08),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(children: [
            Icon(Icons.lock_outline, size: 16, color: widget.color),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Canal en lecture seule. Appuyez longuement sur un message pour réagir.',
              style: TextStyle(fontSize: 13, color: widget.color, fontWeight: FontWeight.w500),
            )),
          ]),
        ),
        Expanded(child: ListView.builder(
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
        )),
      ]),
    );
  }

  Widget _dateLabel(String date) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(20)),
      child: Text(date, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B),
          fontWeight: FontWeight.w500)),
    )),
  );

  Widget _bubble(Map<String, dynamic> msg, int index) {
    final color = msg['color'] as Color;
    final isPDF = msg['type'] == 'pdf';
    return GestureDetector(
      onLongPress: () => _afficherPickerEmoji(index),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 42, height: 42,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(child: Text(msg['initiales'],
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                      color: Colors.white)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(msg['auteur'],
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 8),
              Text(msg['heure'],
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ]),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16), bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                    blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: isPDF
                  ? Row(children: [
                      Container(width: 50, height: 50,
                          decoration: BoxDecoration(color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.picture_as_pdf_rounded, color: color, size: 28)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(msg['texte'], style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        Text(msg['detail'], style: const TextStyle(fontSize: 12,
                            color: Color(0xFF64748B))),
                      ])),
                      Icon(Icons.download_rounded, color: color, size: 22),
                    ])
                  : Text(msg['texte'], style: const TextStyle(fontSize: 15,
                      color: Color(0xFF0F172A), height: 1.55)),
            ),
            if (_reactions.containsKey(index))
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]),
                  child: Text(_reactions[index]!, style: const TextStyle(fontSize: 18)),
                ),
              ),
          ])),
        ]),
      ),
    );
  }
}

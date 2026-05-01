import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class NotesTab extends StatelessWidget {
  const NotesTab({super.key});

  @override
  Widget build(BuildContext context) {
    const notes = [
      _NoteItem(
        code: 'INFO101',
        matiere: 'Algorithmique',
        cc: '14.00',
        tp: '15.00',
        exam: '16.00',
        moyenne: '15.10',
      ),
      _NoteItem(
        code: 'INFO102',
        matiere: 'Bases de Donnees',
        cc: '12.00',
        tp: '13.00',
        exam: '14.00',
        moyenne: '13.10',
      ),
      _NoteItem(
        code: 'MATH201',
        matiere: 'Maths Discretes',
        cc: '11.00',
        tp: '—',
        exam: '13.00',
        moyenne: '12.20',
      ),
      _NoteItem(
        code: 'ANG101',
        matiere: 'Anglais Technique',
        cc: '16.00',
        tp: '—',
        exam: '17.00',
        moyenne: '16.60',
      ),
    ];

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppPalette.blue,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
          child: Column(
            children: [
              Text(
                'Notes',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppPalette.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Moyenne generale',
                style: TextStyle(color: AppPalette.white),
              ),
              const SizedBox(height: 6),
              const Text(
                '14.25 / 20',
                style: TextStyle(
                  color: AppPalette.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                '2024-2025',
                style: TextStyle(color: AppPalette.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 6, bottom: 10),
                child: Text(
                  'SEMESTRE 3',
                  style: TextStyle(
                    color: Colors.black54,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...notes.map((note) => _noteCard(note)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _noteCard(_NoteItem note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppPalette.blue.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                note.code,
                style: const TextStyle(
                  color: AppPalette.blue,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.softYellow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Valide',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          Text(
            note.matiere,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 34),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _scoreBox('CC', note.cc),
              _scoreBox('TP', note.tp),
              _scoreBox('Exam', note.exam),
              _scoreBox('Moy.', note.moyenne, highlighted: true),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Semestre 3', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _scoreBox(String title, String value, {bool highlighted = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: highlighted ? AppPalette.softYellow : const Color(0xFFF4F6FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: highlighted ? AppPalette.blue : AppPalette.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteItem {
  const _NoteItem({
    required this.code,
    required this.matiere,
    required this.cc,
    required this.tp,
    required this.exam,
    required this.moyenne,
  });

  final String code;
  final String matiere;
  final String cc;
  final String tp;
  final String exam;
  final String moyenne;
}

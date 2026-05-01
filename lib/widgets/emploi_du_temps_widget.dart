import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import '../pages/pdf_viewer_screen.dart';

class EmploiDuTempsWidget extends StatelessWidget {
  const EmploiDuTempsWidget({super.key});

  static const List<Map<String, dynamic>> pdfs = [
    {
      'domaine': 'Sciences & Technologies (ST)',
      'sigle':   'ST',
      'fichier': 'PROGRAMME ST2 DU 27 04 2026.pdf',
      'pages':   '7 pages',
      'taille':  '264 Ko',
      'date':    '27 Avr 2026',
      'color':   Color(0xFF0891B2),
    },
    {
      'domaine': 'Sciences & Gestion (SG)',
      'sigle':   'SG',
      'fichier': 'PROGRAMME SG L2 SUIVIE 27 04 2026.pdf',
      'pages':   '5 pages',
      'taille':  '198 Ko',
      'date':    '27 Avr 2026',
      'color':   Color(0xFF15803D),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(children: pdfs.map((pdf) => _PdfCard(pdf: pdf)).toList());
  }
}

class _PdfCard extends StatelessWidget {
  final Map<String, dynamic> pdf;
  const _PdfCard({required this.pdf});

  @override
  Widget build(BuildContext context) {
    final color = pdf['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.picture_as_pdf_rounded, color: color, size: 28),
              const SizedBox(height: 2),
              Text(pdf['sigle'],
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(pdf['domaine'],
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 7),
            Text(pdf['fichier'],
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 5),
            Row(children: [
              const Icon(Icons.insert_drive_file_outlined, size: 13, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text('${pdf['pages']} • ${pdf['taille']}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(width: 10),
              const Icon(Icons.calendar_today, size: 13, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(pdf['date'],
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ]),
          ])),
          const SizedBox(width: 12),
          Column(children: [
            // Ouvrir
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PdfViewerScreen(pdf: pdf),
              )),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.3),
                        blurRadius: 8, offset: const Offset(0, 3))]),
                child: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(height: 8),
            // Télécharger
            GestureDetector(
              onTap: () => showDialog(context: context, barrierDismissible: false,
                  builder: (_) => _DownloadDialog(pdf: pdf)),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.35)),
                ),
                child: Icon(Icons.download_rounded, color: color, size: 20),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _DownloadDialog extends StatefulWidget {
  final Map<String, dynamic> pdf;
  const _DownloadDialog({required this.pdf});

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  double _progress = 0;
  bool _done = false;

  @override
  void initState() { super.initState(); _simuler(); }

  Future<void> _simuler() async {
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      setState(() => _progress = i / 10);
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _done = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.pdf['color'] as Color;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _done
                ? Container(key: const ValueKey('done'), width: 72, height: 72,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1DB954)),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 40))
                : Container(key: const ValueKey('load'), width: 72, height: 72,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1)),
                    child: Padding(padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(value: _progress, color: color, strokeWidth: 4))),
          ),
          const SizedBox(height: 20),
          Text(_done ? 'Téléchargé !' : 'Téléchargement en cours...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: _done ? const Color(0xFF15803D) : const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text(widget.pdf['fichier'], style: const TextStyle(fontSize: 14,
              color: Color(0xFF64748B), height: 1.4), textAlign: TextAlign.center),
          if (_done) ...[
            const SizedBox(height: 10),
            const Text('Enregistré dans vos dossiers',
                style: TextStyle(fontSize: 14, color: Color(0xFF1DB954), fontWeight: FontWeight.w700)),
          ],
          if (!_done) ...[
            const SizedBox(height: 20),
            ClipRRect(borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: _progress,
                    backgroundColor: const Color(0xFFE2E8F0), color: color, minHeight: 7)),
            const SizedBox(height: 10),
            Text('${(_progress * 100).toInt()}%',
                style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)),
          ],
        ]),
      ),
    );
  }
}

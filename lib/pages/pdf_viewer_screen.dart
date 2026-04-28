import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class PdfViewerScreen extends StatelessWidget {
  final Map<String, dynamic> pdf;
  const PdfViewerScreen({super.key, required this.pdf});

  @override
  Widget build(BuildContext context) {
    final color = pdf['color'] as Color;
    final sigle = pdf['sigle'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('$sigle — Emploi du temps',
            style: const TextStyle(fontSize: 17,
                fontWeight: FontWeight.bold, letterSpacing: -0.2)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.download_rounded, size: 26),
              onPressed: () => showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => _DownloadDialog(pdf: pdf),
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [

        // Bandeau fichier
        Container(
          color: color.withOpacity(0.12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(children: [
            Icon(Icons.picture_as_pdf_rounded, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(pdf['fichier'],
                style: TextStyle(fontSize: 14, color: color,
                    fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('${pdf['pages']} • ${pdf['taille']}',
                  style: const TextStyle(fontSize: 12, color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),

        // Tableau programme
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: _Tableau(sigle: sigle, color: color),
        )),

        // Bouton télécharger
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => _DownloadDialog(pdf: pdf),
              ),
              icon: const Icon(Icons.download_rounded, size: 22),
              label: const Text('Télécharger dans mes dossiers',
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.bold, letterSpacing: 0.2)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Tableau programme ──────────────────────────────────────────────────────
class _Tableau extends StatelessWidget {
  final String sigle;
  final Color color;
  const _Tableau({required this.sigle, required this.color});

  Map<String, String> get _data => sigle == 'ST' ? {
    'MERCREDI-07H30-10H30': 'Devoir\nLabo Analyses\nMédicales\n9H-12H',
    'MERCREDI-10H30-12H30': 'Devoir\nLabo Analyses\nMédicales\n9H-12H',
    'SAMEDI-07H30-10H30':   'VISITE\nHOPITAL\nZINIARE',
    'SAMEDI-10H30-12H30':   'VISITE\nHOPITAL\nZINIARE',
  } : {
    'LUNDI-07H30-10H30':  'Comptabilité\nGénérale\nSalle A01',
    'LUNDI-10H30-12H30':  'Droit\nCommercial\nSalle B03',
    'MARDI-07H30-10H30':  'Gestion\nSalle C02',
    'JEUDI-14H00-18H00':  'Fiscalité\nSalle A04',
  };

  @override
  Widget build(BuildContext context) {
    const jours    = ['LUNDI','MARDI','MERCREDI','JEUDI','VENDREDI','SAMEDI'];
    const horaires = ['07H30-10H30','10H30-12H30','PAUSE','14H00-18H00'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // En-tête tableau
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16), topRight: Radius.circular(16),
            ),
          ),
          child: Column(children: [
            const Text('SEMAINE DU 27 AU 02 AVRIL 2026',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                    color: Colors.white, letterSpacing: 0.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 5),
            Text('PROGRAMME $sigle — ANNÉE ACADÉMIQUE 2025-2026',
                style: const TextStyle(fontSize: 11, color: Colors.white70,
                    letterSpacing: 0.3),
                textAlign: TextAlign.center),
          ]),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: const Color(0xFFE2E8F0), width: 0.5),
            defaultColumnWidth: const FixedColumnWidth(95),
            children: [
              // En-tête jours
              TableRow(
                decoration: BoxDecoration(color: color.withOpacity(0.12)),
                children: ['HORAIRES', ...jours].map((j) => TableCell(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(j, style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.bold, color: color),
                        textAlign: TextAlign.center),
                  ),
                )).toList(),
              ),
              // Lignes horaires
              ...horaires.map((h) {
                if (h == 'PAUSE') {
                  return TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFE5E7EB)),
                    children: List.generate(7, (_) => TableCell(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: const Text('PAUSE',
                            style: TextStyle(fontSize: 10,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center),
                      ),
                    )),
                  );
                }
                return TableRow(children: [
                  // Colonne horaire
                  TableCell(child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    color: color.withOpacity(0.06),
                    child: Text(h, style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w700, color: color),
                        textAlign: TextAlign.center),
                  )),
                  // Colonnes jours
                  ...jours.map((j) {
                    final content = _data['$j-$h'];
                    return TableCell(child: Container(
                      height: 85,
                      padding: const EdgeInsets.all(5),
                      color: content != null
                          ? const Color(0xFFFBBF24).withOpacity(0.28)
                          : Colors.white,
                      child: content != null
                          ? Text(content,
                              style: const TextStyle(fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A), height: 1.4),
                              textAlign: TextAlign.center)
                          : const SizedBox(),
                    ));
                  }),
                ]);
              }),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Dialog téléchargement ──────────────────────────────────────────────────
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
                ? Container(key: const ValueKey('d'), width: 72, height: 72,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xFF1DB954)),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 40))
                : Container(key: const ValueKey('l'), width: 72, height: 72,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: color.withOpacity(0.1)),
                    child: Padding(padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            value: _progress, color: color, strokeWidth: 4))),
          ),
          const SizedBox(height: 20),
          Text(_done ? 'Téléchargé !' : 'Téléchargement en cours...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: _done ? const Color(0xFF15803D) : const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text(widget.pdf['fichier'],
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B),
                  height: 1.4),
              textAlign: TextAlign.center),
          if (_done) ...[
            const SizedBox(height: 10),
            const Text('Enregistré dans vos dossiers',
                style: TextStyle(fontSize: 14, color: Color(0xFF1DB954),
                    fontWeight: FontWeight.w700)),
          ],
          if (!_done) ...[
            const SizedBox(height: 20),
            ClipRRect(borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: _progress,
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: color, minHeight: 7)),
            const SizedBox(height: 10),
            Text('${(_progress * 100).toInt()}%',
                style: TextStyle(fontSize: 16, color: color,
                    fontWeight: FontWeight.bold)),
          ],
        ]),
      ),
    );
  }
}

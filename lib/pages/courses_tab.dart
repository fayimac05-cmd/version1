import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class CoursesTab extends StatefulWidget {
  const CoursesTab({super.key});

  @override
  State<CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends State<CoursesTab> {
  String _moduleSelectionne = 'Tous';
  String _recherche = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<Map<String, dynamic>> _cours = [
    {'module': 'Algorithmique & Structures', 'titre': 'Chapitre 3 — Les pointeurs',
      'prof': 'Prof Ouédraogo', 'date': 'Aujourd\'hui, 09h32', 'taille': '2.4 MB',
      'nouveau': true, 'color': AppPalette.blue},
    {'module': 'Base de données', 'titre': 'Chapitre 5 — Jointures SQL',
      'prof': 'Prof Traoré', 'date': 'Hier, 14h15', 'taille': '1.8 MB',
      'nouveau': true, 'color': Color(0xFF7C3AED)},
    {'module': 'Réseaux informatiques', 'titre': 'TD 2 — Adressage IP',
      'prof': 'Prof Sawadogo', 'date': '25 Avr, 10h00', 'taille': '890 KB',
      'nouveau': false, 'color': Color(0xFF0891B2)},
    {'module': 'Algorithmique & Structures', 'titre': 'Chapitre 2 — Récursivité',
      'prof': 'Prof Ouédraogo', 'date': '24 Avr, 16h45', 'taille': '3.1 MB',
      'nouveau': false, 'color': AppPalette.blue},
    {'module': 'Mathématiques discrètes', 'titre': 'Cours 4 — Théorie des graphes',
      'prof': 'Prof Kaboré', 'date': '23 Avr, 11h20', 'taille': '4.2 MB',
      'nouveau': false, 'color': Color(0xFF15803D)},
    {'module': 'Anglais technique', 'titre': 'Vocabulary — IT Terms',
      'prof': 'Prof Johnson', 'date': '22 Avr, 08h00', 'taille': '1.1 MB',
      'nouveau': false, 'color': Color(0xFFD97706)},
  ];

  List<String> get _modules {
    final mods = _cours.map((c) => c['module'] as String).toSet().toList();
    mods.sort();
    return ['Tous', ...mods];
  }

  List<Map<String, dynamic>> get _filtered => _cours.where((c) {
    final matchMod = _moduleSelectionne == 'Tous' || c['module'] == _moduleSelectionne;
    final matchQ   = _recherche.isEmpty ||
        (c['titre']  as String).toLowerCase().contains(_recherche.toLowerCase()) ||
        (c['module'] as String).toLowerCase().contains(_recherche.toLowerCase()) ||
        (c['prof']   as String).toLowerCase().contains(_recherche.toLowerCase());
    return matchMod && matchQ;
  }).toList();

  int get _nbNouveaux => _cours.where((c) => c['nouveau'] == true).length;

  void _telecharger(Map<String, dynamic> cours) {
    showDialog(context: context, barrierDismissible: false,
        builder: (_) => _DownloadDialog(cours: cours));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(children: [

      // ── Header ─────────────────────────────────────────────────────
      Container(
        color: AppPalette.white,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 48, height: 48,
                decoration: BoxDecoration(color: AppPalette.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.menu_book_rounded, color: AppPalette.blue, size: 26)),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mes Cours', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                  color: Color(0xFF121212), letterSpacing: -0.3)),
              SizedBox(height: 2),
              Text('Licence Informatique L2',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            ])),
            if (_nbNouveaux > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1DB954).withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.fiber_new_rounded, color: Color(0xFF15803D), size: 18),
                  const SizedBox(width: 5),
                  Text('$_nbNouveaux nouveau${_nbNouveaux > 1 ? 'x' : ''}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF15803D),
                          fontWeight: FontWeight.w700)),
                ]),
              ),
          ]),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0))),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _recherche = v),
              style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'Rechercher un cours, module, prof...',
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 22),
                suffixIcon: _recherche.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                        onPressed: () { _searchCtrl.clear(); setState(() => _recherche = ''); })
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),

      // ── Filtres ─────────────────────────────────────────────────────
      Container(
        color: AppPalette.white,
        padding: const EdgeInsets.only(bottom: 14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: _modules.map((mod) {
            final selected = _moduleSelectionne == mod;
            final color = mod == 'Tous' ? AppPalette.blue
                : (_cours.firstWhere((c) => c['module'] == mod,
                    orElse: () => {'color': AppPalette.blue})['color'] as Color);
            return GestureDetector(
              onTap: () => setState(() => _moduleSelectionne = mod),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? color : AppPalette.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: selected ? color : const Color(0xFFE2E8F0), width: 1.5),
                  boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.25),
                      blurRadius: 8, offset: const Offset(0, 2))] : [],
                ),
                child: Text(
                  mod == 'Tous' ? 'Tous  ${_cours.length}' :
                  mod.length > 14 ? '${mod.substring(0, 14)}…' : mod,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : const Color(0xFF64748B)),
                ),
              ),
            );
          }).toList()),
        ),
      ),

      Container(height: 1, color: const Color(0xFFE2E8F0)),

      // ── Liste ───────────────────────────────────────────────────────
      Expanded(
        child: filtered.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.search_off_rounded, size: 70,
                    color: const Color(0xFF64748B).withOpacity(0.35)),
                const SizedBox(height: 16),
                const Text('Aucun cours trouvé', style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              ]))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _coursCard(filtered[i]),
              ),
      ),
    ]);
  }

  Widget _coursCard(Map<String, dynamic> cours) {
    final color = cours['color'] as Color;
    final isNew = cours['nouveau'] as bool;
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isNew ? color.withOpacity(0.4) : const Color(0xFFE2E8F0),
            width: isNew ? 1.5 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Container(width: 58, height: 58,
            decoration: BoxDecoration(color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14)),
            child: Stack(children: [
              Center(child: Icon(Icons.picture_as_pdf_rounded, color: color, size: 32)),
              if (isNew) Positioned(top: 4, right: 4, child: Container(
                  width: 11, height: 11,
                  decoration: const BoxDecoration(color: Color(0xFF1DB954),
                      shape: BoxShape.circle))),
            ])),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(cours['module'], style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w700, color: color),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(height: 7),
          Text(cours['titre'], style: const TextStyle(fontSize: 15,
              fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 7),
          Row(children: [
            const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 4),
            Flexible(child: Text(cours['prof'],
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 10),
            const Icon(Icons.access_time, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 4),
            Flexible(child: Text(cours['date'],
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                overflow: TextOverflow.ellipsis)),
          ]),
        ])),
        const SizedBox(width: 12),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(
            onTap: () => _telecharger(cours),
            child: Container(width: 46, height: 46,
                decoration: BoxDecoration(color: color,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.35),
                        blurRadius: 8, offset: const Offset(0, 3))]),
                child: const Icon(Icons.download_rounded, color: Colors.white, size: 24)),
          ),
          const SizedBox(height: 5),
          Text(cours['taille'], style: const TextStyle(fontSize: 11,
              color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ]),
      ])),
    );
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }
}

class _DownloadDialog extends StatefulWidget {
  final Map<String, dynamic> cours;
  const _DownloadDialog({required this.cours});
  @override State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  double _progress = 0; bool _done = false;
  @override void initState() { super.initState(); _simuler(); }
  Future<void> _simuler() async {
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return; setState(() => _progress = i / 10);
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return; setState(() => _done = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) Navigator.of(context).pop();
  }
  @override
  Widget build(BuildContext context) {
    final color = widget.cours['color'] as Color;
    return Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedSwitcher(duration: const Duration(milliseconds: 400),
          child: _done
              ? Container(key: const ValueKey('d'), width: 72, height: 72,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1DB954)),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 40))
              : Container(key: const ValueKey('l'), width: 72, height: 72,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1)),
                  child: Padding(padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(value: _progress, color: color, strokeWidth: 4))),
        ),
        const SizedBox(height: 20),
        Text(_done ? 'Téléchargé !' : 'Téléchargement en cours...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: _done ? const Color(0xFF15803D) : const Color(0xFF0F172A))),
        const SizedBox(height: 8),
        Text(widget.cours['titre'], style: const TextStyle(fontSize: 14,
            color: Color(0xFF64748B), height: 1.4), textAlign: TextAlign.center),
        if (_done) ...[const SizedBox(height: 10),
          const Text('Enregistré dans vos dossiers',
              style: TextStyle(fontSize: 14, color: Color(0xFF1DB954), fontWeight: FontWeight.w700))],
        if (!_done) ...[const SizedBox(height: 20),
          ClipRRect(borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: _progress,
                  backgroundColor: const Color(0xFFE2E8F0), color: color, minHeight: 7)),
          const SizedBox(height: 10),
          Text('${(_progress * 100).toInt()}%',
              style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold))],
      ])),
    );
  }
}

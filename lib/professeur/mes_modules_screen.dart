import 'package:flutter/material.dart';
import '../services/professor_service.dart';
import '../theme/app_palette.dart';

/// « Mes modules » : le professeur voit les modules qui lui sont affectés et
/// peut marquer un module « Terminé » (ou le rouvrir). Quand tous ses modules
/// sont terminés, il ne reçoit plus le rappel des heures libres.
class MesModulesScreen extends StatefulWidget {
  const MesModulesScreen({super.key});
  @override
  State<MesModulesScreen> createState() => _MesModulesScreenState();
}

class _MesModulesScreenState extends State<MesModulesScreen> {
  bool _loading = true;
  String? _erreur;
  List<Map<String, dynamic>> _modules = [];
  final Set<int> _enCours = {};

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _erreur = null;
    });
    final r = await ProfessorService.getModules();
    if (!mounted) return;
    if (r['success'] != true) {
      setState(() {
        _loading = false;
        _erreur = (r['error'] ?? 'Chargement impossible.').toString();
      });
      return;
    }
    setState(() {
      _modules = (r['data'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      _loading = false;
    });
  }

  bool _fini(Map<String, dynamic> m) => m['termine'] == true;
  // « À venir » : affecté mais pas encore lancé par l'administration.
  bool _aVenir(Map<String, dynamic> m) => m['termine'] != true && m['demarre'] != true;

  Future<void> _basculer(Map<String, dynamic> m) async {
    final id = int.tryParse('${m['affectation_id']}');
    if (id == null) return;
    final terminer = !_fini(m);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(terminer ? 'Marquer comme terminé ?' : 'Rouvrir ce module ?'),
        content: Text(terminer
            ? '« ${m['nom']} » (${m['niveau']}) sera considéré comme terminé. Si tous vos modules sont terminés, vous ne recevrez plus le rappel des heures libres.'
            : '« ${m['nom']} » (${m['niveau']}) redeviendra un module en cours.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(terminer ? 'Terminé' : 'Rouvrir')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _enCours.add(id));
    final r = await ProfessorService.terminerModule(id, terminer);
    if (!mounted) return;
    setState(() => _enCours.remove(id));
    if (r['success'] == true) {
      setState(() => m['termine'] = terminer);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((r['error'] ?? 'Erreur').toString()), backgroundColor: const Color(0xFFDC2626)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final enCours = _modules.where((m) => !_fini(m) && !_aVenir(m)).length;
    final aVenir = _modules.where(_aVenir).length;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: AppPalette.blue,
        foregroundColor: Colors.white,
        title: const Text('Mes modules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        actions: [IconButton(onPressed: _charger, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
              ? Center(child: Text(_erreur!, style: const TextStyle(color: Color(0xFF991B1B))))
              : _modules.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text("Aucun module ne vous est affecté pour l'instant.",
                            textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B))),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text('$enCours en cours · $aVenir à venir · ${_modules.where(_fini).length} terminé(s)',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        for (final m in _modules) _carte(m),
                      ],
                    ),
    );
  }

  Widget _carte(Map<String, dynamic> m) {
    final fini = _fini(m);
    final aVenir = _aVenir(m);
    final id = int.tryParse('${m['affectation_id']}') ?? -1;
    final occupe = _enCours.contains(id);
    final detail = [
      if ('${m['filiere_nom'] ?? ''}'.isNotEmpty) '${m['filiere_nom']}',
      if ('${m['niveau'] ?? ''}'.isNotEmpty) '${m['niveau']}',
      if ('${m['semestre'] ?? ''}'.isNotEmpty) 'S${m['semestre']}',
      if ('${m['volume_horaire'] ?? ''}'.isNotEmpty) '${m['volume_horaire']} h',
    ].join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fini ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: fini ? const Color(0xFFD1FAE5) : AppPalette.blue.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(fini ? Icons.check_circle_rounded : Icons.menu_book_rounded,
              color: fini ? const Color(0xFF059669) : AppPalette.blue, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${m['nom'] ?? 'Module'}',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: fini ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                    decoration: fini ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 3),
            Text(detail, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
            if (aVenir)
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Text('À venir — sera lancé par l\'administration',
                    style: TextStyle(fontSize: 11, color: Color(0xFFB7791F), fontWeight: FontWeight.w700)),
              ),
          ]),
        ),
        const SizedBox(width: 8),
        occupe
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
            : aVenir
                ? const SizedBox.shrink()
                : fini
                    ? TextButton(onPressed: () => _basculer(m), child: const Text('Rouvrir'))
                    : FilledButton.tonal(onPressed: () => _basculer(m), child: const Text('Terminé')),
      ]),
    );
  }
}
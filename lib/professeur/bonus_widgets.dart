import 'package:flutter/material.dart';
import '../services/bonus_service.dart';
import '../theme/app_palette.dart';

// ════════════════════════════════════════════════════════════════════════
// BONUS DE PARTICIPATION
//  • ouvrirBonusEtudiant : ajouter / retirer les bonus d'un étudiant
//  • ouvrirBonusModule   : écran Bonus du module (tous les étudiants, total de chacun)
// Les bonus non encore utilisés s'ajoutent à la note lors de la saisie des notes.
// ════════════════════════════════════════════════════════════════════════

const Color _or = Color(0xFFD97706);

/// 0.25 → « +0,25 » ; 2 → « +2 » ; 0.5 → « +0,5 ».
String formatBonus(num v) {
  var t = v.toStringAsFixed(2);
  if (t.contains('.')) {
    t = t.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return '+${t.replaceAll('.', ',')}';
}

/// Feuille « Bonus » d'un étudiant.
Future<void> ouvrirBonusEtudiant(
  BuildContext context, {
  required String moduleId,
  required String matricule,
  required String nomComplet,
  VoidCallback? onChange,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BonusEtudiantSheet(moduleId: moduleId, matricule: matricule, nomComplet: nomComplet, onChange: onChange),
  );
}

/// Écran Bonus du module : [etudiants] = maps avec prenoms, nom, matricule
/// (et éventuellement `_moduleId` pour un tronc commun).
Future<void> ouvrirBonusModule(
  BuildContext context, {
  required String moduleId,
  required String moduleNom,
  required List<dynamic> etudiants,
  VoidCallback? onChange,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BonusModuleSheet(moduleId: moduleId, moduleNom: moduleNom, etudiants: etudiants, onChange: onChange),
  );
}

// ── Feuille d'un étudiant ────────────────────────────────────────────────
class _BonusEtudiantSheet extends StatefulWidget {
  const _BonusEtudiantSheet({required this.moduleId, required this.matricule, required this.nomComplet, this.onChange});
  final String moduleId;
  final String matricule;
  final String nomComplet;
  final VoidCallback? onChange;

  @override
  State<_BonusEtudiantSheet> createState() => _BonusEtudiantSheetState();
}

class _BonusEtudiantSheetState extends State<_BonusEtudiantSheet> {
  static const _rapides = <double>[0.25, 0.5, 1, 2, 5];
  final _valeurCtrl = TextEditingController();
  final _motifCtrl = TextEditingController();
  List<dynamic> _items = [];
  double _total = 0;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _valeurCtrl.dispose();
    _motifCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final res = await BonusService.parModule(widget.moduleId);
    if (!mounted) return;
    final d = res['success'] == true ? (res['data'] as Map<String, dynamic>)[widget.matricule] : null;
    setState(() {
      _items = d == null ? [] : List<dynamic>.from(d['items'] as List);
      _total = d == null ? 0 : ((d['total'] as num?)?.toDouble() ?? 0);
      _loading = false;
    });
  }

  void _msg(String t, {bool erreur = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t), backgroundColor: erreur ? Colors.red : null));
  }

  Future<void> _ajouter(double valeur) async {
    if (_busy) return;
    setState(() => _busy = true);
    final res = await BonusService.ajouter(
      moduleId: widget.moduleId,
      matricule: widget.matricule,
      valeur: valeur,
      motif: _motifCtrl.text.trim().isEmpty ? null : _motifCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['success'] == true) {
      _valeurCtrl.clear();
      _motifCtrl.clear();
      widget.onChange?.call();
      await _charger();
    } else {
      _msg(res['error']?.toString() ?? 'Erreur.', erreur: true);
    }
  }

  void _ajouterSaisi() {
    final v = double.tryParse(_valeurCtrl.text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0 || v > 20) {
      _msg('Entrez un bonus entre 0,01 et 20 (ex. 0,5).', erreur: true);
      return;
    }
    _ajouter(v);
  }

  Future<void> _supprimer(dynamic item) async {
    final res = await BonusService.supprimer(item['id'].toString());
    if (!mounted) return;
    if (res['success'] == true) {
      widget.onChange?.call();
      await _charger();
    } else {
      _msg(res['error']?.toString() ?? 'Erreur.', erreur: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Row(children: [
              const Icon(Icons.star_rounded, color: _or),
              const SizedBox(width: 8),
              Expanded(child: Text('Bonus — ${widget.nomComplet}',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _or.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(_total > 0 ? formatBonus(_total) : '0',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _or)),
              ),
            ]),
            const SizedBox(height: 4),
            const Text('Ajouté à sa prochaine note de ce module (maximum 20/20).',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final v in _rapides)
                ActionChip(
                  label: Text(formatBonus(v), style: const TextStyle(fontWeight: FontWeight.w800, color: _or)),
                  backgroundColor: _or.withValues(alpha: 0.08),
                  side: BorderSide(color: _or.withValues(alpha: 0.3)),
                  onPressed: _busy ? null : () => _ajouter(v),
                ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _valeurCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Autre bonus',
                    hintText: 'ex. 1,5',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _motifCtrl,
                  decoration: InputDecoration(
                    labelText: 'Motif (facultatif)',
                    hintText: 'participation, exposé…',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: _busy ? null : _ajouterSaisi,
                style: IconButton.styleFrom(backgroundColor: AppPalette.blue),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ]),
            const SizedBox(height: 16),
            const Text('Bonus en attente', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            if (_loading)
              const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
            else if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('Aucun bonus pour le moment.', style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8))),
              )
            else
              for (final it in _items)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.star_outline_rounded, color: _or),
                  title: Text(formatBonus((it['valeur'] as num).toDouble()),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: _or)),
                  subtitle: Text(
                    [
                      if ((it['motif'] ?? '').toString().isNotEmpty) it['motif'].toString(),
                      _dateCourte(it['created_at']),
                    ].where((t) => t.isNotEmpty).join(' · '),
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                    onPressed: () => _supprimer(it),
                  ),
                ),
          ]),
        ),
      ),
    );
  }
}

String _dateCourte(dynamic iso) {
  final d = DateTime.tryParse('${iso ?? ''}');
  if (d == null) return '';
  final l = d.isUtc ? d.toLocal() : d;
  String deux(int n) => n.toString().padLeft(2, '0');
  return '${deux(l.day)}/${deux(l.month)}';
}

// ── Écran Bonus du module ────────────────────────────────────────────────
class _BonusModuleSheet extends StatefulWidget {
  const _BonusModuleSheet({required this.moduleId, required this.moduleNom, required this.etudiants, this.onChange});
  final String moduleId;
  final String moduleNom;
  final List<dynamic> etudiants;
  final VoidCallback? onChange;

  @override
  State<_BonusModuleSheet> createState() => _BonusModuleSheetState();
}

class _BonusModuleSheetState extends State<_BonusModuleSheet> {
  final Map<String, double> _totaux = {};
  bool _loading = true;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  String _moduleDe(dynamic e) => (e['_moduleId'] ?? widget.moduleId).toString();

  Future<void> _charger() async {
    final modules = widget.etudiants.map(_moduleDe).toSet();
    final totaux = <String, double>{};
    for (final m in modules) {
      final res = await BonusService.parModule(m);
      if (res['success'] == true) {
        (res['data'] as Map<String, dynamic>).forEach((mat, d) {
          totaux[mat] = ((d['total'] as num?)?.toDouble() ?? 0);
        });
      }
    }
    if (!mounted) return;
    setState(() {
      _totaux
        ..clear()
        ..addAll(totaux);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _recherche.trim().toLowerCase();
    final liste = widget.etudiants.where((e) => q.isEmpty || '${e['prenoms']} ${e['nom']}'.toLowerCase().contains(q)).toList();
    final nbAvecBonus = _totaux.values.where((v) => v > 0).length;
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Icon(Icons.star_rounded, color: _or),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Bonus du module', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                Text('${widget.moduleNom} · $nbAvecBonus étudiant(s) avec bonus',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            onChanged: (v) => setState(() => _recherche = v),
            decoration: InputDecoration(
              hintText: 'Rechercher un étudiant…',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const Divider(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: liste.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final e = liste[i];
                    final total = _totaux['${e['matricule']}'] ?? 0;
                    final nom = '${e['prenoms'] ?? ''} ${e['nom'] ?? ''}'.trim();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(nom, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (total > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: _or.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                            child: Text(formatBonus(total), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _or)),
                          ),
                        const SizedBox(width: 6),
                        const Icon(Icons.add_circle_outline_rounded, color: AppPalette.blue),
                      ]),
                      onTap: () async {
                        await ouvrirBonusEtudiant(
                          context,
                          moduleId: _moduleDe(e),
                          matricule: '${e['matricule']}',
                          nomComplet: nom,
                          onChange: widget.onChange,
                        );
                        if (mounted) _charger();
                      },
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

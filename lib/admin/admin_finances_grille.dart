// lib/admin/admin_finances_grille.dart
// Grille tarifaire : l'administration fixe, par domaine / filière / niveau,
// les frais d'inscription et de scolarité, avec leurs tranches et échéances.
import 'package:flutter/material.dart';
import '../pages/finance_ui.dart';
import '../services/api_service.dart';
import '../services/finance_service.dart';

class _Fil {
  final String id;
  final String nom;
  final String domaine;
  final List<String> niveaux;
  _Fil(this.id, this.nom, this.domaine, this.niveaux);
}

const Map<String, String> _types = {
  'inscription': "Frais d'inscription",
  'scolarite': 'Scolarité',
  'autre': 'Autre frais',
};

String _anneeSuivante(String a) {
  final m = RegExp(r'(\d{4})\D+(\d{4})').firstMatch(a);
  if (m == null) return a;
  return '${int.parse(m.group(1)!) + 1}-${int.parse(m.group(2)!) + 1}';
}

class AdminFinancesGrille extends StatefulWidget {
  final String? annee;
  final Future<void> Function(String annee) onChangeAnnee;
  const AdminFinancesGrille({super.key, required this.annee, required this.onChangeAnnee});
  @override
  State<AdminFinancesGrille> createState() => _AdminFinancesGrilleState();
}

class _AdminFinancesGrilleState extends State<AdminFinancesGrille> {
  List<Map<String, dynamic>> _grilles = [];
  List<_Fil> _filieres = [];
  bool _charge = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _recharger();
  }

  Future<void> _recharger() async {
    final res = await Future.wait([FinanceService.grilles(widget.annee), ApiService.getFilieres()]);
    if (!mounted) return;
    final r = res[0];
    final f = res[1];
    setState(() {
      _charge = false;
      if (r['success'] == true) {
        _grilles = ((r['data'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _erreur = null;
      } else {
        _erreur = '${r['message']}';
      }
      if (f['success'] == true) {
        _filieres = ((f['data'] as List?) ?? const []).map((e) {
          final j = Map<String, dynamic>.from(e as Map);
          final dom = ('${j['domaine_col'] ?? j['domaine'] ?? ''}').trim();
          return _Fil(
            '${j['id']}',
            '${j['nom'] ?? ''}',
            dom,
            ((j['niveaux'] as List?) ?? const []).map((x) => '$x').where((x) => x.trim().isNotEmpty).toList(),
          );
        }).toList();
      }
    });
  }

  String _critere(Map<String, dynamic> g) {
    final p = <String>[];
    if ('${g['domaine'] ?? ''}'.isNotEmpty) p.add('${g['domaine']}');
    if (g['filiere_id'] != null) {
      final f = _filieres.where((x) => x.id == '${g['filiere_id']}');
      p.add(f.isEmpty ? 'Filière #${g['filiere_id']}' : f.first.nom);
    }
    if ('${g['niveau'] ?? ''}'.isNotEmpty) p.add('${g['niveau']}');
    return p.isEmpty ? 'Tous les étudiants' : p.join(' · ');
  }

  Future<void> _ouvrirForm([Map<String, dynamic>? g]) async {
    final anneeEnregistree = await finFeuille<String>(
      context,
      titre: g == null ? 'Nouvelle ligne de la grille' : 'Modifier la ligne',
      contenu: (c) => _FormGrille(annee: widget.annee ?? '', filieres: _filieres, grille: g),
    );
    if (anneeEnregistree != null) {
      await _recharger();
      await widget.onChangeAnnee(anneeEnregistree);
    }
  }

  Future<void> _supprimer(Map<String, dynamic> g) async {
    final oui = await finConfirmer(
      context,
      'Supprimer cette ligne ?',
      '« ${g['libelle']} » disparaîtra de la situation de tous les étudiants concernés. Les versements déjà reçus sont conservés.',
      oui: 'Supprimer',
      danger: true,
    );
    if (!oui) return;
    final r = await FinanceService.supprimerGrille(g['id']);
    if (!mounted) return;
    if (r['success'] == true) {
      _recharger();
    } else {
      finMessage(context, '${r['message']}', erreur: true);
    }
  }

  Future<void> _dupliquer() async {
    final a = widget.annee ?? '';
    final ctrl = TextEditingController(text: _anneeSuivante(a));
    final vers = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Copier la grille'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Copie toutes les lignes de $a vers la nouvelle année. Les dates d\'échéance sont décalées d\'un an.',
              style: const TextStyle(fontSize: 13, color: finGris)),
          const SizedBox(height: 12),
          TextField(controller: ctrl, decoration: finChamp('Nouvelle année', aide: 'Format : 2027-2028')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('Copier')),
        ],
      ),
    );
    if (vers == null || vers.isEmpty) return;
    final r = await FinanceService.dupliquerAnnee(a, vers);
    if (!mounted) return;
    if (r['success'] == true) {
      finMessage(context, '${r['copiees']} ligne(s) copiée(s) vers $vers.');
      await widget.onChangeAnnee(vers);
    } else {
      finMessage(context, '${r['message']}', erreur: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_charge) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      backgroundColor: finFond,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: finBleu,
        foregroundColor: Colors.white,
        onPressed: () => _ouvrirForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
      body: RefreshIndicator(
        onRefresh: _recharger,
        child: ListView(padding: const EdgeInsets.fromLTRB(14, 14, 14, 90), children: [
          Row(children: [
            Expanded(
              child: Text('Année ${widget.annee ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
            TextButton.icon(onPressed: _dupliquer, icon: const Icon(Icons.copy_all_rounded, size: 18), label: const Text('Copier vers une autre année')),
          ]),
          if (_erreur != null) Text(_erreur!, style: const TextStyle(color: finRouge)),
          if (_grilles.isEmpty && _erreur == null)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: Text(
                  "Aucune ligne pour cette année.\nAjoute les frais d'inscription et de scolarité de chaque domaine, filière et niveau.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: finGris),
                ),
              ),
            ),
          for (final g in _grilles) _carte(g),
        ]),
      ),
    );
  }

  Widget _carte(Map<String, dynamic> g) {
    final tr = ((g['tranches'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final actif = g['actif'] != false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: actif ? 1 : 0.55,
        child: FinCarte(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (g['type'] == 'inscription' ? finJaune : finBleu).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_types['${g['type']}'] ?? '${g['type']}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: g['type'] == 'inscription' ? const Color(0xFF8A6D00) : finBleu)),
              ),
              if (!actif) ...[const SizedBox(width: 6), const Text('désactivée', style: TextStyle(fontSize: 11, color: finGris))],
              const Spacer(),
              IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.edit_rounded, size: 19, color: finBleu), onPressed: () => _ouvrirForm(g)),
              IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.delete_outline_rounded, size: 20, color: finRouge), onPressed: () => _supprimer(g)),
            ]),
            Text('${g['libelle']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 2),
            Text(_critere(g), style: const TextStyle(fontSize: 12.5, color: finGris)),
            const SizedBox(height: 8),
            Text(fcfa(g['montant_total']), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: finBleu)),
            if (tr.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final t in tr)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: finFond, borderRadius: BorderRadius.circular(8)),
                    child: Text('${t['libelle'] ?? 'Tranche ${t['numero']}'} : ${fcfa(t['montant'], unite: false)}${t['echeance'] == null ? '' : ' · avant le ${dateFr(t['echeance'])}'}',
                        style: const TextStyle(fontSize: 11.5)),
                  ),
              ]),
            ] else
              const Padding(padding: EdgeInsets.only(top: 6), child: Text('Paiement en une fois', style: TextStyle(fontSize: 12, color: finGris))),
          ]),
        ),
      ),
    );
  }
}

// ═══ Formulaire ════════════════════════════════════════════════
class _TrancheEdit {
  final TextEditingController libelle;
  final TextEditingController montant;
  DateTime? date;
  _TrancheEdit(String l, String m, this.date)
      : libelle = TextEditingController(text: l),
        montant = TextEditingController(text: m);
  void dispose() {
  }
}

class _FormGrille extends StatefulWidget {
  final String annee;
  final List<_Fil> filieres;
  final Map<String, dynamic>? grille;
  const _FormGrille({required this.annee, required this.filieres, this.grille});
  @override
  State<_FormGrille> createState() => _FormGrilleState();
}

class _FormGrilleState extends State<_FormGrille> {
  late String _type;
  late final TextEditingController _libelle;
  late final TextEditingController _annee;
  late final TextEditingController _montant;
  String? _domaine;
  String? _filiereId;
  String? _niveau;
  bool _actif = true;
  final List<_TrancheEdit> _tranches = [];
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    final g = widget.grille;
    _type = '${g?['type'] ?? 'scolarite'}';
    _libelle = TextEditingController(text: '${g?['libelle'] ?? ''}');
    _annee = TextEditingController(text: '${g?['annee_academique'] ?? widget.annee}');
    _montant = TextEditingController(text: g == null ? '' : '${finNum(g['montant_total']).round()}');
    final d = '${g?['domaine'] ?? ''}';
    _domaine = d.isEmpty ? null : d;
    _filiereId = g?['filiere_id'] == null ? null : '${g!['filiere_id']}';
    final n = '${g?['niveau'] ?? ''}';
    _niveau = n.isEmpty ? null : n;
    _actif = g?['actif'] != false;
    for (final t in ((g?['tranches'] as List?) ?? const [])) {
      final m = Map<String, dynamic>.from(t as Map);
      _tranches.add(_TrancheEdit('${m['libelle'] ?? ''}', '${finNum(m['montant']).round()}', DateTime.tryParse('${m['echeance'] ?? ''}')));
    }
  }

  @override
  void dispose() {
    _libelle.dispose();
    _annee.dispose();
    _montant.dispose();
    for (final t in _tranches) {
      t.dispose();
    }
    super.dispose();
  }

  int get _total => int.tryParse(_montant.text.replaceAll(' ', '')) ?? 0;
  int get _sommeTranches => _tranches.fold<int>(0, (s, t) => s + (int.tryParse(t.montant.text.replaceAll(' ', '')) ?? 0));

  List<String> get _domaines => widget.filieres.map((f) => f.domaine).where((d) => d.isNotEmpty).toSet().toList();
  List<_Fil> get _filieresVisibles => widget.filieres.where((f) => _domaine == null || f.domaine == _domaine).toList();
  List<String> get _niveaux {
    final src = _filiereId == null ? widget.filieres : widget.filieres.where((f) => f.id == _filiereId);
    final s = <String>{};
    for (final f in src) {
      s.addAll(f.niveaux);
    }
    return s.toList()..sort();
  }

  void _repartir(int n) {
    final total = _total;
    if (total <= 0) {
      finMessage(context, "Saisis d'abord le montant total.", erreur: true);
      return;
    }
    for (final t in _tranches) {
      t.dispose();
    }
    _tranches.clear();
    final base = total ~/ n;
    for (var i = 1; i <= n; i++) {
      final m = i == n ? total - base * (n - 1) : base;
      _tranches.add(_TrancheEdit('Tranche $i', '$m', null));
    }
    setState(() {});
  }

  Future<void> _enregistrer() async {
    if (_libelle.text.trim().isEmpty) {
      finMessage(context, 'Donne un libellé à cette ligne.', erreur: true);
      return;
    }
    if (_tranches.isNotEmpty && _sommeTranches != _total) {
      finMessage(context, 'La somme des tranches (${fcfa(_sommeTranches)}) doit égaler le montant total (${fcfa(_total)}).', erreur: true);
      return;
    }
    setState(() => _envoi = true);
    final corps = {
      'annee_academique': _annee.text.trim(),
      'type': _type,
      'libelle': _libelle.text.trim(),
      'domaine': _domaine,
      'filiere_id': _filiereId,
      'niveau': _niveau,
      'montant_total': _total,
      'actif': _actif,
      'tranches': [
        for (final t in _tranches)
          {
            'libelle': t.libelle.text.trim(),
            'montant': int.tryParse(t.montant.text.replaceAll(' ', '')) ?? 0,
            'echeance': t.date == null ? null : dateIso(t.date!),
          }
      ],
    };
    final r = widget.grille == null
        ? await FinanceService.creerGrille(corps)
        : await FinanceService.modifierGrille(widget.grille!['id'], corps);
    if (!mounted) return;
    setState(() => _envoi = false);
    if (r['success'] == true) {
      Navigator.pop(context, _annee.text.trim());
    } else {
      finMessage(context, '${r['message']}', erreur: true);
    }
  }

  Widget _titre(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: finGris)),
      );

  @override
  Widget build(BuildContext context) {
    final ecart = _total - _sommeTranches;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 6, children: [
        for (final e in _types.entries)
          ChoiceChip(label: Text(e.value), selected: _type == e.key, onSelected: (_) => setState(() => _type = e.key)),
      ]),
      const SizedBox(height: 10),
      TextField(controller: _libelle, decoration: finChamp('Libellé', aide: 'Ex. Scolarité Licence 3 Réseaux')),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(controller: _annee, decoration: finChamp('Année académique'))),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _montant,
            keyboardType: TextInputType.number,
            decoration: finChamp('Montant total', suffixe: 'FCFA'),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ]),
      _titre('S\'applique à… (laisser « Tous » pour ne pas restreindre)'),
      Wrap(spacing: 6, runSpacing: 6, children: [
        ChoiceChip(label: const Text('Tous les domaines'), selected: _domaine == null, onSelected: (_) => setState(() { _domaine = null; })),
        for (final d in _domaines)
          ChoiceChip(
            label: Text(d),
            selected: _domaine == d,
            onSelected: (_) => setState(() {
              _domaine = d;
              if (_filiereId != null && !_filieresVisibles.any((f) => f.id == _filiereId)) _filiereId = null;
            }),
          ),
      ]),
      const SizedBox(height: 8),
      PopupMenuButton<String>(
        onSelected: (v) => setState(() {
          _filiereId = v == '__tous__' ? null : v;
          if (_niveau != null && !_niveaux.contains(_niveau)) _niveau = null;
        }),
        itemBuilder: (_) => [
          const PopupMenuItem(value: '__tous__', child: Text('Toutes les filières')),
          for (final f in _filieresVisibles) PopupMenuItem(value: f.id, child: Text(f.nom)),
        ],
        child: InputDecorator(
          decoration: finChamp('Filière'),
          child: Row(children: [
            Expanded(
              child: Text(
                _filiereId == null ? 'Toutes les filières' : widget.filieres.firstWhere((f) => f.id == _filiereId, orElse: () => _Fil('', 'Filière', '', const [])).nom,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: [
        ChoiceChip(label: const Text('Tous niveaux'), selected: _niveau == null, onSelected: (_) => setState(() => _niveau = null)),
        for (final n in _niveaux) ChoiceChip(label: Text(n), selected: _niveau == n, onSelected: (_) => setState(() => _niveau = n)),
      ]),
      _titre('Tranches de paiement'),
      Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        const Text('Répartir en', style: TextStyle(fontSize: 13)),
        for (final n in [1, 2, 3, 4, 5, 6]) ActionChip(label: Text('$n'), onPressed: () => _repartir(n)),
        const Text('tranches égales', style: TextStyle(fontSize: 13)),
      ]),
      const SizedBox(height: 8),
      for (var i = 0; i < _tranches.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(flex: 3, child: TextField(controller: _tranches[i].libelle, decoration: finChamp('Nom'))),
            const SizedBox(width: 6),
            Expanded(flex: 3, child: TextField(controller: _tranches[i].montant, keyboardType: TextInputType.number, decoration: finChamp('Montant'), onChanged: (_) => setState(() {}))),
            const SizedBox(width: 6),
            Expanded(
              flex: 3,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14)),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _tranches[i].date ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => _tranches[i].date = d);
                },
                child: Text(_tranches[i].date == null ? 'Échéance' : dateFr(_tranches[i].date!.toIso8601String()), style: const TextStyle(fontSize: 12)),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 18, color: finRouge),
              onPressed: () => setState(() {
                _tranches[i].dispose();
                _tranches.removeAt(i);
              }),
            ),
          ]),
        ),
      Row(children: [
        TextButton.icon(
          onPressed: () => setState(() => _tranches.add(_TrancheEdit('Tranche ${_tranches.length + 1}', '', null))),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Ajouter une tranche'),
        ),
        const Spacer(),
        if (_tranches.isNotEmpty)
          Text(
            ecart == 0 ? 'Somme exacte' : (ecart > 0 ? 'Reste à répartir : ${fcfa(ecart)}' : 'Dépasse de ${fcfa(-ecart)}'),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ecart == 0 ? finVert : finRouge),
          ),
      ]),
      if (widget.grille != null)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _actif,
          onChanged: (v) => setState(() => _actif = v),
          title: const Text('Ligne active'),
          subtitle: const Text('Désactivée : elle n\'est plus comptée dans les frais des étudiants.'),
        ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: finBleu, padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: _envoi ? null : _enregistrer,
          child: Text(_envoi ? 'Enregistrement…' : 'Enregistrer'),
        ),
      ),
    ]);
  }
}

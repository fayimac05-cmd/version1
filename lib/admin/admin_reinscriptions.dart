import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../services/annuel_service.dart';
import '../utils/snackbar_helper.dart';

// Administration — Réinscriptions :
//  • les étudiants admis ou redoublants qui doivent se réinscrire pour l'année en cours ;
//  • validation en un clic après paiement à la caisse (référence du reçu) : le niveau change ici ;
//  • frais de réinscription fixés par niveau.
class AdminReinscriptions extends StatefulWidget {
  const AdminReinscriptions({super.key});
  @override
  State<AdminReinscriptions> createState() => _AdminReinscriptionsState();
}

class _AdminReinscriptionsState extends State<AdminReinscriptions> {
  static const _statuts = <String, String>{
    'demandee': 'Demandées',
    'a_faire': 'À faire',
    'validee': 'Validées',
    'refusee': 'Refusées',
  };

  String _statut = 'demandee';
  String? _annee;
  Map<String, dynamic> _compteurs = {};
  List<dynamic> _liste = [];
  bool _charge = true;
  String? _erreur;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _charge = true;
      _erreur = null;
    });
    final r = await AnnuelService.listerReinscriptions(_statut);
    if (!mounted) return;
    setState(() {
      _charge = false;
      if (r['success'] == true) {
        final d = Map<String, dynamic>.from((r['data'] as Map?) ?? {});
        _annee = d['annee']?.toString();
        _compteurs = Map<String, dynamic>.from((d['compteurs'] as Map?) ?? {});
        _liste = (d['reinscriptions'] as List?) ?? [];
      } else {
        _liste = [];
        _erreur = r['error']?.toString();
      }
    });
  }

  void _snack(String m, {bool erreur = false}) =>
      showAppSnackBar(context, m, backgroundColor: erreur ? AdminTheme.danger : const Color(0xFF1A3C34));

  String _montant(dynamic v) {
    final n = num.tryParse('${v ?? ''}');
    if (n == null) return '—';
    final s = n.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return '$b FCFA';
  }

  Future<void> _valider(dynamic r) async {
    final ref = TextEditingController();
    final montant = TextEditingController(text: r['montant_prevu'] == null ? '' : '${(r['montant_prevu'] as num).round()}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Valider la réinscription', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${r['prenoms'] ?? ''} ${r['nom']} passera en ${r['niveau_cible']}.',
                style: const TextStyle(fontSize: 13, height: 1.4)),
            const SizedBox(height: 14),
            TextField(
              controller: ref,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'Référence du reçu de la caisse', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: montant,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Montant payé (FCFA)', border: OutlineInputBorder(), isDense: true),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Valider')),
        ],
      ),
    );
    if (ok != true) return;
    final res = await AnnuelService.validerReinscription(r['id'], ref.text.trim(), montant: montant.text);
    if (!mounted) return;
    _snack(res['success'] == true ? (res['message']?.toString() ?? 'Validée.') : (res['error']?.toString() ?? 'Erreur.'),
        erreur: res['success'] != true);
    if (res['success'] == true) _charger();
  }

  Future<void> _refuser(dynamic r) async {
    final motif = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Refuser la demande', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: motif,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Motif (vu par l\'étudiant)', border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Refuser')),
        ],
      ),
    );
    if (ok != true) return;
    final res = await AnnuelService.refuserReinscription(r['id'], motif.text.trim());
    if (!mounted) return;
    _snack(res['success'] == true ? (res['message']?.toString() ?? 'Refusée.') : (res['error']?.toString() ?? 'Erreur.'),
        erreur: res['success'] != true);
    if (res['success'] == true) _charger();
  }

  Future<void> _frais() async {
    final r = await AnnuelService.frais();
    if (!mounted) return;
    if (r['success'] != true) {
      _snack(r['error']?.toString() ?? 'Erreur.', erreur: true);
      return;
    }
    final d = Map<String, dynamic>.from((r['data'] as Map?) ?? {});
    final enregistres = <String, String>{
      for (final f in (d['frais'] as List? ?? [])) '${f['niveau']}': '${(f['montant'] as num).round()}',
    };
    final niveaux = <String>{
      ...((d['niveaux_connus'] as List?) ?? []).map((e) => '$e'),
      ...enregistres.keys,
    }.toList()
      ..sort();
    final ctrls = {for (final n in niveaux) n: TextEditingController(text: enregistres[n] ?? '')};

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Frais de réinscription', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 420,
          child: niveaux.isEmpty
              ? const Text('Aucun niveau trouvé : ajoute d\'abord des étudiants.')
              : SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Montant à payer pour entrer dans chaque niveau.',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                    ),
                    const SizedBox(height: 10),
                    for (final n in niveaux)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(
                          controller: ctrls[n],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              labelText: n, suffixText: 'FCFA', border: const OutlineInputBorder(), isDense: true),
                        ),
                      ),
                  ]),
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (ok != true) return;
    final liste = <Map<String, dynamic>>[
      for (final n in niveaux)
        if (ctrls[n]!.text.trim().isNotEmpty) {'niveau': n, 'montant': ctrls[n]!.text.trim()},
    ];
    final res = await AnnuelService.enregistrerFrais(liste);
    if (!mounted) return;
    _snack(res['success'] == true ? (res['message']?.toString() ?? 'Enregistré.') : (res['error']?.toString() ?? 'Erreur.'),
        erreur: res['success'] != true);
    if (res['success'] == true) _charger();
  }

  @override
  Widget build(BuildContext context) {
    final q = _recherche.trim().toLowerCase();
    final visibles = q.isEmpty
        ? _liste
        : _liste.where((r) => '${r['nom']} ${r['prenoms']} ${r['matricule']}'.toLowerCase().contains(q)).toList();

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(children: [
            Expanded(
              child: Text('Réinscriptions ${_annee ?? ''}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            ),
            OutlinedButton.icon(
              onPressed: _frais,
              icon: const Icon(Icons.payments_outlined, size: 18),
              label: const Text('Frais'),
            ),
          ]),
          const SizedBox(height: 4),
          const Text(
            'L\'étudiant fait sa demande, paie à la caisse, puis tu valides avec la référence du reçu : son niveau change à ce moment-là.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in _statuts.entries)
              ChoiceChip(
                label: Text('${e.value} (${_compteurs[e.key] ?? 0})'),
                selected: _statut == e.key,
                onSelected: (_) {
                  setState(() => _statut = e.key);
                  _charger();
                },
              ),
          ]),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _recherche = v),
            decoration: const InputDecoration(
              hintText: 'Rechercher un nom ou un matricule',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),
          if (_charge)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else if (_erreur != null)
            Center(child: Text(_erreur!))
          else if (visibles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Aucune réinscription dans cette liste.', style: TextStyle(color: Color(0xFF64748B)))),
            )
          else
            for (final r in visibles) ...[_carte(r), const SizedBox(height: 10)],
        ],
      ),
    );
  }

  Widget _carte(dynamic r) {
    final statut = '${r['statut']}';
    final valide = statut == 'validee';
    final redouble = '${r['decision_precedente']}' == 'redoublant';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('${r['nom']} ${r['prenoms'] ?? ''}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          ),
          Text('${r['matricule']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ]),
        const SizedBox(height: 4),
        Text(
          '${r['filiere_nom'] ?? ''} · ${r['niveau_precedent']} → ${r['niveau_cible']}${redouble ? ' (redoublement)' : ''}',
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 6),
        Text(
          valide
              ? 'Reçu ${r['reference_recu'] ?? '—'} · ${_montant(r['montant'])}'
              : 'Frais prévus : ${_montant(r['montant_prevu'])}',
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
        ),
        if (statut == 'refusee' && '${r['motif_refus'] ?? ''}'.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Refusée : ${r['motif_refus']}', style: const TextStyle(fontSize: 12.5, color: Color(0xFFC62828))),
          ),
        if (!valide) ...[
          const SizedBox(height: 10),
          Row(children: [
            ElevatedButton.icon(
              onPressed: () => _valider(r),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Valider'),
            ),
            const SizedBox(width: 8),
            if (statut == 'demandee')
              OutlinedButton(onPressed: () => _refuser(r), child: const Text('Refuser')),
          ]),
        ],
      ]),
    );
  }
}

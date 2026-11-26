// lib/admin/admin_finances_caisse.dart
// Onglets « Caisse » (journée de caisse + clôture) et « Journal » (tous les versements,
// filtres, copie CSV pour Excel, impression PDF).
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../pages/finance_ui.dart';
import '../services/finance_service.dart';
import 'admin_finances_etudiants.dart';

String _heure(dynamic iso) {
  final d = DateTime.tryParse('$iso')?.toLocal();
  if (d == null) return '';
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

String _modeLibelle(dynamic m) => kModes['$m'] ?? '$m';

List<Map<String, dynamic>> _liste(dynamic v) =>
    ((v as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

// ═══ CAISSE : journée du caissier + clôture ════════════════════
class AdminFinancesCaisse extends StatefulWidget {
  const AdminFinancesCaisse({super.key});
  @override
  State<AdminFinancesCaisse> createState() => _AdminFinancesCaisseState();
}

class _AdminFinancesCaisseState extends State<AdminFinancesCaisse> {
  DateTime _jour = DateTime.now();
  Map<String, dynamic>? _d;
  List<Map<String, dynamic>> _clotures = [];
  num _totalEcarts = 0;
  String? _erreur;
  bool _charge = true;

  @override
  void initState() {
    super.initState();
    _recharger();
  }

  bool get _estAujourdhui {
    final n = DateTime.now();
    return _jour.year == n.year && _jour.month == n.month && _jour.day == n.day;
  }

  Future<void> _recharger() async {
    setState(() {
      _charge = true;
      _erreur = null;
    });
    final r = await FinanceService.caisseJour(dateIso(_jour));
    Map<String, dynamic>? cl;
    if (FinDroits.admin) cl = await FinanceService.clotures();
    if (!mounted) return;
    setState(() {
      _charge = false;
      if (r['success'] == true) {
        _d = r;
      } else {
        _erreur = '${r['message'] ?? 'Erreur.'}';
      }
      if (cl != null && cl['success'] == true) {
        _clotures = _liste(cl['data']);
        _totalEcarts = finNum(cl['total_ecarts']);
      }
    });
  }

  void _decaler(int n) {
    final j = _jour.add(Duration(days: n));
    if (j.isAfter(DateTime.now())) return;
    setState(() => _jour = j);
    _recharger();
  }

  Future<void> _choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _jour,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d == null || !mounted) return;
    setState(() => _jour = d);
    _recharger();
  }

  // Un étudiant se présente au guichet : on le cherche, on saisit le paiement, on imprime le reçu.
  Future<void> _nouvelEncaissement() async {
    final etu = await finFeuille<Map<String, dynamic>>(context, titre: 'Qui paie ?', contenu: (c) => const _SelecteurEtudiant());
    if (etu == null || !mounted) return;
    final id = await finFeuille<dynamic>(
      context,
      titre: 'Encaisser — ${etu['prenoms'] ?? ''} ${etu['nom'] ?? ''}',
      contenu: (c) => FinFormEncaisser(etudiantId: etu['id'], reste: finNum(etu['reste'])),
    );
    if (id == null || !mounted) return;
    await _recharger();
    if (!mounted) return;
    final voir = await finConfirmer(context, 'Paiement enregistré', 'Ouvrir le reçu pour l\'imprimer et le remettre à l\'étudiant ?', oui: 'Ouvrir le reçu');
    if (voir && mounted) await ouvrirRecu(context, id);
  }

  Future<void> _cloturer() async {
    final acl = Map<String, dynamic>.from((_d?['a_cloturer'] ?? {}) as Map);
    final attendu = finNum(acl['attendu_especes']).round();
    final autres = finNum(acl['autres_modes']);
    final compte = TextEditingController();
    final note = TextEditingController();
    final ok = await finFeuille<bool>(context, titre: 'Clôturer ma caisse du ${dateFr(dateIso(_jour))}', contenu: (c) {
      return StatefulBuilder(builder: (c, setS) {
        final cpt = int.tryParse(compte.text.replaceAll(' ', ''));
        final ecart = cpt == null ? null : cpt - attendu;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FinCarte(
            couleur: finFond,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Espèces attendues (d\'après les reçus) : ${fcfa(attendu)}', style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Autres modes (virement, chèque, mobile money) : ${fcfa(autres)} — à ne pas compter dans le tiroir-caisse.',
                  style: const TextStyle(fontSize: 12, color: finGris)),
            ]),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: compte,
            keyboardType: TextInputType.number,
            onChanged: (_) => setS(() {}),
            decoration: finChamp('Espèces comptées dans la caisse', suffixe: 'FCFA', aide: 'Compte les billets et pièces, puis saisis le total.'),
          ),
          if (ecart != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                ecart == 0 ? 'Caisse juste.' : 'Écart : ${ecart > 0 ? '+' : ''}${fcfa(ecart)} (${ecart > 0 ? 'excédent' : 'manquant'})',
                style: TextStyle(fontWeight: FontWeight.w800, color: ecart == 0 ? finVert : finRouge),
              ),
            ),
          const SizedBox(height: 10),
          TextField(
            controller: note,
            decoration: finChamp(ecart != null && ecart != 0 ? "Explication de l'écart (obligatoire)" : 'Note (facultatif)'),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: finBleu, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () async {
                final v = int.tryParse(compte.text.replaceAll(' ', ''));
                if (v == null || v < 0) {
                  finMessage(c, 'Saisis le montant compté en caisse.', erreur: true);
                  return;
                }
                if (v != attendu && note.text.trim().isEmpty) {
                  finMessage(c, "Explique l'écart dans la note.", erreur: true);
                  return;
                }
                final oui = await finConfirmer(c, 'Clôturer la caisse ?',
                    'Ces encaissements seront verrouillés dans ta caisse. Cette action ne peut pas être annulée par toi.',
                    oui: 'Clôturer');
                if (!oui || !c.mounted) return;
                final r = await FinanceService.cloturerCaisse(dateIso(_jour), v, note.text.trim());
                if (!c.mounted) return;
                if (r['success'] == true) {
                  Navigator.pop(c, true);
                } else {
                  finMessage(c, '${r['message']}', erreur: true);
                }
              },
              child: const Text('Clôturer la journée'),
            ),
          ),
        ]);
      });
    });
    if (ok == true) {
      if (mounted) finMessage(context, 'Caisse clôturée.');
      _recharger();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_charge && _d == null) return const Center(child: CircularProgressIndicator());
    final d = _d;
    final versements = _liste(d?['versements']);
    final acl = Map<String, dynamic>.from((d?['a_cloturer'] ?? {}) as Map);
    final nbOuverts = finNum(d?['nb_a_cloturer']).round();
    final parMode = Map<String, dynamic>.from((acl['par_mode'] ?? {}) as Map);
    final cloturee = versements.isNotEmpty && nbOuverts == 0;

    return RefreshIndicator(
      onRefresh: _recharger,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        children: [
          Row(children: [
            IconButton(onPressed: () => _decaler(-1), icon: const Icon(Icons.chevron_left_rounded)),
            Expanded(
              child: InkWell(
                onTap: _choisirDate,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(children: [
                    Text(_estAujourdhui ? "Aujourd'hui" : 'Journée du', style: const TextStyle(fontSize: 12, color: finGris)),
                    Text(dateFr(dateIso(_jour)), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: finTexte)),
                  ]),
                ),
              ),
            ),
            IconButton(onPressed: _estAujourdhui ? null : () => _decaler(1), icon: const Icon(Icons.chevron_right_rounded)),
          ]),
          if (_erreur != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_erreur!, style: const TextStyle(color: finRouge))),
          if (_estAujourdhui)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: finVert, padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _nouvelEncaissement,
                  icon: const Icon(Icons.add_card_rounded),
                  label: const Text('Nouvel encaissement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          Row(children: [
            Expanded(child: FinKpi(titre: 'Espèces à remettre', valeur: fcfa(acl['attendu_especes']), icone: Icons.payments_rounded, couleur: finVert, sous: 'à clôturer')),
            const SizedBox(width: 10),
            Expanded(child: FinKpi(titre: 'Autres modes', valeur: fcfa(acl['autres_modes']), icone: Icons.account_balance_rounded, couleur: finBleu, sous: 'virement, chèque, mobile')),
          ]),
          if (parMode.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(spacing: 8, runSpacing: 6, children: [
                for (final e in parMode.entries)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Text('${_modeLibelle(e.key)} : ${fcfa(e.value)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
              ]),
            ),
          const SizedBox(height: 12),
          if (cloturee)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: finVert.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [
                Icon(Icons.lock_rounded, color: finVert),
                SizedBox(width: 10),
                Expanded(child: Text('Journée clôturée : tous tes encaissements du jour sont verrouillés.', style: TextStyle(color: finVert, fontWeight: FontWeight.w700))),
              ]),
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: finBleu, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: nbOuverts > 0 ? _cloturer : null,
                icon: const Icon(Icons.lock_clock_rounded, size: 19),
                label: Text(nbOuverts > 0 ? 'Clôturer ma caisse ($nbOuverts encaissement${nbOuverts > 1 ? 's' : ''})' : 'Aucun encaissement à clôturer'),
              ),
            ),
          const SizedBox(height: 16),
          const Text('Mes encaissements', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          if (versements.isEmpty) const Text('Aucun encaissement à la caisse ce jour-là.', style: TextStyle(color: finGris)),
          for (final v in versements)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FinCarte(
                padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${v['prenoms'] ?? ''} ${v['nom'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${_modeLibelle(v['mode'])} · ${_heure(v['date'])}${v['numero_recu'] == null ? '' : ' · ${v['numero_recu']}'}',
                          style: const TextStyle(fontSize: 12, color: finGris)),
                    ]),
                  ),
                  Text(fcfa(v['montant']), style: const TextStyle(fontWeight: FontWeight.w800)),
                  if (v['cloture_id'] != null) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.lock_rounded, size: 16, color: finVert)),
                  IconButton(tooltip: 'Reçu', icon: const Icon(Icons.receipt_long_rounded, color: finBleu), onPressed: () => ouvrirRecu(context, v['id'])),
                ]),
              ),
            ),
          if (FinDroits.admin) ...[
            const SizedBox(height: 18),
            Row(children: [
              const Expanded(child: Text('Clôtures des 30 derniers jours', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
              Text('Écarts : ${_totalEcarts > 0 ? '+' : ''}${fcfa(_totalEcarts)}',
                  style: TextStyle(fontWeight: FontWeight.w800, color: _totalEcarts == 0 ? finVert : finRouge)),
            ]),
            const SizedBox(height: 8),
            if (_clotures.isEmpty) const Text('Aucune clôture enregistrée.', style: TextStyle(color: finGris)),
            for (final c in _clotures)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FinCarte(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('${dateFr(c['date_caisse'])} · ${c['caissier']}', style: const TextStyle(fontWeight: FontWeight.w700))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                            color: (finNum(c['ecart']) == 0 ? finVert : finRouge).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text(finNum(c['ecart']) == 0 ? 'Caisse juste' : 'Écart',
                            style: TextStyle(color: finNum(c['ecart']) == 0 ? finVert : finRouge, fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text('Attendu ${fcfa(c['attendu_especes'])} · compté ${fcfa(c['compte_especes'])}'
                        '${finNum(c['ecart']) == 0 ? '' : ' · écart ${finNum(c['ecart']) > 0 ? '+' : ''}${fcfa(c['ecart'])}'}',
                        style: const TextStyle(fontSize: 12.5, color: finGris)),
                    if ('${c['note'] ?? ''}'.isNotEmpty) Text('Note : ${c['note']}', style: const TextStyle(fontSize: 12.5)),
                  ]),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ═══ JOURNAL : tous les versements ═════════════════════════════
class AdminFinancesJournal extends StatefulWidget {
  const AdminFinancesJournal({super.key});
  @override
  State<AdminFinancesJournal> createState() => _AdminFinancesJournalState();
}

class _AdminFinancesJournalState extends State<AdminFinancesJournal> {
  final TextEditingController _q = TextEditingController();
  String _periode = 'mois';
  String? _mode;
  bool _annules = false;
  bool _charge = true;
  String? _erreur;
  Map<String, dynamic> _d = {};

  static const Map<String, String> _periodes = {
    'jour': "Aujourd'hui",
    '7j': '7 jours',
    'mois': 'Ce mois',
    'tout': 'Tout',
  };

  @override
  void initState() {
    super.initState();
    _recharger();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  (String?, String?) _bornes() {
    final n = DateTime.now();
    switch (_periode) {
      case 'jour':
        return (dateIso(n), dateIso(n));
      case '7j':
        return (dateIso(n.subtract(const Duration(days: 6))), dateIso(n));
      case 'mois':
        return (dateIso(DateTime(n.year, n.month, 1)), dateIso(n));
      default:
        return (null, null);
    }
  }

  Future<void> _recharger() async {
    setState(() {
      _charge = true;
      _erreur = null;
    });
    final (du, au) = _bornes();
    final r = await FinanceService.versements(
      du: du,
      au: au,
      mode: _mode,
      q: _q.text.trim(),
      statut: _annules ? 'tous' : null,
    );
    if (!mounted) return;
    setState(() {
      _charge = false;
      if (r['success'] == true) {
        _d = r;
      } else {
        _erreur = '${r['message'] ?? 'Erreur.'}';
      }
    });
  }

  String _libellePeriode() {
    final (du, au) = _bornes();
    if (du == null) return 'Toutes les dates';
    return du == au ? 'Le ${dateFr(du)}' : 'Du ${dateFr(du)} au ${dateFr(au)}';
  }

  String _csv(List<Map<String, dynamic>> lignes) {
    String c(dynamic v) => '"${'${v ?? ''}'.replaceAll('"', '""')}"';
    final b = StringBuffer('Date;Recu;Matricule;Nom;Prenoms;Filiere;Mode;Reference;Montant;Statut;Caissier\n');
    for (final l in lignes) {
      b.writeln([
        dateFr(l['date']),
        c(l['numero_recu']),
        c(l['matricule']),
        c(l['nom']),
        c(l['prenoms']),
        c(l['filiere_nom']),
        c(_modeLibelle(l['mode'])),
        c(l['reference']),
        finNum(l['montant']).round(),
        l['statut'] == 'annule' ? 'Annulé' : 'Réussi',
        c(l['enregistre_par']),
      ].join(';'));
    }
    return b.toString();
  }

  Future<void> _copierCsv(List<Map<String, dynamic>> lignes) async {
    await Clipboard.setData(ClipboardData(text: _csv(lignes)));
    if (mounted) finMessage(context, 'Tableau copié : colle-le dans Excel (Ctrl+V).');
  }

  Future<void> _imprimer(List<Map<String, dynamic>> lignes) async {
    final doc = pw.Document();
    pw.Widget cell(String t, {bool gras = false, pw.Alignment? al}) => pw.Container(
          alignment: al,
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: pw.Text(finL1(t), style: pw.TextStyle(fontSize: 8, fontWeight: gras ? pw.FontWeight.bold : pw.FontWeight.normal)),
        );
    final entete = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        for (final t in ['Date', 'Recu', 'Etudiant', 'Matricule', 'Mode', 'Reference', 'Caissier', 'Montant']) cell(t, gras: true),
      ],
    );
    final corps = [
      for (final l in lignes)
        pw.TableRow(children: [
          cell(dateFr(l['date'])),
          cell('${l['numero_recu'] ?? ''}'),
          cell('${l['prenoms'] ?? ''} ${l['nom'] ?? ''}${l['statut'] == 'annule' ? ' (ANNULE)' : ''}'),
          cell('${l['matricule'] ?? ''}'),
          cell(_modeLibelle(l['mode'])),
          cell('${l['reference'] ?? ''}'),
          cell('${l['enregistre_par'] ?? ''}'),
          cell(fcfa(l['montant'], unite: false), al: pw.Alignment.centerRight),
        ]),
    ];
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      build: (c) => [
        pw.Text('Journal des versements', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.Text(finL1('${_libellePeriode()}  -  Total : ${fcfa(_d['total'])}  (${_d['nb'] ?? 0} versements)'),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(width: 0.4, color: PdfColors.grey500),
          columnWidths: const {
            0: pw.FixedColumnWidth(55),
            1: pw.FixedColumnWidth(70),
            2: pw.FlexColumnWidth(3),
            3: pw.FixedColumnWidth(55),
            4: pw.FixedColumnWidth(60),
            5: pw.FlexColumnWidth(2),
            6: pw.FlexColumnWidth(2),
            7: pw.FixedColumnWidth(62),
          },
          children: [entete, ...corps],
        ),
      ],
    ));
    await Printing.layoutPdf(onLayout: (_) async => doc.save(), name: 'Journal_versements.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final lignes = _liste(_d['data']);
    final parMode = Map<String, dynamic>.from((_d['par_mode'] ?? {}) as Map);
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _q,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _recharger(),
                decoration: finChamp('Nom, matricule, n° de reçu, référence…').copyWith(prefixIcon: const Icon(Icons.search_rounded)),
              ),
            ),
            IconButton(tooltip: 'Copier pour Excel', onPressed: lignes.isEmpty ? null : () => _copierCsv(lignes), icon: const Icon(Icons.table_view_rounded, color: finBleu)),
            IconButton(tooltip: 'Imprimer / PDF', onPressed: lignes.isEmpty ? null : () => _imprimer(lignes), icon: const Icon(Icons.print_rounded, color: finBleu)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 4, children: [
            for (final e in _periodes.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: _periode == e.key,
                onSelected: (_) {
                  setState(() => _periode = e.key);
                  _recharger();
                },
              ),
          ]),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 4, children: [
            ChoiceChip(
              label: const Text('Tous les modes'),
              selected: _mode == null,
              onSelected: (_) {
                setState(() => _mode = null);
                _recharger();
              },
            ),
            for (final e in kModes.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: _mode == e.key,
                onSelected: (_) {
                  setState(() => _mode = e.key);
                  _recharger();
                },
              ),
          ]),
          Row(children: [
            Switch(
              value: _annules,
              onChanged: (v) {
                setState(() => _annules = v);
                _recharger();
              },
            ),
            const Text('Inclure les versements annulés', style: TextStyle(fontSize: 13)),
          ]),
        ]),
      ),
      Expanded(
        child: _charge
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _recharger,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(14),
                  children: [
                    if (_erreur != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_erreur!, style: const TextStyle(color: finRouge))),
                    Row(children: [
                      Expanded(child: FinKpi(titre: 'Total encaissé', valeur: fcfa(_d['total']), icone: Icons.savings_rounded, couleur: finVert, sous: _libellePeriode())),
                      const SizedBox(width: 10),
                      Expanded(child: FinKpi(titre: 'Versements', valeur: '${_d['nb'] ?? 0}', icone: Icons.receipt_long_rounded, couleur: finBleu)),
                    ]),
                    if (parMode.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Wrap(spacing: 8, runSpacing: 6, children: [
                          for (final e in parMode.entries)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
                              child: Text('${_modeLibelle(e.key)} : ${fcfa(e.value)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                        ]),
                      ),
                    if (_d['tronque'] == true)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Seuls les 1000 derniers versements sont affichés : affine la période.', style: TextStyle(fontSize: 12, color: finOrange)),
                      ),
                    const SizedBox(height: 12),
                    if (lignes.isEmpty) const Text('Aucun versement pour ces filtres.', style: TextStyle(color: finGris)),
                    for (final l in lignes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FinCarte(
                          padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                          child: Row(children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('${l['prenoms'] ?? ''} ${l['nom'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(
                                  '${dateFr(l['date'])} ${_heure(l['date'])} · ${_modeLibelle(l['mode'])}'
                                  '${l['numero_recu'] == null ? '' : ' · ${l['numero_recu']}'}'
                                  '${'${l['enregistre_par'] ?? ''}'.isEmpty ? '' : ' · ${l['enregistre_par']}'}',
                                  style: const TextStyle(fontSize: 12, color: finGris),
                                ),
                                if (l['statut'] == 'annule') Text('Annulé : ${l['motif_annulation'] ?? ''}', style: const TextStyle(fontSize: 12, color: finRouge)),
                              ]),
                            ),
                            Text(fcfa(l['montant']),
                                style: TextStyle(fontWeight: FontWeight.w800, decoration: l['statut'] == 'annule' ? TextDecoration.lineThrough : null)),
                            if (l['statut'] == 'reussi')
                              IconButton(tooltip: 'Reçu', icon: const Icon(Icons.receipt_long_rounded, color: finBleu), onPressed: () => ouvrirRecu(context, l['id']))
                            else
                              const SizedBox(width: 12),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    ]);
  }
}


// ═══ Recherche d'un étudiant au guichet ════════════════════════
class _SelecteurEtudiant extends StatefulWidget {
  const _SelecteurEtudiant();
  @override
  State<_SelecteurEtudiant> createState() => _SelecteurEtudiantState();
}

class _SelecteurEtudiantState extends State<_SelecteurEtudiant> {
  final TextEditingController _q = TextEditingController();
  Timer? _attente;
  List<Map<String, dynamic>> _res = [];
  bool _charge = false;
  String? _erreur;

  @override
  void dispose() {
    _attente?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _surSaisie(String v) {
    _attente?.cancel();
    if (v.trim().length < 2) {
      setState(() {
        _res = [];
        _erreur = null;
      });
      return;
    }
    _attente = Timer(const Duration(milliseconds: 350), _chercher);
  }

  Future<void> _chercher() async {
    setState(() {
      _charge = true;
      _erreur = null;
    });
    final r = await FinanceService.etudiants(q: _q.text.trim());
    if (!mounted) return;
    setState(() {
      _charge = false;
      if (r['success'] == true) {
        _res = _liste(r['data']).take(20).toList();
      } else {
        _erreur = '${r['message'] ?? 'Erreur.'}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _q,
        autofocus: true,
        onChanged: _surSaisie,
        decoration: finChamp('Nom, prénom ou matricule', aide: 'Tape au moins 2 lettres.').copyWith(prefixIcon: const Icon(Icons.search_rounded)),
      ),
      const SizedBox(height: 10),
      if (_charge) const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
      if (_erreur != null) Text(_erreur!, style: const TextStyle(color: finRouge)),
      if (!_charge && _res.isEmpty && _q.text.trim().length >= 2 && _erreur == null)
        const Text('Aucun étudiant trouvé.', style: TextStyle(color: finGris)),
      SizedBox(
        height: 340,
        child: ListView(children: [
          for (final e in _res)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FinCarte(
                onTap: () => Navigator.pop(context, e),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${e['prenoms'] ?? ''} ${e['nom'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${e['matricule'] ?? ''} · ${e['filiere_nom'] ?? ''} ${e['niveau'] ?? ''}', style: const TextStyle(fontSize: 12, color: finGris)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(fcfa(e['reste']), style: TextStyle(fontWeight: FontWeight.w800, color: finNum(e['reste']) > 0 ? finRouge : finVert)),
                    const Text('reste à payer', style: TextStyle(fontSize: 11, color: finGris)),
                  ]),
                ]),
              ),
            ),
        ]),
      ),
    ]);
  }
}

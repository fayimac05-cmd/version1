// lib/admin/admin_finances.dart
// Espace « Finances » de l'administration : tableau de bord, grille tarifaire,
// étudiants (encaissement, impayés, relances, blocage) et dépenses.
import 'package:flutter/material.dart';
import '../pages/finance_ui.dart';
import '../services/finance_service.dart';
import 'admin_finances_grille.dart';
import 'admin_finances_etudiants.dart';
import 'admin_finances_caisse.dart';

class AdminFinances extends StatefulWidget {
  const AdminFinances({super.key});
  @override
  State<AdminFinances> createState() => _AdminFinancesState();
}

class _AdminFinancesState extends State<AdminFinances> with SingleTickerProviderStateMixin {
  TabController? _tab;
  String? _annee;
  List<String> _annees = [];
  bool _pret = false;

  @override
  void initState() {
    super.initState();
    _initialiser();
  }

  // Les droits décident des onglets : l'administration voit tout, le personnel de caisse
  // seulement Étudiants, Caisse et Journal.
  Future<void> _initialiser() async {
    final d = await FinanceService.droits();
    if (!mounted) return;
    if (d['success'] == true) {
      FinDroits.admin = d['admin'] == true;
      FinDroits.caisse = d['caisse'] == true;
      FinDroits.role = '${d['role'] ?? ''}';
    }
    _tab = TabController(length: FinDroits.admin ? 6 : 3, vsync: this);
    if (FinDroits.admin) {
      await _chargerAnnees();
    } else {
      setState(() => _pret = true);
    }
  }

  @override
  void dispose() {
    _tab?.dispose();
    super.dispose();
  }

  Future<void> _chargerAnnees() async {
    final r = await FinanceService.grilles(_annee);
    if (!mounted) return;
    setState(() {
      if (r['success'] == true) {
        _annee = '${r['annee']}';
        _annees = ((r['annees'] as List?) ?? const []).map((e) => '$e').toList();
        if (!_annees.contains(_annee)) _annees.insert(0, _annee!);
      }
      _pret = true;
    });
  }

  void _changerAnnee(String a) {
    setState(() => _annee = a);
  }

  @override
  Widget build(BuildContext context) {
    if (!_pret) return const Center(child: CircularProgressIndicator());
    return Container(
      color: finFond,
      child: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.account_balance_wallet_rounded, color: finBleu),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Finances', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: finTexte)),
              ),
              if (FinDroits.admin)
              PopupMenuButton<String>(
                tooltip: "Année académique",
                onSelected: _changerAnnee,
                itemBuilder: (_) => [for (final a in _annees) PopupMenuItem(value: a, child: Text(a))],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: finFond, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.calendar_month_rounded, size: 16, color: finBleu),
                    const SizedBox(width: 6),
                    Text(_annee ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: finBleu)),
                    const Icon(Icons.arrow_drop_down_rounded, color: finBleu),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
            ]),
            TabBar(
              controller: _tab!,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: finBleu,
              unselectedLabelColor: finGris,
              indicatorColor: finBleu,
              tabs: [
                if (FinDroits.admin) const Tab(text: 'Tableau de bord'),
                if (FinDroits.admin) const Tab(text: 'Grille tarifaire'),
                if (!FinDroits.admin) const Tab(text: 'Caisse'),
                const Tab(text: 'Étudiants'),
                if (FinDroits.admin) const Tab(text: 'Caisse'),
                const Tab(text: 'Journal'),
                if (FinDroits.admin) const Tab(text: 'Dépenses'),
              ],
            ),
          ]),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab!,
            children: [
              if (FinDroits.admin) _TabRapport(key: ValueKey('rap$_annee'), annee: _annee),
              if (FinDroits.admin) AdminFinancesGrille(
                key: ValueKey('gri$_annee'),
                annee: _annee,
                onChangeAnnee: (a) async {
                  _annee = a;
                  await _chargerAnnees();
                },
              ),
              if (!FinDroits.admin) const AdminFinancesCaisse(),
              AdminFinancesEtudiants(key: ValueKey('etu$_annee'), annee: _annee),
              if (FinDroits.admin) const AdminFinancesCaisse(),
              const AdminFinancesJournal(),
              if (FinDroits.admin) _TabDepenses(key: ValueKey('dep$_annee'), annee: _annee),
            ],
          ),
        ),
      ]),
    );
  }
}

// ═══ Tableau de bord ═══════════════════════════════════════════
class _TabRapport extends StatefulWidget {
  final String? annee;
  const _TabRapport({super.key, required this.annee});
  @override
  State<_TabRapport> createState() => _TabRapportState();
}

class _TabRapportState extends State<_TabRapport> {
  Map<String, dynamic>? _d;
  String? _erreur;
  bool _charge = true;

  @override
  void initState() {
    super.initState();
    _recharger();
  }

  Future<void> _recharger() async {
    final r = await FinanceService.rapport(widget.annee);
    if (!mounted) return;
    setState(() {
      _charge = false;
      if (r['success'] == true) {
        _d = r;
        _erreur = null;
      } else {
        _erreur = '${r['message']}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_charge) return const Center(child: CircularProgressIndicator());
    if (_d == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_erreur ?? 'Erreur', style: const TextStyle(color: finRouge)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () { setState(() => _charge = true); _recharger(); }, child: const Text('Réessayer')),
        ]),
      );
    }
    final k = Map<String, dynamic>.from(_d!['kpis'] as Map);
    final mensuel = ((_d!['mensuel'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final modes = ((_d!['par_mode'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final cats = ((_d!['depenses_par_categorie'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final solde = finNum(_d!['solde']);

    Widget grille(List<Widget> w) => LayoutBuilder(builder: (c, box) {
          final deux = box.maxWidth > 560;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [for (final x in w) SizedBox(width: deux ? (box.maxWidth - 10) / 2 : box.maxWidth, child: x)],
          );
        });

    return RefreshIndicator(
      onRefresh: _recharger,
      child: ListView(padding: const EdgeInsets.all(14), children: [
        grille([
          FinKpi(titre: 'Total attendu', valeur: fcfa(k['attendu']), icone: Icons.request_quote_rounded, couleur: finBleu),
          FinKpi(titre: 'Encaissé', valeur: fcfa(k['encaisse']), icone: Icons.payments_rounded, couleur: finVert, sous: 'Taux : ${k['taux']} %'),
          FinKpi(titre: 'Reste à encaisser', valeur: fcfa(k['reste']), icone: Icons.hourglass_bottom_rounded, couleur: finOrange),
          FinKpi(
            titre: 'En retard',
            valeur: fcfa(k['montant_en_retard']),
            icone: Icons.warning_amber_rounded,
            couleur: finRouge,
            sous: '${k['nb_en_retard']} étudiant(s)',
          ),
          FinKpi(titre: 'Étudiants avec impayé', valeur: '${k['nb_impayes']}', icone: Icons.people_alt_rounded, couleur: finBleu),
          FinKpi(titre: 'Accès notes bloqué', valeur: '${k['nb_bloques']}', icone: Icons.lock_rounded, couleur: finGris),
        ]),
        const SizedBox(height: 14),
        FinCarte(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Recettes et dépenses par mois', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 4),
            Row(children: [
              _legende(finBleu, 'Recettes ${fcfa(_d!['recettes'])}'),
              const SizedBox(width: 14),
              _legende(finJaune, 'Dépenses ${fcfa(_d!['depenses'])}'),
            ]),
            const SizedBox(height: 4),
            Text('Solde : ${fcfa(solde)}',
                style: TextStyle(fontWeight: FontWeight.w800, color: solde >= 0 ? finVert : finRouge)),
            const SizedBox(height: 14),
            _Barres(mensuel: mensuel),
          ]),
        ),
        const SizedBox(height: 14),
        if (modes.isNotEmpty)
          FinCarte(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Recettes par mode de paiement', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 10),
              for (final m in modes) _ligneProgression('${m['label']}', finNum(m['total']), modes.fold<num>(0, (s, e) => s + finNum(e['total'])), finBleu),
            ]),
          ),
        const SizedBox(height: 14),
        if (cats.isNotEmpty)
          FinCarte(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Dépenses par catégorie', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 10),
              for (final c in cats) _ligneProgression(_libCategorie('${c['categorie']}'), finNum(c['total']), cats.fold<num>(0, (s, e) => s + finNum(e['total'])), finOrange),
            ]),
          ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _legende(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(t, style: const TextStyle(fontSize: 12, color: finGris)),
      ]);

  Widget _ligneProgression(String nom, num valeur, num total, Color c) {
    final p = total > 0 ? (valeur / total).clamp(0.0, 1.0).toDouble() : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text(nom, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(fcfa(valeur), style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: p, minHeight: 7, color: c, backgroundColor: finFond),
        ),
      ]),
    );
  }
}

String _libCategorie(String c) {
  const m = {
    'salaires': 'Salaires',
    'loyer': 'Loyer',
    'fournitures': 'Fournitures',
    'maintenance': 'Maintenance',
    'eau_electricite': 'Eau et électricité',
    'transport': 'Transport',
    'communication': 'Communication',
    'autre': 'Autre',
  };
  return m[c] ?? c;
}

class _Barres extends StatelessWidget {
  final List<Map<String, dynamic>> mensuel;
  const _Barres({required this.mensuel});
  @override
  Widget build(BuildContext context) {
    num max = 1;
    for (final m in mensuel) {
      final a = finNum(m['recettes']);
      final b = finNum(m['depenses']);
      if (a > max) max = a;
      if (b > max) max = b;
    }
    const hauteur = 120.0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final m in mensuel)
          Container(
            width: 52,
            margin: const EdgeInsets.only(right: 6),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                height: hauteur,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
                  _barre(finNum(m['recettes']) / max * hauteur, finBleu),
                  const SizedBox(width: 3),
                  _barre(finNum(m['depenses']) / max * hauteur, finJaune),
                ]),
              ),
              const SizedBox(height: 4),
              Text(moisCourt('${m['mois']}'), style: const TextStyle(fontSize: 11, color: finGris)),
            ]),
          ),
      ]),
    );
  }

  Widget _barre(double h, Color c) => Container(
        width: 16,
        height: h < 2 && h > 0 ? 2 : h,
        decoration: BoxDecoration(color: c, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
      );
}

// ═══ Dépenses ══════════════════════════════════════════════════
class _TabDepenses extends StatefulWidget {
  final String? annee;
  const _TabDepenses({super.key, required this.annee});
  @override
  State<_TabDepenses> createState() => _TabDepensesState();
}

class _TabDepensesState extends State<_TabDepenses> {
  List<Map<String, dynamic>> _liste = [];
  List<String> _categories = [];
  num _total = 0;
  bool _charge = true;
  String? _filtre;

  @override
  void initState() {
    super.initState();
    _recharger();
  }

  Future<void> _recharger() async {
    final r = await FinanceService.depenses(widget.annee);
    if (!mounted) return;
    setState(() {
      _charge = false;
      if (r['success'] == true) {
        _liste = ((r['data'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _categories = ((r['categories'] as List?) ?? const []).map((e) => '$e').toList();
        _total = finNum(r['total']);
      }
    });
  }

  Future<void> _ajouter() async {
    final libelle = TextEditingController();
    final montant = TextEditingController();
    final benef = TextEditingController();
    String cat = 'autre';
    DateTime date = DateTime.now();
    final ok = await finFeuille<bool>(context, titre: 'Nouvelle dépense', contenu: (c) {
      return StatefulBuilder(builder: (c, setS) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: libelle, decoration: finChamp('Libellé (ex. Salaire de novembre)')),
          const SizedBox(height: 10),
          TextField(controller: montant, keyboardType: TextInputType.number, decoration: finChamp('Montant', suffixe: 'FCFA')),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final k in _categories)
              ChoiceChip(label: Text(_libCategorie(k)), selected: cat == k, onSelected: (_) => setS(() => cat = k)),
          ]),
          const SizedBox(height: 10),
          TextField(controller: benef, decoration: finChamp('Bénéficiaire (facultatif)')),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.event_rounded),
            label: Text('Date : ${dateFr(date.toIso8601String())}'),
            onPressed: () async {
              final d = await showDatePicker(context: c, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (d != null) setS(() => date = d);
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: finBleu, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () async {
                final m = int.tryParse(montant.text.replaceAll(' ', '')) ?? 0;
                if (libelle.text.trim().isEmpty || m <= 0) {
                  finMessage(c, 'Renseigne un libellé et un montant.', erreur: true);
                  return;
                }
                final r = await FinanceService.creerDepense({
                  'libelle': libelle.text.trim(),
                  'categorie': cat,
                  'montant': m,
                  'date_depense': dateIso(date),
                  'beneficiaire': benef.text.trim(),
                });
                if (!c.mounted) return;
                if (r['success'] == true) {
                  Navigator.pop(c, true);
                } else {
                  finMessage(c, '${r['message']}', erreur: true);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ),
        ]);
      });
    });
    if (ok == true) _recharger();
  }

  Future<void> _supprimer(Map<String, dynamic> d) async {
    final oui = await finConfirmer(context, 'Supprimer cette dépense ?', '${d['libelle']} — ${fcfa(d['montant'])}', oui: 'Supprimer', danger: true);
    if (!oui) return;
    final r = await FinanceService.supprimerDepense(d['id']);
    if (!mounted) return;
    if (r['success'] == true) {
      _recharger();
    } else {
      finMessage(context, '${r['message']}', erreur: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_charge) return const Center(child: CircularProgressIndicator());
    final vues = _filtre == null ? _liste : _liste.where((d) => d['categorie'] == _filtre).toList();
    final totalVu = vues.fold<num>(0, (s, d) => s + finNum(d['montant']));
    return Scaffold(
      backgroundColor: finFond,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: finBleu,
        foregroundColor: Colors.white,
        onPressed: _ajouter,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Dépense'),
      ),
      body: RefreshIndicator(
        onRefresh: _recharger,
        child: ListView(padding: const EdgeInsets.fromLTRB(14, 14, 14, 90), children: [
          FinKpi(titre: _filtre == null ? 'Total des dépenses' : 'Total (${_libCategorie(_filtre!)})', valeur: fcfa(_filtre == null ? _total : totalVu), icone: Icons.outbox_rounded, couleur: finOrange),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(label: const Text('Toutes'), selected: _filtre == null, onSelected: (_) => setState(() => _filtre = null)),
              ),
              for (final k in _categories)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(label: Text(_libCategorie(k)), selected: _filtre == k, onSelected: (_) => setState(() => _filtre = k)),
                ),
            ]),
          ),
          const SizedBox(height: 10),
          if (vues.isEmpty)
            const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('Aucune dépense enregistrée.', style: TextStyle(color: finGris)))),
          for (final d in vues)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FinCarte(
                child: Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: finOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.receipt_long_rounded, color: finOrange, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${d['libelle']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        '${_libCategorie('${d['categorie']}')} · ${dateFr(d['date_depense'])}${(d['beneficiaire'] ?? '').toString().isEmpty ? '' : ' · ${d['beneficiaire']}'}',
                        style: const TextStyle(fontSize: 12, color: finGris),
                      ),
                    ]),
                  ),
                  Text(fcfa(d['montant']), style: const TextStyle(fontWeight: FontWeight.w800)),
                  IconButton(
                    tooltip: 'Supprimer',
                    icon: const Icon(Icons.delete_outline_rounded, color: finRouge, size: 20),
                    onPressed: () => _supprimer(d),
                  ),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

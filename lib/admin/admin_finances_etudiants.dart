// lib/admin/admin_finances_etudiants.dart
// Situation de chaque étudiant : impayés, encaissement, remises, relances et
// blocage de l'accès aux notes.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../pages/finance_ui.dart';
import '../services/finance_service.dart';

class AdminFinancesEtudiants extends StatefulWidget {
  final String? annee;
  const AdminFinancesEtudiants({super.key, required this.annee});
  @override
  State<AdminFinancesEtudiants> createState() => _AdminFinancesEtudiantsState();
}

class _AdminFinancesEtudiantsState extends State<AdminFinancesEtudiants> {
  List<Map<String, dynamic>> _tous = [];
  bool _charge = true;
  String? _erreur;
  String _statut = 'tous';
  String? _filiere;
  String? _niveau;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _recharger();
  }

  Future<void> _recharger() async {
    final r = await FinanceService.etudiants(annee: widget.annee);
    if (!mounted) return;
    setState(() {
      _charge = false;
      if (r['success'] == true) {
        _tous = ((r['data'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _erreur = null;
      } else {
        _erreur = '${r['message']}';
      }
    });
  }

  List<Map<String, dynamic>> get _vues {
    final q = _q.trim().toLowerCase();
    return _tous.where((e) {
      if (_filiere != null && '${e['filiere_nom']}' != _filiere) return false;
      if (_niveau != null && '${e['niveau']}' != _niveau) return false;
      if (q.isNotEmpty && !'${e['nom']} ${e['prenoms']} ${e['matricule']}'.toLowerCase().contains(q)) return false;
      switch (_statut) {
        case 'impayes':
          return finNum(e['reste']) > 0;
        case 'en_retard':
          return finNum(e['montant_en_retard']) > 0;
        case 'bloques':
          return e['bloque'] == true;
        case 'a_jour':
          return e['statut'] == 'a_jour';
      }
      return true;
    }).toList();
  }

  Future<void> _relancerListe(List<Map<String, dynamic>> cibles) async {
    final impayes = cibles.where((e) => finNum(e['reste']) > 0).toList();
    if (impayes.isEmpty) {
      finMessage(context, 'Aucun impayé dans cette liste.');
      return;
    }
    await ouvrirRelance(context, ids: impayes.map((e) => e['id']).toList(), nb: impayes.length, annee: widget.annee);
    _recharger();
  }

  Future<void> _bloquerRetardataires() async {
    final cibles = _vues.where((e) => finNum(e['montant_en_retard']) > 0 && e['bloque'] != true).toList();
    if (cibles.isEmpty) {
      finMessage(context, 'Personne à bloquer dans cette liste.');
      return;
    }
    final oui = await finConfirmer(
      context,
      "Bloquer l'accès aux notes ?",
      '${cibles.length} étudiant(s) en retard de paiement ne verront plus leurs notes ni leur bulletin (leurs parents non plus) tant que tu ne les débloques pas.',
      oui: 'Bloquer',
      danger: true,
    );
    if (!oui) return;
    final r = await FinanceService.blocage(cibles.map((e) => e['id']).toList(), true, motif: 'Scolarité à régulariser');
    if (!mounted) return;
    finMessage(context, r['success'] == true ? '${r['modifies']} accès bloqué(s).' : '${r['message']}', erreur: r['success'] != true);
    _recharger();
  }

  @override
  Widget build(BuildContext context) {
    if (_charge) return const Center(child: CircularProgressIndicator());
    final vues = _vues;
    final filieres = _tous.map((e) => '${e['filiere_nom'] ?? ''}').where((x) => x.isNotEmpty).toSet().toList()..sort();
    final niveaux = _tous.map((e) => '${e['niveau'] ?? ''}').where((x) => x.isNotEmpty).toSet().toList()..sort();
    final reste = vues.fold<num>(0, (s, e) => s + finNum(e['reste']));
    return Container(
      color: finFond,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Column(children: [
            TextField(
              decoration: finChamp('Rechercher un nom ou un matricule').copyWith(prefixIcon: const Icon(Icons.search_rounded)),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final s in const [
                  ['tous', 'Tous'],
                  ['impayes', 'Impayés'],
                  ['en_retard', 'En retard'],
                  ['bloques', 'Bloqués'],
                  ['a_jour', 'À jour'],
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(label: Text(s[1]), selected: _statut == s[0], onSelected: (_) => setState(() => _statut = s[0])),
                  ),
              ]),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: _filtre('Filière', _filiere, filieres, (v) => setState(() => _filiere = v))),
              const SizedBox(width: 8),
              Expanded(child: _filtre('Niveau', _niveau, niveaux, (v) => setState(() => _niveau = v))),
            ]),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 2, 6, 2),
          child: Row(children: [
            Expanded(
              child: Text('${vues.length} étudiant(s) · reste ${fcfa(reste)}', style: const TextStyle(fontSize: 12.5, color: finGris, fontWeight: FontWeight.w600)),
            ),
            if (FinDroits.admin)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) {
                if (v == 'relancer') _relancerListe(vues);
                if (v == 'bloquer') _bloquerRetardataires();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'relancer', child: Text('Relancer les impayés de cette liste')),
                PopupMenuItem(value: 'bloquer', child: Text("Bloquer l'accès aux notes des retardataires")),
              ],
            ),
          ]),
        ),
        if (_erreur != null) Padding(padding: const EdgeInsets.all(12), child: Text(_erreur!, style: const TextStyle(color: finRouge))),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _recharger,
            child: vues.isEmpty
                ? ListView(children: const [Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Aucun étudiant.', style: TextStyle(color: finGris))))])
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                    itemCount: vues.length,
                    itemBuilder: (c, i) => _ligne(vues[i]),
                  ),
          ),
        ),
      ]),
    );
  }

  Widget _filtre(String titre, String? valeur, List<String> options, ValueChanged<String?> onChange) {
    return PopupMenuButton<String>(
      onSelected: (v) => onChange(v == '__tous__' ? null : v),
      itemBuilder: (_) => [
        PopupMenuItem(value: '__tous__', child: Text('$titre : toutes')),
        for (final o in options) PopupMenuItem(value: o, child: Text(o)),
      ],
      child: InputDecorator(
        decoration: finChamp(titre),
        child: Row(children: [
          Expanded(child: Text(valeur ?? 'Tous', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
          const Icon(Icons.arrow_drop_down_rounded, size: 20),
        ]),
      ),
    );
  }

  Widget _ligne(Map<String, dynamic> e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FinCarte(
        onTap: () async {
          final change = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => FicheFinanceEtudiant(etudiantId: e['id'], annee: widget.annee)),
          );
          if (change == true) _recharger();
        },
        child: Row(children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: finBleu.withValues(alpha: 0.1),
            child: Text(
              _initiales(e),
              style: const TextStyle(color: finBleu, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text('${e['nom']} ${e['prenoms'] ?? ''}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                if (e['bloque'] == true) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.lock_rounded, size: 15, color: finRouge)),
              ]),
              Text('${e['matricule'] ?? ''} · ${e['filiere_nom'] ?? ''} ${e['niveau'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: finGris)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(finNum(e['reste']) > 0 ? fcfa(e['reste']) : 'Soldé', style: TextStyle(fontWeight: FontWeight.w800, color: finNum(e['reste']) > 0 ? finTexte : finVert)),
            const SizedBox(height: 3),
            FinPastille('${e['statut']}'),
          ]),
        ]),
      ),
    );
  }
}

String _initiales(Map<String, dynamic> e) {
  final p = ('${e['prenoms'] ?? ''}').trim();
  final n = ('${e['nom'] ?? ''}').trim();
  return ((p.isEmpty ? '' : p[0]) + (n.isEmpty ? '' : n[0])).toUpperCase();
}

// ═══ Relance (notification, SMS, WhatsApp, page étudiant/parent) ═══
Future<void> ouvrirRelance(BuildContext context, {List<dynamic>? ids, required int nb, String? annee}) async {
  bool notif = true;
  bool sms = true;
  bool wa = false;
  final msg = TextEditingController();
  bool envoi = false;
  List<Map<String, dynamic>> liens = [];
  String? bilan;

  await finFeuille<void>(context, titre: 'Relancer $nb étudiant(s)', contenu: (c) {
    return StatefulBuilder(builder: (c, setS) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          "Le rappel apparaît aussi sur la page « Ma scolarité » de l'étudiant et de son parent.",
          style: TextStyle(fontSize: 12.5, color: finGris),
        ),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: notif, onChanged: (v) => setS(() => notif = v ?? false), title: const Text("Notification dans l'application (étudiant et parent)")),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: sms, onChanged: (v) => setS(() => sms = v ?? false), title: const Text('SMS au parent')),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: wa, onChanged: (v) => setS(() => wa = v ?? false), title: const Text('WhatsApp (tu valides l\'envoi, un message à la fois)')),
        const SizedBox(height: 6),
        TextField(
          controller: msg,
          maxLines: 3,
          decoration: finChamp('Message (facultatif)', aide: 'Vide : un message automatique avec le montant restant est envoyé.'),
        ),
        const SizedBox(height: 12),
        if (bilan != null) Text(bilan!, style: const TextStyle(fontWeight: FontWeight.w700, color: finVert)),
        for (final l in liens)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.chat_rounded, color: finVert),
            title: Text('${l['nom']}'),
            trailing: TextButton(
              onPressed: () => launchUrl(Uri.parse('${l['url']}'), mode: LaunchMode.externalApplication),
              child: const Text('Ouvrir WhatsApp'),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: finBleu, padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: const Icon(Icons.send_rounded),
            label: Text(envoi ? 'Envoi…' : 'Envoyer la relance'),
            onPressed: envoi
                ? null
                : () async {
                    final canaux = [if (notif) 'notification', if (sms) 'sms', if (wa) 'whatsapp'];
                    if (canaux.isEmpty) {
                      finMessage(c, 'Choisis au moins un canal.', erreur: true);
                      return;
                    }
                    setS(() => envoi = true);
                    final r = await FinanceService.relancer(ids: ids, canaux: canaux, message: msg.text, annee: annee);
                    if (!c.mounted) return;
                    setS(() {
                      envoi = false;
                      if (r['success'] == true) {
                        bilan = '${r['cibles']} relancé(s) · ${r['notifications']} notification(s) · ${r['sms']} SMS';
                        liens = ((r['whatsapp'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
                      } else {
                        finMessage(c, '${r['message']}', erreur: true);
                      }
                    });
                  },
          ),
        ),
      ]);
    });
  });
}

// ═══ Fiche d'un étudiant ═══════════════════════════════════════
class FicheFinanceEtudiant extends StatefulWidget {
  final dynamic etudiantId;
  final String? annee;
  const FicheFinanceEtudiant({super.key, required this.etudiantId, required this.annee});
  @override
  State<FicheFinanceEtudiant> createState() => _FicheFinanceEtudiantState();
}

class _FicheFinanceEtudiantState extends State<FicheFinanceEtudiant> {
  Map<String, dynamic>? _d;
  bool _charge = true;
  bool _modifie = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _recharger();
  }

  Future<void> _recharger() async {
    final r = await FinanceService.detailEtudiant(widget.etudiantId, widget.annee);
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

  Map<String, dynamic> get _etu => Map<String, dynamic>.from(_d!['etudiant'] as Map);
  Map<String, dynamic> get _sit => Map<String, dynamic>.from(_d!['situation'] as Map);
  List<Map<String, dynamic>> _liste(String k) => ((_d![k] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  Future<void> _encaisser() async {
    final id = await finFeuille<dynamic>(context, titre: 'Encaisser un paiement', contenu: (c) => FinFormEncaisser(etudiantId: widget.etudiantId, reste: finNum(_sit['reste']), annee: widget.annee));
    if (id == null) return;
    _modifie = true;
    await _recharger();
    if (!mounted) return;
    final voir = await finConfirmer(context, 'Paiement enregistré', 'Veux-tu afficher le reçu ?', oui: 'Voir le reçu');
    if (voir && mounted) await ouvrirRecu(context, id);
  }

  Future<void> _remise() async {
    final montant = TextEditingController();
    final motif = TextEditingController();
    final ok = await finFeuille<bool>(context, titre: 'Accorder une remise ou une bourse', contenu: (c) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('La remise réduit le total que cet étudiant doit payer.', style: TextStyle(fontSize: 12.5, color: finGris)),
        const SizedBox(height: 10),
        TextField(controller: montant, keyboardType: TextInputType.number, decoration: finChamp('Montant de la remise', suffixe: 'FCFA')),
        const SizedBox(height: 10),
        TextField(controller: motif, decoration: finChamp('Motif (bourse, fratrie, geste commercial…)')),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: finBleu, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () async {
              final m = int.tryParse(montant.text.replaceAll(' ', '')) ?? 0;
              if (m <= 0) {
                finMessage(c, 'Saisis un montant.', erreur: true);
                return;
              }
              final r = await FinanceService.ajouterRemise(widget.etudiantId, m, motif.text.trim(), annee: widget.annee);
              if (!c.mounted) return;
              if (r['success'] == true) {
                Navigator.pop(c, true);
              } else {
                finMessage(c, '${r['message']}', erreur: true);
              }
            },
            child: const Text('Enregistrer la remise'),
          ),
        ),
      ]);
    });
    if (ok == true) {
      _modifie = true;
      _recharger();
    }
  }

  Future<void> _basculerBlocage() async {
    final bloque = _sit['bloque'] == true;
    if (!bloque) {
      final oui = await finConfirmer(context, "Bloquer l'accès aux notes ?", "${_etu['prenoms']} ${_etu['nom']} et ses parents ne verront plus les notes ni le bulletin.", oui: 'Bloquer', danger: true);
      if (!oui) return;
    }
    final r = await FinanceService.blocage([widget.etudiantId], !bloque, motif: 'Scolarité à régulariser');
    if (!mounted) return;
    if (r['success'] == true) {
      _modifie = true;
      finMessage(context, bloque ? 'Accès rétabli.' : 'Accès aux notes bloqué.');
      _recharger();
    } else {
      finMessage(context, '${r['message']}', erreur: true);
    }
  }

  Future<void> _annuler(Map<String, dynamic> v) async {
    final motif = TextEditingController();
    final oui = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Annuler ce versement ?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${fcfa(v['montant'])} · ${dateFr(v['created_at'])}'),
          const SizedBox(height: 10),
          TextField(controller: motif, decoration: finChamp("Motif de l'annulation (obligatoire)")),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Retour')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: finRouge), onPressed: () => Navigator.pop(c, true), child: const Text('Annuler le versement')),
        ],
      ),
    );
    final texte = motif.text.trim();
    if (oui != true) return;
    if (texte.isEmpty) {
      if (mounted) finMessage(context, "Le motif est obligatoire.", erreur: true);
      return;
    }
    final r = await FinanceService.annulerVersement(v['id'], texte);
    if (!mounted) return;
    if (r['success'] == true) {
      _modifie = true;
      _recharger();
    } else {
      finMessage(context, '${r['message']}', erreur: true);
    }
  }

  Future<void> _supprimerRemise(Map<String, dynamic> r0) async {
    final oui = await finConfirmer(context, 'Retirer cette remise ?', '${fcfa(r0['montant'])} sera de nouveau à payer.', oui: 'Retirer', danger: true);
    if (!oui) return;
    final r = await FinanceService.supprimerRemise(r0['id']);
    if (!mounted) return;
    if (r['success'] == true) {
      _modifie = true;
      _recharger();
    } else {
      finMessage(context, '${r['message']}', erreur: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _modifie);
      },
      child: Scaffold(
        backgroundColor: finFond,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: finTexte,
          elevation: 0,
          title: Text(_d == null ? 'Scolarité' : '${_etu['prenoms']} ${_etu['nom']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
        body: _charge
            ? const Center(child: CircularProgressIndicator())
            : _d == null
                ? Center(child: Text(_erreur ?? 'Erreur', style: const TextStyle(color: finRouge)))
                : _corps(),
      ),
    );
  }

  Widget _corps() {
    final s = _sit;
    final etu = _etu;
    final lignes = ((s['lignes'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final versements = _liste('versements');
    final remises = _liste('remises');
    final relances = _liste('relances');
    final bloque = s['bloque'] == true;

    return RefreshIndicator(
      onRefresh: _recharger,
      child: ListView(padding: const EdgeInsets.all(14), children: [
        FinCarte(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text('${etu['matricule'] ?? ''} · ${etu['filiere_nom'] ?? ''} ${etu['niveau'] ?? ''}', style: const TextStyle(color: finGris, fontSize: 13)),
              ),
              FinPastille('${s['statut']}'),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _chiffre('À payer', fcfa(s['net_a_payer']), finTexte),
              _chiffre('Payé', fcfa(s['paye']), finVert),
              _chiffre('Reste', fcfa(s['reste']), finNum(s['reste']) > 0 ? finOrange : finVert),
            ]),
            if (finNum(s['remises']) > 0) Padding(padding: const EdgeInsets.only(top: 6), child: Text('dont remises : ${fcfa(s['remises'])}', style: const TextStyle(fontSize: 12, color: finGris))),
            if (finNum(s['montant_en_retard']) > 0)
              Padding(padding: const EdgeInsets.only(top: 6), child: Text('En retard : ${fcfa(s['montant_en_retard'])}', style: const TextStyle(fontWeight: FontWeight.w700, color: finRouge))),
            if (finNum(s['excedent']) > 0)
              Padding(padding: const EdgeInsets.only(top: 6), child: Text('Trop-perçu : ${fcfa(s['excedent'])}', style: const TextStyle(fontWeight: FontWeight.w700, color: finOrange))),
          ]),
        ),
        const SizedBox(height: 10),
        if (bloque)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: finRouge.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.lock_rounded, color: finRouge),
              const SizedBox(width: 10),
              Expanded(child: Text("Accès aux notes et au bulletin bloqué${(s['motif_blocage'] ?? '').toString().isEmpty ? '' : ' : ${s['motif_blocage']}'}", style: const TextStyle(color: finRouge, fontWeight: FontWeight.w600))),
            ]),
          ),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: finBleu), onPressed: _encaisser, icon: const Icon(Icons.add_card_rounded, size: 18), label: const Text('Encaisser')),
          if (FinDroits.admin) OutlinedButton.icon(onPressed: _remise, icon: const Icon(Icons.percent_rounded, size: 18), label: const Text('Remise')),
          if (FinDroits.admin) OutlinedButton.icon(
            onPressed: finNum(s['reste']) > 0
                ? () async {
                    await ouvrirRelance(context, ids: [widget.etudiantId], nb: 1, annee: widget.annee);
                    _modifie = true;
                    _recharger();
                  }
                : null,
            icon: const Icon(Icons.notifications_active_rounded, size: 18),
            label: const Text('Relancer'),
          ),
          if (FinDroits.admin) OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: bloque ? finVert : finRouge),
            onPressed: _basculerBlocage,
            icon: Icon(bloque ? Icons.lock_open_rounded : Icons.lock_rounded, size: 18),
            label: Text(bloque ? "Rétablir l'accès" : 'Bloquer les notes'),
          ),
        ]),
        const SizedBox(height: 16),
        const Text('Échéancier', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 8),
        if (lignes.isEmpty) const Text('Aucun frais ne correspond à cet étudiant dans la grille.', style: TextStyle(color: finGris)),
        for (final l in lignes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FinCarte(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('${l['libelle']}', style: const TextStyle(fontWeight: FontWeight.w800))),
                  Text(fcfa(l['montant_total']), style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                for (final t in ((l['tranches'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      Expanded(
                        child: Text('${t['libelle'] ?? 'Tranche ${t['numero']}'}${t['echeance'] == null ? '' : ' · avant le ${dateFr(t['echeance'])}'}', style: const TextStyle(fontSize: 13)),
                      ),
                      Text(fcfa(t['montant'], unite: false), style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      FinPastille('${t['statut']}'),
                    ]),
                  ),
              ]),
            ),
          ),
        const SizedBox(height: 10),
        const Text('Versements', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 8),
        if (versements.isEmpty) const Text('Aucun versement.', style: TextStyle(color: finGris)),
        for (final v in versements)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FinCarte(
              child: Row(children: [
                Icon(v['statut'] == 'reussi' ? Icons.check_circle_rounded : (v['statut'] == 'annule' ? Icons.cancel_rounded : Icons.schedule_rounded),
                    color: v['statut'] == 'reussi' ? finVert : (v['statut'] == 'annule' ? finRouge : finOrange)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(fcfa(v['montant']), style: TextStyle(fontWeight: FontWeight.w800, decoration: v['statut'] == 'annule' ? TextDecoration.lineThrough : null)),
                    Text('${v['mode_label'] ?? v['mode']} · ${dateFr(v['created_at'])}${v['numero_recu'] == null ? '' : ' · ${v['numero_recu']}'}', style: const TextStyle(fontSize: 12, color: finGris)),
                    if (v['statut'] == 'annule') Text('Annulé : ${v['motif_annulation'] ?? ''}', style: const TextStyle(fontSize: 12, color: finRouge)),
                    if (v['statut'] == 'en_attente') const Text('En attente de confirmation', style: TextStyle(fontSize: 12, color: finOrange)),
                  ]),
                ),
                if (v['statut'] == 'reussi') ...[
                  IconButton(tooltip: 'Reçu', icon: const Icon(Icons.receipt_long_rounded, color: finBleu), onPressed: () => ouvrirRecu(context, v['id'])),
                  if (FinDroits.admin) IconButton(tooltip: 'Annuler', icon: const Icon(Icons.undo_rounded, color: finRouge, size: 20), onPressed: () => _annuler(v)),
                ],
              ]),
            ),
          ),
        if (remises.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text('Remises et bourses', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          for (final r in remises)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FinCarte(
                child: Row(children: [
                  const Icon(Icons.percent_rounded, color: finBleu),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${fcfa(r['montant'])}${(r['motif'] ?? '').toString().isEmpty ? '' : ' · ${r['motif']}'}')),
                  if (FinDroits.admin) IconButton(icon: const Icon(Icons.delete_outline_rounded, color: finRouge, size: 20), onPressed: () => _supprimerRemise(r)),
                ]),
              ),
            ),
        ],
        if (relances.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text('Dernières relances', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          for (final r in relances)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${dateFr(r['created_at'])} · ${((r['canaux'] as List?) ?? const []).join(', ')}', style: const TextStyle(fontSize: 12.5, color: finGris)),
            ),
        ],
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _chiffre(String t, String v, Color c) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: const TextStyle(fontSize: 12, color: finGris)),
          const SizedBox(height: 2),
          Text(v, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: c)),
        ]),
      );
}

// ═══ Formulaire d'encaissement ═════════════════════════════════
/// Formulaire d'encaissement (utilisé par la fiche étudiant et par l'onglet Caisse).
class FinFormEncaisser extends StatefulWidget {
  final dynamic etudiantId;
  final num reste;
  final String? annee;
  const FinFormEncaisser({super.key, required this.etudiantId, required this.reste, this.annee});
  @override
  State<FinFormEncaisser> createState() => FinFormEncaisserState();
}

class FinFormEncaisserState extends State<FinFormEncaisser> {
  late final TextEditingController _montant = TextEditingController(text: widget.reste > 0 ? '${widget.reste.round()}' : '');
  final TextEditingController _ref = TextEditingController();
  final TextEditingController _note = TextEditingController();
  String _mode = 'especes';
  bool _envoi = false;

  @override
  void dispose() {
    _montant.dispose();
    _ref.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final m = int.tryParse(_montant.text.replaceAll(' ', '')) ?? 0;
    if (m <= 0) {
      finMessage(context, 'Saisis un montant.', erreur: true);
      return;
    }
    if ((_mode == 'virement' || _mode == 'cheque') && _ref.text.trim().isEmpty) {
      finMessage(context, _mode == 'cheque' ? 'Saisis le numéro du chèque.' : 'Saisis la référence du virement.', erreur: true);
      return;
    }
    setState(() => _envoi = true);
    Map<String, dynamic> corps({bool exces = false}) => {
          'etudiant_id': widget.etudiantId,
          'montant': m,
          'mode': _mode,
          'reference': _ref.text.trim(),
          'note': _note.text.trim(),
          if (exces) 'autoriser_excedent': true,
        };
    var r = await FinanceService.encaisser(corps(), annee: widget.annee);
    if (!mounted) return;
    if (r['status'] == 409 && r['code'] == 'EXCEDENT') {
      final oui = await finConfirmer(context, 'Trop-perçu', '${r['message']}', oui: 'Enregistrer quand même');
      if (!oui || !mounted) {
        setState(() => _envoi = false);
        return;
      }
      r = await FinanceService.encaisser(corps(exces: true), annee: widget.annee);
      if (!mounted) return;
    }
    setState(() => _envoi = false);
    if (r['success'] == true) {
      Navigator.pop(context, r['versement_id']);
    } else {
      finMessage(context, '${r['message']}', erreur: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.reste > 0) Text('Reste à payer : ${fcfa(widget.reste)}', style: const TextStyle(color: finGris, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      TextField(controller: _montant, keyboardType: TextInputType.number, decoration: finChamp('Montant reçu', suffixe: 'FCFA')),
      const SizedBox(height: 10),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final e in kModes.entries) ChoiceChip(label: Text(e.value), selected: _mode == e.key, onSelected: (_) => setState(() => _mode = e.key)),
      ]),
      const SizedBox(height: 10),
      TextField(controller: _ref, decoration: finChamp(_mode == 'cheque' ? 'N° du chèque (obligatoire)' : _mode == 'virement' ? 'Référence du virement (obligatoire)' : 'Référence (facultatif)')),
      const SizedBox(height: 10),
      TextField(controller: _note, decoration: finChamp('Note (facultatif)')),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: finBleu, padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: _envoi ? null : _valider,
          child: Text(_envoi ? 'Enregistrement…' : 'Enregistrer le paiement'),
        ),
      ),
    ]);
  }
}

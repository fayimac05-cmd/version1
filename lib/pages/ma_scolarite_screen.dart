// lib/pages/ma_scolarite_screen.dart
// « Ma scolarité » : situation de paiement de l'étudiant (ou de l'enfant, côté parent),
// échéancier, historique, reçus PDF et paiement mobile money.
//
// Étudiant : const MaScolariteScreen()
// Parent   : MaScolariteScreen(etudiantId: enfant.etudiantId, nomEnfant: '${enfant.prenoms} ${enfant.nom}')
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/finance_service.dart';
import 'finance_ui.dart';

const Map<String, String> _operateurs = {
  'orange_money': 'Orange Money',
  'moov_money': 'Moov Money',
  'wave': 'Wave',
};

class MaScolariteScreen extends StatefulWidget {
  final dynamic etudiantId; // null = l'étudiant connecté
  final String? nomEnfant;
  const MaScolariteScreen({super.key, this.etudiantId, this.nomEnfant});
  @override
  State<MaScolariteScreen> createState() => _MaScolariteScreenState();
}

class _MaScolariteScreenState extends State<MaScolariteScreen> {
  Map<String, dynamic>? _d;
  bool _charge = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _recharger();
  }

  Future<void> _recharger() async {
    final r = widget.etudiantId == null ? await FinanceService.maSituation() : await FinanceService.situationEnfant(widget.etudiantId);
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

  Map<String, dynamic> get _sit => Map<String, dynamic>.from(_d!['situation'] as Map);

  num get _prochaineTranche {
    final lignes = ((_sit['lignes'] as List?) ?? const []);
    for (final l in lignes) {
      for (final t in ((l as Map)['tranches'] as List? ?? const [])) {
        final m = Map<String, dynamic>.from(t as Map);
        if (finNum(m['reste']) > 0) return finNum(m['reste']);
      }
    }
    return finNum(_sit['reste']);
  }

  Future<void> _payer() async {
    final reste = finNum(_sit['reste']);
    final tranche = _prochaineTranche;
    final montant = TextEditingController(text: '${tranche.round()}');
    final tel = TextEditingController();
    String operateur = 'orange_money';
    bool envoi = false;

    final initPaiement = await finFeuille<Map<String, dynamic>>(context, titre: 'Payer par mobile money', contenu: (c) {
      return StatefulBuilder(builder: (c, setS) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Reste à payer : ${fcfa(reste)}', style: const TextStyle(color: finGris, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            ActionChip(label: Text('Prochaine tranche · ${fcfa(tranche, unite: false)}'), onPressed: () => setS(() => montant.text = '${tranche.round()}')),
            ActionChip(label: Text('Tout le solde · ${fcfa(reste, unite: false)}'), onPressed: () => setS(() => montant.text = '${reste.round()}')),
          ]),
          const SizedBox(height: 10),
          TextField(controller: montant, keyboardType: TextInputType.number, decoration: finChamp('Montant à payer', suffixe: 'FCFA')),
          const SizedBox(height: 10),
          Wrap(spacing: 6, children: [
            for (final e in _operateurs.entries) ChoiceChip(label: Text(e.value), selected: operateur == e.key, onSelected: (_) => setS(() => operateur = e.key)),
          ]),
          const SizedBox(height: 10),
          TextField(controller: tel, keyboardType: TextInputType.phone, decoration: finChamp('Numéro qui paie', aide: 'Ex. 70 12 34 56')),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: finBleu, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: envoi
                  ? null
                  : () async {
                      final m = int.tryParse(montant.text.replaceAll(' ', '')) ?? 0;
                      final t = tel.text.replaceAll(RegExp(r'\s'), '');
                      if (m <= 0 || t.length < 8) {
                        finMessage(c, 'Saisis le montant et un numéro valide.', erreur: true);
                        return;
                      }
                      setS(() => envoi = true);
                      final r = await FinanceService.payer(etudiantId: widget.etudiantId, montant: m, operateur: operateur, telephone: t);
                      if (!c.mounted) return;
                      setS(() => envoi = false);
                      if (r['success'] == true) {
                        Navigator.pop(c, r);
                      } else {
                        finMessage(c, '${r['message']}', erreur: true);
                      }
                    },
              child: Text(envoi ? 'Envoi…' : 'Payer'),
            ),
          ),
        ]);
      });
    });
    if (initPaiement == null || !mounted) return;
    await _finaliserPaiement(initPaiement);
  }

  Future<void> _finaliserPaiement(Map<String, dynamic> init) async {
    final url = '${init['payment_url'] ?? ''}';
    if (url.isNotEmpty) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
    if (!mounted) return;
    final otp = init['otp_requis'] != false;
    final code = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text(otp ? 'Code de confirmation' : 'Valide sur ton téléphone'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(otp
              ? 'Saisis le code reçu par SMS ou composé sur ton téléphone pour valider le paiement.'
              : 'Valide la demande de paiement sur ton téléphone, puis appuie sur « J\'ai validé ».'),
          if (otp) ...[
            const SizedBox(height: 12),
            TextField(controller: code, keyboardType: TextInputType.number, decoration: finChamp('Code')),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Plus tard')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(otp ? 'Confirmer' : "J'ai validé")),
        ],
      ),
    );
    final texte = code.text.trim();
    if (ok != true || !mounted) {
      _recharger();
      return;
    }
    final r = await FinanceService.confirmerPaiement(init['versement_id'], otp ? texte : null);
    if (!mounted) return;
    if (r['success'] == true) {
      await _recharger();
      if (!mounted) return;
      final voir = await finConfirmer(context, 'Paiement confirmé', 'Merci ! Veux-tu afficher ton reçu ?', oui: 'Voir le reçu');
      if (voir && mounted) await ouvrirRecu(context, r['versement_id'] ?? init['versement_id']);
    } else {
      finMessage(context, '${r['message']}', erreur: true);
      _recharger();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: finFond,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: finTexte,
        elevation: 0,
        title: Text(widget.nomEnfant == null ? 'Ma scolarité' : 'Scolarité de ${widget.nomEnfant}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: _charge
          ? const Center(child: CircularProgressIndicator())
          : _d == null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_erreur ?? 'Erreur', style: const TextStyle(color: finRouge)),
                    const SizedBox(height: 8),
                    OutlinedButton(onPressed: () { setState(() => _charge = true); _recharger(); }, child: const Text('Réessayer')),
                  ]),
                )
              : _corps(),
    );
  }

  Widget _corps() {
    final s = _sit;
    final lignes = ((s['lignes'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final versements = ((_d!['versements'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final rappel = _d!['rappel'] == null ? null : Map<String, dynamic>.from(_d!['rappel'] as Map);
    final net = finNum(s['net_a_payer']);
    final paye = finNum(s['paye']);
    final reste = finNum(s['reste']);
    final p = net > 0 ? (paye / net).clamp(0.0, 1.0).toDouble() : 0.0;

    return RefreshIndicator(
      onRefresh: _recharger,
      child: ListView(padding: const EdgeInsets.all(14), children: [
        if (s['bloque'] == true)
          _bandeau(
            finRouge,
            Icons.lock_rounded,
            "L'accès aux notes et aux bulletins est suspendu tant que la scolarité n'est pas régularisée. Rapproche-toi de l'administration.",
          ),
        if (rappel != null) _bandeau(finOrange, Icons.notifications_active_rounded, '${rappel['message']}'),
        FinCarte(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Année ${_d!['annee']}', style: const TextStyle(color: finGris, fontWeight: FontWeight.w600))),
              FinPastille('${s['statut']}'),
            ]),
            const SizedBox(height: 12),
            Text(reste > 0 ? fcfa(reste) : 'Scolarité soldée', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: reste > 0 ? finTexte : finVert)),
            if (reste > 0) const Text('restant à payer', style: TextStyle(color: finGris, fontSize: 12.5)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: p, minHeight: 9, color: finVert, backgroundColor: finFond),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text('Payé : ${fcfa(paye)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              Text('Total : ${fcfa(net)}', style: const TextStyle(fontSize: 13, color: finGris)),
            ]),
            if (finNum(s['remises']) > 0) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Remise accordée : ${fcfa(s['remises'])}', style: const TextStyle(fontSize: 12.5, color: finGris))),
            if (finNum(s['montant_en_retard']) > 0)
              Padding(padding: const EdgeInsets.only(top: 6), child: Text('Dont en retard : ${fcfa(s['montant_en_retard'])}', style: const TextStyle(fontWeight: FontWeight.w700, color: finRouge))),
            if (s['prochaine_echeance'] != null && reste > 0)
              Padding(padding: const EdgeInsets.only(top: 6), child: Text('Prochaine échéance : ${dateFr(s['prochaine_echeance'])}', style: const TextStyle(fontSize: 12.5, color: finGris))),
            if (reste > 0) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: finBleu, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _payer,
                  icon: const Icon(Icons.phone_android_rounded),
                  label: const Text('Payer maintenant'),
                ),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        const Text('Échéancier', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 8),
        if (lignes.isEmpty) const Text("Aucun frais n'est encore défini pour toi.", style: TextStyle(color: finGris)),
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
                      Expanded(child: Text('${t['libelle'] ?? 'Tranche ${t['numero']}'}${t['echeance'] == null ? '' : ' · avant le ${dateFr(t['echeance'])}'}', style: const TextStyle(fontSize: 13))),
                      Text(fcfa(t['montant'], unite: false), style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      FinPastille('${t['statut']}'),
                    ]),
                  ),
              ]),
            ),
          ),
        const SizedBox(height: 10),
        const Text('Mes paiements', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 8),
        if (versements.isEmpty) const Text('Aucun paiement pour le moment.', style: TextStyle(color: finGris)),
        for (final v in versements)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FinCarte(
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: finVert),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(fcfa(v['montant']), style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('${v['mode_label'] ?? v['mode']} · ${dateFr(v['confirmed_at'] ?? v['created_at'])}', style: const TextStyle(fontSize: 12, color: finGris)),
                  ]),
                ),
                TextButton.icon(onPressed: () => ouvrirRecu(context, v['id']), icon: const Icon(Icons.receipt_long_rounded, size: 18), label: const Text('Reçu')),
              ]),
            ),
          ),
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _bandeau(Color c, IconData i, String t) => Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withValues(alpha: 0.35))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(i, color: c),
          const SizedBox(width: 10),
          Expanded(child: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.w600, height: 1.3))),
        ]),
      );
}

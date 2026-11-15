import 'package:flutter/material.dart';
import '../services/cantine_service.dart';

/// Menu de la cantine côté étudiant : page plein écran ouverte depuis l'accueil
/// (Navigator.push). Le nom de classe reste « CantineSheet » pour ne pas toucher aux imports.
/// La photo de la bannière est lue dans `assets/images/cantine_etudiant.png`
/// (si le fichier est absent, la bannière reste simplement bleue).
class CantineSheet extends StatefulWidget {
  const CantineSheet({super.key});
  @override
  State<CantineSheet> createState() => _CantineSheetState();
}

const _bleu = Color(0xFF1E40AF);
const _bleuFonce = Color(0xFF0F2A5F);
const _bleuClair = Color(0xFFEAF1FF);

const _repasOptions = [
  {'val': 'petit_dejeuner', 'label': 'Petit-déjeuner', 'icon': Icons.coffee_rounded},
  {'val': 'dejeuner', 'label': 'Déjeuner', 'icon': Icons.restaurant_rounded},
  {'val': 'diner', 'label': 'Dîner', 'icon': Icons.nightlight_round},
];

const _jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
const _mois = ['Janv.', 'Févr.', 'Mars', 'Avr.', 'Mai', 'Juin', 'Juil.', 'Août', 'Sept.', 'Oct.', 'Nov.', 'Déc.'];

String _norm(String t) {
  const a = 'àâäáãéèêëíìîïóòôöõúùûüçñ';
  const b = 'aaaaaeeeeiiiiooooouuuucn';
  var s = t.toLowerCase().trim();
  for (var i = 0; i < a.length; i++) {
    s = s.replaceAll(a[i], b[i]);
  }
  return s;
}

String _prixTexte(int p) {
  final s = p.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '$b FCFA';
}

class _CantineSheetState extends State<CantineSheet> {
  bool _loading = true;
  String? _error;
  List<MenuPublie> _menus = [];
  CantineParametres _params = const CantineParametres();
  String _repas = 'dejeuner';
  final TextEditingController _rechCtrl = TextEditingController();

  // Panier : clé « repas|id du plat » → quantité
  final Map<String, int> _panier = {};
  bool _commandeEnCours = false;

  String _cle(CantinePlat p) => '${p.repas}|${p.id}';
  CantinePlat? _platDeCle(String cle) {
    for (final m in _menus) {
      for (final p in m.plats) {
        if (_cle(p) == cle) return p;
      }
    }
    return null;
  }

  int get _nbArticles => _panier.values.fold(0, (a, b) => a + b);
  int get _totalPanier {
    var t = 0;
    _panier.forEach((cle, q) => t += (_platDeCle(cle)?.prix ?? 0) * q);
    return t;
  }

  void _changerQuantite(CantinePlat p, int delta) {
    final k = _cle(p);
    final q = ((_panier[k] ?? 0) + delta).clamp(0, 10).toInt();
    setState(() { if (q == 0) { _panier.remove(k); } else { _panier[k] = q; } });
  }

  @override
  void initState() {
    super.initState();
    final h = DateTime.now().hour;
    _repas = h < 10 ? 'petit_dejeuner' : (h < 16 ? 'dejeuner' : 'diner');
    _charger();
  }

  @override
  void dispose() {
    _rechCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = null; });
    final r = await CantineService.aujourdhui();
    if (!mounted) return;
    if (r['success'] == true) {
      final menus = List<MenuPublie>.from(r['menus'] as List);
      setState(() {
        _menus = menus;
        _params = r['parametres'] as CantineParametres;
        _panier.removeWhere((cle, _) => !menus.any((m) => m.plats.any((p) => _cle(p) == cle)));
        // Si le repas du moment n'est pas publié, on ouvre le premier repas publié.
        if (!menus.any((m) => m.repas == _repas && m.plats.isNotEmpty) && menus.any((m) => m.plats.isNotEmpty)) {
          _repas = menus.firstWhere((m) => m.plats.isNotEmpty).repas;
        }
        _loading = false;
      });
    } else {
      setState(() { _error = r['error'] as String?; _loading = false; });
    }
  }

  bool _publie(String repas) => _menus.any((m) => m.repas == repas && m.plats.isNotEmpty);

  List<CantinePlat> get _plats {
    final q = _norm(_rechCtrl.text);
    final menu = _menus.where((m) => m.repas == _repas);
    if (menu.isEmpty) return [];
    return menu.first.plats.where((p) => q.isEmpty || _norm('${p.nom} ${p.description}').contains(q)).toList();
  }

  String _dateTexte(bool court) {
    final d = DateTime.now();
    final j = _jours[d.weekday - 1];
    return '${court ? j.substring(0, 3) + '.' : j} ${d.day} ${_mois[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        final compact = w < 600;
        return Column(children: [
          _barreHaute(w, compact),
          Expanded(
            child: Stack(children: [
              Positioned.fill(child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _etatErreur()
                    : RefreshIndicator(
                        onRefresh: _charger,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(compact ? 12 : 18, 4, compact ? 12 : 18, _panier.isEmpty ? 16 : 92),
                          children: [
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1200),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _banniere(compact),
                                  const SizedBox(height: 14),
                                  _reperes(compact, w),
                                  const SizedBox(height: 14),
                                  _grille(w - (compact ? 24 : 36)),
                                  const SizedBox(height: 14),
                                  _bonAppetit(),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      )),
              if (_panier.isNotEmpty) Positioned(left: compact ? 12 : 18, right: compact ? 12 : 18, bottom: 12, child: _barrePanier()),
            ]),
          ),
        ]);
        }),
      ),
    );
  }

  Widget _barrePanier() => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Material(
            color: _bleu,
            elevation: 8,
            shadowColor: const Color(0x661E40AF),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: _ouvrirPanier,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(children: [
                  Stack(clipBehavior: Clip.none, children: [
                    const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 26),
                    Positioned(
                      right: -8, top: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: const Color(0xFFFFC21A), borderRadius: BorderRadius.circular(10)),
                        child: Text('$_nbArticles', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: _bleuFonce)),
                      ),
                    ),
                  ]),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Mon panier', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text(_prixTexte(_totalPanier), style: const TextStyle(fontSize: 12.5, color: Colors.white70, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const Text('Voir le panier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
                ]),
              ),
            ),
          ),
        ),
      );

  // ── Panier → commande ───────────────────────────────────────────────────
  String _libelleRepas(String r) => _repasOptions.firstWhere((o) => o['val'] == r, orElse: () => {'label': r})['label'] as String;

  void _ouvrirPanier() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setF) {
        void modifier(CantinePlat p, int delta) {
          _changerQuantite(p, delta);
          setF(() {});
          if (_panier.isEmpty) Navigator.of(ctx).pop();
        }

        final parRepas = <String, List<CantinePlat>>{};
        _panier.forEach((cle, _) {
          final p = _platDeCle(cle);
          if (p != null) parRepas.putIfAbsent(p.repas, () => []).add(p);
        });

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85, maxWidth: 560),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.shopping_cart_rounded, color: _bleu),
              const SizedBox(width: 10),
              const Expanded(child: Text('Mon panier', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _bleuFonce))),
              TextButton(
                onPressed: () { setState(_panier.clear); Navigator.of(ctx).pop(); },
                child: const Text('Vider', style: TextStyle(color: Colors.redAccent)),
              ),
            ]),
            const SizedBox(height: 6),
            Flexible(
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final e in parRepas.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Text(_libelleRepas(e.key).toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Color(0xFF94A3B8))),
                    ),
                    for (final p in e.value)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.nom, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _bleuFonce)),
                              Text(_prixTexte(p.prix), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ]),
                          ),
                          IconButton(visualDensity: VisualDensity.compact, onPressed: () => modifier(p, -1), icon: Icon(_panier[_cle(p)] == 1 ? Icons.delete_outline_rounded : Icons.remove_circle_outline_rounded, color: _bleu)),
                          SizedBox(width: 22, child: Text('${_panier[_cle(p)] ?? 0}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
                          IconButton(visualDensity: VisualDensity.compact, onPressed: (_panier[_cle(p)] ?? 0) >= 10 ? null : () => modifier(p, 1), icon: const Icon(Icons.add_circle_outline_rounded, color: _bleu)),
                        ]),
                      ),
                  ],
                ]),
              ),
            ),
            const Divider(),
            Row(children: [
              const Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(_prixTexte(_totalPanier), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _bleu)),
            ]),
            const SizedBox(height: 6),
            const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Expanded(child: Text('Aucun paiement maintenant : vous réglez à la récupération de votre commande, sur présentation du ticket.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _commandeEnCours ? null : () async { await _passerCommande(ctx); setF(() {}); },
                icon: _commandeEnCours
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.receipt_long_rounded, size: 19),
                label: const Text('Passer la commande'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bleu, foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ]),
        );
      }),
    );
  }

  Future<void> _passerCommande(BuildContext feuille) async {
    final lignes = <Map<String, dynamic>>[];
    _panier.forEach((cle, q) {
      final p = _platDeCle(cle);
      if (p != null) lignes.add({'repas': p.repas, 'plat_id': p.id, 'nom': p.nom, 'quantite': q});
    });
    if (lignes.isEmpty) return;
    setState(() => _commandeEnCours = true);
    final r = await CantineService.passerCommande(lignes);
    if (!mounted) return;
    setState(() => _commandeEnCours = false);
    if (r['success'] == true) {
      setState(_panier.clear);
      if (feuille.mounted) Navigator.of(feuille).pop();
      _afficherTicket(r['commande'] as CantineCommande, nouvelle: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['error'] as String? ?? 'Erreur.'), backgroundColor: Colors.redAccent));
      if ('${r['error']}'.contains('menu')) _charger();
    }
  }

  // ── Ticket ──────────────────────────────────────────────────────────────
  void _afficherTicket(CantineCommande c, {bool nouvelle = false}) {
    Widget ligne(String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 92, child: Text(a, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)))),
            Expanded(child: Text(b.isEmpty ? '-' : b, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _bleuFonce))),
          ]),
        );

    final parRepas = <String, List<CommandeLigne>>{};
    for (final l in c.lignes) {
      parRepas.putIfAbsent(l.repas, () => []).add(l);
    }
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (nouvelle) ...[
                const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 44),
                const SizedBox(height: 6),
                const Text('Commande enregistrée !', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _bleuFonce)),
                const SizedBox(height: 12),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: _bleu, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  const Text('TICKET DE COMMANDE', style: TextStyle(fontSize: 11.5, letterSpacing: 1.2, color: Colors.white70, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(c.ticket, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                ]),
              ),
              const SizedBox(height: 14),
              ligne('Nom', c.nom),
              ligne('Prénom(s)', c.prenoms),
              ligne('Filière', [c.filiere, c.niveau].where((e) => e.isNotEmpty).join(' · ')),
              ligne('Date', c.dateFr),
              ligne('Heure', c.heure.replaceFirst(':', 'h')),
              const Divider(height: 22),
              for (final e in parRepas.entries) ...[
                Text(_libelleRepas(e.key).toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Color(0xFF94A3B8))),
                const SizedBox(height: 4),
                for (final l in e.value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Text('${l.quantite}× ', style: const TextStyle(fontWeight: FontWeight.w900, color: _bleu)),
                      Expanded(child: Text(l.nom, style: const TextStyle(fontSize: 13.5))),
                      Text(_prixTexte(l.prix * l.quantite), style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                    ]),
                  ),
                const SizedBox(height: 4),
              ],
              const Divider(height: 18),
              Row(children: [
                const Text('Montant total', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text(_prixTexte(c.total), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _bleu)),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(11)),
                child: const Text('À régler à la récupération. Présentez ce ticket au comptoir de la cantine.', style: TextStyle(fontSize: 12.5, color: Color(0xFF92400E), fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: _bleu, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Mes commandes ───────────────────────────────────────────────────────
  void _ouvrirMesCommandes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MesCommandesFeuille(
        onTicket: (c) => _afficherTicket(c),
        libelleRepas: _libelleRepas,
      ),
    );
  }

  Widget _etatErreur() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 32),
          const SizedBox(height: 12),
          Text(_error ?? 'Erreur', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _charger, child: const Text('Réessayer')),
        ]),
      );

  // ── Barre du haut ───────────────────────────────────────────────────────
  Widget _barreHaute(double w, bool compact) {
    // Le décor n'occupe que la place laissée libre à droite du titre (≈ 330 px).
    final largeurDecor = (w - 330).clamp(0.0, 560.0);
    final ouvert = _params.ouvertA(DateTime.now());
    final datePilule = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.calendar_month_rounded, size: 18, color: _bleu),
        const SizedBox(width: 8),
        Flexible(child: Text(_dateTexte(w < 400), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _bleuFonce))),
      ]),
    );
    final statut = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ouvert ? const Color(0xFFE7F8EC) : const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ouvert ? const Color(0xFF22C55E) : const Color(0xFFEF4444), width: 1.4),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 11, color: ouvert ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
        const SizedBox(width: 7),
        Text(ouvert ? 'Ouvert' : 'Fermé', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: ouvert ? const Color(0xFF15803D) : const Color(0xFFB91C1C))),
      ]),
    );
    final mesCommandes = Tooltip(
      message: 'Mes commandes',
      child: InkWell(
        onTap: _ouvrirMesCommandes,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: _bleuClair, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.receipt_long_rounded, color: _bleu),
        ),
      ),
    );
    final titre = Row(children: [
      InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: _bleuClair, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.arrow_back_rounded, color: _bleuFonce),
        ),
      ),
      const SizedBox(width: 12),
      Container(
        width: 46, height: 46,
        decoration: BoxDecoration(color: _bleu, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 25),
      ),
      const SizedBox(width: 10),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Cantine', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _bleuFonce)),
        Text('Menu de la cantine', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
      ]),
    ]);
    return Container(
      color: Colors.white,
      child: Stack(children: [
        if (!compact && largeurDecor > 200) Positioned(right: 0, top: 0, bottom: 0, width: largeurDecor, child: const CustomPaint(painter: _HautPainter())),
        Padding(
          padding: EdgeInsets.fromLTRB(compact ? 12 : 18, 12, compact ? 12 : 18, 12),
          child: compact
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [Expanded(child: titre), mesCommandes]),
                  const SizedBox(height: 10),
                  Row(children: [Expanded(child: datePilule), const SizedBox(width: 8), statut]),
                ])
              : Row(children: [titre, const Spacer(), datePilule, const SizedBox(width: 10), statut, const SizedBox(width: 10), mesCommandes]),
        ),
      ]),
    );
  }

  // ── Bannière « Menu du jour » ───────────────────────────────────────────
  Widget _banniere(bool compact) {
    final infos = Wrap(spacing: 18, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.room_service_rounded, size: 19, color: Color(0xFFFFC21A)),
        const SizedBox(width: 7),
        Text('Ouvert de ${CantineParametres.affiche(_params.ouverture)} à ${CantineParametres.affiche(_params.fermeture)}',
            style: TextStyle(fontSize: compact ? 11.5 : 13, fontWeight: FontWeight.w700, color: Colors.white)),
      ]),
      Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.place_rounded, size: 19, color: Colors.white),
        const SizedBox(width: 6),
        Flexible(child: Text(_params.lieu, style: TextStyle(fontSize: compact ? 11.5 : 13, fontWeight: FontWeight.w700, color: Colors.white))),
      ]),
    ]);
    return Container(
      height: compact ? 190 : 215,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(colors: [Color(0xFF0B2A8C), Color(0xFF1E4FD8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: LayoutBuilder(builder: (context, c) {
        return Stack(children: [
          Positioned(
            right: 0, top: 0, bottom: 0,
            width: c.maxWidth * (compact ? 0.38 : 0.58),
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => LinearGradient(colors: const [Colors.transparent, Colors.black], stops: [0.0, compact ? 0.6 : 0.45]).createShader(r),
              child: Image.asset('assets/images/cantine_etudiant.png', fit: BoxFit.cover, alignment: Alignment.centerRight, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 14 : 22),
            child: SizedBox(
              width: compact ? c.maxWidth * 0.64 : null,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: compact ? 44 : 76, height: compact ? 44 : 76,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                  child: Icon(Icons.restaurant_rounded, color: Colors.white, size: compact ? 23 : 40),
                ),
                SizedBox(width: compact ? 10 : 14),
                Flexible(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Menu du jour', style: TextStyle(fontSize: compact ? 20 : 34, fontWeight: FontWeight.w900, color: Colors.white, height: 1.05)),
                    const SizedBox(height: 4),
                    Text('Bien manger, bien étudier ! \u{1F60A}', style: TextStyle(fontSize: compact ? 11.5 : 17, color: Colors.white)),
                  ]),
                ),
              ]),
              SizedBox(height: compact ? 14 : 20),
              SizedBox(width: compact ? null : 560, child: infos),
            ]),
            ),
          ),
        ]);
      }),
    );
  }

  // ── Repas + recherche ───────────────────────────────────────────────────
  Widget _reperes(bool compact, double w) {
    final empile = compact || w < 980;
    Widget pilule(Map<String, Object> r) {
      final val = r['val'] as String;
      final actif = _repas == val;
      final publie = _publie(val);
      final bouton = InkWell(
          onTap: () => setState(() => _repas = val),
          borderRadius: BorderRadius.circular(26),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : (w < 980 ? 12 : 26), vertical: 12),
            decoration: BoxDecoration(
              color: actif ? _bleu : Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: actif ? _bleu : const Color(0xFFE2E8F0)),
              boxShadow: actif ? const [BoxShadow(color: Color(0x331E40AF), blurRadius: 10, offset: Offset(0, 4))] : null,
            ),
            child: Row(mainAxisSize: empile ? MainAxisSize.max : MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
              if (!compact) ...[Icon(r['icon'] as IconData, size: 21, color: actif ? Colors.white : _bleu), const SizedBox(width: 9)],
              Flexible(
                child: Text(r['label'] as String,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: compact ? 12.5 : 15, fontWeight: FontWeight.w800, color: actif ? Colors.white : (publie ? _bleuFonce : const Color(0xFF94A3B8)))),
              ),
            ]),
          ),
        );
      return empile ? Expanded(child: bouton) : bouton;
    }

    final recherche = TextField(
      controller: _rechCtrl,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Rechercher un plat...',
        prefixIcon: const Icon(Icons.search_rounded, color: _bleuFonce),
        suffixIcon: _rechCtrl.text.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => setState(() => _rechCtrl.clear())),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: const BorderSide(color: Color(0xFFDCE6F7))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: const BorderSide(color: Color(0xFFDCE6F7))),
      ),
    );
    final pilules = Row(mainAxisSize: empile ? MainAxisSize.max : MainAxisSize.min, children: [for (final r in _repasOptions) pilule(r)]);
    return empile
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [pilules, const SizedBox(height: 10), recherche])
        : Row(children: [pilules, const Spacer(), SizedBox(width: 320, child: recherche)]);
  }

  // ── Plats ───────────────────────────────────────────────────────────────
  Widget _grille(double largeurDispo) {
    final plats = _plats;
    if (plats.isEmpty) {
      final publie = _publie(_repas);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8ECF4))),
        child: Column(children: [
          const Icon(Icons.no_meals_rounded, size: 40, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 10),
          Text(publie ? 'Aucun plat ne correspond à votre recherche.' : "Le menu de ce repas n'est pas encore publié.",
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          if (!publie) const Padding(padding: EdgeInsets.only(top: 4), child: Text('Vous serez notifié dès sa publication.', style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)))),
        ]),
      );
    }
    final colonnes = largeurDispo >= 1000 ? 4 : (largeurDispo >= 700 ? 3 : (largeurDispo >= 460 ? 2 : 1));
    const ecart = 14.0;
    final largeur = (largeurDispo - ecart * (colonnes - 1)) / colonnes;
    return Wrap(spacing: ecart, runSpacing: ecart, children: [for (final p in plats) SizedBox(width: largeur, child: _cartePlat(p))]);
  }

  Widget _cartePlat(CantinePlat p) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF4)),
        boxShadow: const [BoxShadow(color: Color(0x141E293B), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(fit: StackFit.expand, children: [
              if (p.imageUrl != null)
                Image.network(p.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imageVide())
              else
                _imageVide(),
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.96), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF22C55E))),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.circle, size: 9, color: Color(0xFF16A34A)),
                    SizedBox(width: 5),
                    Text('Disponible', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                  ]),
                ),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
          child: Row(children: [
            const Icon(Icons.restaurant_rounded, size: 19, color: _bleu),
            const SizedBox(width: 7),
            Expanded(child: Text(p.nom, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _bleuFonce))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Text(p.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.3)),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(11)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.monetization_on_rounded, size: 20, color: Color(0xFFF59E0B)),
            const SizedBox(width: 7),
            Text(_prixTexte(p.prix), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: _bleuFonce)),
          ]),
        ),
        const SizedBox(height: 8),
        Builder(builder: (_) {
          final q = _panier[_cle(p)] ?? 0;
          if (q == 0) {
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _changerQuantite(p, 1),
                icon: const Icon(Icons.shopping_cart_rounded, size: 18),
                label: const Text('Ajouter au panier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bleu, foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
              ),
            );
          }
          return Container(
            decoration: BoxDecoration(color: _bleuClair, borderRadius: BorderRadius.circular(11), border: Border.all(color: _bleu, width: 1.4)),
            child: Row(children: [
              IconButton(onPressed: () => _changerQuantite(p, -1), icon: Icon(q == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded, color: _bleu)),
              Expanded(child: Text('$q dans le panier', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _bleuFonce))),
              IconButton(onPressed: q >= 10 ? null : () => _changerQuantite(p, 1), icon: const Icon(Icons.add_rounded, color: _bleu)),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _imageVide() => Container(
        color: const Color(0xFFFFF1D6),
        alignment: Alignment.center,
        child: const Icon(Icons.restaurant_rounded, size: 42, color: Color(0xFFF0B24A)),
      );

  Widget _bonAppetit() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: _bleuClair, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFC9DAFB))),
        child: const Row(children: [
          Icon(Icons.info_rounded, color: _bleu, size: 26),
          SizedBox(width: 12),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: 'Bon appétit ! ', style: TextStyle(fontWeight: FontWeight.w900, color: _bleuFonce)),
              TextSpan(text: 'Profitez de notre menu varié et équilibré pour rester en bonne santé.', style: TextStyle(color: Color(0xFF334155))),
            ]), style: TextStyle(fontSize: 13.5)),
          ),
          SizedBox(width: 10),
          Icon(Icons.favorite_border_rounded, color: _bleu, size: 26),
        ]),
      );
}

/// Décor bleu et jaune derrière la date et le badge « Ouvert » (barre du haut, grand écran).
class _HautPainter extends CustomPainter {
  const _HautPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Rond bleu clair translucide
    canvas.drawCircle(Offset(w * 0.18, h * 0.55), h * 0.70, Paint()..color = const Color(0xFFDCE8FF).withValues(alpha: 0.75));

    // Grand pan bleu foncé à droite
    final bleu = Path()
      ..moveTo(w * 0.34, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(w * 0.22, h)
      ..quadraticBezierTo(w * 0.24, h * 0.35, w * 0.34, 0)
      ..close();
    canvas.drawPath(
      bleu,
      Paint()..shader = const LinearGradient(colors: [Color(0xFF0B2A8C), Color(0xFF1E4FD8)], begin: Alignment.bottomLeft, end: Alignment.topRight).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Arc jaune le long du bord
    final jaune = Path()
      ..moveTo(w * 0.40, 0)
      ..quadraticBezierTo(w * 0.27, h * 0.38, w * 0.26, h)
      ..lineTo(w * 0.30, h)
      ..quadraticBezierTo(w * 0.31, h * 0.40, w * 0.46, 0)
      ..close();
    canvas.drawPath(jaune, Paint()..color = const Color(0xFFFFC21A));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Liste des commandes de l'étudiant (14 derniers jours) avec annulation tant qu'elles sont en cours.
class _MesCommandesFeuille extends StatefulWidget {
  final void Function(CantineCommande) onTicket;
  final String Function(String) libelleRepas;
  const _MesCommandesFeuille({required this.onTicket, required this.libelleRepas});
  @override
  State<_MesCommandesFeuille> createState() => _MesCommandesFeuilleState();
}

class _MesCommandesFeuilleState extends State<_MesCommandesFeuille> {
  bool _loading = true;
  String? _error;
  List<CantineCommande> _commandes = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = null; });
    final r = await CantineService.mesCommandes();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r['success'] == true) {
        _commandes = List<CantineCommande>.from(r['commandes'] as List);
      } else {
        _error = r['error'] as String?;
      }
    });
  }

  Future<void> _annuler(CantineCommande c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Annuler ${c.ticket} ?', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: const Text('Votre commande sera retirée de la liste de la cantine.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, elevation: 0), child: const Text('Annuler la commande')),
        ],
      ),
    );
    if (ok != true) return;
    final r = await CantineService.annulerCommande(c.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(r['success'] == true ? 'Commande ${c.ticket} annulée.' : (r['error'] as String? ?? 'Erreur.')),
      backgroundColor: r['success'] == true ? const Color(0xFF1E293B) : Colors.redAccent,
    ));
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85, maxWidth: 560),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: const BoxDecoration(color: Color(0xFFF4F7FF), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)))),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.receipt_long_rounded, color: _bleu),
          const SizedBox(width: 10),
          const Expanded(child: Text('Mes commandes', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _bleuFonce))),
          IconButton(onPressed: _charger, icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B))),
        ]),
        const SizedBox(height: 6),
        Flexible(
          child: _loading
              ? const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
              : _error != null
                  ? Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(_error!, style: const TextStyle(color: Color(0xFF64748B)))))
                  : _commandes.isEmpty
                      ? const Padding(padding: EdgeInsets.all(30), child: Center(child: Text("Vous n'avez pas encore passé de commande.", style: TextStyle(color: Color(0xFF94A3B8)))))
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _commandes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final c = _commandes[i];
                            final (couleur, fond, texte) = switch (c.statut) {
                              'traitee' => (const Color(0xFF15803D), const Color(0xFFDCFCE7), 'Récupérée'),
                              'annulee' => (const Color(0xFFB91C1C), const Color(0xFFFEE2E2), 'Annulée'),
                              _ => (const Color(0xFFB45309), const Color(0xFFFEF3C7), 'En cours'),
                            };
                            final resume = c.lignes.map((l) => '${l.quantite}× ${l.nom}').join(', ');
                            return InkWell(
                              onTap: () => widget.onTicket(c),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE8ECF4))),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: _bleu, borderRadius: BorderRadius.circular(9)),
                                      child: Text(c.ticket, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text('${c.dateFr} · ${c.heure.replaceFirst(':', 'h')}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(20)),
                                      child: Text(texte, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: couleur)),
                                    ),
                                  ]),
                                  const SizedBox(height: 8),
                                  Text(resume, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    Text(_prixTexte(c.total), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _bleu)),
                                    const Spacer(),
                                    if (c.statut == 'en_cours')
                                      TextButton(onPressed: () => _annuler(c), child: const Text('Annuler', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700))),
                                    const Text('Voir le ticket', style: TextStyle(fontSize: 12.5, color: _bleu, fontWeight: FontWeight.w800)),
                                    const Icon(Icons.chevron_right_rounded, color: _bleu, size: 20),
                                  ]),
                                ]),
                              ),
                            );
                          },
                        ),
        ),
      ]),
    );
  }
}
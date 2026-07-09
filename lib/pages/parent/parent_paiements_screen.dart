import 'package:flutter/material.dart';
import '../../theme/app_palette.dart';

// ════════════════════════════════════════════════════════════════════════════
// PAIEMENTS PARENT
// Payer la scolarité, l'abonnement à la cantine et le bus scolaire.
// ════════════════════════════════════════════════════════════════════════════
class ParentPaiementsScreen extends StatefulWidget {
  const ParentPaiementsScreen({super.key, required this.nomEnfant});

  final String nomEnfant;

  @override
  State<ParentPaiementsScreen> createState() => _ParentPaiementsScreenState();
}

class _ParentPaiementsScreenState extends State<ParentPaiementsScreen> {
  int _currentTab = 0;

  // ── Scolarité ─────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _fraisScolarite = [
    {'libelle': 'Frais d\'inscription', 'montant': 50000, 'statut': 'non_payé'},
    {'libelle': 'Mensualité Juillet', 'montant': 25000, 'statut': 'non_payé'},
  ];

  // ── Cantine ───────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _abonnementsCantine = [
    {
      'libelle': 'Abonnement cantine — Juillet',
      'detail': 'Déjeuner du lundi au vendredi',
      'montant': 15000,
      'statut': 'non_payé',
    },
  ];
  String _cantineActifJusquau = '30/06/2026';

  // ── Bus scolaire ──────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _abonnementsBus = [
    {
      'libelle': 'Abonnement bus — Juillet',
      'detail': 'Ligne 4 — Ouaga 2000 (aller-retour)',
      'montant': 10000,
      'statut': 'non_payé',
    },
  ];
  String _busActifJusquau = '30/06/2026';

  // ── Historique commun ─────────────────────────────────────────────────
  final List<Map<String, dynamic>> _historique = [
    {
      'libelle': 'Mensualité Juin',
      'categorie': 'Scolarité',
      'montant': 25000,
      'date': '10/06/2026',
      'ref': 'SH-982341',
    },
    {
      'libelle': 'Abonnement cantine — Juin',
      'categorie': 'Cantine',
      'montant': 15000,
      'date': '02/06/2026',
      'ref': 'SH-903417',
    },
    {
      'libelle': 'Abonnement bus — Juin',
      'categorie': 'Bus',
      'montant': 10000,
      'date': '02/06/2026',
      'ref': 'SH-903418',
    },
  ];

  // ══════════════════════════════════════════════════════════════════════
  // FLUX DE PAIEMENT ORANGE MONEY (recap → code SMS → succès)
  // ══════════════════════════════════════════════════════════════════════
  void _payer(Map<String, dynamic> f, String categorie) {
    final telCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final montantCtrl = TextEditingController(text: f['montant'].toString());
    bool loading = false;
    bool codeStep = false;
    bool success = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (success) ...[
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFF1DB954)),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 38),
                ),
                const SizedBox(height: 16),
                const Text('Paiement réussi !',
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D))),
                const SizedBox(height: 8),
                Text('${f['libelle']} payé avec succès pour ${widget.nomEnfant}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF64748B), height: 1.5)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.done_rounded),
                    label: const Text('Fermer'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF1DB954),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ] else if (codeStep) ...[
                const Text('Code SMS de confirmation',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                const Text('Entrez le code reçu par SMS.',
                    style:
                        TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: TextField(
                    controller: codeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8),
                    decoration: const InputDecoration(
                      hintText: '- - - - - -',
                      hintStyle:
                          TextStyle(color: Color(0xFF94A3B8), fontSize: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      setSt(() => loading = true);
                      await Future.delayed(const Duration(seconds: 2));
                      final amount =
                          int.tryParse(montantCtrl.text) ?? f['montant'];
                      final now = DateTime.now();
                      setState(() {
                        f['statut'] = 'payé';
                        _historique.insert(0, {
                          'libelle': f['libelle'],
                          'categorie': categorie,
                          'montant': amount,
                          'date': '${now.day}/${now.month}/${now.year}',
                          'ref':
                              'SH-${now.millisecondsSinceEpoch.toString().substring(7)}',
                        });
                        // Prolonger l'abonnement payé d'un mois
                        if (categorie == 'Cantine') {
                          _cantineActifJusquau = '31/07/2026';
                        } else if (categorie == 'Bus') {
                          _busActifJusquau = '31/07/2026';
                        }
                      });
                      setSt(() {
                        loading = false;
                        success = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0),
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Confirmer',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Column(
                    children: [
                      _recap('Motif', f['libelle']),
                      const SizedBox(height: 6),
                      _recap('Catégorie', categorie),
                      const SizedBox(height: 6),
                      _recap('Enfant', widget.nomEnfant),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Montant à payer (FCFA)',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A))),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: TextField(
                    controller: montantCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.blue),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.money_outlined,
                          color: Color(0xFF64748B), size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Numéro Orange Money',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A))),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: TextField(
                    controller: telCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                        fontSize: 15, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      hintText: '7X XX XX XX',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: Icon(Icons.phone_outlined,
                          color: Color(0xFF64748B), size: 20),
                      prefixText: '+226 ',
                      prefixStyle:
                          TextStyle(color: Color(0xFF64748B), fontSize: 15),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      setSt(() => loading = true);
                      await Future.delayed(const Duration(seconds: 1));
                      setSt(() {
                        loading = false;
                        codeStep = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0),
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Recevoir le code SMS',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _recap(String l, String v) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        Flexible(
          child: Text(v,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w500)),
        ),
      ]);

  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Paiements',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppPalette.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _tabButton(0, 'Scolarité', Icons.school_rounded),
                _tabButton(1, 'Cantine', Icons.restaurant_rounded),
                _tabButton(2, 'Bus', Icons.directions_bus_rounded),
                _tabButton(3, 'Historique', Icons.history_rounded),
              ],
            ),
          ),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _tabButton(int index, String label, IconData icon) {
    final bool isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18,
                  color:
                      isSelected ? AppPalette.blue : const Color(0xFF64748B)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? AppPalette.blue
                          : const Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case 0:
        return _buildListeFrais(
          _fraisScolarite,
          categorie: 'Scolarité',
          icon: Icons.receipt_long_outlined,
          messageVide: 'Scolarité entièrement réglée. 🎉',
        );
      case 1:
        return _buildAbonnement(
          _abonnementsCantine,
          categorie: 'Cantine',
          icon: Icons.restaurant_rounded,
          actifJusquau: _cantineActifJusquau,
          description:
              'L\'abonnement cantine donne accès au déjeuner du lundi au vendredi au restaurant du campus.',
        );
      case 2:
        return _buildAbonnement(
          _abonnementsBus,
          categorie: 'Bus',
          icon: Icons.directions_bus_rounded,
          actifJusquau: _busActifJusquau,
          description:
              'L\'abonnement bus couvre le transport aller-retour de votre enfant sur sa ligne scolaire.',
        );
      default:
        return _buildHistorique();
    }
  }

  // ── Liste de frais simples (scolarité) ──────────────────────────────────
  Widget _buildListeFrais(
    List<Map<String, dynamic>> frais, {
    required String categorie,
    required IconData icon,
    required String messageVide,
  }) {
    final aPayer = frais.where((f) => f['statut'] == 'non_payé').toList();
    if (aPayer.isEmpty) {
      return Center(
          child:
              Text(messageVide, style: const TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: aPayer.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) =>
          _carteFrais(aPayer[i], categorie: categorie, icon: icon),
    );
  }

  // ── Onglet abonnement (cantine / bus) ───────────────────────────────────
  Widget _buildAbonnement(
    List<Map<String, dynamic>> abonnements, {
    required String categorie,
    required IconData icon,
    required String actifJusquau,
    required String description,
  }) {
    final aPayer =
        abonnements.where((f) => f['statut'] == 'non_payé').toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        // Statut de l'abonnement en cours
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: const Color(0xFF15803D), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Abonnement $categorie actif',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D))),
                    const SizedBox(height: 2),
                    Text('Valable jusqu\'au $actifJusquau',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppPalette.lightBlue,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppPalette.blue.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppPalette.blue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(description,
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF334155),
                        height: 1.4)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (aPayer.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(
                child: Text('Aucun renouvellement en attente. 🎉',
                    style: TextStyle(color: Colors.grey))),
          )
        else
          for (final f in aPayer) ...[
            _carteFrais(f, categorie: categorie, icon: icon),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  // ── Carte d'un frais à payer ────────────────────────────────────────────
  Widget _carteFrais(Map<String, dynamic> f,
      {required String categorie, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12)),
                  child:
                      Icon(icon, color: const Color(0xFF64748B), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f['libelle'],
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text(
                        (f['detail'] as String?) ?? 'En attente de paiement',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Text('${f['montant']} FCFA',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _payer(f, categorie),
                icon: const Icon(Icons.payment_outlined, size: 18),
                label: const Text('Payer via Orange Money',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Historique ──────────────────────────────────────────────────────────
  Widget _buildHistorique() {
    if (_historique.isEmpty) {
      return const Center(
          child: Text('Aucun paiement enregistré.',
              style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _historique.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final h = _historique[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF86EFAC)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.check_circle_outline,
                    color: Color(0xFF15803D), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h['libelle'],
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('${h['categorie']} — payé le ${h['date']}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${h['montant']} FCFA',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D))),
                  Text(h['ref'],
                      style:
                          const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

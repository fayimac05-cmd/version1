import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class PaiementScolariteScreen extends StatefulWidget {
  const PaiementScolariteScreen({super.key});
  @override
  State<PaiementScolariteScreen> createState() =>
      _PaiementScolariteScreenState();
}

class _PaiementScolariteScreenState extends State<PaiementScolariteScreen> {
  final List<Map<String, dynamic>> frais = [
    {'libelle': 'Frais d\'inscription', 'montant': 50000, 'statut': 'non_payé'},
    {'libelle': 'Mensualité Février', 'montant': 25000, 'statut': 'non_payé'},
  ];

  final List<Map<String, dynamic>> historique = [
    {
      'libelle': 'Mensualité Janvier',
      'montant': 25000,
      'date': '12/01/2026',
      'ref': 'SH-982341',
      'mode': 'Orange Money'
    },
    {
      'libelle': 'Frais de Dossier',
      'montant': 10000,
      'date': '05/01/2026',
      'ref': 'SH-774102',
      'mode': 'Orange Money'
    },
  ];

  int _currentTab = 0; // 0 = Frais, 1 = Historique

  void _payer(Map<String, dynamic> f) {
    final telCtrl     = TextEditingController();
    final codeCtrl    = TextEditingController();
    final montantCtrl = TextEditingController(text: f['montant'].toString());
    bool loading      = false;
    bool codeStep     = false;
    bool success      = false;

    showDialog(context: context, builder: (_) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(mainAxisSize: MainAxisSize.min, children: [

          if (success) ...[
            Container(width: 68, height: 68,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF1DB954)),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 38)),
            const SizedBox(height: 16),
            const Text('Paiement réussi !', style: TextStyle(fontSize: 19,
                fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
            const SizedBox(height: 8),
            Text('Frais : ${f['libelle']} payés avec succès.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  // On crée une copie pour le reçu avec le montant réellement payé
                  final recuData = Map<String, dynamic>.from(f);
                  recuData['montant'] = int.tryParse(montantCtrl.text) ?? f['montant'];
                  _voirRecu(recuData);
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Télécharger le reçu'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF1DB954)),
                  foregroundColor: const Color(0xFF1DB954),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

          ] else if (codeStep) ...[
            const Text('Code SMS de confirmation', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 6),
            const Text('Entrez le code reçu par SMS.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0))),
              child: TextField(controller: codeCtrl,
                keyboardType: TextInputType.number, maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                    letterSpacing: 8),
                decoration: const InputDecoration(
                  hintText: '- - - - - -',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14), counterText: '',
                )),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  setSt(() => loading = true);
                  await Future.delayed(const Duration(seconds: 2));
                  final amount = int.tryParse(montantCtrl.text) ?? f['montant'];
                  setState(() {
                    f['statut'] = 'payé';
                    historique.insert(0, {
                      'libelle': f['libelle'],
                      'montant': amount,
                      'date': '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      'ref': 'SH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                      'mode': 'Orange Money'
                    });
                  });
                  setSt(() { loading = false; success = true; });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Confirmer', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),

          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(children: [
                _recap('Motif', f['libelle']),
              ]),
            ),
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft,
              child: Text('Montant à payer (FCFA)', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A)))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0))),
              child: TextField(controller: montantCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppPalette.blue),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.money_outlined, color: Color(0xFF64748B), size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                )),
            ),
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft,
              child: Text('Numéro Orange Money', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A)))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0))),
              child: TextField(controller: telCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                decoration: const InputDecoration(
                  hintText: '7X XX XX XX',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: Icon(Icons.phone_outlined,
                      color: Color(0xFF64748B), size: 20),
                  prefixText: '+226 ',
                  prefixStyle: TextStyle(color: Color(0xFF64748B), fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                )),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  setSt(() => loading = true);
                  await Future.delayed(const Duration(seconds: 1));
                  setSt(() { loading = false; codeStep = true; });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Recevoir le code SMS',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ]),
      ),
    ));
  }

  void _voirRecu(Map<String, dynamic> f) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('REÇU DE PAIEMENT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppPalette.blue)),
                      Text('ScolarHub — IST', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: AppPalette.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.school, color: AppPalette.blue),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _itemRecu('Référence', 'SH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'),
              _itemRecu('Date', '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
              _itemRecu('Étudiant', 'Ibrahim KONÉ'),
              _itemRecu('Filière', 'Informatique de Gestion'),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _itemRecu('Désignation', f['libelle']),
              _itemRecu('Mode de paiement', 'Orange Money'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL PAYÉ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${f['montant']} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppPalette.blue)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text('Ceci est un document officiel généré par ScolarHub.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Téléchargement du PDF en cours...'), backgroundColor: Colors.green),
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Enregistrer PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemRecu(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _recap(String l, String v, {bool gras = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        Text(v, style: TextStyle(fontSize: 13, color: const Color(0xFF0F172A),
            fontWeight: gras ? FontWeight.bold : FontWeight.w500)),
      ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Paiements Scolarité', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppPalette.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Sélecteur d'onglets personnalisé
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _tabButton(0, 'Frais à payer', Icons.pending_actions_rounded),
                _tabButton(1, 'Historique', Icons.history_rounded),
              ],
            ),
          ),
          
          Expanded(
            child: _currentTab == 0 ? _buildFraisList() : _buildHistoriqueList(),
          ),
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
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? AppPalette.blue : const Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? AppPalette.blue : const Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFraisList() {
    final aPayer = frais.where((f) => f['statut'] == 'non_payé').toList();
    if (aPayer.isEmpty) {
      return const Center(child: Text('Aucun frais en attente. 🎉', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: aPayer.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final f = aPayer[i];
        return _buildFraisCard(f);
      },
    );
  }

  Widget _buildHistoriqueList() {
    if (historique.isEmpty) {
      return const Center(child: Text('Aucun paiement enregistré.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: historique.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final h = historique[i];
        return _buildHistoryCard(h);
      },
    );
  }

  Widget _buildFraisCard(Map<String, dynamic> f) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
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
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF64748B), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f['libelle'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      const Text('En attente de paiement', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Text('${f['montant']} FCFA', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => _payer(f),
                icon: const Icon(Icons.payment_outlined, size: 18),
                label: const Text('Payer via Orange Money', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> h) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.check_circle_outline, color: Color(0xFF15803D), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h['libelle'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('Payé le ${h['date']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${h['montant']} FCFA', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                    Text(h['ref'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          InkWell(
            onTap: () => _voirRecu(h),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_rounded, size: 16, color: AppPalette.blue),
                  const SizedBox(width: 8),
                  Text('Revoir le reçu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppPalette.blue)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

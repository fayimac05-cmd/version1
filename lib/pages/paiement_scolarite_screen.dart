import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';

/// Paiement de la scolarité par mobile money (Orange Money, Wave, Moov, MTN).
/// Frais et historique viennent du backend ; reçu PDF généré localement.
class PaiementScolariteScreen extends StatefulWidget {
  const PaiementScolariteScreen({super.key});
  @override
  State<PaiementScolariteScreen> createState() =>
      _PaiementScolariteScreenState();
}

class _PaiementScolariteScreenState extends State<PaiementScolariteScreen> {
  int _currentTab = 0;
  bool _loading = false;
  bool _offline = false;
  String? _error;
  List<dynamic> _frais = [];
  List<dynamic> _historique = [];
  Map<String, dynamic>? _etudiant;

  final List<Map<String, dynamic>> _operateurs = const [
    {'value': 'orange_money', 'label': 'Orange Money', 'color': Color(0xFFFF6B00)},
    {'value': 'wave', 'label': 'Wave', 'color': Color(0xFF1DC9FF)},
    {'value': 'moov_money', 'label': 'Moov Money', 'color': Color(0xFF00A859)},
    {'value': 'mtn_momo', 'label': 'MTN MoMo', 'color': Color(0xFFFFCC00)},
  ];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ApiService.getMesPaiements();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _offline = result['offline'] == true;
      if (result['success'] == true) {
        _frais = (result['frais'] as List<dynamic>?) ?? [];
        _historique = (result['historique'] as List<dynamic>?) ?? [];
        _etudiant = result['etudiant'] as Map<String, dynamic>?;
      } else {
        _error = result['error'];
      }
    });
  }

  String _labelOperateur(String? value) {
    final op = _operateurs.where((o) => o['value'] == value);
    return op.isNotEmpty ? op.first['label'] as String : (value ?? '');
  }



  void _payer(Map<String, dynamic> f) {
    final telCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final montantCtrl =
        TextEditingController(text: '${num.tryParse('${f['montant']}')?.toInt() ?? f['montant']}');
    String operateur = 'orange_money';
    bool loading = false;
    bool codeStep = false;
    String? paiementId;
    String? erreur;
    Map<String, dynamic>? recu;

    showDialog(context: context, builder: (_) => StatefulBuilder(
      builder: (ctx, setSt) {
        final opColor = _operateurs
            .firstWhere((o) => o['value'] == operateur)['color'] as Color;

        Future<void> initier() async {
          final montant = num.tryParse(montantCtrl.text);
          if (montant == null || montant <= 0) {
            setSt(() => erreur = 'Montant invalide.');
            return;
          }
          if (telCtrl.text.trim().length < 8) {
            setSt(() => erreur = 'Numéro de téléphone invalide.');
            return;
          }
          setSt(() { loading = true; erreur = null; });
          final result = await ApiService.initierPaiement(
            fraisId: f['id'] as int,
            montant: montant,
            telephone: telCtrl.text.trim(),
            operateur: operateur,
          );
          setSt(() {
            loading = false;
            if (result['success'] == true) {
              paiementId = result['paiement_id'];
              codeStep = true;
            } else {
              erreur = result['error'];
            }
          });
        }

        Future<void> confirmer() async {
          if (codeCtrl.text.trim().length < 6) {
            setSt(() => erreur = 'Entrez le code à 6 chiffres reçu par SMS.');
            return;
          }
          setSt(() { loading = true; erreur = null; });
          final result =
              await ApiService.confirmerPaiement(paiementId!, codeCtrl.text.trim());
          setSt(() {
            loading = false;
            if (result['success'] == true) {
              recu = result['recu'] as Map<String, dynamic>?;
            } else {
              erreur = result['error'];
            }
          });
          if (result['success'] == true) _charger();
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              if (recu != null) ...[
                Container(width: 68, height: 68,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFF1DB954)),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 38)),
                const SizedBox(height: 16),
                const Text('Paiement réussi !', style: TextStyle(fontSize: 19,
                    fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                const SizedBox(height: 8),
                Text('Réf : ${recu!['reference'] ?? ''}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _telechargerRecu(recu!);
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('Télécharger le reçu PDF'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF1DB954)),
                      foregroundColor: const Color(0xFF1DB954),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

              ] else if (codeStep) ...[
                const Text('Code de confirmation', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                Text('Entrez le code envoyé par ${_labelOperateur(operateur)}.',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
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
                if (erreur != null) ...[
                  const SizedBox(height: 10),
                  Text(erreur!, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                ],
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: loading ? null : confirmer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: opColor,
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
                    _recap('Motif', '${f['libelle']}'),
                  ]),
                ),
                const SizedBox(height: 16),
                const Align(alignment: Alignment.centerLeft,
                  child: Text('Opérateur', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A)))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _operateurs.map((o) {
                    final actif = operateur == o['value'];
                    final color = o['color'] as Color;
                    return GestureDetector(
                      onTap: () => setSt(() => operateur = o['value'] as String),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: actif ? color : color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color, width: actif ? 0 : 1),
                        ),
                        child: Text(o['label'] as String,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                color: actif ? Colors.white : color)),
                      ),
                    );
                  }).toList(),
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
                Align(alignment: Alignment.centerLeft,
                  child: Text('Numéro ${_labelOperateur(operateur)}', style: const TextStyle(
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
                if (erreur != null) ...[
                  const SizedBox(height: 10),
                  Text(erreur!, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                ],
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: loading ? null : initier,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: opColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: loading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Recevoir le code',
                            style: TextStyle(fontSize: 15,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ]),
          ),
        );
      },
    ));
  }

  // ── Reçu PDF (généré localement, partage/impression via printing) ──
  Future<void> _telechargerRecu(Map<String, dynamic> recu) async {
    final doc = pw.Document();
    final dateStr = recu['date'] != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(
            DateTime.tryParse('${recu['date']}') ?? DateTime.now())
        : DateFormat('dd/MM/yyyy').format(DateTime.now());

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5,
      build: (ctx) => pw.Padding(
        padding: const pw.EdgeInsets.all(24),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('REÇU DE PAIEMENT',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF0A3D91))),
                  pw.Text('ScolarHub — IST',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                ]),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            _pdfLigne('Référence', '${recu['reference'] ?? ''}'),
            _pdfLigne('Transaction', '${recu['transaction_id'] ?? ''}'),
            _pdfLigne('Date', dateStr),
            _pdfLigne('Étudiant', '${recu['etudiant'] ?? ''}'),
            _pdfLigne('Matricule', '${recu['matricule'] ?? ''}'),
            _pdfLigne('Filière', '${recu['filiere'] ?? ''}'),
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            _pdfLigne('Désignation', '${recu['libelle'] ?? 'Frais de scolarité'}'),
            _pdfLigne('Mode de paiement', '${recu['mode'] ?? ''}'),
            pw.SizedBox(height: 14),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF1F5F9),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL PAYÉ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text('${recu['montant']} FCFA',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14,
                          color: PdfColor.fromInt(0xFF0A3D91))),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Center(
              child: pw.Text('Document officiel généré par ScolarHub.',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey,
                      fontStyle: pw.FontStyle.italic)),
            ),
          ],
        ),
      ),
    ));

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'recu_${recu['reference'] ?? 'paiement'}.pdf',
    );
  }

  pw.Widget _pdfLigne(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );

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
        actions: [
          IconButton(onPressed: _charger, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Column(
        children: [
          if (_offline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFEF3C7),
              child: const Text('Mode hors-ligne : dernières données connues.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF92400E))),
            ),
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red))))
                    : _currentTab == 0 ? _buildFraisList() : _buildHistoriqueList(),
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
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
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
    if (_frais.isEmpty) {
      return const Center(child: Text('Aucun frais en attente. 🎉', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _frais.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _buildFraisCard(_frais[i] as Map<String, dynamic>),
    );
  }

  Widget _buildHistoriqueList() {
    if (_historique.isEmpty) {
      return const Center(child: Text('Aucun paiement enregistré.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _historique.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _buildHistoryCard(_historique[i] as Map<String, dynamic>),
    );
  }

  Widget _buildFraisCard(Map<String, dynamic> f) {
    final montant = num.tryParse('${f['montant']}')?.toInt() ?? f['montant'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))],
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
                      Text('${f['libelle']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      const Text('En attente de paiement', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Text('$montant FCFA', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
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
                onPressed: _offline ? null : () => _payer(f),
                icon: const Icon(Icons.payment_outlined, size: 18),
                label: const Text('Payer par mobile money', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> h) {
    final montant = num.tryParse('${h['montant']}')?.toInt() ?? h['montant'];
    final date = h['confirmed_at'] ?? h['created_at'];
    final dateStr = date != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.tryParse('$date') ?? DateTime.now())
        : '';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))],
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
                      Text('${h['frais_libelle'] ?? 'Frais de scolarité'}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('Payé le $dateStr · ${_labelOperateur(h['operateur'])}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$montant FCFA', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                    Text('${h['reference'] ?? ''}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          InkWell(
            onTap: () => _telechargerRecu({
              'reference': h['reference'],
              'transaction_id': h['transaction_id'],
              'libelle': h['frais_libelle'],
              'montant': montant,
              'mode': _labelOperateur(h['operateur']),
              'etudiant': _etudiant != null
                  ? '${_etudiant!['prenoms'] ?? ''} ${_etudiant!['nom'] ?? ''}'
                  : '',
              'matricule': _etudiant?['matricule'],
              'filiere': _etudiant?['filiere_nom'],
              'date': date,
            }),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_rounded, size: 16, color: AppPalette.blue),
                  SizedBox(width: 8),
                  Text('Télécharger le reçu PDF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppPalette.blue)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

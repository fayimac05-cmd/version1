// lib/pages/finance_ui.dart
// Éléments visuels et utilitaires communs aux écrans Finances (admin, étudiant, parent).
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/finance_service.dart';

const Color finBleu = Color(0xFF0A4DA2);
const Color finJaune = Color(0xFFF8C400);
const Color finVert = Color(0xFF16A34A);
const Color finRouge = Color(0xFFDC2626);
const Color finOrange = Color(0xFFEA580C);
const Color finTexte = Color(0xFF0F172A);
const Color finGris = Color(0xFF64748B);
const Color finFond = Color(0xFFF1F5F9);

num finNum(dynamic v) => v is num ? v : (num.tryParse('${v ?? ''}') ?? 0);

/// 1250000 -> « 1 250 000 FCFA »
String fcfa(dynamic v, {bool unite = true}) {
  final n = finNum(v).round();
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '${n < 0 ? '-' : ''}$b${unite ? ' FCFA' : ''}';
}

String dateFr(dynamic iso) {
  if (iso == null) return '—';
  final d = DateTime.tryParse('$iso');
  if (d == null) return '$iso';
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
}

String dateIso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

const List<String> _moisCourts = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
String moisCourt(String yyyyMm) {
  final p = yyyyMm.split('-');
  if (p.length < 2) return yyyyMm;
  final m = int.tryParse(p[1]) ?? 1;
  return _moisCourts[(m - 1).clamp(0, 11)];
}

const Map<String, String> kModes = {
  'especes': 'Espèces',
  'orange_money': 'Orange Money',
  'moov_money': 'Moov Money',
  'wave': 'Wave',
  'virement': 'Virement',
  'cheque': 'Chèque',
};

Color couleurStatut(String s) {
  switch (s) {
    case 'a_jour':
    case 'payee':
      return finVert;
    case 'partiel':
    case 'partielle':
      return finOrange;
    case 'en_retard':
      return finRouge;
    default:
      return finGris;
  }
}

String libelleStatut(String s) {
  switch (s) {
    case 'a_jour':
      return 'À jour';
    case 'partiel':
      return 'Partiel';
    case 'non_paye':
      return 'Non payé';
    case 'en_retard':
      return 'En retard';
    case 'aucun_frais':
      return 'Aucun frais';
    case 'payee':
      return 'Payée';
    case 'partielle':
      return 'Partielle';
    case 'a_payer':
      return 'À payer';
    default:
      return s;
  }
}

class FinPastille extends StatelessWidget {
  final String statut;
  const FinPastille(this.statut, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = couleurStatut(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(libelleStatut(statut), style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}

class FinCarte extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? couleur;
  final VoidCallback? onTap;
  const FinCarte({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.couleur, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: couleur ?? Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class FinKpi extends StatelessWidget {
  final String titre;
  final String valeur;
  final IconData icone;
  final Color couleur;
  final String? sous;
  const FinKpi({super.key, required this.titre, required this.valeur, required this.icone, required this.couleur, this.sous});
  @override
  Widget build(BuildContext context) {
    return FinCarte(
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: couleur.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
          child: Icon(icone, color: couleur, size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titre, style: const TextStyle(fontSize: 12, color: finGris, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(valeur,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: finTexte)),
            if (sous != null) Text(sous!, style: const TextStyle(fontSize: 11, color: finGris)),
          ]),
        ),
      ]),
    );
  }
}

void finMessage(BuildContext context, String texte, {bool erreur = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(texte),
    behavior: SnackBarBehavior.floating,
    backgroundColor: erreur ? finRouge : finTexte,
  ));
}

/// Feuille modale qui remonte avec le clavier.
Future<T?> finFeuille<T>(BuildContext context, {required String titre, required Widget Function(BuildContext) contenu}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (c) => Padding(
      padding: EdgeInsets.fromLTRB(18, 14, 18, 16 + MediaQuery.of(c).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 14),
          Text(titre, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: finTexte)),
          const SizedBox(height: 14),
          contenu(c),
        ]),
      ),
    ),
  );
}

InputDecoration finChamp(String libelle, {String? aide, String? suffixe}) => InputDecoration(
      labelText: libelle,
      helperText: aide,
      suffixText: suffixe,
      isDense: true,
      filled: true,
      fillColor: finFond,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide.none),
    );

Future<bool> finConfirmer(BuildContext context, String titre, String texte, {String oui = 'Confirmer', bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(titre),
      content: Text(texte),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: danger ? finRouge : finBleu),
          onPressed: () => Navigator.pop(c, true),
          child: Text(oui),
        ),
      ],
    ),
  );
  return r == true;
}

// ── Reçu PDF ──────────────────────────────────────────────────
// Texte sans caractères hors Latin-1 (la police PDF par défaut ne les gère pas).
String _l1(String s) => s
    .replaceAll('’', "'")
    .replaceAll('–', '-')
    .replaceAll('—', '-')
    .replaceAll(' ', ' ')
    .replaceAll(' ', ' ');

/// Version publique du nettoyage de texte pour les PDF (police par défaut = Latin-1).
String finL1(String s) => _l1(s);

Future<void> ouvrirRecu(BuildContext context, dynamic versementId) async {
  final r = await FinanceService.recu(versementId);
  if (!context.mounted) return;
  if (r['success'] != true) {
    finMessage(context, '${r['message'] ?? 'Reçu indisponible.'}', erreur: true);
    return;
  }
  final recu = Map<String, dynamic>.from(r['recu'] as Map);
  final etab = Map<String, dynamic>.from((recu['etablissement'] ?? {}) as Map);
  final etu = Map<String, dynamic>.from((recu['etudiant'] ?? {}) as Map);
  final original = recu['original'] != false;
  final dup = finNum(recu['duplicata_numero']).round();
  final caissier = '${recu['caissier'] ?? ''}'.trim();
  final doc = pw.Document();

  pw.Widget ligne(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.SizedBox(width: 130, child: pw.Text(_l1(k), style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10.5))),
          pw.Expanded(child: pw.Text(_l1(v), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5))),
        ]),
      );

  pw.Widget cadreSignature(String titre) => pw.Expanded(
        child: pw.Container(
          height: 58,
          padding: const pw.EdgeInsets.all(5),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500, width: 0.7)),
          child: pw.Text(_l1(titre), style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
        ),
      );

  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a5,
    margin: const pw.EdgeInsets.all(26),
    build: (c) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(_l1('${etab['nom'] ?? 'Etablissement'}'), style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            if ('${etab['adresse'] ?? ''}${etab['ville'] ?? ''}${etab['telephone'] ?? ''}'.isNotEmpty)
              pw.Text(_l1('${etab['adresse'] ?? ''} ${etab['ville'] ?? ''}  ${etab['telephone'] ?? ''}'.trim()),
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
          ]),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: original ? PdfColors.green700 : PdfColors.orange800, width: 1.2),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(original ? 'ORIGINAL' : 'DUPLICATA N° $dup',
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: original ? PdfColors.green700 : PdfColors.orange800)),
        ),
      ]),
      pw.SizedBox(height: 10),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 7),
        decoration: const pw.BoxDecoration(color: PdfColors.blue800),
        child: pw.Center(
          child: pw.Text(_l1('RECU DE PAIEMENT  N° ${recu['numero']}'),
              style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12.5)),
        ),
      ),
      pw.SizedBox(height: 9),
      ligne('Date', dateFr(recu['date'])),
      ligne('Annee academique', '${recu['annee_academique'] ?? ''}'),
      ligne('Etudiant', '${etu['prenoms'] ?? ''} ${etu['nom'] ?? ''}'),
      ligne('Matricule', '${etu['matricule'] ?? ''}'),
      ligne('Filiere / niveau', '${etu['filiere'] ?? ''} ${etu['niveau'] ?? ''}'),
      ligne('Mode de paiement', '${recu['mode'] ?? ''}'),
      if ('${recu['reference'] ?? ''}'.isNotEmpty && recu['reference'] != null) ligne('Reference', '${recu['reference']}'),
      pw.SizedBox(height: 8),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blue800, width: 1.2)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('MONTANT RECU', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11.5)),
            pw.Text(_l1(fcfa(recu['montant'])), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 15, color: PdfColors.blue800)),
          ]),
          if ('${recu['montant_lettres'] ?? ''}'.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(_l1('Arrete le present recu a la somme de : ${recu['montant_lettres']}'),
                style: pw.TextStyle(fontSize: 9.5, fontStyle: pw.FontStyle.italic)),
          ],
        ]),
      ),
      pw.SizedBox(height: 8),
      ligne('Total a payer', fcfa(recu['net_a_payer'])),
      ligne('Total verse a ce jour', fcfa(recu['total_paye'])),
      ligne('Reste a payer', fcfa(recu['reste'])),
      if (caissier.isNotEmpty) ligne('Recu par (caisse)', caissier),
      pw.Spacer(),
      pw.Row(children: [
        cadreSignature('Le parent / l\'etudiant'),
        pw.SizedBox(width: 12),
        cadreSignature('Le caissier - Signature et cachet'),
      ]),
    ]),
  ));

  await Printing.layoutPdf(onLayout: (_) async => doc.save(), name: 'Recu_${recu['numero']}.pdf');
}

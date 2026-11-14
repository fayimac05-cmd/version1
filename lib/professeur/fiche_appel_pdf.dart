import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Fiche d'appel (liste de présence) en PDF : en-tête complet (filière,
/// niveau, cours, professeur, date, heure), totaux de présents / absents,
/// puis la liste avec « Présent » ou « Absent » devant chaque nom.
///
/// [lignes] : une entrée par étudiant, avec les clés prenoms, nom, matricule
/// et statut (present / absent / retard / justifie).
Future<Uint8List> construireFicheAppelPdf({
  required String filiere,
  required String niveau,
  required String cours,
  required String professeur,
  required DateTime dateHeure,
  required List<Map<String, dynamic>> lignes,
}) async {
  const bleu = PdfColor.fromInt(0xFF1E40AF);
  const vert = PdfColor.fromInt(0xFF047857);
  const vertFond = PdfColor.fromInt(0xFFD1FAE5);
  const rouge = PdfColor.fromInt(0xFFB91C1C);
  const rougeFond = PdfColor.fromInt(0xFFFEE2E2);
  const ambre = PdfColor.fromInt(0xFFB45309);
  const ambreFond = PdfColor.fromInt(0xFFFEF3C7);
  const violet = PdfColor.fromInt(0xFF6D28D9);
  const violetFond = PdfColor.fromInt(0xFFEDE9FE);

  String deux(int n) => n.toString().padLeft(2, '0');
  final dateTxt = '${deux(dateHeure.day)}/${deux(dateHeure.month)}/${dateHeure.year}';
  final heureTxt = '${deux(dateHeure.hour)}h${deux(dateHeure.minute)}';

  String statutDe(Map<String, dynamic> l) => (l['statut'] ?? 'present').toString().toLowerCase();
  int compte(String s) => lignes.where((l) => statutDe(l) == s).length;
  final presents = compte('present');
  final absents = compte('absent');
  final retards = compte('retard');
  final justifies = compte('justifie');

  final gras = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10);
  const normal = pw.TextStyle(fontSize: 10);

  pw.Widget info(String cle, String valeur) => pw.Expanded(
        child: pw.RichText(
          text: pw.TextSpan(children: [
            pw.TextSpan(text: '$cle : ', style: gras),
            pw.TextSpan(text: valeur.isEmpty ? '-' : valeur, style: normal),
          ]),
        ),
      );

  pw.Widget boite(String valeur, String libelle, PdfColor texte, PdfColor fond) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 8),
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: pw.BoxDecoration(color: fond, borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Column(children: [
            pw.Text(valeur, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: texte)),
            pw.Text(libelle, style: pw.TextStyle(fontSize: 9, color: texte)),
          ]),
        ),
      );

  pw.Widget cellule(String texte, {pw.TextStyle? style}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: pw.Text(texte, style: style ?? const pw.TextStyle(fontSize: 9.5)),
      );

  pw.Widget celluleStatut(String statut) {
    final PdfColor texte;
    final PdfColor fond;
    final String libelle;
    switch (statut) {
      case 'absent':
        texte = rouge; fond = rougeFond; libelle = 'Absent';
        break;
      case 'retard':
        texte = ambre; fond = ambreFond; libelle = 'Retard';
        break;
      case 'justifie':
        texte = violet; fond = violetFond; libelle = 'Justifié';
        break;
      default:
        texte = vert; fond = vertFond; libelle = 'Présent';
    }
    return pw.Container(
      color: fond,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(libelle, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: texte)),
    );
  }

  final entete = pw.TableRow(
    repeat: true,
    decoration: const pw.BoxDecoration(color: bleu),
    children: [
      for (final t in ['N°', 'Nom & Prénoms', 'Matricule', 'Statut'])
        cellule(t, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
    ],
  );

  final rangees = <pw.TableRow>[
    for (var i = 0; i < lignes.length; i++)
      pw.TableRow(children: [
        cellule('${i + 1}'),
        cellule('${lignes[i]['prenoms'] ?? ''} ${lignes[i]['nom'] ?? ''}'.trim()),
        cellule('${lignes[i]['matricule'] ?? ''}'),
        celluleStatut(statutDe(lignes[i])),
      ]),
  ];

  final pdf = pw.Document();
  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(36),
    footer: (ctx) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text('ScolarHub - fiche d\'appel du $dateTxt à $heureTxt',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
    ]),
    build: (ctx) => [
      pw.Text('ScolarHub', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: bleu)),
      pw.SizedBox(height: 2),
      pw.Text('FICHE D\'APPEL - LISTE DE PRÉSENCE',
          style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: bleu)),
      pw.SizedBox(height: 12),
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(children: [
          pw.Row(children: [info('Filière', filiere), info('Niveau', niveau)]),
          pw.SizedBox(height: 6),
          pw.Row(children: [info('Cours', cours), info('Professeur', professeur)]),
          pw.SizedBox(height: 6),
          pw.Row(children: [info('Date', dateTxt), info('Heure de l\'appel', heureTxt)]),
        ]),
      ),
      pw.SizedBox(height: 12),
      pw.Row(children: [
        boite('${lignes.length}', 'Effectif', bleu, PdfColors.blue50),
        boite('$presents', 'Présents', vert, vertFond),
        boite('$absents', 'Absents', rouge, rougeFond),
        if (retards > 0) boite('$retards', 'En retard', ambre, ambreFond),
        if (justifies > 0) boite('$justifies', 'Justifiés', violet, violetFond),
      ]),
      pw.SizedBox(height: 14),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        columnWidths: {
          0: pw.FixedColumnWidth(28),
          1: pw.FlexColumnWidth(3),
          2: pw.FlexColumnWidth(1.6),
          3: pw.FixedColumnWidth(70),
        },
        children: [entete, ...rangees],
      ),
      pw.SizedBox(height: 30),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('Signature du professeur : ____________________', style: normal),
        pw.Text('Visa de l\'administration : ____________________', style: normal),
      ]),
    ],
  ));
  return pdf.save();
}

/// Date et heure d'un appel enregistré (created_at, à défaut date_appel).
DateTime? dateHeureAppel(dynamic appel) {
  if (appel is! Map) return null;
  for (final cle in ['created_at', 'date_appel']) {
    final v = appel[cle]?.toString();
    if (v == null || v.isEmpty) continue;
    final d = DateTime.tryParse(v);
    if (d != null) return d.isUtc ? d.toLocal() : d;
  }
  return null;
}

/// Nom de fichier propre : Fiche_appel_<cours>_<AAAA-MM-JJ>.pdf
String nomFichierFicheAppel(String cours, DateTime date) {
  String deux(int n) => n.toString().padLeft(2, '0');
  final propre = cours.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  return 'Fiche_appel_${propre.isEmpty ? 'classe' : propre}_${date.year}-${deux(date.month)}-${deux(date.day)}.pdf';
}
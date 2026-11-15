import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../config/etablissement_config.dart';

/// PDF du bulletin et des notes de l'étudiant : en-tête encadré avec le nom
/// de l'établissement, puis étudiant, filière, niveau et année académique.

const _bleu = PdfColor.fromInt(0xFF1E40AF);
const _gris = PdfColor.fromInt(0xFF64748B);
const _fond = PdfColor.fromInt(0xFFF1F5F9);
const _vert = PdfColor.fromInt(0xFF047857);
const _vertFond = PdfColor.fromInt(0xFFD1FAE5);
const _rouge = PdfColor.fromInt(0xFFB91C1C);
const _rougeFond = PdfColor.fromInt(0xFFFEE2E2);

String _deux(int n) => n.toString().padLeft(2, '0');
String _aujourdhui() {
  final d = DateTime.now();
  return '${_deux(d.day)}/${_deux(d.month)}/${d.year}';
}

String _propre(String t) =>
    t.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');

/// Année académique déduite d'une date (septembre à août).
String _anneeDepuisDate(DateTime d) {
  final debut = d.month >= 9 ? d.year : d.year - 1;
  return '$debut-${debut + 1}';
}

pw.Widget _info(String cle, String valeur) => pw.Expanded(
      child: pw.RichText(
        text: pw.TextSpan(children: [
          pw.TextSpan(text: '$cle : ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.TextSpan(text: valeur.isEmpty ? '-' : valeur, style: const pw.TextStyle(fontSize: 10)),
        ]),
      ),
    );

pw.Widget _boite(String valeur, String libelle, PdfColor texte, PdfColor fond) => pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 8),
        padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        decoration: pw.BoxDecoration(color: fond, borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Column(children: [
          pw.Text(valeur, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: texte)),
          pw.Text(libelle, style: pw.TextStyle(fontSize: 9, color: texte)),
        ]),
      ),
    );

pw.Widget _cadreTitre(String etablissement, String titre) => pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _bleu, width: 1.2),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(children: [
        if (etablissement.isNotEmpty) ...[
          pw.Text(etablissement.toUpperCase(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _bleu)),
          pw.SizedBox(height: 6),
          pw.Container(height: 0.8, width: 120, color: _bleu),
          pw.SizedBox(height: 6),
        ],
        pw.Text(titre, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
      ]),
    );

pw.Widget _cadreInfos(List<List<List<String>>> lignes) => pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(children: [
        for (var k = 0; k < lignes.length; k++) ...[
          if (k > 0) pw.SizedBox(height: 6),
          pw.Row(children: [for (final c in lignes[k]) _info(c[0], c[1])]),
        ],
      ]),
    );

pw.Widget _cell(String t, {bool gras = false, PdfColor? couleur, pw.TextAlign align = pw.TextAlign.left}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(t,
          textAlign: align,
          style: pw.TextStyle(fontSize: 10, fontWeight: gras ? pw.FontWeight.bold : pw.FontWeight.normal, color: couleur)),
    );

pw.Widget _pied(pw.Context ctx, String texte) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text(texte, style: const pw.TextStyle(fontSize: 8, color: _gris)),
      pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: _gris)),
    ]);

pw.TableRow _enteteTable(List<String> titres, {Set<int> centres = const {}}) => pw.TableRow(
      decoration: const pw.BoxDecoration(color: _bleu),
      children: [
        for (var i = 0; i < titres.length; i++)
          _cell(titres[i], gras: true, couleur: PdfColors.white, align: centres.contains(i) ? pw.TextAlign.center : pw.TextAlign.left),
      ],
    );

// ════════════════════════════════════════════════════════════════════════
// BULLETIN D'UN SEMESTRE
// ════════════════════════════════════════════════════════════════════════

/// [matieres] : liste de {nom, coefficient, moyenne (double?)}.
Future<void> telechargerBulletinPdf({
  required String nom,
  required String prenoms,
  required String filiere,
  required String niveau,
  required String anneeAcademique,
  required String semestre,
  required double? moyenneGenerale,
  required String statutLabel,
  required bool valide,
  required String? datePublication,
  required List<Map<String, dynamic>> matieres,
  String dateNaissance = '',
  String lieuNaissance = '',
}) async {
  await EtablissementConfig.instance.charger();
  final etab = EtablissementConfig.instance.nom.trim();
  final dateTxt = _aujourdhui();

  final pdf = pw.Document(title: 'Bulletin');
  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    footer: (ctx) => _pied(ctx, 'ScolarHub - bulletin édité le $dateTxt'),
    build: (ctx) => [
      _cadreTitre(etab, 'RELEVÉ DE NOTES - ${semestre.toUpperCase()}'),
      pw.SizedBox(height: 10),
      _cadreInfos([
        [['Étudiant(e)', '$prenoms $nom'.trim()], ['Filière', filiere]],
        [['Né(e) le', dateNaissance], ['Lieu de naissance', lieuNaissance]],
        [['Niveau', niveau], ['Année académique', anneeAcademique]],
        [['Semestre', semestre], ['Publié le', datePublication ?? '-']],
      ]),
      pw.SizedBox(height: 10),
      pw.Row(children: [
        _boite(moyenneGenerale == null ? '-' : moyenneGenerale.toStringAsFixed(2), 'Moyenne générale /20', _bleu, PdfColors.blue50),
        _boite(statutLabel, 'Résultat', valide ? _vert : _rouge, valide ? _vertFond : _rougeFond),
      ]),
      pw.SizedBox(height: 12),
      if (matieres.isEmpty)
        pw.Text('Aucune note de module publiée pour ce semestre.', style: const pw.TextStyle(fontSize: 10, color: _gris))
      else
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: const {
            0: pw.FixedColumnWidth(26),
            1: pw.FlexColumnWidth(4),
            2: pw.FixedColumnWidth(48),
            3: pw.FixedColumnWidth(74),
          },
          children: [
            _enteteTable(['N°', 'Intitulé de la matière', 'Coef.', 'Moyenne /20'], centres: {2, 3}),
            for (var i = 0; i < matieres.length; i++)
              pw.TableRow(
                decoration: pw.BoxDecoration(color: i.isOdd ? _fond : PdfColors.white),
                children: [
                  _cell('${i + 1}'),
                  _cell('${matieres[i]['nom'] ?? ''}'),
                  _cell('${matieres[i]['coefficient'] ?? ''}', align: pw.TextAlign.center),
                  () {
                    final m = matieres[i]['moyenne'] as double?;
                    return _cell(m == null ? '-' : m.toStringAsFixed(2),
                        gras: true, align: pw.TextAlign.center, couleur: m == null ? null : (m >= 10 ? _vert : _rouge));
                  }(),
                ],
              ),
          ],
        ),
      pw.SizedBox(height: 30),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('Le Directeur Académique : ____________________', style: const pw.TextStyle(fontSize: 10)),
        pw.Text('Fait à Ouagadougou, le $dateTxt', style: const pw.TextStyle(fontSize: 10)),
      ]),
    ],
  ));
  final Uint8List bytes = await pdf.save();
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'Bulletin_${_propre(semestre)}_${_propre(anneeAcademique)}_${_propre(nom)}.pdf',
  );
}

// ════════════════════════════════════════════════════════════════════════
// MES NOTES (toutes les notes publiées)
// ════════════════════════════════════════════════════════════════════════

String _texteNote(Map<String, dynamic> n, List<String> cles) {
  for (final k in cles) {
    final v = n[k]?.toString().trim();
    if (v != null && v.isNotEmpty && v != 'null') return v;
  }
  return '';
}

DateTime? _dateNote(Map<String, dynamic> n) {
  for (final k in ['date_session', 'date_note', 'date_evaluation', 'created_at', 'date']) {
    final raw = n[k]?.toString();
    if (raw == null || raw.isEmpty) continue;
    final d = DateTime.tryParse(raw);
    if (d != null) return d.isUtc ? d.toLocal() : d;
  }
  return null;
}

String _valeurNote(Map<String, dynamic> n) {
  final v = n['valeur'] ?? n['note'] ?? n['score'];
  if (v == null) return '-';
  final d = double.tryParse(v.toString());
  if (d == null) return v.toString();
  return d.toStringAsFixed(d % 1 == 0 ? 0 : 2).replaceAll('.', ',');
}

/// Appréciation calculée à partir de la note /20 (même échelle que côté professeur).
String appreciationDepuisNote(double? note) {
  if (note == null) return '';
  if (note >= 17) return 'Très bien';
  if (note >= 15) return 'Bien';
  if (note >= 13) return 'Assez bien';
  if (note >= 12) return 'Passable';
  return 'Faible';
}

Future<void> telechargerNotesPdf({
  required String nom,
  required String prenoms,
  required String filiere,
  required String niveau,
  required List<Map<String, dynamic>> notes,
}) async {
  await EtablissementConfig.instance.charger();
  final etab = EtablissementConfig.instance.nom.trim();
  final dateTxt = _aujourdhui();

  // Année académique : champ du serveur si présent, sinon déduite de la date.
  String anneeDe(Map<String, dynamic> n) {
    final a = _texteNote(n, ['annee_academique', 'annee']);
    if (a.isNotEmpty) return a;
    final d = _dateNote(n);
    return d == null ? '' : _anneeDepuisDate(d);
  }

  final annees = <String>{for (final n in notes) if (anneeDe(n).isNotEmpty) anneeDe(n)}.toList()..sort();
  final anneeEntete = annees.isEmpty ? '' : annees.last;

  // Groupes par semestre (ordre alphabétique : S1, S2, ...).
  final groupes = <String, List<Map<String, dynamic>>>{};
  for (final n in notes) {
    final s = _texteNote(n, ['semestre']);
    groupes.putIfAbsent(s.isEmpty ? 'Autres notes' : s, () => []).add(n);
  }
  final cles = groupes.keys.toList()..sort();

  final pdf = pw.Document(title: 'Mes notes');
  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    footer: (ctx) => _pied(ctx, 'ScolarHub - notes éditées le $dateTxt'),
    build: (ctx) => [
      _cadreTitre(etab, 'RELEVÉ DE MES NOTES'),
      pw.SizedBox(height: 10),
      _cadreInfos([
        [['Étudiant(e)', '$prenoms $nom'.trim()], ['Filière', filiere]],
        [['Niveau', niveau], ['Année académique', anneeEntete]],
      ]),
      pw.SizedBox(height: 12),
      if (notes.isEmpty)
        pw.Text('Aucune note publiée pour le moment.', style: const pw.TextStyle(fontSize: 10, color: _gris)),
      for (final cle in cles) ...[
        pw.Text(cle, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _bleu)),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: const {
            0: pw.FixedColumnWidth(24),
            1: pw.FlexColumnWidth(3.2),
            2: pw.FixedColumnWidth(42),
            3: pw.FixedColumnWidth(54),
            4: pw.FlexColumnWidth(1.6),
            5: pw.FixedColumnWidth(74),
          },
          children: [
            _enteteTable(['N°', 'Matière', 'Coef.', 'Note /20', 'Appréciation', 'Date'], centres: {2, 3}),
            for (var i = 0; i < groupes[cle]!.length; i++)
              () {
                final n = groupes[cle]![i];
                final d = _dateNote(n);
                final v = double.tryParse('${n['valeur'] ?? n['note'] ?? n['score'] ?? ''}');
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: i.isOdd ? _fond : PdfColors.white),
                  children: [
                    _cell('${i + 1}'),
                    _cell(_texteNote(n, ['module_nom', 'matiere_nom', 'matiere', 'cours', 'module', 'ue', 'intitule']).ifEmpty('Note publiée')),
                    _cell(_texteNote(n, ['coefficient', 'coef']), align: pw.TextAlign.center),
                    _cell(_valeurNote(n), gras: true, align: pw.TextAlign.center, couleur: v == null ? null : (v >= 10 ? _vert : _rouge)),
                    _cell(_texteNote(n, ['mention']).ifEmpty(appreciationDepuisNote(v))),
                    _cell(d == null ? '' : '${_deux(d.day)}/${_deux(d.month)}/${d.year}'),
                  ],
                );
              }(),
          ],
        ),
        pw.SizedBox(height: 14),
      ],
    ],
  ));
  final Uint8List bytes = await pdf.save();
  await Printing.sharePdf(bytes: bytes, filename: 'Mes_notes_${_propre(nom)}_${_propre(prenoms)}.pdf');
}

extension _VideSinon on String {
  String ifEmpty(String autre) => isEmpty ? autre : this;
}

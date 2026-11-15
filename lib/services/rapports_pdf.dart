import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../config/etablissement_config.dart';

/// PDF administration : relevé d'une session de notes et résultats des
/// bulletins d'une classe. En-tête encadré (établissement, filière, niveau,
/// année académique), statistiques (notes faibles / fortes, moyenne, taux de
/// réussite), puis tableau Matricule - Nom - Prénom(s) - ...

const _bleu = PdfColor.fromInt(0xFF1E40AF);
const _gris = PdfColor.fromInt(0xFF64748B);
const _fond = PdfColor.fromInt(0xFFF1F5F9);
const _vert = PdfColor.fromInt(0xFF047857);
const _vertFond = PdfColor.fromInt(0xFFD1FAE5);
const _rouge = PdfColor.fromInt(0xFFB91C1C);
const _rougeFond = PdfColor.fromInt(0xFFFEE2E2);
const _ambre = PdfColor.fromInt(0xFFB45309);
const _ambreFond = PdfColor.fromInt(0xFFFEF3C7);

/// Seuils utilisés dans les statistiques.
const double seuilNoteFaible = 10; // strictement en dessous : note faible
const double seuilNoteForte = 15; // à partir de : note forte

String _deux(int n) => n.toString().padLeft(2, '0');
String _aujourdhui() {
  final d = DateTime.now();
  return '${_deux(d.day)}/${_deux(d.month)}/${d.year}';
}

String _propre(String t) =>
    t.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');

String _pct(int n, int total) => total == 0 ? '0 %' : '${(n * 100 / total).toStringAsFixed(n * 100 % total == 0 ? 0 : 1)} %';

/// Appréciation calculée à partir de la note /20 (même échelle que côté professeur).
String appreciationNote(double? note) {
  if (note == null) return '-';
  if (note >= 17) return 'Très bien';
  if (note >= 15) return 'Bien';
  if (note >= 13) return 'Assez bien';
  if (note >= 12) return 'Passable';
  return 'Faible';
}

/// "2001-05-14T00:00:00.000Z" -> "14/05/2001" ; texte non reconnu renvoyé tel quel.
String formaterDateNaissance(dynamic brut) {
  final t = '${brut ?? ''}'.trim();
  if (t.isEmpty || t == 'null') return '';
  final d = DateTime.tryParse(t);
  if (d == null) return t;
  return '${_deux(d.day)}/${_deux(d.month)}/${d.year}';
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
          pw.Text(valeur, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: texte)),
          pw.Text(libelle, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8.5, color: texte)),
        ]),
      ),
    );

pw.Widget _cadreTitre(String etablissement, String titre, String sousTitre, pw.ImageProvider? logo) => pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _bleu, width: 1.2),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(children: [
        if (logo != null) ...[pw.Image(logo, height: 38, fit: pw.BoxFit.contain), pw.SizedBox(height: 6)],
        if (etablissement.isNotEmpty) ...[
          pw.Text(etablissement.toUpperCase(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _bleu)),
          pw.SizedBox(height: 6),
          pw.Container(height: 0.8, width: 120, color: _bleu),
          pw.SizedBox(height: 6),
        ],
        pw.Text(titre, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        if (sousTitre.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Text(sousTitre, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _gris)),
        ],
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

pw.Widget _cell(String t,
        {bool gras = false, PdfColor? couleur, pw.TextAlign align = pw.TextAlign.left, double taille = 9.5}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(t,
          textAlign: align,
          style: pw.TextStyle(fontSize: taille, fontWeight: gras ? pw.FontWeight.bold : pw.FontWeight.normal, color: couleur)),
    );

pw.TableRow _enteteTable(List<String> titres, {Set<int> centres = const {}, double taille = 9.5}) => pw.TableRow(
      repeat: true,
      decoration: const pw.BoxDecoration(color: _bleu),
      children: [
        for (var i = 0; i < titres.length; i++)
          _cell(titres[i],
              gras: true, couleur: PdfColors.white, taille: taille, align: centres.contains(i) ? pw.TextAlign.center : pw.TextAlign.left),
      ],
    );

pw.Widget _pied(pw.Context ctx, String texte) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text(texte, style: const pw.TextStyle(fontSize: 8, color: _gris)),
      pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: _gris)),
    ]);

Future<pw.ImageProvider?> _logo() async {
  final url = EtablissementConfig.instance.logoUrl;
  if (!url.startsWith('http')) return null;
  try {
    return await networkImage(url);
  } catch (_) {
    return null;
  }
}

Future<void> _sortie(pw.Document doc, String nom, bool imprimer) async {
  final bytes = await doc.save();
  if (imprimer) {
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: nom);
  } else {
    await Printing.sharePdf(bytes: bytes, filename: nom);
  }
}

// ════════════════════════════════════════════════════════════════════════
// SESSION DE NOTES (vue administration)
// ════════════════════════════════════════════════════════════════════════

/// [notes] : liste de {matricule, nom, prenoms, valeur (double)}.
Future<void> exporterSessionNotes({
  required String module,
  required String filiere,
  required String niveau,
  required String semestre,
  required String anneeAcademique,
  required String professeur,
  required String dateSession,
  required String statut,
  required List<Map<String, dynamic>> notes,
  bool imprimer = false,
}) async {
  await EtablissementConfig.instance.charger();
  final etab = EtablissementConfig.instance.nom.trim();
  final logo = await _logo();
  final dateTxt = _aujourdhui();

  final valeurs = [for (final n in notes) (n['valeur'] as num).toDouble()];
  final eff = valeurs.length;
  final moyenne = eff == 0 ? null : valeurs.reduce((a, b) => a + b) / eff;
  final reussite = valeurs.where((v) => v >= 10).length;
  final faibles = valeurs.where((v) => v < seuilNoteFaible).length;
  final fortes = valeurs.where((v) => v >= seuilNoteForte).length;
  final maxi = eff == 0 ? null : valeurs.reduce((a, b) => a > b ? a : b);
  final mini = eff == 0 ? null : valeurs.reduce((a, b) => a < b ? a : b);

  final doc = pw.Document(title: 'Notes $module');
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(30),
    footer: (ctx) => _pied(ctx, 'ScolarHub - relevé de notes édité le $dateTxt'),
    build: (ctx) => [
      _cadreTitre(etab, 'RELEVÉ DE NOTES', module, logo),
      pw.SizedBox(height: 10),
      _cadreInfos([
        [['Filière', filiere], ['Niveau', niveau]],
        [['Semestre', semestre], ['Année académique', anneeAcademique]],
        [['Professeur', professeur], ['Date de la session', dateSession]],
        [['Statut', statut], ['Édité le', dateTxt]],
      ]),
      pw.SizedBox(height: 10),
      pw.Row(children: [
        _boite('$eff', 'Effectif', _bleu, PdfColors.blue50),
        _boite(moyenne == null ? '-' : moyenne.toStringAsFixed(2), 'Moyenne de la classe /20', _bleu, PdfColors.blue50),
        _boite(_pct(reussite, eff), 'Taux de réussite (>= 10)', _vert, _vertFond),
      ]),
      pw.SizedBox(height: 6),
      pw.Row(children: [
        _boite('$faibles  (${_pct(faibles, eff)})', 'Notes faibles (< ${seuilNoteFaible.toStringAsFixed(0)})', _rouge, _rougeFond),
        _boite('$fortes  (${_pct(fortes, eff)})', 'Notes fortes (>= ${seuilNoteForte.toStringAsFixed(0)})', _vert, _vertFond),
        _boite(maxi == null ? '-' : '${maxi.toStringAsFixed(2)}  /  ${mini!.toStringAsFixed(2)}', 'Plus forte / plus faible note', _ambre, _ambreFond),
      ]),
      pw.SizedBox(height: 12),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(2.2),
          1: pw.FlexColumnWidth(2),
          2: pw.FlexColumnWidth(2.4),
          3: pw.FixedColumnWidth(52),
          4: pw.FlexColumnWidth(1.6),
        },
        children: [
          _enteteTable(['Matricule', 'Nom', 'Prénom(s)', 'Note /20', 'Appréciation'], centres: {3}),
          for (var i = 0; i < notes.length; i++)
            () {
              final v = (notes[i]['valeur'] as num).toDouble();
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: i.isOdd ? _fond : PdfColors.white),
                children: [
                  _cell('${notes[i]['matricule'] ?? ''}'),
                  _cell('${notes[i]['nom'] ?? ''}'.trim()),
                  _cell('${notes[i]['prenoms'] ?? ''}'.trim()),
                  _cell(v.toStringAsFixed(2),
                      gras: true, align: pw.TextAlign.center, couleur: v < seuilNoteFaible ? _rouge : (v >= seuilNoteForte ? _vert : null)),
                  _cell(appreciationNote(v)),
                ],
              );
            }(),
        ],
      ),
    ],
  ));
  await _sortie(doc, 'Notes_${_propre(module)}_${_propre(niveau)}_${_propre(semestre)}.pdf', imprimer);
}

// ════════════════════════════════════════════════════════════════════════
// RÉSULTATS DES BULLETINS D'UNE CLASSE (vue administration)
// ════════════════════════════════════════════════════════════════════════

/// [etudiants] : liste de {matricule, nom, prenoms, dateNaissance, lieuNaissance,
/// valeursModules (List<String>), moyenne (double?), appreciation, valide (bool)}.
Future<void> exporterBulletinsClasse({
  required String filiere,
  required String niveau,
  required String semestre,
  required String anneeAcademique,
  required bool apresRattrapage,
  required List<String> titresModules,
  required List<Map<String, dynamic>> etudiants,
  bool imprimer = false,
}) async {
  await EtablissementConfig.instance.charger();
  final etab = EtablissementConfig.instance.nom.trim();
  final logo = await _logo();
  final dateTxt = _aujourdhui();

  final moys = [for (final e in etudiants) if (e['moyenne'] != null) (e['moyenne'] as num).toDouble()];
  final eff = etudiants.length;
  final moyenneClasse = moys.isEmpty ? null : moys.reduce((a, b) => a + b) / moys.length;
  final valides = etudiants.where((e) => e['valide'] == true).length;
  final faibles = moys.where((v) => v < seuilNoteFaible).length;
  final fortes = moys.where((v) => v >= seuilNoteForte).length;

  final nbMod = titresModules.length;
  final colonnes = <int, pw.TableColumnWidth>{
    0: const pw.FlexColumnWidth(2.2),
    1: const pw.FlexColumnWidth(1.8),
    2: const pw.FlexColumnWidth(2.2),
    3: const pw.FixedColumnWidth(58),
    4: const pw.FlexColumnWidth(1.6),
    for (var i = 0; i < nbMod; i++) 5 + i: const pw.FixedColumnWidth(48),
    5 + nbMod: const pw.FixedColumnWidth(48),
    6 + nbMod: const pw.FlexColumnWidth(1.4),
    7 + nbMod: const pw.FixedColumnWidth(52),
  };

  final doc = pw.Document(title: 'Bulletins $semestre');
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4.landscape,
    margin: const pw.EdgeInsets.all(24),
    footer: (ctx) => _pied(ctx, 'ScolarHub - résultats édités le $dateTxt'),
    build: (ctx) => [
      _cadreTitre(etab, 'RÉSULTATS DU ${semestre.toUpperCase()}${apresRattrapage ? ' (APRÈS RATTRAPAGE)' : ''}', '', logo),
      pw.SizedBox(height: 10),
      _cadreInfos([
        [['Filière', filiere], ['Niveau', niveau]],
        [['Semestre', semestre], ['Année académique', anneeAcademique]],
      ]),
      pw.SizedBox(height: 10),
      pw.Row(children: [
        _boite('$eff', 'Effectif', _bleu, PdfColors.blue50),
        _boite(moyenneClasse == null ? '-' : moyenneClasse.toStringAsFixed(2), 'Moyenne de la classe /20', _bleu, PdfColors.blue50),
        _boite('$valides / $eff  (${_pct(valides, eff)})', 'Validés (taux de réussite)', _vert, _vertFond),
        _boite('$faibles  (${_pct(faibles, moys.length)})', 'Moyennes faibles (< ${seuilNoteFaible.toStringAsFixed(0)})', _rouge, _rougeFond),
        _boite('$fortes  (${_pct(fortes, moys.length)})', 'Moyennes fortes (>= ${seuilNoteForte.toStringAsFixed(0)})', _vert, _vertFond),
      ]),
      pw.SizedBox(height: 12),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        columnWidths: colonnes,
        children: [
          _enteteTable([
            'Matricule', 'Nom', 'Prénom(s)', 'Né(e) le', 'Lieu de naissance',
            ...titresModules,
            'Moyenne', 'Appréciation', 'Résultat',
          ], taille: 7.5, centres: {for (var i = 0; i < nbMod + 1; i++) 5 + i}),
          for (var i = 0; i < etudiants.length; i++)
            () {
              final e = etudiants[i];
              final m = (e['moyenne'] as num?)?.toDouble();
              final ok = e['valide'] == true;
              final vals = (e['valeursModules'] as List<dynamic>).map((x) => '$x').toList();
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: i.isOdd ? _fond : PdfColors.white),
                children: [
                  _cell('${e['matricule'] ?? ''}', taille: 8),
                  _cell('${e['nom'] ?? ''}'.trim(), taille: 8),
                  _cell('${e['prenoms'] ?? ''}'.trim(), taille: 8),
                  _cell('${e['dateNaissance'] ?? ''}', taille: 8),
                  _cell('${e['lieuNaissance'] ?? ''}', taille: 8),
                  for (var k = 0; k < nbMod; k++) _cell(k < vals.length ? vals[k] : '-', taille: 8, align: pw.TextAlign.center),
                  _cell(m == null ? '-' : m.toStringAsFixed(2),
                      taille: 8, gras: true, align: pw.TextAlign.center, couleur: m == null ? null : (m >= 10 ? _vert : _rouge)),
                  _cell('${e['appreciation'] ?? '-'}', taille: 8),
                  _cell(ok ? 'Validé' : 'Non validé', taille: 8, gras: true, couleur: ok ? _vert : _rouge),
                ],
              );
            }(),
        ],
      ),
    ],
  ));
  await _sortie(doc, 'Bulletins_${_propre(filiere)}_${_propre(niveau)}_${_propre(semestre)}_${_propre(anneeAcademique)}.pdf', imprimer);
}

// ════════════════════════════════════════════════════════════════════════
// LISTE DES ÉTUDIANTS (vue administration) : établissement entier ou une filière
// ════════════════════════════════════════════════════════════════════════

/// [etudiants] : liste de {matricule, nom, prenoms, filiere, niveau, domaine}.
/// [filiere] null = liste générale de l'établissement ; sinon une seule filière.
/// Les étudiants sont regroupés par filière puis par niveau, un tableau par groupe.
Future<void> exporterListeEtudiants({
  String? filiere,
  String? niveauChoisi,
  required String anneeAcademique,
  required List<Map<String, String>> etudiants,
  String filtres = '',
  bool imprimer = false,
}) async {
  await EtablissementConfig.instance.charger();
  final etab = EtablissementConfig.instance.nom.trim();
  final logo = await _logo();
  final dateTxt = _aujourdhui();

  String cle(Map<String, String> e, String k) => (e[k] ?? '').trim();
  int cmp(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

  final groupes = <String, List<Map<String, String>>>{};
  for (final e in etudiants) {
    final k = '${cle(e, 'filiere')}\u0001${cle(e, 'niveau')}';
    groupes.putIfAbsent(k, () => []).add(e);
  }
  final cles = groupes.keys.toList()..sort(cmp);
  for (final l in groupes.values) {
    l.sort((a, b) {
      final c = cmp(cle(a, 'nom'), cle(b, 'nom'));
      return c != 0 ? c : cmp(cle(a, 'prenoms'), cle(b, 'prenoms'));
    });
  }

  final domaines = (etudiants.map((e) => cle(e, 'domaine')).where((d) => d.isNotEmpty).toSet().toList()..sort(cmp)).join(', ');
  final niveaux = (etudiants.map((e) => cle(e, 'niveau')).where((d) => d.isNotEmpty).toSet().toList()..sort(cmp)).join(', ');
  final nbFilieres = etudiants.map((e) => cle(e, 'filiere')).where((d) => d.isNotEmpty).toSet().length;
  final eff = etudiants.length;

  final doc = pw.Document(title: filiere == null ? 'Liste des étudiants' : 'Liste des étudiants - $filiere');
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(30),
    footer: (ctx) => _pied(ctx, 'ScolarHub - liste des étudiants éditée le $dateTxt'),
    build: (ctx) => [
      _cadreTitre(etab, 'LISTE DES ÉTUDIANTS', [filiere ?? 'Ensemble de l\'établissement', if (niveauChoisi != null) niveauChoisi].join('  -  '), logo),
      pw.SizedBox(height: 10),
      _cadreInfos(filiere != null
          ? [
              [['Filière', filiere], ['Domaine', domaines]],
              [['Niveau', niveaux], ['Année académique', anneeAcademique]],
              [['Effectif', '$eff étudiant(s)'], ['Édité le', dateTxt]],
            ]
          : [
              [['Domaine', domaines], ['Filières', '$nbFilieres']],
              [['Niveaux', niveaux], ['Année académique', anneeAcademique]],
              [['Effectif', '$eff étudiant(s)'], ['Édité le', dateTxt]],
              if (filtres.isNotEmpty) [['Filtres appliqués', filtres]],
            ]),
      pw.SizedBox(height: 12),
      for (final k in cles) ...(() {
          final lst = groupes[k]!;
          final parts = k.split('\u0001');
          final titreGroupe = [
            if (filiere == null && parts[0].isNotEmpty) parts[0],
            if (parts[1].isNotEmpty) parts[1],
          ].join('  -  ');
          return <pw.Widget>[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              margin: const pw.EdgeInsets.only(bottom: 4),
              decoration: pw.BoxDecoration(color: PdfColors.blue50, borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text(titreGroupe.isEmpty ? 'Étudiants' : titreGroupe,
                    style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _bleu)),
                pw.Text('${lst.length} étudiant(s)', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _gris)),
              ]),
            ),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.4),
                1: pw.FlexColumnWidth(2.4),
                2: pw.FlexColumnWidth(3.2),
              },
              children: [
                _enteteTable(['Matricule', 'Nom', 'Prénom(s)']),
                for (var i = 0; i < lst.length; i++)
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: i.isOdd ? _fond : PdfColors.white),
                    children: [
                      _cell(cle(lst[i], 'matricule')),
                      _cell(cle(lst[i], 'nom'), gras: true),
                      _cell(cle(lst[i], 'prenoms')),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 14),
          ];
        }()),
    ],
  ));
  await _sortie(doc, 'Liste_Etudiants_${_propre(filiere ?? 'Etablissement')}${niveauChoisi == null ? '' : '_${_propre(niveauChoisi)}'}.pdf', imprimer);
}
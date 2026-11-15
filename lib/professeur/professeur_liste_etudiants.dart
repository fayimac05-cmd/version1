import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../config/etablissement_config.dart';
import '../services/api_service.dart';
import '../services/professor_service.dart';
import '../theme/app_palette.dart';

/// Liste des étudiants d'une classe (filière+niveau). S'affiche
/// immédiatement (nom, prénoms) — le choix module/semestre/année
/// est optionnel et ne sert qu'à enrichir avec les notes des sessions
/// validées, le coefficient du module et les heures d'absence.
class ProfesseurListeEtudiantsScreen extends StatefulWidget {
  const ProfesseurListeEtudiantsScreen({super.key, required this.classe, this.professeurNom = ''});
  final Map<String, dynamic> classe; // {id, nom, niveau}

  /// Nom du professeur, imprimé sur le PDF.
  final String professeurNom;

  @override
  State<ProfesseurListeEtudiantsScreen> createState() => _ProfesseurListeEtudiantsScreenState();
}

class _ProfesseurListeEtudiantsScreenState extends State<ProfesseurListeEtudiantsScreen> {
  // ── Liste de base (toujours affichée) ────────────────────────────────────
  bool _loadingEtudiants = true;
  String? _erreurEtudiants;
  List<dynamic> _etudiants = [];

  // ── Enrichissement optionnel (notes + absences) ──────────────────────────
  bool _enrichissementOuvert = false;
  List<dynamic> _modules = [];
  bool _loadingModules = true;
  String? _moduleId;
  final _anneeCtrl = TextEditingController(text: DateTime.now().year.toString());
  final _dureeSeanceCtrl = TextEditingController(text: '2');
  bool _loadingNotes = false;
  String? _erreurNotes;
  Map<String, dynamic>? _notesData; // {module_nom, coefficient, nb_sessions, etudiants}

  String? get _niveau => widget.classe['niveau']?.toString();

  @override
  void initState() {
    super.initState();
    _chargerEtudiants();
    _chargerModules();
  }

  @override
  void dispose() {
    _anneeCtrl.dispose();
    _dureeSeanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerEtudiants() async {
    setState(() { _loadingEtudiants = true; _erreurEtudiants = null; });
    final result = await ProfessorService.getStudentsByFiliere(
      int.parse(widget.classe['id'].toString()),
      niveau: _niveau,
    );
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        _etudiants = result['data'] as List<dynamic>;
      } else {
        _erreurEtudiants = result['error']?.toString() ?? 'Erreur lors du chargement.';
      }
      _loadingEtudiants = false;
    });
  }

  Future<void> _chargerModules() async {
    final res = await ProfessorService.getModules();
    if (!mounted) return;
    final idsVus = <String>{};
    final rawModules = res['success'] == true ? res['data'] as List<dynamic> : [];
    setState(() {
      _modules = rawModules.where((m) => idsVus.add(m['id'].toString())).toList();
      _loadingModules = false;
    });
  }

  Future<void> _chargerNotes() async {
    if (_moduleId == null || _anneeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Choisissez le module et l\'année académique.'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    setState(() { _loadingNotes = true; _erreurNotes = null; _notesData = null; });
    final result = await ApiService.getListeClasseAvecNotes(
      filiereId: widget.classe['id'].toString(),
      niveau: _niveau ?? '',
      moduleId: _moduleId!,
      anneeAcademique: _anneeCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        _notesData = result['data'] as Map<String, dynamic>;
      } else {
        _erreurNotes = result['error']?.toString();
      }
      _loadingNotes = false;
    });
  }

  // Semestre du module chargé (défini par l'administration).
  String _semestreAffiche() {
    final s = _notesData?['semestre']?.toString();
    if (s != null && s.isNotEmpty) return s.startsWith('S') ? s : 'S$s';
    for (final m in _modules) {
      if (m['id'].toString() == _moduleId && m['semestre'] != null) {
        return 'S${m['semestre'].toString().replaceAll(RegExp(r'\D'), '')}';
      }
    }
    return '';
  }

  double get _dureeSeance => double.tryParse(_dureeSeanceCtrl.text.trim().replaceAll(',', '.')) ?? 2.0;

  Future<void> _imprimerOuTelecharger(pw.Document pdf, String nomFichier) async {
    final choix = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.print_rounded, color: AppPalette.blue),
            title: const Text('Imprimer'),
            onTap: () => Navigator.pop(sheetContext, 'imprimer'),
          ),
          ListTile(
            leading: const Icon(Icons.download_rounded, color: Color(0xFF10B981)),
            title: const Text('Télécharger le PDF'),
            onTap: () => Navigator.pop(sheetContext, 'telecharger'),
          ),
        ]),
      ),
    );
    if (choix == 'imprimer') {
      await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: nomFichier);
    } else if (choix == 'telecharger') {
      await Printing.sharePdf(bytes: await pdf.save(), filename: nomFichier);
    }
  }

  Future<void> _genererPDF() async {
    await EtablissementConfig.instance.charger();
    final etablissement = EtablissementConfig.instance.nom.trim();
    const bleu = PdfColor.fromInt(0xFF1E40AF);
    const gris = PdfColor.fromInt(0xFF64748B);
    const fond = PdfColor.fromInt(0xFFF1F5F9);
    final enrichi = _notesData != null;
    final filiere = '${widget.classe['nom'] ?? ''}';
    final niveau = _niveau ?? '';
    final professeur = widget.professeurNom.trim();
    final d = DateTime.now();
    String deux(int n) => n.toString().padLeft(2, '0');
    final dateTxt = '${deux(d.day)}/${deux(d.month)}/${d.year}';

    pw.Widget info(String cle, String valeur) => pw.Expanded(
          child: pw.RichText(
            text: pw.TextSpan(children: [
              pw.TextSpan(text: '$cle : ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.TextSpan(text: valeur.isEmpty ? '-' : valeur, style: const pw.TextStyle(fontSize: 10)),
            ]),
          ),
        );

    final lignesInfo = <List<List<String>>>[
      [['Filière', filiere], ['Niveau', niveau]],
      [['Professeur', professeur], ['Date', dateTxt]],
      if (enrichi) ...[
        [['Module', '${_notesData!['module_nom'] ?? ''}'], ['Semestre', _semestreAffiche()]],
        [['Année académique', _anneeCtrl.text.trim()], ['Coefficient', '${_notesData!['coefficient'] ?? ''}']],
      ],
    ];

    final entete = <pw.Widget>[
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: bleu, width: 1.2), borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Column(children: [
          if (etablissement.isNotEmpty) ...[
            pw.Text(etablissement.toUpperCase(),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: bleu)),
            pw.SizedBox(height: 6),
            pw.Container(height: 0.8, width: 120, color: bleu),
            pw.SizedBox(height: 6),
          ],
          pw.Text('LISTE DES ÉTUDIANTS',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ]),
      ),
      pw.SizedBox(height: 10),
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5), borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Column(children: [
          for (var k = 0; k < lignesInfo.length; k++) ...[
            if (k > 0) pw.SizedBox(height: 6),
            pw.Row(children: [for (final c in lignesInfo[k]) info(c[0], c[1])]),
          ],
        ]),
      ),
      pw.SizedBox(height: 10),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 12),
        decoration: pw.BoxDecoration(color: PdfColors.blue50, borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Text(
          'Effectif : ${enrichi ? (_notesData!['etudiants'] as List<dynamic>).length : _etudiants.length} étudiant(s)',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: bleu),
        ),
      ),
      pw.SizedBox(height: 12),
    ];

    final pdf = pw.Document();
    pw.Widget pied(pw.Context ctx) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('ScolarHub - liste des étudiants du $dateTxt', style: const pw.TextStyle(fontSize: 8, color: gris)),
          pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: gris)),
        ]);

    if (enrichi) {
      final nbSessions = (_notesData!['nb_sessions'] as num).toInt();
      final etudiants = _notesData!['etudiants'] as List<dynamic>;
      final coefficient = _notesData!['coefficient'];
      final headers = [
        'N°', 'Nom', 'Prénom(s)',
        ...List.generate(nbSessions, (i) => 'Note ${i + 1}'),
        'Coef.', 'H. absence',
      ];
      final data = <List<String>>[];
      for (var i = 0; i < etudiants.length; i++) {
        final e = etudiants[i];
        final notes = (e['notes'] as List<dynamic>);
        final nbAbsences = (e['nb_absences'] as num).toInt();
        final heures = nbAbsences * _dureeSeance;
        data.add([
          '${i + 1}', e['nom']?.toString() ?? '', e['prenoms']?.toString() ?? '',
          ...notes.map((n) => n == null ? '-' : n.toString()),
          '$coefficient', '${heures.toStringAsFixed(heures % 1 == 0 ? 0 : 1)}h',
        ]);
      }
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(30),
        footer: pied,
        build: (ctx) => [
          ...entete,
          pw.TableHelper.fromTextArray(
            headers: headers, data: data,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9.5),
            headerDecoration: const pw.BoxDecoration(color: bleu),
            cellStyle: const pw.TextStyle(fontSize: 9.5),
            oddRowDecoration: const pw.BoxDecoration(color: fond),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            columnWidths: {
              0: const pw.FixedColumnWidth(28),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2.4),
            },
          ),
          pw.SizedBox(height: 10),
          pw.Text('Durée d\'une séance utilisée pour le calcul des heures d\'absence : ${_dureeSeance}h.',
              style: const pw.TextStyle(fontSize: 8, color: gris)),
        ],
      ));
      await _imprimerOuTelecharger(pdf, 'Liste_Etudiants_${filiere.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}.pdf');
      return;
    }

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      footer: pied,
      build: (ctx) => [
        ...entete,
        pw.TableHelper.fromTextArray(
          headers: ['N°', 'Nom', 'Prénom(s)'],
          data: _etudiants.asMap().entries.map((entry) => [
            '${entry.key + 1}',
            entry.value['nom']?.toString() ?? '',
            entry.value['prenoms']?.toString() ?? '',
          ]).toList(),
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: bleu),
          cellStyle: const pw.TextStyle(fontSize: 10),
          oddRowDecoration: const pw.BoxDecoration(color: fond),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          columnWidths: {
            0: const pw.FixedColumnWidth(28),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2.4),
          },
        ),
      ],
    ));
    await _imprimerOuTelecharger(pdf, 'Liste_Etudiants_${filiere.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}.pdf');
  }

  // ── Tableau affiché à l'écran : N°, Nom, Prénom(s) (+ notes et absences
  // quand un module est chargé), pleine largeur, lignes alternées.
  Widget _tableauEtudiants() {
    const bleu = Color(0xFF1E40AF);
    const bord = BorderSide(color: Color(0xFFE2E8F0), width: 0.8);
    final enrichi = _notesData != null;
    final nbSessions = enrichi ? (_notesData!['nb_sessions'] as num).toInt() : 0;
    final lignes = enrichi ? (_notesData!['etudiants'] as List<dynamic>) : _etudiants;

    Widget cell(String t, {bool entete = false, Color? couleur, bool gras = false, TextAlign align = TextAlign.left}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(t,
              textAlign: align,
              style: TextStyle(
                fontSize: entete ? 12.5 : 13,
                fontWeight: entete || gras ? FontWeight.w700 : FontWeight.w500,
                color: entete ? Colors.white : (couleur ?? const Color(0xFF0F172A)),
              )),
        );

    final colonnes = <int, TableColumnWidth>{
      0: const FixedColumnWidth(48),
      1: const FlexColumnWidth(2),
      2: const FlexColumnWidth(2.4),
      if (enrichi) ...{
        for (var i = 0; i < nbSessions; i++) 3 + i: const FixedColumnWidth(80),
        3 + nbSessions: const FixedColumnWidth(70),
        4 + nbSessions: const FixedColumnWidth(100),
      },
    };

    final enteteRow = TableRow(
      decoration: const BoxDecoration(color: bleu),
      children: [
        cell('N°', entete: true),
        cell('Nom', entete: true),
        cell('Prénom(s)', entete: true),
        if (enrichi) ...[
          for (var i = 0; i < nbSessions; i++) cell('Note ${i + 1}', entete: true, align: TextAlign.center),
          cell('Coef.', entete: true, align: TextAlign.center),
          cell('H. absence', entete: true, align: TextAlign.center),
        ],
      ],
    );

    final rows = <TableRow>[
      for (var i = 0; i < lignes.length; i++)
        TableRow(
          decoration: BoxDecoration(color: i.isOdd ? const Color(0xFFF8FAFC) : Colors.white),
          children: [
            cell('${i + 1}', couleur: const Color(0xFF64748B)),
            cell('${lignes[i]['nom'] ?? ''}', gras: true),
            cell('${lignes[i]['prenoms'] ?? ''}'),
            if (enrichi) ...[
              for (final n in (lignes[i]['notes'] as List<dynamic>))
                cell(n == null ? '-' : n.toString(), gras: true, align: TextAlign.center),
              cell('${_notesData!['coefficient']}', align: TextAlign.center),
              () {
                final nbAbs = (lignes[i]['nb_absences'] as num).toInt();
                final h = nbAbs * _dureeSeance;
                return cell('${h.toStringAsFixed(h % 1 == 0 ? 0 : 1)}h',
                    gras: true, align: TextAlign.center, couleur: nbAbs > 0 ? Colors.redAccent : null);
              }(),
            ],
          ],
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: lignes.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Aucun étudiant dans cette classe.', style: TextStyle(color: Color(0xFF94A3B8)))),
            )
          : LayoutBuilder(builder: (context, c) {
              final largeurMin = enrichi ? 48 + 260 + nbSessions * 80 + 170 : 0.0;
              final table = Table(
                border: const TableBorder(horizontalInside: bord),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: colonnes,
                children: [enteteRow, ...rows],
              );
              if (!enrichi || c.maxWidth >= largeurMin) return table;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: largeurMin.toDouble(), child: table),
              );
            }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        title: Text('${widget.classe['nom']} — $_niveau', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      body: _loadingEtudiants
          ? const Center(child: CircularProgressIndicator())
          : _erreurEtudiants != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_erreurEtudiants!, style: const TextStyle(color: Colors.redAccent)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _chargerEtudiants, child: const Text('Réessayer')),
                  ]),
                ))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text('${_etudiants.length} étudiant(s)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      ),
                      ElevatedButton.icon(
                        onPressed: _genererPDF,
                        icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
                        label: const Text('PDF', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _tableauEtudiants(),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: Column(children: [
                        ListTile(
                          onTap: () => setState(() => _enrichissementOuvert = !_enrichissementOuvert),
                          leading: const Icon(Icons.fact_check_outlined, color: Color(0xFF10B981)),
                          title: const Text('Ajouter notes et absences', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          subtitle: const Text('Optionnel — pour un module précis', style: TextStyle(fontSize: 11)),
                          trailing: Icon(_enrichissementOuvert ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                        ),
                        if (_enrichissementOuvert)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _loadingModules
                                ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
                                : Column(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _moduleId,
                                          isExpanded: true,
                                          hint: const Text('Choisir un module'),
                                          items: _modules.map<DropdownMenuItem<String>>((m) => DropdownMenuItem(value: m['id'].toString(), child: Text('${m['nom']}'))).toList(),
                                          onChanged: (v) => setState(() { _moduleId = v; _notesData = null; }),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                                          child: Row(children: [
                                            const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF64748B)),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(
                                              _moduleId == null ? 'Semestre : selon le module' : 'Semestre : ${_semestreAffiche().isEmpty ? "à définir" : _semestreAffiche()}',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                            )),
                                          ]),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: _anneeCtrl,
                                          decoration: InputDecoration(labelText: 'Année académique', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                                        ),
                                      ),
                                    ]),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _dureeSeanceCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        labelText: 'Durée d\'une séance (heures)',
                                        helperText: 'Convertit le nombre de séances absentes en heures.',
                                        isDense: true,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _loadingNotes ? null : _chargerNotes,
                                        icon: _loadingNotes
                                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                            : const Icon(Icons.search_rounded, color: Colors.white, size: 18),
                                        label: const Text('Charger notes & absences', style: TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                      ),
                                    ),
                                    if (_erreurNotes != null) ...[
                                      const SizedBox(height: 10),
                                      Text(_erreurNotes!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                                    ],
                                    if (_notesData != null) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10)),
                                        child: Text(
                                          '✅ ${_notesData!['module_nom']} chargé — ${_notesData!['nb_sessions']} évaluation(s) validée(s). Le PDF inclura désormais les notes et absences.',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF047857)),
                                        ),
                                      ),
                                    ],
                                  ]),
                          ),
                      ]),
                    ),
                  ],
                ),
    );
  }
}
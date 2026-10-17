import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import '../services/professor_service.dart';
import '../theme/app_palette.dart';
import 'notes_tab.dart' show semestresPourNiveau;

/// Liste des étudiants d'une classe (filière+niveau). S'affiche
/// immédiatement (nom, prénoms, matricule) — le choix module/semestre/année
/// est optionnel et ne sert qu'à enrichir avec les notes des sessions
/// validées, le coefficient du module et les heures d'absence.
class ProfesseurListeEtudiantsScreen extends StatefulWidget {
  const ProfesseurListeEtudiantsScreen({super.key, required this.classe});
  final Map<String, dynamic> classe; // {id, nom, niveau}

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
  String? _semestre;
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
    if (_moduleId == null || _semestre == null || _anneeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Choisissez module, semestre et année académique.'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    setState(() { _loadingNotes = true; _erreurNotes = null; _notesData = null; });
    final result = await ApiService.getListeClasseAvecNotes(
      filiereId: widget.classe['id'].toString(),
      niveau: _niveau ?? '',
      moduleId: _moduleId!,
      semestre: _semestre!,
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
    final pdf = pw.Document();

    if (_notesData != null) {
      final nbSessions = (_notesData!['nb_sessions'] as num).toInt();
      final etudiants = _notesData!['etudiants'] as List<dynamic>;
      final coefficient = _notesData!['coefficient'];
      final moduleNom = _notesData!['module_nom'] ?? '';

      final headers = [
        'N°', 'Matricule', 'Nom', 'Prénoms',
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
          '${i + 1}', e['matricule']?.toString() ?? '', e['nom']?.toString() ?? '', e['prenoms']?.toString() ?? '',
          ...notes.map((n) => n == null ? '-' : n.toString()),
          '$coefficient', '${heures.toStringAsFixed(heures % 1 == 0 ? 0 : 1)}h',
        ]);
      }

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('LISTE DES ÉTUDIANTS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1E40AF))),
          pw.SizedBox(height: 4),
          pw.Text('${widget.classe['nom']} — $_niveau · $moduleNom · $_semestre (${_anneeCtrl.text})', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: headers, data: data,
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E40AF)),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(5),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Durée d\'une séance utilisée pour le calcul des heures d\'absence : ${_dureeSeance}h.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ]),
      ));
      await _imprimerOuTelecharger(pdf, 'Liste_Etudiants_${widget.classe['nom']}.pdf');
      return;
    }

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('LISTE DES ÉTUDIANTS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1E40AF))),
        pw.SizedBox(height: 4),
        pw.Text('${widget.classe['nom']} — $_niveau', style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 14),
        pw.TableHelper.fromTextArray(
          headers: ['N°', 'Matricule', 'Nom', 'Prénoms'],
          data: _etudiants.asMap().entries.map((entry) => [
            '${entry.key + 1}',
            entry.value['matricule']?.toString() ?? '',
            entry.value['nom']?.toString() ?? '',
            entry.value['prenoms']?.toString() ?? '',
          ]).toList(),
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E40AF)),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: const pw.EdgeInsets.all(6),
        ),
      ]),
    ));
    await _imprimerOuTelecharger(pdf, 'Liste_Etudiants_${widget.classe['nom']}.pdf');
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
                    // ── Tableau (mis à jour avec Note 1/2/3, Coef., Heures
                    // d'absence dès que le module est chargé ci-dessous — ce
                    // sont de vraies colonnes, au même niveau que Nom/Prénoms,
                    // pas du texte regroupé à côté du nom).
                    Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                          columns: [
                            const DataColumn(label: Text('Matricule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            const DataColumn(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            const DataColumn(label: Text('Prénom(s)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            if (_notesData != null) ...[
                              for (var i = 0; i < (_notesData!['nb_sessions'] as num).toInt(); i++)
                                DataColumn(label: Text('Note ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              const DataColumn(label: Text('Coef.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              const DataColumn(label: Text('H. absence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            ],
                          ],
                          rows: _notesData != null
                              ? (_notesData!['etudiants'] as List<dynamic>).map((e) {
                                  final notes = e['notes'] as List<dynamic>;
                                  final nbAbsences = (e['nb_absences'] as num).toInt();
                                  final heures = nbAbsences * _dureeSeance;
                                  return DataRow(cells: [
                                    DataCell(Text('${e['matricule']}', style: const TextStyle(fontSize: 12))),
                                    DataCell(Text('${e['nom']}', style: const TextStyle(fontSize: 12))),
                                    DataCell(Text('${e['prenoms']}', style: const TextStyle(fontSize: 12))),
                                    ...notes.map((n) => DataCell(Text(n == null ? '-' : n.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))),
                                    DataCell(Text('${_notesData!['coefficient']}', style: const TextStyle(fontSize: 12))),
                                    DataCell(Text(
                                      '${heures.toStringAsFixed(heures % 1 == 0 ? 0 : 1)}h',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: nbAbsences > 0 ? Colors.redAccent : const Color(0xFF0F172A)),
                                    )),
                                  ]);
                                }).toList()
                              : _etudiants.map((e) => DataRow(cells: [
                                    DataCell(Text('${e['matricule']}', style: const TextStyle(fontSize: 12))),
                                    DataCell(Text('${e['nom']}', style: const TextStyle(fontSize: 12))),
                                    DataCell(Text('${e['prenoms']}', style: const TextStyle(fontSize: 12))),
                                  ])).toList(),
                        ),
                      ),
                    ),
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
                                          onChanged: (v) => setState(() => _moduleId = v),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _semestre,
                                              isExpanded: true,
                                              hint: const Text('Semestre'),
                                              items: semestresPourNiveau(_niveau).map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                              onChanged: (v) => setState(() => _semestre = v),
                                            ),
                                          ),
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
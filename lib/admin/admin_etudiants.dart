import 'package:flutter/material.dart';
import '../models/etudiant_model.dart'; // Import crucial
import '../services/api_service.dart';
import '../admin/admin_theme.dart';

class AdminEtudiants extends StatefulWidget {
  const AdminEtudiants({super.key});
  @override State<AdminEtudiants> createState() => _AdminEtudiantsState();
}

class _AdminEtudiantsState extends State<AdminEtudiants> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Etudiant> _filteredList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _chargerEtudiants();
  }

  Future<void> _chargerEtudiants() async {
    setState(() => _loading = true);
    final result = await ApiService.getEtudiants();
    if (result['success'] == true) {
      final data = result['data'] as List<dynamic>;
      adminEtudiants = data
          .map((e) => _etudiantFromApi(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else {
      adminEtudiants = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Erreur chargement étudiants'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  // --- Fonctions manquantes ---
  void _inscrireEtudiant() { /* Ton ancienne logique ici */ }
  void _ouvrirFiche(Etudiant e) { /* Ton ancienne logique ici */ }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, 20, isDesktop ? 24 : 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Étudiants', style: TextStyle(fontSize: 22,
                    fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                Text('${adminEtudiants.length} inscrits · ${liste.length} affichés',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              ])),
              _statBadge('${adminEtudiants.where((e) => e.statut == 'actif').length} Actifs',
                  AdminTheme.success, AdminTheme.successLight),
              const SizedBox(width: 6),
              _statBadge('${adminEtudiants.where((e) => e.statut == 'suspendu').length} Suspendus',
                  AdminTheme.warning, AdminTheme.warningLight),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _inscrireEtudiant(),
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AdminTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: AdminTheme.primary.withOpacity(0.3),
                        blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.person_add_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Inscrire', style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            TabBar(
              controller: _tabs,
              labelColor: AdminTheme.primary,
              unselectedLabelColor: AdminTheme.textSecondary,
              indicatorColor: AdminTheme.primary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(text: 'Tous (${adminEtudiants.length})'),
                Tab(text: 'Délégués & BDE (${adminEtudiants.where((e) => e.role != 'etudiant').length})'),
              ]),
          ]),
        ),
        adminDivider,
        Expanded(child: TabBarView(controller: _tabs, children: [
          // ── Onglet 1 : Liste complète ──────────────────────────────
          Column(children: [
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, 10, isDesktop ? 24 : 16, 10),
              child: isDesktop
                  ? Row(children: [
                      Expanded(flex: 3, child: _searchBar()),
                      const SizedBox(width: 10),
                      Expanded(child: _filtreDropdown('Statut', _filtreStatut,
                          ['tous', 'actif', 'suspendu', 'renvoye'],
                          ['Tous', 'Actif', 'Suspendu', 'Renvoyé'],
                          (v) => setState(() => _filtreStatut = v!))),
                      const SizedBox(width: 10),
                      Expanded(child: _filtreDropdown('Domaine', _filtredomaine,
                          ['tous', 'Sciences & Technologies', 'Sciences de Gestion'],
                          ['Tous', 'Sciences & Tech', 'Gestion'],
                          (v) => setState(() => _filtredomaine = v!))),
                      const SizedBox(width: 10),
                      Expanded(child: _filtreDropdown('Niveau', _filtreNiveau,
                          ['tous', 'Licence 1', 'Licence 2', 'Licence 3'],
                          ['Tous', 'Licence 1', 'Licence 2', 'Licence 3'],
                          (v) => setState(() => _filtreNiveau = v!))),
                    ])
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _searchBar(),
                      const SizedBox(height: 8),
                      SingleChildScrollView(scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          _filtreChip('Tous', _filtreStatut == 'tous',
                              () => setState(() => _filtreStatut = 'tous')),
                          _filtreChip('Actifs', _filtreStatut == 'actif',
                              () => setState(() => _filtreStatut = 'actif'),
                              color: AdminTheme.success),
                          _filtreChip('Suspendus', _filtreStatut == 'suspendu',
                              () => setState(() => _filtreStatut = 'suspendu'),
                              color: AdminTheme.warning),
                          _filtreChip('Renvoyés', _filtreStatut == 'renvoye',
                              () => setState(() => _filtreStatut = 'renvoye'),
                              color: AdminTheme.danger),
                        ])),
                    ]),
            ),
            adminDivider,
            Expanded(child: liste.isEmpty
                ? _vide()
                : ListView.separated(
                    padding: EdgeInsets.all(isDesktop ? 20 : 12),
                    itemCount: liste.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _carteEtudiant(liste[i]),
                  )),
          ]),
          // ── Onglet 2 : Délégués & BDE ─────────────────────────────
          _pageDeleguesBDE(isDesktop),
        ])),
      ]),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.all(24),
    color: Colors.white,
    child: Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        _inputField(ctrl, hint, type: type),
      ]);

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(t, style: const TextStyle(fontSize: 12,
        fontWeight: FontWeight.w700, color: Color(0xFF374151))));

  Widget _inputField(TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text}) =>
      Container(
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: TextField(controller: ctrl, keyboardType: type,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10))));

  Widget _selectField(String value, List<String> items,
      ValueChanged<String?> onChanged) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: value, isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)),
          items: items.map((v) => DropdownMenuItem(value: v,
              child: Text(v, style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        )));

  // ════════════════════════════════════════════════════════════════════════
  // FICHE INDIVIDUELLE
  // ════════════════════════════════════════════════════════════════════════
  void _ouvrirFiche(Etudiant e) {
    showModalBottomSheet(context: context, isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _FicheEtudiant(
            etudiant: e, onRefresh: () => setState(() {})));
  }

  // ════════════════════════════════════════════════════════════════════════
  // GÉNÉRATION CARTE PDF
  // ════════════════════════════════════════════════════════════════════════
  Future<void> _genererCarte(Etudiant e) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat(85.6 * PdfPageFormat.mm, 54 * PdfPageFormat.mm),
      margin: const pw.EdgeInsets.all(0),
      build: (ctx) => pw.Container(
        decoration: const pw.BoxDecoration(
          gradient: pw.LinearGradient(
            colors: [PdfColor.fromInt(0xFF1A3C34), PdfColor.fromInt(0xFF2D6A4F)],
            begin: pw.Alignment.topLeft, end: pw.Alignment.bottomRight,
          ),
        ),
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Row(children: [
            pw.Expanded(child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(children: [
                  pw.Container(width: 20, height: 20,
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFD8F3DC),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                    child: pw.Center(child: pw.Text('S',
                        style: pw.TextStyle(fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(0xFF1A3C34))))),
                  pw.SizedBox(width: 6),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('ScholARHub', style: pw.TextStyle(fontSize: 9,
                        fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    pw.Text('IST Ouaga 2000', style: const pw.TextStyle(
                        fontSize: 7, color: PdfColors.white)),
                  ]),
                ]),
                pw.SizedBox(height: 6),
                pw.Container(width: 36, height: 36,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0x30FFFFFF),
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.white, width: 1.5)),
                  child: pw.Center(child: pw.Text('${e.prenoms[0]}${e.nom[0]}',
                      style: pw.TextStyle(fontSize: 14,
                          fontWeight: pw.FontWeight.bold, color: PdfColors.white)))),
                pw.SizedBox(height: 6),
                pw.Text('${e.prenoms} ${e.nom}', style: pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                pw.Text(e.filiere, style: const pw.TextStyle(
                    fontSize: 7, color: PdfColors.white)),
                pw.SizedBox(height: 2),
                pw.Text('${e.niveau} · 2024-2025', style: const pw.TextStyle(
                    fontSize: 7, color: PdfColors.white)),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFB7950B),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10))),
                  child: pw.Text(e.matricule, style: pw.TextStyle(
                      fontSize: 8, fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white, font: pw.Font.courier()))),
              ],
            )),
            pw.SizedBox(width: 10),
            pw.Column(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: 'ScholARHub|${e.matricule}|${e.nom}|${e.prenoms}',
                width: 52, height: 52,
                color: PdfColors.white,
                backgroundColor: PdfColor.fromInt(0x20FFFFFF)),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.white, width: 0.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3))),
                child: pw.Text('VALIDE 2024-2025', style: const pw.TextStyle(
                    fontSize: 5, color: PdfColors.white))),
            ]),
          ]),
        ),
      ),
    ));
    await Printing.layoutPdf(
        onLayout: (_) => pdf.save(),
        name: 'Carte_${e.nom}_${e.prenoms}.pdf');
  }

  void _menuActions(Etudiant e) {
    showModalBottomSheet(context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text('${e.prenoms} ${e.nom}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        Text(e.matricule, style: const TextStyle(fontSize: 11,
            color: Color(0xFF9CA3AF), fontFamily: 'monospace')),
        const SizedBox(height: 12),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.visibility_rounded, color: AdminTheme.primary),
            title: const Text('Voir la fiche'),
            onTap: () { Navigator.pop(context); _ouvrirFiche(e); }),
        ListTile(leading: const Icon(Icons.picture_as_pdf_rounded, color: AdminTheme.warning),
            title: const Text('Générer carte PDF'),
            onTap: () { Navigator.pop(context); _genererCarte(e); }),
        if (e.statut == 'actif')
          ListTile(
            leading: const Icon(Icons.block_rounded, color: AdminTheme.warning),
            title: const Text('Suspendre', style: TextStyle(color: AdminTheme.warning)),
            onTap: () { Navigator.pop(context);
              setState(() => e.statut = 'suspendu');
              _snack('${e.prenoms} suspendu(e).'); }),
        if (e.statut == 'suspendu')
          ListTile(
            leading: const Icon(Icons.check_circle_outline, color: AdminTheme.success),
            title: const Text('Réactiver', style: TextStyle(color: AdminTheme.success)),
            onTap: () { Navigator.pop(context);
              setState(() => e.statut = 'actif');
              _snack('${e.prenoms} réactivé(e).'); }),
        const SizedBox(height: 8),
      ])));
  }

  void _snack(String msg) => showAppSnackBar(context, msg);
}

// ════════════════════════════════════════════════════════════════════════════
// FICHE ÉTUDIANT
// ════════════════════════════════════════════════════════════════════════════
class _FicheEtudiant extends StatelessWidget {
  final Etudiant etudiant;
  final VoidCallback onRefresh;
  const _FicheEtudiant({required this.etudiant, required this.onRefresh});

  double get _moyenne {
    if (etudiant.notes.isEmpty) return 0;
    final total = etudiant.notes.fold<double>(0,
        (s, n) => s + (n['note'] as double) * (n['coef'] as int));
    final coefs = etudiant.notes.fold<int>(0, (s, n) => s + (n['coef'] as int));
    return total / coefs;
  }

  @override
  Widget build(BuildContext context) {
    final e = etudiant;
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
        // Header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AdminTheme.primary, AdminTheme.primaryMid],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AdminTheme.elevatedShadow),
          child: Row(children: [
            Container(width: 60, height: 60,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2)),
              child: Center(child: Text('${e.prenoms[0]}${e.nom[0]}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: Colors.white)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${e.prenoms} ${e.nom}', style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 3),
              Text(e.matricule, style: const TextStyle(
                  fontSize: 11, color: Colors.white70, fontFamily: 'monospace')),
              const SizedBox(height: 3),
              Text('${e.filiere} · ${e.niveau}', style: const TextStyle(
                  fontSize: 11, color: Colors.white70)),
              if (e.badges.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(spacing: 6, children: e.badges.map((b) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: AdminTheme.accent.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('🏅 $b', style: const TextStyle(
                      fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)))).toList()),
              ],
            ])),
            Column(children: [
              if (etudiant.notes.isNotEmpty) ...[
                Text(_moyenne.toStringAsFixed(1), style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w900,
                    color: _moyenne >= 10 ? AdminTheme.primaryLight : AdminTheme.danger)),
                const Text('/20', style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ]),
          ]),
        ),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _section('Informations personnelles', [
              _row(Icons.cake_rounded, 'Naissance', e.dateNaissance),
              _row(Icons.flag_rounded, 'Nationalité', e.nationalite),
              _row(Icons.phone_rounded, 'Téléphone', e.telephone),
              _row(Icons.email_rounded, 'Email', e.email),
              _row(Icons.home_rounded, 'Adresse', e.adresse),
            ]),
            const SizedBox(height: 12),
            _section('Contact d\'urgence', [
              _row(Icons.person_rounded, 'Parent', e.nomParent),
              _row(Icons.phone_rounded, 'Téléphone', e.telParent),
            ]),
            if (e.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionNotes(e),
            ],
          ])),
        ),
      ]),
      const Spacer(),
      FilledButton.icon(onPressed: _inscrireEtudiant, icon: const Icon(Icons.add), label: const Text('Inscrire'))
    ]),
  );

  Widget _buildListView(List<Etudiant> items) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: items.length,
    itemBuilder: (_, i) => _carteEtudiantModerne(items[i]),
  );

  Widget _carteEtudiantModerne(Etudiant e) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: CircleAvatar(child: Text(e.prenoms[0])),
      title: Text("${e.prenoms} ${e.nom}"),
      subtitle: Text(e.matricule),
      trailing: IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _ouvrirFiche(e)),
    ),
  );
}
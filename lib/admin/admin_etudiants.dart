import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:image_picker/image_picker.dart';
import '../models/etudiant_model.dart';
import '../models/student_profile.dart';
import '../services/api_service.dart';
import '../app/scolar_hub_app.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_widgets.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/delegue_badge.dart';
class AdminEtudiants extends StatefulWidget {
  final StudentProfile profile;
  const AdminEtudiants({super.key, required this.profile});
  @override
  State<AdminEtudiants> createState() => _AdminEtudiantsState();
}

class _AdminEtudiantsState extends State<AdminEtudiants>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _loading = true;

  String _filtreStatut = 'tous';
  late String _filtredomaine;
  String _filtreNiveau = 'tous';
  String _filtreFiliere = 'toutes';
  String _recherche = '';
  final TextEditingController _searchCtrl = TextEditingController();

  bool get isDesktop => MediaQuery.of(context).size.width >= 900;

  /// Filières distinctes présentes dans la liste — alimente le filtre.
  List<String> get _filieresDisponibles {
    final noms = adminEtudiants.map((e) => e.filiere).where((f) => f.isNotEmpty).toSet().toList();
    noms.sort();
    return noms;
  }

  List<Etudiant> get liste => adminEtudiants.where((e) {
    if (_filtreStatut.toLowerCase() != 'tous' &&
        e.statut.toLowerCase() != _filtreStatut.toLowerCase())
      return false;
    if (_filtredomaine.toLowerCase() != 'tous' &&
        e.domaine.toLowerCase() != _filtredomaine.toLowerCase())
      return false;
    if (_filtreNiveau.toLowerCase() != 'tous' &&
        e.niveau.toLowerCase() != _filtreNiveau.toLowerCase())
      return false;
    if (_filtreFiliere.toLowerCase() != 'toutes' &&
        e.filiere.toLowerCase() != _filtreFiliere.toLowerCase())
      return false;
    if (_recherche.isNotEmpty) {
      final q = _recherche.toLowerCase();
      if (!e.nom.toLowerCase().contains(q) &&
          !e.prenoms.toLowerCase().contains(q) &&
          !e.matricule.toLowerCase().contains(q)) {
        return false;
      }
    }
    return true;
  }).toList();

  @override
  void initState() {
    super.initState();
    _filtredomaine = widget.profile.filtreParDomaine
        ? widget.profile.domaineAdmin
        : 'tous';
    _tabs = TabController(length: 2, vsync: this);
    _chargerEtudiants();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerEtudiants() async {
    setState(() => _loading = true);
    final result = await ApiService.getEtudiants(
      domaine: widget.profile.filtreParDomaine
          ? widget.profile.domaineAdmin
          : null,
    );
    if (result['success'] == true) {
      final data = result['data'] as List<dynamic>;
      // ignore: avoid_print
      print(
        '[AdminEtudiants] ${data.length} étudiant(s) chargé(s) | filtreParDomaine=${widget.profile.filtreParDomaine} | domaineAdmin=${widget.profile.domaineAdmin}',
      );
      adminEtudiants = data
          .map((e) => etudiantFromApi(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else {
      // ignore: avoid_print
      print('[AdminEtudiants] ERREUR chargement: ${result['error']}');
      adminEtudiants = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  void _inscrireEtudiant() {
    showDialog(
      context: context,
      builder: (_) => _InscrireEtudiantDialog(
        onInscrit: () {
          _chargerEtudiants();
          _snack('Étudiant inscrit avec succès.');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 24 : 16,
              20,
              isDesktop ? 24 : 16,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Étudiants',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            '${adminEtudiants.length} inscrits · ${liste.length} affichés',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statBadge(
                      '${adminEtudiants.where((e) => e.statut == 'actif').length} Actifs',
                      AdminTheme.success,
                      AdminTheme.successLight,
                    ),
                    const SizedBox(width: 6),
                    _statBadge(
                      '${adminEtudiants.where((e) => e.statut == 'suspendu').length} Suspendus',
                      AdminTheme.warning,
                      AdminTheme.warningLight,
                    ),
                    const SizedBox(width: 6),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _exporterListePDF,
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEF4444)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFEF4444), size: 16),
                            SizedBox(width: 6),
                            Text('PDF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _inscrireEtudiant(),
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AdminTheme.iconBgAlt,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AdminTheme.iconBgAlt.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_add_rounded,
                              color: AdminTheme.iconFgAlt,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Inscrire',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TabBar(
                  controller: _tabs,
                  labelColor: AdminTheme.primary,
                  unselectedLabelColor: AdminTheme.textSecondary,
                  indicatorColor: AdminTheme.primary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: 'Tous (${adminEtudiants.length})'),
                    Tab(
                      text:
                          'Délégués & BDE (${adminEtudiants.where((e) => e.role != 'etudiant').length})',
                    ),
                  ],
                ),
              ],
            ),
          ),
          adminDivider,
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // ── Onglet 1 : Liste complète ──────────────────────────────
                Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: EdgeInsets.fromLTRB(
                        isDesktop ? 24 : 16,
                        10,
                        isDesktop ? 24 : 16,
                        10,
                      ),
                      child: isDesktop
                          ? Row(
                              children: [
                                Expanded(flex: 3, child: _searchBar()),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _filtreDropdown(
                                    'Statut',
                                    _filtreStatut,
                                    ['tous', 'actif', 'suspendu', 'renvoye'],
                                    ['Tous', 'Actif', 'Suspendu', 'Renvoyé'],
                                    (v) => setState(() => _filtreStatut = v!),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _filtreDropdown(
                                    'Domaine',
                                    _filtredomaine,
                                    [
                                      'tous',
                                      'Sciences & Technologies',
                                      'Sciences de Gestion',
                                    ],
                                    ['Tous', 'Sciences & Tech', 'Gestion'],
                                    widget.profile.filtreParDomaine
                                        ? null
                                        : (v) => setState(
                                            () => _filtredomaine = v!,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _filtreDropdown(
                                    'Niveau',
                                    _filtreNiveau,
                                    [
                                      'tous',
                                      'Licence 1',
                                      'Licence 2',
                                      'Licence 3',
                                    ],
                                    [
                                      'Tous',
                                      'Licence 1',
                                      'Licence 2',
                                      'Licence 3',
                                    ],
                                    (v) => setState(() => _filtreNiveau = v!),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _filtreDropdown(
                                    'Filière',
                                    _filtreFiliere,
                                    ['toutes', ..._filieresDisponibles],
                                    ['Toutes', ..._filieresDisponibles],
                                    (v) => setState(() => _filtreFiliere = v!),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _searchBar(),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _filtreChip(
                                        'Tous',
                                        _filtreStatut == 'tous',
                                        () => setState(
                                          () => _filtreStatut = 'tous',
                                        ),
                                      ),
                                      _filtreChip(
                                        'Actifs',
                                        _filtreStatut == 'actif',
                                        () => setState(
                                          () => _filtreStatut = 'actif',
                                        ),
                                        color: AdminTheme.success,
                                      ),
                                      _filtreChip(
                                        'Suspendus',
                                        _filtreStatut == 'suspendu',
                                        () => setState(
                                          () => _filtreStatut = 'suspendu',
                                        ),
                                        color: AdminTheme.warning,
                                      ),
                                      _filtreChip(
                                        'Renvoyés',
                                        _filtreStatut == 'renvoye',
                                        () => setState(
                                          () => _filtreStatut = 'renvoye',
                                        ),
                                        color: AdminTheme.danger,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _filtreDropdown(
                                        'Niveau',
                                        _filtreNiveau,
                                        ['tous', 'Licence 1', 'Licence 2', 'Licence 3'],
                                        ['Tous', 'Licence 1', 'Licence 2', 'Licence 3'],
                                        (v) => setState(() => _filtreNiveau = v!),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _filtreDropdown(
                                        'Filière',
                                        _filtreFiliere,
                                        ['toutes', ..._filieresDisponibles],
                                        ['Toutes', ..._filieresDisponibles],
                                        (v) => setState(() => _filtreFiliere = v!),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                    adminDivider,
                    Expanded(
                      child: liste.isEmpty
                          ? _vide()
                          : ListView.separated(
                              padding: EdgeInsets.all(isDesktop ? 20 : 12),
                              itemCount: liste.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) => _carteEtudiant(liste[i]),
                            ),
                    ),
                  ],
                ),
                // ── Onglet 2 : Délégués & BDE ─────────────────────────────
                _pageDeleguesBDE(isDesktop),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, Color fg, Color bg) => Container(
    margin: const EdgeInsets.only(left: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
    ),
  );

  Widget _searchBar() => Container(
    height: 40,
    decoration: BoxDecoration(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _recherche = v),
      style: const TextStyle(fontSize: 13),
      decoration: const InputDecoration(
        hintText: 'Rechercher un étudiant...',
        hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: Color(0xFF9CA3AF),
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 10),
      ),
    ),
  );

  Widget _filtreDropdown(
    String hint,
    String? value,
    List<String> vals,
    List<String> labels,
    ValueChanged<String?>? onChanged,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    height: 40,
    decoration: BoxDecoration(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        hint: Text(
          hint,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
        style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A2E)),
        items: List.generate(
          vals.length,
          (i) => DropdownMenuItem(value: vals[i], child: Text(labels[i])),
        ),
        onChanged: onChanged,
      ),
    ),
  );

  Widget _filtreChip(
    String label,
    bool selected,
    VoidCallback onTap, {
    Color? color,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? (color ?? AdminTheme.primary) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? (color ?? AdminTheme.primary)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : const Color(0xFF374151),
        ),
      ),
    ),
  );

  Widget _carteEtudiant(Etudiant e) => GestureDetector(
    onTap: () => _ouvrirFiche(e),
    onLongPress: () => _menuActions(e),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: e.statut == 'suspendu'
              ? AdminTheme.warningLight
              : e.statut == 'renvoye'
              ? AdminTheme.dangerLight
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AdminTheme.iconBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${e.prenoms[0]}${e.nom[0]}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.iconFg,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Text(
                    '${e.prenoms} ${e.nom}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  )),
                  const SizedBox(width: 6),
                  DelegueBadge(role: e.role, niveau: e.niveau, compact: true),
                ]),
                Text(
                  e.matricule,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '${e.filiere} · ${e.niveau}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: e.statut == 'actif'
                  ? AdminTheme.successLight
                  : e.statut == 'suspendu'
                  ? AdminTheme.warningLight
                  : AdminTheme.dangerLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              e.statut[0].toUpperCase() + e.statut.substring(1),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: e.statut == 'actif'
                    ? AdminTheme.success
                    : e.statut == 'suspendu'
                    ? AdminTheme.warning
                    : AdminTheme.danger,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF9CA3AF),
            size: 18,
          ),
        ],
      ),
    ),
  );

  Widget _vide() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text(
          'Aucun étudiant trouvé',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Modifiez vos filtres de recherche',
          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        ),
      ],
    ),
  );

  Widget _pageDeleguesBDE(bool desktop) {
    final delegues = adminEtudiants.where((e) => e.role != 'etudiant').toList();
    if (delegues.isEmpty) return _vide();
    return ListView.separated(
      padding: EdgeInsets.all(desktop ? 20 : 12),
      itemCount: delegues.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _carteEtudiant(delegues[i]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // FICHE INDIVIDUELLE
  // ════════════════════════════════════════════════════════════════════════
  void _ouvrirFiche(Etudiant e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _FicheEtudiant(etudiant: e, onRefresh: () => setState(() {})),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // EXPORT PDF — LISTE FILTRÉE (roster, pas de notes : l'admin n'est pas
  // rattaché à un module précis)
  // ════════════════════════════════════════════════════════════════════════
  Future<void> _exporterListePDF() async {
    if (liste.isEmpty) {
      showAppSnackBar(context, 'Aucun étudiant à exporter avec ces filtres.');
      return;
    }
    final pdf = pw.Document();
    final filtreLabel = [
      if (_filtreFiliere != 'toutes') _filtreFiliere,
      if (_filtreNiveau != 'tous') _filtreNiveau,
      if (_filtreStatut != 'tous') _filtreStatut,
    ].join(' · ');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('INSTITUT SUPÉRIEUR DE TECHNOLOGIES (IST)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Text('Liste des étudiants', style: const pw.TextStyle(fontSize: 9)),
              ]),
              pw.Text('${liste.length} étudiant(s)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          if (filtreLabel.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text('Filtres : $filtreLabel', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          ],
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: ['N°', 'Matricule', 'Nom', 'Prénoms', 'Filière', 'Niveau', 'Statut'],
            data: liste.asMap().entries.map((entry) => [
              '${entry.key + 1}',
              entry.value.matricule,
              entry.value.nom,
              entry.value.prenoms,
              entry.value.filiere,
              entry.value.niveau,
              entry.value.statut,
            ]).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E40AF)),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(5),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Liste_Etudiants.pdf');
  }

  // ════════════════════════════════════════════════════════════════════════
  // GÉNÉRATION CARTE PDF
  // ════════════════════════════════════════════════════════════════════════
  /// Propose d'ajouter une photo AVANT de générer la carte. Cette photo est
  /// utilisée UNIQUEMENT pour ce PDF — elle n'est jamais envoyée au backend
  /// ni associée au profil de l'étudiant (voir demande explicite d'Ib).
  Future<void> _choisirPhotoEtGenererCarte(Etudiant e) async {
    Uint8List? photoBytes;
    final choix = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Photo pour la carte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        content: const Text(
          'Ajouter une photo pour cette carte d\'étudiant ? Elle ne sera utilisée que pour ce document — elle ne modifie pas le profil de l\'étudiant.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, 'sans'), child: const Text('Sans photo')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, 'avec'),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.iconBgAlt),
            child: const Text('Choisir une photo', style: TextStyle(color: AdminTheme.iconFgAlt)),
          ),
        ],
      ),
    );

    if (choix == 'avec') {
      try {
        final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
        if (picked != null) {
          photoBytes = await picked.readAsBytes();
        }
      } catch (_) {
        if (mounted) showAppSnackBar(context, 'Impossible de charger cette image.');
      }
    } else if (choix == null) {
      return; // dialogue fermé sans choix
    }

    _genererCarte(e, photoBytes: photoBytes);
  }

  Future<void> _genererCarte(Etudiant e, {Uint8List? photoBytes}) async {
    final pw.ImageProvider? photoImage = photoBytes != null ? pw.MemoryImage(photoBytes) : null;
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          85.6 * PdfPageFormat.mm,
          54 * PdfPageFormat.mm,
        ),
        margin: pw.EdgeInsets.zero,
        build: (ctx) => pw.Container(
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [
                PdfColor.fromInt(0xFF1A3C34),
                PdfColor.fromInt(0xFF2D6A4F),
              ],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
          ),
          child: pw.Padding(
            padding: pw.EdgeInsets.all(10),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 20,
                            height: 20,
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromInt(0xFFD8F3DC),
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(4),
                              ),
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                'S',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromInt(0xFF1A3C34),
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 6),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'ScholARHub',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                              pw.Text(
                                'IST Ouaga 2000',
                                style: const pw.TextStyle(
                                  fontSize: 7,
                                  color: PdfColors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        width: 36,
                        height: 36,
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0x30FFFFFF),
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(
                            color: PdfColors.white,
                            width: 1.5,
                          ),
                          image: photoImage != null
                              ? pw.DecorationImage(image: photoImage, fit: pw.BoxFit.cover)
                              : null,
                        ),
                        child: photoImage == null
                            ? pw.Center(
                                child: pw.Text(
                                  '${e.prenoms[0]}${e.nom[0]}',
                                  style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        '${e.prenoms} ${e.nom}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        e.filiere,
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '${e.niveau} · 2024-2025',
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFFB7950B),
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(10),
                          ),
                        ),
                        child: pw.Text(
                          e.matricule,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            font: pw.Font.courier(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: 'ScholARHub|${e.matricule}|${e.nom}|${e.prenoms}',
                      width: 52,
                      height: 52,
                      color: PdfColors.white,
                      backgroundColor: PdfColor.fromInt(0x20FFFFFF),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.white,
                          width: 0.5,
                        ),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(3),
                        ),
                      ),
                      child: pw.Text(
                        'VALIDE 2024-2025',
                        style: const pw.TextStyle(
                          fontSize: 5,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: 'Carte_${e.nom}_${e.prenoms}.pdf',
    );
  }

  void _menuActions(Etudiant e) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${e.prenoms} ${e.nom}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              e.matricule,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.visibility_rounded,
                color: AdminTheme.iconBg,
              ),
              title: const Text('Voir la fiche'),
              onTap: () {
                Navigator.pop(context);
                _ouvrirFiche(e);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf_rounded,
                color: AdminTheme.warning,
              ),
              title: const Text('Générer carte PDF'),
              onTap: () {
                Navigator.pop(context);
                _choisirPhotoEtGenererCarte(e);
              },
            ),
            if (e.statut == 'actif')
              ListTile(
                leading: const Icon(
                  Icons.block_rounded,
                  color: AdminTheme.warning,
                ),
                title: const Text(
                  'Suspendre',
                  style: TextStyle(color: AdminTheme.warning),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _changerStatut(e, 'suspendu');
                },
              ),
            if (e.statut == 'suspendu')
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: AdminTheme.success,
                ),
                title: const Text(
                  'Réactiver',
                  style: TextStyle(color: AdminTheme.success),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _changerStatut(e, 'actif');
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ⚠️ CORRIGÉ — "Suspendre"/"Réactiver" ne faisaient auparavant qu'un
  // setState() local, jamais persisté en base : l'étudiant "suspendu"
  // pouvait donc continuer à se connecter normalement. Appelle maintenant
  // le vrai endpoint, qui met à jour users.statut (vérifié par login()).
  Future<void> _changerStatut(Etudiant e, String nouveauStatut) async {
    final result = await ApiService.changerStatutEtudiant(e.id, nouveauStatut);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() => e.statut = nouveauStatut);
      _snack(nouveauStatut == 'actif' ? '${e.prenoms} réactivé(e).' : '${e.prenoms} suspendu(e).');
    } else {
      _snack(result['error']?.toString() ?? 'Erreur lors du changement de statut.');
    }
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
    final total = etudiant.notes.fold<double>(
      0,
      (s, n) => s + (n['note'] as double) * (n['coef'] as int),
    );
    final coefs = etudiant.notes.fold<int>(0, (s, n) => s + (n['coef'] as int));
    return total / coefs;
  }

  @override
  Widget build(BuildContext context) {
    final e = etudiant;
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AdminTheme.primary, AdminTheme.primaryMid],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AdminTheme.elevatedShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${e.prenoms[0]}${e.nom[0]}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.prenoms} ${e.nom}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        e.matricule,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${e.filiere} · ${e.niveau}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                      if (e.badges.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: e.badges
                              .map(
                                (b) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AdminTheme.accent.withValues(
                                      alpha: 0.3,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '🏅 $b',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (etudiant.notes.isNotEmpty) ...[
                      Text(
                        _moyenne.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: _moyenne >= 10
                              ? AdminTheme.primaryLight
                              : AdminTheme.danger,
                        ),
                      ),
                      const Text(
                        '/20',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 10),
        ...rows,
      ],
    ),
  );

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _sectionNotes(Etudiant e) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            Text(
              'Moyenne : ${_moyenne.toStringAsFixed(2)}/20',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _moyenne >= 10 ? AdminTheme.success : AdminTheme.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...e.notes.map(
          (n) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    n['module'] ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Text(
                  '${n['note']}/20',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// DIALOGUE — INSCRIRE UN ÉTUDIANT
// ════════════════════════════════════════════════════════════════════════════
class _InscrireEtudiantDialog extends StatefulWidget {
  final VoidCallback onInscrit;
  const _InscrireEtudiantDialog({required this.onInscrit});

  @override
  State<_InscrireEtudiantDialog> createState() =>
      _InscrireEtudiantDialogState();
}

class _InscrireEtudiantDialogState extends State<_InscrireEtudiantDialog> {
  static const _niveaux = [
    'Licence 1',
    'Licence 2',
    'Licence 3',
    'Master 1',
    'Master 2',
  ];
  static const _filieresParDefaut = [
    'Réseaux Informatiques et Télécom',
    'Électrotechnique',
    'Marketing & Communication',
    'Gestion Comptable et Financière',
    'Génie Civil',
    'Finance Comptabilité',
  ];

  final _nomCtrl = TextEditingController();
  final _prenomsCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _matriculeCtrl = TextEditingController();

  // ── Champs tuteur / parent (optionnels) ─────────────────────────────────
  // Remplis => création/liaison automatique d'un compte parent côté backend
  // (voir etudiants.controller.js::creerOuLierParent). Le téléphone est la
  // clé utilisée pour détecter une fratrie (même tuteur, plusieurs enfants).
  final _nomParentCtrl = TextEditingController();
  final _prenomParentCtrl = TextEditingController();
  final _telParentCtrl = TextEditingController();
  final _emailParentCtrl = TextEditingController();

  List<String> _filieres = _filieresParDefaut;
  String? _filiereSelectionnee;
  String _niveauSelectionne = _niveaux.first;
  bool _chargementFilieres = true;
  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _chargerFilieres();
  }

  Future<void> _chargerFilieres() async {
    final result = await ApiService.getFilieres();
    if (result['success'] == true) {
      final data = result['data'] as List<dynamic>;
      if (data.isNotEmpty) {
        _filieres = data.map((f) => f['nom'] as String).toList();
      }
    }
    if (mounted) {
      setState(() {
        _filiereSelectionnee = _filieres.first;
        _chargementFilieres = false;
      });
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomsCtrl.dispose();
    _emailCtrl.dispose();
    _telephoneCtrl.dispose();
    _matriculeCtrl.dispose();
    _nomParentCtrl.dispose();
    _prenomParentCtrl.dispose();
    _telParentCtrl.dispose();
    _emailParentCtrl.dispose();
    super.dispose();
  }

  Future<void> _soumettre() async {
    final nom = _nomCtrl.text.trim();
    final prenoms = _prenomsCtrl.text.trim();

    if (nom.isEmpty || prenoms.isEmpty) {
      setState(() => _erreur = 'Nom et prénoms sont obligatoires.');
      return;
    }
    if (_filiereSelectionnee == null) {
      setState(() => _erreur = 'Veuillez sélectionner une filière.');
      return;
    }

    setState(() {
      _envoi = true;
      _erreur = null;
    });

    final result = await ApiService.inscrireEtudiant({
      'nom': nom,
      'prenoms': prenoms,
      'filiere': _filiereSelectionnee,
      'niveau': _niveauSelectionne,
      if (_emailCtrl.text.trim().isNotEmpty) 'email': _emailCtrl.text.trim(),
      if (_telephoneCtrl.text.trim().isNotEmpty)
        'telephone': _telephoneCtrl.text.trim(),
      if (_matriculeCtrl.text.trim().isNotEmpty)
        'matricule': _matriculeCtrl.text.trim(),
      if (_nomParentCtrl.text.trim().isNotEmpty)
        'nomParent': _nomParentCtrl.text.trim(),
      if (_prenomParentCtrl.text.trim().isNotEmpty)
        'prenomParent': _prenomParentCtrl.text.trim(),
      if (_telParentCtrl.text.trim().isNotEmpty)
        'telParent': _telParentCtrl.text.trim(),
      if (_emailParentCtrl.text.trim().isNotEmpty)
        'emailParent': _emailParentCtrl.text.trim(),
    });

    if (!mounted) return;

    if (result['success'] == true) {
      final mat = result['matricule']?.toString() ?? '';
      final notif = result['notifications'] is Map
          ? result['notifications'] as Map
          : const {};
      final smsOk = notif['sms'] is Map && notif['sms']['envoye'] == true;
      final emailOk = notif['email'] is Map && notif['email']['envoye'] == true;
      Navigator.pop(context);
      widget.onInscrit();
      _confirmationInscription(mat, smsOk, emailOk);
    } else {
      setState(() {
        _envoi = false;
        _erreur =
            result['error'] as String? ?? 'Erreur lors de l\'inscription.';
      });
    }
  }

  // Confirmation affichée à l'admin : matricule généré + état des notifications.
  void _confirmationInscription(String matricule, bool smsOk, bool emailOk) {
    final ctx = ScolarHubApp.navigatorKey.currentContext;
    if (ctx == null) return;
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF15803D)),
            SizedBox(width: 10),
            Text(
              'Étudiant inscrit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Matricule généré',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                matricule,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ligneNotif('SMS de confirmation', smsOk),
            const SizedBox(height: 8),
            _ligneNotif('Email de confirmation', emailOk),
            const SizedBox(height: 14),
            const Text(
              'L\'étudiant reçoit son matricule et un lien pour définir son mot de passe et confirmer son inscription.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.iconBgAlt,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Terminé'),
          ),
        ],
      ),
    );
  }

  Widget _ligneNotif(String label, bool ok) => Row(
    children: [
      Icon(
        ok ? Icons.check_circle_outline : Icons.cancel_outlined,
        size: 18,
        color: ok ? const Color(0xFF15803D) : const Color(0xFF94A3B8),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
      ),
      const Spacer(),
      Text(
        ok ? 'Envoyé' : 'Non envoyé',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: ok ? const Color(0xFF15803D) : const Color(0xFF94A3B8),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        constraints: const BoxConstraints(maxHeight: 680),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_add_rounded, color: AdminTheme.iconBgAlt),
                  SizedBox(width: 10),
                  Text(
                    'Inscrire un étudiant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _champ('Nom *', _nomCtrl)),
                  const SizedBox(width: 12),
                  Expanded(child: _champ('Prénoms *', _prenomsCtrl)),
                ],
              ),
              const SizedBox(height: 14),
              _chargementFilieres
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    )
                  : _dropdown(
                      'Filière *',
                      _filiereSelectionnee,
                      _filieres,
                      (v) => setState(() => _filiereSelectionnee = v),
                    ),
              const SizedBox(height: 14),
              _dropdown(
                'Niveau',
                _niveauSelectionne,
                _niveaux,
                (v) => setState(() => _niveauSelectionne = v!),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _champ('Email (optionnel)', _emailCtrl)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _champ('Téléphone (optionnel)', _telephoneCtrl),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _champ('Matricule (auto-généré si vide)', _matriculeCtrl),

              // ── Section tuteur / parent (optionnelle) ───────────────────
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Tuteur / Parent (optionnel)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Si rempli, un compte parent sera créé (ou lié s\'il existe déjà pour ce numéro).',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _champ('Nom du tuteur', _nomParentCtrl)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _champ('Prénom(s) du tuteur', _prenomParentCtrl),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _champ('Téléphone du tuteur', _telParentCtrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _champ('Email du tuteur', _emailParentCtrl),
                  ),
                ],
              ),

              if (_erreur != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AdminTheme.dangerLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _erreur!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AdminTheme.danger,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _envoi ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _envoi ? null : _soumettre,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.iconBgAlt,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _envoi
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Inscrire',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
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

  Widget _champ(String label, TextEditingController ctrl) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
        ),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
      ),
    ],
  );

  Widget _dropdown(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
        ),
      ),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        items: options
            .map(
              (o) => DropdownMenuItem(
                value: o,
                child: Text(o, style: const TextStyle(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    ],
  );
}
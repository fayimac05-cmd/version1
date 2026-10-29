import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/etudiant_model.dart';
import '../models/student_profile.dart';
import '../services/api_service.dart';
import '../services/api_extra.dart';
import '../app/scolar_hub_app.dart';
import '../config/etablissement_config.dart';
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
  int _nbEnAttente = 0;

  String _filtreStatut = 'tous';
  late String _filtredomaine;
  String _filtreNiveau = 'tous';
  String _filtreFiliere = 'toutes';
  String _recherche = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // ── Vue liste / pagination / carte d'étudiant ───────────────────────────
  Etudiant? _ficheEtudiant; // fiche détaillée affichée à la place de la liste
  String _filtreRegime = 'tous'; // 'tous' | 'jour' | 'soir'
  bool _modeInscription = false; // page « Inscrire un étudiant » affichée à la place de la liste
  String? _carteMatriculeAttente; // carte à ouvrir après rechargement (depuis l'inscription)
  String _vue = 'tableau'; // 'tableau' | 'grille'
  int _page = 0;
  static const int _parPage = 10;
  final Set<String> _coches = {}; // matricules cochés
  Etudiant? _carteSel; // étudiant affiché dans le panneau « Carte d'étudiant »
  bool _versoCarte = false;
  Uint8List? _photoCarte; // photo choisie à la main (uniquement pour le PDF)
  String? _photoCarteMat;
  // Nom du responsable : saisi librement (ce n'est pas toujours la même personne
  // qui fait les cartes), il n'est jamais rempli automatiquement.
  final TextEditingController _responsableCtrl = TextEditingController();
  final TextEditingController _anneeCtrl = TextEditingController(text: _anneeCourante());
  // Données complémentaires renvoyées par l'API (sexe, naissance, urgence, photo),
  // indexées par matricule — le modèle Etudiant n'a pas ces champs.
  final Map<String, Map<String, String>> _extras = {};

  String _x(Etudiant e, String k) => _extras[e.matricule]?[k] ?? '';

  _CarteInfos _infos(Etudiant e) => _CarteInfos(
    nom: e.nom,
    prenoms: e.prenoms,
    matricule: e.matricule,
    filiere: e.filiere,
    niveau: e.niveau,
    nationalite: _x(e, 'nationalite').isEmpty ? 'Burkinabè' : _x(e, 'nationalite'),
    sexe: _x(e, 'sexe'),
    naissance: _x(e, 'dateNaissance'),
    lieu: _x(e, 'lieuNaissance'),
    urgNom: _x(e, 'urgenceNom'),
    urgTel: _x(e, 'urgenceTel'),
    urgLien: _x(e, 'urgenceLien'),
    photoUrl: _x(e, 'photoUrl'),
  );

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
    if (_filtreRegime != 'tous' && (_x(e, 'regime').isEmpty ? 'jour' : _x(e, 'regime')) != _filtreRegime) {
      return false;
    }
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
    _responsableCtrl.dispose();
    _anneeCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerEtudiants({bool silencieux = false}) async {
    if (!silencieux) setState(() => _loading = true);
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
      // Champs complémentaires (sexe, naissance, personne à prévenir, photo) par matricule
      _extras.clear();
      for (final raw in data) {
        final m = Map<String, dynamic>.from(raw as Map);
        String g(String k) => (m[k] ?? '').toString();
        _extras[g('matricule')] = {
          'sexe': g('sexe'),
          'nationalite': g('nationalite'),
          'dateNaissance': g('dateNaissance'),
          'lieuNaissance': g('lieuNaissance'),
          'urgenceNom': g('urgenceNom'),
          'urgenceTel': g('urgenceTel'),
          'urgenceLien': g('urgenceLien'),
          'photoUrl': g('photoUrl'),
          'email': g('email'),
          'telephone': g('telephone'),
          'adresse': g('adresse'),
          'nomParent': g('nomParent'),
          'telParent': g('telParent'),
          'emailParent': g('emailParent'),
          'regime': g('regime').isEmpty ? 'jour' : g('regime'),
        };
      }
    } else {
      // ignore: avoid_print
      print('[AdminEtudiants] ERREUR chargement: ${result['error']}');
      adminEtudiants = [];
    }
    if (mounted) setState(() => _loading = false);
    final enAttente = _carteMatriculeAttente;
    if (enAttente != null && mounted) {
      _carteMatriculeAttente = null;
      for (final e in adminEtudiants) {
        if (e.matricule == enAttente) {
          _selectionnerCarte(e);
          break;
        }
      }
    }
    _chargerNbEnAttente();
  }

  // Nombre d'auto-inscriptions en attente de validation (pastille du bouton « Demandes »).
  Future<void> _chargerNbEnAttente() async {
    final r = await ApiService.getInscriptionsEnAttente();
    if (!mounted) return;
    if (r['success'] == true && r['data'] is List) {
      setState(() => _nbEnAttente = (r['data'] as List).length);
    }
  }

  void _ouvrirDemandes() {
    showDialog(
      context: context,
      builder: (_) => const _DemandesDialog(),
    ).then((_) {
      if (mounted) _chargerEtudiants();
    });
  }

  void _inscrireEtudiant() => setState(() => _modeInscription = true);

  @override
  Widget build(BuildContext context) {
    if (_modeInscription) {
      return _InscrireEtudiantPage(
        profile: widget.profile,
        onRetour: () => setState(() => _modeInscription = false),
        onInscrit: () {
          _chargerEtudiants();
          _snack('Étudiant inscrit avec succès.');
        },
        onCarte: (matricule) {
          _carteMatriculeAttente = matricule;
          setState(() => _modeInscription = false);
          _chargerEtudiants();
        },
      );
    }
    if (_ficheEtudiant != null) {
      final fe = _ficheEtudiant!;
      return _FichePage(
        key: ValueKey('fiche-${fe.matricule}'),
        etudiant: fe,
        extras: Map<String, String>.from(_extras[fe.matricule] ?? {}),
        onRetour: () => setState(() => _ficheEtudiant = null),
        onModifie: () => _chargerEtudiants(silencieux: true),
        onCarte: () {
          setState(() => _ficheEtudiant = null);
          _selectionnerCarte(fe);
        },
      );
    }
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
                            'Gestion des étudiants',
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
                  ],
                ),
                const SizedBox(height: 10),
                // Boutons d'action : retour à la ligne automatique sur petit écran.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 8,
                  children: [
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
                      onTap: _ouvrirDemandes,
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AdminTheme.primary),
                          ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.how_to_reg_outlined, color: AdminTheme.primary, size: 16),
                            const SizedBox(width: 6),
                            const Text('Demandes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AdminTheme.primary)),
                            if (_nbEnAttente > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(color: AdminTheme.danger, borderRadius: BorderRadius.circular(10)),
                                child: Text('$_nbEnAttente', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                              ),
                            ],
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
                // ── Onglet 1 : KPI + filtres + tableau/grille + carte ─────
                _ongletListe(),
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
  void _ouvrirFiche(Etudiant e) => setState(() => _ficheEtudiant = e);

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
      if (_filtreRegime != 'tous') (_filtreRegime == 'soir' ? 'Cours du soir' : 'Cours du jour'),
    ].join(' · ');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(EtablissementConfig.instance.nom.toUpperCase(), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
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
            headers: ['N°', 'Matricule', 'Nom', 'Prénoms', 'Filière', 'Niveau', 'Régime', 'Statut'],
            data: liste.asMap().entries.map((entry) => [
              '${entry.key + 1}',
              entry.value.matricule,
              entry.value.nom,
              entry.value.prenoms,
              entry.value.filiere,
              entry.value.niveau,
              _x(entry.value, 'regime') == 'soir' ? 'Soir' : 'Jour',
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
  // ONGLET « TOUS » — KPI, filtres, tableau/grille, panneau carte
  // ════════════════════════════════════════════════════════════════════════
  Widget _ongletListe() {
    final data = liste;
    final nbPages = data.isEmpty ? 1 : ((data.length + _parPage - 1) ~/ _parPage);
    if (_page >= nbPages) _page = nbPages - 1;
    final debut = _page * _parPage;
    final fin = (debut + _parPage) > data.length ? data.length : debut + _parPage;
    final visibles = data.sublist(debut, fin);
    final largeur = MediaQuery.of(context).size.width;
    final avecPanneau = largeur >= 1180;

    final principal = SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 20 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kpis(),
          const SizedBox(height: 16),
          _barreFiltres(),
          const SizedBox(height: 12),
          if (_coches.isNotEmpty) _barreSelection(),
          if (data.isEmpty)
            SizedBox(height: 260, child: _vide())
          else if (_vue == 'grille')
            _grille(visibles)
          else
            _tableau(visibles),
          const SizedBox(height: 12),
          _pagination(data.length, debut, fin, nbPages),
        ],
      ),
    );

    if (!avecPanneau) return principal;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: principal),
        Container(
          width: 360,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _panneauCarte(),
          ),
        ),
      ],
    );
  }

  String get _anneeAffichee => _anneeCtrl.text.trim().isEmpty ? _anneeCourante() : _anneeCtrl.text.trim();

  Widget _kpis() {
    final filieres = adminEtudiants.map((e) => e.filiere).where((f) => f.isNotEmpty).toSet().length;
    final niveaux = adminEtudiants.map((e) => e.niveau).where((f) => f.isNotEmpty).toSet().length;
    final actifs = adminEtudiants.where((e) => e.statut == 'actif').length;
    final soir = adminEtudiants.where((e) => _x(e, 'regime') == 'soir').length;
    return LayoutBuilder(
      builder: (_, c) {
        final cols = c.maxWidth >= 760 ? 4 : 2;
        final w = (c.maxWidth - (cols - 1) * 12) / cols;
        Widget k(IconData ic, Color fg, Color bg, String label, String val, String sub) => SizedBox(
          width: w,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(ic, color: fg, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis),
                      Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)), overflow: TextOverflow.ellipsis),
                      Text(sub, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            k(Icons.groups_rounded, AdminTheme.primary, AdminTheme.primaryLight, 'Total étudiants', '${adminEtudiants.length}', '$actifs inscrit(s) · $soir du soir'),
            k(Icons.menu_book_rounded, AdminTheme.success, AdminTheme.successLight, 'Filières', '$filieres', 'au total'),
            k(Icons.layers_rounded, AdminTheme.warning, AdminTheme.warningLight, 'Niveaux', '$niveaux', 'au total'),
            k(Icons.calendar_month_rounded, AdminTheme.info, AdminTheme.infoLight, 'Année académique', _anneeAffichee, 'en cours'),
          ],
        );
      },
    );
  }

  Widget _barreFiltres() {
    final niveaux = adminEtudiants.map((e) => e.niveau).where((n) => n.isNotEmpty).toSet().toList()..sort();
    Widget filtre(String h, String v, List<String> vals, List<String> labels, ValueChanged<String?> f) =>
        _filtreDropdown(h, vals.contains(v) ? v : vals.first, vals, labels, (x) {
          f(x);
          setState(() => _page = 0);
        });
    final recherche = _searchBar();
    final fFiliere = filtre('Filière', _filtreFiliere, ['toutes', ..._filieresDisponibles], ['Filière : toutes', ..._filieresDisponibles], (v) => _filtreFiliere = v!);
    final fNiveau = filtre('Niveau', _filtreNiveau, ['tous', ...niveaux], ['Niveau : tous', ...niveaux], (v) => _filtreNiveau = v!);
    final fRegime = filtre('Régime', _filtreRegime, ['tous', 'jour', 'soir'], ['Cours : tous', 'Cours du jour', 'Cours du soir'], (v) => _filtreRegime = v!);
    final fStatut = filtre('Statut', _filtreStatut, ['tous', 'actif', 'suspendu', 'renvoye'], ['Statut : tous', 'Inscrit', 'Suspendu', 'Renvoyé'], (v) => _filtreStatut = v!);
    final bascule = Container(
      height: 40,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _boutonVue('Grille', Icons.grid_view_rounded, 'grille'),
          _boutonVue('Tableau', Icons.table_rows_rounded, 'tableau'),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (_, c) {
        if (c.maxWidth >= 900) {
          return Row(
            children: [
              Expanded(flex: 3, child: recherche),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: fFiliere),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: fNiveau),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: fStatut),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: fRegime),
              const SizedBox(width: 10),
              bascule,
            ],
          );
        }
        return Column(
          children: [
            recherche,
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: fFiliere),
              const SizedBox(width: 8),
              Expanded(child: fNiveau),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: fStatut),
              const SizedBox(width: 8),
              Expanded(child: fRegime),
            ]),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: bascule),
          ],
        );
      },
    );
  }

  Widget _boutonVue(String label, IconData ic, String valeur) {
    final actif = _vue == valeur;
    return GestureDetector(
      onTap: () => setState(() => _vue = valeur),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: actif ? AdminTheme.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(ic, size: 16, color: actif ? AdminTheme.primary : const Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: actif ? AdminTheme.primary : const Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }

  Widget _barreSelection() {
    final sel = adminEtudiants.where((e) => _coches.contains(e.matricule)).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Text('${sel.length} sélectionné(s)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AdminTheme.primary)),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _telechargerCartes(sel),
            icon: const Icon(Icons.badge_outlined, size: 16),
            label: const Text('Cartes (PDF)'),
          ),
          TextButton(onPressed: () => setState(_coches.clear), child: const Text('Désélectionner')),
        ],
      ),
    );
  }

  // ── Pastilles ───────────────────────────────────────────────────────────
  Widget _badgeSexe(String s) {
    if (s != 'M' && s != 'F') return const Text('—', style: TextStyle(color: Color(0xFF9CA3AF)));
    final h = s == 'M';
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: h ? AdminTheme.infoLight : const Color(0xFFFCE7F3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(h ? 'H' : 'F', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: h ? AdminTheme.info : const Color(0xFFDB2777))),
    );
  }

  Widget _badgeRegime(String r) {
    final soir = r == 'soir';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: soir ? const Color(0xFFEDE9FE) : const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(20)),
      child: Text(soir ? 'Soir' : 'Jour', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: soir ? const Color(0xFF6D28D9) : const Color(0xFF2563EB))),
    );
  }

  Widget _badgeStatut(String statut) {
    final Color fg;
    final Color bg;
    final String label;
    switch (statut) {
      case 'actif':
        fg = AdminTheme.success; bg = AdminTheme.successLight; label = 'Inscrit';
        break;
      case 'suspendu':
        fg = AdminTheme.warning; bg = AdminTheme.warningLight; label = 'Suspendu';
        break;
      case 'renvoye':
        fg = AdminTheme.danger; bg = AdminTheme.dangerLight; label = 'Renvoyé';
        break;
      default:
        fg = AdminTheme.warning; bg = AdminTheme.warningLight; label = 'En attente';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _avatar(Etudiant e, double taille) {
    final url = _x(e, 'photoUrl');
    final ini = (e.prenoms.isNotEmpty ? e.prenoms[0] : '') + (e.nom.isNotEmpty ? e.nom[0] : '');
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        color: AdminTheme.iconBg,
        shape: BoxShape.circle,
        image: url.isNotEmpty ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
      ),
      child: url.isEmpty
          ? Center(child: Text(ini.toUpperCase(), style: TextStyle(fontSize: taille * 0.34, fontWeight: FontWeight.bold, color: AdminTheme.iconFg)))
          : null,
    );
  }

  // ── Tableau ─────────────────────────────────────────────────────────────
  Widget _tableau(List<Etudiant> lignes) {
    final toutesCochees = lignes.isNotEmpty && lignes.every((e) => _coches.contains(e.matricule));
    Widget th(String t, {int flex = 1, double? w}) {
      final child = Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)));
      return w != null ? SizedBox(width: w, child: child) : Expanded(flex: flex, child: child);
    }

    return LayoutBuilder(
      builder: (_, c) {
        final largeurMin = c.maxWidth < 1000 ? 1000.0 : c.maxWidth;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: largeurMin,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFF9FAFB),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Checkbox(
                              value: toutesCochees,
                              onChanged: (v) => setState(() {
                                for (final e in lignes) {
                                  if (v == true) {
                                    _coches.add(e.matricule);
                                  } else {
                                    _coches.remove(e.matricule);
                                  }
                                }
                              }),
                            ),
                          ),
                          th('Photo', w: 52),
                          th('Matricule', flex: 2),
                          th('Nom & Prénoms', flex: 4),
                          th('Filière', flex: 3),
                          th('Niveau', flex: 2),
                          th('Régime', w: 76),
                          th('Sexe', w: 56),
                          th('Nationalité', flex: 2),
                          th('Statut', w: 100),
                          th('Actions', w: 92),
                        ],
                      ),
                    ),
                    for (final e in lignes) _ligneTableau(e),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _ligneTableau(Etudiant e) {
    final choisi = _carteSel?.matricule == e.matricule;
    const st = TextStyle(fontSize: 13, color: Color(0xFF1A1A2E));
    return InkWell(
      onTap: () => _ouvrirFiche(e),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: choisi ? AdminTheme.primaryLight.withValues(alpha: 0.5) : Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Checkbox(
                value: _coches.contains(e.matricule),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _coches.add(e.matricule);
                  } else {
                    _coches.remove(e.matricule);
                  }
                }),
              ),
            ),
            SizedBox(width: 52, child: Align(alignment: Alignment.centerLeft, child: _avatar(e, 36))),
            Expanded(flex: 2, child: Text(e.matricule, style: st.copyWith(fontFamily: 'monospace', fontSize: 12), overflow: TextOverflow.ellipsis)),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Flexible(child: Text('${e.nom} ${e.prenoms}', style: st.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  DelegueBadge(role: e.role, niveau: e.niveau, compact: true),
                ],
              ),
            ),
            Expanded(flex: 3, child: Text(e.filiere, style: st, overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2, child: Text(e.niveau, style: st, overflow: TextOverflow.ellipsis)),
            SizedBox(width: 76, child: Align(alignment: Alignment.centerLeft, child: _badgeRegime(_x(e, 'regime')))),
            SizedBox(width: 56, child: Align(alignment: Alignment.centerLeft, child: _badgeSexe(_x(e, 'sexe')))),
            Expanded(flex: 2, child: Text(_x(e, 'nationalite').isEmpty ? 'Burkinabè' : _x(e, 'nationalite'), style: st, overflow: TextOverflow.ellipsis)),
            SizedBox(width: 100, child: Align(alignment: Alignment.centerLeft, child: _badgeStatut(e.statut))),
            SizedBox(
              width: 92,
              child: Row(
                children: [
                  IconButton(
                    tooltip: "Carte d'étudiant",
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.badge_outlined, size: 20, color: Color(0xFF2563EB)),
                    onPressed: () => _selectionnerCarte(e),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF6B7280)),
                    onPressed: () => _menuActions(e),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Grille ──────────────────────────────────────────────────────────────
  Widget _grille(List<Etudiant> lignes) {
    return LayoutBuilder(
      builder: (_, c) {
        final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 620 ? 2 : 1);
        final w = (c.maxWidth - (cols - 1) * 12) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final e in lignes)
              SizedBox(
                width: w,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _ouvrirFiche(e),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _carteSel?.matricule == e.matricule ? AdminTheme.primary : const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        _avatar(e, 52),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${e.nom} ${e.prenoms}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                              Text(e.matricule, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontFamily: 'monospace')),
                              Text('${e.filiere} · ${e.niveau}', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Wrap(spacing: 6, runSpacing: 4, children: [_badgeSexe(_x(e, 'sexe')), _badgeRegime(_x(e, 'regime')), _badgeStatut(e.statut)]),
                            ],
                          ),
                        ),
                        Column(children: [
                          IconButton(tooltip: "Carte d'étudiant", icon: const Icon(Icons.badge_outlined, size: 20, color: Color(0xFF2563EB)), onPressed: () => _selectionnerCarte(e)),
                          IconButton(icon: const Icon(Icons.more_horiz_rounded), onPressed: () => _menuActions(e)),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── Pagination ──────────────────────────────────────────────────────────
  Widget _pagination(int total, int debut, int fin, int nbPages) {
    Widget bouton(String t, int p, {bool actif = false}) => GestureDetector(
      onTap: () => setState(() => _page = p),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(left: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: actif ? AdminTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: actif ? AdminTheme.primary : const Color(0xFFE5E7EB)),
        ),
        child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: actif ? Colors.white : const Color(0xFF374151))),
      ),
    );
    final pages = <Widget>[];
    // Fenêtre de 5 pages autour de la page courante
    int d = _page - 2 < 0 ? 0 : _page - 2;
    int f = d + 4 >= nbPages ? nbPages - 1 : d + 4;
    d = f - 4 < 0 ? 0 : f - 4;
    for (int p = d; p <= f; p++) {
      pages.add(bouton('${p + 1}', p, actif: p == _page));
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            total == 0 ? 'Aucun résultat' : 'Affichage de ${debut + 1} à $fin sur $total étudiants',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ),
        if (_page > 0) bouton('‹', _page - 1),
        ...pages,
        if (_page < nbPages - 1) bouton('›', _page + 1),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // CARTE D'ÉTUDIANT — panneau, aperçu, PDF recto/verso
  // ════════════════════════════════════════════════════════════════════════
  void _selectionnerCarte(Etudiant e) {
    final largeur = MediaQuery.of(context).size.width;
    setState(() {
      _carteSel = e;
      _versoCarte = false;
    });
    if (largeur < 1180) _ouvrirCarte(e);
  }

  /// Écran étroit : le panneau s'ouvre dans une boîte de dialogue.
  void _ouvrirCarte(Etudiant e) {
    setState(() {
      _carteSel = e;
      _versoCarte = false;
    });
    if (MediaQuery.of(context).size.width >= 1180) return; // panneau déjà visible
    showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setD) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _panneauCarte(rafraichir: () {
                setD(() {});
                setState(() {});
              }, fermer: () => Navigator.pop(dctx)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _panneauCarte({VoidCallback? rafraichir, VoidCallback? fermer}) {
    void maj(VoidCallback f) {
      setState(f);
      rafraichir?.call();
    }

    final e = _carteSel;
    final titre = Row(
      children: [
        const Expanded(
          child: Text("Carte d'étudiant", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        ),
        if (fermer != null) IconButton(onPressed: fermer, icon: const Icon(Icons.close_rounded)),
      ],
    );
    if (e == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titre,
          const SizedBox(height: 40),
          Icon(Icons.badge_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text("Sélectionnez un étudiant dans la liste pour prévisualiser et imprimer sa carte.",
              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
        ],
      );
    }
    final inf = _infos(e);
    final manque = inf.sexe.isEmpty || inf.naissance.isEmpty || inf.urgNom.isEmpty;
    Widget onglet(String t, bool verso) {
      final actif = _versoCarte == verso;
      return Expanded(
        child: GestureDetector(
          onTap: () => maj(() => _versoCarte = verso),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: actif ? AdminTheme.primaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: actif ? AdminTheme.primary : const Color(0xFF6B7280))),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titre,
        Text('${e.prenoms} ${e.nom}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [onglet('Recto', false), onglet('Verso', true)]),
        ),
        const SizedBox(height: 12),
        _ApercuCarte(
          infos: inf,
          photoBytes: _photoCarteMat == e.matricule ? _photoCarte : null,
          responsable: _responsableCtrl.text.trim(),
          annee: _anneeAffichee,
          verso: _versoCarte,
        ),
        const SizedBox(height: 14),
        const Text('Nom et prénom du responsable (signature)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        const SizedBox(height: 6),
        _champCourt(_responsableCtrl, 'À remplir (laisser vide pour l\'écrire à la main)', (_) => maj(() {})),
        const SizedBox(height: 10),
        const Text('Année académique', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        const SizedBox(height: 6),
        _champCourt(_anneeCtrl, '2026 - 2027', (_) => maj(() {})),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _choisirPhotoCarte(e);
                  rafraichir?.call();
                },
                icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                label: Text(_photoCarteMat == e.matricule ? 'Changer la photo' : 'Photo pour la carte', style: const TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _completerIdentite(e);
                  rafraichir?.call();
                },
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Identité', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
        if (manque)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Sexe, date de naissance ou personne à prévenir non renseignés — cliquez sur « Identité » pour les compléter.',
              style: TextStyle(fontSize: 11, color: AdminTheme.warning),
            ),
          ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _telechargerCartes([e]),
                icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                label: const Text('Télécharger PDF', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, padding: const EdgeInsets.symmetric(vertical: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _imprimerCartes([e]),
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Imprimer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _champCourt(TextEditingController c, String hint, ValueChanged<String> onChanged) => TextField(
    controller: c,
    onChanged: onChanged,
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    ),
  );

  /// Photo utilisée UNIQUEMENT pour le PDF de cette carte (jamais envoyée au serveur).
  Future<void> _choisirPhotoCarte(Etudiant e) async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photoCarte = bytes;
        _photoCarteMat = e.matricule;
      });
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Impossible de charger cette image.');
    }
  }

  Future<void> _completerIdentite(Etudiant e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _IdentiteDialog(
        etudiant: e,
        initial: Map<String, String>.from(_extras[e.matricule] ?? {}),
        onSaved: (m) => _extras[e.matricule] = {...(_extras[e.matricule] ?? {}), ...m},
      ),
    );
    if (ok == true && mounted) {
      setState(() {});
      _snack('Identité mise à jour.');
    }
  }

  Future<void> _telechargerCartes(List<Etudiant> cibles) async {
    if (cibles.isEmpty) return;
    try {
      final bytes = await _construirePdfCartes(cibles);
      final nom = cibles.length == 1 ? 'Carte_${cibles.first.nom}_${cibles.first.prenoms}.pdf' : 'Cartes_etudiants.pdf';
      await Printing.sharePdf(bytes: bytes, filename: nom);
    } catch (err) {
      if (mounted) _snack('Génération du PDF impossible : $err');
    }
  }

  Future<void> _imprimerCartes(List<Etudiant> cibles) async {
    if (cibles.isEmpty) return;
    try {
      await Printing.layoutPdf(
        onLayout: (_) => _construirePdfCartes(cibles),
        name: cibles.length == 1 ? 'Carte_${cibles.first.nom}_${cibles.first.prenoms}.pdf' : 'Cartes_etudiants.pdf',
      );
    } catch (err) {
      if (mounted) _snack('Impression impossible : $err');
    }
  }

  static const PdfPageFormat _formatCarte = PdfPageFormat(85.6 * PdfPageFormat.mm, 54 * PdfPageFormat.mm);

  Future<Uint8List> _construirePdfCartes(List<Etudiant> cibles) async {
    final pdf = pw.Document();
    final resp = _responsableCtrl.text.trim();
    final annee = _anneeAffichee;
    for (final e in cibles) {
      final inf = _infos(e);
      pw.ImageProvider? photo;
      if (_photoCarte != null && _photoCarteMat == e.matricule) {
        photo = pw.MemoryImage(_photoCarte!);
      } else if (inf.photoUrl.isNotEmpty) {
        try {
          photo = await networkImage(inf.photoUrl);
        } catch (_) {
          photo = null; // photo injoignable : initiales à la place
        }
      }
      pdf.addPage(_pageRecto(inf, photo, resp, annee));
      pdf.addPage(_pageVerso(inf, annee));
    }
    return pdf.save();
  }

  pw.Page _pageRecto(_CarteInfos i, pw.ImageProvider? photo, String resp, String annee) {
    const vert = PdfColor.fromInt(0xFF1A3C34);
    final ecole = EtablissementConfig.instance.nom;
    pw.Widget ligne(String l, String v) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2.2),
      child: pw.RichText(
        text: pw.TextSpan(children: [
          pw.TextSpan(text: '$l : ', style: const pw.TextStyle(fontSize: 5.2, color: PdfColors.grey700)),
          pw.TextSpan(text: v, style: pw.TextStyle(fontSize: 6.4, fontWeight: pw.FontWeight.bold)),
        ]),
      ),
    );
    final ini = ((i.prenoms.isNotEmpty ? i.prenoms[0] : '') + (i.nom.isNotEmpty ? i.nom[0] : '')).toUpperCase();
    final sexeTxt = i.sexe == 'M' ? 'Masculin' : (i.sexe == 'F' ? 'Féminin' : '');
    return pw.Page(
      pageFormat: _formatCarte,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Container(
        color: PdfColors.white,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              height: 24,
              color: vert,
              padding: const pw.EdgeInsets.symmetric(horizontal: 8),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 16,
                    height: 16,
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFD8F3DC), borderRadius: pw.BorderRadius.all(pw.Radius.circular(3))),
                    child: pw.Center(child: pw.Text(ecole.isNotEmpty ? ecole[0].toUpperCase() : 'S', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: vert))),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(ecole.toUpperCase(), maxLines: 1, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                        pw.Text("CARTE D'ÉTUDIANT", style: const pw.TextStyle(fontSize: 5, color: PdfColors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(8, 5, 8, 0),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          ligne('Nom', i.nom.toUpperCase()),
                          ligne('Prénoms', i.prenoms),
                          ligne('Né(e) le', '${_fmtDate(i.naissance).isEmpty ? '..........' : _fmtDate(i.naissance)}${i.lieu.isNotEmpty ? ' à ${i.lieu}' : ''}'),
                          ligne('Nationalité', i.nationalite),
                          ligne('Sexe', sexeTxt.isEmpty ? '..........' : sexeTxt),
                          ligne('Matricule', i.matricule),
                          ligne('Filière', i.filiere),
                          ligne('Niveau', i.niveau),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Container(
                      width: 42,
                      height: 52,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
                        image: photo != null ? pw.DecorationImage(image: photo, fit: pw.BoxFit.cover) : null,
                      ),
                      child: photo == null
                          ? pw.Center(child: pw.Text(ini, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)))
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            pw.Container(
              height: 34,
              padding: const pw.EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text("Signature de l'étudiant", style: const pw.TextStyle(fontSize: 4.8, color: PdfColors.grey700)),
                        pw.SizedBox(height: 12),
                        pw.Container(height: 0.5, color: PdfColors.grey500),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('Le responsable', style: const pw.TextStyle(fontSize: 4.8, color: PdfColors.grey700)),
                        pw.SizedBox(height: 8),
                        pw.Container(height: 0.5, color: PdfColors.grey500),
                        pw.SizedBox(height: 1.5),
                        pw.Text('Nom et Prénom : ${resp.isEmpty ? '.................................' : resp}', maxLines: 1, style: const pw.TextStyle(fontSize: 4.8)),
                        pw.Text('Année académique : $annee', style: pw.TextStyle(fontSize: 4.8, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Page _pageVerso(_CarteInfos i, String annee) {
    const vert = PdfColor.fromInt(0xFF1A3C34);
    final ecole = EtablissementConfig.instance.nom;
    pw.Widget val(String t, double size, {bool gras = false}) =>
        pw.Text(t.isEmpty ? '...............................' : t, style: pw.TextStyle(fontSize: size, fontWeight: gras ? pw.FontWeight.bold : pw.FontWeight.normal));
    return pw.Page(
      pageFormat: _formatCarte,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Container(
        color: PdfColors.white,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              height: 20,
              color: vert,
              alignment: pw.Alignment.centerLeft,
              padding: const pw.EdgeInsets.symmetric(horizontal: 8),
              child: pw.Text('EN CAS DE BESOIN, PRÉVENIR', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            ),
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Nom et prénom', style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey700)),
                          val(i.urgNom, 8.5, gras: true),
                          pw.SizedBox(height: 5),
                          pw.Text('Lien avec l\'étudiant', style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey700)),
                          val(i.urgLien, 7),
                          pw.SizedBox(height: 5),
                          pw.Text('Téléphone', style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey700)),
                          val(i.urgTel, 9, gras: true),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: 'ScholARHub|${i.matricule}|${i.nom}|${i.prenoms}',
                      width: 46,
                      height: 46,
                    ),
                  ],
                ),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.fromLTRB(10, 0, 10, 6),
              child: pw.Text(
                'Cette carte est strictement personnelle et valable pour l\'année académique $annee. En cas de perte ou de découverte, merci de la rapporter à : $ecole.',
                style: const pw.TextStyle(fontSize: 4.6, color: PdfColors.grey700),
              ),
            ),
          ],
        ),
      ),
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
              title: const Text("Carte d'étudiant"),
              onTap: () {
                Navigator.pop(context);
                _ouvrirCarte(e);
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
            ListTile(
              leading: const Icon(Icons.lock_reset_rounded, color: AdminTheme.iconBg),
              title: const Text('Réinitialiser le mot de passe'),
              onTap: () {
                Navigator.pop(context);
                _reinitialiserMdp(e);
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

  // Efface le mot de passe : l'étudiant en choisira un nouveau à sa prochaine connexion
  // (utile s'il n'a pas d'email, donc pas de « Mot de passe oublié » possible).
  Future<void> _reinitialiserMdp(Etudiant e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe ?'),
        content: Text('${e.prenoms} ${e.nom} pourra choisir un nouveau mot de passe à sa prochaine '
            'connexion, avec son matricule. Son ancien mot de passe ne fonctionnera plus.\n\n'
            'Faites-le quand l\'étudiant est prêt à se connecter : tant qu\'il n\'a pas choisi son mot de passe, '
            'le compte peut être activé par quiconque connaît son matricule.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Réinitialiser')),
        ],
      ),
    );
    if (ok != true) return;
    final res = await ApiExtra.reinitialiserMotDePasseEtudiant(e.id);
    if (!mounted) return;
    _snack(res['success'] == true
        ? 'Mot de passe de ${e.prenoms} réinitialisé.'
        : (res['error']?.toString() ?? 'Réinitialisation impossible.'));
  }

  void _snack(String msg) => showAppSnackBar(context, msg);
}

// ════════════════════════════════════════════════════════════════════════════
// FICHE ÉTUDIANT (toutes les informations d'inscription + modification)
// ════════════════════════════════════════════════════════════════════════════
class _FichePage extends StatefulWidget {
  final Etudiant etudiant;
  final Map<String, String> extras;
  final VoidCallback onRetour;
  final VoidCallback onModifie; // recharge la liste après enregistrement
  final VoidCallback onCarte;
  const _FichePage({
    super.key,
    required this.etudiant,
    required this.extras,
    required this.onRetour,
    required this.onModifie,
    required this.onCarte,
  });

  @override
  State<_FichePage> createState() => _FichePageState();
}

class _FichePageState extends State<_FichePage> {
  static const _niveaux = ['Licence 1', 'Licence 2', 'Licence 3', 'Master 1', 'Master 2'];
  static const _nationalites = [
    'Burkinabè', 'Ivoirienne', 'Malienne', 'Nigérienne', 'Togolaise', 'Béninoise',
    'Ghanéenne', 'Sénégalaise', 'Guinéenne', 'Nigériane', 'Camerounaise', 'Autre',
  ];
  static const _bleu = Color(0xFF2563EB);

  bool _edition = false;
  bool _envoi = false;
  String? _erreur;
  List<String> _filieres = [];
  List<dynamic> _documents = [];

  late Map<String, String> _m; // valeurs affichées (copie locale)
  final Map<String, TextEditingController> _c = {};
  String _sexe = '';
  String _regime = 'jour';
  String _niveau = '';
  String _filiere = '';
  String _nationalite = 'Burkinabè';
  String _dateNaissance = '';

  static const _champsTexte = [
    'nom', 'prenoms', 'lieuNaissance', 'email', 'telephone', 'adresse',
    'urgenceNom', 'urgenceTel', 'urgenceLien', 'nomParent', 'telParent', 'emailParent', 'natAutre',
  ];

  Etudiant get e => widget.etudiant;

  @override
  void initState() {
    super.initState();
    _m = Map<String, String>.from(widget.extras);
    _m['nom'] = e.nom;
    _m['prenoms'] = e.prenoms;
    _m['filiere'] = e.filiere;
    _m['niveau'] = e.niveau;
    for (final k in _champsTexte) {
      _c[k] = TextEditingController();
    }
    _chargerComplements();
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _chargerComplements() async {
    final f = await ApiService.getFilieres();
    if (f['success'] == true) {
      _filieres = (f['data'] as List<dynamic>)
          .map((x) => (x['nom'] ?? '').toString().trim())
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList();
    }
    try {
      final headers = await ApiService.getHeaders();
      final r = await http.get(Uri.parse('${ApiService.baseUrl}/etudiants/${e.id}/documents'), headers: headers);
      if (r.statusCode == 200) {
        final body = jsonDecode(utf8.decode(r.bodyBytes));
        if (body is Map && body['data'] is List) _documents = body['data'] as List<dynamic>;
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  void _demarrerEdition() {
    final nat = (_m['nationalite'] ?? '').isEmpty ? 'Burkinabè' : _m['nationalite']!;
    final dansListe = _nationalites.contains(nat);
    _c['nom']!.text = _m['nom'] ?? '';
    _c['prenoms']!.text = _m['prenoms'] ?? '';
    _c['lieuNaissance']!.text = _m['lieuNaissance'] ?? '';
    _c['email']!.text = (_m['email'] ?? '').endsWith('@sans-email.scolarhub') ? '' : (_m['email'] ?? '');
    _c['telephone']!.text = _m['telephone'] ?? '';
    _c['adresse']!.text = _m['adresse'] ?? '';
    _c['urgenceNom']!.text = _m['urgenceNom'] ?? '';
    _c['urgenceTel']!.text = _m['urgenceTel'] ?? '';
    _c['urgenceLien']!.text = _m['urgenceLien'] ?? '';
    _c['nomParent']!.text = _m['nomParent'] ?? '';
    _c['telParent']!.text = _m['telParent'] ?? '';
    _c['emailParent']!.text = _m['emailParent'] ?? '';
    _c['natAutre']!.text = dansListe ? '' : nat;
    _nationalite = dansListe ? nat : 'Autre';
    _sexe = _m['sexe'] ?? '';
    _regime = _m['regime'] == 'soir' ? 'soir' : 'jour';
    _niveau = _m['niveau'] ?? '';
    _filiere = _m['filiere'] ?? '';
    final d = _m['dateNaissance'] ?? '';
    _dateNaissance = (d.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(d)) ? d.substring(0, 10) : '';
    setState(() { _edition = true; _erreur = null; });
  }

  Future<void> _choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateNaissance) ?? DateTime(2003, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(() => _dateNaissance =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _enregistrer() async {
    String t(String k) => _c[k]!.text.trim();
    if (t('nom').isEmpty || t('prenoms').isEmpty) {
      setState(() => _erreur = 'Nom et prénoms sont obligatoires.');
      return;
    }
    final nat = _nationalite == 'Autre' ? t('natAutre') : _nationalite;
    final body = <String, dynamic>{
      'nom': t('nom'),
      'prenoms': t('prenoms'),
      'sexe': _sexe,
      'regime': _regime,
      'nationalite': nat,
      'dateNaissance': _dateNaissance,
      'lieuNaissance': t('lieuNaissance'),
      'niveau': _niveau,
      if (_filiere.isNotEmpty) 'filiere': _filiere,
      'telephone': t('telephone'),
      'adresse': t('adresse'),
      if (t('email').isNotEmpty) 'email': t('email'),
      'urgenceNom': t('urgenceNom'),
      'urgenceTel': t('urgenceTel'),
      'urgenceLien': t('urgenceLien'),
      'nomParent': t('nomParent'),
      'telParent': t('telParent'),
      'emailParent': t('emailParent'),
    };
    setState(() { _envoi = true; _erreur = null; });
    try {
      final headers = await ApiService.getHeaders();
      final r = await http.put(
        Uri.parse('${ApiService.baseUrl}/etudiants/${e.id}'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (r.statusCode >= 200 && r.statusCode < 300) {
        // Met à jour l'affichage local puis recharge la liste en arrière-plan
        _m = {
          ..._m,
          'nom': t('nom').toUpperCase(),
          'prenoms': t('prenoms'),
          'sexe': _sexe,
          'regime': _regime,
          'nationalite': nat.isEmpty ? 'Burkinabè' : nat,
          'dateNaissance': _dateNaissance,
          'lieuNaissance': t('lieuNaissance'),
          'niveau': _niveau,
          'filiere': _filiere.isNotEmpty ? _filiere : (_m['filiere'] ?? ''),
          'telephone': t('telephone'),
          'adresse': t('adresse'),
          if (t('email').isNotEmpty) 'email': t('email'),
          'urgenceNom': t('urgenceNom'),
          'urgenceTel': t('urgenceTel'),
          'urgenceLien': t('urgenceLien'),
          'nomParent': t('nomParent'),
          'telParent': t('telParent'),
          'emailParent': t('emailParent'),
        };
        widget.onModifie();
        if (mounted) setState(() { _edition = false; _envoi = false; });
        if (mounted) showAppSnackBar(context, 'Informations mises à jour.');
      } else {
        String msg = 'Erreur ${r.statusCode}';
        try { msg = (jsonDecode(r.body)['message'] ?? msg).toString(); } catch (_) {}
        if (mounted) setState(() { _envoi = false; _erreur = msg; });
      }
    } catch (err) {
      if (mounted) setState(() { _envoi = false; _erreur = 'Connexion impossible : $err'; });
    }
  }

  // ── Widgets ───────────────────────────────────────────────────────────
  Widget _carte(IconData ic, String titre, List<Widget> enfants) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(color: _bleu, shape: BoxShape.circle),
            child: Icon(ic, size: 15, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(titre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
        ]),
        const SizedBox(height: 12),
        ...enfants,
      ],
    ),
  );

  Widget _ligne(String label, String valeur) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 150, child: Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)))),
        Expanded(child: Text(valeur.isEmpty ? '—' : valeur, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)))),
      ],
    ),
  );

  Widget _in(String label, String cle, {TextInputType? type}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        const SizedBox(height: 5),
        TextField(
          controller: _c[cle],
          keyboardType: type,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
          ),
        ),
      ],
    ),
  );

  Widget _sel(String label, String valeur, List<String> items, ValueChanged<String?> on, {String Function(String)? aff}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        const SizedBox(height: 5),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFD1D5DB))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(valeur) ? valeur : null,
              isExpanded: true,
              hint: const Text('Sélectionner', style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF))),
              style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
              items: [for (final i in items) DropdownMenuItem(value: i, child: Text(aff != null ? aff(i) : i, overflow: TextOverflow.ellipsis))],
              onChanged: on,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _cols(List<Widget> ws) => LayoutBuilder(
    builder: (_, c) {
      if (c.maxWidth < 520) return Column(children: ws);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (int i = 0; i < ws.length; i++) ...[if (i > 0) const SizedBox(width: 14), Expanded(child: ws[i])]],
      );
    },
  );

  Widget _badge(String t, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(t, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
  );

  String _v(String k) => _m[k] ?? '';

  @override
  Widget build(BuildContext context) {
    final url = _v('photoUrl');
    final ini = ((_v('prenoms').isNotEmpty ? _v('prenoms')[0] : '') + (_v('nom').isNotEmpty ? _v('nom')[0] : '')).toUpperCase();
    final soir = _v('regime') == 'soir';
    final sexeTxt = _v('sexe') == 'M' ? 'Masculin' : (_v('sexe') == 'F' ? 'Féminin' : '');
    final emailAff = _v('email').endsWith('@sans-email.scolarhub') ? '' : _v('email');
    final statut = e.statut;

    final entete = Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              shape: BoxShape.circle,
              image: url.isNotEmpty ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
            ),
            child: url.isEmpty ? Center(child: Text(ini, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _bleu))) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_v('nom')} ${_v('prenoms')}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                Text(e.matricule, style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), fontFamily: 'monospace')),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  _badge(statut == 'actif' ? 'Inscrit' : (statut == 'suspendu' ? 'Suspendu' : 'Renvoyé'),
                      statut == 'actif' ? AdminTheme.success : (statut == 'suspendu' ? AdminTheme.warning : AdminTheme.danger),
                      statut == 'actif' ? AdminTheme.successLight : (statut == 'suspendu' ? AdminTheme.warningLight : AdminTheme.dangerLight)),
                  _badge(soir ? 'Cours du soir' : 'Cours du jour', soir ? const Color(0xFF6D28D9) : _bleu, soir ? const Color(0xFFEDE9FE) : const Color(0xFFDBEAFE)),
                ]),
              ],
            ),
          ),
          if (!_edition) ...[
            IconButton.filledTonal(
              tooltip: 'Modifier les informations',
              onPressed: _demarrerEdition,
              icon: const Icon(Icons.edit_outlined),
            ),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed: widget.onCarte,
              icon: const Icon(Icons.badge_outlined, size: 16),
              label: const Text("Carte"),
            ),
          ],
        ],
      ),
    );

    final lecture = <Widget>[
      _carte(Icons.person_outline, 'Informations personnelles', [
        _ligne('Nom', _v('nom')),
        _ligne('Prénoms', _v('prenoms')),
        _ligne('Date de naissance', _fmtDate(_v('dateNaissance'))),
        _ligne('Lieu de naissance', _v('lieuNaissance')),
        _ligne('Nationalité', _v('nationalite').isEmpty ? 'Burkinabè' : _v('nationalite')),
        _ligne('Sexe', sexeTxt),
        _ligne('Matricule', e.matricule),
      ]),
      _carte(Icons.school_outlined, 'Informations académiques', [
        _ligne('Filière', _v('filiere')),
        _ligne('Niveau', _v('niveau')),
        _ligne('Régime', soir ? 'Cours du soir' : 'Cours du jour'),
      ]),
      _carte(Icons.info_outline, 'Informations complémentaires', [
        _ligne('Téléphone', _v('telephone')),
        _ligne('Email', emailAff),
        _ligne('Adresse', _v('adresse')),
      ]),
      _carte(Icons.emergency_outlined, 'Personne à prévenir en cas de besoin', [
        _ligne('Nom et prénom', _v('urgenceNom')),
        _ligne('Téléphone', _v('urgenceTel')),
        _ligne('Lien', _v('urgenceLien')),
      ]),
      _carte(Icons.family_restroom_outlined, 'Tuteur / Parent', [
        _ligne('Nom', _v('nomParent')),
        _ligne('Téléphone', _v('telParent')),
        _ligne('Email', _v('emailParent')),
      ]),
      _carte(Icons.attach_file, 'Pièces jointes', [
        if (_documents.isEmpty)
          const Text('Aucun document enregistré.', style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)))
        else
          for (final d in _documents)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                const Icon(Icons.description_outlined, size: 18, color: Color(0xFF6B7280)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${(d['type'] ?? '') == 'cnib' ? 'CNIB / acte' : 'Autre'} — ${d['nom_fichier'] ?? 'fichier'}',
                      style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
                ),
                TextButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: (d['url'] ?? '').toString()));
                    if (mounted) showAppSnackBar(context, 'Lien copié.');
                  },
                  child: const Text('Copier le lien', style: TextStyle(fontSize: 12)),
                ),
              ]),
            ),
      ]),
    ];

    final edition = <Widget>[
      _carte(Icons.person_outline, 'Informations personnelles', [
        _cols([_in('Nom', 'nom'), _in('Prénoms', 'prenoms')]),
        _cols([
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Date de naissance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
              const SizedBox(height: 5),
              InkWell(
                onTap: _choisirDate,
                child: Container(
                  height: 42,
                  width: double.infinity,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFD1D5DB))),
                  child: Text(_dateNaissance.isEmpty ? 'Choisir une date' : _fmtDate(_dateNaissance), style: const TextStyle(fontSize: 13)),
                ),
              ),
            ]),
          ),
          _in('Lieu de naissance', 'lieuNaissance'),
        ]),
        _cols([
          _sel('Nationalité', _nationalite, _nationalites, (v) => setState(() => _nationalite = v ?? _nationalite)),
          _sel('Sexe', _sexe, const ['M', 'F'], (v) => setState(() => _sexe = v ?? ''), aff: (s) => s == 'M' ? 'Masculin' : 'Féminin'),
        ]),
        if (_nationalite == 'Autre') _in('Précisez la nationalité', 'natAutre'),
        _ligne('Matricule', '${e.matricule}  (non modifiable)'),
      ]),
      _carte(Icons.school_outlined, 'Informations académiques', [
        _cols([
          _sel('Filière', _filiere, _filieres.contains(_filiere) || _filiere.isEmpty ? _filieres : [..._filieres, _filiere], (v) => setState(() => _filiere = v ?? _filiere)),
          _sel('Niveau', _niveau, _niveaux.contains(_niveau) || _niveau.isEmpty ? _niveaux : [..._niveaux, _niveau], (v) => setState(() => _niveau = v ?? _niveau)),
          _sel('Régime', _regime, const ['jour', 'soir'], (v) => setState(() => _regime = v ?? 'jour'), aff: (s) => s == 'soir' ? 'Cours du soir' : 'Cours du jour'),
        ]),
      ]),
      _carte(Icons.info_outline, 'Informations complémentaires', [
        _cols([_in('Téléphone', 'telephone', type: TextInputType.phone), _in('Email', 'email', type: TextInputType.emailAddress), _in('Adresse', 'adresse')]),
      ]),
      _carte(Icons.emergency_outlined, 'Personne à prévenir en cas de besoin', [
        _cols([_in('Nom et prénom', 'urgenceNom'), _in('Téléphone', 'urgenceTel', type: TextInputType.phone), _in('Lien', 'urgenceLien')]),
      ]),
      _carte(Icons.family_restroom_outlined, 'Tuteur / Parent', [
        _cols([_in('Nom', 'nomParent'), _in('Téléphone', 'telParent', type: TextInputType.phone), _in('Email', 'emailParent', type: TextInputType.emailAddress)]),
      ]),
      if (_erreur != null)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AdminTheme.dangerLight, borderRadius: BorderRadius.circular(8)),
          child: Text(_erreur!, style: const TextStyle(fontSize: 12, color: AdminTheme.danger)),
        ),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(onPressed: _envoi ? null : () => setState(() => _edition = false), child: const Text('Annuler')),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _envoi ? null : _enregistrer,
            icon: _envoi
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined, size: 18, color: Colors.white),
            label: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: _bleu, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(onPressed: widget.onRetour, icon: const Icon(Icons.arrow_back, size: 16), label: const Text('Retour à la liste')),
                ),
                const SizedBox(height: 14),
                entete,
                ..._edition ? edition : lecture,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PAGE « INSCRIRE UN ÉTUDIANT » (remplace l'ancienne boîte de dialogue)
// ════════════════════════════════════════════════════════════════════════════
class _Fichier {
  final String nom;
  final Uint8List bytes;
  const _Fichier(this.nom, this.bytes);
}

class _InscrireEtudiantPage extends StatefulWidget {
  final StudentProfile profile;
  final VoidCallback onRetour;
  final VoidCallback onInscrit;
  final void Function(String matricule) onCarte;
  const _InscrireEtudiantPage({
    required this.profile,
    required this.onRetour,
    required this.onInscrit,
    required this.onCarte,
  });

  @override
  State<_InscrireEtudiantPage> createState() => _InscrireEtudiantPageState();
}

class _InscrireEtudiantPageState extends State<_InscrireEtudiantPage> {
  static const _niveaux = ['Licence 1', 'Licence 2', 'Licence 3', 'Master 1', 'Master 2'];
  static const _nationalites = [
    'Burkinabè', 'Ivoirienne', 'Malienne', 'Nigérienne', 'Togolaise', 'Béninoise',
    'Ghanéenne', 'Sénégalaise', 'Guinéenne', 'Nigériane', 'Camerounaise', 'Autre',
  ];
  static const _bleu = Color(0xFF2563EB);

  final _nomCtrl = TextEditingController();
  final _prenomsCtrl = TextEditingController();
  final _lieuCtrl = TextEditingController();
  final _natAutreCtrl = TextEditingController();
  final _matriculeCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _urgNomCtrl = TextEditingController();
  final _urgTelCtrl = TextEditingController();
  final _urgLienCtrl = TextEditingController();
  // Tuteur / parent (optionnel) : crée ou lie un compte parent côté backend
  final _nomParentCtrl = TextEditingController();
  final _prenomParentCtrl = TextEditingController();
  final _telParentCtrl = TextEditingController();
  final _emailParentCtrl = TextEditingController();

  String _dateNaissance = ''; // ISO yyyy-MM-dd
  String? _nationalite = 'Burkinabè';
  String? _sexe; // 'M' | 'F'
  String? _filiere;
  String? _niveau;
  String _regime = 'jour'; // 'jour' | 'soir'
  late String _annee;
  late final List<String> _annees;
  List<String> _filieres = [];
  bool _chargementFilieres = true;
  bool _genMatricule = false;

  _Fichier? _photo; // facultative
  _Fichier? _cnib;
  _Fichier? _autre;

  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    final y = n.month >= 9 ? n.year : n.year - 1;
    _annees = ['${y - 1} - $y', '$y - ${y + 1}', '${y + 1} - ${y + 2}'];
    _annee = _annees[1];
    _chargerFilieres();
  }

  @override
  void dispose() {
    for (final c in [
      _nomCtrl, _prenomsCtrl, _lieuCtrl, _natAutreCtrl, _matriculeCtrl, _telCtrl, _emailCtrl,
      _adresseCtrl, _urgNomCtrl, _urgTelCtrl, _urgLienCtrl, _nomParentCtrl, _prenomParentCtrl,
      _telParentCtrl, _emailParentCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _chargerFilieres() async {
    final result = await ApiService.getFilieres();
    if (result['success'] == true) {
      final data = result['data'] as List<dynamic>;
      // toSet() : évite les doublons de nom (sinon le menu déroulant plante).
      _filieres = data
          .map((f) => (f['nom'] ?? '').toString().trim())
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList();
    }
    if (mounted) setState(() => _chargementFilieres = false);
  }

  int get _anneeEntree => int.tryParse(_annee.split(' ').first) ?? DateTime.now().year;

  Future<void> _genererMatricule() async {
    setState(() { _genMatricule = true; _erreur = null; });
    final r = await ApiService.getProchainMatricule(anneeEntree: _anneeEntree);
    if (!mounted) return;
    setState(() {
      _genMatricule = false;
      if (r['success'] == true && (r['matricule'] ?? '').toString().isNotEmpty) {
        _matriculeCtrl.text = r['matricule'].toString();
      } else {
        _erreur = r['error']?.toString() ?? r['message']?.toString() ?? 'Génération impossible.';
      }
    });
  }

  Future<void> _choisirPhoto() async {
    try {
      final p = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (p == null) return;
      final b = await p.readAsBytes();
      if (b.length > 2 * 1024 * 1024) {
        setState(() => _erreur = 'La photo dépasse 2 Mo.');
        return;
      }
      setState(() { _photo = _Fichier(p.name, b); _erreur = null; });
    } catch (_) {
      setState(() => _erreur = 'Impossible de charger cette image.');
    }
  }

  Future<_Fichier?> _choisirDocument() async {
    try {
      final r = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (r == null || r.files.isEmpty) return null;
      final f = r.files.first;
      final b = f.bytes;
      if (b == null) return null;
      if (b.length > 5 * 1024 * 1024) {
        setState(() => _erreur = 'Le fichier « ${f.name} » dépasse 5 Mo.');
        return null;
      }
      setState(() => _erreur = null);
      return _Fichier(f.name, b);
    } catch (_) {
      setState(() => _erreur = 'Impossible de charger ce fichier.');
      return null;
    }
  }

  Future<void> _choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateNaissance) ?? DateTime(2003, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(() => _dateNaissance =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
    }
  }

  String get _nationaliteFinale =>
      _nationalite == 'Autre' ? _natAutreCtrl.text.trim() : (_nationalite ?? '');

  // ── Enregistrement ────────────────────────────────────────────────────
  Future<void> _soumettre() async {
    final manque = <String>[
      if (_nomCtrl.text.trim().isEmpty) 'nom',
      if (_prenomsCtrl.text.trim().isEmpty) 'prénoms',
      if (_dateNaissance.isEmpty) 'date de naissance',
      if (_lieuCtrl.text.trim().isEmpty) 'lieu de naissance',
      if (_nationaliteFinale.isEmpty) 'nationalité',
      if (_sexe == null) 'sexe',
      if (_filiere == null) 'filière',
      if (_niveau == null) 'niveau',
    ];
    if (manque.isNotEmpty) {
      setState(() => _erreur = 'Champs obligatoires manquants : ${manque.join(', ')}.');
      return;
    }
    setState(() { _envoi = true; _erreur = null; });

    // Matricule obligatoire : généré automatiquement s'il n'a pas été saisi.
    if (_matriculeCtrl.text.trim().isEmpty) {
      final r = await ApiService.getProchainMatricule(anneeEntree: _anneeEntree);
      if (r['success'] == true && (r['matricule'] ?? '').toString().isNotEmpty) {
        _matriculeCtrl.text = r['matricule'].toString();
      } else {
        if (!mounted) return;
        setState(() {
          _envoi = false;
          _erreur = r['error']?.toString() ?? r['message']?.toString() ?? 'Matricule : génération impossible.';
        });
        return;
      }
    }

    String t(TextEditingController c) => c.text.trim();
    final result = await ApiService.inscrireEtudiant({
      'nom': t(_nomCtrl),
      'prenoms': t(_prenomsCtrl),
      'filiere': _filiere,
      'niveau': _niveau,
      'matricule': t(_matriculeCtrl),
      'sexe': _sexe,
      'regime': _regime,
      'nationalite': _nationaliteFinale,
      'dateNaissance': _dateNaissance,
      'lieuNaissance': t(_lieuCtrl),
      'anneeEntree': _anneeEntree,
      if (t(_emailCtrl).isNotEmpty) 'email': t(_emailCtrl),
      if (t(_telCtrl).isNotEmpty) 'telephone': t(_telCtrl),
      if (t(_adresseCtrl).isNotEmpty) 'adresse': t(_adresseCtrl),
      if (t(_urgNomCtrl).isNotEmpty) 'urgenceNom': t(_urgNomCtrl),
      if (t(_urgTelCtrl).isNotEmpty) 'urgenceTel': t(_urgTelCtrl),
      if (t(_urgLienCtrl).isNotEmpty) 'urgenceLien': t(_urgLienCtrl),
      if (t(_nomParentCtrl).isNotEmpty) 'nomParent': t(_nomParentCtrl),
      if (t(_prenomParentCtrl).isNotEmpty) 'prenomParent': t(_prenomParentCtrl),
      if (t(_telParentCtrl).isNotEmpty) 'telParent': t(_telParentCtrl),
      if (t(_emailParentCtrl).isNotEmpty) 'emailParent': t(_emailParentCtrl),
    });
    if (!mounted) return;
    if (result['success'] != true) {
      setState(() {
        _envoi = false;
        _erreur = result['error']?.toString() ?? 'Erreur lors de l\'inscription.';
      });
      return;
    }

    // Pièces jointes (non bloquant : l'étudiant est déjà inscrit)
    final etuId = (result['etudiant'] is Map) ? (result['etudiant']['id'] ?? '').toString() : '';
    final echecs = <String>[];
    if (etuId.isNotEmpty) {
      if (_photo != null && !await _envoyerFichier('/etudiants/$etuId/photo', _photo!)) echecs.add('photo');
      if (_cnib != null && !await _envoyerFichier('/etudiants/$etuId/document', _cnib!, type: 'cnib')) echecs.add('CNIB');
      if (_autre != null && !await _envoyerFichier('/etudiants/$etuId/document', _autre!, type: 'autre')) echecs.add('autre document');
    }
    if (!mounted) return;

    final mat = result['matricule']?.toString() ?? _matriculeCtrl.text.trim();
    final notif = result['notifications'] is Map ? result['notifications'] as Map : const {};
    final smsOk = notif['sms'] is Map && notif['sms']['envoye'] == true;
    final emailOk = notif['email'] is Map && notif['email']['envoye'] == true;
    setState(() => _envoi = false);
    _confirmation(mat, smsOk, emailOk, echecs);
  }

  Future<bool> _envoyerFichier(String chemin, _Fichier f, {String? type}) async {
    try {
      final token = await ApiService.getToken();
      final req = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}$chemin'));
      req.headers['Authorization'] = 'Bearer $token';
      if (type != null) req.fields['type'] = type;
      req.files.add(http.MultipartFile.fromBytes('file', f.bytes, filename: f.nom));
      final r = await http.Response.fromStream(await req.send());
      return r.statusCode >= 200 && r.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  void _confirmation(String matricule, bool smsOk, bool emailOk, List<String> echecs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Color(0xFF15803D)),
          SizedBox(width: 10),
          Text('Étudiant inscrit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Matricule', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(matricule, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1, color: Color(0xFF1E40AF))),
            ),
            const SizedBox(height: 14),
            _ligneNotif('SMS de confirmation', smsOk),
            const SizedBox(height: 8),
            _ligneNotif('Email de confirmation', emailOk),
            if (echecs.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Non enregistré(s) : ${echecs.join(', ')}. Vous pourrez les ajouter plus tard.',
                  style: const TextStyle(fontSize: 12, color: AdminTheme.warning)),
            ],
            const SizedBox(height: 12),
            const Text(
              'L\'étudiant reçoit son matricule et un lien pour définir son mot de passe et confirmer son inscription.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(dctx); widget.onInscrit(); widget.onRetour(); },
            child: const Text('Terminer'),
          ),
          ElevatedButton.icon(
            onPressed: () { Navigator.pop(dctx); widget.onCarte(matricule); },
            icon: const Icon(Icons.badge_outlined, size: 16, color: Colors.white),
            label: const Text('Générer la carte', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: _bleu),
          ),
        ],
      ),
    );
  }

  Widget _ligneNotif(String label, bool ok) => Row(
    children: [
      Icon(ok ? Icons.check_circle_outline : Icons.cancel_outlined, size: 18, color: ok ? const Color(0xFF15803D) : const Color(0xFF94A3B8)),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 13.5)),
      const Spacer(),
      Text(ok ? 'Envoyé' : 'Non envoyé', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: ok ? const Color(0xFF15803D) : const Color(0xFF94A3B8))),
    ],
  );

  // ── Fiche d'inscription PDF (télécharger / imprimer) ──────────────────
  Future<Uint8List> _fichePdf() async {
    final pdf = pw.Document();
    pw.Widget l(String a, String b) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.SizedBox(width: 130, child: pw.Text(a, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))),
        pw.Expanded(child: pw.Text(b.isEmpty ? '................................' : b, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
      ]),
    );
    pw.Widget titre(String t) => pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: PdfColors.grey200,
      child: pw.Text(t, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
    );
    final sexe = _sexe == 'M' ? 'Masculin' : (_sexe == 'F' ? 'Féminin' : '');
    final photo = _photo != null ? pw.MemoryImage(_photo!.bytes) : null;
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text(EtablissementConfig.instance.nom.toUpperCase(), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text("FICHE D'INSCRIPTION", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Année académique : $_annee', style: const pw.TextStyle(fontSize: 10)),
                  ]),
                ),
                pw.Container(
                  width: 80,
                  height: 100,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey600, width: 0.6),
                    image: photo != null ? pw.DecorationImage(image: photo, fit: pw.BoxFit.cover) : null,
                  ),
                  child: photo == null ? pw.Center(child: pw.Text('Photo', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))) : null,
                ),
              ],
            ),
            titre('Informations personnelles'),
            l('Nom', _nomCtrl.text.trim().toUpperCase()),
            l('Prénoms', _prenomsCtrl.text.trim()),
            l('Né(e) le', _fmtDate(_dateNaissance)),
            l('Lieu de naissance', _lieuCtrl.text.trim()),
            l('Nationalité', _nationaliteFinale),
            l('Sexe', sexe),
            l('Matricule', _matriculeCtrl.text.trim()),
            titre('Informations académiques'),
            l('Filière', _filiere ?? ''),
            l('Niveau', _niveau ?? ''),
            l('Année académique', _annee),
            l('Régime', _regime == 'soir' ? 'Cours du soir' : 'Cours du jour'),
            titre('Informations complémentaires'),
            l('Téléphone', _telCtrl.text.trim()),
            l('Email', _emailCtrl.text.trim()),
            l('Adresse', _adresseCtrl.text.trim()),
            titre('Personne à prévenir en cas de besoin'),
            l('Nom et prénom', _urgNomCtrl.text.trim()),
            l('Téléphone', _urgTelCtrl.text.trim()),
            l('Lien', _urgLienCtrl.text.trim()),
            pw.Spacer(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Signature de l'étudiant", style: const pw.TextStyle(fontSize: 10)),
                pw.Text("Le responsable", style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 40),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  // ── Widgets de base ───────────────────────────────────────────────────
  static const _bordure = Color(0xFFD1D5DB);

  Widget _lbl(String t, {bool req = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text.rich(TextSpan(
      text: t,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
      children: [if (req) const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFDC2626)))],
    )),
  );

  Widget _boite({required Widget child, VoidCallback? onTap}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: _bordure)),
      child: child,
    ),
  );

  Widget _champ(String label, TextEditingController c, {IconData? icon, String? hint, bool req = false, TextInputType? type}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _lbl(label, req: req),
      _boite(
        child: Row(children: [
          if (icon != null) ...[Icon(icon, size: 18, color: const Color(0xFF6B7280)), const SizedBox(width: 8)],
          Expanded(
            child: TextField(
              controller: c,
              keyboardType: type,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
              ),
            ),
          ),
        ]),
      ),
    ],
  );

  Widget _select(String label, String? value, List<String> items, ValueChanged<String?> on,
      {IconData? icon, String hint = 'Sélectionner', bool req = false, String Function(String)? aff, bool charge = false}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _lbl(label, req: req),
          _boite(
            child: Row(children: [
              if (icon != null) ...[Icon(icon, size: 18, color: const Color(0xFF6B7280)), const SizedBox(width: 8)],
              Expanded(
                child: charge
                    ? const LinearProgressIndicator()
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: items.contains(value) ? value : null,
                          isExpanded: true,
                          hint: Text(hint, style: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF))),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                          items: [for (final i in items) DropdownMenuItem(value: i, child: Text(aff != null ? aff(i) : i, overflow: TextOverflow.ellipsis))],
                          onChanged: on,
                        ),
                      ),
              ),
            ]),
          ),
        ],
      );

  Widget _dateChamp() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _lbl('Date de naissance', req: true),
      _boite(
        onTap: _choisirDate,
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Text(_dateNaissance.isEmpty ? 'jj/mm/aaaa' : _fmtDate(_dateNaissance),
              style: TextStyle(fontSize: 13, color: _dateNaissance.isEmpty ? const Color(0xFF9CA3AF) : const Color(0xFF111827))),
        ]),
      ),
    ],
  );

  /// Place les champs côte à côte si la largeur le permet, sinon en colonne.
  Widget _cols(List<Widget> ws) => LayoutBuilder(
    builder: (_, c) {
      if (c.maxWidth < 560) {
        return Column(children: [for (int i = 0; i < ws.length; i++) ...[if (i > 0) const SizedBox(height: 12), ws[i]]]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (int i = 0; i < ws.length; i++) ...[if (i > 0) const SizedBox(width: 14), Expanded(child: ws[i])]],
      );
    },
  );

  Widget _section(IconData ic, String titre) => Container(
    margin: const EdgeInsets.only(top: 18, bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(color: _bleu, shape: BoxShape.circle),
        child: Icon(ic, size: 15, color: Colors.white),
      ),
      const SizedBox(width: 10),
      Text(titre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
    ]),
  );

  Widget _zone(String titre, IconData ic, String formats, _Fichier? f, VoidCallback onTap, VoidCallback onRetirer, {bool req = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _lbl(titre, req: req),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 104,
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: f != null ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: f != null ? const Color(0xFF86EFAC) : const Color(0xFF93C5FD)),
          ),
          child: f == null
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(ic, color: _bleu, size: 24),
                  const SizedBox(height: 6),
                  const Text('Cliquez pour ajouter', style: TextStyle(fontSize: 11.5, color: Color(0xFF374151))),
                  const SizedBox(height: 2),
                  Text(formats, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)), textAlign: TextAlign.center),
                ])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 24),
                  const SizedBox(height: 4),
                  Text(f.nom, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: onRetirer,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 24)),
                    child: const Text('Retirer', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
                  ),
                ]),
        ),
      ),
    ],
  );

  // ── Colonne de droite ─────────────────────────────────────────────────
  Widget _carteDroite({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
    child: child,
  );

  Widget _bouton(String t, IconData ic, VoidCallback on, {bool plein = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SizedBox(
      width: double.infinity,
      child: plein
          ? ElevatedButton.icon(
              onPressed: on,
              icon: Icon(ic, size: 18, color: Colors.white),
              label: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              style: ElevatedButton.styleFrom(backgroundColor: _bleu, padding: const EdgeInsets.symmetric(vertical: 14)),
            )
          : OutlinedButton.icon(
              onPressed: on,
              icon: Icon(ic, size: 18, color: _bleu),
              label: Text(t, style: const TextStyle(color: _bleu, fontWeight: FontWeight.w700, fontSize: 13)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: _bleu)),
            ),
    ),
  );

  Widget _colonneDroite() {
    final ini = ((_prenomsCtrl.text.trim().isNotEmpty ? _prenomsCtrl.text.trim()[0] : '') +
            (_nomCtrl.text.trim().isNotEmpty ? _nomCtrl.text.trim()[0] : ''))
        .toUpperCase();
    final admin = '${widget.profile.prenoms} ${widget.profile.nom}'.trim();
    return Column(
      children: [
        _carteDroite(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.account_box_outlined, color: _bleu, size: 20),
                SizedBox(width: 8),
                Text('Aperçu de la photo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 14),
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(16),
                    image: _photo != null ? DecorationImage(image: MemoryImage(_photo!.bytes), fit: BoxFit.cover) : null,
                  ),
                  child: _photo == null
                      ? Center(
                          child: ini.isEmpty
                              ? const Icon(Icons.person_rounded, size: 90, color: _bleu)
                              : Text(ini, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: _bleu)),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _choisirPhoto,
                  icon: const Icon(Icons.photo_camera_outlined, size: 16),
                  label: Text(_photo == null ? 'Ajouter une photo' : 'Changer la photo', style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
        _carteDroite(
          child: Container(
            color: const Color(0xFFEFF6FF),
            padding: const EdgeInsets.all(2),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.lightbulb_outline, color: _bleu, size: 18),
                  SizedBox(width: 8),
                  Text('Rappel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ]),
                SizedBox(height: 8),
                Text(
                  'La carte d\'étudiant peut être générée juste après l\'enregistrement des informations.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF4B5563), height: 1.4),
                ),
              ],
            ),
          ),
        ),
        _carteDroite(
          child: Column(children: [
            _bouton('Générer la carte d\'étudiant', Icons.badge_outlined, () {
              setState(() => _erreur = 'Enregistrez d\'abord l\'étudiant : la carte se génère ensuite.');
            }, plein: true),
            _bouton('Télécharger le formulaire (PDF)', Icons.picture_as_pdf_outlined, () async {
              await Printing.sharePdf(bytes: await _fichePdf(), filename: 'Fiche_inscription.pdf');
            }),
            _bouton('Imprimer la fiche', Icons.print_outlined, () async {
              await Printing.layoutPdf(onLayout: (_) => _fichePdf(), name: 'Fiche_inscription.pdf');
            }),
          ]),
        ),
        _carteDroite(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.info_outline, color: _bleu, size: 20),
                SizedBox(width: 8),
                Text('Informations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 12),
              _infoLigne('Ajouté par :', Text(admin.isEmpty ? '—' : admin, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
              const SizedBox(height: 8),
              _infoLigne('Date d\'inscription :', const Text('—', style: TextStyle(fontSize: 12.5))),
              const SizedBox(height: 8),
              _infoLigne(
                'Statut :',
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: AdminTheme.successLight, borderRadius: BorderRadius.circular(20)),
                  child: const Text('En cours', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AdminTheme.success)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoLigne(String a, Widget b) => Row(
    children: [
      Expanded(child: Text(a, style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)))),
      b,
    ],
  );

  // ── Formulaire ────────────────────────────────────────────────────────
  Widget _formulaire() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section(Icons.person_outline, 'Informations personnelles'),
          _cols([
            _champ('Nom', _nomCtrl, icon: Icons.person_outline, hint: 'Ex. KABORE', req: true),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _champ('Prénoms', _prenomsCtrl, icon: Icons.person_outline, hint: 'Ex. Issa', req: true),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Si plusieurs prénoms, seul le premier ou deux seront affichés sur la carte.',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF6B7280))),
              ),
            ]),
          ]),
          const SizedBox(height: 14),
          _cols([
            _dateChamp(),
            _champ('Lieu de naissance', _lieuCtrl, icon: Icons.location_on_outlined, hint: 'Ex. Ouagadougou', req: true),
            _select('Nationalité', _nationalite, _nationalites, (v) => setState(() => _nationalite = v),
                icon: Icons.public, hint: 'Sélectionner la nationalité', req: true),
          ]),
          if (_nationalite == 'Autre') ...[
            const SizedBox(height: 12),
            _champ('Précisez la nationalité', _natAutreCtrl, icon: Icons.public, hint: 'Ex. Mauritanienne'),
          ],
          const SizedBox(height: 14),
          _cols([
            _select('Sexe', _sexe, const ['M', 'F'], (v) => setState(() => _sexe = v),
                icon: Icons.wc, hint: 'Sélectionner le sexe', req: true, aff: (s) => s == 'M' ? 'Masculin' : 'Féminin'),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _champ('Matricule', _matriculeCtrl, icon: Icons.badge_outlined, hint: 'Ex. RITL2-001', req: true),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _genMatricule ? null : _genererMatricule,
                  icon: _genMatricule
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_fix_high_rounded, size: 14),
                  label: const Text('Générer automatiquement', style: TextStyle(fontSize: 11.5)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28)),
                ),
              ),
              Text(
                EtablissementConfig.instance.modeleMatricule.isNotEmpty
                    ? 'Ancien étudiant : saisissez-le. Modèle : ${EtablissementConfig.instance.modeleMatricule}'
                    : 'Ancien étudiant : saisissez-le. Nouvel étudiant : générez-le.',
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF)),
              ),
            ]),
            const SizedBox.shrink(),
          ]),

          _section(Icons.school_outlined, 'Informations académiques'),
          _cols([
            _select('Filière', _filiere, _filieres, (v) => setState(() => _filiere = v),
                icon: Icons.menu_book_outlined, hint: 'Sélectionner une filière', req: true, charge: _chargementFilieres),
            _select('Niveau', _niveau, _niveaux, (v) => setState(() => _niveau = v),
                icon: Icons.layers_outlined, hint: 'Sélectionner un niveau', req: true),
            _select('Année académique', _annee, _annees, (v) => setState(() => _annee = v ?? _annee),
                icon: Icons.calendar_today_outlined, req: true),
          ]),
          const SizedBox(height: 14),
          _lbl('Régime', req: true),
          Wrap(
            spacing: 10,
            children: [
              ChoiceChip(
                avatar: const Icon(Icons.wb_sunny_outlined, size: 16),
                label: const Text('Cours du jour'),
                selected: _regime == 'jour',
                onSelected: (_) => setState(() => _regime = 'jour'),
              ),
              ChoiceChip(
                avatar: const Icon(Icons.nights_stay_outlined, size: 16),
                label: const Text('Cours du soir'),
                selected: _regime == 'soir',
                onSelected: (_) => setState(() => _regime = 'soir'),
              ),
            ],
          ),

          _section(Icons.info_outline, 'Informations complémentaires'),
          _cols([
            _champ('Téléphone', _telCtrl, icon: Icons.phone_outlined, hint: 'Ex. 70 12 34 56', type: TextInputType.phone),
            _champ('Email', _emailCtrl, icon: Icons.mail_outline, hint: 'Ex. issa.kabore@email.com', type: TextInputType.emailAddress),
            _champ('Adresse', _adresseCtrl, icon: Icons.location_on_outlined, hint: 'Ex. Quartier, ville'),
          ]),

          _section(Icons.emergency_outlined, 'Personne à prévenir en cas de besoin'),
          _cols([
            _champ('Nom et prénom', _urgNomCtrl, icon: Icons.person_outline),
            _champ('Téléphone', _urgTelCtrl, icon: Icons.phone_outlined, type: TextInputType.phone),
            _champ('Lien (ex : Père, Oncle)', _urgLienCtrl, icon: Icons.family_restroom_outlined),
          ]),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Imprimée au verso de la carte d\'étudiant.', style: TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF))),
          ),

          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: const Text('Tuteur / Parent (optionnel)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
              subtitle: const Text('Si rempli, un compte parent est créé (ou lié s\'il existe déjà pour ce numéro).',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              children: [
                _cols([
                  _champ('Nom du tuteur', _nomParentCtrl),
                  _champ('Prénom(s) du tuteur', _prenomParentCtrl),
                ]),
                const SizedBox(height: 12),
                _cols([
                  _champ('Téléphone du tuteur', _telParentCtrl, type: TextInputType.phone),
                  _champ('Email du tuteur', _emailParentCtrl, type: TextInputType.emailAddress),
                ]),
              ],
            ),
          ),

          _section(Icons.attach_file, 'Pièces jointes'),
          _cols([
            _zone('Photo d\'identité (facultative)', Icons.photo_camera_outlined, 'Format : JPG, PNG | Taille max : 2 Mo',
                _photo, _choisirPhoto, () => setState(() => _photo = null)),
            _zone('Copie de la CNIB (ou acte de naissance)', Icons.description_outlined, 'Format : PDF, JPG, PNG | Taille max : 5 Mo',
                _cnib, () async { final f = await _choisirDocument(); if (f != null) setState(() => _cnib = f); }, () => setState(() => _cnib = null)),
            _zone('Autres documents (facultatif)', Icons.description_outlined, 'Format : PDF, JPG, PNG | Taille max : 5 Mo',
                _autre, () async { final f = await _choisirDocument(); if (f != null) setState(() => _autre = f); }, () => setState(() => _autre = null)),
          ]),

          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFFEF9C3), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFDE68A))),
            child: const Row(children: [
              Icon(Icons.info, size: 16, color: Color(0xFFCA8A04)),
              SizedBox(width: 8),
              Expanded(
                child: Text('Après l\'inscription, vous pourrez générer la carte d\'étudiant et l\'associer à un groupe (si nécessaire).',
                    style: TextStyle(fontSize: 12, color: Color(0xFF854D0E))),
              ),
            ]),
          ),
          if (_erreur != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AdminTheme.dangerLight, borderRadius: BorderRadius.circular(8)),
              child: Text(_erreur!, style: const TextStyle(fontSize: 12, color: AdminTheme.danger)),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _envoi ? null : widget.onRetour,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Annuler'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14)),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _envoi ? null : _soumettre,
                icon: _envoi
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined, size: 18, color: Colors.white),
                label: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(backgroundColor: _bleu, padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: LayoutBuilder(
        builder: (_, c) {
          final large = c.maxWidth >= 1000;
          return SingleChildScrollView(
            padding: EdgeInsets.all(c.maxWidth >= 900 ? 22 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.onRetour,
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Retour'),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: _bleu, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Inscrire un étudiant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                          Text('Renseignez les informations de l\'étudiant pour l\'ajouter à la base de données.',
                              style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (large)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _formulaire()),
                      const SizedBox(width: 18),
                      SizedBox(width: 330, child: _colonneDroite()),
                    ],
                  )
                else ...[
                  _formulaire(),
                  const SizedBox(height: 16),
                  _colonneDroite(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DIALOGUE — INSCRIPTIONS EN ATTENTE (auto-inscriptions des anciens étudiants)
// + interrupteurs de l'inscription en ligne (réservés au Super Admin côté serveur)
// ════════════════════════════════════════════════════════════════════════════
class _DemandesDialog extends StatefulWidget {
  const _DemandesDialog();

  @override
  State<_DemandesDialog> createState() => _DemandesDialogState();
}

class _DemandesDialogState extends State<_DemandesDialog> {
  bool _chargement = true;
  bool _occupe = false;
  String? _message;
  bool _messageErreur = false;
  List<Map<String, dynamic>> _demandes = [];
  final Set<String> _selection = {};
  bool _ouverte = false;
  bool _validation = true;
  bool _paramsOk = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    final r = await ApiService.getInscriptionsEnAttente();
    final p = await ApiService.getParametresInscription();
    if (!mounted) return;
    setState(() {
      _chargement = false;
      if (r['success'] == true && r['data'] is List) {
        _demandes = (r['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _selection.removeWhere((id) => !_demandes.any((d) => '${d['id']}' == id));
      } else {
        _message = r['error']?.toString() ?? 'Impossible de charger les demandes.';
        _messageErreur = true;
      }
      if (p['success'] == true) {
        _ouverte = p['inscriptionOuverte'] == true;
        _validation = p['inscriptionValidation'] != false;
        _paramsOk = true;
      }
    });
  }

  Future<void> _majParametre({bool? ouverte, bool? validation}) async {
    final ancienO = _ouverte, ancienV = _validation;
    setState(() {
      if (ouverte != null) _ouverte = ouverte;
      if (validation != null) _validation = validation;
      _message = null;
    });
    final r = await ApiService.setParametresInscription(
      inscriptionOuverte: ouverte,
      inscriptionValidation: validation,
    );
    if (!mounted) return;
    if (r['success'] != true) {
      setState(() {
        _ouverte = ancienO;
        _validation = ancienV;
        _message = r['error']?.toString() ?? 'Modification impossible.';
        _messageErreur = true;
      });
    }
  }

  Future<void> _valider({bool tout = false}) async {
    if (!tout && _selection.isEmpty) return;
    setState(() { _occupe = true; _message = null; });
    final r = await ApiService.validerInscriptions(ids: _selection.toList(), all: tout);
    if (!mounted) return;
    setState(() {
      _occupe = false;
      _messageErreur = r['success'] != true;
      _message = r['success'] == true
          ? '${r['valides'] ?? 0} inscription(s) validée(s).'
          : (r['error']?.toString() ?? 'Validation impossible.');
      if (r['success'] == true) _selection.clear();
    });
    if (r['success'] == true) _charger();
  }

  Future<void> _refuser() async {
    if (_selection.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Refuser ces demandes ?'),
        content: Text('${_selection.length} demande(s) seront supprimées. Les étudiants pourront refaire une demande.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Refuser', style: TextStyle(color: AdminTheme.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() { _occupe = true; _message = null; });
    final r = await ApiService.refuserInscriptions(_selection.toList());
    if (!mounted) return;
    setState(() {
      _occupe = false;
      _messageErreur = r['success'] != true;
      _message = r['success'] == true
          ? '${r['refuses'] ?? 0} demande(s) refusée(s).'
          : (r['error']?.toString() ?? 'Refus impossible.');
      if (r['success'] == true) _selection.clear();
    });
    if (r['success'] == true) _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 680),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.how_to_reg_outlined, color: AdminTheme.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Inscriptions des anciens étudiants',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ],
            ),
            if (_paramsOk) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Inscription en ligne ouverte', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                subtitle: const Text(
                  'À fermer quand tous les anciens étudiants sont inscrits (Super Admin).',
                  style: TextStyle(fontSize: 11.5),
                ),
                value: _ouverte,
                onChanged: (v) => _majParametre(ouverte: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Validation par l\'administration', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                subtitle: const Text(
                  'Activée : chaque demande doit être validée avant la première connexion.',
                  style: TextStyle(fontSize: 11.5),
                ),
                value: _validation,
                onChanged: (v) => _majParametre(validation: v),
              ),
              const Divider(height: 18),
            ],
            if (_message != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _messageErreur ? AdminTheme.dangerLight : AdminTheme.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_message!,
                    style: TextStyle(fontSize: 12.5, color: _messageErreur ? AdminTheme.danger : AdminTheme.success)),
              ),
            Flexible(
              child: _chargement
                  ? const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
                  : _demandes.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(
                            child: Text('Aucune demande en attente.',
                                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _demandes.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final d = _demandes[i];
                            final id = '${d['id']}';
                            final aPrevenir = [d['nom_parent'], d['tel_parent']]
                                .where((x) => x != null && '$x'.isNotEmpty)
                                .join(' · ');
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: _selection.contains(id),
                              onChanged: _occupe
                                  ? null
                                  : (v) => setState(() => v == true ? _selection.add(id) : _selection.remove(id)),
                              title: Text('${d['prenoms'] ?? ''} ${d['nom'] ?? ''}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                [
                                  '${d['matricule'] ?? ''}',
                                  '${d['filiere'] ?? ''} · ${d['niveau'] ?? ''}',
                                  '${d['tel'] ?? ''} · ${d['email'] ?? ''}',
                                  if (aPrevenir.isNotEmpty) 'À prévenir : $aPrevenir',
                                ].join('\n'),
                                style: const TextStyle(fontSize: 11.5, height: 1.4),
                              ),
                              isThreeLine: true,
                            );
                          },
                        ),
            ),
            if (_demandes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    onPressed: _occupe
                        ? null
                        : () => setState(() {
                              if (_selection.length == _demandes.length) {
                                _selection.clear();
                              } else {
                                _selection
                                  ..clear()
                                  ..addAll(_demandes.map((d) => '${d['id']}'));
                              }
                            }),
                    child: Text(_selection.length == _demandes.length ? 'Tout désélectionner' : 'Tout sélectionner'),
                  ),
                  OutlinedButton(
                    onPressed: _occupe || _selection.isEmpty ? null : _refuser,
                    style: OutlinedButton.styleFrom(foregroundColor: AdminTheme.danger),
                    child: const Text('Refuser'),
                  ),
                  ElevatedButton(
                    onPressed: _occupe || _selection.isEmpty ? null : () => _valider(),
                    style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.iconBgAlt),
                    child: Text(
                      _selection.isEmpty ? 'Valider' : 'Valider (${_selection.length})',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// OUTILS CARTE D'ÉTUDIANT
// ════════════════════════════════════════════════════════════════════════════
/// Année académique courante : de septembre à août (ex. octobre 2026 → « 2026 - 2027 »).
String _anneeCourante() {
  final n = DateTime.now();
  final y = n.month >= 9 ? n.year : n.year - 1;
  return '$y - ${y + 1}';
}

/// « 2003-05-14… » → « 14/05/2003 » (sans décalage de fuseau).
String _fmtDate(String iso) {
  if (iso.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(iso)) {
    return '${iso.substring(8, 10)}/${iso.substring(5, 7)}/${iso.substring(0, 4)}';
  }
  return iso;
}

class _CarteInfos {
  final String nom, prenoms, matricule, filiere, niveau, nationalite, sexe;
  final String naissance, lieu, urgNom, urgTel, urgLien, photoUrl;
  const _CarteInfos({
    required this.nom,
    required this.prenoms,
    required this.matricule,
    required this.filiere,
    required this.niveau,
    required this.nationalite,
    required this.sexe,
    required this.naissance,
    required this.lieu,
    required this.urgNom,
    required this.urgTel,
    required this.urgLien,
    required this.photoUrl,
  });
}

/// Aperçu à l'écran de la carte (mêmes champs que le PDF). Dessinée en 342 × 216
/// (= 85,6 × 54 mm × 1,41) puis mise à l'échelle de la largeur disponible.
class _ApercuCarte extends StatelessWidget {
  final _CarteInfos infos;
  final Uint8List? photoBytes;
  final String responsable;
  final String annee;
  final bool verso;
  const _ApercuCarte({
    required this.infos,
    required this.photoBytes,
    required this.responsable,
    required this.annee,
    required this.verso,
  });

  static const _vert = Color(0xFF1A3C34);
  static const double _k = 1.41;

  Widget _ligne(String l, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: [
        TextSpan(text: '$l : ', style: TextStyle(fontSize: 5.2 * _k, color: Colors.grey.shade600)),
        TextSpan(text: v, style: TextStyle(fontSize: 6.4 * _k, fontWeight: FontWeight.bold, color: Colors.black)),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: FittedBox(
          fit: BoxFit.fitWidth,
          child: SizedBox(width: 342, height: 216, child: verso ? _verso() : _recto()),
        ),
      ),
    );
  }

  Widget _recto() {
    final ecole = EtablissementConfig.instance.nom;
    final i = infos;
    final ini = ((i.prenoms.isNotEmpty ? i.prenoms[0] : '') + (i.nom.isNotEmpty ? i.nom[0] : '')).toUpperCase();
    final sexeTxt = i.sexe == 'M' ? 'Masculin' : (i.sexe == 'F' ? 'Féminin' : '..........');
    final naiss = _fmtDate(i.naissance).isEmpty ? '..........' : _fmtDate(i.naissance);
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 24 * _k,
            color: _vert,
            padding: EdgeInsets.symmetric(horizontal: 8 * _k),
            child: Row(
              children: [
                Container(
                  width: 16 * _k,
                  height: 16 * _k,
                  decoration: BoxDecoration(color: const Color(0xFFD8F3DC), borderRadius: BorderRadius.circular(3 * _k)),
                  alignment: Alignment.center,
                  child: Text(ecole.isNotEmpty ? ecole[0].toUpperCase() : 'S', style: TextStyle(fontSize: 9 * _k, fontWeight: FontWeight.bold, color: _vert)),
                ),
                SizedBox(width: 6 * _k),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ecole.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 7 * _k, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text("CARTE D'ÉTUDIANT", style: TextStyle(fontSize: 5 * _k, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(8 * _k, 5 * _k, 8 * _k, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ligne('Nom', i.nom.toUpperCase()),
                        _ligne('Prénoms', i.prenoms),
                        _ligne('Né(e) le', '$naiss${i.lieu.isNotEmpty ? ' à ${i.lieu}' : ''}'),
                        _ligne('Nationalité', i.nationalite),
                        _ligne('Sexe', sexeTxt),
                        _ligne('Matricule', i.matricule),
                        _ligne('Filière', i.filiere),
                        _ligne('Niveau', i.niveau),
                      ],
                    ),
                  ),
                  SizedBox(width: 6 * _k),
                  Container(
                    width: 42 * _k,
                    height: 52 * _k,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      border: Border.all(color: Colors.grey.shade500, width: 0.7),
                      image: photoBytes != null
                          ? DecorationImage(image: MemoryImage(photoBytes!), fit: BoxFit.cover)
                          : (i.photoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(i.photoUrl), fit: BoxFit.cover) : null),
                    ),
                    alignment: Alignment.center,
                    child: (photoBytes == null && i.photoUrl.isEmpty)
                        ? Text(ini, style: TextStyle(fontSize: 14 * _k, fontWeight: FontWeight.bold, color: Colors.grey.shade600))
                        : null,
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 34 * _k,
            padding: EdgeInsets.fromLTRB(8 * _k, 0, 8 * _k, 4 * _k),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Signature de l'étudiant", style: TextStyle(fontSize: 4.8 * _k, color: Colors.grey.shade600)),
                      SizedBox(height: 12 * _k),
                      Container(height: 0.7, color: Colors.grey.shade500),
                    ],
                  ),
                ),
                SizedBox(width: 8 * _k),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Le responsable', style: TextStyle(fontSize: 4.8 * _k, color: Colors.grey.shade600)),
                      SizedBox(height: 8 * _k),
                      Container(height: 0.7, color: Colors.grey.shade500),
                      SizedBox(height: 1.5 * _k),
                      Text('Nom et Prénom : ${responsable.isEmpty ? '.................................' : responsable}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 4.8 * _k, color: Colors.black)),
                      Text('Année académique : $annee', style: TextStyle(fontSize: 4.8 * _k, fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _verso() {
    final i = infos;
    final ecole = EtablissementConfig.instance.nom;
    Widget lbl(String t) => Text(t, style: TextStyle(fontSize: 5 * _k, color: Colors.grey.shade600));
    Widget val(String t, double s, {bool gras = false}) => Text(
      t.isEmpty ? '...............................' : t,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: s * _k, fontWeight: gras ? FontWeight.bold : FontWeight.normal, color: Colors.black),
    );
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 20 * _k,
            color: _vert,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 8 * _k),
            child: Text('EN CAS DE BESOIN, PRÉVENIR', style: TextStyle(fontSize: 7 * _k, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(10 * _k, 8 * _k, 10 * _k, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  lbl('Nom et prénom'),
                  val(i.urgNom, 8.5, gras: true),
                  SizedBox(height: 5 * _k),
                  lbl("Lien avec l'étudiant"),
                  val(i.urgLien, 7),
                  SizedBox(height: 5 * _k),
                  lbl('Téléphone'),
                  val(i.urgTel, 9, gras: true),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10 * _k, 0, 10 * _k, 6 * _k),
            child: Text(
              "Cette carte est strictement personnelle et valable pour l'année académique $annee. En cas de perte ou de découverte, merci de la rapporter à : $ecole.",
              style: TextStyle(fontSize: 4.6 * _k, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Complète (ou corrige) l'identité d'un étudiant : sexe, naissance, nationalité,
/// personne à prévenir. Enregistré en base via PUT /etudiants/:id/identite.
class _IdentiteDialog extends StatefulWidget {
  final Etudiant etudiant;
  final Map<String, String> initial;
  final void Function(Map<String, String>) onSaved;
  const _IdentiteDialog({required this.etudiant, required this.initial, required this.onSaved});

  @override
  State<_IdentiteDialog> createState() => _IdentiteDialogState();
}

class _IdentiteDialogState extends State<_IdentiteDialog> {
  late String _sexe;
  late final TextEditingController _nat;
  late final TextEditingController _lieu;
  late final TextEditingController _uNom;
  late final TextEditingController _uTel;
  late final TextEditingController _uLien;
  String _naissance = ''; // ISO yyyy-MM-dd
  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    _sexe = (m['sexe'] == 'M' || m['sexe'] == 'F') ? m['sexe']! : '';
    _nat = TextEditingController(text: (m['nationalite'] ?? '').isEmpty ? 'Burkinabè' : m['nationalite']);
    _lieu = TextEditingController(text: m['lieuNaissance'] ?? '');
    _uNom = TextEditingController(text: m['urgenceNom'] ?? '');
    _uTel = TextEditingController(text: m['urgenceTel'] ?? '');
    _uLien = TextEditingController(text: m['urgenceLien'] ?? '');
    final d = m['dateNaissance'] ?? '';
    if (d.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(d)) _naissance = d.substring(0, 10);
  }

  @override
  void dispose() {
    _nat.dispose();
    _lieu.dispose();
    _uNom.dispose();
    _uTel.dispose();
    _uLien.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final base = DateTime.tryParse(_naissance) ?? DateTime(2003, 1, 1);
    final d = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(() => _naissance =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _enregistrer() async {
    setState(() { _envoi = true; _erreur = null; });
    try {
      final headers = await ApiService.getHeaders();
      final body = {
        'sexe': _sexe,
        'nationalite': _nat.text.trim(),
        'dateNaissance': _naissance,
        'lieuNaissance': _lieu.text.trim(),
        'urgenceNom': _uNom.text.trim(),
        'urgenceTel': _uTel.text.trim(),
        'urgenceLien': _uLien.text.trim(),
      };
      final r = await http.put(
        Uri.parse('${ApiService.baseUrl}/etudiants/${widget.etudiant.id}/identite'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (r.statusCode >= 200 && r.statusCode < 300) {
        widget.onSaved({
          'sexe': _sexe,
          'nationalite': _nat.text.trim().isEmpty ? 'Burkinabè' : _nat.text.trim(),
          'dateNaissance': _naissance,
          'lieuNaissance': _lieu.text.trim(),
          'urgenceNom': _uNom.text.trim(),
          'urgenceTel': _uTel.text.trim(),
          'urgenceLien': _uLien.text.trim(),
        });
        if (mounted) Navigator.pop(context, true);
      } else {
        String msg = 'Erreur ${r.statusCode}';
        try {
          msg = (jsonDecode(r.body)['message'] ?? msg).toString();
        } catch (_) {}
        if (mounted) setState(() { _envoi = false; _erreur = msg; });
      }
    } catch (err) {
      if (mounted) setState(() { _envoi = false; _erreur = 'Connexion impossible : $err'; });
    }
  }

  Widget _t(String label, TextEditingController c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
      const SizedBox(height: 6),
      TextField(
        controller: c,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final e = widget.etudiant;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Identité — ${e.prenoms} ${e.nom}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              const Text('Sexe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
              const SizedBox(height: 6),
              Row(
                children: [
                  ChoiceChip(label: const Text('Masculin'), selected: _sexe == 'M', onSelected: (_) => setState(() => _sexe = 'M')),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text('Féminin'), selected: _sexe == 'F', onSelected: (_) => setState(() => _sexe = 'F')),
                ],
              ),
              const SizedBox(height: 14),
              _t('Nationalité', _nat),
              const SizedBox(height: 14),
              const Text('Date de naissance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
              const SizedBox(height: 6),
              InkWell(
                onTap: _choisirDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: Text(_naissance.isEmpty ? 'Choisir une date' : _fmtDate(_naissance),
                      style: TextStyle(fontSize: 13, color: _naissance.isEmpty ? const Color(0xFF9CA3AF) : Colors.black)),
                ),
              ),
              const SizedBox(height: 14),
              _t('Lieu de naissance', _lieu),
              const SizedBox(height: 18),
              const Text('Personne à prévenir en cas de besoin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _t('Nom et prénom', _uNom),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _t('Téléphone', _uTel)),
                  const SizedBox(width: 12),
                  Expanded(child: _t('Lien (ex : Père)', _uLien)),
                ],
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 10),
                Text(_erreur!, style: const TextStyle(fontSize: 12, color: AdminTheme.danger)),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: _envoi ? null : () => Navigator.pop(context, false), child: const Text('Annuler'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _envoi ? null : _enregistrer,
                      style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary),
                      child: _envoi
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
}
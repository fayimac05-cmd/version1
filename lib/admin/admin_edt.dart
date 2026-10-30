import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_annonces.dart' show istNiveaux;
import '../admin/admin_filieres.dart' show Filiere, Module;
import '../services/api_service.dart';
import '../config/etablissement_config.dart';
import 'calendrier_academique_admin.dart';

const Color _navy = Color(0xFF0B1E4D);
const Color _blue = Color(0xFF1565E0);

// ════════════════════════════════════════════════════════════════════════════
// CONFIGURATION GRILLE
// ════════════════════════════════════════════════════════════════════════════
const List<String> joursSemaine = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];

const List<Map<String, String>> typeCoursOptions = [
  {'val': 'cours', 'label': 'Cours'},
  {'val': 'td', 'label': 'TD'},
  {'val': 'tp', 'label': 'TP'},
  {'val': 'examen', 'label': 'Examen'},
];

Color couleurPourType(String type) {
  switch (type) {
    case 'td': return const Color(0xFF8B5CF6);
    case 'tp': return const Color(0xFF10B981);
    case 'examen': return AdminTheme.danger;
    default: return AdminTheme.iconBg;
  }
}

String labelPourType(String type) {
  return typeCoursOptions.firstWhere((t) => t['val'] == type, orElse: () => typeCoursOptions[0])['label']!;
}

/// Étiquette courte affichée sur les cartes (CM / TD / TP / EX).
String badgePourType(String type) {
  switch (type) {
    case 'td': return 'TD';
    case 'tp': return 'TP';
    case 'examen': return 'EX';
    default: return 'CM';
  }
}

final DateFormat _formatDateAffichage = DateFormat('dd/MM/yyyy');
const List<String> _moisCourts = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

/// Année académique en cours, ex. « 2026-2027 » (la rentrée est en septembre).
String anneeAcademiqueCourante() {
  final n = DateTime.now();
  final y = n.month >= 9 ? n.year : n.year - 1;
  return '$y-${y + 1}';
}

int? _minutes(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final p = raw.split(':');
  if (p.length < 2) return null;
  final h = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

// Couleurs de cartes par matière (stables : calculées sur le nom)
const List<List<Color>> _cartePalette = [
  [Color(0xFFEFF6FF), Color(0xFFBFDBFE), Color(0xFF2563EB)],
  [Color(0xFFECFDF5), Color(0xFFA7F3D0), Color(0xFF059669)],
  [Color(0xFFF5F3FF), Color(0xFFDDD6FE), Color(0xFF7C3AED)],
  [Color(0xFFFFFBEB), Color(0xFFFDE68A), Color(0xFFD97706)],
  [Color(0xFFFEF2F2), Color(0xFFFECACA), Color(0xFFDC2626)],
];
List<Color> _paletteMatiere(String matiere) {
  var h = 0;
  for (final u in matiere.trim().toLowerCase().codeUnits) { h = (h * 31 + u) & 0x7fffffff; }
  return _cartePalette[h % _cartePalette.length];
}

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES
// ════════════════════════════════════════════════════════════════════════════
class Creneau {
  String jour, heureDebut, heureFin, matiere, salle, type, prof;
  Creneau({
    required this.jour, required this.heureDebut, required this.heureFin,
    required this.matiere, required this.salle, this.type = 'cours', this.prof = '',
  });

  factory Creneau.fromJson(Map<String, dynamic> json) => Creneau(
        jour: json['jour'] ?? '',
        heureDebut: json['heureDebut'] ?? '',
        heureFin: json['heureFin'] ?? '',
        matiere: json['matiere'] ?? '',
        salle: json['salle'] ?? '',
        type: json['type'] ?? 'cours',
        prof: json['prof'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'jour': jour, 'heureDebut': heureDebut, 'heureFin': heureFin,
        'matiere': matiere, 'salle': salle, 'type': type, 'prof': prof,
      };
}

class EdtEntry {
  final String id;
  final String? filiereId;
  final String filiereNom, niveau, anneeAcademique;
  final bool archive;
  final List<Creneau> creneaux;
  final DateTime? dateDebut;
  final DateTime? dateFin;

  EdtEntry({
    required this.id, this.filiereId, required this.filiereNom,
    required this.niveau, required this.anneeAcademique,
    required this.archive, required this.creneaux,
    this.dateDebut, this.dateFin,
  });

  factory EdtEntry.fromJson(Map<String, dynamic> json) => EdtEntry(
        id: json['id'].toString(),
        filiereId: json['filiere']?.toString(),
        filiereNom: json['filiere_nom'] ?? 'Filière inconnue',
        niveau: json['niveau'] ?? '',
        anneeAcademique: json['anneeAcademique'] ?? '',
        archive: json['archive'] == true,
        creneaux: (json['creneaux'] as List<dynamic>? ?? [])
            .map((c) => Creneau.fromJson(c as Map<String, dynamic>))
            .toList(),
        dateDebut: json['dateDebut'] != null ? DateTime.tryParse(json['dateDebut'].toString()) : null,
        dateFin: json['dateFin'] != null ? DateTime.tryParse(json['dateFin'].toString()) : null,
      );

  String get periodeAffichee => (dateDebut != null && dateFin != null)
      ? 'Semaine du ${_formatDateAffichage.format(dateDebut!)} au ${_formatDateAffichage.format(dateFin!)}'
      : '';

  /// Semaine terminée (date de fin dépassée).
  bool get estPasse {
    final f = dateFin;
    if (f == null) return false;
    final now = DateTime.now();
    return DateTime(f.year, f.month, f.day).isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Archivé à la main OU semaine terminée → rangé dans l'onglet « Archivés ».
  bool get estArchive => archive || estPasse;

  /// Statut calculé : Archivé / En préparation (semaine à venir) / Actif.
  String get statut {
    if (estArchive) return 'Archivé';
    final d = dateDebut;
    if (d != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (DateTime(d.year, d.month, d.day).isAfter(today)) return 'En préparation';
    }
    return 'Actif';
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PAGE ADMIN EDT — liste + assistant de création
// ════════════════════════════════════════════════════════════════════════════
class AdminEDT extends StatefulWidget {
  const AdminEDT({super.key});
  @override State<AdminEDT> createState() => _AdminEDTState();
}

class _AdminEDTState extends State<AdminEDT> {
  static const int _parPage = 6;

  List<EdtEntry> _entries = [];
  List<Filiere> _filieres = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _query = '';
  String? _filtreDomaine;
  String? _filtreNiveau;
  String? _filtreAnnee;
  int _onglet = 0; // 0 tous · 1 actifs · 2 archivés
  bool _vueCartes = true;
  int _section = 0; // 0 emplois du temps · 1 calendrier académique
  int _page = 1;
  final _searchCtrl = TextEditingController();

  bool _wizardOuvert = false;
  EdtEntry? _wizardExistant;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadData({bool silencieux = false}) async {
    if (!silencieux) setState(() { _isLoading = true; _errorMessage = null; });
    final results = await Future.wait([
      ApiService.getEdtAdmin(includeArchives: true),
      ApiService.getFilieres(),
    ]);
    if (!mounted) return;
    final edtResult = results[0];
    final filieresResult = results[1];
    setState(() {
      _isLoading = false;
      if (edtResult['success'] == true) {
        _entries = (edtResult['data'] as List<dynamic>).map((j) => EdtEntry.fromJson(Map<String, dynamic>.from(j as Map))).toList();
        _errorMessage = null;
      } else {
        _errorMessage = edtResult['error'] as String? ?? 'Erreur de chargement.';
      }
      if (filieresResult['success'] == true) {
        _filieres = (filieresResult['data'] as List<dynamic>)
            .map((f) => Filiere.fromApi(Map<String, dynamic>.from(f as Map))).toList();
      }
    });
  }

  Filiere? _filiereDe(EdtEntry e) {
    for (final f in _filieres) { if (f.backendId == e.filiereId) return f; }
    return null;
  }

  List<EdtEntry> get _filtered => _entries.where((e) {
    final f = _filiereDe(e);
    final q = _query.trim().toLowerCase();
    final matchQ = q.isEmpty ||
        e.filiereNom.toLowerCase().contains(q) ||
        (f?.abreviation.toLowerCase().contains(q) ?? false) ||
        e.creneaux.any((c) => c.matiere.toLowerCase().contains(q) || c.prof.toLowerCase().contains(q));
    final matchO = _onglet == 0 || (_onglet == 1 && !e.estArchive) || (_onglet == 2 && e.estArchive);
    final matchD = _filtreDomaine == null || f?.domaine == _filtreDomaine;
    final matchN = _filtreNiveau == null || e.niveau == _filtreNiveau;
    final matchA = _filtreAnnee == null || e.anneeAcademique == _filtreAnnee;
    return matchQ && matchO && matchD && matchN && matchA;
  }).toList();

  List<EdtEntry> get _pageItems {
    final all = _filtered;
    final start = (_page - 1) * _parPage;
    if (start >= all.length) return all.take(_parPage).toList();
    return all.skip(start).take(_parPage).toList();
  }

  int get _nbPages {
    final n = _filtered.length;
    return n == 0 ? 1 : ((n + _parPage - 1) ~/ _parPage);
  }

  List<String> get _annees {
    final s = <String>{anneeAcademiqueCourante()};
    for (final e in _entries) { if (e.anneeAcademique.isNotEmpty) s.add(e.anneeAcademique); }
    return s.toList()..sort();
  }

  List<String> get _domaines {
    final s = <String>{};
    for (final f in _filieres) { if (f.domaine.isNotEmpty) s.add(f.domaine); }
    return s.toList()..sort();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.redAccent : const Color(0xFF1E293B), behavior: SnackBarBehavior.floating),
    );
  }

  void _ouvrirWizard([EdtEntry? existant]) => setState(() { _wizardOuvert = true; _wizardExistant = existant; });

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdminTheme.isDesktop(context);
    final pad = isDesktop ? 24.0 : 14.0;

    if (_wizardOuvert) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7FC),
        body: _EdtWizard(
          key: ValueKey(_wizardExistant?.id ?? 'nouveau'),
          filieres: _filieres,
          existant: _wizardExistant,
          onClose: (saved) {
            setState(() { _wizardOuvert = false; _wizardExistant = null; });
            if (saved) _loadData(silencieux: true);
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: () => _loadData(silencieux: true),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(pad),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _header(isDesktop),
                      const SizedBox(height: 14),
                      _selecteurSection(),
                      const SizedBox(height: 16),
                      if (_section == 1)
                        const CalendrierAcademiqueAdmin()
                      else ...[
                        _kpiRow(isDesktop),
                        const SizedBox(height: 16),
                        _barreFiltres(isDesktop),
                        const SizedBox(height: 14),
                        _onglets(),
                        const SizedBox(height: 14),
                        if (_filtered.isEmpty)
                          _vide()
                        else if (_vueCartes)
                          _grille()
                        else
                          _tableau(),
                        const SizedBox(height: 14),
                        _pied(),
                      ],
                    ]),
                  ),
                ),
    );
  }

  Widget _buildErrorState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 32),
          const SizedBox(height: 12),
          Text(_errorMessage ?? 'Erreur', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loadData, child: const Text('Réessayer')),
        ]),
      );

  // ── En-tête ─────────────────────────────────────────────────────────────
  Widget _header(bool isDesktop) {
    final titre = Row(children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 28),
      ),
      const SizedBox(width: 14),
      Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Text('Emplois du Temps', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _navy, letterSpacing: -0.4)),
        const SizedBox(height: 2),
        const Text("Planifiez et gérez les emplois du temps de votre établissement.", style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
      ])),
    ]);

    final actualiser = OutlinedButton.icon(
      onPressed: _isLoading ? null : _loadData,
      icon: const Icon(Icons.refresh_rounded, size: 17),
      label: const Text('Actualiser', style: TextStyle(fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        foregroundColor: _blue, side: const BorderSide(color: Color(0xFFCBD5E1)), backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    final creer = ElevatedButton.icon(
      onPressed: () => _ouvrirWizard(),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Créer un emploi du temps', style: TextStyle(fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    if (isDesktop) {
      return Row(children: [Expanded(child: titre), const SizedBox(width: 16), actualiser, const SizedBox(width: 10), creer]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      titre, const SizedBox(height: 12),
      Row(children: [Expanded(child: actualiser), const SizedBox(width: 10), Expanded(child: creer)]),
    ]);
  }

  // ── KPI (valeurs réelles, sans tendances inventées) ─────────────────────
  Widget _kpiRow(bool isDesktop) {
    final actifs = _entries.where((e) => !e.estArchive).toList();
    final archives = _entries.where((e) => e.estArchive).length;
    final filieresConcernees = actifs.map((e) => e.filiereId).where((id) => id != null).toSet().length;
    final creneaux = actifs.fold<int>(0, (s, e) => s + e.creneaux.length);

    final cards = [
      _kpi(Icons.calendar_month_rounded, const Color(0xFF1D4ED8), 'Programmes actifs', '${actifs.length}', 'Emplois du temps en cours'),
      _kpi(Icons.school_rounded, const Color(0xFF10B981), 'Filières concernées', '$filieresConcernees', 'Avec un programme actif'),
      _kpi(Icons.event_note_rounded, const Color(0xFF7C3AED), 'Créneaux programmés', '$creneaux', 'Dans les programmes actifs'),
      _kpi(Icons.inventory_2_rounded, const Color(0xFFF59E0B), 'Programmes archivés', '$archives', 'Emplois du temps archivés'),
    ];
    if (isDesktop) {
      return Row(children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Expanded(child: cards[i]),
        ],
      ]);
    }
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 118, children: cards,
    );
  }

  Widget _kpi(IconData icon, Color c, String label, String value, String caption) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: Colors.white, size: 24)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _navy, height: 1.1)),
        const SizedBox(height: 4),
        Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ])),
    ]),
  );

  // ── Filtres ─────────────────────────────────────────────────────────────
  Widget _barreFiltres(bool isDesktop) {
    final search = Container(
      height: 52,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() { _query = v; _page = 1; }),
        style: const TextStyle(fontSize: 13.5),
        decoration: const InputDecoration(
          hintText: 'Rechercher par filière, module, professeur...',
          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 19),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
    final dDomaine = _PDrop<String>(
      boxLabel: 'Domaine', hint: 'Tous les domaines', value: _filtreDomaine,
      items: _domaines, labelOf: (d) => d,
      onChanged: (v) => setState(() { _filtreDomaine = v; _page = 1; }),
    );
    final dNiveau = _PDrop<String>(
      boxLabel: 'Niveau', hint: 'Tous les niveaux', value: _filtreNiveau,
      items: istNiveaux, labelOf: (d) => d,
      onChanged: (v) => setState(() { _filtreNiveau = v; _page = 1; }),
    );
    final dAnnee = _PDrop<String>(
      boxLabel: 'Année académique', hint: 'Toutes les années', value: _filtreAnnee,
      items: _annees, labelOf: (d) => d,
      onChanged: (v) => setState(() { _filtreAnnee = v; _page = 1; }),
    );
    final toggle = _toggleVue();

    if (isDesktop) {
      return Row(children: [
        Expanded(flex: 4, child: search), const SizedBox(width: 12),
        Expanded(flex: 3, child: dDomaine), const SizedBox(width: 12),
        Expanded(flex: 3, child: dNiveau), const SizedBox(width: 12),
        Expanded(flex: 3, child: dAnnee), const SizedBox(width: 12),
        toggle,
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      search, const SizedBox(height: 10), dDomaine, const SizedBox(height: 10),
      Row(children: [Expanded(child: dNiveau), const SizedBox(width: 10), Expanded(child: dAnnee)]),
      const SizedBox(height: 10), toggle,
    ]);
  }

  Widget _toggleVue() {
    Widget btn(String label, IconData icon, bool actif, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: actif ? _blue : Colors.white, borderRadius: BorderRadius.circular(9),
          border: Border.all(color: actif ? _blue : const Color(0xFFE2E8F0)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: actif ? Colors.white : _navy), const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: actif ? Colors.white : _navy)),
        ]),
      ),
    );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      btn('Cartes', Icons.grid_view_rounded, _vueCartes, () => setState(() => _vueCartes = true)),
      const SizedBox(width: 6),
      btn('Tableau', Icons.view_list_rounded, !_vueCartes, () => setState(() => _vueCartes = false)),
    ]);
  }

  // ── Sélecteur de section : Emplois du temps | Calendrier académique ────────
  Widget _selecteurSection() {
    Widget bouton(String label, IconData ic, int i) {
      final actif = _section == i;
      return GestureDetector(
        onTap: () => setState(() => _section = i),
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: actif ? _navy : Colors.white, borderRadius: BorderRadius.circular(24),
            border: Border.all(color: actif ? _navy : const Color(0xFFE2E8F0)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(ic, size: 16, color: actif ? Colors.white : const Color(0xFF475569)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: actif ? Colors.white : const Color(0xFF475569))),
          ]),
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        bouton('Emplois du temps', Icons.calendar_month_rounded, 0),
        bouton('Calendrier académique', Icons.event_note_rounded, 1),
      ]),
    );
  }

  Widget _onglets() {
    final nTous = _entries.length;
    final nActifs = _entries.where((e) => !e.estArchive).length;
    final nArch = nTous - nActifs;
    Widget tab(String label, int i) {
      final actif = _onglet == i;
      return GestureDetector(
        onTap: () => setState(() { _onglet = i; _page = 1; }),
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          decoration: BoxDecoration(
            color: actif ? _blue : Colors.white, borderRadius: BorderRadius.circular(24),
            border: Border.all(color: actif ? _blue : const Color(0xFFE2E8F0)),
          ),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: actif ? Colors.white : const Color(0xFF475569))),
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [tab('Tous ($nTous)', 0), tab('Actifs ($nActifs)', 1), tab('Archivés ($nArch)', 2)]),
    );
  }

  // ── Cartes ──────────────────────────────────────────────────────────────
  static const List<Color> _couleursCarte = [
    Color(0xFF1D4ED8), Color(0xFFF59E0B), Color(0xFF7C3AED),
    Color(0xFF10B981), Color(0xFFEF4444), Color(0xFF2563EB),
  ];
  Color _couleurDe(EdtEntry e) {
    final id = int.tryParse(e.filiereId ?? '') ?? e.filiereNom.length;
    return _couleursCarte[id % _couleursCarte.length];
  }

  IconData _iconeDe(String nom) {
    final n = nom.toLowerCase();
    if (n.contains('réseau') || n.contains('reseau') || n.contains('télécom') || n.contains('telecom')) return Icons.hub_rounded;
    if (n.contains('électro') || n.contains('electro')) return Icons.bolt_rounded;
    if (n.contains('marketing') || n.contains('communication')) return Icons.campaign_rounded;
    if (n.contains('civil')) return Icons.settings_rounded;
    if (n.contains('compta') || n.contains('financ')) return Icons.account_balance_rounded;
    if (n.contains('gestion')) return Icons.bar_chart_rounded;
    if (n.contains('science') || n.contains('techno')) return Icons.science_rounded;
    return Icons.calendar_month_rounded;
  }

  Widget _grille() => LayoutBuilder(builder: (ctx, c) {
    final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
    final items = _pageItems;
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols, mainAxisSpacing: 16, crossAxisSpacing: 16, mainAxisExtent: 300,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _carte(items[i]),
    );
  });

  Widget _pillStatut(String s) {
    final cfg = s == 'Actif'
        ? [const Color(0xFFD1FAE5), const Color(0xFF047857)]
        : s == 'En préparation'
            ? [const Color(0xFFFEF3C7), const Color(0xFFB45309)]
            : [const Color(0xFFE2E8F0), const Color(0xFF475569)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: cfg[0], borderRadius: BorderRadius.circular(20)),
      child: Text('● $s', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: cfg[1])),
    );
  }

  Widget _carte(EdtEntry e) {
    final f = _filiereDe(e);
    final color = _couleurDe(e);
    final abrev = f?.abreviation ?? '';
    final etu = f?.parNiveau[e.niveau];

    Widget stat(IconData ic, String val, String label) => Expanded(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(ic, size: 16, color: _blue), const SizedBox(width: 6),
          Flexible(child: Text(val, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _navy))),
        ]),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
      ]));

    Widget ligne(IconData ic, String t) => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        Icon(ic, size: 15, color: const Color(0xFF334155)), const SizedBox(width: 8),
        Expanded(child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
      ]),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 3.5, color: color),
          Expanded(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 50, height: 50, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(13)),
                    child: Icon(_iconeDe(e.filiereNom), color: Colors.white, size: 26)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(abrev.isEmpty ? e.filiereNom : abrev, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _navy)),
                  const SizedBox(height: 2),
                  Text(abrev.isEmpty ? e.niveau : e.filiereNom, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                ])),
                const SizedBox(width: 6),
                _pillStatut(e.statut),
                _menu(e),
              ]),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 10),
              Padding(padding: const EdgeInsets.only(right: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                stat(Icons.groups_rounded, etu == null ? '—' : '$etu', 'Étudiants'),
                stat(Icons.layers_rounded, e.niveau.isEmpty ? '—' : e.niveau, 'Niveau'),
                stat(Icons.menu_book_rounded, f == null ? '—' : '${f.nbModules}', 'Modules'),
              ])),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 10),
              Padding(padding: const EdgeInsets.only(right: 8), child: Column(children: [
                ligne(Icons.event_rounded, e.periodeAffichee.isEmpty ? 'Année ${e.anneeAcademique}' : e.periodeAffichee),
                ligne(Icons.schedule_rounded, '${e.creneaux.length} créneau${e.creneaux.length > 1 ? 'x' : ''} programmé${e.creneaux.length > 1 ? 's' : ''}'),
                if (f != null && f.responsable.isNotEmpty) ligne(Icons.person_rounded, 'Responsable : ${f.responsable}'),
              ])),
              const Spacer(),
              Padding(padding: const EdgeInsets.only(right: 8), child: Row(children: [
                Expanded(child: ElevatedButton.icon(
                  onPressed: () => _ouvrirWizard(e),
                  icon: const Icon(Icons.calendar_month_rounded, size: 15),
                  label: const Text('Voir le planning', maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0,
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _handleAction('envoyer', e),
                  icon: const Icon(Icons.send_rounded, size: 15),
                  label: const Text('Envoyer', maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy, side: const BorderSide(color: Color(0xFFCBD5E1)),
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )),
              ])),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _menu(EdtEntry e) => PopupMenuButton<String>(
    tooltip: 'Plus d\'actions',
    icon: const Icon(Icons.more_vert_rounded, size: 19, color: Color(0xFF64748B)),
    padding: EdgeInsets.zero,
    position: PopupMenuPosition.under,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    onSelected: (v) => _handleAction(v, e),
    itemBuilder: (_) => [
      const PopupMenuItem(value: 'envoyer', child: Row(children: [Icon(Icons.send_rounded, size: 17, color: _blue), SizedBox(width: 10), Text('Envoyer aux étudiants')])),
      const PopupMenuItem(value: 'modifier', child: Row(children: [Icon(Icons.edit_rounded, size: 17), SizedBox(width: 10), Text('Modifier la grille')])),
      PopupMenuItem(value: e.archive ? 'reactiver' : 'archiver', child: Row(children: [Icon(e.archive ? Icons.unarchive_rounded : Icons.archive_rounded, size: 17), const SizedBox(width: 10), Text(e.archive ? 'Réactiver' : 'Archiver')])),
      const PopupMenuItem(value: 'supprimer', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 17, color: Colors.redAccent), SizedBox(width: 10), Text('Supprimer', style: TextStyle(color: Colors.redAccent))])),
    ],
  );

  // ── Vue tableau ─────────────────────────────────────────────────────────
  Widget _tableau() {
    Widget cell(String t, double w, {bool bold = false, Color? color}) => SizedBox(
      width: w, child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12.5, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color ?? const Color(0xFF334155))));
    const widths = [80.0, 230.0, 100.0, 100.0, 250.0, 90.0, 130.0, 50.0];
    const heads = ['Code', 'Filière', 'Niveau', 'Année', 'Période', 'Créneaux', 'Statut', ''];
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), color: const Color(0xFFF8FAFC),
            child: Row(children: [for (var i = 0; i < heads.length; i++) cell(heads[i], widths[i], bold: true, color: _navy)]),
          ),
          for (final e in _pageItems) InkWell(
            onTap: () => _ouvrirWizard(e),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
              child: Row(children: [
                cell(_filiereDe(e)?.abreviation ?? '—', widths[0], bold: true, color: _couleurDe(e)),
                cell(e.filiereNom, widths[1], bold: true),
                cell(e.niveau, widths[2]),
                cell(e.anneeAcademique, widths[3]),
                cell(e.periodeAffichee.isEmpty ? '—' : e.periodeAffichee, widths[4]),
                cell('${e.creneaux.length}', widths[5]),
                SizedBox(width: widths[6], child: Align(alignment: Alignment.centerLeft, child: _pillStatut(e.statut))),
                SizedBox(width: widths[7], child: _menu(e)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _vide() => Container(
    padding: const EdgeInsets.symmetric(vertical: 48), alignment: Alignment.center,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.event_note_outlined, color: Color(0xFF94A3B8), size: 40),
      const SizedBox(height: 12),
      const Text('Aucun emploi du temps trouvé', style: TextStyle(color: Color(0xFF64748B))),
    ]),
  );

  Widget _pied() {
    final total = _filtered.length;
    final debut = total == 0 ? 0 : (_page - 1) * _parPage + 1;
    final fin = total == 0 ? 0 : ((_page - 1) * _parPage + _pageItems.length);
    Widget nav(IconData ic, bool enabled, VoidCallback onTap) => GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Icon(ic, size: 16, color: enabled ? _navy : const Color(0xFFCBD5E1)),
      ),
    );
    return Row(children: [
      Expanded(child: Text('Affichage de $debut à $fin sur $total emploi${total > 1 ? 's' : ''} du temps', style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)))),
      nav(Icons.chevron_left_rounded, _page > 1, () => setState(() => _page--)),
      const SizedBox(width: 6),
      for (var p = 1; p <= _nbPages; p++) ...[
        GestureDetector(
          onTap: () => setState(() => _page = p),
          child: Container(
            width: 34, height: 34, alignment: Alignment.center,
            decoration: BoxDecoration(color: p == _page ? _blue : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: p == _page ? _blue : const Color(0xFFE2E8F0))),
            child: Text('$p', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p == _page ? Colors.white : _navy)),
          ),
        ),
        const SizedBox(width: 6),
      ],
      nav(Icons.chevron_right_rounded, _page < _nbPages, () => setState(() => _page++)),
    ]);
  }

  // ── Actions ─────────────────────────────────────────────────────────────
  Future<void> _handleAction(String action, EdtEntry e) async {
    if (action == 'modifier') { _ouvrirWizard(e); return; }
    if (action == 'envoyer') { await _envoyerAuxEtudiants(e.id, e.filiereNom, e.niveau); return; }
    if (action == 'archiver') {
      final result = await ApiService.archiveEdt(e.id);
      if (result['success'] == true) { _showSnack('Emploi du temps archivé.'); _loadData(silencieux: true); }
      else { _showSnack(result['error'] as String? ?? 'Erreur.', isError: true); }
      return;
    }
    if (action == 'reactiver') {
      final result = await ApiService.updateEdtGrille(e.id, {'archive': false});
      if (result['success'] == true) { _showSnack('Emploi du temps réactivé.'); _loadData(silencieux: true); }
      else { _showSnack(result['error'] as String? ?? 'Erreur.', isError: true); }
      return;
    }
    if (action == 'supprimer') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Confirmer la suppression', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Supprimer l\'emploi du temps de « ${e.filiereNom} - ${e.niveau} » ? Cette action est irréversible.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        final result = await ApiService.deleteEdt(e.id);
        if (result['success'] == true) { _showSnack('Emploi du temps supprimé.'); _loadData(silencieux: true); }
        else { _showSnack(result['error'] as String? ?? 'Erreur.', isError: true); }
      }
    }
  }

  Future<void> _envoyerAuxEtudiants(String id, String filiereNom, String niveau) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(children: [
          Icon(Icons.send_rounded, color: _blue), SizedBox(width: 10),
          Text('Envoyer aux étudiants', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: Text('Notifier tous les étudiants de « $filiereNom — $niveau » que leur emploi du temps est disponible ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    _showSnack('Envoi en cours…');
    final result = await ApiService.envoyerEdt(id);
    if (!mounted) return;
    if (result['success'] == true) {
      final total = result['total'] ?? 0;
      final notifies = result['notifies'] ?? 0;
      _showSnack(total == 0 ? 'Aucun étudiant trouvé pour cette filière et ce niveau.' : 'Emploi du temps envoyé à $notifies étudiant(s).');
    } else {
      _showSnack(result['error'] as String? ?? 'Erreur lors de l\'envoi.', isError: true);
    }
  }
}

// ── Liste déroulante générique (PopupMenuButton — jamais DropdownButton sur le web)
class _PDrop<T> extends StatelessWidget {
  final IconData? icon;
  final String? boxLabel; // petit libellé dans la boîte (page liste)
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final bool enabled;
  final bool clearable;
  const _PDrop({this.icon, this.boxLabel, required this.hint, required this.value, required this.items,
      required this.labelOf, required this.onChanged, this.enabled = true, this.clearable = true});

  @override
  Widget build(BuildContext context) {
    final texte = Text(value != null ? labelOf(value as T) : hint, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: value != null ? _navy : const Color(0xFF64748B)));
    return PopupMenuButton<int>(
      enabled: enabled && items.isNotEmpty,
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 380),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (i) => onChanged(i < 0 ? null : items[i]),
      itemBuilder: (_) => [
        if (clearable) PopupMenuItem<int>(value: -1, child: Text(hint, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        for (var i = 0; i < items.length; i++)
          PopupMenuItem<int>(value: i, child: Text(labelOf(items[i]), style: const TextStyle(fontSize: 13))),
      ],
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(children: [
          if (icon != null) ...[Icon(icon, size: 18, color: const Color(0xFF475569)), const SizedBox(width: 10)],
          Expanded(child: boxLabel == null
              ? texte
              : Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(boxLabel!, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                  texte,
                ])),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 19, color: Color(0xFF64748B)),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ASSISTANT DE CRÉATION / ÉDITION — 3 étapes
// ════════════════════════════════════════════════════════════════════════════
class _Slot {
  final String debut, fin;
  const _Slot(this.debut, this.fin);
  String get key => '$debut-$fin';
  String get label => '$debut - $fin';
}

/// Portion affichée d'un créneau : un cours saisi 07:30-12:30 est découpé à
/// l'affichage comme sur le programme papier (07:30-10:30 puis 10:30-12:30).
class _Seg {
  final String debut, fin;
  final Creneau src;
  const _Seg(this.debut, this.fin, this.src);
  String get key => '$debut-$fin';
}

String _hhmm(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

class _EdtWizard extends StatefulWidget {
  final List<Filiere> filieres;
  final EdtEntry? existant;
  final void Function(bool saved) onClose;
  const _EdtWizard({super.key, required this.filieres, required this.existant, required this.onClose});
  @override State<_EdtWizard> createState() => _EdtWizardState();
}

class _EdtWizardState extends State<_EdtWizard> {
  int _step = 0;
  String? _domaine, _filiereId, _niveau;
  late String _annee;
  DateTime? _dateDebut, _dateFin;
  int _programme = 0; // 0 standard (semaine) · 1 personnalisé (période libre)
  late List<Creneau> _creneaux;
  int _vue = 0; // 0 calendrier · 1 liste · 2 par matière
  List<Module> _modules = [];
  bool _saving = false;
  String _pauseDebut = '12:30', _pauseFin = '13:30';
  String _etabNom = '', _etabLogo = '', _responsable = '';

  bool get _edition => widget.existant != null;

  static const List<_Slot> _slotsDefaut = [
    _Slot('08:00', '10:00'), _Slot('10:00', '12:00'), _Slot('14:00', '16:00'), _Slot('16:00', '18:00'),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existant;
    if (e != null) {
      _filiereId = e.filiereId;
      _niveau = e.niveau.isEmpty ? null : e.niveau;
      _annee = e.anneeAcademique.isEmpty ? anneeAcademiqueCourante() : e.anneeAcademique;
      _dateDebut = e.dateDebut;
      _dateFin = e.dateFin;
      _creneaux = List.from(e.creneaux);
      _step = 1;
      final f = _filiere;
      _domaine = f?.domaine;
      if (_dateDebut != null && _dateFin != null && _dateFin!.difference(_dateDebut!).inDays != 5) _programme = 1;
    } else {
      _annee = anneeAcademiqueCourante();
      _creneaux = [];
      final n = DateTime.now();
      final lundi = DateTime(n.year, n.month, n.day).subtract(Duration(days: n.weekday - 1));
      _dateDebut = lundi;
      _dateFin = lundi.add(const Duration(days: 5));
    }
    _chargerModules();
    _chargerEntete();
  }

  Filiere? get _filiere {
    for (final f in widget.filieres) { if (f.backendId == _filiereId) return f; }
    return null;
  }

  /// Nom / logo de l'établissement (config) et Responsable Pédagogique
  /// (membre admin dont le titre de nomination est « Responsable Pédagogique »).
  Future<void> _chargerEntete() async {
    final cfg = EtablissementConfig.instance;
    final nom = cfg.nom, logo = cfg.logoUrl;
    String resp = '';
    try {
      final res = await ApiService.getMembresAdmin();
      if (res['success'] == true) {
        for (final m in (res['data'] as List<dynamic>)) {
          final mm = Map<String, dynamic>.from(m as Map);
          final perms = mm['permissions'] is Map ? Map<String, dynamic>.from(mm['permissions'] as Map) : <String, dynamic>{};
          final titre = '${mm['admin_sub_role'] ?? ''} ${mm['role'] ?? ''} ${mm['titre'] ?? ''} ${perms['role'] ?? ''}'.toLowerCase();
          final ok = titre.contains('responsable') && (titre.contains('pédagogique') || titre.contains('pedagogique'));
          if (ok) {
            resp = '${mm['nom'] ?? ''} ${mm['prenoms'] ?? ''}'.trim();
            if (resp.isNotEmpty) break;
          }
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() { _etabNom = nom; _etabLogo = logo; _responsable = resp; });
  }

  String _anneeLabel() {
    final n = _niveau ?? '';
    if (n.startsWith('Licence')) { final k = n.replaceAll(RegExp(r'[^0-9]'), ''); return '${k.isEmpty ? '' : k}${k == '1' ? 'ère' : 'ème'} Année'; }
    return n; // Master 1 / Master 2
  }

  String _semaineLabel() {
    final a = _dateDebut, b = _dateFin;
    if (a == null || b == null) return '';
    final m1 = _moisLongs[a.month - 1].toUpperCase(), m2 = _moisLongs[b.month - 1].toUpperCase();
    if (a.year == b.year && a.month == b.month) return 'SEMAINE DU ${a.day} AU ${b.day} $m2 ${b.year}';
    return 'SEMAINE DU ${a.day} $m1${a.year == b.year ? '' : ' ${a.year}'} AU ${b.day} $m2 ${b.year}';
  }

  Widget _enteteOfficiel() {
    const noir = Color(0xFF111111);
    final f = _filiere;
    final dept = (f?.domaine ?? _domaine ?? '').trim();
    final fil = (f?.nom ?? '').toUpperCase();
    TextStyle st({bool b = false}) => TextStyle(fontSize: 11.5, color: noir, fontWeight: b ? FontWeight.w800 : FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(children: [
        Center(child: Text(_semaineLabel(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: noir, decoration: TextDecoration.underline))),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (dept.isNotEmpty) Text('Département $dept', style: st()),
            const SizedBox(height: 4),
            Text('ANNEE ACADEMIQUE $_annee', style: st(b: true)),
            const SizedBox(height: 4),
            Text('PROGRAMME de la ${_anneeLabel()} $fil'.trim(), style: st(b: true)),
          ])),
          if (_etabNom.isNotEmpty || _etabLogo.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [            if (_etabLogo.isNotEmpty) Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Image.network(_etabLogo, height: 44, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
            if (_etabNom.isNotEmpty) ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(_etabNom, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1565E0)))),
          ]),
        ]),
      ]),
    );
  }

  Future<void> _chargerModules() async {
    final id = _filiereId;
    if (id == null) { if (_modules.isNotEmpty) setState(() => _modules = []); return; }
    final res = await ApiService.getModules(filiereId: id);
    if (!mounted || res['success'] != true) return;
    setState(() {
      _modules = (res['data'] as List<dynamic>).map((m) => Module.fromApi(Map<String, dynamic>.from(m as Map))).toList();
    });
  }

  void _snack(String msg, {bool erreur = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), behavior: SnackBarBehavior.floating,
      backgroundColor: erreur ? Colors.redAccent : const Color(0xFF1E293B),
    ));
  }

  String _d(DateTime? d) => d == null ? '' : _formatDateAffichage.format(d);

  // ── Squelette ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDesktop = AdminTheme.isDesktop(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _entete(isDesktop),
        const SizedBox(height: 16),
        _carte(child: _step == 0 ? _etape1(isDesktop) : _step == 1 ? _etape2(isDesktop) : _etape3(isDesktop)),
      ]),
    );
  }

  Widget _carte({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: child,
  );

  Widget _entete(bool isDesktop) {
    final titre = Row(children: [
      Container(width: 60, height: 60, decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(15)),
          child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 30)),
      const SizedBox(width: 16),
      Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(_edition ? 'Modifier un emploi du temps' : 'Créer un emploi du temps',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _navy)),
        const SizedBox(height: 3),
        const Text("Configurez et publiez un nouvel emploi du temps pour une filière, un niveau d'études.",
            style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
      ])),
    ]);

    Widget pas(int i, String label) {
      final actif = _step == i;
      final fait = _step > i;
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 32, height: 32, alignment: Alignment.center,
          decoration: BoxDecoration(
            color: actif || fait ? _blue : Colors.white, shape: BoxShape.circle,
            border: Border.all(color: actif || fait ? _blue : const Color(0xFFCBD5E1), width: 1.5),
          ),
          child: fait
              ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
              : Text('${i + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: actif ? Colors.white : const Color(0xFF94A3B8))),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: actif ? FontWeight.w700 : FontWeight.w500, color: actif ? _blue : const Color(0xFF94A3B8))),
      ]);
    }

    final pasRow = Wrap(spacing: 22, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      pas(0, 'Informations générales'), pas(1, 'Créneaux et planning'), pas(2, 'Vérification et publication'),
    ]);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: isDesktop
          ? Row(children: [Expanded(child: titre), const SizedBox(width: 16), pasRow])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [titre, const SizedBox(height: 14), pasRow]),
    );
  }

  Widget _titreEtape(int n, String titre, String sous) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(children: [
      Container(width: 38, height: 38, alignment: Alignment.center,
          decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
          child: Text('$n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
      const SizedBox(width: 12),
      Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$n. $titre', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _navy)),
        Text(sous, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
      ])),
    ]),
  );

  Widget _champ(String label, Widget child, {bool requis = true}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(requis ? '$label *' : label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
      const SizedBox(height: 6),
      child,
    ],
  );

  Widget _rangee(bool isDesktop, List<Widget> kids) {
    if (!isDesktop) {
      return Column(children: [for (var i = 0; i < kids.length; i++) ...[if (i > 0) const SizedBox(height: 14), kids[i]]]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < kids.length; i++) ...[if (i > 0) const SizedBox(width: 18), Expanded(child: kids[i])],
    ]);
  }

  Widget _champDate(DateTime? v, VoidCallback onTap, {bool enabled = true}) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      height: 52, padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: enabled ? Colors.white : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(children: [
        const Icon(Icons.calendar_today_rounded, size: 17, color: Color(0xFF475569)), const SizedBox(width: 10),
        Expanded(child: Text(v == null ? 'jj/mm/aaaa' : _d(v), style: TextStyle(fontSize: 13, color: v == null ? const Color(0xFF94A3B8) : _navy))),
      ]),
    ),
  );

  // ── Étape 1 ─────────────────────────────────────────────────────────────
  List<String> get _domaines {
    final s = <String>{};
    for (final f in widget.filieres) { if (f.domaine.isNotEmpty) s.add(f.domaine); }
    return s.toList()..sort();
  }

  List<String> get _annees {
    final a = int.tryParse(anneeAcademiqueCourante().split('-').first) ?? DateTime.now().year;
    final s = <String>{'${a - 1}-$a', '$a-${a + 1}', '${a + 1}-${a + 2}', _annee};
    return s.toList()..sort();
  }

  Future<void> _choisirDate(bool debut) async {
    final init = (debut ? _dateDebut : _dateFin) ?? _dateDebut ?? DateTime.now();
    final d = await showDatePicker(
      context: context, initialDate: init, firstDate: DateTime(2020), lastDate: DateTime(2100),
      helpText: debut ? 'Date de début' : 'Date de fin',
    );
    if (d == null) return;
    setState(() {
      if (debut) {
        _dateDebut = d;
        if (_programme == 0 || _dateFin == null || _dateFin!.isBefore(d)) _dateFin = d.add(const Duration(days: 5));
      } else {
        _dateFin = d;
      }
    });
  }

  Widget _etape1(bool isDesktop) {
    final filiereOptions = widget.filieres.where((f) => _domaine == null || f.domaine == _domaine).toList();
    final filiere = _filiere;

    Widget carteProg(int i, IconData ic, String label) {
      final sel = _programme == i;
      return GestureDetector(
        onTap: () => setState(() {
          _programme = i;
          if (i == 0 && _dateDebut != null) _dateFin = _dateDebut!.add(const Duration(days: 5));
        }),
        child: Container(
          height: 52, padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? _blue : const Color(0xFFE2E8F0), width: sel ? 1.6 : 1)),
          child: Row(children: [
            Icon(sel ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, size: 19, color: sel ? _blue : const Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Icon(ic, size: 17, color: const Color(0xFF475569)), const SizedBox(width: 8),
            Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: _navy, fontWeight: FontWeight.w600))),
          ]),
        ),
      );
    }

    final info = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF1F6FE), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFD6E4FB))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_rounded, size: 18, color: _blue), const SizedBox(width: 10),
        Expanded(child: Text(
          _dateDebut != null && _dateFin != null
              ? 'Les créneaux seront créés pour la période du ${_d(_dateDebut)} au ${_d(_dateFin)}.\nVous pourrez les modifier à l\'étape suivante.'
              : 'Choisissez la date de début pour définir la période.',
          style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.5),
        )),
      ]),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _titreEtape(1, 'Informations générales', 'Sélectionnez les paramètres de votre emploi du temps.'),
      _rangee(isDesktop, [
        _champ('Domaine académique', _PDrop<String>(
          icon: Icons.school_rounded, hint: 'Tous les domaines', value: _domaine, items: _domaines, labelOf: (d) => d,
          enabled: !_edition,
          onChanged: (v) => setState(() {
            _domaine = v;
            if (_filiere != null && v != null && _filiere!.domaine != v) { _filiereId = null; _modules = []; }
          }),
        ), requis: false),
        _champ('Filière', _PDrop<Filiere>(
          icon: Icons.account_tree_rounded, hint: 'Choisir la filière', value: filiere, items: filiereOptions,
          labelOf: (f) => f.nom, clearable: false, enabled: !_edition,
          onChanged: (f) { setState(() { _filiereId = f?.backendId; if (f != null) _domaine = f.domaine; }); _chargerModules(); },
        )),
        _champ("Niveau d'études", _PDrop<String>(
          icon: Icons.layers_rounded, hint: 'Choisir le niveau', value: _niveau, items: istNiveaux, labelOf: (n) => n,
          clearable: false, onChanged: (v) => setState(() => _niveau = v),
        )),
      ]),
      const SizedBox(height: 16),
      _rangee(isDesktop, [
        _champ('Année académique', _PDrop<String>(
          icon: Icons.calendar_today_rounded, hint: 'Année', value: _annee, items: _annees, labelOf: (a) => a,
          clearable: false, onChanged: (v) => setState(() => _annee = v ?? _annee),
        )),
        _champ('Date de début de la semaine', _champDate(_dateDebut, () => _choisirDate(true))),
        _champ('Date de fin de la semaine', _champDate(_dateFin, () => _choisirDate(false), enabled: _programme == 1)),
      ]),
      const SizedBox(height: 16),
      _champ('Type de programme', isDesktop
          ? Row(children: [
              Expanded(child: carteProg(0, Icons.date_range_rounded, 'Standard (par semaine)')),
              const SizedBox(width: 12),
              Expanded(child: carteProg(1, Icons.schedule_rounded, 'Personnalisé (période spécifique)')),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: info),
            ])
          : Column(children: [
              carteProg(0, Icons.date_range_rounded, 'Standard (par semaine)'), const SizedBox(height: 10),
              carteProg(1, Icons.schedule_rounded, 'Personnalisé (période spécifique)'), const SizedBox(height: 10), info,
            ])),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        OutlinedButton(
          onPressed: () => widget.onClose(false),
          style: OutlinedButton.styleFrom(foregroundColor: _blue, side: const BorderSide(color: Color(0xFFCBD5E1)), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
          child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _continuer1,
          icon: const Icon(Icons.arrow_forward_rounded, size: 17),
          label: const Text('Continuer', style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
        ),
      ]),
    ]);
  }

  void _continuer1() {
    if (_filiereId == null || _niveau == null) { _snack('⚠️ Sélectionnez une filière et un niveau.'); return; }
    if (_dateDebut == null || _dateFin == null) { _snack('⚠️ Indiquez la date de début et de fin.'); return; }
    if (_dateFin!.isBefore(_dateDebut!)) { _snack('⚠️ La date de fin précède la date de début.'); return; }
    setState(() => _step = 1);
  }

  // ── Étape 2 ─────────────────────────────────────────────────────────────
  void _decalerSemaine(int jours) {
    if (_dateDebut == null || _dateFin == null) return;
    setState(() {
      _dateDebut = _dateDebut!.add(Duration(days: jours));
      _dateFin = _dateFin!.add(Duration(days: jours));
    });
  }

  Widget _etape2(bool isDesktop) {
    Widget vueBtn(String label, IconData ic, int i) {
      final actif = _vue == i;
      return GestureDetector(
        onTap: () => setState(() => _vue = i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: actif ? _blue : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: actif ? _blue : const Color(0xFFE2E8F0))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(ic, size: 15, color: actif ? Colors.white : const Color(0xFF475569)), const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: actif ? Colors.white : const Color(0xFF475569))),
          ]),
        ),
      );
    }
    Widget navBtn(IconData ic, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Icon(ic, size: 18, color: _navy)),
    );

    final vues = Row(mainAxisSize: MainAxisSize.min, children: [
      vueBtn('Vue calendrier', Icons.calendar_month_rounded, 0), const SizedBox(width: 6),
      vueBtn('Vue liste', Icons.view_list_rounded, 1), const SizedBox(width: 6),
      vueBtn('Vue par matière', Icons.menu_book_rounded, 2), const SizedBox(width: 6),
      vueBtn('Aperçu officiel', Icons.table_chart_rounded, 3),
    ]);
    final nav = Row(mainAxisSize: MainAxisSize.min, children: [
      navBtn(Icons.arrow_back_rounded, () => _decalerSemaine(-7)), const SizedBox(width: 8),
      Container(
        height: 40, padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF475569)), const SizedBox(width: 8),
          Text('${_d(_dateDebut)} - ${_d(_dateFin)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _navy)),
        ]),
      ),
      const SizedBox(width: 8),
      navBtn(Icons.arrow_forward_rounded, () => _decalerSemaine(7)),
    ]);
    final ajouter = ElevatedButton.icon(
      onPressed: () => _editer(),
      icon: const Icon(Icons.add_rounded, size: 17),
      label: const Text('Ajouter un créneau', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
      style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
    );

    final pause = GestureDetector(
      onTap: _choisirPause,
      child: Container(
        height: 40, padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: const Color(0xFFF1F6FE), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFD6E4FB))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.free_breakfast_rounded, size: 15, color: _blue), const SizedBox(width: 6),
          Text('Pause $_pauseDebut - $_pauseFin', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _blue)),
        ]),
      ),
    );

    final barre = isDesktop
        ? Row(children: [vues, const Spacer(), pause, const SizedBox(width: 10), nav, const SizedBox(width: 10), ajouter])
        : Wrap(spacing: 10, runSpacing: 10, children: [vues, pause, nav, ajouter]);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _titreEtape(2, 'Créneaux et planning', 'Organisez les cours de la semaine en ajoutant les créneaux et en attribuant les modules.'),
      barre,
      const SizedBox(height: 14),
      if (_vue == 0) _calendrier() else if (_vue == 1) _liste() else if (_vue == 2) _parMatiere() else _tableauOfficiel(),
      const SizedBox(height: 16),
      _barreBas(
        gauche: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF64748B)), const SizedBox(width: 8),
          Flexible(child: Text('Semaine du ${_d(_dateDebut)} au ${_d(_dateFin)}  •  ${_creneaux.length} créneau${_creneaux.length > 1 ? 'x' : ''} programmé${_creneaux.length > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)))),
        ]),
        retour: () => setState(() => _step = 0),
        libelle: 'Continuer', icone: Icons.arrow_forward_rounded,
        action: () {
          if (_creneaux.isEmpty) { _snack('⚠️ Ajoutez au moins un créneau avant de continuer.'); return; }
          setState(() => _step = 2);
        },
      ),
    ]);
  }

  Widget _barreBas({required Widget gauche, required VoidCallback retour, required String libelle, required IconData icone, required VoidCallback? action}) {
    final retourBtn = OutlinedButton.icon(
      onPressed: retour, icon: const Icon(Icons.arrow_back_rounded, size: 16),
      label: const Text('Retour', style: TextStyle(fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(foregroundColor: _blue, side: const BorderSide(color: Color(0xFFCBD5E1)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
    );
    final suite = ElevatedButton.icon(
      onPressed: action,
      icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(icone, size: 16),
      label: Text(libelle, style: const TextStyle(fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
    );
    return LayoutBuilder(builder: (ctx, c) {
      if (c.maxWidth < 640) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          gauche, const SizedBox(height: 10),
          Row(children: [Expanded(child: retourBtn), const SizedBox(width: 10), Expanded(child: suite)]),
        ]);
      }
      return Row(children: [Expanded(child: gauche), const SizedBox(width: 12), retourBtn, const SizedBox(width: 10), suite]);
    });
  }

  // Créneaux regroupés ----------------------------------------------------
  /// Découpe d'affichage d'un créneau (la donnée enregistrée reste inchangée) :
  ///  1. la pause (par défaut 12:30-13:30) est retirée si le cours la traverse ;
  ///  2. la partie du matin de plus de 3 h est coupée en deux
  ///     (ex. 07:30-12:30 → 07:30-10:30 puis 10:30-12:30) ;
  ///  3. la partie de l'après-midi reste en un seul bloc.
  List<_Seg> _segments(Creneau c) {
    final a = _minutes(c.heureDebut), b = _minutes(c.heureFin);
    final p0 = _minutes(_pauseDebut) ?? 750, p1 = _minutes(_pauseFin) ?? 810;
    if (a == null || b == null || b <= a) return [_Seg(c.heureDebut, c.heureFin, c)];

    final parts = <List<int>>[];
    if (a < p0 && b > p1) {
      parts..add([a, p0])..add([p1, b]);
    } else if (a < p0 && b > p0) {
      parts.add([a, p0]);
    } else if (a >= p0 && a < p1 && b > p1) {
      parts.add([p1, b]);
    } else {
      parts.add([a, b]);
    }

    final out = <_Seg>[];
    for (final p in parts) {
      final debut = p[0], fin = p[1];
      if (debut < p0 && fin - debut > 180) {
        out..add(_Seg(_hhmm(debut), _hhmm(debut + 180), c))..add(_Seg(_hhmm(debut + 180), _hhmm(fin), c));
      } else {
        out.add(_Seg(_hhmm(debut), _hhmm(fin), c));
      }
    }
    return out;
  }

  List<_Seg> get _tousSegments => [for (final c in _creneaux) ..._segments(c)];

  List<_Slot> _slots() {
    final map = <String, _Slot>{};
    // Horaires par défaut uniquement tant qu'aucun créneau n'existe.
    if (_creneaux.isEmpty) { for (final s in _slotsDefaut) { map[s.key] = s; } }
    for (final g in _tousSegments) {
      if (g.debut.isEmpty || g.fin.isEmpty) continue;
      map[g.key] = _Slot(g.debut, g.fin);
    }
    // Le soir : une seule case blanche par défaut (14:00 - 18:00) tant qu'aucun
    // cours n'est programmé après la pause.
    final p0 = _minutes(_pauseDebut) ?? 750;
    final aApresMidi = map.values.any((sl) => (_minutes(sl.debut) ?? 0) >= p0);
    if (!aApresMidi) { map['14:00-18:00'] = const _Slot('14:00', '18:00'); }
    final l = map.values.toList()..sort((a, b) {
      final x = a.debut.compareTo(b.debut);
      return x != 0 ? x : a.fin.compareTo(b.fin);
    });
    return l;
  }

  List<String> _jours() {
    final j = joursSemaine.take(5).toList();
    if (_creneaux.any((c) => c.jour == 'Samedi')) j.add('Samedi');
    return j;
  }

  String _abrevMatiere(String matiere) {
    final a = _filiere?.abreviation ?? '';
    return a.isEmpty ? matiere : '$matiere ($a)';
  }

  Widget _calendrier() {
    const double hourW = 112, colW = 188;
    final jours = _jours();
    final slots = _slots();
    final largeur = hourW + colW * jours.length;

    Widget entete(String t, {String? sous, double? w}) => Container(
      width: w ?? colW, height: 56, alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(color: Color(0xFFF1F6FE), border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)), left: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _navy)),
        if (sous != null) Text(sous, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ]),
    );

    final lignes = <Widget>[];
    for (var i = 0; i < slots.length; i++) {
      final s = slots[i];
      // Pause méridienne visuelle entre le dernier cours du matin et le premier de l'après-midi
      if (i > 0) {
        final prevFin = _minutes(slots[i - 1].fin) ?? 0;
        final debut = _minutes(s.debut) ?? 0;
        if (_estPause(prevFin, debut)) {
          lignes.add(Container(
            width: largeur, height: 30, alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 14),
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Text('PAUSE · $_pauseDebut - $_pauseFin', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
          ));
        }
      }
      lignes.add(IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          width: hourW, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
          child: Text(s.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
        ),
        for (final j in jours) Container(
          width: colW,
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)), left: BorderSide(color: Color(0xFFE2E8F0)))),
          child: _cellule(j, s),
        ),
      ])));
    }

    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: largeur,
          child: Column(children: [
            Row(children: [
              Container(width: hourW, height: 56, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: const BoxDecoration(color: Color(0xFFF1F6FE), border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
                  child: const Row(children: [Icon(Icons.schedule_rounded, size: 15, color: Color(0xFF475569)), SizedBox(width: 6), Text('Heure', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _navy))])),
              for (final j in jours) entete(j, sous: _dateDuJour(j)),
            ]),
            ...lignes,
          ]),
        ),
      ),
    );
  }

  Future<void> _choisirPause() async {
    TimeOfDay base(String h) { final m = _minutes(h) ?? 750; return TimeOfDay(hour: m ~/ 60, minute: m % 60); }
    final d = await showTimePicker(context: context, initialTime: base(_pauseDebut), helpText: 'Début de la pause');
    if (d == null || !mounted) return;
    final f = await showTimePicker(context: context, initialTime: base(_pauseFin), helpText: 'Fin de la pause');
    if (f == null) return;
    final m0 = d.hour * 60 + d.minute, m1 = f.hour * 60 + f.minute;
    if (m1 <= m0) { _snack('⚠️ La fin de la pause doit être après son début.'); return; }
    setState(() { _pauseDebut = _hhmm(m0); _pauseFin = _hhmm(m1); });
  }

  /// Vrai si l'écart entre deux plages est une pause (≥ 30 min, autour de midi).
  bool _estPause(int finPrecedente, int debutSuivant) {
    final p0 = _minutes(_pauseDebut) ?? 750, p1 = _minutes(_pauseFin) ?? 810;
    return finPrecedente <= p0 && debutSuivant >= p1;
  }

  String? _dateDuJour(String jour) {
    if (_dateDebut == null) return null;
    final idx = joursSemaine.indexOf(jour);
    if (idx < 0) return null;
    final d = _dateDebut!.add(Duration(days: idx));
    return '${d.day} ${_moisCourts[d.month - 1]}';
  }

  Widget _cellule(String jour, _Slot s) {
    final cs = _tousSegments.where((g) => g.src.jour == jour && g.debut == s.debut && g.fin == s.fin).map((g) => g.src).toList();
    if (cs.isEmpty) {
      // Plage déjà occupée par un cours plus long ce jour-là (ex. 07:30-12:30) :
      // ce n'est pas « libre », on l'affiche comme couverte.
      final s0 = _minutes(s.debut) ?? 0, s1 = _minutes(s.fin) ?? 0;
      final couvert = _tousSegments.any((g) {
        if (g.src.jour != jour) return false;
        final a = _minutes(g.debut), b = _minutes(g.fin);
        return a != null && b != null && a < s1 && s0 < b;
      });
      if (couvert) {
        return Container(
          margin: const EdgeInsets.all(7), height: 78, alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
          child: const Text('Cours en cours', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        );
      }
      return InkWell(
        onTap: () => _editer(jour: jour, slot: s),
        child: Container(
          margin: const EdgeInsets.all(7), height: 78,
          decoration: BoxDecoration(color: const Color(0xFFFAFBFD), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFCBD5E1))),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_circle_outline_rounded, size: 17, color: Color(0xFF94A3B8)), SizedBox(width: 6),
            Text('Libre', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ]),
        ),
      );
    }
    return Column(children: [for (final c in cs) _carteCreneau(c)]);
  }

  Widget _carteCreneau(Creneau c) {
    final p = _paletteMatiere(c.matiere);
    return GestureDetector(
      onTap: () => _editer(existant: c),
      child: Container(
        margin: const EdgeInsets.all(7), padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
        decoration: BoxDecoration(color: p[0], borderRadius: BorderRadius.circular(10), border: Border.all(color: p[1])),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(color: p[2], borderRadius: BorderRadius.circular(7)),
                child: const Icon(Icons.menu_book_rounded, size: 15, color: Colors.white)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_abrevMatiere(c.matiere), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: _navy)),
              if (c.prof.isNotEmpty) Text(c.prof, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
              Text(c.salle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
            ])),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero, iconSize: 16, icon: const Icon(Icons.more_vert_rounded, size: 16, color: Color(0xFF64748B)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (v) {
                if (v == 'edit') _editer(existant: c);
                if (v == 'del') setState(() => _creneaux.remove(c));
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Modifier')),
                PopupMenuItem(value: 'del', child: Text('Supprimer', style: TextStyle(color: Colors.redAccent))),
              ],
            ),
          ]),
          const SizedBox(height: 4),
          Align(alignment: Alignment.centerRight, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: couleurPourType(c.type).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(badgePourType(c.type), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: couleurPourType(c.type))),
          )),
        ]),
      ),
    );
  }

  Widget _vueVide() => Container(
    padding: const EdgeInsets.symmetric(vertical: 40), alignment: Alignment.center,
    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(10)),
    child: const Text('Aucun créneau pour le moment. Utilisez « Ajouter un créneau ».', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
  );

  Widget _ligneCreneau(Creneau c, {bool avecJour = true, bool avecMatiere = true}) {
    final p = _paletteMatiere(c.matiere);
    return InkWell(
      onTap: () => _editer(existant: c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
        child: Row(children: [
          Container(width: 4, height: 34, decoration: BoxDecoration(color: p[2], borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          SizedBox(width: avecJour ? 150 : 110, child: Text(avecJour ? '${c.jour} · ${c.heureDebut}-${c.heureFin}' : '${c.heureDebut}-${c.heureFin}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)))),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(avecMatiere ? _abrevMatiere(c.matiere) : (c.prof.isEmpty ? '—' : c.prof), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _navy)),
            Text([if (avecMatiere && c.prof.isNotEmpty) c.prof, c.salle].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: couleurPourType(c.type).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(badgePourType(c.type), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: couleurPourType(c.type))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
            onPressed: () => setState(() => _creneaux.remove(c)),
          ),
        ]),
      ),
    );
  }

  Widget _liste() {
    if (_creneaux.isEmpty) return _vueVide();
    final tries = [..._creneaux]..sort((a, b) {
      final j = joursSemaine.indexOf(a.jour).compareTo(joursSemaine.indexOf(b.jour));
      return j != 0 ? j : a.heureDebut.compareTo(b.heureDebut);
    });
    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [for (final c in tries) _ligneCreneau(c)]),
    );
  }

  Widget _parMatiere() {
    if (_creneaux.isEmpty) return _vueVide();
    final groupes = <String, List<Creneau>>{};
    for (final c in _creneaux) { groupes.putIfAbsent(c.matiere, () => []).add(c); }
    final noms = groupes.keys.toList()..sort();
    return Column(children: [
      for (final nom in noms) Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), color: _paletteMatiere(nom)[0],
            child: Text('${_abrevMatiere(nom)} — ${groupes[nom]!.length} créneau${groupes[nom]!.length > 1 ? 'x' : ''} · ${_formatDuree(groupes[nom]!)}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _navy)),
          ),
          for (final c in groupes[nom]!) _ligneCreneau(c, avecMatiere: false),
        ]),
      ),
    ]);
  }

  String _formatDuree(List<Creneau> l) {
    var total = 0;
    for (final c in l) {
      final a = _minutes(c.heureDebut), b = _minutes(c.heureFin);
      if (a != null && b != null && b > a) total += b - a;
    }
    final h = total ~/ 60, m = total % 60;
    return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
  }

  // ── Édition d'un créneau (sans DropdownButton) ──────────────────────────
  void _editer({String? jour, _Slot? slot, Creneau? existant}) {
    final matiereCtrl = TextEditingController(text: existant?.matiere ?? '');
    final salleCtrl = TextEditingController(text: existant?.salle ?? '');
    final profCtrl = TextEditingController(text: existant?.prof ?? '');
    String type = existant?.type ?? 'cours';
    String? jourSel = existant?.jour ?? jour;
    int? debut = _minutes(existant?.heureDebut ?? slot?.debut);
    int? fin = _minutes(existant?.heureFin ?? slot?.fin);

    String fmt(int? m) => m == null ? '--:--' : '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

    showDialog(context: context, builder: (dCtx) => StatefulBuilder(builder: (dCtx, setD) {
      Widget heure(String label, int? v, ValueChanged<int> set) => Expanded(child: GestureDetector(
        onTap: () async {
          final t = await showTimePicker(context: dCtx, initialTime: TimeOfDay(hour: (v ?? 480) ~/ 60, minute: (v ?? 480) % 60));
          if (t != null) setD(() => set(t.hour * 60 + t.minute));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(children: [
            const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)), const SizedBox(width: 8),
            Text(v == null ? label : fmt(v), style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
          ]),
        ),
      ));

      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(existant == null ? 'Nouveau créneau' : 'Modifier le créneau', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(width: 400, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Jour', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final j in joursSemaine) ChoiceChip(
              label: Text(j, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: jourSel == j ? Colors.white : _navy)),
              selected: jourSel == j, selectedColor: _blue, onSelected: (_) => setD(() => jourSel = j),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            heure('Heure début', debut, (m) => debut = m), const SizedBox(width: 10),
            heure('Heure fin', fin, (m) => fin = m),
          ]),
          const SizedBox(height: 14),
          if (_modules.isNotEmpty) ...[
            PopupMenuButton<int>(
              position: PopupMenuPosition.under,
              constraints: const BoxConstraints(maxWidth: 380),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (i) => setD(() {
                matiereCtrl.text = _modules[i].nom;
                if (_modules[i].professeur.isNotEmpty) profCtrl.text = _modules[i].professeur;
              }),
              itemBuilder: (_) => [for (var i = 0; i < _modules.length; i++) PopupMenuItem<int>(value: i, child: Text(_modules[i].nom, style: const TextStyle(fontSize: 13)))],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFFF1F6FE), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFD6E4FB))),
                child: const Row(children: [
                  Icon(Icons.menu_book_rounded, size: 16, color: _blue), SizedBox(width: 8),
                  Expanded(child: Text('Choisir un module de la filière', style: TextStyle(fontSize: 12.5, color: _blue, fontWeight: FontWeight.w600))),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _blue),
                ]),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(controller: matiereCtrl, decoration: InputDecoration(labelText: 'Matière / Module', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 12),
          TextField(controller: profCtrl, decoration: InputDecoration(labelText: 'Professeur', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 12),
          TextField(controller: salleCtrl, decoration: InputDecoration(labelText: 'Salle', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final t in typeCoursOptions) ChoiceChip(
              label: Text(t['label']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: type == t['val'] ? Colors.white : couleurPourType(t['val']!))),
              selected: type == t['val'], selectedColor: couleurPourType(t['val']!),
              backgroundColor: couleurPourType(t['val']!).withValues(alpha: 0.08),
              onSelected: (_) => setD(() => type = t['val']!),
            ),
          ]),
        ]))),
        actions: [
          if (existant != null)
            TextButton(onPressed: () { setState(() => _creneaux.remove(existant)); Navigator.pop(dCtx); },
                child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent))),
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final matiere = matiereCtrl.text.trim();
              final salle = salleCtrl.text.trim();
              String? err;
              if (jourSel == null || debut == null || fin == null) { err = 'Choisissez le jour et les horaires.'; }
              else if (fin! <= debut!) { err = "L'heure de fin doit être après l'heure de début."; }
              else if (matiere.isEmpty || salle.isEmpty) { err = 'Renseignez la matière et la salle.'; }
              if (err != null) {
                ScaffoldMessenger.of(dCtx).showSnackBar(SnackBar(content: Text('⚠️ $err'), backgroundColor: Colors.redAccent));
                return;
              }
              setState(() {
                if (existant != null) _creneaux.remove(existant);
                _creneaux.add(Creneau(jour: jourSel!, heureDebut: fmt(debut), heureFin: fmt(fin), matiere: matiere, salle: salle, type: type, prof: profCtrl.text.trim()));
              });
              Navigator.pop(dCtx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white),
            child: const Text('Valider'),
          ),
        ],
      );
    }));
  }

  // ── Tableau au format du programme officiel de l'école ──────────────────
  static const List<String> _moisLongs = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];

  /// Le tableau s'adapte à la largeur disponible : les 6 jours restent visibles
  /// d'un coup (défilement horizontal seulement si l'écran est vraiment étroit).
  Widget _tableauOfficiel() {
    if (_creneaux.isEmpty) return _vueVide();
    return LayoutBuilder(builder: (ctx, c) => _tableauOfficielAvec(c.maxWidth - 26));
  }

  Widget _tableauOfficielAvec(double dispo) {
    const double hW = 88;
    final jourW = ((dispo - hW) / joursSemaine.length).floorToDouble().clamp(120.0, 400.0);
    final double cW = (jourW * 0.68).floorToDouble();
    final double sW = jourW - cW;
    final slots = _slots();
    final largeur = hW + (cW + sW) * joursSemaine.length;
    const noir = Color(0xFF111111);
    const trait = BorderSide(color: Color(0xFF333333), width: 0.8);

    Widget boite(double w, Widget child, {Color? bg, double? h, double minH = 0}) => Container(
      width: w, height: h, constraints: BoxConstraints(minHeight: minH),
      alignment: Alignment.center, padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: bg, border: const Border.fromBorderSide(trait)),
      child: child,
    );
    TextStyle gras(double t, {Color c = noir}) => TextStyle(fontSize: t, fontWeight: FontWeight.w800, color: c, height: 1.25);

    String hh(String t) => t.replaceAll(':', 'H').toUpperCase();
    // Cours = blanc ; TD / TP / Examen = teinte claire de leur couleur (comme la légende)
    Color? fondType(String type) => type == 'cours' ? null : couleurPourType(type).withValues(alpha: 0.22);

    final lignes = <Widget>[
      // En-tête
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        boite(hW, Text('HORAIRES', style: gras(11)), h: 52),
        for (final j in joursSemaine) Column(children: [
          boite(cW + sW, Text(j.toUpperCase(), style: gras(11)), h: 26),
          Row(children: [boite(cW, Text('COURS', style: gras(10)), h: 26), boite(sW, Text('SALLE', style: gras(10)), h: 26)]),
        ]),
      ]),
    ];

    for (var i = 0; i < slots.length; i++) {
      final sl = slots[i];
      if (i > 0) {
        final prevFin = _minutes(slots[i - 1].fin) ?? 0;
        final debut = _minutes(sl.debut) ?? 0;
        if (_estPause(prevFin, debut)) {
          lignes.add(Container(
            width: largeur, height: 18, alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFA6A6A6), border: Border.fromBorderSide(trait)),
            child: Text('PAUSE', style: gras(10)),
          ));
        }
      }
      lignes.add(IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        boite(hW, Text('${hh(sl.debut)}-${hh(sl.fin)}', style: gras(10.5, c: const Color(0xFFD00000))), bg: const Color(0xFF00B0F0), minH: 96),
        for (final j in joursSemaine) ...[
          () {
            final cs = _tousSegments.where((g) => g.src.jour == j && g.debut == sl.debut && g.fin == sl.fin).map((g) => g.src).toList();
            return boite(cW, cs.isEmpty
                ? const SizedBox()
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    for (final c in cs) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(c.matiere, textAlign: TextAlign.center, style: gras(11.5)),
                      if (c.prof.isNotEmpty) ...[const SizedBox(height: 6), Text('Prof : ${c.prof}', textAlign: TextAlign.center, style: gras(10.5, c: const Color(0xFF1D4ED8)))],
                    ])),
                  ]), bg: cs.isEmpty ? null : fondType(cs.first.type));
          }(),
          () {
            final cs = _tousSegments.where((g) => g.src.jour == j && g.debut == sl.debut && g.fin == sl.fin).map((g) => g.src).toList();
            return boite(sW, cs.isEmpty
                ? const SizedBox()
                : Column(mainAxisSize: MainAxisSize.min, children: [for (final c in cs) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(c.salle, textAlign: TextAlign.center, style: gras(10.5)))]),
                bg: cs.isEmpty ? null : fondType(cs.first.type));
          }(),
        ],
      ])));
    }

    final n = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _enteteOfficiel(),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: largeur, child: Column(children: lignes))),
        const SizedBox(height: 10),
        Wrap(spacing: 14, runSpacing: 6, children: [
          for (final t in typeCoursOptions) Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 14, height: 14, decoration: BoxDecoration(
              color: t['val'] == 'cours' ? Colors.white : couleurPourType(t['val']!).withValues(alpha: 0.22),
              border: Border.all(color: t['val'] == 'cours' ? const Color(0xFF94A3B8) : couleurPourType(t['val']!)),
              borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(t['label']!, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
          ]),
        ]),
        const SizedBox(height: 12),
        const Text("N.B1: Chaque professeur est tenu de respecter le présent calendrier, toute modification doit être initiée par l'administration", style: TextStyle(fontSize: 10.5, color: noir)),
        const Text("N.B2: Aucune modification n'est permise sans autorisation expresse du responsable pédagogique", style: TextStyle(fontSize: 10.5, color: noir)),
        const Text("N.B3: Toute modification du présent programme vous sera communiquée à l'avance par le responsable pédagogique", style: TextStyle(fontSize: 10.5, color: noir)),
        const Text('Enfin, cet emploi du temps peut être modifié à tout moment', style: TextStyle(fontSize: 10.5, color: noir)),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerRight, child: Text('Fait à Ouagadougou, le ${n.day} ${_moisLongs[n.month - 1]} ${n.year}', style: const TextStyle(fontSize: 11, color: noir))),
        if (_responsable.isNotEmpty) ...[
          const SizedBox(height: 4),
          Align(alignment: Alignment.centerRight, child: Text('Le Responsable Pédagogique : $_responsable', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: noir))),
        ],
      ]),
    );
  }

  // ── Étape 3 ─────────────────────────────────────────────────────────────
  List<String> _conflits() {
    final out = <String>[];
    for (var i = 0; i < _creneaux.length; i++) {
      for (var j = i + 1; j < _creneaux.length; j++) {
        final a = _creneaux[i], b = _creneaux[j];
        if (a.jour != b.jour) continue;
        final a0 = _minutes(a.heureDebut), a1 = _minutes(a.heureFin), b0 = _minutes(b.heureDebut), b1 = _minutes(b.heureFin);
        if (a0 == null || a1 == null || b0 == null || b1 == null) continue;
        if (a0 < b1 && b0 < a1) {
          if (a.salle.trim().isNotEmpty && a.salle.trim().toLowerCase() == b.salle.trim().toLowerCase()) {
            out.add('${a.jour} : la salle ${a.salle} est utilisée par « ${a.matiere} » et « ${b.matiere} » en même temps.');
          } else if (a.prof.isNotEmpty && a.prof == b.prof) {
            out.add('${a.jour} : ${a.prof} a deux cours en même temps (« ${a.matiere} » et « ${b.matiere} »).');
          } else {
            out.add('${a.jour} : « ${a.matiere} » et « ${b.matiere} » se chevauchent.');
          }
        }
      }
    }
    return out;
  }

  Widget _etape3(bool isDesktop) {
    final conflits = _conflits();
    final f = _filiere;
    Widget info(IconData ic, String label, String val) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(children: [
        Icon(ic, size: 18, color: _blue), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          Text(val, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _navy)),
        ])),
      ]),
    );

    final cases = [
      info(Icons.account_tree_rounded, 'Filière', f?.nom ?? widget.existant?.filiereNom ?? '—'),
      info(Icons.layers_rounded, 'Niveau', _niveau ?? '—'),
      info(Icons.calendar_today_rounded, 'Année académique', _annee),
      info(Icons.date_range_rounded, 'Période', '${_d(_dateDebut)} → ${_d(_dateFin)}'),
      info(Icons.event_note_rounded, 'Créneaux', '${_creneaux.length} (${_formatDuree(_creneaux)} de cours)'),
      info(Icons.groups_rounded, 'Étudiants concernés', _niveau == null || f == null ? '—' : '${f.parNiveau[_niveau] ?? 0}'),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _titreEtape(3, 'Vérification et publication', 'Contrôlez les informations avant d\'enregistrer le planning.'),
      LayoutBuilder(builder: (ctx, c) {
        final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
        return GridView.count(
          crossAxisCount: cols, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 82, children: cases,
        );
      }),
      const SizedBox(height: 16),
      if (conflits.isEmpty)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFA7F3D0))),
          child: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 19), SizedBox(width: 10),
            Expanded(child: Text('Aucun conflit détecté (salles, professeurs, horaires).', style: TextStyle(fontSize: 12.5, color: Color(0xFF047857), fontWeight: FontWeight.w600))),
          ]),
        )
      else
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFDE68A))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 19), const SizedBox(width: 10),
              Text('${conflits.length} point${conflits.length > 1 ? 's' : ''} à vérifier', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
            ]),
            const SizedBox(height: 8),
            for (final t in conflits) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $t', style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)))),
          ]),
        ),
      const SizedBox(height: 20),
      const Text('Aperçu du programme (format remis aux étudiants)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _navy)),
      const SizedBox(height: 10),
      _tableauOfficiel(),
      const SizedBox(height: 18),
      _barreBas(
        gauche: const Text("L'emploi du temps sera enregistré ; vous pourrez ensuite notifier les étudiants.", style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        retour: () => setState(() => _step = 1),
        libelle: _edition ? 'Mettre à jour et publier' : 'Enregistrer et publier', icone: Icons.send_rounded,
        action: _saving ? null : _publier,
      ),
    ]);
  }

  Future<void> _publier() async {
    if (_creneaux.isEmpty) { _snack('⚠️ Ajoutez au moins un créneau.'); return; }
    if (_filiereId == null || _niveau == null || _dateDebut == null || _dateFin == null) { _snack('⚠️ Informations générales incomplètes.'); return; }
    setState(() => _saving = true);

    String iso(DateTime d) => d.toIso8601String().split('T').first;
    final payload = {
      'filiere': _filiereId,
      'niveau': _niveau,
      'anneeAcademique': _annee,
      'creneaux': _creneaux.map((c) => c.toJson()).toList(),
      'dateDebut': iso(_dateDebut!),
      'dateFin': iso(_dateFin!),
    };
    final result = widget.existant == null
        ? await ApiService.createEdtGrille(payload)
        : await ApiService.updateEdtGrille(widget.existant!.id, payload);
    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] != true) {
      _snack(result['error'] as String? ?? "Erreur lors de l'enregistrement.");
      return;
    }

    final newId = (widget.existant?.id ?? (result['data'] is Map ? result['data']['id'] : null))?.toString();
    final nomFiliere = _filiere?.nom ?? widget.existant?.filiereNom ?? '';
    if (newId != null) {
      final envoyer = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Emploi du temps enregistré', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          content: Text('Envoyer une notification aux étudiants de $nomFiliere — $_niveau ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Plus tard')),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white),
              icon: const Icon(Icons.send_rounded, size: 17),
              label: const Text('Envoyer aux étudiants'),
            ),
          ],
        ),
      ) ?? false;
      if (envoyer && mounted) {
        final env = await ApiService.envoyerEdt(newId);
        if (mounted) {
          _snack(env['success'] == true
              ? ((env['total'] ?? 0) == 0 ? 'Aucun étudiant trouvé pour cette filière et ce niveau.' : 'Emploi du temps envoyé à ${env['notifies'] ?? 0} étudiant(s).')
              : (env['error'] as String? ?? "Erreur lors de l'envoi."), erreur: env['success'] != true);
        }
      }
    }
    if (!mounted) return;
    _snack('✅ Emploi du temps enregistré avec succès.', erreur: false);
    widget.onClose(true);
  }
}
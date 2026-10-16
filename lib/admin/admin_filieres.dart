import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../admin/admin_edt.dart';
import '../admin/admin_notes.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_widgets.dart';
import '../models/student_profile.dart';
import '../pages/groupe_filiere_screen.dart';
import '../services/api_service.dart';
import '../services/professor_service.dart';
import '../utils/snackbar_helper.dart';

const Color _navy = Color(0xFF0B1E4D);
const Color _blue = Color(0xFF1565E0);
const String _domTech = 'Sciences & Technologies';
const String _domGestion = 'Sciences de Gestion';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES
// ════════════════════════════════════════════════════════════════════════════
class Module {
  final String id, nom, code;
  final int coefficient, volumeHoraire;
  String professeur;
  Module({required this.id, required this.nom, required this.code,
      required this.coefficient, required this.volumeHoraire,
      required this.professeur});

  factory Module.fromApi(Map<String, dynamic> json) => Module(
        id: json['id'].toString(),
        nom: json['nom'] as String? ?? '',
        code: '',
        coefficient: ((json['coefficient'] as num?) ?? 1).round(),
        volumeHoraire: (json['volume_horaire'] as num?)?.round() ?? 0,
        professeur: (json['professeur'] as String?)?.trim() ?? '',
      );
}

/// Filière — construite à partir de GET /api/filieres (données réelles :
/// effectifs, niveaux et nombre de modules calculés côté serveur).
class Filiere {
  final String id, nom, abreviation, niveau, domaine, anneeAcademique;
  final List<Module> modules;
  int nbEtudiants;
  int nbModules;
  bool active;
  String? backendId;
  String responsable;
  String statut;
  List<String> niveaux;
  Map<String, int> parNiveau;
  Filiere({required this.id, required this.nom, required this.abreviation, required this.niveau,
      required this.domaine, required this.anneeAcademique,
      required this.modules, this.nbEtudiants = 0, this.nbModules = 0, this.active = true,
      this.backendId, this.responsable = '', this.statut = '', this.niveaux = const [], this.parNiveau = const {}});

  factory Filiere.fromApi(Map<String, dynamic> j) {
    final nom = (j['nom'] ?? '').toString().trim();
    final desc = (j['description'] ?? '').toString();
    final niveaux = ((j['niveaux'] as List?) ?? const [])
        .map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();

    var domaine = (j['domaine_col'] ?? j['domaine'] ?? '').toString().trim();
    if (domaine.isEmpty) {
      final part = desc.split('·').first.trim();
      domaine = part.startsWith('Sciences') ? part : _domaineFromNom(nom);
    }
    var abrev = (j['abreviation'] ?? '').toString().trim();
    if (abrev.isEmpty) abrev = _deriveAbrev(nom);

    final now = DateTime.now();
    final y = now.month >= 9 ? now.year : now.year - 1;

    return Filiere(
      id: j['id'].toString(),
      backendId: j['id'].toString(),
      nom: nom,
      abreviation: abrev,
      niveau: niveaux.map(_abrevNiveau).join(', '),
      niveaux: niveaux,
      parNiveau: ((j['par_niveau'] as Map?) ?? const {}).map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
      domaine: domaine,
      anneeAcademique: '$y-${y + 1}',
      modules: [],
      nbEtudiants: (j['nb_etudiants'] as num?)?.toInt() ?? 0,
      nbModules: (j['nb_modules'] as num?)?.toInt() ?? 0,
      responsable: (j['responsable'] ?? '').toString().trim(),
      statut: (j['statut'] ?? '').toString().trim(),
    );
  }
}

/// Liste partagée (utilisée par admin_evaluations.dart) : alimentée avec les
/// vraies filières du backend. [chargerAdminFilieres] la remplit à la demande.
final List<Filiere> adminFilieres = [];

Future<void> chargerAdminFilieres() async {
  final res = await ApiService.getFilieres();
  if (res['success'] != true) return;
  final list = (res['data'] as List<dynamic>)
      .map((e) => Filiere.fromApi(Map<String, dynamic>.from(e as Map)))
      .toList();
  adminFilieres..clear()..addAll(list);
}

String _abrevNiveau(String n) {
  final t = n.trim();
  final m = RegExp(r'^(licence|master)\s*(\d)$', caseSensitive: false).firstMatch(t);
  if (m == null) return t;
  return '${m.group(1)!.toLowerCase() == 'licence' ? 'L' : 'M'}${m.group(2)}';
}

String _deriveAbrev(String nom) {
  const stop = {'et', 'de', 'des', 'du', 'la', 'le', 'les', 'en', 'd', '&', 'l'};
  final words = nom.split(RegExp(r"[\s'’-]+")).where((w) => w.isNotEmpty && !stop.contains(w.toLowerCase())).toList();
  if (words.isEmpty) return '';
  if (words.length == 1) {
    final w = words.first;
    return (w.length <= 3 ? w : w.substring(0, 3)).toUpperCase();
  }
  return words.map((w) => w[0]).join().toUpperCase();
}

String _domaineFromNom(String nom) {
  final n = nom.toLowerCase();
  const gestion = ['gestion', 'compta', 'marketing', 'commerc', 'financ', 'communication', 'management', 'banque', 'assurance'];
  return gestion.any(n.contains) ? _domGestion : _domTech;
}

IconData _iconFiliere(String nom) {
  final n = nom.toLowerCase();
  if (n.contains('réseau') || n.contains('reseau') || n.contains('télécom') || n.contains('telecom')) return Icons.hub_rounded;
  if (n.contains('électro') || n.contains('electro') || n.contains('énergie') || n.contains('energie')) return Icons.bolt_rounded;
  if (n.contains('marketing') || n.contains('communication')) return Icons.campaign_rounded;
  if (n.contains('civil') || n.contains('bâtiment') || n.contains('batiment')) return Icons.settings_rounded;
  if (n.contains('compta') || n.contains('financ')) return Icons.account_balance_rounded;
  if (n.contains('gestion')) return Icons.bar_chart_rounded;
  if (n.contains('informatique') || n.contains('logiciel')) return Icons.computer_rounded;
  if (n.contains('science') || n.contains('techno')) return Icons.science_rounded;
  return Icons.school_rounded;
}

const List<Color> _palette = [
  Color(0xFF1D4ED8), Color(0xFFF59E0B), Color(0xFF7C3AED),
  Color(0xFF10B981), Color(0xFFEF4444), Color(0xFF2563EB),
];
Color _colorFiliere(Filiere f) {
  final id = int.tryParse(f.backendId ?? '') ?? f.nom.hashCode.abs();
  return _palette[id % _palette.length];
}

// ════════════════════════════════════════════════════════════════════════════
// PAGE FILIÈRES & MODULES
// ════════════════════════════════════════════════════════════════════════════
class AdminFilieres extends StatefulWidget {
  final StudentProfile profile;
  const AdminFilieres({super.key, required this.profile});
  @override State<AdminFilieres> createState() => _AdminFilieresState();
}

class _AdminFilieresState extends State<AdminFilieres> {
  static const int _parPage = 6;

  List<Filiere> _filieres = [];
  bool _loading = true;
  String? _error;

  String _query = '';
  String? _filtreFiliere; // backendId
  String? _filtreDomaine;
  String? _filtreNiveau;
  bool _vueCartes = true;
  int _page = 1;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.profile.filtreParDomaine) _filtreDomaine = widget.profile.domaineAdmin;
    _charger();
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _charger({bool silencieux = false}) async {
    if (!silencieux) setState(() { _loading = true; _error = null; });
    final res = await ApiService.getFilieres();
    if (!mounted) return;
    if (res['success'] != true) {
      setState(() { _loading = false; _error = res['error']?.toString() ?? 'Erreur de chargement.'; });
      return;
    }
    final list = (res['data'] as List<dynamic>)
        .map((e) => Filiere.fromApi(Map<String, dynamic>.from(e as Map)))
        .toList();
    adminFilieres..clear()..addAll(list);
    setState(() { _filieres = list; _loading = false; _error = null; });
  }

  // Filières visibles pour cet admin (restriction par domaine si nécessaire)
  List<Filiere> get _visibles => widget.profile.filtreParDomaine
      ? _filieres.where((f) => f.domaine == widget.profile.domaineAdmin).toList()
      : _filieres;

  List<Filiere> get _filtered => _visibles.where((f) {
    final q = _query.trim().toLowerCase();
    final matchQ = q.isEmpty ||
        f.nom.toLowerCase().contains(q) ||
        f.abreviation.toLowerCase().contains(q);
    final matchF = _filtreFiliere == null || f.backendId == _filtreFiliere;
    final matchD = _filtreDomaine == null || f.domaine == _filtreDomaine;
    final matchN = _filtreNiveau == null || f.niveaux.contains(_filtreNiveau);
    return matchQ && matchF && matchD && matchN;
  }).toList();

  List<String> get _tousNiveaux {
    final s = <String>{};
    for (final f in _visibles) { s.addAll(f.niveaux); }
    final l = s.toList()..sort();
    return l;
  }

  List<Filiere> get _pageItems {
    final all = _filtered;
    final start = (_page - 1) * _parPage;
    if (start >= all.length) return all.take(_parPage).toList();
    return all.skip(start).take(_parPage).toList();
  }

  int get _nbPages {
    final n = _filtered.length;
    return n == 0 ? 1 : ((n + _parPage - 1) ~/ _parPage);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdminTheme.isDesktop(context);
    final pad = isDesktop ? 24.0 : 14.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _erreur()
              : RefreshIndicator(
                  onRefresh: () => _charger(silencieux: true),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(pad),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _header(isDesktop),
                      const SizedBox(height: 18),
                      _kpiRow(isDesktop),
                      const SizedBox(height: 16),
                      _barreFiltres(isDesktop),
                      const SizedBox(height: 18),
                      _enteteListe(),
                      const SizedBox(height: 12),
                      if (_filtered.isEmpty)
                        _vide()
                      else if (_vueCartes)
                        _grille(isDesktop)
                      else
                        _tableau(),
                      const SizedBox(height: 14),
                      _pied(),
                    ]),
                  ),
                ),
    );
  }

  Widget _erreur() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.cloud_off_rounded, size: 44, color: Color(0xFF94A3B8)),
    const SizedBox(height: 12),
    Text(_error ?? '', style: const TextStyle(color: Color(0xFF64748B))),
    const SizedBox(height: 12),
    ElevatedButton(onPressed: _charger, child: const Text('Réessayer')),
  ]));

  // ── Bandeau titre + photo ───────────────────────────────────────────────
  Widget _header(bool isDesktop) {
    final bouton = ElevatedButton.icon(
      onPressed: _ouvrirCreation,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Nouvelle filière', style: TextStyle(fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _navy, foregroundColor: Colors.white, elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    final titre = Row(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 30),
      ),
      const SizedBox(width: 16),
      Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Text('Filières & Modules', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _navy, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        const Text("Gérez les filières, les niveaux d'études et les modules de votre établissement.",
            style: TextStyle(fontSize: 13.5, color: Color(0xFF475569))),
      ])),
    ]);

    if (!isDesktop) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          titre, const SizedBox(height: 14), SizedBox(width: double.infinity, child: bouton),
        ]),
      );
    }

    return Container(
      height: 118,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(children: [
          Positioned(
            top: 0, bottom: 0, right: 0, width: 560,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => const LinearGradient(
                colors: [Colors.transparent, Colors.white], stops: [0.0, 0.45],
              ).createShader(r),
              child: Image.asset('assets/images/etablissement_banner.png',
                  fit: BoxFit.cover, alignment: Alignment.centerRight,
                  errorBuilder: (_, __, ___) => const SizedBox()),
            ),
          ),
          Positioned(
            right: -40, bottom: -22,
            child: Transform.rotate(angle: -0.13,
                child: Container(width: 340, height: 30, color: const Color(0xFFF5B800))),
          ),
          Positioned.fill(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(children: [
              Expanded(child: titre),
              const SizedBox(width: 16),
              bouton,
            ]),
          )),
        ]),
      ),
    );
  }

  // ── KPI ─────────────────────────────────────────────────────────────────
  Widget _kpiRow(bool isDesktop) {
    final v = _visibles;
    final totalEtu = v.fold<int>(0, (s, f) => s + f.nbEtudiants);
    final totalMod = v.fold<int>(0, (s, f) => s + f.nbModules);
    final niv = _tousNiveaux;

    final cards = [
      _kpi(Icons.school_rounded, const Color(0xFF1D4ED8), 'Filières', '${v.length}', 'Filières enregistrées'),
      _kpi(Icons.groups_rounded, const Color(0xFF10B981), 'Étudiants', '$totalEtu', 'Total des étudiants inscrits'),
      _kpi(Icons.menu_book_rounded, const Color(0xFF7C3AED), 'Modules', '$totalMod', 'Tous les modules confondus'),
      _kpi(Icons.layers_rounded, const Color(0xFFF59E0B), "Niveaux d'études", '${niv.length}',
          niv.isEmpty ? 'Aucun étudiant rattaché' : niv.map(_abrevNiveau).join(', ')),
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
      mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 112,
      children: cards,
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
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _navy, height: 1.1)),
        const SizedBox(height: 4),
        Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
      ])),
    ]),
  );

  // ── Barre de filtres ────────────────────────────────────────────────────
  Widget _barreFiltres(bool isDesktop) {
    final search = Container(
      height: 46,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() { _query = v; _page = 1; }),
        style: const TextStyle(fontSize: 13.5),
        decoration: const InputDecoration(
          hintText: 'Rechercher une filière par nom ou code...',
          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 19),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );

    final dFiliere = _FDrop<Filiere>(
      icon: Icons.account_tree_rounded, hint: 'Toutes les filières',
      value: _visibles.where((f) => f.backendId == _filtreFiliere).isEmpty
          ? null : _visibles.firstWhere((f) => f.backendId == _filtreFiliere),
      items: _visibles, labelOf: (f) => f.abreviation.isEmpty ? f.nom : '${f.abreviation} — ${f.nom}',
      onChanged: (f) => setState(() { _filtreFiliere = f?.backendId; _page = 1; }),
    );
    final dDomaine = _FDrop<String>(
      icon: Icons.category_rounded, hint: 'Tous les domaines',
      value: _filtreDomaine,
      items: widget.profile.filtreParDomaine ? [widget.profile.domaineAdmin] : const [_domTech, _domGestion],
      labelOf: (d) => d,
      onChanged: (d) => setState(() { _filtreDomaine = d; _page = 1; }),
    );
    final dNiveau = _FDrop<String>(
      icon: Icons.layers_rounded, hint: 'Tous les niveaux',
      value: _filtreNiveau, items: _tousNiveaux, labelOf: (n) => n,
      onChanged: (n) => setState(() { _filtreNiveau = n; _page = 1; }),
    );
    final toggle = _toggleVue();

    if (isDesktop) {
      return Row(children: [
        Expanded(flex: 4, child: search), const SizedBox(width: 12),
        Expanded(flex: 3, child: dFiliere), const SizedBox(width: 12),
        Expanded(flex: 3, child: dDomaine), const SizedBox(width: 12),
        Expanded(flex: 3, child: dNiveau), const SizedBox(width: 12),
        toggle,
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      search, const SizedBox(height: 10),
      dFiliere, const SizedBox(height: 10),
      Row(children: [Expanded(child: dDomaine), const SizedBox(width: 10), Expanded(child: dNiveau)]),
      const SizedBox(height: 10),
      toggle,
    ]);
  }

  Widget _toggleVue() {
    Widget btn(String label, IconData icon, bool actif, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: actif ? _blue : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: actif ? _blue : const Color(0xFFE2E8F0)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: actif ? Colors.white : _navy),
          const SizedBox(width: 6),
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

  Widget _enteteListe() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Row(children: [
      const Icon(Icons.school_rounded, color: _blue, size: 20),
      const SizedBox(width: 8),
      Expanded(child: Text('Toutes les filières (${_visibles.length})',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _navy))),
      Text('${_filtered.length} filière${_filtered.length > 1 ? 's' : ''} trouvée${_filtered.length > 1 ? 's' : ''}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
    ]),
  );

  // ── Grille de cartes ────────────────────────────────────────────────────
  Widget _grille(bool isDesktop) => LayoutBuilder(builder: (ctx, c) {
    final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols, mainAxisSpacing: 16, crossAxisSpacing: 16, mainAxisExtent: 262,
      ),
      itemCount: _pageItems.length,
      itemBuilder: (_, i) => _carteFiliere(_pageItems[i]),
    );
  });

  Widget _carteFiliere(Filiere f) {
    final color = _colorFiliere(f);
    final niveauxTxt = f.niveaux.isEmpty ? '—' : f.niveaux.map(_abrevNiveau).join(', ');

    Widget stat(IconData ic, String val, String label, {String? sub}) => Expanded(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(ic, size: 16, color: _blue), const SizedBox(width: 6),
          Flexible(child: Text(val, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _navy))),
        ]),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
        if (sub != null) Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
      ]));

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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(13)),
                  child: Icon(_iconFiliere(f.nom), color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f.abreviation, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _navy)),
                  const SizedBox(height: 2),
                  Text(f.nom, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                ])),
                if (f.statut.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(20)),
                    child: Text(f.statut, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF047857))),
                  ),
              ]),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                stat(Icons.groups_rounded, '${f.nbEtudiants}', 'Étudiants'),
                stat(Icons.layers_rounded, f.niveaux.isEmpty ? '0' : '${f.niveaux.length}', 'Niveaux', sub: f.niveaux.isEmpty ? null : '($niveauxTxt)'),
                stat(Icons.menu_book_rounded, '${f.nbModules}', 'Modules'),
              ]),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 10),
              SizedBox(height: 18, child: f.responsable.isEmpty
                  ? const SizedBox()
                  : Row(children: [
                      const Icon(Icons.person_rounded, size: 15, color: Color(0xFF334155)),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Responsable : ${f.responsable}', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)))),
                    ])),
              const Spacer(),
              Row(children: [
                Expanded(child: ElevatedButton.icon(
                  onPressed: () => _ouvrirDetail(f, tab: 1),
                  icon: const Icon(Icons.visibility_rounded, size: 15),
                  label: const Text('Voir les détails', maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0,
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _ouvrirDetail(f, tab: 0),
                  icon: const Icon(Icons.settings_rounded, size: 15),
                  label: const Text('Gérer les modules', maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy, side: const BorderSide(color: Color(0xFFCBD5E1)),
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )),
                const SizedBox(width: 8),
                _menuFiliere(f),
              ]),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _menuFiliere(Filiere f) => PopupMenuButton<String>(
    tooltip: 'Plus d\'actions',
    position: PopupMenuPosition.under,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    onSelected: (v) {
      if (v == 'edit') _modifier(f);
      if (v == 'delete') _supprimer(f);
    },
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 16), SizedBox(width: 8), Text('Modifier')])),
      PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: Color(0xFFEF4444)))])),
    ],
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))),
      child: const Icon(Icons.more_horiz_rounded, size: 18, color: _navy),
    ),
  );

  // ── Vue tableau ─────────────────────────────────────────────────────────
  Widget _tableau() {
    Widget cell(String t, double w, {bool bold = false, Color? color}) => SizedBox(
      width: w, child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12.5, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color ?? const Color(0xFF334155))));
    const widths = [80.0, 240.0, 170.0, 90.0, 120.0, 80.0, 190.0, 50.0];
    const heads = ['Code', 'Filière', 'Domaine', 'Étudiants', 'Niveaux', 'Modules', 'Responsable', ''];
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF8FAFC),
            child: Row(children: [for (var i = 0; i < heads.length; i++) cell(heads[i], widths[i], bold: true, color: _navy)]),
          ),
          for (final f in _pageItems) InkWell(
            onTap: () => _ouvrirDetail(f, tab: 1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
              child: Row(children: [
                cell(f.abreviation, widths[0], bold: true, color: _colorFiliere(f)),
                cell(f.nom, widths[1], bold: true),
                cell(f.domaine, widths[2]),
                cell('${f.nbEtudiants}', widths[3]),
                cell(f.niveaux.isEmpty ? '—' : f.niveaux.map(_abrevNiveau).join(', '), widths[4]),
                cell('${f.nbModules}', widths[5]),
                cell(f.responsable.isEmpty ? '—' : f.responsable, widths[6]),
                SizedBox(width: widths[7], child: _menuFiliere(f)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Pied : compteur + pagination ────────────────────────────────────────
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
      Expanded(child: Text('Affichage de $debut à $fin sur $total filière${total > 1 ? 's' : ''}',
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)))),
      nav(Icons.arrow_back_rounded, _page > 1, () => setState(() => _page--)),
      const SizedBox(width: 6),
      for (var p = 1; p <= _nbPages; p++) ...[
        GestureDetector(
          onTap: () => setState(() => _page = p),
          child: Container(
            width: 34, height: 34, alignment: Alignment.center,
            decoration: BoxDecoration(color: p == _page ? _blue : Colors.white, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p == _page ? _blue : const Color(0xFFE2E8F0))),
            child: Text('$p', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p == _page ? Colors.white : _navy)),
          ),
        ),
        const SizedBox(width: 6),
      ],
      nav(Icons.arrow_forward_rounded, _page < _nbPages, () => setState(() => _page++)),
    ]);
  }

  // ── Actions ─────────────────────────────────────────────────────────────
  void _ouvrirDetail(Filiere f, {int tab = 0}) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailFiliere(
        profile: widget.profile, filiere: f, initialTab: tab,
        onEdit: () => setState(() {})),
    ).then((_) => _charger(silencieux: true));
  }

  void _ouvrirCreation() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreationFiliere(onCreated: (f) async { await _charger(silencieux: true); }),
    );
  }

  void _modifier(Filiere f) {
    final nomCtrl = TextEditingController(text: f.nom);
    final abrCtrl = TextEditingController(text: f.abreviation);
    final respCtrl = TextEditingController(text: f.responsable);
    String domaine = f.domaine;
    bool envoi = false;

    InputDecoration deco(String label) => InputDecoration(
      labelText: label, isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );

    showDialog(context: context, builder: (dCtx) => StatefulBuilder(builder: (dCtx, setD) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Modifier la filière', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      content: SizedBox(width: 380, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nomCtrl, decoration: deco('Nom de la filière')),
        const SizedBox(height: 12),
        TextField(controller: abrCtrl, decoration: deco('Code / abréviation (ex : RIT)')),
        const SizedBox(height: 12),
        TextField(controller: respCtrl, decoration: deco('Responsable (ex : Dr. SOME Karim)')),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: Wrap(spacing: 8, children: [
          for (final d in const [_domTech, _domGestion])
            ChoiceChip(label: Text(d, style: const TextStyle(fontSize: 12)), selected: domaine == d,
                onSelected: (_) => setD(() => domaine = d)),
        ])),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: envoi ? null : () async {
            if (nomCtrl.text.trim().isEmpty) return;
            setD(() => envoi = true);
            final res = await ApiService.updateFiliere(
              id: f.backendId!, nom: nomCtrl.text.trim(),
              abreviation: abrCtrl.text.trim(), domaine: domaine,
              responsable: respCtrl.text.trim(),
            );
            if (!mounted) return;
            if (dCtx.mounted) Navigator.pop(dCtx);
            if (res['success'] == true) {
              await _charger(silencieux: true);
              if (!mounted) return;
              if (res['partial'] == true) {
                showAppSnackBar(context, 'Nom enregistré. Pour sauvegarder code, domaine et responsable, exécute le SQL de migration (colonnes manquantes).', backgroundColor: const Color(0xFFF59E0B));
              } else {
                showAppSnackBar(context, 'Filière mise à jour.');
              }
            } else {
              showAppSnackBar(context, res['error']?.toString() ?? 'Erreur de modification.', backgroundColor: AdminTheme.danger);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0),
          child: const Text('Enregistrer'),
        ),
      ],
    )));
  }

  Future<void> _supprimer(Filiere f) async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Supprimer la filière ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      content: Text('« ${f.nom} » sera supprimée définitivement. Impossible si des étudiants ou des modules y sont rattachés.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () => Navigator.pop(c, true),
          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.danger, foregroundColor: Colors.white, elevation: 0),
          child: const Text('Supprimer'),
        ),
      ],
    ));
    if (ok != true || f.backendId == null) return;
    final res = await ApiService.deleteFiliere(f.backendId!);
    if (!mounted) return;
    if (res['success'] == true) {
      await _charger(silencieux: true);
      if (!mounted) return;
      showAppSnackBar(context, 'Filière supprimée.');
    } else {
      showAppSnackBar(context, res['error']?.toString() ?? 'Erreur de suppression.', backgroundColor: AdminTheme.danger);
    }
  }

  Widget _vide() => Container(
    padding: const EdgeInsets.symmetric(vertical: 48),
    alignment: Alignment.center,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 64, height: 64,
        decoration: BoxDecoration(color: AdminTheme.iconBg, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.school_outlined, color: AdminTheme.iconFg, size: 32)),
      const SizedBox(height: 14),
      const Text('Aucune filière trouvée', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _navy)),
    ]),
  );
}

// ── Liste déroulante (PopupMenuButton — jamais DropdownButton sur Flutter Web)
class _FDrop<T> extends StatelessWidget {
  final IconData icon;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  const _FDrop({required this.icon, required this.hint, required this.value,
      required this.items, required this.labelOf, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 360),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (i) => onChanged(i < 0 ? null : items[i]),
      itemBuilder: (_) => [
        PopupMenuItem<int>(value: -1, child: Text(hint, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        for (var i = 0; i < items.length; i++)
          PopupMenuItem<int>(value: i, child: Text(labelOf(items[i]), style: const TextStyle(fontSize: 13))),
      ],
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Row(children: [
          Icon(icon, size: 16, color: const Color(0xFF475569)),
          const SizedBox(width: 8),
          Expanded(child: Text(value != null ? labelOf(value as T) : hint, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: value != null ? _navy : const Color(0xFF475569)))),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DÉTAIL FILIÈRE — Bottom Sheet
// ════════════════════════════════════════════════════════════════════════════
class _DetailFiliere extends StatefulWidget {
  final StudentProfile profile;
  final Filiere filiere;
  final VoidCallback onEdit;
  final int initialTab;
  const _DetailFiliere({required this.profile, required this.filiere, required this.onEdit, this.initialTab = 0});
  @override State<_DetailFiliere> createState() => _DetailFiliereState();
}

class _DetailFiliereState extends State<_DetailFiliere>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _etudiants = [];
  bool _loadingEtudiants = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this, initialIndex: widget.initialTab.clamp(0, 2));
    _chargerModules();
    _chargerEtudiants();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  // Charge les modules réels de la filière (la liste ne les embarque plus).
  Future<void> _chargerModules() async {
    final id = widget.filiere.backendId;
    if (id == null) return;
    final res = await ApiService.getModules(filiereId: id);
    if (!mounted || res['success'] != true) return;
    setState(() {
      widget.filiere.modules
        ..clear()
        ..addAll((res['data'] as List<dynamic>).map((m) => Module.fromApi(Map<String, dynamic>.from(m as Map))));
    });
  }

  Future<void> _chargerEtudiants() async {
    var id = widget.filiere.backendId;
    // Filière pas encore rattachée au backend : on tente le rattachement ici.
    if (id == null) {
      final res = await ApiService.getFilieres();
      if (res['success'] == true) {
        final matches = (res['data'] as List<dynamic>).where((bf) =>
            (bf['nom'] as String).trim().toLowerCase() ==
            widget.filiere.nom.trim().toLowerCase());
        if (matches.isNotEmpty) {
          widget.filiere.backendId = matches.first['id'].toString();
          id = widget.filiere.backendId;
        }
      }
    }
    if (id == null) {
      if (mounted) setState(() => _loadingEtudiants = false);
      return;
    }
    final res = await ProfessorService.getStudentsByFiliere(int.parse(id));
    if (!mounted) return;
    setState(() {
      _etudiants = res['success'] == true ? res['data'] as List<dynamic> : [];
      if (_etudiants.isNotEmpty) widget.filiere.nbEtudiants = _etudiants.length;
      _loadingEtudiants = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.filiere;
    final isST = f.domaine.contains('Technologies');
    final color = isST ? AdminTheme.primary : AdminTheme.info;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
        // Header
        Container(color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 42, height: 42,
                decoration: BoxDecoration(color: color.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(isST ? Icons.computer_rounded : Icons.business_center_rounded,
                    color: color, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.nom, style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                Text(f.niveau.isEmpty ? f.anneeAcademique : '${f.niveau} · ${f.anneeAcademique}',
                    style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
              ])),
              IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              _chip('${f.nbEtudiants} étudiants', Icons.people_rounded, color),
              const SizedBox(width: 8),
              _chip('${f.modules.length} modules', Icons.book_rounded, color),
              const SizedBox(width: 8),
              _chip(f.domaine.contains('Technologies') ? 'Sciences & Tech' : 'Sciences Gestion',
                  Icons.category_rounded, color),
            ]),
            const SizedBox(height: 14),
            TabBar(
              controller: _tab,
              labelColor: color, unselectedLabelColor: const Color(0xFF9CA3AF),
              indicatorColor: color,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [Tab(text: 'Modules'), Tab(text: 'Étudiants'), Tab(text: 'Actions')],
            ),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        Expanded(child: TabBarView(controller: _tab, children: [
          _tabModules(f, color),
          _tabEtudiants(f),
          _tabActions(f, color),
        ])),
      ]),
    );
  }

  Widget _tabModules(Filiere f, Color color) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Row(children: [
        Expanded(child: Text('${f.modules.length} modules · Coef total : ${f.modules.fold(0, (s, m) => s + m.coefficient)}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
        GestureDetector(
          onTap: () => _ajouterModule(f),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: color,
                borderRadius: BorderRadius.circular(8)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text('Ajouter module', style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      ...f.modules.map((m) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.03),
                blurRadius: 6, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.nom, style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 3),
            Text('${m.volumeHoraire}h · Coefficient ${m.coefficient}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text('Coef ${m.coefficient}', style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w800, color: color)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
            onPressed: () => _supprimerModule(f, m),
          ),
        ]),
      )),
    ],
  );

  Widget _tabEtudiants(Filiere f) {
    if (_loadingEtudiants) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_etudiants.isEmpty) {
      return Center(child: Text('Aucun étudiant inscrit en ${f.nom}',
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))));
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Row(children: [
          Expanded(child: Text('${_etudiants.length} étudiant(s) inscrit(s)',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
          GestureDetector(
            onTap: () => _exporterListePdf(f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: AdminTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.download_rounded, color: AdminTheme.primary, size: 16),
                SizedBox(width: 6),
                Text('Exporter liste PDF', style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w700, color: AdminTheme.primary)),
              ]),
            ),
          ),
        ]),
      ),
      Expanded(child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _etudiants.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final e = _etudiants[i];
          final prenoms = '${e['prenoms'] ?? ''}';
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            leading: CircleAvatar(
              backgroundColor: AdminTheme.primaryLight,
              child: Text(prenoms.isNotEmpty ? prenoms[0].toUpperCase() : '?',
                  style: const TextStyle(color: AdminTheme.primary, fontWeight: FontWeight.w700)),
            ),
            title: Text('$prenoms ${e['nom'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('${e['matricule'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          );
        },
      )),
    ]);
  }

  Future<void> _exporterListePdf(Filiere f) async {
    final doc = pw.Document();
    
    // Header
    final titleStyle = pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: const PdfColor(0.1, 0.3, 0.6));
    final subtitleStyle = pw.TextStyle(fontSize: 14, color: const PdfColor(0.3, 0.3, 0.3));

    doc.addPage(pw.MultiPage(
      pageFormat: const PdfPageFormat(21.0 * PdfPageFormat.cm, 29.7 * PdfPageFormat.cm, marginAll: 2.0 * PdfPageFormat.cm),
      build: (context) => [
        // En-tête
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('ScolarHub', style: titleStyle),
                pw.Text('Institut Supérieur de Technologie', style: subtitleStyle),
              ]
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Année académique', style: subtitleStyle.copyWith(fontSize: 10)),
                pw.Text(f.anneeAcademique, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ]
            )
          ]
        ),
        pw.SizedBox(height: 30),
        
        // Titre du document
        pw.Center(
          child: pw.Text('LISTE DES ÉTUDIANTS', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline))
        ),
        pw.SizedBox(height: 20),
        
        // Infos Filière
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(color: const PdfColor(0.95, 0.95, 0.95), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Filière : ${f.nom} (${f.abreviation})', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Niveau : ${f.niveau}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Effectif : ${_etudiants.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ]
          )
        ),
        pw.SizedBox(height: 20),

        // Tableau
        pw.TableHelper.fromTextArray(
          headers: ['N°', 'Matricule', 'Nom', 'Prénoms', 'Filière'],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColor(0.1, 0.3, 0.6)),
          cellHeight: 30,
          cellAlignments: {
            0: pw.Alignment.center,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.centerLeft,
            4: pw.Alignment.centerLeft,
          },
          data: [
            for (var i = 0; i < _etudiants.length; i++)
              [
                '${i + 1}',
                '${_etudiants[i]['matricule'] ?? ''}',
                '${_etudiants[i]['nom'] ?? ''}',
                '${_etudiants[i]['prenoms'] ?? ''}',
                f.abreviation,
              ],
          ],
        ),
      ],
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 10),
        child: pw.Text('Page ${context.pageNumber} sur ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
      ),
    ));
    await Printing.layoutPdf(name: 'Liste_${f.abreviation}_${f.niveau}.pdf', onLayout: (format) async => doc.save());
  }

  Widget _tabActions(Filiere f, Color color) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      _actionRow(Icons.campaign_rounded, 'Envoyer une annonce à la filière',
          'Cibler uniquement les étudiants de ${f.nom}', color, () => _envoyerAnnonce(f)),
      const SizedBox(height: 12),
      _actionRow(Icons.forum_rounded, 'Ouvrir le groupe de messagerie',
          'Voir le groupe privé de la filière', color, () => _ouvrirGroupe(f)),
      const SizedBox(height: 12),
      _actionRow(Icons.calendar_today_rounded, 'Emploi du temps',
          'Voir ou modifier l\'emploi du temps', color,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminEDT()))),
      const SizedBox(height: 12),
      _actionRow(Icons.grade_rounded, 'Notes de la filière',
          'Voir toutes les notes et moyennes', color,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminNotes(profile: widget.profile)))),
    ]),
  );

  void _envoyerAnnonce(Filiere f) {
    final titreCtrl = TextEditingController();
    final contenuCtrl = TextEditingController();
    bool envoi = false;

    showDialog(context: context, builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Annonce — ${f.nom}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(titreCtrl, 'Titre de l\'annonce', Icons.title_rounded),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB))),
            child: TextField(controller: contenuCtrl, maxLines: 5,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(hintText: 'Contenu du message...',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12))),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton.icon(
            icon: envoi
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 16),
            label: const Text('Envoyer'),
            onPressed: envoi ? null : () async {
              if (titreCtrl.text.trim().isEmpty || contenuCtrl.text.trim().isEmpty) return;
              setDialogState(() => envoi = true);
              final messenger = ScaffoldMessenger.of(context);

              final res = await ApiService.createAnnonce({
                'titre': titreCtrl.text.trim(),
                'contenu': contenuCtrl.text.trim(),
                'filiere': f.backendId ?? f.nom,
                'niveau': f.niveau,
                'cibleRole': 'etudiant',
              });
              if (!dialogCtx.mounted) return;
              if (res['success'] == true) {
                // L'annonce est créée en brouillon : on la publie aussitôt
                // pour qu'elle atteigne les étudiants de la filière.
                final id = res['data']?['id'];
                if (id != null) await ApiService.publierAnnonce(id.toString());
                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                messenger.showSnackBar(SnackBar(
                  content: Text('Annonce envoyée aux étudiants de ${f.nom}.'),
                  backgroundColor: const Color(0xFF1A3C34),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ));
              } else {
                setDialogState(() => envoi = false);
                messenger.showSnackBar(SnackBar(
                  content: Text(res['error'] as String? ?? 'Erreur lors de l\'envoi.'),
                  backgroundColor: AdminTheme.danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary,
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ],
      ),
    ));
  }

  void _ouvrirGroupe(Filiere f) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupeFiliere(
      profile: StudentProfile(
        nom: 'ScolarHub', prenoms: 'Administration', matricule: 'ADMIN',
        email: '', telephone: '', filiere: f.nom, motDePasse: '',
        niveau: f.niveau, role: 'admin',
      ),
    )));
  }

  Widget _actionRow(IconData icon, String titre, String sub, Color color,
      VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titre, style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ])),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
      ]),
    ),
  );

  Widget _chip(String label, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 12),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11,
          fontWeight: FontWeight.w700, color: color)),
    ]),
  );

  void _ajouterModule(Filiere f) {
    final nomCtrl  = TextEditingController();
    final coefCtrl = TextEditingController(text: '2');
    final vhCtrl   = TextEditingController(text: '30');
    bool envoi = false;

    // Liste des professeurs pour l'attribution du module
    final profsFuture = ApiService.getProfesseurs();
    String? profUserId;

    showDialog(context: context, builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ajouter un module',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(nomCtrl, 'Nom du module', Icons.book_rounded),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _field(coefCtrl, 'Coefficient', Icons.numbers_rounded,
                type: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _field(vhCtrl, 'Volume horaire (h)', Icons.schedule_rounded,
                type: TextInputType.number)),
          ]),
          const SizedBox(height: 10),
          // Attribution du module à un professeur (optionnelle)
          FutureBuilder<Map<String, dynamic>>(
            future: profsFuture,
            builder: (_, snap) {
              final profs = (snap.data?['success'] == true)
                  ? List<Map<String, dynamic>>.from(snap.data!['data'] as List)
                  : <Map<String, dynamic>>[];
              return DropdownButtonFormField<String>(
                initialValue: profUserId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Professeur (attribution)',
                  prefixIcon: const Icon(Icons.person_rounded, size: 20),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
                items: [
                  const DropdownMenuItem<String>(
                      value: null, child: Text('— Aucun pour l\'instant —')),
                  ...profs.map((p) => DropdownMenuItem<String>(
                        value: p['user_id'].toString(),
                        child: Text(
                            '${p['prenoms'] ?? ''} ${p['nom'] ?? ''}'.trim(),
                            overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (v) => setDialogState(() => profUserId = v),
              );
            },
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton(
            onPressed: envoi ? null : () async {
              if (nomCtrl.text.trim().isEmpty) return;
              setDialogState(() => envoi = true);
              final messenger = ScaffoldMessenger.of(context);

              if (f.backendId != null) {
                final result = await ApiService.createModule(
                  nom: nomCtrl.text.trim(),
                  coefficient: int.tryParse(coefCtrl.text) ?? 2,
                  volumeHoraire: int.tryParse(vhCtrl.text) ?? 30,
                  filiereId: int.tryParse(f.backendId!),
                  filiereNom: f.nom,
                  professeurUserId: profUserId,
                );
                if (!dialogCtx.mounted) return;
                if (result['success'] == true) {
                  setState(() => f.modules.add(Module.fromApi(result['data'] as Map<String, dynamic>)));
                  Navigator.pop(dialogCtx);
                } else {
                  setDialogState(() => envoi = false);
                  messenger.showSnackBar(SnackBar(
                    content: Text(result['error'] as String? ?? 'Erreur lors de l\'ajout du module.'),
                    backgroundColor: AdminTheme.danger,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ));
                }
              } else {
                // Filière non synchronisée avec le backend (ex: créée hors ligne) : ajout local uniquement.
                setState(() {
                  f.modules.add(Module(
                    id: 'M${f.modules.length + 100}',
                    nom: nomCtrl.text.trim(), code: '',
                    coefficient: int.tryParse(coefCtrl.text) ?? 2,
                    volumeHoraire: int.tryParse(vhCtrl.text) ?? 30,
                    professeur: '',
                  ));
                });
                Navigator.pop(dialogCtx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary,
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: envoi
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Ajouter'),
          ),
        ],
      ),
    ));
  }

  Future<void> _supprimerModule(Filiere f, Module m) async {
    if (f.backendId != null) {
      final result = await ApiService.deleteModule(m.id);
      if (!mounted) return;
      if (result['success'] != true) {
        showAppSnackBar(context, result['error'] as String? ?? 'Erreur lors de la suppression.', backgroundColor: AdminTheme.danger);
        return;
      }
    }
    setState(() => f.modules.removeWhere((mod) => mod.id == m.id));
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text}) =>
      Container(
        decoration: BoxDecoration(color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: TextField(controller: ctrl, keyboardType: type,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 16),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12))),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// CRÉATION FILIÈRE — Stepper 3 étapes
// ════════════════════════════════════════════════════════════════════════════
class _CreationFiliere extends StatefulWidget {
  final Future<void> Function(Filiere) onCreated;
  const _CreationFiliere({required this.onCreated});
  @override State<_CreationFiliere> createState() => _CreationFiliereState();
}

class _CreationFiliereState extends State<_CreationFiliere> {
  int _step = 0;
  final _nomCtrl    = TextEditingController();
  final _abbrCtrl   = TextEditingController(); // Nouveau contrôleur ajouté
  final _anneeCtrl  = TextEditingController(text: '2024-2025');
  String _niveau    = 'Licence 2';
  String _domaine   = 'Sciences & Technologies';
  final List<Map<String, dynamic>> _modules = [];

  // Méthode snack ajoutée pour éviter l'erreur de compilation
  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AdminTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            const Expanded(child: Text('Créer une filière',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E)))),
            IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                onPressed: () => Navigator.pop(context)),
          ]),
        ),
        // Stepper indicator
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: List.generate(3, (i) {
            final done   = i < _step;
            final active = i == _step;
            return Expanded(child: Row(children: [
              Expanded(child: Column(children: [
                AnimatedContainer(duration: const Duration(milliseconds: 200),
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: done ? AdminTheme.success
                        : active ? AdminTheme.primary : const Color(0xFFE5E7EB),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: done
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : Text('${i + 1}', style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: active ? Colors.white : const Color(0xFF9CA3AF))))),
                const SizedBox(height: 4),
                Text(['Informations', 'Modules', 'Confirmation'][i],
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: active ? AdminTheme.primary : const Color(0xFF9CA3AF))),
              ])),
              if (i < 2) Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 20),
                  color: done ? AdminTheme.success : const Color(0xFFE5E7EB))),
            ]));
          })),
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        

        // Contenu étape
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: [_etape1(), _etape2(), _etape3()][_step],
        )),

        // Navigation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
          child: Row(children: [
            if (_step > 0)
              Expanded(child: GestureDetector(
                onTap: () => setState(() => _step--),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: const Center(child: Text('Retour',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280)))),
                ),
              )),
            if (_step > 0) const SizedBox(width: 12),
            Expanded(flex: 2, child: GestureDetector(
              onTap: _step < 2
                  ? () { if (_validerEtape()) setState(() => _step++); }
                  : _creer,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: AdminTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AdminTheme.primary.withValues(alpha:0.3),
                      blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Center(child: Text(
                  _step < 2 ? 'Continuer →' : '✅ Créer la filière',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: Colors.white))),
              ),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _etape1() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Informations de la filière',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
    const SizedBox(height: 4),
    const Text('Remplissez les informations de base de la filière.',
        style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
    const SizedBox(height: 20),
    _label('Nom de la filière *'),
    _input(_nomCtrl, 'Ex: Réseaux Informatiques et Télécom', Icons.school_rounded),
    const SizedBox(height: 14),
    _label('Abréviation (ex:RIT)*'),
    _input(_abbrCtrl, 'Ex: RIT', Icons.short_text_rounded),
    const SizedBox(height: 14),
    _label('Niveau'),
    _select(_niveau, ['Licence 1', 'Licence 2', 'Licence 3', 'BTS 1', 'BTS 2'],
        (v) => setState(() => _niveau = v!)),
    const SizedBox(height: 14),
    _label('Domaine'),
    _select(_domaine, ['Sciences & Technologies', 'Sciences de Gestion'],
        (v) => setState(() => _domaine = v!)),
    const SizedBox(height: 14),
    _label('Année académique'),
    _input(_anneeCtrl, '2024-2025', Icons.calendar_today_rounded),
  ]);

  Widget _etape2() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Modules de la filière',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        SizedBox(height: 4),
        Text('Ajoutez les modules de cette filière.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
      ])),
      GestureDetector(
        onTap: _ajouterModuleForm,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: AdminTheme.primary,
              borderRadius: BorderRadius.circular(8)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text('Ajouter', style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      ),
    ]),
    const SizedBox(height: 16),
    if (_modules.isEmpty)
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: const Center(child: Text('Aucun module ajouté.\nCliquez sur "Ajouter" pour commencer.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)))))
    else
      ...List.generate(_modules.length, (i) {
        final m = _modules[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(
                color: AdminTheme.primary, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m['nom'] as String, style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              Text('Coef ${m['coef']} · ${m['vh']}h · ${m['prof']}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ])),
            GestureDetector(
              onTap: () => setState(() => _modules.removeAt(i)),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444), size: 18)),
          ]),
        );
      }),
  ]);

  Widget _etape3() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Confirmation',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
    const SizedBox(height: 4),
    const Text('Vérifiez les informations avant de créer la filière.',
        style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
    const SizedBox(height: 20),
    _resumeRow('Nom', _nomCtrl.text),
    _resumeRow('Niveau', _niveau),
    _resumeRow('Domaine', _domaine),
    _resumeRow('Année', _anneeCtrl.text),
    _resumeRow('Modules', '${_modules.length} module(s)'),
    const SizedBox(height: 16),
    Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AdminTheme.successLight,
          borderRadius: BorderRadius.circular(12)),
      child: const Row(children: [
        Icon(Icons.auto_awesome_rounded, color: AdminTheme.success, size: 18),
        SizedBox(width: 10),
        Expanded(child: Text(
          'Un groupe de messagerie privé sera créé automatiquement pour cette filière.',
          style: TextStyle(fontSize: 12, color: AdminTheme.success,
              fontWeight: FontWeight.w600))),
      ])),
  ]);

  Widget _resumeRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
      const SizedBox(width: 12),
      Expanded(child: Text(value, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)))),
    ]),
  );

  bool _validerEtape() {
    if (_step == 0 && _nomCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez saisir le nom de la filière.'),
        backgroundColor: AdminTheme.danger, behavior: SnackBarBehavior.floating));
      return false;
    }
    return true;
  }

  void _ajouterModuleForm() {
    final nomCtrl  = TextEditingController();
    final coefCtrl = TextEditingController(text: '2');
    final vhCtrl   = TextEditingController(text: '30');
    final profCtrl = TextEditingController();

    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Ajouter un module',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _inputSimple(nomCtrl, 'Nom du module'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _inputSimple(coefCtrl, 'Coefficient',
              type: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: _inputSimple(vhCtrl, 'Volume horaire (h)',
              type: TextInputType.number)),
        ]),
        const SizedBox(height: 10),
        _inputSimple(profCtrl, 'Professeur'),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF6B7280)))),
        ElevatedButton(
          onPressed: () {
            if (nomCtrl.text.isEmpty) return;
            setState(() => _modules.add({
              'nom': nomCtrl.text, 'coef': coefCtrl.text, 'vh': vhCtrl.text,
              'prof': profCtrl.text,
            }));
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary,
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Ajouter'),
        ),
      ],
    ));
  }

 
Future<void> _creer() async {
  if (_nomCtrl.text.isEmpty || _abbrCtrl.text.isEmpty) {
    _snack('Erreur : Nom et Abréviation requis !');
    return;
  }
  final f = Filiere(
    id: 'F${DateTime.now().millisecondsSinceEpoch}',
    nom: _nomCtrl.text,
    abreviation: _abbrCtrl.text, // Ajouté ici
    niveau: _niveau,
    domaine: _domaine,
    anneeAcademique: _anneeCtrl.text,
    modules: _modules.map((m) => Module(
      id: 'M${DateTime.now().millisecondsSinceEpoch}',
      nom: m['nom'] as String, code: '',
      coefficient: int.tryParse(m['coef'] as String) ?? 2,
      volumeHoraire: int.tryParse(m['vh'] as String) ?? 30,
      professeur: m['prof'] as String,
    )).toList(),
  );
  final result = await ApiService.createFiliere(
    nom: f.nom,
    description: '${f.domaine} · ${f.niveau}',
    abreviation: f.abreviation,
    domaine: f.domaine,
  );
  if (!mounted) return;
  if (result['success'] != true) {
    _snack(result['error']?.toString() ?? 'Erreur création filière.');
    return;
  }
  final data = result['data'] as Map<String, dynamic>;
  final filierePersisted = Filiere(
    id: data['id'].toString(),
    nom: data['nom']?.toString() ?? f.nom,
    abreviation: f.abreviation,
    niveau: f.niveau,
    domaine: f.domaine,
    anneeAcademique: f.anneeAcademique,
    modules: f.modules,
    backendId: data['id'].toString(),
  );
  // Les modules saisis dans l'assistant n'étaient jamais enregistrés : on les persiste.
  for (final m in _modules) {
    await ApiService.createModule(
      nom: (m['nom'] as String).trim(),
      coefficient: int.tryParse(m['coef'].toString()) ?? 2,
      volumeHoraire: int.tryParse(m['vh'].toString()) ?? 30,
      filiereId: int.tryParse(filierePersisted.backendId!),
      filiereNom: filierePersisted.nom,
    );
  }
  await widget.onCreated(filierePersisted);
  if (mounted) Navigator.pop(context);
}

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 13,
        fontWeight: FontWeight.w700, color: Color(0xFF374151))));

  Widget _input(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text}) =>
      Container(
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: TextField(controller: ctrl, keyboardType: type,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14))),
      );

  Widget _inputSimple(TextEditingController ctrl, String hint,
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11))),
      );

  Widget _select(String value, List<String> items, ValueChanged<String?> onChanged) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: value, isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
          items: items.map((v) => DropdownMenuItem(value: v,
              child: Text(v, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        )),
      );
}
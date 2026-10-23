import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_annonces.dart' show istNiveaux;
import '../admin/admin_notes.dart' show semestresPourNiveau;
import '../models/student_profile.dart';
import '../services/api_service.dart';
import '../services/bulletins_admin_service.dart';
import '../utils/snackbar_helper.dart';

const List<String> _appreciations = ['Très bien', 'Bien', 'Assez bien', 'Passable', 'Insuffisant'];

// Couleurs proposées pour les UE (côte à côte dans le tableau).
const List<String> _couleursUe = ['#1565C0', '#2E7D32', '#EF6C00', '#6A1B9A', '#00838F', '#C62828', '#5D4037', '#AD1457'];

Color _hex(String? h, {Color defaut = const Color(0xFF607D8B)}) {
  if (h == null || h.length != 7 || !h.startsWith('#')) return defaut;
  final v = int.tryParse(h.substring(1), radix: 16);
  return v == null ? defaut : Color(0xFF000000 | v);
}

// Colonne du tableau : soit un module, soit la moyenne d'une UE.
class _Col {
  final Map<String, dynamic>? module;
  final int? ueIndex;
  final Color? couleur;
  final String? titre;
  _Col.module(this.module, {this.couleur}) : ueIndex = null, titre = null;
  _Col.ue(this.ueIndex, this.titre, this.couleur) : module = null;
}

/// Publication des bulletins : calcule la moyenne du semestre à partir des
/// moyennes par module (notes transférées + coefficients), puis publie à
/// chaque étudiant UNIQUEMENT son propre bulletin.
class AdminBulletins extends StatefulWidget {
  final StudentProfile profile;
  const AdminBulletins({super.key, required this.profile});
  @override
  State<AdminBulletins> createState() => _AdminBulletinsState();
}

class _AdminBulletinsState extends State<AdminBulletins> {
  List<Map<String, dynamic>> _filieres = [];
  String? _domaine, _filiereId, _niveau, _semestre, _annee;
  bool _chargementBase = true, _chargement = false, _charge = false, _envoi = false;
  String? _erreur;

  List<Map<String, dynamic>> _modules = [];
  List<Map<String, dynamic>> _etus = [];
  final Set<String> _sel = {};
  final Map<String, String> _statut = {};
  final Map<String, String> _apprec = {};
  final Map<String, double> _moyCorr = {};

  // Paramètres du dernier chargement (pour publier exactement ce qui est affiché)
  String? _cFiliere, _cNiveau, _cSemestre, _cAnnee;
  Map<String, dynamic> _regle = {'mode': 'general', 'seuil_validation': 10};
  List<String> _horsUe = [];

  late final List<String> _annees;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final debut = now.month >= 9 ? now.year : now.year - 1;
    _annees = List.generate(4, (i) => '${debut + 1 - i}-${debut + 2 - i}'); // année suivante → 2 ans avant
    _annee = '$debut-${debut + 1}';
    if (widget.profile.filtreParDomaine) _domaine = widget.profile.domaineAdmin;
    _chargerBase();
  }

  Future<void> _chargerBase() async {
    final r = await ApiService.getFilieres();
    if (!mounted) return;
    setState(() {
      _chargementBase = false;
      if (r['success'] == true) {
        _filieres = (r['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      } else {
        _erreur = r['error'] as String?;
      }
    });
  }

  // ── Données dérivées ──────────────────────────────────────────────────
  List<String> get _domaines => _filieres.map((f) => (f['domaine'] ?? '').toString()).where((d) => d.isNotEmpty).toSet().toList()..sort();

  List<Map<String, dynamic>> get _filieresVisibles => _filieres.where((f) {
        if (_domaine == null || _domaine!.isEmpty || _domaine == 'Tous') return true;
        return (f['domaine'] ?? '').toString() == _domaine;
      }).toList();

  String _id(Map<String, dynamic> e) => e['etudiant_id'].toString();

  double? _moyenne(Map<String, dynamic> e) {
    final corr = _moyCorr[_id(e)];
    if (corr != null) return corr;
    final m = e['moyenne_calculee'];
    return m == null ? null : (m as num).toDouble();
  }

  bool _scolariteBloquee(Map<String, dynamic> e) => e['scolarite_a_regulariser'] == true;

  Future<void> _charger() async {
    if (_filiereId == null || _niveau == null || _semestre == null || _annee == null) {
      _snack('Choisis la filière, le niveau, le semestre et l\'année.', isError: true);
      return;
    }
    setState(() { _chargement = true; _erreur = null; });
    final r = await BulletinsAdminService.preparation(
        filiereId: _filiereId!, niveau: _niveau!, semestre: _semestre!, anneeAcademique: _annee!);
    if (!mounted) return;
    if (r['success'] != true) {
      setState(() { _chargement = false; _erreur = r['error'] as String?; });
      return;
    }
    final etus = (r['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    setState(() {
      _chargement = false;
      _charge = true;
      _etus = etus;
      _modules = (r['modules'] as List<dynamic>).cast<Map<String, dynamic>>();
      _regle = (r['regle'] as Map<String, dynamic>?) ?? {'mode': 'general', 'seuil_validation': 10};
      _horsUe = (r['modules_hors_ue'] as List<dynamic>? ?? []).map((x) => x.toString()).toList();
      _cFiliere = _filiereId; _cNiveau = _niveau; _cSemestre = _semestre; _cAnnee = _annee;
      _sel.clear(); _statut.clear(); _apprec.clear(); _moyCorr.clear();
      for (final e in etus) {
        final id = _id(e);
        final m = (e['moyenne_calculee'] as num?)?.toDouble();
        // Statut proposé par la règle de la filière ; modifiable ligne par ligne.
        _statut[id] = (e['bulletin_statut'] as String?) ?? ((e['statut_suggere'] as String?) ?? 'ajourne');
        final a = (e['appreciation'] as String?) ?? (e['appreciation_suggeree'] as String?);
        if (a != null) _apprec[id] = a;
        if (m != null && !_scolariteBloquee(e) && _statut[id] == 'valide' && e['resultat'] != 'incomplet') _sel.add(id);
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: _chargementBase
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _entete(),
                const SizedBox(height: 14),
                _bandeauInfo(),
                const SizedBox(height: 14),
                _filtres(),
                if (_erreur != null) ...[
                  const SizedBox(height: 12),
                  Text(_erreur!, style: const TextStyle(color: AdminTheme.danger, fontSize: 13)),
                ],
                if (_charge) ...[
                  const SizedBox(height: 14),
                  _kpis(),
                  const SizedBox(height: 14),
                  _blocBulletins(),
                ],
              ]),
            ),
    );
  }

  Widget _entete() => Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: AdminTheme.primary, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.description_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Publication des bulletins', style: AdminTheme.headingLarge),
          Text('Calcul des moyennes, validation et diffusion individuelle.', style: AdminTheme.bodyMedium),
        ])),
        OutlinedButton.icon(
          onPressed: _ouvrirRegles,
          icon: const Icon(Icons.rule_rounded, size: 18),
          label: const Text('Règles de validation'),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: _charge && !_chargement ? _charger : null,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Actualiser'),
        ),
      ]);

  Widget _bandeauInfo() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AdminTheme.infoLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AdminTheme.info.withValues(alpha: 0.3))),
        child: const Row(children: [
          Icon(Icons.info_rounded, color: AdminTheme.info, size: 20),
          SizedBox(width: 10),
          Expanded(child: Text('Les moyennes sont calculées à partir des notes validées et des coefficients des modules.',
              style: TextStyle(fontSize: 13, color: AdminTheme.info, fontWeight: FontWeight.w600))),
        ]),
      );

  // ── Filtres ───────────────────────────────────────────────────────────
  Widget _filtres() {
    final fil = _filieresVisibles;
    final sems = _niveau == null ? <String>[] : semestresPourNiveau(_niveau);
    final domaineFixe = widget.profile.filtreParDomaine;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(AdminTheme.radiusCard), border: Border.all(color: AdminTheme.border), boxShadow: AdminTheme.cardShadow),
      child: Wrap(spacing: 14, runSpacing: 14, crossAxisAlignment: WrapCrossAlignment.end, children: [
        _champ('Domaine académique', 240, _liste(_domaine, _domaines, _domaines, 'Tous les domaines',
            domaineFixe ? null : (v) => setState(() {
                  _domaine = v; _filiereId = null; _charge = false;
                }))),
        _champ('Filière', 300, _liste(_filiereId, fil.map((f) => f['id'].toString()).toList(), fil.map((f) => (f['nom'] ?? '').toString()).toList(), 'Choisir une filière',
            (v) => setState(() { _filiereId = v; _charge = false; }))),
        _champ('Niveau', 180, _liste(_niveau, istNiveaux, istNiveaux, 'Choisir un niveau', (v) => setState(() {
              _niveau = v; _charge = false;
              if (_semestre != null && !semestresPourNiveau(v).contains(_semestre)) _semestre = null;
            }))),
        _champ('Semestre', 140, _liste(_semestre, sems, sems, _niveau == null ? 'Niveau d\'abord' : 'Semestre',
            _niveau == null ? null : (v) => setState(() { _semestre = v; _charge = false; }))),
        _champ('Année académique', 180, _liste(_annee, _annees, _annees, 'Année', (v) => setState(() { _annee = v; _charge = false; }))),
        SizedBox(height: 44, child: ElevatedButton.icon(
          onPressed: _chargement ? null : _charger,
          icon: _chargement
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.table_chart_rounded, size: 18),
          label: const Text('Charger les résultats'),
          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusButton))),
        )),
      ]),
    );
  }

  Widget _champ(String label, double largeur, Widget child) => SizedBox(
        width: largeur,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminTheme.textSecondary)),
          const SizedBox(height: 6),
          child,
        ]),
      );

  Widget _liste(String? v, List<String> ids, List<String> labels, String hint, ValueChanged<String?>? onChanged) => Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(AdminTheme.radiusButton), border: Border.all(color: AdminTheme.border)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: v != null && ids.contains(v) ? v : null,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 13)),
          items: List.generate(ids.length, (i) => DropdownMenuItem(value: ids[i], child: Text(labels[i], style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))),
          onChanged: onChanged,
        )),
      );

  // ── KPI ───────────────────────────────────────────────────────────────
  Widget _kpis() {
    Widget carte(IconData ic, Color fg, Color bg, String gros, String petit) => Expanded(child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(AdminTheme.radiusCard), border: Border.all(color: AdminTheme.border), boxShadow: AdminTheme.cardShadow),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Icon(ic, color: fg, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(gros, style: TextStyle(fontSize: gros.length > 6 ? 15 : 22, fontWeight: FontWeight.w800, color: AdminTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(petit, style: AdminTheme.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ));
    return Row(children: [
      carte(Icons.groups_rounded, AdminTheme.info, AdminTheme.infoLight, '${_etus.length}', 'Étudiants'),
      const SizedBox(width: 12),
      carte(Icons.menu_book_rounded, AdminTheme.primary, AdminTheme.primaryLight, '${_modules.length}', 'Modules'),
      const SizedBox(width: 12),
      carte(Icons.calculate_rounded, AdminTheme.info, AdminTheme.infoLight, 'Moyenne calculée', 'automatiquement'),
      const SizedBox(width: 12),
      carte(Icons.check_circle_rounded, AdminTheme.success, AdminTheme.successLight, '${_sel.length}', 'Sélectionnés pour diffusion'),
    ]);
  }

  // ── Bloc tableau ──────────────────────────────────────────────────────
  Widget _blocBulletins() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(AdminTheme.radiusCard), border: Border.all(color: AdminTheme.border), boxShadow: AdminTheme.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Bulletins des étudiants', style: AdminTheme.headingMedium),
          const Spacer(),
          const Icon(Icons.circle, size: 9, color: AdminTheme.success), const SizedBox(width: 5),
          Text('Semestre validé', style: AdminTheme.caption), const SizedBox(width: 14),
          const Icon(Icons.circle, size: 9, color: AdminTheme.danger), const SizedBox(width: 5),
          Text('Non validé', style: AdminTheme.caption),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AdminTheme.surfaceAlt, borderRadius: BorderRadius.circular(8)),
            child: Text(_resumeRegle(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdminTheme.textSecondary)),
          ),
          TextButton.icon(onPressed: _ouvrirRegles, icon: const Icon(Icons.rule_rounded, size: 16), label: const Text('Règles de validation')),
        ]),
        if (_modeUe && _horsUe.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 6), child: Text(
              '⚠️ Modules hors UE (non comptés) : ${_horsUe.join(', ')}', style: const TextStyle(fontSize: 12, color: AdminTheme.warning, fontWeight: FontWeight.w700))),
        const SizedBox(height: 12),
        if (_modules.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AdminTheme.warningLight, borderRadius: BorderRadius.circular(10)),
            child: const Text('Aucun module n\'a de notes transférées pour ce semestre : transfère d\'abord les notes dans « Notes & Moyennes ».',
                style: TextStyle(fontSize: 13, color: AdminTheme.warning, fontWeight: FontWeight.w600)),
          )
        else if (_etus.isEmpty)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Aucun étudiant dans cette filière / ce niveau.')))
        else
          _tableau(),
        const SizedBox(height: 14),
        _pied(),
      ]),
    );
  }

  bool get _modeUe => _regle['mode'] == 'ue';
  double get _seuilUe => (_regle['seuil_ue'] as num?)?.toDouble() ?? 12;
  List<Map<String, dynamic>> get _uesRegle => ((_regle['ues'] as List<dynamic>?) ?? []).cast<Map<String, dynamic>>();

  List<_Col> _colonnes() {
    if (!_modeUe) return _modules.map((m) => _Col.module(m)).toList();
    final cols = <_Col>[];
    for (var i = 0; i < _uesRegle.length; i++) {
      final ue = _uesRegle[i];
      final couleur = _hex(ue['couleur'] as String?, defaut: _hex(_couleursUe[i % _couleursUe.length]));
      final ids = ((ue['module_ids'] as List<dynamic>?) ?? []).map((x) => x.toString()).toList();
      for (final id in ids) {
        final m = _modules.where((x) => x['id'].toString() == id);
        if (m.isNotEmpty) cols.add(_Col.module(m.first, couleur: couleur));
      }
      cols.add(_Col.ue(i, '${ue['nom'] ?? 'UE ${i + 1}'}', couleur));
    }
    return cols;
  }

  String _resumeRegle() {
    final sv = _regle['seuil_validation'];
    if (!_modeUe) return 'Règle : moyenne générale pondérée — semestre validé à partir de $sv/20';
    return 'Règle par UE : UE validée à ${_regle['seuil_ue']}/20 · compensation si chaque UE ≥ ${_regle['seuil_compensation']} · semestre validé à $sv/20';
  }

  static const double _wCase = 48, _wEtu = 230, _wMat = 100, _wMod = 118, _wMoy = 110, _wApp = 150, _wDif = 120, _wAct = 90;

  Widget _tableau() {
    final cols = _colonnes();
    final largeur = _wCase + _wEtu + _wMat + cols.length * _wMod + _wMoy + _wApp + _wDif + _wAct;
    final toutes = _etus.isNotEmpty && _etus.every((e) => _sel.contains(_id(e)) || _moyenne(e) == null);
    const th = TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AdminTheme.textSecondary);
    return LayoutBuilder(builder: (context, c) {
      final w = largeur < c.maxWidth ? c.maxWidth : largeur;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: w, child: Column(children: [
          Container(
            color: AdminTheme.surfaceAlt,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              SizedBox(width: _wCase, child: Checkbox(value: toutes, onChanged: (v) => setState(() {
                for (final e in _etus) {
                  if (_moyenne(e) == null) continue;
                  v == true ? _sel.add(_id(e)) : _sel.remove(_id(e));
                }
              }))),
              SizedBox(width: _wEtu, child: Text('Tout sélectionner (${_sel.length}/${_etus.length})\nÉtudiant', style: th)),
              const SizedBox(width: _wMat, child: Text('Matricule', style: th)),
              ...cols.map((c) => c.module != null
                  ? Container(width: _wMod, color: c.couleur?.withValues(alpha: 0.10), padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [
                      Text('${c.module!['nom']}', style: th, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text('(Coef. ${c.module!['coefficient']})', style: th.copyWith(fontWeight: FontWeight.w500)),
                    ]))
                  : Container(width: _wMod, color: c.couleur?.withValues(alpha: 0.28), padding: const EdgeInsets.symmetric(vertical: 8), child: Text(
                      '${c.titre}', textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: th.copyWith(color: c.couleur, fontWeight: FontWeight.w800)))),
              SizedBox(width: _wMoy, child: Text('Moyenne $_cSemestre', style: th, textAlign: TextAlign.center)),
              const SizedBox(width: _wApp, child: Text('Appréciation', style: th, textAlign: TextAlign.center)),
              const SizedBox(width: _wDif, child: Text('Diffusion', style: th, textAlign: TextAlign.center)),
              const SizedBox(width: _wAct, child: Text('Actions', style: th, textAlign: TextAlign.center)),
            ]),
          ),
          ..._etus.map((e) => Column(children: [_ligne(e), const Divider(height: 1, color: AdminTheme.border)])),
        ])),
      );
    });
  }

  Widget _ligne(Map<String, dynamic> e) {
    final id = _id(e);
    final moy = _moyenne(e);
    final nom = '${e['prenoms'] ?? ''} ${e['nom'] ?? ''}'.trim();
    final initiales = '${(e['prenoms'] ?? '?').toString().isNotEmpty ? (e['prenoms'] as String)[0] : '?'}${(e['nom'] ?? '?').toString().isNotEmpty ? (e['nom'] as String)[0] : '?'}'.toUpperCase();
    final statut = _statut[id] ?? 'ajourne';
    final detail = (e['detail_modules'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final selectionne = _sel.contains(id);

    return Container(
      color: selectionne ? AdminTheme.primaryLight.withValues(alpha: 0.35) : null,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        SizedBox(width: _wCase, child: Checkbox(
          value: selectionne,
          onChanged: moy == null ? null : (v) => setState(() { v == true ? _sel.add(id) : _sel.remove(id); }),
        )),
        SizedBox(width: _wEtu, child: Row(children: [
          Container(width: 34, height: 34, decoration: const BoxDecoration(color: AdminTheme.primaryLight, shape: BoxShape.circle),
              child: Center(child: Text(initiales, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminTheme.primary)))),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(nom, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (_scolariteBloquee(e))
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AdminTheme.warningLight, borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.lock_rounded, size: 10, color: AdminTheme.warning), SizedBox(width: 3),
                  Text('Scolarité à régulariser', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AdminTheme.warning)),
                ]),
              )
            else
              Text('${e['matricule'] ?? ''}', style: AdminTheme.caption),
          ])),
        ])),
        SizedBox(width: _wMat, child: Text('${e['matricule'] ?? ''}', style: AdminTheme.caption.copyWith(fontFamily: 'monospace'))),
        ..._colonnes().map((c) {
          if (c.module != null) {
            final d = detail.where((x) => x['module_id'].toString() == c.module!['id'].toString());
            final v = d.isEmpty ? null : (d.first['moyenne_module'] as num?)?.toDouble();
            return Container(width: _wMod, color: c.couleur?.withValues(alpha: 0.06), padding: const EdgeInsets.symmetric(vertical: 6), child: Center(child: Text(v == null ? '-' : '${v.toStringAsFixed(2)} / 20',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: v == null ? AdminTheme.textMuted : AdminTheme.textPrimary))));
          }
          final ues = (e['ues_detail'] as List<dynamic>? ?? []);
          final u = c.ueIndex! < ues.length ? ues[c.ueIndex!] as Map<String, dynamic> : null;
          final v = (u?['moyenne'] as num?)?.toDouble();
          final ok = v != null && v >= _seuilUe;
          return Container(width: _wMod, color: c.couleur?.withValues(alpha: 0.18), padding: const EdgeInsets.symmetric(vertical: 6), child: Center(child: Text(
              v == null ? '-' : '${v.toStringAsFixed(2)} / 20',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: v == null ? AdminTheme.textMuted : ok ? AdminTheme.success : AdminTheme.warning))));
        }),
        SizedBox(width: _wMoy, child: Center(child: Text(moy == null ? '-' : '${moy.toStringAsFixed(2)} / 20',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: moy == null ? AdminTheme.textMuted : AdminTheme.textPrimary)))),
        SizedBox(width: _wApp, child: Center(child: _appreciation(id, moy))),
        SizedBox(width: _wDif, child: Center(child: _badgeDiffusion(statut, e['bulletin_publie'] == true, e['resultat'] as String?, e['motif'] as String?))),
        SizedBox(width: _wAct, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(visualDensity: VisualDensity.compact, tooltip: 'Voir le bulletin', onPressed: () => _voir(e),
              icon: const Icon(Icons.visibility_outlined, size: 19, color: AdminTheme.primary)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 19, color: AdminTheme.textSecondary),
            onSelected: (v) => _menu(v, e),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'valide', child: Text('Marquer Validé')),
              const PopupMenuItem(value: 'ajourne', child: Text('Marquer Ajourné')),
              const PopupMenuItem(value: 'invalide', child: Text('Marquer Invalidé')),
              const PopupMenuItem(value: 'corriger', child: Text('Corriger la moyenne')),
              if (_moyCorr.containsKey(id)) const PopupMenuItem(value: 'retablir', child: Text('Rétablir la moyenne calculée')),
            ],
          ),
        ])),
      ]),
    );
  }

  Widget _appreciation(String id, double? moy) {
    final v = _apprec[id];
    return Container(
      height: 34, width: 126,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AdminTheme.border)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: _appreciations.contains(v) ? v : null,
        isExpanded: true,
        hint: const Text('-', style: TextStyle(fontSize: 12)),
        style: const TextStyle(fontSize: 12.5, color: AdminTheme.textPrimary),
        items: _appreciations.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
        onChanged: moy == null ? null : (x) => setState(() { if (x != null) _apprec[id] = x; }),
      )),
    );
  }

  Widget _badgeDiffusion(String statut, bool publie, String? resultat, String? motif) {
    final ok = statut == 'valide';
    final incomplet = resultat == 'incomplet' && !ok;
    final fg = ok ? AdminTheme.success : incomplet ? AdminTheme.textSecondary : AdminTheme.danger;
    final label = ok ? (resultat == 'valide_compensation' ? 'Validé (comp.)' : 'Validé') : incomplet ? 'Incomplet' : 'Non validé';
    final tip = statut == 'ajourne' ? 'Ajourné' : statut == 'invalide' ? 'Invalidé' : 'Validé';
    return Tooltip(
      message: '${publie ? '$tip · déjà publié' : tip}${motif != null && motif.isNotEmpty ? '\n$motif' : ''}',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(ok ? Icons.check_rounded : Icons.circle, size: ok ? 14 : 8, color: fg), const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
          ]),
        ),
        if (publie) Text('Publié', style: AdminTheme.caption.copyWith(fontSize: 10)),
      ]),
    );
  }

  Widget _pied() {
    return Wrap(spacing: 12, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Text('${_sel.length} étudiants sélectionnés sur ${_etus.length}', style: AdminTheme.bodyMedium),
      const Icon(Icons.info_outline_rounded, size: 15, color: AdminTheme.info),
      Text('Chaque étudiant ne verra que son propre bulletin.', style: AdminTheme.caption),
      const SizedBox(width: 20),
      ElevatedButton.icon(
        onPressed: _envoi || _sel.isEmpty ? null : () => _confirmerPublication(),
        icon: _envoi ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, size: 16),
        label: const Text('Publier les bulletins sélectionnés'),
        style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusButton))),
      ),
      OutlinedButton.icon(
        onPressed: _etus.isEmpty ? null : _exporterPdf,
        icon: const Icon(Icons.download_rounded, size: 16),
        label: const Text('Exporter PDF'),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
      ),
      OutlinedButton.icon(
        onPressed: _envoi || _sel.isEmpty ? null : () => _enregistrer(publier: false),
        icon: const Icon(Icons.save_outlined, size: 16),
        label: const Text('Enregistrer sans publier'),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
      ),
    ]);
  }

  // ── Actions ───────────────────────────────────────────────────────────
  void _menu(String action, Map<String, dynamic> e) {
    final id = _id(e);
    switch (action) {
      case 'valide':
      case 'ajourne':
      case 'invalide':
        setState(() => _statut[id] = action);
        break;
      case 'corriger':
        _corrigerMoyenne(e);
        break;
      case 'retablir':
        setState(() => _moyCorr.remove(id));
        break;
    }
  }

  Future<void> _corrigerMoyenne(Map<String, dynamic> e) async {
    final ctrl = TextEditingController(text: _moyenne(e)?.toStringAsFixed(2) ?? '');
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Corriger la moyenne — ${e['prenoms']} ${e['nom']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Moyenne calculée : ${(e['moyenne_calculee'] as num?)?.toStringAsFixed(2) ?? '-'} / 20', style: AdminTheme.bodyMedium),
        const SizedBox(height: 10),
        TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Nouvelle moyenne /20', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
      ],
    ));
    if (ok != true) return;
    final v = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
    if (v == null || v < 0 || v > 20) { _snack('Moyenne invalide (0 à 20).', isError: true); return; }
    setState(() {
      _moyCorr[_id(e)] = v;
      _apprec[_id(e)] = _appreciationPour(v);
    });
  }

  String _appreciationPour(double m) => m >= 16 ? 'Très bien' : m >= 14 ? 'Bien' : m >= 12 ? 'Assez bien' : m >= 10 ? 'Passable' : 'Insuffisant';

  void _voir(Map<String, dynamic> e) {
    final id = _id(e);
    final moy = _moyenne(e);
    final detail = (e['detail_modules'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('${e['prenoms']} ${e['nom']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      content: SizedBox(width: 520, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${e['matricule']} · $_cSemestre · $_cAnnee', style: AdminTheme.caption),
        if (_modeUe) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: (e['ues_detail'] as List<dynamic>? ?? []).map((u) {
            final um = u as Map<String, dynamic>;
            final c = _hex(um['couleur'] as String?);
            final v = (um['moyenne'] as num?)?.toDouble();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withValues(alpha: 0.5))),
              child: Text('${um['nom']} : ${v == null ? '-' : v.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c)),
            );
          }).toList()),
        ],
        if ((e['motif'] as String?)?.isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text('Décision : ${e['motif']}', style: AdminTheme.caption.copyWith(fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 10),
        ...detail.map((d) {
          final notes = (d['notes'] as List<dynamic>? ?? []).map((n) => n == null ? '-' : (n as num).toStringAsFixed(1)).join(' · ');
          final mm = (d['moyenne_module'] as num?)?.toDouble();
          return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${d['module_nom']}  (Coef. ${d['coefficient']})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text('Devoirs : $notes', style: AdminTheme.caption),
            ])),
            Text(mm == null ? '-' : '${mm.toStringAsFixed(2)} / 20', style: const TextStyle(fontWeight: FontWeight.w800)),
          ]));
        }),
        const Divider(),
        Row(children: [
          const Text('Moyenne du semestre', style: TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(moy == null ? '-' : '${moy.toStringAsFixed(2)} / 20', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
        Text('Appréciation : ${_apprec[id] ?? '-'}', style: AdminTheme.bodyMedium),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
    ));
  }

  List<Map<String, dynamic>> _resultatsSelection() {
    final res = <Map<String, dynamic>>[];
    for (final e in _etus) {
      final id = _id(e);
      if (!_sel.contains(id) || _moyenne(e) == null) continue;
      res.add({
        'etudiant_id': e['etudiant_id'],
        'statut': _statut[id] ?? 'ajourne',
        if (_apprec[id] != null) 'appreciation': _apprec[id],
        if (_moyCorr.containsKey(id)) 'moyenne': _moyCorr[id],
      });
    }
    return res;
  }

  void _confirmerPublication() {
    final bloques = _etus.where((e) => _sel.contains(_id(e)) && _scolariteBloquee(e)).length;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Publier les bulletins ?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${_sel.length} bulletin(s) du $_cSemestre ($_cAnnee) seront envoyés. Chaque étudiant reçoit uniquement le sien.', style: const TextStyle(fontSize: 13)),
        if (bloques > 0) ...[
          const SizedBox(height: 10),
          Text('⚠️ $bloques étudiant(s) sélectionné(s) ont une scolarité à régulariser.', style: const TextStyle(fontSize: 12.5, color: AdminTheme.warning, fontWeight: FontWeight.w700)),
        ],
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); _enregistrer(publier: true); },
          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, foregroundColor: Colors.white, elevation: 0),
          child: const Text('Publier'),
        ),
      ],
    ));
  }

  Future<void> _enregistrer({required bool publier}) async {
    final resultats = _resultatsSelection();
    if (resultats.isEmpty) { _snack('Aucun étudiant sélectionné.', isError: true); return; }
    setState(() => _envoi = true);
    final r = await BulletinsAdminService.publier(
      filiereId: _cFiliere!, niveau: _cNiveau!, semestre: _cSemestre!, anneeAcademique: _cAnnee!,
      resultats: resultats, publier: publier,
    );
    if (!mounted) return;
    setState(() => _envoi = false);
    if (r['success'] == true) {
      _snack((r['message'] as String?) ?? (publier ? 'Bulletins publiés.' : 'Bulletins enregistrés.'));
      _charger();
    } else {
      _snack((r['error'] as String?) ?? 'Erreur.', isError: true);
    }
  }

  Future<void> _exporterPdf() async {
    final doc = pw.Document();
    final entetes = <String>[
      'Etudiant', 'Matricule',
      ..._colonnes().map((c) => c.module != null ? '${c.module!['nom']} (Coef. ${c.module!['coefficient']})' : 'UE ${c.titre}'),
      'Moyenne $_cSemestre', 'Appreciation', 'Resultat',
    ];
    final lignes = _etus.map((e) {
      final id = _id(e);
      final detail = (e['detail_modules'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      final moy = _moyenne(e);
      return <String>[
        '${e['prenoms'] ?? ''} ${e['nom'] ?? ''}'.trim(),
        '${e['matricule'] ?? ''}',
        ..._colonnes().map((c) {
          if (c.module != null) {
            final d = detail.where((x) => x['module_id'].toString() == c.module!['id'].toString());
            final v = d.isEmpty ? null : (d.first['moyenne_module'] as num?)?.toDouble();
            return v == null ? '-' : v.toStringAsFixed(2);
          }
          final ues = (e['ues_detail'] as List<dynamic>? ?? []);
          final u = c.ueIndex! < ues.length ? ues[c.ueIndex!] as Map<String, dynamic> : null;
          final v = (u?['moyenne'] as num?)?.toDouble();
          return v == null ? '-' : v.toStringAsFixed(2);
        }),
        moy == null ? '-' : moy.toStringAsFixed(2),
        _apprec[id] ?? '-',
        (_statut[id] ?? 'ajourne') == 'valide' ? 'Valide' : 'Non valide',
      ];
    }).toList();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      build: (_) => [
        pw.Text('Resultats du $_cSemestre - $_cAnnee', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('$_cNiveau - ${_nomFiliere(_cFiliere)}', style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: entetes,
          data: lignes,
          headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'bulletins_${_cSemestre}_$_cAnnee.pdf');
  }

  String _nomFiliere(String? id) {
    final f = _filieres.where((x) => x['id'].toString() == id);
    return f.isEmpty ? '' : '${f.first['nom']}';
  }

  // ════════════════════════════════════════════════════════════════════════
  // RÈGLES DE VALIDATION — général (défaut) ou par UE, par filière/niveau/semestre
  // ════════════════════════════════════════════════════════════════════════
  Future<void> _ouvrirRegles() async {
    if (_filiereId == null || _niveau == null || _semestre == null) {
      _snack('Choisis d\'abord la filière, le niveau et le semestre.', isError: true);
      return;
    }
    final results = await Future.wait([
      BulletinsAdminService.regles(filiereId: _filiereId!, niveau: _niveau!, semestre: _semestre!),
      ApiService.getModules(filiereId: _filiereId),
    ]);
    if (!mounted) return;
    final rr = results[0];
    final mr = results[1];
    if (rr['success'] != true) { _snack((rr['error'] as String?) ?? 'Erreur.', isError: true); return; }
    final modules = mr['success'] == true ? (mr['data'] as List<dynamic>).cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
    final regle = rr['data'] as Map<String, dynamic>;

    final sauve = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogRegles(
        filiereId: _filiereId!, niveau: _niveau!, semestre: _semestre!,
        filiereNom: _nomFiliere(_filiereId), modules: modules, regle: regle,
      ),
    );
    if (sauve == true && mounted) {
      _snack('Règles enregistrées.');
      if (_charge) _charger();
    }
  }

  void _snack(String msg, {bool isError = false}) => showAppSnackBar(context, msg, backgroundColor: isError ? AdminTheme.danger : const Color(0xFF1A3C34));
}

// ════════════════════════════════════════════════════════════════════════════
// DIALOGUE — Règles de validation (mode général ou par UE)
// ════════════════════════════════════════════════════════════════════════════
class _UeEdit {
  String nom;
  String couleur;
  final Set<String> moduleIds;
  _UeEdit(this.nom, this.couleur, this.moduleIds);
}

class _DialogRegles extends StatefulWidget {
  final String filiereId, niveau, semestre, filiereNom;
  final List<Map<String, dynamic>> modules;
  final Map<String, dynamic> regle;
  const _DialogRegles({required this.filiereId, required this.niveau, required this.semestre, required this.filiereNom, required this.modules, required this.regle});
  @override
  State<_DialogRegles> createState() => _DialogReglesState();
}

class _DialogReglesState extends State<_DialogRegles> {
  late bool _ue;
  late final TextEditingController _seuilVal, _seuilUe, _seuilComp;
  final List<_UeEdit> _ues = [];
  bool _enregistrement = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    final r = widget.regle;
    _ue = r['mode'] == 'ue';
    String f(dynamic v, String d) => v == null ? d : (v as num).toString().replaceAll(RegExp(r'\.0+$'), '');
    _seuilVal = TextEditingController(text: f(r['seuil_validation'], _ue ? '12' : '10'));
    _seuilUe = TextEditingController(text: f(r['seuil_ue'], '12'));
    _seuilComp = TextEditingController(text: f(r['seuil_compensation'], '7'));
    for (final u in ((r['ues'] as List<dynamic>?) ?? []).cast<Map<String, dynamic>>()) {
      _ues.add(_UeEdit('${u['nom'] ?? ''}', (u['couleur'] as String?) ?? _couleursUe[_ues.length % _couleursUe.length],
          ((u['module_ids'] as List<dynamic>?) ?? []).map((x) => x.toString()).toSet()));
    }
  }

  @override
  void dispose() {
    _seuilVal.dispose(); _seuilUe.dispose(); _seuilComp.dispose();
    super.dispose();
  }

  double _coef(Map<String, dynamic> m) => double.tryParse('${m['coefficient']}') ?? 0;
  double _total(_UeEdit u) => widget.modules.where((m) => u.moduleIds.contains(m['id'].toString())).fold(0.0, (a, m) => a + _coef(m));
  bool _pris(String id, _UeEdit sauf) => _ues.any((u) => u != sauf && u.moduleIds.contains(id));

  double? _num(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> _enregistrer() async {
    final sv = _num(_seuilVal), su = _num(_seuilUe), sc = _num(_seuilComp);
    if (sv == null || sv < 0 || sv > 20 || (_ue && (su == null || sc == null || su > 20 || sc > 20))) {
      setState(() => _erreur = 'Les seuils doivent être compris entre 0 et 20.');
      return;
    }
    if (_ue) {
      if (_ues.isEmpty) { setState(() => _erreur = 'Ajoute au moins une UE.'); return; }
      for (final u in _ues) {
        if (u.moduleIds.isEmpty) { setState(() => _erreur = '${u.nom.isEmpty ? 'Une UE' : u.nom} : choisis au moins un module.'); return; }
        if (_total(u) > 6) { setState(() => _erreur = '${u.nom} : coefficient total ${_total(u)} > 6.'); return; }
      }
    }
    setState(() { _enregistrement = true; _erreur = null; });
    final r = await BulletinsAdminService.sauverRegles(
      filiereId: widget.filiereId, niveau: widget.niveau, semestre: widget.semestre,
      mode: _ue ? 'ue' : 'general', seuilValidation: sv, seuilUe: su ?? 12, seuilCompensation: sc ?? 7,
      ues: _ues.asMap().entries.map((e) => {
            'nom': e.value.nom.trim().isEmpty ? 'UE ${e.key + 1}' : e.value.nom.trim(),
            'couleur': e.value.couleur,
            'module_ids': e.value.moduleIds.toList(),
          }).toList(),
    );
    if (!mounted) return;
    if (r['success'] == true) {
      Navigator.pop(context, true);
    } else {
      setState(() { _enregistrement = false; _erreur = r['error'] as String?; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Règles de validation — ${widget.niveau} · ${widget.semestre}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      content: SizedBox(width: 640, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.filiereNom, style: AdminTheme.bodyMedium),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Général'), icon: Icon(Icons.functions_rounded)),
            ButtonSegment(value: true, label: Text('Par UE'), icon: Icon(Icons.view_module_rounded)),
          ],
          selected: {_ue},
          onSelectionChanged: (s) => setState(() {
            _ue = s.first;
            if (_ue && _seuilVal.text.trim() == '10') _seuilVal.text = '12';
            if (!_ue && _seuilVal.text.trim() == '12') _seuilVal.text = '10';
          }),
        ),
        const SizedBox(height: 10),
        Text(_ue
            ? 'Les modules sont regroupés en UE (coefficient total ≤ 6). Une UE est validée à partir du seuil UE ; si certaines UE sont entre le seuil de compensation et le seuil UE, la moyenne générale décide ; une UE sous le seuil de compensation bloque le semestre.'
            : 'Moyenne générale = somme des (moyenne du module × coefficient) ÷ somme des coefficients. Le semestre est validé à partir du seuil ci-dessous.',
            style: AdminTheme.caption),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 10, children: [
          _champNombre('Semestre validé à partir de', _seuilVal),
          if (_ue) _champNombre('UE validée à partir de', _seuilUe),
          if (_ue) _champNombre('Compensation possible dès', _seuilComp),
        ]),
        if (_ue) ...[
          const SizedBox(height: 16),
          Row(children: [
            Text('Unités d\'enseignement', style: AdminTheme.headingSmall),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() => _ues.add(_UeEdit('UE ${_ues.length + 1}', _couleursUe[_ues.length % _couleursUe.length], {}))),
              icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Ajouter une UE'),
            ),
          ]),
          ..._ues.map(_carteUe),
          if (widget.modules.isEmpty) Text('Aucun module trouvé pour cette filière.', style: AdminTheme.caption),
        ],
        if (_erreur != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_erreur!, style: const TextStyle(color: AdminTheme.danger, fontSize: 12.5, fontWeight: FontWeight.w700))),
      ]))),
      actions: [
        TextButton(onPressed: _enregistrement ? null : () => Navigator.pop(context, false), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _enregistrement ? null : _enregistrer,
          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, foregroundColor: Colors.white, elevation: 0),
          child: Text(_enregistrement ? 'Enregistrement...' : 'Enregistrer'),
        ),
      ],
    );
  }

  Widget _champNombre(String label, TextEditingController c) => SizedBox(
        width: 190,
        child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: '$label /20', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        ),
      );

  Widget _carteUe(_UeEdit u) {
    final couleur = _hex(u.couleur);
    final total = _total(u);
    final depasse = total > 6;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: couleur.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(10), border: Border.all(color: couleur.withValues(alpha: 0.5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: TextFormField(
            initialValue: u.nom,
            onChanged: (v) => u.nom = v,
            decoration: const InputDecoration(labelText: 'Nom de l\'UE', isDense: true, border: OutlineInputBorder()),
          )),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: depasse ? AdminTheme.dangerLight : AdminTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: depasse ? AdminTheme.danger : AdminTheme.border)),
            child: Text('Coef. ${total % 1 == 0 ? total.toInt() : total} / 6', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: depasse ? AdminTheme.danger : AdminTheme.textPrimary)),
          ),
          IconButton(tooltip: 'Supprimer l\'UE', onPressed: () => setState(() => _ues.remove(u)), icon: const Icon(Icons.delete_outline_rounded, color: AdminTheme.danger)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, children: _couleursUe.map((h) => GestureDetector(
              onTap: () => setState(() => u.couleur = h),
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(color: _hex(h), shape: BoxShape.circle, border: Border.all(color: u.couleur == h ? Colors.black87 : Colors.transparent, width: 2)),
              ),
            )).toList()),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, children: widget.modules.map((m) {
          final id = m['id'].toString();
          final pris = _pris(id, u);
          final sel = u.moduleIds.contains(id);
          return FilterChip(
            label: Text('${m['nom']} (coef. ${m['coefficient']})', style: const TextStyle(fontSize: 12)),
            selected: sel,
            selectedColor: couleur.withValues(alpha: 0.25),
            onSelected: pris ? null : (v) => setState(() { v ? u.moduleIds.add(id) : u.moduleIds.remove(id); }),
          );
        }).toList()),
      ]),
    );
  }
}
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/student_profile.dart';
import '../services/api_service.dart';
import '../admin/admin_theme.dart';

const List<String> kDomaines = ['Sciences & Technologies', 'Sciences de Gestion', 'Sciences Humaines', 'Droit'];
const List<String> kNiveaux = ['Licence 1', 'Licence 2', 'Licence 3', 'Master 1', 'Master 2'];
const List<int> kSemestres = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
const List<String> kNationalitesProf = [
  'Burkinabè', 'Ivoirienne', 'Malienne', 'Nigérienne', 'Togolaise', 'Béninoise',
  'Ghanéenne', 'Sénégalaise', 'Guinéenne', 'Nigériane', 'Camerounaise', 'Française', 'Autre',
];
const List<String> kGrades = [
  'Professeur titulaire', 'Maître de conférences', 'Maître-assistant', 'Assistant',
  'Chargé de cours', 'Vacataire', 'Ingénieur formateur', 'Autre',
];
const List<String> kDiplomes = ['Licence', 'Master', 'Ingénieur', 'Doctorat (PhD)', 'Habilitation', 'Autre'];

const Color _bordureGris = Color(0xFFE5E7EB);
const Color _bordureChamp = Color(0xFFD1D5DB);
const Color _texteFonce = Color(0xFF1A1A2E);
const Color _texteGris = Color(0xFF6B7280);

// ── Utilitaires ───────────────────────────────────────────────────────────────
String _s(dynamic v) => v?.toString() ?? '';

List<Map<String, dynamic>> _liste(dynamic v) =>
    v is List ? v.map((e) => Map<String, dynamic>.from(e as Map)).toList() : <Map<String, dynamic>>[];

String _fmtDate(String iso) {
  final t = iso.length >= 10 ? iso.substring(0, 10) : iso;
  final p = t.split('-');
  if (p.length != 3) return iso;
  return '${p[2]}/${p[1]}/${p[0]}';
}

String _abrev(Map<String, dynamic> m) {
  final a = _s(m['abreviation']).trim();
  if (a.isNotEmpty) return a;
  final n = _s(m['filiere_nom']).trim();
  return n.length > 18 ? '${n.substring(0, 17)}…' : n;
}

/// Domaine d'une filière : colonne `domaine` si renseignée, sinon déduit du nom.
String _domaineDeFiliere(Map<String, dynamic> f) {
  final d = _s(f['domaine']).trim();
  if (d.isNotEmpty) return d;
  final n = _s(f['nom']).toLowerCase();
  final gestion = n.contains('marketing') || n.contains('gestion') || n.contains('finance') || n.contains('comptab');
  return gestion ? 'Sciences de Gestion' : 'Sciences & Technologies';
}

/// Pastilles « FIL · Niveau · S1 » d'un professeur.
List<String> _pastilles(Map<String, dynamic> p) {
  final mods = _liste(p['modules']);
  final affs = _liste(p['affectations']);
  final vus = <String>{};
  final out = <String>[];
  for (final m in mods) {
    final k = '${m['filiere_id']}|${m['niveau']}|${m['semestre']}';
    if (vus.add(k)) out.add('${_abrev(m)} · ${m['niveau']} · S${m['semestre']}');
  }
  final couverts = mods.map((m) => '${m['filiere_id']}|${m['niveau']}').toSet();
  for (final a in affs) {
    if (!couverts.contains('${a['filiere_id']}|${a['niveau']}')) {
      out.add('${_abrev(a)} · ${a['niveau']}');
    }
  }
  return out;
}

List<dynamic> _infoStatut(String statut) {
  switch (statut) {
    case 'actif':
      return ['Actif', AdminTheme.success, AdminTheme.successLight];
    case 'renvoye':
      return ['Renvoyé', AdminTheme.danger, AdminTheme.dangerLight];
    default:
      return ['Inactif', AdminTheme.warning, AdminTheme.warningLight];
  }
}

class _AvatarProf extends StatelessWidget {
  final Map<String, dynamic> prof;
  final double taille;
  const _AvatarProf({required this.prof, this.taille = 44});

  @override
  Widget build(BuildContext context) {
    final url = _s(prof['photo_url']);
    if (url.isNotEmpty) {
      return CircleAvatar(
        radius: taille / 2,
        backgroundColor: AdminTheme.primaryLight,
        backgroundImage: NetworkImage(url),
      );
    }
    final pre = _s(prof['prenoms']).trim();
    final nom = _s(prof['nom']).trim();
    final ini = '${pre.isNotEmpty ? pre[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase();
    return CircleAvatar(
      radius: taille / 2,
      backgroundColor: AdminTheme.primary,
      child: Text(ini, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: taille * 0.34)),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  PAGE LISTE
// ═════════════════════════════════════════════════════════════════════════════
class AdminProfesseurs extends StatefulWidget {
  final StudentProfile profile;
  const AdminProfesseurs({super.key, required this.profile});

  @override
  State<AdminProfesseurs> createState() => _AdminProfesseursState();
}

class _AdminProfesseursState extends State<AdminProfesseurs> {
  List<Map<String, dynamic>> _professeurs = [];
  List<Map<String, dynamic>> _filieres = [];
  bool _loading = true;
  String? _error;

  bool _formOuvert = false;
  Map<String, dynamic>? _profEdition;

  String _recherche = '';
  String _fDomaine = 'tous';
  String _fFiliere = 'toutes';
  String _fNiveau = 'tous';
  String _fStatut = 'tous';
  int _page = 0;
  static const int _parPage = 8;
  final Set<String> _coches = {};

  @override
  void initState() {
    super.initState();
    _charger();
  }

  List<String> get _domaines {
    final d = _filieres.map(_domaineDeFiliere).where((x) => x.isNotEmpty).toSet().toList()..sort();
    return d.isEmpty ? kDomaines : d;
  }

  Future<void> _charger({bool silencieux = false}) async {
    if (!silencieux) setState(() { _loading = true; _error = null; });
    try {
      final resFils = await ApiService.getFilieres();
      final resProfs = await ApiService.getProfesseurs();
      if (!mounted) return;
      setState(() {
        final allFilieres = resFils['success'] == true
            ? List<Map<String, dynamic>>.from(resFils['data'])
            : <Map<String, dynamic>>[];
        final allProfs = resProfs['success'] == true
            ? List<Map<String, dynamic>>.from(resProfs['data'])
            : <Map<String, dynamic>>[];

        if (widget.profile.filtreParDomaine) {
          final String df = widget.profile.domaineAdmin;
          _filieres = allFilieres.where((f) => _domaineDeFiliere(f) == df).toList();
          _professeurs = allProfs
              .where((p) => _s(p['domaine']).toLowerCase().contains(df.toLowerCase()))
              .toList();
        } else {
          _filieres = allFilieres;
          _professeurs = allProfs;
        }
        _coches.removeWhere((id) => !_professeurs.any((p) => _s(p['id']) == id));
        _loading = false;
        _error = (resFils['success'] == true && resProfs['success'] == true) ? null : 'Erreur de chargement.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Serveur injoignable.'; _loading = false; });
    }
  }

  void _snack(String msg, {required bool success}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  // ── Filtres ───────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filtres {
    final q = _recherche.trim().toLowerCase();
    return _professeurs.where((p) {
      if (_fStatut != 'tous' && _s(p['statut']) != _fStatut) return false;
      if (_fDomaine != 'tous' && !_s(p['domaine']).toLowerCase().contains(_fDomaine.toLowerCase())) return false;
      final affs = _liste(p['affectations']);
      final mods = _liste(p['modules']);
      if (_fFiliere != 'toutes') {
        final ok = affs.any((a) => _s(a['filiere_id']) == _fFiliere) ||
            mods.any((m) => _s(m['filiere_id']) == _fFiliere);
        if (!ok) return false;
      }
      if (_fNiveau != 'tous') {
        final ok = affs.any((a) => _s(a['niveau']) == _fNiveau) || mods.any((m) => _s(m['niveau']) == _fNiveau);
        if (!ok) return false;
      }
      if (q.isNotEmpty) {
        final texte = [
          p['nom'], p['prenoms'], p['email'], p['tel'], p['domaine'],
          ...affs.map((a) => a['filiere_nom']),
          ...mods.map((m) => m['module_nom']),
        ].map(_s).join(' ').toLowerCase();
        if (!texte.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  void _ouvrirForm([Map<String, dynamic>? prof]) {
    setState(() { _profEdition = prof; _formOuvert = true; });
  }

  Future<void> _changerStatut(List<String> ids, String statut) async {
    int ok = 0;
    try {
      final headers = await ApiService.getHeaders();
      for (final id in ids) {
        final res = await http.put(
          Uri.parse('${ApiService.baseUrl}/professeurs/$id'),
          headers: headers,
          body: jsonEncode({'statut': statut}),
        );
        if (res.statusCode == 200) ok++;
      }
    } catch (_) {}
    _snack(
      ok == ids.length
          ? (statut == 'actif' ? 'Professeur(s) réactivé(s).' : 'Professeur(s) désactivé(s).')
          : 'Certaines modifications ont échoué.',
      success: ok == ids.length,
    );
    setState(() => _coches.clear());
    await _charger(silencieux: true);
  }

  Future<void> _supprimer(Map<String, dynamic> p) async {
    final nom = '${_s(p['prenoms'])} ${_s(p['nom'])}';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer le prof. $nom ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.delete(Uri.parse('${ApiService.baseUrl}/professeurs/${p['id']}'), headers: headers);
      if (res.statusCode == 200) {
        _snack('Professeur supprimé.', success: true);
        await _charger(silencieux: true);
      } else {
        _snack('Erreur lors de la suppression.', success: false);
      }
    } catch (e) {
      _snack('Serveur injoignable.', success: false);
    }
  }

  void _voir(Map<String, dynamic> p) {
    showDialog(
      context: context,
      builder: (dctx) => _FicheProfDialog(
        prof: p,
        onModifier: () {
          Navigator.pop(dctx);
          _ouvrirForm(p);
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _formOuvert
          ? _FormulaireProfPage(
              key: ValueKey('form-${_profEdition?['id'] ?? 'new'}'),
              profile: widget.profile,
              allFilieres: _filieres,
              domaines: _domaines,
              prof: _profEdition,
              onRetour: () => setState(() { _formOuvert = false; _profEdition = null; }),
              onTermine: (edition) async {
                await _charger(silencieux: true);
                if (!mounted) return;
                setState(() { _formOuvert = false; _profEdition = null; });
                _snack(
                  edition
                      ? 'Professeur mis à jour avec succès.'
                      : 'Professeur créé. Il pourra se connecter avec son nom, prénom et téléphone.',
                  success: true,
                );
              },
              onErreur: (m) => _snack(m, success: false),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _charger, child: const Text('Réessayer')),
                      ]),
                    )
                  : _vueListe(),
    );
  }

  Widget _vueListe() {
    final liste = _filtres;
    final nbPages = liste.isEmpty ? 1 : ((liste.length - 1) ~/ _parPage) + 1;
    if (_page >= nbPages) _page = nbPages - 1;
    final debut = _page * _parPage;
    final fin = (debut + _parPage) > liste.length ? liste.length : debut + _parPage;
    final visibles = liste.isEmpty ? <Map<String, dynamic>>[] : liste.sublist(debut, fin);

    return RefreshIndicator(
      onRefresh: () => _charger(silencieux: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gestion des professeurs',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _texteFonce)),
            const SizedBox(height: 2),
            const Text('Consultez les profils, les affectations et les modules enseignés.',
                style: TextStyle(fontSize: 13, color: _texteGris)),
            const SizedBox(height: 16),
            _kpis(),
            const SizedBox(height: 16),
            _barreFiltres(),
            if (_coches.isNotEmpty) ...[const SizedBox(height: 10), _barreSelection()],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _bordureGris),
              ),
              child: Column(
                children: [
                  if (visibles.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('Aucun professeur ne correspond.', style: TextStyle(color: Colors.grey, fontSize: 15)),
                    )
                  else
                    LayoutBuilder(builder: (_, c) => c.maxWidth >= 900 ? _tableau(visibles) : _cartes(visibles)),
                  const SizedBox(height: 12),
                  _pagination(liste.length, debut, fin, nbPages),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── KPI ───────────────────────────────────────────────────────────────────
  Widget _kpis() {
    final domaines = <String>{};
    final classes = <String>{};
    int modules = 0;
    for (final p in _professeurs) {
      for (final d in _s(p['domaine']).split(',')) {
        if (d.trim().isNotEmpty) domaines.add(d.trim());
      }
      for (final a in _liste(p['affectations'])) {
        classes.add('${a['filiere_id']}|${a['niveau']}');
      }
      final mods = _liste(p['modules']);
      for (final m in mods) {
        classes.add('${m['filiere_id']}|${m['niveau']}');
      }
      modules += mods.length;
    }
    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth >= 760 ? 4 : 2;
      final w = (c.maxWidth - (cols - 1) * 12) / cols;
      Widget k(IconData ic, Color fg, Color bg, String val, String label) => SizedBox(
            width: w,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _bordureGris),
              ),
              child: Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: fg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(ic, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _texteFonce)),
                    Text(label, style: const TextStyle(fontSize: 12.5, color: _texteGris), overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ]),
            ),
          );
      return Wrap(spacing: 12, runSpacing: 12, children: [
        k(Icons.person_rounded, AdminTheme.primary, AdminTheme.primaryLight, '${_professeurs.length}', 'Professeurs'),
        k(Icons.school_rounded, AdminTheme.warning, AdminTheme.warningLight, '${domaines.length}', 'Domaines'),
        k(Icons.account_tree_rounded, AdminTheme.success, AdminTheme.successLight, '${classes.length}', 'Filières / niveaux'),
        k(Icons.menu_book_rounded, const Color(0xFF7C3AED), AdminTheme.infoLight, '$modules', 'Modules attribués'),
      ]);
    });
  }

  // ── Filtres ───────────────────────────────────────────────────────────────
  Widget _liste_(String label, String value, List<String> vals, List<String> labels, ValueChanged<String?> on) {
    return SizedBox(
      width: 170,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _bordureGris)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _bordureGris)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: vals.contains(value) ? value : vals.first,
            isDense: true,
            isExpanded: true,
            style: const TextStyle(fontSize: 13, color: _texteFonce),
            items: [for (int i = 0; i < vals.length; i++) DropdownMenuItem(value: vals[i], child: Text(labels[i], overflow: TextOverflow.ellipsis))],
            onChanged: on,
          ),
        ),
      ),
    );
  }

  Widget _barreFiltres() {
    final domaines = _domaines;
    final niveaux = <String>{...kNiveaux};
    for (final p in _professeurs) {
      for (final a in _liste(p['affectations'])) {
        if (_s(a['niveau']).isNotEmpty) niveaux.add(_s(a['niveau']));
      }
    }
    final filieres = [..._filieres]..sort((a, b) => _s(a['nom']).compareTo(_s(b['nom'])));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _bordureGris),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            height: 44,
            child: TextField(
              onChanged: (v) => setState(() { _recherche = v; _page = 0; }),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher un professeur…',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _bordureGris)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _bordureGris)),
              ),
            ),
          ),
          _liste_('Domaine', _fDomaine, ['tous', ...domaines], ['Tous les domaines', ...domaines],
              (v) => setState(() { _fDomaine = v ?? 'tous'; _page = 0; })),
          _liste_('Filière', _fFiliere, ['toutes', ...filieres.map((f) => _s(f['id']))],
              ['Toutes les filières', ...filieres.map((f) => _s(f['nom']))],
              (v) => setState(() { _fFiliere = v ?? 'toutes'; _page = 0; })),
          _liste_('Niveau', _fNiveau, ['tous', ...niveaux], ['Tous les niveaux', ...niveaux],
              (v) => setState(() { _fNiveau = v ?? 'tous'; _page = 0; })),
          _liste_('Statut', _fStatut, ['tous', 'actif', 'inactif', 'renvoye'],
              ['Tous les statuts', 'Actif', 'Inactif', 'Renvoyé'],
              (v) => setState(() { _fStatut = v ?? 'tous'; _page = 0; })),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _ouvrirForm(),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Ajouter un professeur', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barreSelection() {
    final ids = _coches.toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AdminTheme.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('${ids.length} sélectionné(s)',
              style: const TextStyle(fontWeight: FontWeight.w700, color: _texteFonce, fontSize: 13)),
          TextButton.icon(
            onPressed: () => _changerStatut(ids, 'actif'),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Réactiver'),
          ),
          TextButton.icon(
            onPressed: () => _changerStatut(ids, 'inactif'),
            icon: const Icon(Icons.pause_circle_outline, size: 18),
            label: const Text('Désactiver'),
          ),
          TextButton(onPressed: () => setState(_coches.clear), child: const Text('Annuler')),
        ],
      ),
    );
  }

  // ── Tableau (écran large) ─────────────────────────────────────────────────
  Widget _tableau(List<Map<String, dynamic>> lignes) {
    final toutes = lignes.every((p) => _coches.contains(_s(p['id'])));
    Widget th(String t, {int flex = 1, double? w}) {
      final child = Text(t, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _texteFonce));
      return w != null ? SizedBox(width: w, child: child) : Expanded(flex: flex, child: child);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            SizedBox(
              width: 40,
              child: Checkbox(
                value: toutes,
                onChanged: (v) => setState(() {
                  for (final p in lignes) {
                    if (v == true) {
                      _coches.add(_s(p['id']));
                    } else {
                      _coches.remove(_s(p['id']));
                    }
                  }
                }),
              ),
            ),
            th('Professeur', flex: 26),
            th('Domaines', flex: 17),
            th('Filières & niveaux', flex: 24),
            th('Modules attribués', flex: 12),
            th('Statut', flex: 10),
            th('Actions', w: 150),
          ]),
        ),
        for (final p in lignes) _ligneTableau(p),
      ],
    );
  }

  Widget _ligneTableau(Map<String, dynamic> p) {
    final id = _s(p['id']);
    final domaines = _s(p['domaine']).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final nbMods = _liste(p['modules']).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(
          width: 40,
          child: Checkbox(
            value: _coches.contains(id),
            onChanged: (v) => setState(() { v == true ? _coches.add(id) : _coches.remove(id); }),
          ),
        ),
        Expanded(
          flex: 26,
          child: InkWell(
            onTap: () => _voir(p),
            child: Row(children: [
              _AvatarProf(prof: p, taille: 44),
              const SizedBox(width: 10),
              Expanded(child: _blocIdentite(p)),
            ]),
          ),
        ),
        Expanded(
          flex: 17,
          child: Wrap(spacing: 4, runSpacing: 4, children: [
            for (final d in domaines) _badgeDomaine(d),
            if (domaines.isEmpty) const Text('—', style: TextStyle(color: _texteGris)),
          ]),
        ),
        Expanded(flex: 24, child: _blocPastilles(p)),
        Expanded(
          flex: 12,
          child: InkWell(
            onTap: () => _voir(p),
            child: Row(children: [
              const Icon(Icons.menu_book_outlined, size: 18, color: AdminTheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text('$nbMods module${nbMods > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12.5, color: _texteFonce), overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.chevron_right, size: 16, color: _texteGris),
            ]),
          ),
        ),
        Expanded(flex: 10, child: Align(alignment: Alignment.centerLeft, child: _badgeStatut(_s(p['statut']))),),
        SizedBox(width: 150, child: _actions(p)),
      ]),
    );
  }

  // ── Cartes (écran étroit) ─────────────────────────────────────────────────
  Widget _cartes(List<Map<String, dynamic>> lignes) {
    return Column(
      children: [
        for (final p in lignes)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _bordureGris),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Checkbox(
                  value: _coches.contains(_s(p['id'])),
                  onChanged: (v) => setState(() { v == true ? _coches.add(_s(p['id'])) : _coches.remove(_s(p['id'])); }),
                ),
                _AvatarProf(prof: p, taille: 42),
                const SizedBox(width: 10),
                Expanded(child: InkWell(onTap: () => _voir(p), child: _blocIdentite(p))),
                _badgeStatut(_s(p['statut'])),
              ]),
              const SizedBox(height: 8),
              _blocPastilles(p),
              const SizedBox(height: 6),
              Row(children: [
                InkWell(
                  onTap: () => _voir(p),
                  child: Text('${_liste(p['modules']).length} module(s) ›',
                      style: const TextStyle(fontSize: 12.5, color: AdminTheme.primary, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                _actions(p),
              ]),
            ]),
          ),
      ],
    );
  }

  Widget _blocIdentite(Map<String, dynamic> p) {
    final tel = _s(p['tel']);
    final email = _s(p['email']);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${_s(p['prenoms'])} ${_s(p['nom'])}'.toUpperCase(),
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _texteFonce), overflow: TextOverflow.ellipsis),
      if (tel.isNotEmpty)
        Row(children: [
          const Icon(Icons.phone, size: 12, color: _texteGris),
          const SizedBox(width: 4),
          Flexible(child: Text(tel, style: const TextStyle(fontSize: 12, color: _texteGris), overflow: TextOverflow.ellipsis)),
        ]),
      if (email.isNotEmpty)
        Row(children: [
          const Icon(Icons.mail_outline, size: 12, color: _texteGris),
          const SizedBox(width: 4),
          Flexible(child: Text(email, style: const TextStyle(fontSize: 12, color: _texteGris), overflow: TextOverflow.ellipsis)),
        ]),
    ]);
  }

  Widget _blocPastilles(Map<String, dynamic> p) {
    final past = _pastilles(p);
    if (past.isEmpty) {
      return const Text('Aucune affectation', style: TextStyle(fontSize: 12, color: _texteGris));
    }
    final montrer = past.take(3).toList();
    return Wrap(spacing: 4, runSpacing: 4, children: [
      for (final t in montrer) _pastille(t),
      if (past.length > 3)
        InkWell(
          onTap: () => _voir(p),
          child: _pastille('+${past.length - 3}', fort: true),
        ),
    ]);
  }

  Widget _pastille(String t, {bool fort = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: fort ? AdminTheme.primaryLight : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(t,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fort ? AdminTheme.primary : const Color(0xFF334155))),
      );

  Widget _badgeDomaine(String d) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.school_outlined, size: 13, color: AdminTheme.primary),
          const SizedBox(width: 4),
          Flexible(child: Text(d, style: const TextStyle(fontSize: 11, color: AdminTheme.primary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        ]),
      );

  Widget _badgeStatut(String statut) {
    final i = _infoStatut(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: i[2] as Color, borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(statut == 'actif' ? Icons.check_circle : Icons.circle, size: 13, color: i[1] as Color),
        const SizedBox(width: 4),
        Text(i[0] as String, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: i[1] as Color)),
      ]),
    );
  }

  Widget _actions(Map<String, dynamic> p) {
    Widget bouton(IconData ic, VoidCallback on, String tip) => Tooltip(
          message: tip,
          child: InkWell(
            onTap: on,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _bordureGris),
              ),
              child: Icon(ic, size: 18, color: AdminTheme.primary),
            ),
          ),
        );
    final actif = _s(p['statut']) == 'actif';
    return Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
      bouton(Icons.visibility_outlined, () => _voir(p), 'Voir'),
      bouton(Icons.edit_outlined, () => _ouvrirForm(p), 'Modifier'),
      PopupMenuButton<String>(
        tooltip: 'Plus',
        onSelected: (v) {
          if (v == 'statut') _changerStatut([_s(p['id'])], actif ? 'inactif' : 'actif');
          if (v == 'suppr') _supprimer(p);
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'statut', child: Text(actif ? 'Désactiver' : 'Réactiver')),
          const PopupMenuItem(value: 'suppr', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _bordureGris),
          ),
          child: const Icon(Icons.more_vert, size: 18, color: _texteFonce),
        ),
      ),
    ]);
  }

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
              border: Border.all(color: actif ? AdminTheme.primary : _bordureGris),
            ),
            child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: actif ? Colors.white : const Color(0xFF374151))),
          ),
        );
    int d = _page - 2 < 0 ? 0 : _page - 2;
    int f = d + 4 >= nbPages ? nbPages - 1 : d + 4;
    d = f - 4 < 0 ? 0 : f - 4;
    return Row(children: [
      Expanded(
        child: Text(
          total == 0 ? 'Aucun résultat' : 'Affichage de ${debut + 1} à $fin sur $total professeur${total > 1 ? 's' : ''}',
          style: const TextStyle(fontSize: 12, color: _texteGris),
        ),
      ),
      if (_page > 0) bouton('‹', _page - 1),
      for (int p = d; p <= f; p++) bouton('${p + 1}', p, actif: p == _page),
      if (_page < nbPages - 1) bouton('›', _page + 1),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  FICHE (œil)
// ═════════════════════════════════════════════════════════════════════════════
class _FicheProfDialog extends StatelessWidget {
  final Map<String, dynamic> prof;
  final VoidCallback onModifier;
  const _FicheProfDialog({required this.prof, required this.onModifier});

  Widget _ligne(String l, String v) => v.trim().isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 130, child: Text(l, style: const TextStyle(fontSize: 12.5, color: _texteGris))),
            Expanded(child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _texteFonce))),
          ]),
        );

  @override
  Widget build(BuildContext context) {
    final mods = _liste(prof['modules']);
    final affs = _liste(prof['affectations']);
    final sexe = _s(prof['sexe']) == 'F' ? 'Femme' : (_s(prof['sexe']) == 'M' ? 'Homme' : '');
    final naiss = _s(prof['date_naissance']).isEmpty ? '' : _fmtDate(_s(prof['date_naissance']));
    final lieu = _s(prof['lieu_naissance']);
    final statut = _infoStatut(_s(prof['statut']));

    // Regroupe les modules par filière / niveau / semestre
    final groupes = <String, List<Map<String, dynamic>>>{};
    for (final m in mods) {
      groupes.putIfAbsent('${_s(m['filiere_nom'])}|${m['niveau']}|${m['semestre']}', () => []).add(m);
    }
    final couverts = mods.map((m) => '${m['filiere_id']}|${m['niveau']}').toSet();
    final sansModules = affs.where((a) => !couverts.contains('${a['filiere_id']}|${a['niveau']}')).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 640),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
            child: Row(children: [
              _AvatarProf(prof: prof, taille: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${_s(prof['prenoms'])} ${_s(prof['nom'])}'.toUpperCase(),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _texteFonce)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: statut[2] as Color, borderRadius: BorderRadius.circular(12)),
                    child: Text(statut[0] as String,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: statut[1] as Color)),
                  ),
                ]),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Informations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _texteFonce)),
                const SizedBox(height: 6),
                _ligne('Téléphone', _s(prof['tel'])),
                _ligne('Email', _s(prof['email'])),
                _ligne('Sexe', sexe),
                _ligne('Date de naissance', naiss),
                _ligne('Lieu de naissance', lieu),
                _ligne('Nationalité', _s(prof['nationalite'])),
                _ligne('Matricule', _s(prof['matricule'])),
                _ligne('Grade / Fonction', _s(prof['grade'])),
                _ligne('Spécialité', _s(prof['expertise'])),
                _ligne('Diplôme', _s(prof['diplome'])),
                _ligne('Domaines', _s(prof['domaine']).replaceAll(',', ', ')),
                _ligne('Note', _s(prof['note'])),
                const SizedBox(height: 16),
                Text('Affectations et modules (${mods.length})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _texteFonce)),
                const SizedBox(height: 8),
                if (groupes.isEmpty && sansModules.isEmpty)
                  const Text('Aucune affectation.', style: TextStyle(color: _texteGris, fontSize: 13)),
                for (final e in groupes.entries)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _bordureGris),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        '${e.key.split('|')[0]} · ${e.key.split('|')[1]} · Semestre ${e.key.split('|')[2]}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _texteFonce),
                      ),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        for (final m in e.value)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(14)),
                            child: Text(_s(m['module_nom']),
                                style: const TextStyle(fontSize: 11.5, color: AdminTheme.primary, fontWeight: FontWeight.w600)),
                          ),
                      ]),
                    ]),
                  ),
                for (final a in sansModules)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('${_s(a['filiere_nom'])} · ${_s(a['niveau'])} — aucun module affecté',
                        style: const TextStyle(fontSize: 12.5, color: _texteGris)),
                  ),
              ]),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onModifier,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Modifier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  FORMULAIRE — page complète (ajout / modification)
// ═════════════════════════════════════════════════════════════════════════════
class _Aff {
  String? fid;
  String? niveau;
  int semestre = 1;
  final Set<int> modules = {};
}

class _FormulaireProfPage extends StatefulWidget {
  final StudentProfile profile;
  final List<Map<String, dynamic>> allFilieres;
  final List<String> domaines;
  final Map<String, dynamic>? prof;
  final VoidCallback onRetour;
  final Future<void> Function(bool edition) onTermine;
  final void Function(String) onErreur;

  const _FormulaireProfPage({
    super.key,
    required this.profile,
    required this.allFilieres,
    required this.domaines,
    required this.onRetour,
    required this.onTermine,
    required this.onErreur,
    this.prof,
  });

  @override
  State<_FormulaireProfPage> createState() => _FormulaireProfPageState();
}

class _FormulaireProfPageState extends State<_FormulaireProfPage> {
  final _nomCtrl = TextEditingController();
  final _prenomsCtrl = TextEditingController();
  final _lieuCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _matriculeCtrl = TextEditingController();
  final _expertiseCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _natAutreCtrl = TextEditingController();

  String _dateNaissance = '';
  String? _sexe; // 'M' | 'F'
  String? _nationalite;
  String? _grade;
  String? _diplome;

  Uint8List? _photoBytes;
  String? _photoNom;
  String _photoUrl = '';

  final Set<String> _domainesSel = {};
  final Set<String> _filieresSel = {};
  final Set<String> _niveauxSel = {};
  final List<_Aff> _lignes = [];
  String _rechFiliere = '';

  final Map<String, List<Map<String, dynamic>>> _modulesParFiliere = {};
  final Set<String> _modEnCharge = {};
  List<Map<String, dynamic>> _existants = [];

  bool _saving = false;
  String? _erreur;

  bool get _edition => widget.prof != null;

  @override
  void initState() {
    super.initState();
    final p = widget.prof;
    if (p != null) {
      _nomCtrl.text = _s(p['nom']);
      _prenomsCtrl.text = _s(p['prenoms']);
      _telCtrl.text = _s(p['tel']);
      _emailCtrl.text = _s(p['email']);
      _lieuCtrl.text = _s(p['lieu_naissance']);
      _matriculeCtrl.text = _s(p['matricule']);
      _expertiseCtrl.text = _s(p['expertise']);
      _noteCtrl.text = _s(p['note']);
      final dn = _s(p['date_naissance']);
      _dateNaissance = dn.length >= 10 ? dn.substring(0, 10) : '';
      final sx = _s(p['sexe']);
      _sexe = (sx == 'M' || sx == 'F') ? sx : null;
      final nat = _s(p['nationalite']);
      if (nat.isNotEmpty) {
        if (kNationalitesProf.contains(nat)) {
          _nationalite = nat;
        } else {
          _nationalite = 'Autre';
          _natAutreCtrl.text = nat;
        }
      }
      final g = _s(p['grade']);
      if (g.isNotEmpty) _grade = kGrades.contains(g) ? g : 'Autre';
      final dp = _s(p['diplome']);
      if (dp.isNotEmpty) _diplome = kDiplomes.contains(dp) ? dp : 'Autre';
      _photoUrl = _s(p['photo_url']);

      for (final d in _s(p['domaine']).split(',')) {
        final t = d.trim();
        if (widget.domaines.contains(t)) _domainesSel.add(t);
      }

      _existants = _liste(p['modules']);
      final groupes = <String, _Aff>{};
      for (final m in _existants) {
        final fid = _s(m['filiere_id']);
        final niv = _s(m['niveau']);
        final sem = int.tryParse(_s(m['semestre'])) ?? 1;
        final mid = int.tryParse(_s(m['module_id']));
        if (fid.isEmpty || niv.isEmpty || mid == null) continue;
        final a = groupes.putIfAbsent('$fid|$niv|$sem', () => _Aff()
          ..fid = fid
          ..niveau = niv
          ..semestre = sem);
        a.modules.add(mid);
      }
      _lignes.addAll(groupes.values);
      final couverts = groupes.values.map((a) => '${a.fid}|${a.niveau}').toSet();
      for (final a in _liste(p['affectations'])) {
        final fid = _s(a['filiere_id']);
        final niv = _s(a['niveau']);
        if (fid.isEmpty || niv.isEmpty || couverts.contains('$fid|$niv')) continue;
        _lignes.add(_Aff()
          ..fid = fid
          ..niveau = niv);
        couverts.add('$fid|$niv');
      }
      for (final a in _lignes) {
        _filieresSel.add(a.fid!);
        _niveauxSel.add(a.niveau!);
        final f = widget.allFilieres.firstWhere((x) => _s(x['id']) == a.fid, orElse: () => <String, dynamic>{});
        if (f.isNotEmpty) _domainesSel.add(_domaineDeFiliere(f));
        _chargerModules(a.fid!);
      }
    } else if (widget.profile.filtreParDomaine && widget.profile.domaineAdmin.isNotEmpty) {
      _domainesSel.add(widget.profile.domaineAdmin);
    }
  }

  @override
  void dispose() {
    for (final c in [_nomCtrl, _prenomsCtrl, _lieuCtrl, _telCtrl, _emailCtrl, _matriculeCtrl, _expertiseCtrl, _noteCtrl, _natAutreCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Données ───────────────────────────────────────────────────────────────
  Future<void> _chargerModules(String fid) async {
    if (_modulesParFiliere.containsKey(fid) || _modEnCharge.contains(fid)) return;
    _modEnCharge.add(fid);
    final res = await ApiService.getModules(filiereId: fid);
    if (!mounted) return;
    setState(() {
      _modulesParFiliere[fid] = res['success'] == true
          ? List<Map<String, dynamic>>.from(res['data'])
          : <Map<String, dynamic>>[];
      _modEnCharge.remove(fid);
    });
  }

  List<Map<String, dynamic>> get _filieresVisibles {
    if (_domainesSel.isEmpty) return [];
    final q = _rechFiliere.trim().toLowerCase();
    return widget.allFilieres.where((f) {
      if (!_domainesSel.contains(_domaineDeFiliere(f))) return false;
      return q.isEmpty || _s(f['nom']).toLowerCase().contains(q);
    }).toList();
  }

  String _nomFiliere(String? fid) {
    final f = widget.allFilieres.firstWhere((x) => _s(x['id']) == fid, orElse: () => <String, dynamic>{});
    return f.isEmpty ? '—' : _s(f['nom']);
  }

  int get _nbModulesTotal => _lignes.fold<int>(0, (n, a) => n + a.modules.length);

  // ── Actions ───────────────────────────────────────────────────────────────
  void _basculerDomaine(String d) {
    setState(() {
      if (_domainesSel.contains(d)) {
        _domainesSel.remove(d);
        final aRetirer = _filieresSel.where((fid) {
          final f = widget.allFilieres.firstWhere((x) => _s(x['id']) == fid, orElse: () => <String, dynamic>{});
          return f.isNotEmpty && !_domainesSel.contains(_domaineDeFiliere(f));
        }).toList();
        for (final fid in aRetirer) {
          _filieresSel.remove(fid);
          _lignes.removeWhere((a) => a.fid == fid);
        }
      } else {
        _domainesSel.add(d);
      }
    });
  }

  void _basculerFiliere(String fid) {
    setState(() {
      if (_filieresSel.contains(fid)) {
        _filieresSel.remove(fid);
        _lignes.removeWhere((a) => a.fid == fid);
      } else {
        _filieresSel.add(fid);
        _chargerModules(fid);
      }
    });
  }

  void _basculerNiveau(String niv) {
    setState(() {
      if (_niveauxSel.contains(niv)) {
        _niveauxSel.remove(niv);
        _lignes.removeWhere((a) => a.niveau == niv);
      } else {
        _niveauxSel.add(niv);
      }
    });
  }

  void _ajouterLigne() {
    if (_filieresSel.isEmpty || _niveauxSel.isEmpty) {
      setState(() => _erreur = 'Cochez au moins une filière et un niveau avant d\'ajouter une affectation.');
      return;
    }
    final a = _Aff()
      ..fid = _filieresSel.first
      ..niveau = kNiveaux.firstWhere(_niveauxSel.contains, orElse: () => _niveauxSel.first);
    setState(() { _lignes.add(a); _erreur = null; });
    _chargerModules(a.fid!);
  }

  void _toutSelectionner() {
    setState(() {
      for (final a in _lignes) {
        final mods = _modulesParFiliere[a.fid] ?? [];
        for (final m in mods) {
          final id = int.tryParse(_s(m['id']));
          if (id != null) a.modules.add(id);
        }
      }
    });
  }

  Future<void> _choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateNaissance) ?? DateTime(1985, 1, 1),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(() => _dateNaissance =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
    }
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
      setState(() { _photoBytes = b; _photoNom = p.name; _erreur = null; });
    } catch (_) {
      setState(() => _erreur = 'Impossible de charger cette image.');
    }
  }

  Future<String?> _enregistrerProf(Map<String, dynamic> data, List<Map<String, String>> affectations) async {
    try {
      final headers = await ApiService.getHeaders();
      final id = widget.prof?['id'];
      final corps = jsonEncode({...data, 'affectations': affectations});
      final http.Response res = id == null
          ? await http.post(Uri.parse('${ApiService.baseUrl}/professeurs'), headers: headers, body: corps)
          : await http.put(Uri.parse('${ApiService.baseUrl}/professeurs/$id'), headers: headers, body: corps);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        return id?.toString() ?? body['professeur']?['id']?.toString();
      }
      String msg = 'Erreur lors de la sauvegarde.';
      try { msg = jsonDecode(res.body)['error']?.toString() ?? msg; } catch (_) {}
      setState(() => _erreur = msg);
      return null;
    } catch (e) {
      setState(() => _erreur = 'Serveur injoignable.');
      return null;
    }
  }

  Future<bool> _envoyerPhoto(String profId) async {
    try {
      final token = await ApiService.getToken();
      final req = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/professeurs/$profId/photo'));
      req.headers['Authorization'] = 'Bearer $token';
      req.files.add(http.MultipartFile.fromBytes('file', _photoBytes!, filename: _photoNom ?? 'photo.jpg'));
      final r = await http.Response.fromStream(await req.send());
      return r.statusCode >= 200 && r.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<void> _soumettre() async {
    String t(TextEditingController c) => c.text.trim();
    final natFinale = _nationalite == 'Autre' ? t(_natAutreCtrl) : (_nationalite ?? '');

    if (t(_nomCtrl).isEmpty || t(_prenomsCtrl).isEmpty || t(_telCtrl).isEmpty) {
      setState(() => _erreur = 'Nom, prénoms et téléphone sont obligatoires.');
      return;
    }
    if (!_edition) {
      if (t(_emailCtrl).isEmpty || !t(_emailCtrl).contains('@')) {
        setState(() => _erreur = 'Une adresse email valide est obligatoire.');
        return;
      }
      if (_dateNaissance.isEmpty || t(_lieuCtrl).isEmpty || _sexe == null || natFinale.isEmpty) {
        setState(() => _erreur = 'Date et lieu de naissance, sexe et nationalité sont obligatoires.');
        return;
      }
    }
    if (_domainesSel.isEmpty) {
      setState(() => _erreur = 'Sélectionnez au moins un domaine d\'enseignement.');
      return;
    }
    if (!_edition && _lignes.isEmpty) {
      setState(() => _erreur = 'Ajoutez au moins une affectation (filière, niveau, semestre).');
      return;
    }

    final paires = <String>{};
    final affectations = <Map<String, String>>[];
    for (final a in _lignes) {
      if (a.fid == null || a.niveau == null) continue;
      if (paires.add('${a.fid}|${a.niveau}')) {
        affectations.add({'filiere_id': a.fid!, 'niveau': a.niveau!});
      }
    }

    setState(() { _saving = true; _erreur = null; });

    final profId = await _enregistrerProf({
      'nom': t(_nomCtrl).toUpperCase(),
      'prenoms': t(_prenomsCtrl),
      'tel': t(_telCtrl),
      'email': t(_emailCtrl).isEmpty ? null : t(_emailCtrl),
      'domaines': _domainesSel.toList(),
      'sexe': _sexe ?? '',
      'date_naissance': _dateNaissance,
      'lieu_naissance': t(_lieuCtrl),
      'nationalite': natFinale,
      'matricule': t(_matriculeCtrl),
      'grade': _grade == 'Autre' ? 'Autre' : (_grade ?? ''),
      'expertise': t(_expertiseCtrl),
      'diplome': _diplome ?? '',
      'note': t(_noteCtrl),
    }, affectations);

    if (profId == null) {
      if (mounted) setState(() => _saving = false);
      return;
    }

    // ── Synchronisation des modules (professeur_modules) ───────────────────
    final voulus = <String, List<int>>{}; // 'moduleId|niveau' -> [fid, semestre]
    for (final a in _lignes) {
      if (a.fid == null || a.niveau == null) continue;
      final fidInt = int.tryParse(a.fid!);
      if (fidInt == null) continue;
      for (final mid in a.modules) {
        voulus['$mid|${a.niveau}'] = [fidInt, a.semestre];
      }
    }
    int echecs = 0;
    try {
      for (final e in voulus.entries) {
        final parts = e.key.split('|');
        final res = await ApiService.assignerModuleProfesseur(
          professeurId: profId,
          moduleId: int.parse(parts[0]),
          filiereId: e.value[0],
          niveau: parts[1],
          semestre: e.value[1],
        );
        if (res['success'] != true) echecs++;
      }
      for (final ancien in _existants) {
        final cle = '${_s(ancien['module_id'])}|${_s(ancien['niveau'])}';
        final affId = int.tryParse(_s(ancien['affectation_id']));
        if (affId != null && !voulus.containsKey(cle)) {
          await ApiService.retirerModuleProfesseur(professeurId: profId, affectationId: affId);
        }
      }
    } catch (e) {
      echecs++;
    }
    if (echecs > 0) widget.onErreur('$echecs affectation(s) de module n\'ont pas pu être enregistrées.');

    if (_photoBytes != null) {
      final ok = await _envoyerPhoto(profId);
      if (!ok) widget.onErreur('Professeur enregistré, mais la photo n\'a pas pu être envoyée.');
    }

    await widget.onTermine(_edition);
    if (mounted) setState(() => _saving = false);
  }

  // ── Widgets de base ───────────────────────────────────────────────────────
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: _bordureChamp)),
          child: child,
        ),
      );

  Widget _champ(String label, TextEditingController c, {IconData? icon, String? hint, bool req = false, TextInputType? type}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _lbl(label, req: req),
          _boite(
            child: Row(children: [
              if (icon != null) ...[Icon(icon, size: 18, color: _texteGris), const SizedBox(width: 8)],
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
          {IconData? icon, bool req = false, String Function(String)? aff}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _lbl(label, req: req),
          _boite(
            child: Row(children: [
              if (icon != null) ...[Icon(icon, size: 18, color: _texteGris), const SizedBox(width: 8)],
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: items.contains(value) ? value : null,
                    isExpanded: true,
                    hint: const Text('Sélectionner', style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF))),
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

  Widget _cols(List<Widget> ws) => LayoutBuilder(builder: (_, c) {
        if (c.maxWidth < 380) {
          return Column(children: [for (int i = 0; i < ws.length; i++) ...[if (i > 0) const SizedBox(height: 12), ws[i]]]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (int i = 0; i < ws.length; i++) ...[if (i > 0) const SizedBox(width: 12), Expanded(child: ws[i])]],
        );
      });

  Widget _carte({required Widget child, Color? fond}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: fond ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _bordureGris),
        ),
        child: child,
      );

  Widget _titreSection(IconData ic, String titre) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(color: AdminTheme.primary, shape: BoxShape.circle),
            child: Icon(ic, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(titre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _texteFonce)),
        ]),
      );

  Widget _avatarPhoto(double taille) {
    ImageProvider? img;
    if (_photoBytes != null) {
      img = MemoryImage(_photoBytes!);
    } else if (_photoUrl.isNotEmpty) {
      img = NetworkImage(_photoUrl);
    }
    return CircleAvatar(
      radius: taille / 2,
      backgroundColor: AdminTheme.primaryLight,
      backgroundImage: img,
      child: img == null ? Icon(Icons.person, size: taille * 0.55, color: AdminTheme.primary) : null,
    );
  }

  // ── Colonne 1 : informations personnelles ────────────────────────────────
  Widget _colInfos() => _carte(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _titreSection(Icons.person, 'Informations personnelles'),
          Row(children: [
            _avatarPhoto(84),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Photo d\'identité', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                const Text('JPG, PNG (max. 2 Mo) — facultative', style: TextStyle(fontSize: 11.5, color: _texteGris)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _choisirPhoto,
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: Text(_photoBytes == null && _photoUrl.isEmpty ? 'Choisir une photo' : 'Changer la photo'),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          _cols([
            _champ('Nom', _nomCtrl, icon: Icons.person_outline, hint: 'Ex. KABORE', req: true),
            _champ('Prénoms', _prenomsCtrl, icon: Icons.person_outline, hint: 'Ex. Issa', req: true),
          ]),
          const SizedBox(height: 12),
          _cols([
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _lbl('Date de naissance', req: !_edition),
              _boite(
                onTap: _choisirDate,
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: _texteGris),
                  const SizedBox(width: 8),
                  Text(_dateNaissance.isEmpty ? 'jj/mm/aaaa' : _fmtDate(_dateNaissance),
                      style: TextStyle(fontSize: 13, color: _dateNaissance.isEmpty ? const Color(0xFF9CA3AF) : const Color(0xFF111827))),
                ]),
              ),
            ]),
            _champ('Lieu de naissance', _lieuCtrl, icon: Icons.place_outlined, hint: 'Ex. Ouagadougou', req: !_edition),
          ]),
          const SizedBox(height: 12),
          _cols([
            _select('Sexe', _sexe == null ? null : (_sexe == 'F' ? 'Femme' : 'Homme'), ['Homme', 'Femme'],
                (v) => setState(() => _sexe = v == 'Femme' ? 'F' : (v == 'Homme' ? 'M' : null)),
                icon: Icons.wc, req: !_edition),
            _select('Nationalité', _nationalite, kNationalitesProf, (v) => setState(() => _nationalite = v),
                icon: Icons.flag_outlined, req: !_edition),
          ]),
          if (_nationalite == 'Autre') ...[
            const SizedBox(height: 12),
            _champ('Précisez la nationalité', _natAutreCtrl, icon: Icons.flag_outlined),
          ],
          const SizedBox(height: 12),
          _cols([
            _champ('Numéro de téléphone', _telCtrl, icon: Icons.phone_outlined, hint: 'Ex. 70 12 34 56', req: true, type: TextInputType.phone),
            _champ('Adresse email', _emailCtrl, icon: Icons.mail_outline, hint: 'Ex. professeur@exemple.com', req: !_edition, type: TextInputType.emailAddress),
          ]),
          const SizedBox(height: 12),
          _cols([
            _champ('Matricule (si disponible)', _matriculeCtrl, icon: Icons.badge_outlined, hint: 'Ex. RITL2-001'),
            _select('Grade / Fonction', _grade, kGrades, (v) => setState(() => _grade = v), icon: Icons.workspace_premium_outlined),
          ]),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.description_outlined, size: 18, color: AdminTheme.primary),
              const SizedBox(width: 8),
              const Text('Informations complémentaires',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
            ]),
          ),
          const SizedBox(height: 12),
          _cols([
            _champ('Spécialité / Expertise', _expertiseCtrl, icon: Icons.psychology_outlined, hint: 'Réseaux, Sécurité, Télécom…'),
            _select('Diplôme le plus élevé', _diplome, kDiplomes, (v) => setState(() => _diplome = v), icon: Icons.school_outlined),
          ]),
          const SizedBox(height: 12),
          _lbl('Note / Observations'),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: _bordureChamp)),
            child: TextField(
              controller: _noteCtrl,
              maxLines: 4,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(10),
                hintText: 'Informations supplémentaires (optionnel)…',
                hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
              ),
            ),
          ),
        ]),
      );

  // ── Colonne 2 : affectations académiques ─────────────────────────────────
  Widget _caseACocher(String label, bool coche, VoidCallback on) => InkWell(
        onTap: on,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: coche ? AdminTheme.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: coche ? AdminTheme.primary.withValues(alpha: 0.5) : _bordureGris),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(coche ? Icons.check_box : Icons.check_box_outline_blank, size: 20, color: coche ? AdminTheme.primary : const Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Flexible(child: Text(label, style: const TextStyle(fontSize: 13, color: _texteFonce))),
          ]),
        ),
      );

  Widget _mini<T>(String label, T? value, List<T> items, String Function(T) aff, ValueChanged<T?> on, {double w = 150}) => SizedBox(
        width: w,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _bordureChamp)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: items.contains(value) ? value : null,
              isDense: true,
              isExpanded: true,
              style: const TextStyle(fontSize: 12.5, color: _texteFonce),
              items: [for (final i in items) DropdownMenuItem<T>(value: i, child: Text(aff(i), overflow: TextOverflow.ellipsis))],
              onChanged: on,
            ),
          ),
        ),
      );

  Widget _ligneAffectation(int index) {
    final a = _lignes[index];
    final modules = a.fid == null ? null : _modulesParFiliere[a.fid!];
    if (a.fid != null && modules == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _chargerModules(a.fid!));
    }
    final filieresDispo = _filieresSel.toList();
    final niveauxDispo = kNiveaux.where(_niveauxSel.contains).toList() +
        _niveauxSel.where((n) => !kNiveaux.contains(n)).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _bordureGris),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              _mini<String>('Filière', a.fid, filieresDispo, _nomFiliere, (v) {
                setState(() { a.fid = v; a.modules.clear(); });
                if (v != null) _chargerModules(v);
              }, w: 230),
              _mini<String>('Niveau', a.niveau, niveauxDispo, (x) => x, (v) => setState(() => a.niveau = v), w: 130),
              _mini<int>('Semestre', a.semestre, kSemestres, (x) => 'S$x', (v) => setState(() => a.semestre = v ?? 1), w: 100),
            ]),
          ),
          IconButton(
            tooltip: 'Supprimer cette affectation',
            onPressed: () => setState(() => _lignes.removeAt(index)),
            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
          ),
        ]),
        const SizedBox(height: 10),
        const Text('Modules', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _texteGris)),
        const SizedBox(height: 6),
        if (a.fid == null)
          const Text('Choisissez une filière.', style: TextStyle(fontSize: 12, color: _texteGris))
        else if (modules == null)
          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
        else if (modules.isEmpty)
          const Text('Aucun module dans cette filière.', style: TextStyle(fontSize: 12, color: _texteGris))
        else
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final m in modules)
              if (int.tryParse(_s(m['id'])) != null)
                FilterChip(
                  label: Text(_s(m['nom']), style: TextStyle(fontSize: 12, color: a.modules.contains(int.parse(_s(m['id']))) ? AdminTheme.primary : _texteFonce)),
                  selected: a.modules.contains(int.parse(_s(m['id']))),
                  showCheckmark: false,
                  selectedColor: AdminTheme.primaryLight,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: a.modules.contains(int.parse(_s(m['id']))) ? AdminTheme.primary : _bordureGris),
                  onSelected: (v) => setState(() {
                    final id = int.parse(_s(m['id']));
                    v ? a.modules.add(id) : a.modules.remove(id);
                  }),
                ),
          ]),
      ]),
    );
  }

  Widget _colAffectations() {
    final visibles = _filieresVisibles;
    final niveaux = <String>[...kNiveaux, ..._niveauxSel.where((n) => !kNiveaux.contains(n))];
    return _carte(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _titreSection(Icons.check, 'Affectations académiques'),
        _lbl('Domaines d\'enseignement', req: true),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final d in widget.domaines) _caseACocher(d, _domainesSel.contains(d), () => _basculerDomaine(d)),
        ]),
        const SizedBox(height: 16),
        _lbl('Filières', req: true),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: _bordureChamp)),
          child: Row(children: [
            const Icon(Icons.search, size: 18, color: _texteGris),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _rechFiliere = v),
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Rechercher une filière…',
                  hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 230),
          decoration: BoxDecoration(border: Border.all(color: _bordureGris), borderRadius: BorderRadius.circular(8)),
          child: visibles.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(_domainesSel.isEmpty ? 'Sélectionnez d\'abord un domaine.' : 'Aucune filière trouvée.',
                      style: const TextStyle(fontSize: 12.5, color: _texteGris)),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final f in visibles)
                      InkWell(
                        onTap: () => _basculerFiliere(_s(f['id'])),
                        child: Container(
                          color: _filieresSel.contains(_s(f['id'])) ? AdminTheme.primaryLight : null,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                          child: Row(children: [
                            Icon(_filieresSel.contains(_s(f['id'])) ? Icons.check_box : Icons.check_box_outline_blank,
                                size: 20, color: _filieresSel.contains(_s(f['id'])) ? AdminTheme.primary : const Color(0xFF94A3B8)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_s(f['nom']), style: const TextStyle(fontSize: 13))),
                          ]),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _lbl('Niveaux', req: true),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final n in niveaux) _caseACocher(n, _niveauxSel.contains(n), () => _basculerNiveau(n)),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          const Expanded(
            child: Text.rich(TextSpan(
              text: 'Modules et semestres',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _texteFonce),
              children: [TextSpan(text: ' *', style: TextStyle(color: Color(0xFFDC2626)))],
            )),
          ),
          TextButton.icon(
            onPressed: _lignes.isEmpty ? null : _toutSelectionner,
            icon: const Icon(Icons.done_all, size: 16),
            label: const Text('Tout sélectionner', style: TextStyle(fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 6),
        if (_lignes.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('Cochez des filières et des niveaux, puis ajoutez une affectation pour choisir le semestre et les modules.',
                style: TextStyle(fontSize: 12.5, color: _texteGris)),
          ),
        for (int i = 0; i < _lignes.length; i++) _ligneAffectation(i),
        ElevatedButton.icon(
          onPressed: _ajouterLigne,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Ajouter une affectation', style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ]),
    );
  }

  // ── Colonne 3 : récapitulatif + photo ────────────────────────────────────
  Widget _colRecap() {
    Widget l(IconData ic, String t, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(children: [
            Icon(ic, size: 20, color: AdminTheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _texteFonce))),
            Text(v, style: const TextStyle(fontSize: 12.5, color: AdminTheme.primary, fontWeight: FontWeight.w600)),
          ]),
        );
    return Column(children: [
      _carte(
        fond: const Color(0xFFF8FBFF),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _titreSection(Icons.fact_check_outlined, 'Récapitulatif des affectations'),
          l(Icons.school_outlined, 'Domaines', '${_domainesSel.length} sélectionné(s)'),
          l(Icons.account_tree_outlined, 'Filières', '${_filieresSel.length} sélectionnée(s)'),
          l(Icons.layers_outlined, 'Niveaux', '${_niveauxSel.length} sélectionné(s)'),
          l(Icons.event_note_outlined, 'Affectations', '${_lignes.length} ligne(s)'),
          l(Icons.menu_book_outlined, 'Modules', '$_nbModulesTotal module(s)'),
        ]),
      ),
      const SizedBox(height: 14),
      _carte(
        child: Column(children: [
          Align(alignment: Alignment.centerLeft, child: _titreSection(Icons.photo_camera_outlined, 'Aperçu de la photo')),
          _avatarPhoto(110),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _choisirPhoto,
            icon: const Icon(Icons.photo_camera_outlined, size: 18),
            label: const Text('Changer la photo'),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEFCE8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info, size: 18, color: Color(0xFFF59E0B)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Un professeur peut enseigner plusieurs modules dans une même filière, plusieurs niveaux '
              'd\'une même filière, ou plusieurs filières dans différents domaines. Il se connecte avec '
              'son nom, prénom et téléphone, puis définit son mot de passe à la première connexion.',
              style: TextStyle(fontSize: 12, color: Color(0xFF713F12)),
            ),
          ),
        ]),
      ),
    ]);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          OutlinedButton.icon(
            onPressed: _saving ? null : widget.onRetour,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Retour'),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_edition ? 'Modifier le professeur' : 'Ajouter un professeur',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _texteFonce)),
              const Text('Renseignez les informations du professeur et ses affectations académiques.',
                  style: TextStyle(fontSize: 12.5, color: _texteGris)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (_, c) {
          if (c.maxWidth >= 1100) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 11, child: _colInfos()),
              const SizedBox(width: 16),
              Expanded(flex: 13, child: _colAffectations()),
              const SizedBox(width: 16),
              Expanded(flex: 8, child: _colRecap()),
            ]);
          }
          return Column(children: [
            _colInfos(),
            const SizedBox(height: 16),
            _colAffectations(),
            const SizedBox(height: 16),
            _colRecap(),
          ]);
        }),
        const SizedBox(height: 16),
        if (_erreur != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFECACA))),
            child: Text(_erreur!, style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C))),
          ),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlinedButton.icon(
            onPressed: _saving ? null : widget.onRetour,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Annuler'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(120, 46)),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _saving ? null : _soumettre,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_outlined, size: 18),
            label: Text(_saving ? 'Enregistrement…' : 'Enregistrer', style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(150, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
      ]),
    );
  }
}
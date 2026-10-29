import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../admin/admin_theme.dart';
import '../admin/admin_widgets.dart';
import '../services/api_service.dart';

// ════════════════════════════════════════════════════════════════════════════
// PARENTS — administration (multi-établissement : tout est filtré côté serveur)
// ════════════════════════════════════════════════════════════════════════════

const List<String> _kRelations = ['Père', 'Mère', 'Tuteur'];

// ── Modèles légers ──────────────────────────────────────────────────────────
class _Enfant {
  final int etudiantId;
  final String matricule, nom, prenoms, filiere, niveau, relation;
  _Enfant(Map<String, dynamic> j)
      : etudiantId = int.tryParse('${j['etudiantId'] ?? j['etudiant_id']}') ?? 0,
        matricule = '${j['matricule'] ?? ''}',
        nom = '${j['nom'] ?? ''}',
        prenoms = '${j['prenoms'] ?? ''}',
        filiere = '${j['filiere'] ?? j['filiere_nom'] ?? ''}',
        niveau = '${j['niveau'] ?? ''}',
        relation = '${j['relation'] ?? ''}';
  String get nomComplet => '$prenoms $nom'.trim();
}

class _Parent {
  final String id, nom, prenoms, tel, email, statut;
  final bool compteActif;
  final List<_Enfant> enfants;
  _Parent(Map<String, dynamic> j)
      : id = '${j['id']}',
        nom = '${j['nom'] ?? ''}',
        prenoms = '${j['prenoms'] ?? ''}',
        tel = '${j['tel'] ?? ''}',
        email = '${j['email'] ?? ''}',
        statut = '${j['statut'] ?? 'actif'}',
        compteActif = j['compte_actif'] == true,
        enfants = ((j['enfants'] as List?) ?? const [])
            .map((e) => _Enfant(Map<String, dynamic>.from(e as Map)))
            .toList();
  String get nomComplet => '$nom $prenoms'.trim();
  bool get inactif => statut == 'inactif';
  String get initiales =>
      '${nom.isNotEmpty ? nom[0] : '?'}${prenoms.isNotEmpty ? prenoms[0] : ''}'.toUpperCase();
}

class _EnAttente {
  final int etudiantId;
  final String matricule, nom, prenoms, filiere, niveau, nomParent, telParent, emailParent;
  _EnAttente(Map<String, dynamic> j)
      : etudiantId = int.tryParse('${j['etudiant_id']}') ?? 0,
        matricule = '${j['matricule'] ?? ''}',
        nom = '${j['nom'] ?? ''}',
        prenoms = '${j['prenoms'] ?? ''}',
        filiere = '${j['filiere_nom'] ?? ''}',
        niveau = '${j['niveau'] ?? ''}',
        nomParent = '${j['nom_parent'] ?? ''}'.trim(),
        telParent = '${j['tel_parent'] ?? ''}'.trim(),
        emailParent = '${j['email_parent'] ?? ''}'.trim();
  String get enfantComplet => '$prenoms $nom'.trim();

  /// « OUEDRAOGO Pascal » → nom = OUEDRAOGO, prénoms = Pascal. Les mots
  /// entièrement en majuscules au début forment le nom ; le reste, le prénom.
  /// Sans majuscules, le premier mot est le nom.
  List<String> get nomPrenomsParent {
    final mots = nomParent.split(RegExp(r'\s+')).where((m) => m.isNotEmpty).toList();
    if (mots.isEmpty) return ['', ''];
    int i = 0;
    while (i < mots.length && mots[i] == mots[i].toUpperCase() && mots[i] != mots[i].toLowerCase()) {
      i++;
    }
    if (i == 0) i = 1;
    if (i >= mots.length) return [mots.join(' '), ''];
    return [mots.sublist(0, i).join(' '), mots.sublist(i).join(' ')];
  }
}

// ── API ─────────────────────────────────────────────────────────────────────
class _ParentsApi {
  static Future<Map<String, dynamic>> _req(String method, String path, {Map<String, dynamic>? body}) async {
    try {
      final headers = await ApiService.getHeaders();
      final uri = Uri.parse('${ApiService.baseUrl}/parents$path');
      late http.Response r;
      switch (method) {
        case 'POST':   r = await http.post(uri, headers: headers, body: jsonEncode(body ?? {})); break;
        case 'PUT':    r = await http.put(uri, headers: headers, body: jsonEncode(body ?? {})); break;
        case 'PATCH':  r = await http.patch(uri, headers: headers, body: jsonEncode(body ?? {})); break;
        case 'DELETE': r = await http.delete(uri, headers: headers); break;
        default:       r = await http.get(uri, headers: headers);
      }
      final data = jsonDecode(utf8.decode(r.bodyBytes));
      if (data is Map && data['success'] == true) return Map<String, dynamic>.from(data);
      return {
        'success': false,
        'conflict': data is Map && data['conflict'] == true,
        'error': (data is Map ? data['message'] : null) ?? 'Erreur (${r.statusCode}).',
      };
    } catch (_) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> liste() => _req('GET', '');
  static Future<Map<String, dynamic>> lier(Map<String, dynamic> body) => _req('POST', '', body: body);
  static Future<Map<String, dynamic>> retirerLien(int etudiantId) => _req('DELETE', '/lien/$etudiantId');
  static Future<Map<String, dynamic>> modifier(String id, Map<String, dynamic> body) => _req('PUT', '/$id', body: body);
  static Future<Map<String, dynamic>> reinitialiser(String id) => _req('POST', '/$id/reinitialiser');
  static Future<Map<String, dynamic>> statut(String id, String statut) =>
      _req('PATCH', '/$id/statut', body: {'statut': statut});
}

// ════════════════════════════════════════════════════════════════════════════
// PAGE
// ════════════════════════════════════════════════════════════════════════════
class AdminParents extends StatefulWidget {
  const AdminParents({super.key});
  @override
  State<AdminParents> createState() => _AdminParentsState();
}

class _AdminParentsState extends State<AdminParents> {
  static const String _tousStatuts = 'Tous les statuts';
  static const String _toutesFilieres = 'Toutes les filières';
  static const List<String> _statuts = [
    _tousStatuts, 'Actif', 'En attente de connexion', 'Inactif', 'Rattachement en attente',
  ];

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filtreStatut = _tousStatuts;
  String _filtreFiliere = _toutesFilieres;

  List<_Parent> _parents = [];
  List<_EnAttente> _attente = [];
  bool _loading = true;
  String? _error;
  String? _selectionId; // parent affiché dans la fiche latérale (bureau)

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger({bool silencieux = false}) async {
    if (!mounted) return;
    if (!silencieux) setState(() { _loading = true; _error = null; });
    final r = await _ParentsApi.liste();
    if (!mounted) return;
    if (r['success'] != true) {
      setState(() { _loading = false; _error = r['error']?.toString() ?? 'Impossible de charger les parents.'; });
      return;
    }
    setState(() {
      _parents = ((r['parents'] as List?) ?? const [])
          .map((e) => _Parent(Map<String, dynamic>.from(e as Map))).toList();
      _attente = ((r['enfantsSansTuteurLie'] as List?) ?? const [])
          .map((e) => _EnAttente(Map<String, dynamic>.from(e as Map))).toList();
      _loading = false;
      _error = null;
      if (_selectionId != null && !_parents.any((p) => p.id == _selectionId)) _selectionId = null;
    });
  }

  // ── Filtres ───────────────────────────────────────────────────────────────
  List<String> get _filieres {
    final s = <String>{
      for (final p in _parents) for (final e in p.enfants) if (e.filiere.isNotEmpty) e.filiere,
      for (final a in _attente) if (a.filiere.isNotEmpty) a.filiere,
    }.toList()..sort();
    return [_toutesFilieres, ...s];
  }

  bool _matchTexte(String q, List<String> champs) => champs.any((c) => c.toLowerCase().contains(q));

  List<_Parent> get _parentsFiltres {
    if (_filtreStatut == 'Rattachement en attente') return [];
    final q = _query.trim().toLowerCase();
    return _parents.where((p) {
      if (_filtreStatut == 'Actif' && !(p.compteActif && !p.inactif)) return false;
      if (_filtreStatut == 'En attente de connexion' && !(!p.compteActif && !p.inactif)) return false;
      if (_filtreStatut == 'Inactif' && !p.inactif) return false;
      if (_filtreFiliere != _toutesFilieres && !p.enfants.any((e) => e.filiere == _filtreFiliere)) return false;
      if (q.isEmpty) return true;
      return _matchTexte(q, [p.nom, p.prenoms, p.tel, p.email]) ||
          p.enfants.any((e) => _matchTexte(q, [e.nom, e.prenoms, e.matricule]));
    }).toList();
  }

  List<_EnAttente> get _attenteFiltree {
    if (!(_filtreStatut == _tousStatuts || _filtreStatut == 'Rattachement en attente')) return [];
    final q = _query.trim().toLowerCase();
    return _attente.where((a) {
      if (_filtreFiliere != _toutesFilieres && a.filiere != _filtreFiliere) return false;
      if (q.isEmpty) return true;
      return _matchTexte(q, [a.nom, a.prenoms, a.matricule, a.nomParent, a.telParent]);
    }).toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.of(context).size.width >= 1000;
    final selection = _parents.where((p) => p.id == _selectionId).toList();
    final fiche = (large && selection.isNotEmpty) ? selection.first : null;

    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(children: [
            AdminPageHeader(
              title: 'Parents',
              subtitle: '${_parents.length} tuteur(s) lié(s) · ${_attente.length} en attente de rattachement',
              trailing: AdminAddButton(label: 'Lier un tuteur', onTap: () => _ouvrirFormulaire()),
            ),
            Expanded(child: _corps(large)),
          ]),
        ),
        if (fiche != null)
          Container(
            width: 390,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(left: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: _FicheParent(
              key: ValueKey(fiche.id),
              parent: fiche,
              onFermer: () => setState(() => _selectionId = null),
              onChange: () => _charger(silencieux: true),
              onRattacher: () => _ouvrirFormulaire(parentExistant: fiche),
              snack: _snack,
            ),
          ),
      ]),
    );
  }

  Widget _corps(bool large) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
          const SizedBox(height: 12),
          TextButton.icon(onPressed: _charger, icon: const Icon(Icons.refresh_rounded), label: const Text('Réessayer')),
        ]),
      );
    }

    final parents = _parentsFiltres;
    final attente = _attenteFiltree;
    final nbEtudiants = _parents.fold<int>(0, (s, p) => s + p.enfants.length);

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: EdgeInsets.fromLTRB(large ? 24 : 16, 8, large ? 24 : 16, 24),
        children: [
          // Statistiques
          LayoutBuilder(builder: (context, c) {
            final cartes = [
              _carteStat(Icons.family_restroom_rounded, '${_parents.length}', 'Parents liés', AdminTheme.primary, AdminTheme.primaryLight),
              _carteStat(Icons.school_rounded, '$nbEtudiants', 'Étudiants rattachés', AdminTheme.primary, AdminTheme.primaryLight),
              _carteStat(Icons.hourglass_top_rounded, '${_attente.length}', 'À confirmer', AdminTheme.warning, AdminTheme.warningLight),
            ];
            if (c.maxWidth < 560) {
              return Column(children: [
                for (final k in cartes) Padding(padding: const EdgeInsets.only(bottom: 8), child: k),
              ]);
            }
            return Row(children: [
              for (int i = 0; i < cartes.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: cartes[i]),
              ],
            ]);
          }),
          const SizedBox(height: 14),

          // Recherche + filtres
          LayoutBuilder(builder: (context, c) {
            final recherche = AdminSearchBar(
              controller: _searchCtrl,
              hintText: 'Rechercher un parent ou un enfant...',
              onChanged: (v) => setState(() => _query = v),
            );
            final f1 = _menuFiltre(_statuts, _filtreStatut, (v) => setState(() => _filtreStatut = v));
            final f2 = _menuFiltre(_filieres, _filtreFiliere, (v) => setState(() => _filtreFiliere = v));
            if (c.maxWidth < 700) {
              return Column(children: [
                recherche,
                const SizedBox(height: 8),
                Row(children: [Expanded(child: f1), const SizedBox(width: 8), Expanded(child: f2)]),
              ]);
            }
            return Row(children: [
              Expanded(flex: 3, child: recherche),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: f1),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: f2),
            ]);
          }),
          const SizedBox(height: 16),

          if (parents.isEmpty && attente.isEmpty)
            _vide()
          else ...[
            LayoutBuilder(builder: (context, c) {
              if (c.maxWidth >= 760) return _tableau(attente, parents, large);
              return Column(children: [
                for (final a in attente) Padding(padding: const EdgeInsets.only(bottom: 10), child: _ligneAttente(a)),
                for (final p in parents) Padding(padding: const EdgeInsets.only(bottom: 10), child: _ligneParent(p, large)),
              ]);
            }),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Affichage de ${parents.length + attente.length} élément(s) sur ${_parents.length + _attente.length}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _carteStat(IconData icone, String valeur, String libelle, Color couleur, Color fond) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: fond, shape: BoxShape.circle),
            child: Icon(icone, color: couleur, size: 22),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(valeur, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
            Text(libelle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ]),
        ]),
      );

  Widget _menuFiltre(List<String> options, String valeur, ValueChanged<String> onChanged) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: options.contains(valeur) ? valeur : options.first,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        ),
      );

  // ── Tableau (grand écran) ─────────────────────────────────────────────────
  static const _fNom = 30, _fContact = 28, _fRel = 12, _fEtu = 10, _fStatut = 17, _fAct = 22;

  Widget _tableau(List<_EnAttente> attente, List<_Parent> parents, bool large) {
    final lignes = <Widget>[
      for (final a in attente) _rangeeAttente(a),
      for (final p in parents) _rangeeParent(p, large),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        _enteteTableau(),
        for (int i = 0; i < lignes.length; i++) ...[
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          lignes[i],
        ],
      ]),
    );
  }

  Widget _enteteTableau() {
    Widget h(String t, int flex, {bool centre = false}) => Expanded(
          flex: flex,
          child: Text(t,
              textAlign: centre ? TextAlign.center : TextAlign.start,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        );
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        h('Nom du parent', _fNom),
        h('Téléphone / Email', _fContact),
        h('Relation', _fRel),
        h('Étudiants liés', _fEtu, centre: true),
        h('Statut', _fStatut),
        h('Actions', _fAct, centre: true),
      ]),
    );
  }

  Widget _avatar(String initiales, {Color fond = AdminTheme.primaryLight, Color texte = AdminTheme.primary}) => Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: fond, shape: BoxShape.circle),
        child: Center(child: Text(initiales, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: texte))),
      );

  Widget _contact(String tel, String email) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (tel.isNotEmpty)
          Row(children: [
            const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF94A3B8)),
            const SizedBox(width: 5),
            Flexible(child: Text(tel, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
          ]),
        if (email.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(children: [
              const Icon(Icons.mail_outline_rounded, size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 5),
              Flexible(child: Text(email, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
            ]),
          ),
        if (tel.isEmpty && email.isEmpty) const Text('—', style: TextStyle(color: Color(0xFF94A3B8))),
      ]);

  Widget _badgeRelation(String relation) {
    Color fond, texte;
    switch (relation) {
      case 'Père':
        fond = const Color(0xFFDBEAFE); texte = const Color(0xFF1D4ED8); break;
      case 'Mère':
        fond = const Color(0xFFFCE7F3); texte = const Color(0xFFBE185D); break;
      case 'Tuteur':
        fond = const Color(0xFFEDE9FE); texte = const Color(0xFF6D28D9); break;
      default:
        return const Text('—', style: TextStyle(color: Color(0xFF94A3B8)));
    }
    return _pastille(relation, fond, texte);
  }

  Widget _rangeeParent(_Parent p, bool large) {
    final selectionne = p.id == _selectionId && large;
    final (etiquette, fond, texte) = _badgeStatut(p);
    final relations = p.enfants.map((e) => e.relation).where((r) => r.isNotEmpty).toSet().toList();
    return InkWell(
      onTap: () => _voirFiche(p, large),
      child: Container(
        color: selectionne ? AdminTheme.primaryLight.withValues(alpha: 0.5) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            flex: _fNom,
            child: Row(children: [
              _avatar(p.initiales),
              const SizedBox(width: 10),
              Expanded(child: Text(p.nomComplet, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)))),
            ]),
          ),
          Expanded(flex: _fContact, child: _contact(p.tel, p.email)),
          Expanded(
            flex: _fRel,
            child: relations.isEmpty
                ? const Text('—')
                : Wrap(spacing: 4, runSpacing: 4, children: relations.map(_badgeRelation).toList()),
          ),
          Expanded(
            flex: _fEtu,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.people_alt_outlined, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 5),
              Text('${p.enfants.length}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
          ),
          Expanded(flex: _fStatut, child: Align(alignment: Alignment.centerLeft, child: _pastille(etiquette, fond, texte))),
          Expanded(
            flex: _fAct,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              OutlinedButton.icon(
                onPressed: () => _voirFiche(p, large),
                icon: const Icon(Icons.visibility_outlined, size: 15),
                label: const Text('Voir la fiche', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AdminTheme.primary,
                  side: BorderSide(color: AdminTheme.primary.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Plus d\'actions',
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF64748B)),
                onSelected: (v) {
                  if (v == 'fiche') _voirFiche(p, large);
                  if (v == 'rattacher') _ouvrirFormulaire(parentExistant: p);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'fiche', child: Text('Voir la fiche')),
                  PopupMenuItem(value: 'rattacher', child: Text('Rattacher un autre étudiant')),
                ],
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _rangeeAttente(_EnAttente a) {
    final np = a.nomPrenomsParent;
    final nomTuteur = [np[0], np[1]].where((x) => x.isNotEmpty).join(' ');
    final initiales = nomTuteur.isEmpty
        ? '?'
        : '${np[0].isNotEmpty ? np[0][0] : ''}${np[1].isNotEmpty ? np[1][0] : ''}'.toUpperCase();
    final manque = _champsManquants(a);
    final detailEtu = [a.enfantComplet, if (a.filiere.isNotEmpty) '(${a.filiere}${a.niveau.isNotEmpty ? ' - ${a.niveau}' : ''})'].join(' ');
    return Container(
      color: AdminTheme.warningLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
          flex: _fNom,
          child: Row(children: [
            _avatar(initiales, fond: Colors.white, texte: AdminTheme.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nomTuteur.isEmpty ? 'Tuteur non renseigné' : nomTuteur, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                Text('En attente : 1 étudiant → $detailEtu',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                if (manque.isNotEmpty)
                  Text('À compléter : ${manque.join(', ')}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AdminTheme.danger)),
              ]),
            ),
          ]),
        ),
        Expanded(flex: _fContact, child: _contact(a.telParent, a.emailParent)),
        const Expanded(flex: _fRel, child: Text('—', style: TextStyle(color: Color(0xFF94A3B8)))),
        const Expanded(
          flex: _fEtu,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.people_alt_outlined, size: 15, color: Color(0xFF64748B)),
            SizedBox(width: 5),
            Text('1', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ),
        Expanded(
          flex: _fStatut,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _pastille('Rattachement en attente', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
          ),
        ),
        Expanded(
          flex: _fAct,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton.icon(
              onPressed: () => _ouvrirFormulaire(attente: a),
              icon: const Icon(Icons.link_rounded, size: 15),
              label: const Text('Lier maintenant', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.white,
                foregroundColor: AdminTheme.primary,
                elevation: 0,
                side: BorderSide(color: AdminTheme.primary.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Ligne : rattachement en attente ───────────────────────────────────────
  Widget _ligneAttente(_EnAttente a) {
    final mots = a.nomParent.isNotEmpty ? a.nomParent : 'Tuteur non renseigné';
    final manque = _champsManquants(a);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminTheme.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.hourglass_top_rounded, color: AdminTheme.warning, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.enfantComplet,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 2),
            Text(
              '${a.matricule} · Tuteur renseigné : $mots${a.telParent.isNotEmpty ? ' (${a.telParent})' : ''}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            if (manque.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('À compléter : ${manque.join(', ')}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AdminTheme.danger)),
              ),
          ]),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _ouvrirFormulaire(attente: a),
          icon: const Icon(Icons.link_rounded, size: 16),
          label: const Text('Lier maintenant', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  List<String> _champsManquants(_EnAttente a) {
    final np = a.nomPrenomsParent;
    return [
      if (np[0].isEmpty) 'nom',
      if (np[1].isEmpty) 'prénom',
      if (a.telParent.isEmpty) 'téléphone',
    ];
  }

  // ── Ligne : parent lié ────────────────────────────────────────────────────
  Widget _ligneParent(_Parent p, bool large) {
    final selectionne = p.id == _selectionId && large;
    final (etiquette, fond, texte) = _badgeStatut(p);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _voirFiche(p, large),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selectionne ? AdminTheme.primary : const Color(0xFFE5E7EB), width: selectionne ? 1.6 : 1),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(color: AdminTheme.primaryLight, shape: BoxShape.circle),
            child: Center(child: Text(p.initiales,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AdminTheme.primary))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.nomComplet,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 2),
              Text(p.tel, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              if (p.email.isNotEmpty)
                Text(p.email, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  p.enfants.map((e) => '${e.nomComplet} (${e.relation})').join(' · '),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AdminTheme.primary),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _pastille(etiquette, fond, texte),
            const SizedBox(height: 6),
            Text('${p.enfants.length} étudiant(s)', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ]),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
        ]),
      ),
    );
  }

  (String, Color, Color) _badgeStatut(_Parent p) {
    if (p.inactif) return ('Inactif', const Color(0xFFF3F4F6), const Color(0xFF6B7280));
    if (p.compteActif) return ('Actif', AdminTheme.successLight, AdminTheme.success);
    return ('En attente de connexion', AdminTheme.warningLight, AdminTheme.warning);
  }

  Widget _pastille(String t, Color fond, Color texte) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(8)),
        child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: texte)),
      );

  Widget _vide() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.people_outline_rounded, size: 56, color: Color(0xFFD1D5DB)),
            SizedBox(height: 12),
            Text('Aucun parent trouvé', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
            SizedBox(height: 4),
            Text('Modifiez votre recherche ou liez un tuteur.', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          ]),
        ),
      );

  // ── Fiche : panneau latéral (bureau) ou feuille (mobile) ──────────────────
  void _voirFiche(_Parent p, bool large) {
    if (large) {
      setState(() => _selectionId = p.id);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: _FicheParent(
            parent: p,
            onFermer: () => Navigator.pop(ctx),
            onChange: () {
              Navigator.pop(ctx);
              _charger(silencieux: true);
            },
            onRattacher: () {
              Navigator.pop(ctx);
              _ouvrirFormulaire(parentExistant: p);
            },
            snack: _snack,
          ),
        ),
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AdminTheme.danger : AdminTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Formulaire de rattachement ────────────────────────────────────────────
  // - attente : l'étudiant (matricule verrouillé) et le tuteur renseigné à
  //   l'inscription sont préremplis.
  // - parentExistant : « rattacher un autre étudiant » à un parent déjà lié.
  // - aucun des deux : « Lier un tuteur » libre (matricule à saisir).
  Future<void> _ouvrirFormulaire({_EnAttente? attente, _Parent? parentExistant}) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormulaireLien(attente: attente, parentExistant: parentExistant),
    );
    if (ok == true) {
      _snack('Tuteur lié avec succès.');
      _charger(silencieux: true);
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// FICHE PARENT
// ════════════════════════════════════════════════════════════════════════════
class _FicheParent extends StatefulWidget {
  final _Parent parent;
  final VoidCallback onFermer, onChange, onRattacher;
  final void Function(String, {bool isError}) snack;
  const _FicheParent({
    super.key,
    required this.parent,
    required this.onFermer,
    required this.onChange,
    required this.onRattacher,
    required this.snack,
  });
  @override
  State<_FicheParent> createState() => _FicheParentState();
}

class _FicheParentState extends State<_FicheParent> {
  bool _edition = false;
  bool _busy = false;
  late final TextEditingController _nom, _prenoms, _tel, _email;

  @override
  void initState() {
    super.initState();
    final p = widget.parent;
    _nom = TextEditingController(text: p.nom);
    _prenoms = TextEditingController(text: p.prenoms);
    _tel = TextEditingController(text: p.tel);
    _email = TextEditingController(text: p.email);
  }

  @override
  void dispose() {
    _nom.dispose(); _prenoms.dispose(); _tel.dispose(); _email.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (_nom.text.trim().isEmpty || _prenoms.text.trim().isEmpty || _tel.text.trim().isEmpty) {
      widget.snack('Nom, prénom et téléphone sont obligatoires.', isError: true);
      return;
    }
    setState(() => _busy = true);
    final r = await _ParentsApi.modifier(widget.parent.id, {
      'nom': _nom.text.trim(), 'prenoms': _prenoms.text.trim(),
      'tel': _tel.text.trim(), 'email': _email.text.trim(),
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (r['success'] == true) {
      widget.snack('Informations mises à jour.');
      widget.onChange();
    } else {
      widget.snack(r['error']?.toString() ?? 'Erreur.', isError: true);
    }
  }

  Future<bool> _confirmer(String titre, String message, String bouton, {bool danger = false}) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(titre),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: danger ? AdminTheme.danger : AdminTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(bouton),
          ),
        ],
      ),
    );
    return r == true;
  }

  Future<void> _reinitialiser() async {
    if (!await _confirmer('Réinitialiser l\'accès ?',
        'Le mot de passe de ${widget.parent.nomComplet} sera effacé. Il en créera un nouveau à sa prochaine connexion (nom, prénom, téléphone).',
        'Réinitialiser')) return;
    setState(() => _busy = true);
    final r = await _ParentsApi.reinitialiser(widget.parent.id);
    if (!mounted) return;
    setState(() => _busy = false);
    widget.snack(r['success'] == true ? (r['message']?.toString() ?? 'Accès réinitialisé.') : (r['error']?.toString() ?? 'Erreur.'),
        isError: r['success'] != true);
  }

  Future<void> _basculerStatut() async {
    final inactif = widget.parent.inactif;
    if (!await _confirmer(
      inactif ? 'Réactiver le compte ?' : 'Désactiver le compte ?',
      inactif
          ? '${widget.parent.nomComplet} pourra de nouveau se connecter.'
          : '${widget.parent.nomComplet} ne pourra plus se connecter. Ses liens avec les étudiants sont conservés.',
      inactif ? 'Réactiver' : 'Désactiver',
      danger: !inactif,
    )) return;
    setState(() => _busy = true);
    final r = await _ParentsApi.statut(widget.parent.id, inactif ? 'actif' : 'inactif');
    if (!mounted) return;
    setState(() => _busy = false);
    if (r['success'] == true) {
      widget.snack(r['message']?.toString() ?? 'Statut mis à jour.');
      widget.onChange();
    } else {
      widget.snack(r['error']?.toString() ?? 'Erreur.', isError: true);
    }
  }

  Future<void> _retirerLien(_Enfant e) async {
    if (!await _confirmer('Retirer ce lien ?',
        '${e.nomComplet} ne sera plus rattaché à ce tuteur. Le compte parent lui-même n\'est pas supprimé.',
        'Retirer', danger: true)) return;
    final r = await _ParentsApi.retirerLien(e.etudiantId);
    if (!mounted) return;
    if (r['success'] == true) {
      widget.snack('Lien retiré.');
      widget.onChange();
    } else {
      widget.snack(r['error']?.toString() ?? 'Erreur lors du retrait.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.parent;
    final (etiquette, fond, texte) = p.inactif
        ? ('Compte inactif', const Color(0xFFF3F4F6), const Color(0xFF6B7280))
        : p.compteActif
            ? ('Compte actif', AdminTheme.successLight, AdminTheme.success)
            : ('En attente de connexion', AdminTheme.warningLight, AdminTheme.warning);

    return Material(
      color: Colors.white,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
          child: Row(children: [
            const Expanded(child: Text('Fiche du parent', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
            IconButton(icon: const Icon(Icons.close_rounded), onPressed: widget.onFermer),
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 18), children: [
            Row(children: [
              Container(
                width: 56, height: 56,
                decoration: const BoxDecoration(color: AdminTheme.primaryLight, shape: BoxShape.circle),
                child: Center(child: Text(p.initiales,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AdminTheme.primary))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.nomComplet, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(8)),
                    child: Text(etiquette, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: texte)),
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: 16),

            _bloc('Informations personnelles', Icons.person_outline_rounded, _edition ? _formEdition() : _lectureInfos(p)),
            const SizedBox(height: 12),

            _bloc(
              'Étudiants rattachés (${p.enfants.length})',
              Icons.school_outlined,
              Column(children: [
                for (final e in p.enfants) _carteEnfant(e),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: widget.onRattacher,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Rattacher un autre étudiant', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            if (_edition) ...[
              _bouton('Enregistrer', Icons.check_rounded, AdminTheme.primary, true, _busy ? null : _enregistrer),
              const SizedBox(height: 8),
              _bouton('Annuler', Icons.close_rounded, AdminTheme.primary, false, _busy ? null : () => setState(() => _edition = false)),
            ] else ...[
              _bouton('Modifier les informations', Icons.edit_outlined, AdminTheme.primary, true, _busy ? null : () => setState(() => _edition = true)),
              const SizedBox(height: 8),
              _bouton('Réinitialiser l\'accès', Icons.lock_reset_rounded, AdminTheme.primary, false,
                  (_busy || !p.compteActif) ? null : _reinitialiser),
              const SizedBox(height: 8),
              _bouton(p.inactif ? 'Réactiver le compte' : 'Désactiver le compte',
                  p.inactif ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                  p.inactif ? AdminTheme.success : AdminTheme.danger, false, _busy ? null : _basculerStatut),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _bloc(String titre, IconData icone, Widget contenu) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icone, size: 18, color: AdminTheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(titre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
          ]),
          const Divider(height: 18),
          contenu,
        ]),
      );

  Widget _ligne(String label, String valeur) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 92, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
          Expanded(child: Text(valeur.isEmpty ? '—' : valeur,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)))),
        ]),
      );

  Widget _lectureInfos(_Parent p) {
    final relations = p.enfants.map((e) => e.relation).where((r) => r.isNotEmpty).toSet().join(' / ');
    return Column(children: [
      _ligne('Nom', p.nom),
      _ligne('Prénom', p.prenoms),
      _ligne('Téléphone', p.tel),
      _ligne('Email', p.email),
      _ligne('Relation', relations),
    ]);
  }

  Widget _formEdition() => Column(children: [
        _champ(_nom, 'Nom *'),
        _champ(_prenoms, 'Prénom *'),
        _champ(_tel, 'Téléphone *', type: TextInputType.phone),
        _champ(_email, 'Email (optionnel)', type: TextInputType.emailAddress),
      ]);

  Widget _champ(TextEditingController c, String label, {TextInputType type = TextInputType.text}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          keyboardType: type,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );

  Widget _carteEnfant(_Enfant e) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Icon(Icons.school_rounded, color: AdminTheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${e.nomComplet}  ·  ${e.relation}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AdminTheme.primary)),
              Text('Matricule : ${e.matricule}', style: const TextStyle(fontSize: 11, color: AdminTheme.primaryMid)),
              if (e.filiere.isNotEmpty)
                Text('Filière : ${e.filiere}', style: const TextStyle(fontSize: 11, color: AdminTheme.primaryMid)),
              if (e.niveau.isNotEmpty)
                Text('Niveau : ${e.niveau}', style: const TextStyle(fontSize: 11, color: AdminTheme.primaryMid)),
            ]),
          ),
          IconButton(
            tooltip: 'Retirer ce lien',
            icon: const Icon(Icons.link_off_rounded, size: 18, color: AdminTheme.danger),
            onPressed: () => _retirerLien(e),
          ),
        ]),
      );

  Widget _bouton(String label, IconData icone, Color couleur, bool plein, VoidCallback? onTap) => SizedBox(
        width: double.infinity,
        height: 44,
        child: plein
            ? ElevatedButton.icon(
                onPressed: onTap,
                icon: Icon(icone, size: 18),
                label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: couleur, foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )
            : OutlinedButton.icon(
                onPressed: onTap,
                icon: Icon(icone, size: 18),
                label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: couleur,
                  side: BorderSide(color: couleur.withValues(alpha: 0.6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// FORMULAIRE DE LIEN
// ════════════════════════════════════════════════════════════════════════════
class _FormulaireLien extends StatefulWidget {
  final _EnAttente? attente;
  final _Parent? parentExistant;
  const _FormulaireLien({this.attente, this.parentExistant});
  @override
  State<_FormulaireLien> createState() => _FormulaireLienState();
}

class _FormulaireLienState extends State<_FormulaireLien> {
  late final TextEditingController _nom, _prenoms, _tel, _email, _mat;
  String? _relation;
  bool _saving = false;
  bool _tentative = false; // devient vrai après un premier clic sur « Valider »

  bool get _matriculeVerrouille => widget.attente != null;

  @override
  void initState() {
    super.initState();
    final a = widget.attente;
    final p = widget.parentExistant;
    if (a != null) {
      final np = a.nomPrenomsParent;
      _nom = TextEditingController(text: np[0]);
      _prenoms = TextEditingController(text: np[1]);
      _tel = TextEditingController(text: a.telParent);
      _email = TextEditingController(text: a.emailParent);
      _mat = TextEditingController(text: a.matricule);
    } else if (p != null) {
      _nom = TextEditingController(text: p.nom);
      _prenoms = TextEditingController(text: p.prenoms);
      _tel = TextEditingController(text: p.tel);
      _email = TextEditingController(text: p.email);
      _mat = TextEditingController();
      final rel = p.enfants.map((e) => e.relation).where(_kRelations.contains).toSet();
      if (rel.length == 1) _relation = rel.first;
    } else {
      _nom = TextEditingController();
      _prenoms = TextEditingController();
      _tel = TextEditingController();
      _email = TextEditingController();
      _mat = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nom.dispose(); _prenoms.dispose(); _tel.dispose(); _email.dispose(); _mat.dispose();
    super.dispose();
  }

  bool _vide(TextEditingController c) => c.text.trim().isEmpty;

  /// Rattachement complet : tout est déjà renseigné → simple récapitulatif.
  bool get _complet =>
      !_vide(_nom) && !_vide(_prenoms) && !_vide(_tel) && !_vide(_mat) && _relation != null;

  Future<void> _valider({bool remplacer = false}) async {
    setState(() => _tentative = true);
    if (!_complet) return;
    setState(() => _saving = true);
    final r = await _ParentsApi.lier({
      'nom': _nom.text.trim(),
      'prenoms': _prenoms.text.trim(),
      'telephone': _tel.text.trim(),
      'email': _email.text.trim(),
      'relation': _relation,
      'matriculeEnfant': _mat.text.trim().toUpperCase(),
      'remplacerExistant': remplacer,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (r['success'] == true) {
      Navigator.pop(context, true);
      return;
    }
    if (r['conflict'] == true && !remplacer) {
      _confirmerRemplacement(r['error']?.toString() ?? 'Cet enfant a déjà un tuteur principal.');
    } else {
      _erreur(r['error']?.toString() ?? 'Erreur lors de l\'enregistrement.');
    }
  }

  void _confirmerRemplacement(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tuteur déjà assigné'),
        content: Text('$message\n\nVoulez-vous le remplacer par ce nouveau tuteur ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.danger, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _valider(remplacer: true);
            },
            child: const Text('Remplacer'),
          ),
        ],
      ),
    );
  }

  void _erreur(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AdminTheme.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attente;
    final recap = a != null && _complet;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(children: [
              Expanded(
                child: Text(
                  widget.parentExistant != null ? 'Rattacher un étudiant' : 'Lier un tuteur',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: _saving ? null : () => Navigator.pop(context)),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (a != null) _carteEtudiant(a),
                if (a != null) const SizedBox(height: 12),
                _banniere(recap),
                const SizedBox(height: 14),
                _champ('Nom *', _nom, 'Nom de famille (ex : LANKOANDE)', requis: true),
                _champ('Prénom *', _prenoms, 'Prénom (ex : Pascal)', requis: true),
                _champ('Téléphone *', _tel, 'Ex : 70 12 34 56', requis: true, type: TextInputType.phone),
                _champ('Email (optionnel)', _email, 'adresse@email.com', type: TextInputType.emailAddress),
                _labelRelation(),
                const SizedBox(height: 12),
                _champ('Matricule de l\'enfant *', _mat, 'Matricule de l\'étudiant', requis: true, enabled: !_matriculeVerrouille),
                const SizedBox(height: 4),
                _noteMotDePasse(),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _saving ? null : _valider,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primary, foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(recap ? 'Valider le lien' : 'Enregistrer',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _carteEtudiant(_EnAttente a) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.school_rounded, color: AdminTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.enfantComplet, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AdminTheme.primary)),
              Text(
                [a.matricule, if (a.filiere.isNotEmpty) a.filiere, if (a.niveau.isNotEmpty) a.niveau].join(' · '),
                style: const TextStyle(fontSize: 11, color: AdminTheme.primaryMid),
              ),
            ]),
          ),
        ]),
      );

  Widget _banniere(bool recap) {
    final bool manque = _tentative && !_complet;
    final Color c = manque ? AdminTheme.danger : (recap ? AdminTheme.success : const Color(0xFF0284C7));
    final String t = manque
        ? 'Des informations obligatoires manquent : complétez les champs signalés en rouge.'
        : recap
            ? 'Toutes les informations sont renseignées. Vérifiez le récapitulatif puis validez.'
            : 'Nom, prénom, téléphone et relation sont obligatoires. L\'email est facultatif.';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(manque ? Icons.error_outline_rounded : Icons.info_outline_rounded, size: 18, color: c),
        const SizedBox(width: 8),
        Expanded(child: Text(t, style: TextStyle(fontSize: 12, color: c, height: 1.3))),
      ]),
    );
  }

  Widget _champ(String label, TextEditingController c, String hint,
      {bool requis = false, bool enabled = true, TextInputType type = TextInputType.text}) {
    final erreur = _tentative && requis && c.text.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: erreur ? AdminTheme.danger : const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: c,
            enabled: enabled,
            keyboardType: type,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        if (erreur)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('À renseigner', style: TextStyle(fontSize: 11, color: AdminTheme.danger)),
          ),
      ]),
    );
  }

  Widget _labelRelation() {
    final erreur = _tentative && _relation == null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Relation *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      const SizedBox(height: 6),
      Row(
        children: _kRelations.map((r) {
          final actif = _relation == r;
          return GestureDetector(
            onTap: () => setState(() => _relation = r),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: actif ? AdminTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: actif ? AdminTheme.primary : (erreur ? AdminTheme.danger : const Color(0xFFE5E7EB))),
              ),
              child: Text(r,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: actif ? Colors.white : const Color(0xFF6B7280))),
            ),
          );
        }).toList(),
      ),
      if (erreur)
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Choisissez la relation', style: TextStyle(fontSize: 11, color: AdminTheme.danger)),
        ),
    ]);
  }

  Widget _noteMotDePasse() => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBAE6FD)),
        ),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF0284C7)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Aucun mot de passe n\'est défini ici : à sa première connexion (nom, prénom, téléphone), le parent crée lui-même son mot de passe et le confirme.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF0369A1), height: 1.3),
            ),
          ),
        ]),
      );
}
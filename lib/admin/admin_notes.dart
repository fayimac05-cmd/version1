import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_annonces.dart' show istNiveaux;
import '../services/api_service.dart';
import '../services/notes_admin_service.dart';
import '../utils/snackbar_helper.dart';
import '../models/student_profile.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES
// ════════════════════════════════════════════════════════════════════════════
class NoteEntry {
  final String matricule, nom, prenoms;
  final double valeur;
  NoteEntry({required this.matricule, required this.nom, required this.prenoms, required this.valeur});

  factory NoteEntry.fromJson(Map<String, dynamic> j) => NoteEntry(
        matricule: j['matricule'] ?? '',
        nom: j['nom'] ?? '',
        prenoms: j['prenoms'] ?? '',
        valeur: double.tryParse(j['valeur'].toString()) ?? 0.0,
      );
}

class NoteSession {
  final String id, moduleNom, filiereNom, niveau, profNom, profPrenoms, dateSession;
  final double coefficient;
  String statut;
  final List<NoteEntry> notes;
  // Vrai champ domaine renvoyé par le backend (jointure filieres.domaine) —
  // remplace l'ancienne heuristique qui devinait le domaine à partir du
  // texte du nom de la filière.
  final String? domaine;
  final String? mention;
  final String? semestre;
  final String? anneeAcademique;
  final String? filiereId;
  final bool archive;

  NoteSession({
    required this.id, required this.moduleNom, required this.filiereNom, required this.niveau,
    required this.profNom, required this.profPrenoms, required this.dateSession,
    required this.coefficient, required this.statut, required this.notes,
    this.domaine, this.mention, this.semestre, this.anneeAcademique,
    this.filiereId, this.archive = false,
  });

  factory NoteSession.fromJson(Map<String, dynamic> j) => NoteSession(
        id: j['id'].toString(),
        moduleNom: j['module_nom'] ?? '',
        filiereNom: j['filiere_nom'] ?? '',
        niveau: j['niveau'] ?? '',
        profNom: j['prof_nom'] ?? '',
        profPrenoms: j['prof_prenoms'] ?? '',
        dateSession: j['date_session'] ?? '',
        coefficient: double.tryParse(j['coefficient'].toString()) ?? 1.0,
        statut: j['statut'] ?? 'en_attente',
        notes: (j['notes'] as List<dynamic>? ?? []).map((n) => NoteEntry.fromJson(n as Map<String, dynamic>)).toList(),
        domaine: j['domaine'] as String?,
        mention: j['mention'] as String?,
        semestre: j['semestre'] as String?,
        anneeAcademique: j['annee_academique'] as String?,
        filiereId: j['filiere_id']?.toString(),
        archive: j['archive'] == true,
      );

  String get dateFormatee {
    final dt = DateTime.tryParse(dateSession);
    if (dt == null) return dateSession;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class MoyenneEtudiant {
  final String matricule, nom, prenoms, filiereNom, niveau;
  final double moyenne;
  final int nbNotes;
  final String? domaine;

  MoyenneEtudiant({
    required this.matricule, required this.nom, required this.prenoms,
    required this.filiereNom, required this.niveau, required this.moyenne, required this.nbNotes,
    this.domaine,
  });

  factory MoyenneEtudiant.fromJson(Map<String, dynamic> j) => MoyenneEtudiant(
        matricule: j['matricule'] ?? '',
        nom: j['nom'] ?? '',
        prenoms: j['prenoms'] ?? '',
        filiereNom: j['filiere_nom'] ?? '',
        niveau: j['niveau'] ?? '',
        moyenne: double.tryParse(j['moyenne'].toString()) ?? 0.0,
        nbNotes: int.tryParse(j['nb_notes'].toString()) ?? 0,
        domaine: j['domaine'] as String?,
      );
}

// Liste des mentions choisies par le professeur pour une session (module) —
// distinctes des statuts Validé/Ajourné/Invalidé du bulletin (semestre).
const List<String> mentionsModule = [
  'Très Bien', 'Bien', 'Assez Bien', 'Passable', 'Insuffisant',
];

const List<String> semestresDisponibles = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6'];

// ════════════════════════════════════════════════════════════════════════════
// PAGE NOTES & MOYENNES
// ════════════════════════════════════════════════════════════════════════════
class AdminNotes extends StatefulWidget {
  final StudentProfile profile;
  const AdminNotes({super.key, required this.profile});
  @override State<AdminNotes> createState() => _AdminNotesState();
}

// Semestres proposés selon le niveau choisi (Licence 1 → S1,S2 ; L2 → S3,S4 ; L3 → S5,S6…).
List<String> semestresPourNiveau(String? niveau) {
  switch (niveau) {
    case 'Licence 1': return ['S1', 'S2'];
    case 'Licence 2': return ['S3', 'S4'];
    case 'Licence 3': return ['S5', 'S6'];
    case 'Master 1': return ['S7', 'S8'];
    case 'Master 2': return ['S9', 'S10'];
    default: return semestresDisponibles;
  }
}

class _AdminNotesState extends State<AdminNotes> {
  List<NoteSession> _sessions = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _tab = 0; // 0 reçues · 1 en attente · 2 transférées · 3 archives
  String? _fDomaine, _fFiliere, _fNiveau, _fSemestre, _fStatut;
  final Set<String> _sel = {};
  int _page = 0;
  static const int _parPage = 10;

  // Panneau « moyenne provisoire »
  String? _pFiliere, _pNiveau, _pSemestre;
  bool _pChargement = false;
  Map<String, dynamic>? _apercu;
  String _pAnnee = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Fail-closed : un admin restreint à un domaine ne voit que ce domaine.
  bool _estMemeDomaine(String? domaine) {
    if (!widget.profile.filtreParDomaine) return true;
    if (domaine == null || domaine.isEmpty) return false;
    return domaine == widget.profile.domaineAdmin;
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    final res = await ApiService.getSessionsNotesAdmin();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _sessions = (res['data'] as List<dynamic>)
            .map((j) => NoteSession.fromJson(j as Map<String, dynamic>))
            .where((s) => _estMemeDomaine(s.domaine))
            .toList();
        _sel.removeWhere((id) => !_sessions.any((s) => s.id == id));
      } else {
        _errorMessage = res['error'] as String?;
      }
    });
  }

  // ── Données dérivées ──────────────────────────────────────────────────
  List<NoteSession> get _actives => _sessions.where((s) => !s.archive).toList();
  int get _nbRecues => _actives.length;
  int get _nbAttente => _actives.where((s) => s.statut == 'en_attente').length;
  int get _nbStockees => _actives.where((s) => s.statut == 'stockee').length;
  int get _nbTransferees => _actives.where((s) => s.statut == 'validee').length;
  int get _nbArchives => _sessions.where((s) => s.archive).length;

  List<NoteSession> get _filtrees => _sessions.where((s) {
        if (_tab == 3 ? !s.archive : s.archive) return false;
        if (_tab == 1 && s.statut != 'en_attente') return false;
        if (_tab == 2 && s.statut != 'validee') return false;
        if (_fStatut != null && s.statut != _fStatut) return false;
        if (_fDomaine != null && s.domaine != _fDomaine) return false;
        if (_fFiliere != null && s.filiereId != _fFiliere) return false;
        if (_fNiveau != null && s.niveau != _fNiveau) return false;
        if (_fSemestre != null && s.semestre != _fSemestre) return false;
        return true;
      }).toList();

  List<NoteSession> get _pageCourante {
    final f = _filtrees;
    final debut = _page * _parPage;
    if (debut >= f.length) return [];
    return f.sublist(debut, (debut + _parPage).clamp(0, f.length));
  }

  Map<String, String> get _filieresConnues {
    final m = <String, String>{};
    for (final s in _sessions) {
      if (s.filiereId != null && s.filiereId!.isNotEmpty) m[s.filiereId!] = s.filiereNom;
    }
    return m;
  }

  List<String> get _domainesConnus => _sessions.map((s) => s.domaine ?? '').where((d) => d.isNotEmpty).toSet().toList()..sort();

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _erreur()
              : LayoutBuilder(builder: (context, c) {
                  final large = c.maxWidth >= 1150;
                  final tableau = _blocTableau();
                  final panneau = _panneauMoyenne();
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _entete(),
                      const SizedBox(height: 16),
                      _kpis(),
                      const SizedBox(height: 16),
                      large
                          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Expanded(child: tableau),
                              const SizedBox(width: 16),
                              SizedBox(width: 380, child: panneau),
                            ])
                          : Column(children: [tableau, const SizedBox(height: 16), panneau]),
                    ]),
                  );
                }),
    );
  }

  Widget _entete() => Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Notes & Moyennes', style: AdminTheme.headingLarge),
          Text('Réception, stockage, transfert des notes et moyennes provisoires par module', style: AdminTheme.bodyMedium),
        ])),
        IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh_rounded, color: AdminTheme.textSecondary), tooltip: 'Actualiser'),
        const SizedBox(width: 6),
        ElevatedButton.icon(
          onPressed: _ouvrirSaisieDirecte,
          icon: const Icon(Icons.edit_note_rounded, size: 18),
          label: const Text('Saisie directe'),
          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusButton))),
        ),
      ]);

  void _ouvrirSaisieDirecte() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      appBar: AppBar(title: const Text('Saisie directe des notes'), backgroundColor: AdminTheme.surface, foregroundColor: AdminTheme.textPrimary, elevation: 0),
      body: _SaisieDirecte(onSaved: _loadData),
    )));
  }

  // ── KPI (cliquables : filtrent par statut) ────────────────────────────
  Widget _kpis() {
    Widget carte(IconData ic, String titre, int n, Color fg, Color bg, String? statut, {int? onglet}) {
      final actif = (statut != null && _fStatut == statut);
      return Expanded(child: InkWell(
        borderRadius: BorderRadius.circular(AdminTheme.radiusCard),
        onTap: () => setState(() {
          _page = 0; _sel.clear();
          if (onglet != null) { _tab = onglet; _fStatut = null; }
          else if (statut != null) { _tab = 0; _fStatut = actif ? null : statut; }
          else { _tab = 0; _fStatut = null; }
        }),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(AdminTheme.radiusCard),
              border: Border.all(color: actif ? fg : AdminTheme.border, width: actif ? 1.6 : 1), boxShadow: AdminTheme.cardShadow),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)), child: Icon(ic, color: fg, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$n', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: fg)),
              Text(titre, style: AdminTheme.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ),
      ));
    }

    return Row(children: [
      Expanded(child: Row(children: [
        carte(Icons.inbox_rounded, 'Notes reçues', _nbRecues, AdminTheme.info, AdminTheme.infoLight, null),
        const SizedBox(width: 10),
        carte(Icons.hourglass_top_rounded, 'En attente', _nbAttente, AdminTheme.warning, AdminTheme.warningLight, 'en_attente'),
        const SizedBox(width: 10),
        carte(Icons.inventory_2_rounded, 'Stockées', _nbStockees, AdminTheme.textSecondary, AdminTheme.surfaceAlt, 'stockee'),
        const SizedBox(width: 10),
        carte(Icons.send_rounded, 'Transférées', _nbTransferees, AdminTheme.success, AdminTheme.successLight, 'validee'),
      ])),
    ]);
  }

  // ── Bloc tableau : filtres + onglets + liste ──────────────────────────
  Widget _blocTableau() {
    final liste = _filtrees;
    final nbPages = (liste.length / _parPage).ceil().clamp(1, 9999);
    if (_page >= nbPages) _page = nbPages - 1;
    final page = _pageCourante;

    return Container(
      decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(AdminTheme.radiusCard), border: Border.all(color: AdminTheme.border), boxShadow: AdminTheme.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: _filtres()),
        _onglets(),
        const Divider(height: 1, color: AdminTheme.border),
        if (_sel.isNotEmpty) _barreSelection(),
        if (liste.isEmpty)
          Padding(padding: const EdgeInsets.all(40), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.grade_outlined, color: AdminTheme.primary, size: 36),
            const SizedBox(height: 10),
            Text('Aucune note dans cette vue', style: AdminTheme.headingSmall),
          ])))
        else
          LayoutBuilder(builder: (context, c) {
            final largeur = c.maxWidth < 860 ? 860.0 : c.maxWidth;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: largeur, child: Column(children: [
                _enteteTable(page),
                const Divider(height: 1, color: AdminTheme.border),
                ...page.map((s) => Column(children: [_ligne(s), const Divider(height: 1, color: AdminTheme.border)])),
              ])),
            );
          }),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Text(liste.isEmpty ? '' : 'Affichage ${_page * _parPage + 1}–${_page * _parPage + page.length} sur ${liste.length}', style: AdminTheme.caption),
            const Spacer(),
            IconButton(onPressed: _page > 0 ? () => setState(() => _page--) : null, icon: const Icon(Icons.chevron_left_rounded)),
            Text('${_page + 1} / $nbPages', style: AdminTheme.caption.copyWith(fontWeight: FontWeight.w700)),
            IconButton(onPressed: _page < nbPages - 1 ? () => setState(() => _page++) : null, icon: const Icon(Icons.chevron_right_rounded)),
          ]),
        ),
      ]),
    );
  }

  Widget _filtres() {
    final fil = _filieresConnues;
    return Wrap(spacing: 10, runSpacing: 10, children: [
      if (!widget.profile.filtreParDomaine)
        _filtre('Domaine', _fDomaine, _domainesConnus, _domainesConnus, (v) => setState(() { _fDomaine = v; _page = 0; })),
      _filtre('Filière', _fFiliere, fil.keys.toList(), fil.values.toList(), (v) => setState(() { _fFiliere = v; _page = 0; })),
      _filtre('Niveau', _fNiveau, istNiveaux, istNiveaux, (v) => setState(() {
            _fNiveau = v; _page = 0;
            if (_fSemestre != null && !semestresPourNiveau(v).contains(_fSemestre)) _fSemestre = null;
          })),
      _filtre('Semestre', _fSemestre, semestresPourNiveau(_fNiveau), semestresPourNiveau(_fNiveau), (v) => setState(() { _fSemestre = v; _page = 0; })),
      if (_fStatut != null)
        InputChip(
          label: Text('Statut : ${_libelleStatut(_fStatut!)}'),
          onDeleted: () => setState(() { _fStatut = null; _page = 0; }),
        ),
    ]);
  }

  Widget _filtre(String titre, String? valeur, List<String> ids, List<String> labels, ValueChanged<String?> onChanged) => Container(
        width: 170,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(AdminTheme.radiusButton), border: Border.all(color: AdminTheme.border)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: valeur != null && ids.contains(valeur) ? valeur : '',
          isExpanded: true,
          style: AdminTheme.bodyLarge,
          items: [
            DropdownMenuItem(value: '', child: Text('$titre : Tous', style: const TextStyle(fontSize: 13))),
            ...List.generate(ids.length, (i) => DropdownMenuItem(value: ids[i], child: Text(labels[i], style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))),
          ],
          onChanged: (v) => onChanged((v == null || v.isEmpty) ? null : v),
        )),
      );

  Widget _onglets() {
    Widget t(int i, String label, int n) {
      final actif = _tab == i;
      return InkWell(
        onTap: () => setState(() { _tab = i; _page = 0; _sel.clear(); if (i != 0) _fStatut = null; }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: actif ? AdminTheme.primary : Colors.transparent, width: 2))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: actif ? AdminTheme.primary : AdminTheme.textSecondary)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: actif ? AdminTheme.primaryLight : AdminTheme.surfaceAlt, borderRadius: BorderRadius.circular(10)),
              child: Text('$n', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: actif ? AdminTheme.primary : AdminTheme.textSecondary)),
            ),
          ]),
        ),
      );
    }
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
      t(0, 'Notes reçues', _nbRecues),
      t(1, 'En attente', _nbAttente),
      t(2, 'Transférées', _nbTransferees),
      t(3, 'Archives', _nbArchives),
    ]));
  }

  Widget _barreSelection() {
    final choisies = _sessions.where((s) => _sel.contains(s.id)).toList();
    final enArchive = _tab == 3;
    return Container(
      color: AdminTheme.primaryLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text('${_sel.length} sélectionnée(s)', style: const TextStyle(fontWeight: FontWeight.w700, color: AdminTheme.primary, fontSize: 13)),
        if (!enArchive) ...[
          _miniBtn('Transférer aux étudiants', Icons.send_rounded, AdminTheme.success, () => _confirmerTransfert(choisies)),
          _miniBtn('Stocker', Icons.inventory_2_rounded, AdminTheme.textSecondary, () => _agir(() => NotesAdminService.stocker(_ids(choisies)))),
          _miniBtn('Archiver', Icons.archive_rounded, AdminTheme.info, () => _agir(() => NotesAdminService.archiver(_ids(choisies)))),
        ] else
          _miniBtn('Restaurer', Icons.unarchive_rounded, AdminTheme.info, () => _agir(() => NotesAdminService.archiver(_ids(choisies), archive: false))),
        TextButton(onPressed: () => setState(_sel.clear), child: const Text('Annuler')),
      ]),
    );
  }

  List<String> _ids(List<NoteSession> l) => l.map((s) => s.id).toList();

  Widget _miniBtn(String label, IconData ic, Color c, VoidCallback onTap) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(ic, size: 15, color: c),
        label: Text(label, style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(side: BorderSide(color: c.withValues(alpha: 0.4)), backgroundColor: AdminTheme.surface),
      );

  Widget _enteteTable(List<NoteSession> page) {
    const st = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminTheme.textSecondary);
    final toutes = page.isNotEmpty && page.every((s) => _sel.contains(s.id));
    return Container(
      color: AdminTheme.surfaceAlt,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        SizedBox(width: 36, child: Checkbox(value: toutes, onChanged: (v) => setState(() {
          for (final s in page) { v == true ? _sel.add(s.id) : _sel.remove(s.id); }
        }))),
        const Expanded(flex: 3, child: Text('MODULE', style: st)),
        const Expanded(flex: 3, child: Text('FILIÈRE / NIVEAU', style: st)),
        const Expanded(flex: 2, child: Text('PROFESSEUR', style: st)),
        const SizedBox(width: 60, child: Text('SEM.', style: st)),
        const SizedBox(width: 60, child: Text('ÉTUD.', style: st)),
        const SizedBox(width: 90, child: Text('REÇUE LE', style: st)),
        const SizedBox(width: 100, child: Text('STATUT', style: st)),
        const SizedBox(width: 150, child: Text('ACTIONS', style: st)),
      ]),
    );
  }

  Widget _ligne(NoteSession s) {
    final blam = s.notes.where((n) => n.valeur < 7).length;
    return InkWell(
      onTap: () => _voir(s),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          SizedBox(width: 36, child: Checkbox(value: _sel.contains(s.id), onChanged: (v) => setState(() { v == true ? _sel.add(s.id) : _sel.remove(s.id); }))),
          Expanded(flex: 3, child: Row(children: [
            Flexible(child: Text(s.moduleNom, style: AdminTheme.headingSmall.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (blam > 0) ...[const SizedBox(width: 4), Tooltip(message: '$blam note(s) blâmable(s)', child: const Icon(Icons.warning_amber_rounded, color: AdminTheme.danger, size: 15))],
          ])),
          Expanded(flex: 3, child: Text('${s.filiereNom} · ${s.niveau}', style: AdminTheme.bodyMedium.copyWith(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text('${s.profPrenoms} ${s.profNom}'.trim(), style: AdminTheme.bodyMedium.copyWith(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 60, child: Text(s.semestre ?? '—', style: AdminTheme.bodyMedium.copyWith(fontSize: 12))),
          SizedBox(width: 60, child: Tooltip(message: s.notes.isEmpty ? 'Aucune note enregistrée dans cette session' : '${s.notes.length} étudiant(s)', child: Text('${s.notes.length}', style: AdminTheme.bodyMedium.copyWith(fontSize: 12, fontWeight: s.notes.isEmpty ? FontWeight.w800 : FontWeight.w400, color: s.notes.isEmpty ? AdminTheme.warning : null)))),
          SizedBox(width: 90, child: Text(s.dateFormatee, style: AdminTheme.caption)),
          SizedBox(width: 100, child: Align(alignment: Alignment.centerLeft, child: _statusBadge(s.statut))),
          SizedBox(width: 150, child: Row(children: [
            s.statut == 'en_attente'
                ? _boutonAction('Traiter', () => _voir(s), AdminTheme.primary, plein: true)
                : _boutonAction('Voir', () => _voir(s), AdminTheme.primary),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 18, color: AdminTheme.textSecondary),
              onSelected: (v) => _menu(v, s),
              itemBuilder: (_) => [
                if (s.statut != 'validee' && !s.archive) const PopupMenuItem(value: 'transferer', child: Text('Transférer aux étudiants')),
                if (s.statut == 'en_attente') const PopupMenuItem(value: 'stocker', child: Text('Stocker')),
                if (s.statut == 'en_attente' || s.statut == 'stockee') const PopupMenuItem(value: 'rejeter', child: Text('Rejeter')),
                PopupMenuItem(value: s.archive ? 'restaurer' : 'archiver', child: Text(s.archive ? 'Restaurer' : 'Archiver')),
              ],
            ),
          ])),
        ]),
      ),
    );
  }

  // « Traiter » = bouton plein (action attendue) ; « Voir » = bouton à contour.
  Widget _boutonAction(String t, VoidCallback f, Color c, {bool plein = false}) => SizedBox(
        height: 30,
        child: plein
            ? ElevatedButton(
                onPressed: f,
                style: ElevatedButton.styleFrom(backgroundColor: c, foregroundColor: Colors.white, elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              )
            : OutlinedButton(
                onPressed: f,
                style: OutlinedButton.styleFrom(side: BorderSide(color: c.withValues(alpha: 0.5)), foregroundColor: c,
                    padding: const EdgeInsets.symmetric(horizontal: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
      );

  void _menu(String action, NoteSession s) {
    switch (action) {
      case 'transferer': _confirmerTransfert([s]); break;
      case 'stocker': _agir(() => NotesAdminService.stocker([s.id])); break;
      case 'rejeter': _rejeter(s); break;
      case 'archiver': _agir(() => NotesAdminService.archiver([s.id])); break;
      case 'restaurer': _agir(() => NotesAdminService.archiver([s.id], archive: false)); break;
    }
  }

  Future<void> _agir(Future<Map<String, dynamic>> Function() appel) async {
    final r = await appel();
    if (!mounted) return;
    if (r['success'] == true) {
      _snack((r['message'] as String?) ?? 'Opération effectuée.');
      _sel.clear();
      await _loadData();
    } else {
      _snack((r['error'] as String?) ?? 'Erreur.', isError: true);
    }
  }

  // ── Détail (Traiter / Voir) ───────────────────────────────────────────
  void _voir(NoteSession s) {
    final moy = s.notes.isEmpty ? 0.0 : s.notes.fold<double>(0, (a, n) => a + n.valeur) / s.notes.length;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Expanded(child: Text(s.moduleNom, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
        _statusBadge(s.statut),
      ]),
      content: SizedBox(width: 520, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${s.profPrenoms} ${s.profNom} · ${s.filiereNom} · ${s.niveau}${s.semestre != null ? ' · ${s.semestre}' : ''}', style: AdminTheme.bodyMedium),
        if (s.mention != null && s.mention!.isNotEmpty) Text('Mention du professeur : ${s.mention}', style: AdminTheme.caption),
        const SizedBox(height: 10),
        Flexible(child: SingleChildScrollView(child: Column(children: s.notes.map((n) {
          final blam = n.valeur < 7;
          final ok = n.valeur >= 10;
          return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
            Expanded(child: Text('${n.prenoms} ${n.nom}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            Text(n.matricule, style: AdminTheme.caption.copyWith(fontFamily: 'monospace')),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: blam ? AdminTheme.dangerLight : ok ? AdminTheme.successLight : AdminTheme.warningLight, borderRadius: BorderRadius.circular(8)),
              child: Text('${n.valeur.toStringAsFixed(1)}/20', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: blam ? AdminTheme.danger : ok ? AdminTheme.success : AdminTheme.warning)),
            ),
          ]));
        }).toList()))),
        const Divider(),
        Row(children: [
          const Text('Moyenne de la classe', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const Spacer(),
          Text('${moy.toStringAsFixed(2)}/20', style: TextStyle(fontWeight: FontWeight.w800, color: moy >= 10 ? AdminTheme.primary : AdminTheme.danger)),
        ]),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        if (s.statut == 'en_attente' || s.statut == 'stockee')
          TextButton(onPressed: () { Navigator.pop(ctx); _rejeter(s); }, child: const Text('Rejeter', style: TextStyle(color: AdminTheme.danger))),
        if (s.statut == 'en_attente')
          OutlinedButton(onPressed: () { Navigator.pop(ctx); _agir(() => NotesAdminService.stocker([s.id])); }, child: const Text('Stocker')),
        if (s.statut != 'validee' && !s.archive)
          ElevatedButton.icon(
            onPressed: () { Navigator.pop(ctx); _confirmerTransfert([s]); },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Transférer'),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, foregroundColor: Colors.white, elevation: 0),
          ),
      ],
    ));
  }

  void _confirmerTransfert(List<NoteSession> l) {
    final aTransferer = l.where((s) => s.statut != 'validee').toList();
    if (aTransferer.isEmpty) { _snack('Ces notes sont déjà transférées.'); return; }
    final nb = aTransferer.fold<int>(0, (a, s) => a + s.notes.length);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [Icon(Icons.send_rounded, color: AdminTheme.primary), SizedBox(width: 10), Text('Transférer aux étudiants', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${aTransferer.length} session(s) · $nb note(s) à transférer.', style: const TextStyle(fontSize: 14, color: AdminTheme.textSecondary)),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
          child: const Row(children: [
            Icon(Icons.security_rounded, color: AdminTheme.primary, size: 16), SizedBox(width: 8),
            Expanded(child: Text('Chaque étudiant reçoit uniquement sa propre note.', style: TextStyle(fontSize: 12, color: AdminTheme.primary, fontWeight: FontWeight.w600))),
          ])),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); _agir(() => NotesAdminService.transferer(_ids(aTransferer))); },
          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, foregroundColor: Colors.white, elevation: 0),
          child: const Text('Confirmer le transfert'),
        ),
      ],
    ));
  }

  Future<void> _rejeter(NoteSession s) async {
    final motifCtrl = TextEditingController();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.cancel_outlined, color: AdminTheme.danger), SizedBox(width: 10), Text('Rejeter la session', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Indiquez le motif du rejet pour ${s.moduleNom}.', style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary)),
          const SizedBox(height: 12),
          TextField(controller: motifCtrl, maxLines: 3, decoration: InputDecoration(hintText: 'Ex : Notes incohérentes…', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.danger, foregroundColor: Colors.white), onPressed: () => Navigator.pop(context, true), child: const Text('Rejeter')),
        ],
      ),
    );
    if (confirme != true) return;
    final result = await ApiService.rejeterSessionNotes(s.id, motif: motifCtrl.text.trim());
    if (!mounted) return;
    if (result['success'] == true) { _snack('Soumission rejetée.'); _loadData(); }
    else { _snack(result['error'] as String? ?? 'Erreur.', isError: true); }
  }

  // ════════════════════════════════════════════════════════════════════════
  // PANNEAU — GÉNÉRER UNE MOYENNE PROVISOIRE (par module, PAS générale)
  // ════════════════════════════════════════════════════════════════════════
  Widget _panneauMoyenne() {
    final fil = _filieresConnues;
    final etape = _apercu == null ? 1 : 2;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(AdminTheme.radiusCard), border: Border.all(color: AdminTheme.border), boxShadow: AdminTheme.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Générer une moyenne provisoire', style: AdminTheme.headingSmall),
        const SizedBox(height: 4),
        Text('Moyenne par module (devoir 1 + devoir 2…), sans moyenne générale.', style: AdminTheme.caption),
        const SizedBox(height: 14),
        Row(children: [
          _pastille(1, 'Choisir', etape >= 1), _traitEtape(),
          _pastille(2, 'Aperçu', etape >= 2), _traitEtape(),
          _pastille(3, 'Envoyer', false),
        ]),
        const SizedBox(height: 14),
        _liste('Filière', _pFiliere, fil.keys.toList(), fil.values.toList(), (v) => setState(() { _pFiliere = v; _apercu = null; })),
        const SizedBox(height: 10),
        _liste('Niveau', _pNiveau, istNiveaux, istNiveaux, (v) => setState(() {
              _pNiveau = v; _apercu = null;
              if (_pSemestre != null && !semestresPourNiveau(v).contains(_pSemestre)) _pSemestre = null;
            })),
        const SizedBox(height: 10),
        _liste('Semestre', _pSemestre, _pNiveau == null ? <String>[] : semestresPourNiveau(_pNiveau), _pNiveau == null ? <String>[] : semestresPourNiveau(_pNiveau),
            (v) => setState(() { _pSemestre = v; _apercu = null; })),
        if (_pNiveau == null)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text('Choisis d\'abord le niveau : les semestres en dépendent.', style: AdminTheme.caption)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: (_pFiliere != null && _pNiveau != null && _pSemestre != null && !_pChargement) ? _genererApercu : null,
          icon: _pChargement ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.calculate_rounded, size: 16),
          label: const Text('Générer l\'aperçu'),
          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusButton))),
        )),
        if (_apercu != null) ...[
          const SizedBox(height: 14),
          _apercuTable(),
        ],
        const SizedBox(height: 16),
        _rappel(),
      ]),
    );
  }

  Widget _pastille(int n, String t, bool actif) => Column(children: [
        Container(width: 26, height: 26, decoration: BoxDecoration(shape: BoxShape.circle, color: actif ? AdminTheme.primary : AdminTheme.surfaceAlt, border: Border.all(color: actif ? AdminTheme.primary : AdminTheme.border)),
            child: Center(child: Text('$n', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: actif ? Colors.white : AdminTheme.textSecondary)))),
        const SizedBox(height: 3),
        Text(t, style: AdminTheme.caption),
      ]);

  Widget _traitEtape() => Expanded(child: Container(height: 1.5, margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4), color: AdminTheme.border));

  Widget _liste(String titre, String? v, List<String> ids, List<String> labels, ValueChanged<String?> onChanged) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(AdminTheme.radiusButton), border: Border.all(color: AdminTheme.border)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: v != null && ids.contains(v) ? v : null,
          isExpanded: true,
          hint: Text(titre, style: const TextStyle(fontSize: 13)),
          items: List.generate(ids.length, (i) => DropdownMenuItem(value: ids[i], child: Text(labels[i], style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))),
          onChanged: ids.isEmpty ? null : onChanged,
        )),
      );

  Future<void> _genererApercu() async {
    // Année académique : celle des sessions correspondantes (la plus récente).
    final match = _sessions.where((s) => s.filiereId == _pFiliere && (s.niveau == _pNiveau || s.niveau == 'Tous') && s.semestre == _pSemestre && s.anneeAcademique != null && s.anneeAcademique!.isNotEmpty);
    _pAnnee = match.isNotEmpty ? match.first.anneeAcademique! : '';
    setState(() => _pChargement = true);
    final r = await NotesAdminService.apercuMoyennes(filiereId: _pFiliere!, niveau: _pNiveau!, semestre: _pSemestre!, annee: _pAnnee);
    if (!mounted) return;
    setState(() => _pChargement = false);
    if (r['success'] == true) {
      final data = r['data'] as Map<String, dynamic>;
      if ((data['modules'] as List).isEmpty) {
        setState(() => _apercu = null);
        _snack('Aucun module transféré pour ce semestre : transfère d\'abord les notes aux étudiants.', isError: true);
      } else {
        setState(() => _apercu = data);
      }
    } else {
      _snack((r['error'] as String?) ?? 'Erreur.', isError: true);
    }
  }

  Widget _apercuTable() {
    final modules = (_apercu!['modules'] as List).cast<Map<String, dynamic>>();
    final etus = (_apercu!['etudiants'] as List).cast<Map<String, dynamic>>();
    final dej = _apercu!['deja_publiees'] ?? 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${modules.length} module(s) · ${etus.length} étudiant(s) — $_pSemestre', style: AdminTheme.headingSmall.copyWith(fontSize: 13)),
      if ((dej as num) > 0) Text('Déjà envoyées à $dej étudiant(s) : un nouvel envoi mettra leurs moyennes à jour.', style: AdminTheme.caption),
      const SizedBox(height: 8),
      Container(
        height: 280,
        decoration: BoxDecoration(border: Border.all(color: AdminTheme.border), borderRadius: BorderRadius.circular(8)),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: SingleChildScrollView(child: DataTable(
          headingRowHeight: 38, dataRowMinHeight: 34, dataRowMaxHeight: 38, columnSpacing: 18,
          columns: [
            const DataColumn(label: Text('Étudiant', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
            ...modules.map((m) => DataColumn(numeric: true, label: Tooltip(message: '${m['nb_devoirs']} devoir(s)', child: SizedBox(width: 90, child: Text('${m['nom']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis))))),
          ],
          rows: etus.map((e) {
            final mods = (e['modules'] as Map).cast<String, dynamic>();
            return DataRow(cells: [
              DataCell(Text('${e['prenoms']} ${e['nom']}', style: const TextStyle(fontSize: 12))),
              ...modules.map((m) {
                final v = mods[m['id'].toString()];
                final moy = v == null ? null : (v['moyenne'] as num).toDouble();
                return DataCell(Text(moy == null ? '—' : moy.toStringAsFixed(2),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: moy == null ? AdminTheme.textMuted : moy >= 10 ? AdminTheme.success : AdminTheme.danger)));
              }),
            ]);
          }).toList(),
        ))),
      ),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: _confirmerPublication,
        icon: const Icon(Icons.send_rounded, size: 16),
        label: const Text('Envoyer aux étudiants'),
        style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.success, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusButton))),
      )),
    ]);
  }

  void _confirmerPublication() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Envoyer les moyennes provisoires ?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      content: Text('Chaque étudiant de $_pNiveau · $_pSemestre recevra uniquement ses propres moyennes par module. Aucune moyenne générale n\'est envoyée.', style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final r = await NotesAdminService.publierMoyennes(filiereId: _pFiliere!, niveau: _pNiveau!, semestre: _pSemestre!, annee: _pAnnee);
            if (!mounted) return;
            if (r['success'] == true) {
              _snack((r['message'] as String?) ?? 'Moyennes envoyées.');
              setState(() => _apercu = null);
            } else {
              _snack((r['error'] as String?) ?? 'Erreur.', isError: true);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.success, foregroundColor: Colors.white, elevation: 0),
          child: const Text('Envoyer'),
        ),
      ],
    ));
  }

  Widget _rappel() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AdminTheme.infoLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AdminTheme.info.withValues(alpha: 0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Rappel du processus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AdminTheme.info)),
          const SizedBox(height: 6),
          ...[
            'Le professeur envoie les notes d\'un module.',
            'Tu les stockes ou les transfères aux étudiants (en un clic).',
            'Tu choisis filière, niveau et semestre.',
            'La moyenne du module = moyenne de ses devoirs.',
            'Tu envoies les moyennes provisoires aux étudiants.',
          ].map((t) => Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('• $t', style: const TextStyle(fontSize: 11.5, color: AdminTheme.info)))),
        ]),
      );

  // ── Helpers ───────────────────────────────────────────────────────────
  String _libelleStatut(String statut) {
    switch (statut) {
      case 'validee': return 'Transférée';
      case 'stockee': return 'Stockée';
      case 'rejetee': return 'Rejetée';
      default: return 'En attente';
    }
  }

  Widget _statusBadge(String statut) {
    Color fg;
    switch (statut) {
      case 'validee': fg = AdminTheme.success; break;
      case 'stockee': fg = AdminTheme.info; break;
      case 'rejetee': fg = AdminTheme.danger; break;
      default: fg = AdminTheme.warning;
    }
    return AdminTheme.badge(_libelleStatut(statut), fg, fg.withValues(alpha: 0.1));
  }

  Widget _erreur() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 32),
        const SizedBox(height: 12),
        Text(_errorMessage ?? 'Erreur', style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _loadData, child: const Text('Réessayer')),
      ]));

  void _snack(String msg, {bool isError = false}) => showAppSnackBar(context, msg, backgroundColor: isError ? AdminTheme.danger : const Color(0xFF1A3C34));
}

// ════════════════════════════════════════════════════════════════════════════
// SAISIE DIRECTE — Widget séparé avec état
// ════════════════════════════════════════════════════════════════════════════
class _SaisieDirecte extends StatefulWidget {
  final VoidCallback onSaved;
  const _SaisieDirecte({required this.onSaved});
  @override State<_SaisieDirecte> createState() => _SaisieDirecteState();
}

class _SaisieDirecteState extends State<_SaisieDirecte> {
  List<Map<String, dynamic>> _filieres = [];
  List<Map<String, dynamic>> _modules = [];
  List<Map<String, dynamic>> _etudiants = [];
  String? _filiereId;
  String? _moduleId;
  String? _niveau;
  String? _semestre;
  String? _mention;
  final _anneeCtrl = TextEditingController(text: '${DateTime.now().year}-${DateTime.now().year + 1}');
  bool _isLoadingBase = true;
  bool _isLoadingModules = false;
  bool _isSaving = false;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _chargerBase();
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    _anneeCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerBase() async {
    setState(() => _isLoadingBase = true);
    final results = await Future.wait([ApiService.getFilieres(), ApiService.getEtudiants()]);
    if (!mounted) return;
    final filieresResult = results[0];
    final etudiantsResult = results[1];
    setState(() {
      _isLoadingBase = false;
      if (filieresResult['success'] == true) {
        _filieres = (filieresResult['data'] as List<dynamic>).cast<Map<String, dynamic>>();
        if (_filieres.isNotEmpty) _filiereId = _filieres.first['id'].toString();
      }
      if (etudiantsResult['success'] == true) {
        _etudiants = (etudiantsResult['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      }
    });
    if (_filiereId != null) _chargerModules(_filiereId!);
  }

  Future<void> _chargerModules(String filiereId) async {
    setState(() { _isLoadingModules = true; _modules = []; _moduleId = null; });
    final result = await ApiService.getModules(filiereId: filiereId);
    if (!mounted) return;
    setState(() {
      _isLoadingModules = false;
      if (result['success'] == true) {
        _modules = (result['data'] as List<dynamic>).cast<Map<String, dynamic>>();
        if (_modules.isNotEmpty) _moduleId = _modules.first['id'].toString();
      }
    });
  }

  // ✅ CORRIGÉ (round 2, confirmé par le vrai code backend) : la fonction
  // mapRowToEtudiant() dans etudiants.controller.js transforme explicitement
  // filiere_id (colonne SQL) en `filiereId` (camelCase) avant de renvoyer le
  // JSON. Ma correction précédente vers `filiere_id` (snake_case) était une
  // déduction par convention, faite avant d'avoir vu ce fichier — elle était
  // fausse. Le code d'origine avait raison sur ce point précis.
  List<Map<String, dynamic>> get _etudiantsFiltres => _etudiants.where((e) {
        final matchFiliere = _filiereId == null || e['filiereId']?.toString() == _filiereId;
        final matchNiveau = _niveau == null || e['niveau'] == _niveau;
        final matchStatut = (e['statut'] ?? 'actif') == 'actif';
        return matchFiliere && matchNiveau && matchStatut;
      }).toList();

  TextEditingController _controllerPour(String matricule) {
    return _controllers.putIfAbsent(matricule, () => TextEditingController());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingBase) return const Center(child: CircularProgressIndicator());
    final moduleNom = _modules.firstWhere((m) => m['id'].toString() == _moduleId, orElse: () => {'nom': '—'})['nom'] as String;

    return Column(children: [
      Container(
        color: AdminTheme.surface,
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Expanded(child: _dropField('Filière', _filiereId, _filieres.map((f) => f['id'].toString()).toList(),
                _filieres.map((f) => f['nom'] as String).toList(), (v) {
              setState(() => _filiereId = v);
              if (v != null) _chargerModules(v);
            })),
            const SizedBox(width: 12),
            Expanded(child: _dropField('Niveau', _niveau, istNiveaux, istNiveaux, (v) => setState(() => _niveau = v))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _isLoadingModules
                ? const SizedBox(height: 44, child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))))
                : _dropField('Module', _moduleId, _modules.map((m) => m['id'].toString()).toList(), _modules.map((m) => m['nom'] as String).toList(), (v) => setState(() => _moduleId = v))),
            const SizedBox(width: 12),
            Expanded(child: _dropField('Semestre', _semestre, semestresDisponibles, semestresDisponibles, (v) => setState(() => _semestre = v))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(AdminTheme.radiusButton), border: Border.all(color: AdminTheme.border)),
                child: TextField(
                  controller: _anneeCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Année académique',
                    labelStyle: TextStyle(fontSize: 12),
                    border: InputBorder.none,
                    hintText: 'ex: 2025-2026',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _dropField('Mention (classe)', _mention, mentionsModule, mentionsModule, (v) => setState(() => _mention = v))),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _sauvegarder,
              icon: _isSaving ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded, size: 16),
              label: const Text('Sauvegarder'),
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusButton))),
            ),
          ),
        ]),
      ),
      const Divider(height: 1, color: AdminTheme.border),
      Container(
        color: AdminTheme.surfaceAlt,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(children: [
          const Expanded(flex: 2, child: Text('Étudiant', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminTheme.textSecondary))),
          const Text('Matricule', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminTheme.textSecondary)),
          const SizedBox(width: 60),
          SizedBox(width: 100, child: Text(moduleNom, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminTheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ),
      const Divider(height: 1, color: AdminTheme.border),
      Expanded(child: _etudiantsFiltres.isEmpty ? _videFiliere() : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _etudiantsFiltres.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AdminTheme.border),
              itemBuilder: (_, i) {
                final e = _etudiantsFiltres[i];
                final nom = (e['nom'] ?? '') as String;
                final prenoms = (e['prenoms'] ?? '') as String;
                final matricule = (e['matricule'] ?? '') as String;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Expanded(flex: 2, child: Row(children: [
                      Container(width: 34, height: 34, decoration: const BoxDecoration(color: AdminTheme.primaryLight, shape: BoxShape.circle),
                          child: Center(child: Text('${prenoms.isNotEmpty ? prenoms[0] : "?"}${nom.isNotEmpty ? nom[0] : "?"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminTheme.primary)))),
                      const SizedBox(width: 10),
                      Expanded(child: Text('$prenoms $nom', style: AdminTheme.headingSmall.copyWith(fontSize: 13))),
                    ])),
                    Text(matricule, style: AdminTheme.caption.copyWith(fontFamily: 'monospace')),
                    const SizedBox(width: 16),
                    SizedBox(width: 90, child: TextField(
                        controller: _controllerPour(matricule),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '—',
                          border: InputBorder.none,
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminTheme.border)),
                        ))),
                  ]),
                );
              })),
    ]);
  }

  Widget _dropField(String hint, String? value, List<String> ids, List<String> labels, ValueChanged<String?> onChanged) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(AdminTheme.radiusButton), border: Border.all(color: AdminTheme.border)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: value, isExpanded: true, hint: Text(hint, style: const TextStyle(fontSize: 13)),
          style: AdminTheme.bodyLarge,
          items: List.generate(ids.length, (i) => DropdownMenuItem(value: ids[i], child: Text(labels[i], style: const TextStyle(fontSize: 13)))),
          onChanged: onChanged,
        )),
      );

  Widget _videFiliere() => Center(child: Text('Aucun étudiant actif trouvé pour ces critères.', style: AdminTheme.bodyMedium));

  Future<void> _sauvegarder() async {
    if (_filiereId == null || _moduleId == null) {
      _snack('Sélectionnez une filière et un module.', isError: true);
      return;
    }
    if (_semestre == null || _anneeCtrl.text.trim().isEmpty) {
      _snack('Le semestre et l\'année académique sont requis.', isError: true);
      return;
    }

    final notesSaisies = <Map<String, dynamic>>[];
    for (final e in _etudiantsFiltres) {
      final matricule = (e['matricule'] ?? '') as String;
      final ctrl = _controllers[matricule];
      if (ctrl != null && ctrl.text.trim().isNotEmpty) {
        final valeur = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
        if (valeur == null || valeur < 0 || valeur > 20) {
          _snack('Note invalide pour ${e['nom']}', isError: true);
          return;
        }
        notesSaisies.add({'matricule': matricule, 'valeur': valeur});
      }
    }
    if (notesSaisies.isEmpty) {
      _snack('Aucune note saisie.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    final filiereNom = _filieres.firstWhere((f) => f['id'].toString() == _filiereId, orElse: () => {'nom': ''})['nom'] as String;

    final result = await ApiService.createSessionNotes({
      'filiere_id': _filiereId,
      'filiere_nom': filiereNom,
      'niveau': _niveau ?? 'Tous',
      'module_id': _moduleId,
      'notes': notesSaisies,
      'statut': 'validee',
      'semestre': _semestre,
      'annee_academique': _anneeCtrl.text.trim(),
      if (_mention != null) 'mention': _mention,
    });

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      for (final ctrl in _controllers.values) {
        ctrl.clear();
      }
      widget.onSaved();
      _snack('✅ ${notesSaisies.length} note(s) enregistrée(s) et envoyée(s) aux étudiants.');
    } else {
      _snack(result['error'] as String? ?? 'Erreur lors de l\'enregistrement.', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) => showAppSnackBar(context, msg, backgroundColor: isError ? AdminTheme.danger : const Color(0xFF1A3C34));
}
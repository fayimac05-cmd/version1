import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../services/professor_service.dart';
import '../services/rattrapage_service.dart';
import '../theme/app_palette.dart';

// Onglet « Rattrapage » du professeur.
// 1. Il choisit sa classe.
// 2. Il voit combien d'étudiants ont validé, combien sont en rattrapage,
//    pour quels modules, et la liste des étudiants concernés.
// 3. Pour chacun de SES modules, il saisit les notes de rattrapage
//    (uniquement pour les étudiants concernés), puis les envoie à l'administration.
class RattrapageTab extends StatefulWidget {
  const RattrapageTab({super.key, required this.profile, this.initialClasse});
  final StudentProfile profile;
  final Map<String, dynamic>? initialClasse;

  @override
  State<RattrapageTab> createState() => _RattrapageTabState();
}

class _RattrapageTabState extends State<RattrapageTab> {
  static const Color _navyText = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _faint = Color(0xFF94A3B8);
  static const Color _border = Color(0xFFE5EBF3);
  static const Color _vert = Color(0xFF10B981);
  static const Color _orange = Color(0xFFF59E0B);
  static const Color _rouge = Color(0xFFEF4444);

  List<dynamic> _classes = [];
  Set<String> _mesModules = {}; // ids des modules enseignés par ce professeur
  Map<String, dynamic>? _classe;
  Map<String, dynamic>? _data;
  bool _chargeClasses = true;
  bool _chargeApercu = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _initialiser();
  }

  Future<void> _initialiser() async {
    final res = await Future.wait([ProfessorService.getClasses(), ProfessorService.getModules()]);
    if (!mounted) return;
    final c = res[0], m = res[1];
    setState(() {
      _classes = c['success'] == true ? (c['data'] as List<dynamic>) : [];
      _mesModules = m['success'] == true
          ? (m['data'] as List<dynamic>).map((x) => '${x['id']}').where((s) => s != 'null').toSet()
          : {};
      _erreur = c['success'] == true ? null : c['error']?.toString();
      _chargeClasses = false;
    });
    final init = widget.initialClasse;
    if (init != null) {
      _choisir(Map<String, dynamic>.from(init));
    }
  }

  Future<void> _choisir(Map<String, dynamic> classe) async {
    setState(() {
      _classe = classe;
      _data = null;
      _chargeApercu = true;
      _erreur = null;
    });
    await _recharger();
  }

  Future<void> _recharger() async {
    final c = _classe;
    if (c == null) return;
    final r = await RattrapageService.apercu(c['id'], '${c['niveau']}');
    if (!mounted) return;
    setState(() {
      _chargeApercu = false;
      if (r['success'] == true) {
        _data = Map<String, dynamic>.from(r['data'] as Map);
      } else {
        _erreur = r['error']?.toString();
      }
    });
  }

  String _fmtDate(dynamic v) {
    final d = DateTime.tryParse('${v ?? ''}');
    if (d == null) return '';
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F7FB),
      child: SafeArea(
        bottom: false,
        child: _chargeClasses
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async => _choisirOuRecharger(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Rattrapage',
                            style: TextStyle(color: _navyText, fontSize: 24, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        const Text(
                            'Suivez les étudiants à repasser et saisissez leurs notes de rattrapage.',
                            style: TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 18),
                        _selecteurClasse(),
                        const SizedBox(height: 16),
                        if (_erreur != null) _bandeau(_erreur!, _rouge),
                        if (_chargeApercu) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
                        if (_data != null) ..._contenu(),
                        if (_classe == null && _erreur == null)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 50),
                            child: Center(child: Text('Choisissez une classe pour commencer.', style: TextStyle(color: _faint, fontSize: 13))),
                          ),
                      ]),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _choisirOuRecharger() async {
    if (_classe != null) await _recharger();
  }

  Widget _bandeau(String texte, Color c) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withValues(alpha: 0.3))),
        child: Text(texte, style: TextStyle(color: c, fontSize: 12.5, fontWeight: FontWeight.w600)),
      );

  Widget _selecteurClasse() {
    final label = _classe == null ? 'Choisir une classe' : '${_classe!['nom']} · ${_classe!['niveau']}';
    return Container(
      height: 46,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: PopupMenuButton<int>(
        tooltip: '',
        onSelected: (i) => _choisir(Map<String, dynamic>.from(_classes[i] as Map)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (_) => [
          for (var i = 0; i < _classes.length; i++)
            PopupMenuItem<int>(
              value: i,
              child: Text('${_classes[i]['nom']} · ${_classes[i]['niveau']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            const Icon(Icons.groups_rounded, size: 18, color: AppPalette.blue),
            const SizedBox(width: 10),
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _navyText, fontSize: 13.5, fontWeight: FontWeight.w700))),
            const Icon(Icons.keyboard_arrow_down_rounded, color: _faint),
          ]),
        ),
      ),
    );
  }

  // ── Contenu après chargement ───────────────────────────────
  List<Widget> _contenu() {
    final d = _data!;
    final semestres = (d['semestres'] as List?) ?? [];
    final etudiants = (d['etudiants'] as List?) ?? [];
    final modules = ((d['modules'] as List?) ?? []).where((m) {
      // Ne montrer que les modules de CE professeur (si la liste est connue).
      return _mesModules.isEmpty || _mesModules.contains('${m['module_id']}');
    }).toList();
    final debut = _fmtDate(d['date_debut']);
    final fin = _fmtDate(d['date_fin']);

    return [
      Wrap(spacing: 8, runSpacing: 8, children: [
        _pastille(Icons.event_note_rounded, 'Année ${d['annee_academique']}', AppPalette.blue),
        if (debut.isNotEmpty && fin.isNotEmpty) _pastille(Icons.date_range_rounded, 'Rattrapage du $debut au $fin', _orange),
        if (debut.isEmpty || fin.isEmpty) _pastille(Icons.date_range_rounded, 'Dates du rattrapage non fixées', _faint),
      ]),
      const SizedBox(height: 14),
      if (semestres.isEmpty)
        _bandeau('Aucun bulletin publié pour cette classe cette année : le rattrapage sera calculé après la publication des bulletins.', _muted)
      else
        Wrap(spacing: 12, runSpacing: 12, children: [
          for (final s in semestres) _carteSemestre(s),
        ]),
      const SizedBox(height: 22),
      const Text('Mes modules à repasser', style: TextStyle(color: _navyText, fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      if (modules.isEmpty)
        _bandeau('Aucun étudiant ne doit repasser un de vos modules.', _vert)
      else
        for (final m in modules) ...[_carteModule(m, etudiants), const SizedBox(height: 10)],
      const SizedBox(height: 18),
      Text('Étudiants en rattrapage (${etudiants.length})',
          style: const TextStyle(color: _navyText, fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      if (etudiants.isEmpty)
        _bandeau('Aucun étudiant en rattrapage dans cette classe.', _vert)
      else
        for (final e in etudiants) ...[_ligneEtudiant(e), const SizedBox(height: 8)],
    ];
  }

  Widget _pastille(IconData ic, String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(ic, size: 14, color: c),
          const SizedBox(width: 6),
          Text(t, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _carteSemestre(dynamic s) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Semestre ${'${s['semestre']}'.replaceAll('S', '')}', style: const TextStyle(color: _navyText, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Row(children: [
          _chiffre('${s['nb_valides']}', 'validé(s)', _vert),
          const SizedBox(width: 22),
          _chiffre('${s['nb_rattrapage']}', 'en rattrapage', _orange),
          const SizedBox(width: 22),
          _chiffre('${s['nb_total']}', 'total', _muted),
        ]),
      ]),
    );
  }

  Widget _chiffre(String v, String l, Color c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(v, style: TextStyle(color: c, fontSize: 20, fontWeight: FontWeight.w900)),
        Text(l, style: const TextStyle(color: _faint, fontSize: 10, fontWeight: FontWeight.w600)),
      ]);

  // ── Un module : statut de la session + bouton de saisie ────
  Widget _carteModule(dynamic m, List<dynamic> etudiants) {
    final session = m['session'] as Map?;
    final statut = session?['statut']?.toString();
    final envoyee = session?['is_sent'] == true;
    String etat;
    Color couleur;
    if (session == null) {
      etat = 'Notes à saisir';
      couleur = _orange;
    } else if (statut == 'validee') {
      etat = 'Validée par l\'administration';
      couleur = _vert;
    } else if (statut == 'rejetee') {
      etat = 'Rejetée — à corriger';
      couleur = _rouge;
    } else if (envoyee) {
      etat = 'Envoyée — en attente de validation';
      couleur = AppPalette.blue;
    } else {
      etat = 'Brouillon enregistré';
      couleur = _muted;
    }
    final concernes = etudiants
        .where((e) => ((e['modules'] as List?) ?? []).any((x) => '${x['module_id']}' == '${m['module_id']}'))
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${m['module_nom']}', style: const TextStyle(color: _navyText, fontSize: 14.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text('${m['semestre']} · ${m['nb_concernes']} étudiant(s) concerné(s)', style: const TextStyle(color: _muted, fontSize: 12)),
            ]),
          ),
          _pastille(Icons.circle, etat, couleur),
        ]),
        if (statut == 'rejetee' && (session?['motif_rejet'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          _bandeau('Motif du rejet : ${session!['motif_rejet']}', _rouge),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: Icon(statut == 'validee' ? Icons.visibility_outlined : Icons.edit_note_rounded, size: 18),
            label: Text(statut == 'validee' ? 'Voir les notes' : 'Saisir les notes', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _ouvrirEditeur(m, concernes),
          ),
        ),
      ]),
    );
  }

  void _ouvrirEditeur(dynamic module, List<dynamic> concernes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditeurNotesRattrapage(
        classe: _classe!,
        module: Map<String, dynamic>.from(module as Map),
        etudiants: concernes,
        onChange: _recharger,
      ),
    );
  }

  Widget _ligneEtudiant(dynamic e) {
    final modules = (e['modules'] as List?) ?? [];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('${e['prenoms'] ?? ''} ${e['nom'] ?? ''}'.trim(), style: const TextStyle(color: _navyText, fontSize: 13.5, fontWeight: FontWeight.w800))),
          Text('${e['matricule'] ?? ''}', style: const TextStyle(color: _faint, fontSize: 11.5)),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final x in modules)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: _orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(
                '${x['module_nom']}${x['moyenne_normale'] != null ? ' (${(x['moyenne_normale'] as num).toStringAsFixed(2)})' : ''}',
                style: const TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
        ]),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Feuille de saisie des notes d'un module
// ═══════════════════════════════════════════════════════════════════════
class _EditeurNotesRattrapage extends StatefulWidget {
  const _EditeurNotesRattrapage({
    required this.classe,
    required this.module,
    required this.etudiants,
    required this.onChange,
  });
  final Map<String, dynamic> classe;
  final Map<String, dynamic> module;
  final List<dynamic> etudiants;
  final Future<void> Function() onChange;

  @override
  State<_EditeurNotesRattrapage> createState() => _EditeurNotesRattrapageState();
}

class _EditeurNotesRattrapageState extends State<_EditeurNotesRattrapage> {
  final Map<String, TextEditingController> _ctrl = {};
  bool _envoi = false;

  bool get _verrouille => widget.module['session']?['statut'] == 'validee';

  String _noteNormale(dynamic e) {
    for (final x in (e['modules'] as List?) ?? []) {
      if ('${x['module_id']}' == '${widget.module['module_id']}' && x['moyenne_normale'] != null) {
        return (x['moyenne_normale'] as num).toStringAsFixed(2);
      }
    }
    return '—';
  }

  @override
  void initState() {
    super.initState();
    final deja = <String, dynamic>{};
    for (final n in (widget.module['session']?['notes'] as List?) ?? []) {
      deja['${n['etudiant_id']}'] = n['valeur'];
    }
    for (final e in widget.etudiants) {
      final v = deja['${e['etudiant_id']}'];
      _ctrl['${e['matricule']}'] = TextEditingController(text: v == null ? '' : (v as num).toString());
    }
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _msg(String t, {bool erreur = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(t),
      backgroundColor: erreur ? Colors.red : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _sauver({required bool envoyer}) async {
    final notes = <Map<String, dynamic>>[];
    for (final e in widget.etudiants) {
      final txt = _ctrl['${e['matricule']}']!.text.trim().replaceAll(',', '.');
      if (txt.isEmpty) continue; // absent : la note normale est conservée
      final v = double.tryParse(txt);
      if (v == null || v < 0 || v > 20) {
        _msg('Note invalide pour ${e['prenoms']} ${e['nom']} (0 à 20).', erreur: true);
        return;
      }
      notes.add({'matricule': e['matricule'], 'valeur': v});
    }
    if (envoyer && notes.isEmpty) {
      _msg('Saisissez au moins une note avant d\'envoyer.', erreur: true);
      return;
    }
    setState(() => _envoi = true);
    final r = await RattrapageService.creerSession(
      filiereId: widget.classe['id'],
      niveau: '${widget.classe['niveau']}',
      moduleId: widget.module['module_id'],
      notes: notes,
    );
    if (!mounted) return;
    if (r['success'] != true) {
      setState(() => _envoi = false);
      _msg(r['error']?.toString() ?? 'Erreur.', erreur: true);
      return;
    }
    if (envoyer) {
      final s = await RattrapageService.envoyer('${r['session_id']}');
      if (!mounted) return;
      if (s['success'] != true) {
        setState(() => _envoi = false);
        _msg(s['error']?.toString() ?? 'Envoi impossible.', erreur: true);
        await widget.onChange();
        return;
      }
    }
    await widget.onChange();
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(envoyer ? 'Notes envoyées à l\'administration.' : 'Brouillon enregistré.'),
      backgroundColor: const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bas = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: bas),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${widget.module['module_nom']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 2),
              Text(
                _verrouille
                    ? 'Session validée : lecture seule.'
                    : 'Laissez vide un étudiant absent : sa note normale est conservée.',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
            ]),
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: widget.etudiants.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final e = widget.etudiants[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${e['prenoms'] ?? ''} ${e['nom'] ?? ''}'.trim(), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      Text('${e['matricule']} · note normale ${_noteNormale(e)}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
                    ]),
                  ),
                  SizedBox(
                    width: 84,
                    child: TextField(
                      controller: _ctrl['${e['matricule']}'],
                      enabled: !_verrouille,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '/20',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ]),
              );
            },
          ),
        ),
        if (!_verrouille)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _envoi ? null : () => _sauver(envoyer: false),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _envoi ? null : () => _sauver(envoyer: true),
                  icon: _envoi
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Envoyer à l\'administration', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}

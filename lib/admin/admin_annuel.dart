import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../services/annuel_service.dart';
import '../utils/snackbar_helper.dart';

// Administration — Fin d'année :
//  • avancement des décisions (admis / redoublant / diplômé) classe par classe ;
//  • aperçu d'une classe, correction à la main, validation de toute la classe en une action ;
//  • clôture de l'année et ouverture de la suivante (les années passées passent en lecture seule).
class AdminAnnuel extends StatefulWidget {
  const AdminAnnuel({super.key});
  @override
  State<AdminAnnuel> createState() => _AdminAnnuelState();
}

const Map<String, String> _libelles = {
  'admis': 'Admis',
  'redoublant': 'Redoublant',
  'diplome': 'Diplômé',
  'abandon': 'Abandon',
  'incomplet': 'Incomplet',
};

Color _couleurDecision(String? d) {
  switch (d) {
    case 'admis':
      return const Color(0xFF15803D);
    case 'diplome':
      return const Color(0xFF1D4ED8);
    case 'redoublant':
      return const Color(0xFFD97706);
    case 'abandon':
      return const Color(0xFF64748B);
    case 'incomplet':
      return const Color(0xFFC62828);
    default:
      return const Color(0xFF94A3B8);
  }
}

class _AdminAnnuelState extends State<AdminAnnuel> {
  Map<String, dynamic> _etat = {};
  bool _charge = true;
  String? _erreur;
  bool _cloture = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _charge = true;
      _erreur = null;
    });
    final r = await AnnuelService.etat();
    if (!mounted) return;
    setState(() {
      _charge = false;
      if (r['success'] == true) {
        _etat = Map<String, dynamic>.from((r['data'] as Map?) ?? {});
      } else {
        _erreur = r['error']?.toString();
      }
    });
  }

  void _snack(String m, {bool erreur = false}) =>
      showAppSnackBar(context, m, backgroundColor: erreur ? AdminTheme.danger : const Color(0xFF1A3C34));

  Future<void> _ouvrirClasse(dynamic c) async {
    final modifie = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FeuilleClasse(
        filiereId: c['filiere_id'],
        niveau: '${c['niveau']}',
        titre: '${c['filiere_nom'] ?? 'Filière'} · ${c['niveau']}',
        lectureSeule: '${_etat['statut']}' != 'en_cours',
      ),
    );
    if (modifie == true) _charger();
  }

  Future<void> _cloturer() async {
    final ctrl = TextEditingController(text: '${_etat['prochaine_annee'] ?? ''}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clôturer l\'année ?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'L\'année ${_etat['annee']} passera en lecture seule (rien n\'est supprimé). '
            'Les diplômés quittent les classes actives. Les admis et les redoublants devront se réinscrire : '
            'leur niveau ne changera qu\'à la validation de leur réinscription.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          const Text('Année à ouvrir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, hintText: '2026-2027'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clôturer')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _cloture = true);
    final r = await AnnuelService.cloturer(ctrl.text.trim());
    if (!mounted) return;
    setState(() => _cloture = false);
    _snack(r['success'] == true ? (r['message']?.toString() ?? 'Année clôturée.') : (r['error']?.toString() ?? 'Erreur.'),
        erreur: r['success'] != true);
    if (r['success'] == true) _charger();
  }

  @override
  Widget build(BuildContext context) {
    if (_charge) return const Center(child: CircularProgressIndicator());
    if (_erreur != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_erreur!),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _charger, child: const Text('Réessayer')),
        ]),
      );
    }
    final classes = (_etat['classes'] as List?) ?? [];
    final restants = (_etat['sans_decision'] as num?)?.toInt() ?? 0;
    final enCours = '${_etat['statut']}' == 'en_cours';
    final pret = _etat['pret_a_cloturer'] == true;

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Fin d\'année ${_etat['annee'] ?? ''}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 6),
          Text(
            enCours
                ? (restants == 0 && classes.isNotEmpty
                    ? 'Toutes les décisions sont prises : tu peux clôturer l\'année.'
                    : '$restants étudiant(s) sans décision. Valide chaque classe, puis clôture l\'année.')
                : 'Cette année est clôturée (lecture seule).',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          if (classes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Aucun étudiant inscrit pour cette année.')),
            ),
          for (final c in classes) ...[_carteClasse(c), const SizedBox(height: 10)],
          if (enCours) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: (pret && !_cloture) ? _cloturer : null,
                icon: _cloture
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.lock_outline_rounded),
                label: Text('Clôturer ${_etat['annee'] ?? ''} et ouvrir ${_etat['prochaine_annee'] ?? 'la suivante'}'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _carteClasse(dynamic c) {
    final total = (c['nb_etudiants'] as num?)?.toInt() ?? 0;
    final decides = (c['nb_decides'] as num?)?.toInt() ?? 0;
    final complet = total > 0 && decides == total;
    return InkWell(
      onTap: () => _ouvrirClasse(c),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: complet ? const Color(0xFF15803D).withValues(alpha: 0.4) : const Color(0xFFE2E8F0)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${c['filiere_nom'] ?? 'Filière'} · ${c['niveau']}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                _pastille('$decides / $total décidés', complet ? const Color(0xFF15803D) : const Color(0xFF64748B)),
                if ((c['nb_admis'] as num? ?? 0) > 0) _pastille('${c['nb_admis']} admis', _couleurDecision('admis')),
                if ((c['nb_redoublants'] as num? ?? 0) > 0)
                  _pastille('${c['nb_redoublants']} redoublants', _couleurDecision('redoublant')),
                if ((c['nb_diplomes'] as num? ?? 0) > 0) _pastille('${c['nb_diplomes']} diplômés', _couleurDecision('diplome')),
                if ((c['nb_abandons'] as num? ?? 0) > 0) _pastille('${c['nb_abandons']} abandons', _couleurDecision('abandon')),
              ]),
            ]),
          ),
          Icon(complet ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              color: complet ? const Color(0xFF15803D) : const Color(0xFF94A3B8)),
        ]),
      ),
    );
  }
}

Widget _pastille(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(t, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c)),
    );

// ── Feuille d'une classe : aperçu, corrections, validation ─────────────────
class _FeuilleClasse extends StatefulWidget {
  final dynamic filiereId;
  final String niveau;
  final String titre;
  final bool lectureSeule;
  const _FeuilleClasse({
    required this.filiereId,
    required this.niveau,
    required this.titre,
    required this.lectureSeule,
  });
  @override
  State<_FeuilleClasse> createState() => _FeuilleClasseState();
}

class _FeuilleClasseState extends State<_FeuilleClasse> {
  Map<String, dynamic> _data = {};
  final Map<String, String> _corrections = {};
  bool _charge = true;
  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _charge = true;
      _erreur = null;
    });
    final r = await AnnuelService.apercuDecisions(widget.filiereId, widget.niveau);
    if (!mounted) return;
    setState(() {
      _charge = false;
      if (r['success'] == true) {
        _data = Map<String, dynamic>.from((r['data'] as Map?) ?? {});
      } else {
        _erreur = r['error']?.toString();
      }
    });
  }

  void _snack(String m, {bool erreur = false}) =>
      showAppSnackBar(context, m, backgroundColor: erreur ? AdminTheme.danger : const Color(0xFF1A3C34));

  // Décision affichée : correction en cours > proposition du serveur.
  String _decisionDe(dynamic e) {
    final id = '${e['etudiant_id']}';
    if (_corrections.containsKey(id)) return _corrections[id]!;
    final p = '${e['proposee']}';
    if (p == 'admis' && _data['niveau_final'] == true) return 'diplome';
    return p;
  }

  Future<void> _valider({bool forcer = false}) async {
    setState(() => _envoi = true);
    final r = await AnnuelService.validerDecisions(
      filiereId: widget.filiereId,
      niveau: widget.niveau,
      corrections: _corrections,
      forcer: forcer,
    );
    if (!mounted) return;
    setState(() => _envoi = false);
    if (r['success'] == true) {
      _snack(r['message']?.toString() ?? 'Décisions enregistrées.');
      Navigator.pop(context, true);
      return;
    }
    final raw = (r['raw'] as Map?) ?? {};
    if (raw['rattrapage_attendu'] != null && !forcer) {
      final oui = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Rattrapage non terminé ?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          content: Text('${raw['message']}\n\nValider quand même ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Attendre')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Valider quand même')),
          ],
        ),
      );
      if (oui == true) _valider(forcer: true);
      return;
    }
    _snack(r['error']?.toString() ?? 'Erreur.', erreur: true);
  }

  @override
  Widget build(BuildContext context) {
    final etudiants = (_data['etudiants'] as List?) ?? [];
    final incomplets = etudiants.where((e) => _decisionDe(e) == 'incomplet').length;
    final resume = <String, int>{};
    for (final e in etudiants) {
      final d = _decisionDe(e);
      resume[d] = (resume[d] ?? 0) + 1;
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.92,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 6),
          child: Row(children: [
            Expanded(
              child: Text(widget.titre,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            ),
            IconButton(onPressed: () => Navigator.pop(context, false), icon: const Icon(Icons.close_rounded)),
          ]),
        ),
        if (_charge)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_erreur != null)
          Expanded(child: Center(child: Text(_erreur!)))
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(spacing: 6, runSpacing: 6, children: [
                for (final k in ['admis', 'diplome', 'redoublant', 'abandon', 'incomplet'])
                  if ((resume[k] ?? 0) > 0) _pastille('${resume[k]} ${_libelles[k]!.toLowerCase()}', _couleurDecision(k)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: etudiants.isEmpty
                ? const Center(child: Text('Aucun étudiant dans cette classe.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    itemCount: etudiants.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    itemBuilder: (_, i) => _ligne(etudiants[i]),
                  ),
          ),
          if (!widget.lectureSeule)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (incomplets > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '$incomplets étudiant(s) sans tous leurs bulletins : choisis leur décision à la main (menu à droite de leur nom) ou publie leurs bulletins.',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFC62828)),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: (_envoi || incomplets > 0 || etudiants.isEmpty) ? null : () => _valider(),
                      icon: _envoi
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.done_all_rounded),
                      label: const Text('Valider les décisions de la classe'),
                    ),
                  ),
                ]),
              ),
            ),
        ],
      ]),
    );
  }

  Widget _ligne(dynamic e) {
    final id = '${e['etudiant_id']}';
    final d = _decisionDe(e);
    final corrige = _corrections.containsKey(id);
    final sems = (e['semestres'] as List?) ?? [];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${e['nom']} ${e['prenoms'] ?? ''}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            Text('${e['matricule']}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            Wrap(spacing: 10, runSpacing: 2, children: [
              for (final s in sems) _semestre(s),
            ]),
            if (e['rattrapage_attendu'] == true)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text('Pas encore de bulletin après rattrapage',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFFD97706))),
              ),
          ]),
        ),
        const SizedBox(width: 8),
        widget.lectureSeule
            ? _pastille('${_libelles[d] ?? d}', _couleurDecision(d))
            : PopupMenuButton<String>(
                tooltip: 'Changer la décision',
                onSelected: (v) => setState(() {
                  if (v == '_auto') {
                    _corrections.remove(id);
                  } else {
                    _corrections[id] = v;
                  }
                }),
                itemBuilder: (_) => [
                  for (final k in ['admis', 'redoublant', 'diplome', 'abandon'])
                    PopupMenuItem(value: k, child: Text(_libelles[k]!)),
                  if (corrige) const PopupMenuItem(value: '_auto', child: Text('Revenir à la proposition')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _couleurDecision(d).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: corrige ? Border.all(color: _couleurDecision(d)) : null,
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_libelles[d] ?? d,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _couleurDecision(d))),
                    Icon(Icons.arrow_drop_down_rounded, size: 18, color: _couleurDecision(d)),
                  ]),
                ),
              ),
      ]),
    );
  }

  Widget _semestre(dynamic s) {
    final ok = '${s['statut_final']}' == 'valide';
    final manquant = s['statut_final'] == null;
    final moy = (s['moyenne_finale'] as num?)?.toStringAsFixed(2);
    final c = manquant ? const Color(0xFFC62828) : (ok ? const Color(0xFF15803D) : const Color(0xFFD97706));
    final suite = s['apres_rattrapage'] == true ? ' (rattrapage)' : '';
    return Text(
      manquant ? '${s['semestre']} : pas de bulletin' : '${s['semestre']} : ${moy ?? '—'}${ok ? ' validé' : ' non validé'}$suite',
      style: TextStyle(fontSize: 11.5, color: c, fontWeight: FontWeight.w600),
    );
  }
}

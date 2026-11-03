import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../services/rattrapage_service.dart';
import '../utils/snackbar_helper.dart';

// Administration — Rattrapage :
//  • paramètres de l'année en cours (dates du rattrapage, règle de la note) ;
//  • validation des notes de rattrapage envoyées par les professeurs.
class AdminRattrapage extends StatefulWidget {
  const AdminRattrapage({super.key});
  @override
  State<AdminRattrapage> createState() => _AdminRattrapageState();
}

class _AdminRattrapageState extends State<AdminRattrapage> {
  // Année en cours
  Map<String, dynamic>? _annee;
  DateTime? _debut, _fin;
  String _regle = 'remplace';
  bool _sauvegarde = false;

  // Sessions
  String _statut = 'en_attente';
  List<dynamic> _sessions = [];
  bool _charge = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _tout();
  }

  Future<void> _tout() async {
    await Future.wait([_chargerAnnee(), _chargerSessions()]);
  }

  Future<void> _chargerAnnee() async {
    final r = await RattrapageService.anneeCourante();
    if (!mounted) return;
    setState(() {
      if (r['success'] == true && r['data'] != null) {
        _annee = Map<String, dynamic>.from(r['data'] as Map);
        _debut = DateTime.tryParse('${_annee!['date_rattrapage_debut'] ?? ''}')?.toLocal();
        _fin = DateTime.tryParse('${_annee!['date_rattrapage_fin'] ?? ''}')?.toLocal();
        _regle = '${_annee!['regle_rattrapage'] ?? 'remplace'}';
      } else {
        _annee = null;
      }
    });
  }

  Future<void> _chargerSessions() async {
    setState(() {
      _charge = true;
      _erreur = null;
    });
    final r = await RattrapageService.sessionsAdmin(_statut);
    if (!mounted) return;
    setState(() {
      _charge = false;
      if (r['success'] == true) {
        _sessions = (r['data'] as List?) ?? [];
      } else {
        _sessions = [];
        _erreur = r['error']?.toString();
      }
    });
  }

  String _fmt(DateTime? d) => d == null
      ? 'Non fixée'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _iso(DateTime? d) => d == null
      ? ''
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _choisirDate(bool debut) async {
    final base = (debut ? _debut : _fin) ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(base.year - 1),
      lastDate: DateTime(base.year + 2),
    );
    if (d == null) return;
    setState(() => debut ? _debut = d : _fin = d);
  }

  Future<void> _enregistrerParametres() async {
    if (_annee == null) return;
    setState(() => _sauvegarde = true);
    final r = await RattrapageService.reglerRattrapage(
      _annee!['id'],
      debut: _debut == null ? null : _iso(_debut),
      fin: _fin == null ? null : _iso(_fin),
      regle: _regle,
    );
    if (!mounted) return;
    setState(() => _sauvegarde = false);
    _snack(r['success'] == true ? (r['message']?.toString() ?? 'Enregistré.') : (r['error']?.toString() ?? 'Erreur.'),
        erreur: r['success'] != true);
  }

  void _snack(String m, {bool erreur = false}) =>
      showAppSnackBar(context, m, backgroundColor: erreur ? AdminTheme.danger : const Color(0xFF1A3C34));

  // ── Actions sur une session ────────────────────────────────
  Future<void> _voir(dynamic s) async {
    final r = await RattrapageService.detail('${s['id']}');
    if (!mounted) return;
    if (r['success'] != true) {
      _snack(r['error']?.toString() ?? 'Erreur.', erreur: true);
      return;
    }
    final notes = ((r['data'] as Map)['notes'] as List?) ?? [];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${s['module_nom']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 480,
          child: notes.isEmpty
              ? const Text('Aucune note saisie.')
              : SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    for (final n in notes)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(children: [
                          Expanded(child: Text('${n['prenoms']} ${n['nom']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                          Text('${n['matricule']}', style: AdminTheme.caption),
                          const SizedBox(width: 12),
                          Text('${double.tryParse('${n['valeur']}')?.toStringAsFixed(2) ?? n['valeur']}/20',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: (double.tryParse('${n['valeur']}') ?? 0) >= 10 ? AdminTheme.success : AdminTheme.danger)),
                        ]),
                      ),
                  ]),
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
      ),
    );
  }

  Future<void> _valider(dynamic s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Valider les notes de rattrapage ?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Text(
            '${s['module_nom']} · ${s['nb_notes']} note(s). Chaque étudiant reçoit uniquement sa propre note.',
            style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.success, foregroundColor: Colors.white, elevation: 0),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final r = await RattrapageService.valider('${s['id']}');
    if (!mounted) return;
    _snack(r['success'] == true ? (r['message']?.toString() ?? 'Validé.') : (r['error']?.toString() ?? 'Erreur.'),
        erreur: r['success'] != true);
    if (r['success'] == true) _chargerSessions();
  }

  Future<void> _rejeter(dynamic s) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rejeter la session', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Indiquez le motif pour ${s['module_nom']}.', style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(hintText: 'Ex : notes incohérentes…', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.danger, foregroundColor: Colors.white),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
    final motif = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true) return;
    final r = await RattrapageService.rejeter('${s['id']}', motif);
    if (!mounted) return;
    _snack(r['success'] == true ? (r['message']?.toString() ?? 'Rejeté.') : (r['error']?.toString() ?? 'Erreur.'),
        erreur: r['success'] != true);
    if (r['success'] == true) _chargerSessions();
  }

  // ── Interface ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: RefreshIndicator(
        onRefresh: _tout,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Rattrapage', style: AdminTheme.headingLarge),
            Text('Paramètres de la session et validation des notes envoyées par les professeurs.', style: AdminTheme.bodyMedium),
            const SizedBox(height: 16),
            _cartesParametres(),
            const SizedBox(height: 16),
            _blocSessions(),
          ]),
        ),
      ),
    );
  }

  BoxDecoration get _carte => BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radiusCard),
        border: Border.all(color: AdminTheme.border),
        boxShadow: AdminTheme.cardShadow,
      );

  Widget _cartesParametres() {
    if (_annee == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _carte,
        child: Text('Aucune année académique en cours : créez-en une avant de régler le rattrapage.', style: AdminTheme.bodyMedium),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _carte,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Année ${_annee!['libelle']} — paramètres du rattrapage', style: AdminTheme.headingSmall),
        const SizedBox(height: 4),
        Text('Le rattrapage a lieu une fois par an, aux dates fixées par l\'établissement.', style: AdminTheme.caption),
        const SizedBox(height: 14),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _boutonDate('Début', _debut, () => _choisirDate(true)),
          _boutonDate('Fin', _fin, () => _choisirDate(false)),
        ]),
        const SizedBox(height: 14),
        Text('Note retenue après rattrapage', style: AdminTheme.caption.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [
          ChoiceChip(
            label: const Text('La note de rattrapage remplace la note normale'),
            selected: _regle == 'remplace',
            onSelected: (_) => setState(() => _regle = 'remplace'),
          ),
          ChoiceChip(
            label: const Text('On garde la meilleure des deux'),
            selected: _regle == 'meilleure',
            onSelected: (_) => setState(() => _regle = 'meilleure'),
          ),
        ]),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: _sauvegarde ? null : _enregistrerParametres,
          icon: _sauvegarde
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_outlined, size: 16),
          label: const Text('Enregistrer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusButton)),
          ),
        ),
      ]),
    );
  }

  Widget _boutonDate(String titre, DateTime? d, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AdminTheme.radiusButton),
        child: Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AdminTheme.surface,
            borderRadius: BorderRadius.circular(AdminTheme.radiusButton),
            border: Border.all(color: AdminTheme.border),
          ),
          child: Row(children: [
            const Icon(Icons.event_rounded, size: 16, color: AdminTheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('$titre : ${_fmt(d)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          ]),
        ),
      );

  Widget _blocSessions() {
    Widget onglet(String code, String label) {
      final actif = _statut == code;
      return ChoiceChip(
        label: Text(label),
        selected: actif,
        onSelected: (_) {
          setState(() => _statut = code);
          _chargerSessions();
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _carte,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Notes de rattrapage reçues', style: AdminTheme.headingSmall),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: [
          onglet('en_attente', 'En attente'),
          onglet('validee', 'Validées'),
          onglet('rejetee', 'Rejetées'),
        ]),
        const SizedBox(height: 12),
        if (_charge)
          const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
        else if (_erreur != null)
          Text(_erreur!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))
        else if (_sessions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(30),
            child: Center(child: Text('Aucune session dans cette vue.', style: AdminTheme.bodyMedium)),
          )
        else
          for (final s in _sessions) ...[_ligne(s), const Divider(height: 1, color: AdminTheme.border)],
      ]),
    );
  }

  Widget _ligne(dynamic s) {
    final prof = '${s['prof_prenoms'] ?? ''} ${s['prof_nom'] ?? ''}'.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 330,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${s['module_nom']}', style: AdminTheme.headingSmall.copyWith(fontSize: 13.5)),
              Text(
                '${s['filiere_nom'] ?? ''} · ${s['niveau']} · ${s['semestre']} · ${s['nb_notes']} note(s)',
                style: AdminTheme.bodyMedium.copyWith(fontSize: 12),
              ),
              if (prof.isNotEmpty) Text('Prof. $prof', style: AdminTheme.caption),
              if (_statut == 'rejetee' && '${s['motif_rejet'] ?? ''}'.isNotEmpty)
                Text('Motif : ${s['motif_rejet']}', style: AdminTheme.caption.copyWith(color: AdminTheme.danger)),
            ]),
          ),
          OutlinedButton(onPressed: () => _voir(s), child: const Text('Voir')),
          if (_statut == 'en_attente') ...[
            ElevatedButton(
              onPressed: () => _valider(s),
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.success, foregroundColor: Colors.white, elevation: 0),
              child: const Text('Valider'),
            ),
            TextButton(
              onPressed: () => _rejeter(s),
              child: const Text('Rejeter', style: TextStyle(color: AdminTheme.danger)),
            ),
          ],
        ],
      ),
    );
  }
}

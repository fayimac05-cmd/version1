import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_widgets.dart';
import '../admin/admin_filieres.dart';
import '../services/api_service.dart';
import '../utils/snackbar_helper.dart';

class AdminEvaluations extends StatefulWidget {
  const AdminEvaluations({super.key});
  @override
  State<AdminEvaluations> createState() => _AdminEvaluationsState();
}

class _AdminEvaluationsState extends State<AdminEvaluations> {
  bool _loading = true;
  String? _erreur;
  List<dynamic> _periodes = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _erreur = null; });
    final result = await ApiService.getPeriodesEvaluation();
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        _periodes = result['data'] as List<dynamic>;
      } else {
        _erreur = result['error']?.toString() ?? 'Erreur lors du chargement.';
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Column(children: [
        AdminPageHeader(
          title: 'Évaluation des Professeurs',
          subtitle: 'Évaluations anonymes par les étudiants',
          trailing: AdminAddButton(label: 'Ouvrir une période', onTap: () => _ouvrirPeriode()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AdminTheme.infoLight,
                borderRadius: BorderRadius.circular(10)),
            child: const Row(children: [
              Icon(Icons.shield_rounded, color: AdminTheme.info, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Les évaluations sont anonymes pour vous : les réponses sont liées à un compte étudiant uniquement pour empêcher les votes multiples, jamais affichées ici.',
                style: TextStyle(fontSize: 12, color: AdminTheme.info,
                    fontWeight: FontWeight.w600))),
            ]),
          ),
        ),
        adminDivider,
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _erreur != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_erreur!, style: const TextStyle(color: AdminTheme.danger)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _charger, child: const Text('Réessayer')),
                    ]))
                  : _periodes.isEmpty
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.rate_review_outlined, size: 48, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 12),
                            const Text('Aucune période d\'évaluation', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                          ]),
                        )
                      : RefreshIndicator(
                          onRefresh: _charger,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _periodes.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) => _cartePeriode(_periodes[i] as Map<String, dynamic>),
                          ),
                        ),
        ),
      ]),
    );
  }

  Widget _cartePeriode(Map<String, dynamic> ev) {
    final ouverte = ev['ouverte'] == true;
    final nbReponses = int.tryParse('${ev['nb_reponses']}') ?? 0;
    final dateDebut = _formatDate(ev['date_debut']);
    final dateFin = _formatDate(ev['date_fin']);

    return Container(
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ouverte
              ? AdminTheme.success.withValues(alpha:0.3) : const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(
                color: ouverte ? AdminTheme.successLight : const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(ouverte ? Icons.lock_open_rounded : Icons.lock_rounded,
                  color: ouverte ? AdminTheme.success : const Color(0xFF9CA3AF),
                  size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${ev['filiere_nom'] ?? ''}', style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              Text('Du $dateDebut au $dateFin',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ouverte ? AdminTheme.successLight : const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(20)),
              child: Text(ouverte ? '🟢 Ouverte' : '⚫ Fermée',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: ouverte ? AdminTheme.success : const Color(0xFF9CA3AF)))),
          ])),

        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text('$nbReponses réponse(s) reçue(s)',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
        ),

        adminDivider,
        Padding(padding: const EdgeInsets.all(12),
          child: Row(children: [
            if (ouverte) ...[
              Expanded(child: _btn('🔒 Clôturer', AdminTheme.danger, AdminTheme.dangerLight,
                () => _cloturer(ev['id'].toString()))),
              const SizedBox(width: 8),
            ],
            Expanded(child: _btn('📊 Voir le rapport',
                AdminTheme.primary, AdminTheme.primaryLight,
                () => _voirRapport(ev['id'].toString(), '${ev['filiere_nom'] ?? ''}'))),
          ])),
      ]));
  }

  String _formatDate(dynamic iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso.toString());
    if (dt == null) return iso.toString();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Future<void> _cloturer(String id) async {
    final result = await ApiService.cloturerPeriodeEvaluation(id);
    if (!mounted) return;
    if (result['success'] == true) {
      _snack('Période d\'évaluation clôturée.');
      _charger();
    } else {
      _snack(result['error']?.toString() ?? 'Erreur lors de la clôture.');
    }
  }

  void _voirRapport(String periodeId, String filiereNom) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _RapportEvaluationScreen(periodeId: periodeId, filiereNom: filiereNom)),
    );
  }

  void _ouvrirPeriode() {
    final debutCtrl = TextEditingController();
    final finCtrl = TextEditingController();
    String? filiereSelectedId = adminFilieres.isNotEmpty ? adminFilieres.first.id.toString() : null;
    bool envoi = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Ouvrir une période d\'évaluation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(10)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: filiereSelectedId,
                  isExpanded: true,
                  hint: const Text('Choisir une filière'),
                  items: adminFilieres.map((f) => DropdownMenuItem(value: f.id.toString(), child: Text(f.nom))).toList(),
                  onChanged: (v) => setS(() => filiereSelectedId = v),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: debutCtrl, decoration: const InputDecoration(labelText: 'Date début (AAAA-MM-JJ)')),
            const SizedBox(height: 10),
            TextField(controller: finCtrl, decoration: const InputDecoration(labelText: 'Date fin (AAAA-MM-JJ)')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: envoi ? null : () async {
                  if (filiereSelectedId == null || debutCtrl.text.trim().isEmpty || finCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx2).showSnackBar(
                      const SnackBar(content: Text('⚠️ Tous les champs sont requis.'), backgroundColor: Colors.redAccent),
                    );
                    return;
                  }
                  setS(() => envoi = true);
                  final result = await ApiService.creerPeriodeEvaluation(
                    filiereId: filiereSelectedId!,
                    dateDebut: debutCtrl.text.trim(),
                    dateFin: finCtrl.text.trim(),
                  );
                  if (!mounted) return;
                  if (result['success'] == true) {
                    Navigator.pop(ctx);
                    _snack('Période ouverte — les étudiants ont été notifiés.');
                    _charger();
                  } else {
                    setS(() => envoi = false);
                    ScaffoldMessenger.of(ctx2).showSnackBar(
                      SnackBar(content: Text(result['error']?.toString() ?? 'Erreur.'), backgroundColor: Colors.redAccent),
                    );
                  }
                },
                child: envoi
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Valider'),
              ),
            ),
            const SizedBox(height: 10),
          ]),
        ),
      ),
    );
  }

  Widget _btn(String label, Color fg, Color bg, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
        child: Container(padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8),
              border: Border.all(color: fg.withValues(alpha:0.3))),
          child: Center(child: Text(label, style: TextStyle(fontSize: 12,
              fontWeight: FontWeight.w700, color: fg)))));

  void _snack(String msg) => showAppSnackBar(context, msg);
}

// ════════════════════════════════════════════════════════════════════════════
// RAPPORT — résultats agrégés par professeur, jamais l'étudiant
// ════════════════════════════════════════════════════════════════════════════
class _RapportEvaluationScreen extends StatefulWidget {
  const _RapportEvaluationScreen({required this.periodeId, required this.filiereNom});
  final String periodeId;
  final String filiereNom;

  @override
  State<_RapportEvaluationScreen> createState() => _RapportEvaluationScreenState();
}

class _RapportEvaluationScreenState extends State<_RapportEvaluationScreen> {
  bool _loading = true;
  String? _erreur;
  List<dynamic> _resultats = [];

  static const _labelsCriteres = {
    'moy_pedagogie': 'Pédagogie',
    'moy_ponctualite': 'Ponctualité',
    'moy_disponibilite': 'Disponibilité',
    'moy_clarte': 'Clarté des explications',
  };

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _erreur = null; });
    final result = await ApiService.getResultatsPeriodeEvaluation(widget.periodeId);
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        _resultats = result['data'] as List<dynamic>;
      } else {
        _erreur = result['error']?.toString() ?? 'Erreur lors du chargement.';
      }
      _loading = false;
    });
  }

  double? _num(dynamic v) => v == null ? null : double.tryParse(v.toString());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A2E),
        title: Text('Rapport — ${widget.filiereNom}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
              ? Center(child: Text(_erreur!, style: const TextStyle(color: AdminTheme.danger)))
              : _resultats.isEmpty
                  ? const Center(child: Text('Aucune réponse pour l\'instant.', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _resultats.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final r = _resultats[i] as Map<String, dynamic>;
                        final moyGlobale = _num(r['moyenne_globale']) ?? 0;
                        final nomComplet = '${r['prenoms'] ?? ''} ${r['nom'] ?? ''}'.trim();
                        final commentaires = (r['commentaires'] as List<dynamic>? ?? []);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(width: 38, height: 38,
                                decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: Center(child: Text(nomComplet.isNotEmpty ? nomComplet[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))))),
                              const SizedBox(width: 10),
                              Expanded(child: Text(nomComplet, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(moyGlobale.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AdminTheme.accent)),
                                Text('${r['nb_reponses']} réponse(s)', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                              ]),
                            ]),
                            const SizedBox(height: 12),
                            ..._labelsCriteres.entries.map((entry) {
                              final val = _num(r[entry.key]) ?? 0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(children: [
                                  SizedBox(width: 140, child: Text(entry.value, style: const TextStyle(fontSize: 12, color: Color(0xFF374151)))),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: val / 5, minHeight: 6,
                                        backgroundColor: const Color(0xFFE5E7EB),
                                        color: val >= 4 ? AdminTheme.success : val >= 3 ? AdminTheme.warning : AdminTheme.danger,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(width: 32, child: Text(val.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                                ]),
                              );
                            }),
                            if (commentaires.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Divider(),
                              const Text('Commentaires', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
                              const SizedBox(height: 6),
                              ...commentaires.map((c) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text('"$c"', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontStyle: FontStyle.italic)),
                                  )),
                            ],
                          ]),
                        );
                      },
                    ),
    );
  }
}
import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_annonces.dart' show istNiveaux;
import '../services/api_service.dart';
import '../utils/snackbar_helper.dart';

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

  NoteSession({
    required this.id, required this.moduleNom, required this.filiereNom, required this.niveau,
    required this.profNom, required this.profPrenoms, required this.dateSession,
    required this.coefficient, required this.statut, required this.notes,
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

  MoyenneEtudiant({
    required this.matricule, required this.nom, required this.prenoms,
    required this.filiereNom, required this.niveau, required this.moyenne, required this.nbNotes,
  });

  factory MoyenneEtudiant.fromJson(Map<String, dynamic> j) => MoyenneEtudiant(
        matricule: j['matricule'] ?? '',
        nom: j['nom'] ?? '',
        prenoms: j['prenoms'] ?? '',
        filiereNom: j['filiere_nom'] ?? '',
        niveau: j['niveau'] ?? '',
        moyenne: double.tryParse(j['moyenne'].toString()) ?? 0.0,
        nbNotes: int.tryParse(j['nb_notes'].toString()) ?? 0,
      );
}

// ════════════════════════════════════════════════════════════════════════════
// PAGE NOTES & MOYENNES
// ════════════════════════════════════════════════════════════════════════════
class AdminNotes extends StatefulWidget {
  const AdminNotes({super.key});
  @override State<AdminNotes> createState() => _AdminNotesState();
}

class _AdminNotesState extends State<AdminNotes> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<NoteSession> _sessions = [];
  List<MoyenneEtudiant> _moyennes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    final results = await Future.wait([
      ApiService.getSessionsNotesAdmin(),
      ApiService.getMoyennesAdmin(),
    ]);
    if (!mounted) return;
    final sessionsResult = results[0];
    final moyennesResult = results[1];
    setState(() {
      _isLoading = false;
      if (sessionsResult['success'] == true) {
        _sessions = (sessionsResult['data'] as List<dynamic>).map((j) => NoteSession.fromJson(j as Map<String, dynamic>)).toList();
      } else {
        _errorMessage = sessionsResult['error'] as String?;
      }
      if (moyennesResult['success'] == true) {
        _moyennes = (moyennesResult['data'] as List<dynamic>).map((j) => MoyenneEtudiant.fromJson(j as Map<String, dynamic>)).toList();
      }
    });
  }

  int get _nbEnAttente => _sessions.where((s) => s.statut == 'en_attente').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Column(children: [
        Container(
          color: AdminTheme.surface,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Notes & Moyennes', style: AdminTheme.headingLarge),
                Text('Gestion du flux des notes — réception, validation, envoi', style: AdminTheme.bodyMedium),
              ])),
              IconButton(onPressed: _isLoading ? null : _loadData, icon: const Icon(Icons.refresh_rounded, color: AdminTheme.textSecondary), tooltip: 'Actualiser'),
              const SizedBox(width: 8),
              _kpiChip(Icons.hourglass_top_rounded, '$_nbEnAttente en attente', AdminTheme.warning, AdminTheme.warningLight),
              const SizedBox(width: 8),
              _kpiChip(Icons.check_circle_rounded, '${_sessions.where((s) => s.statut == 'validee').length} validées', AdminTheme.success, AdminTheme.successLight),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AdminTheme.infoLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AdminTheme.info.withValues(alpha:0.3))),
              child: Row(children: [
                const Icon(Icons.security_rounded, color: AdminTheme.info, size: 16),
                const SizedBox(width: 8),
                const Expanded(child: Text(
                  '⚠️ Règle d\'or : Chaque étudiant reçoit UNIQUEMENT sa propre note. Aucun étudiant ne peut voir la note d\'un autre.',
                  style: TextStyle(fontSize: 11, color: AdminTheme.info, fontWeight: FontWeight.w600),
                )),
              ]),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabCtrl,
              labelColor: AdminTheme.primary,
              unselectedLabelColor: AdminTheme.textSecondary,
              indicatorColor: AdminTheme.primary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              isScrollable: true,
              tabs: [
                Tab(child: Row(children: [
                  const Text('Notes en attente'),
                  if (_nbEnAttente > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AdminTheme.warning, borderRadius: BorderRadius.circular(10)),
                      child: Text('$_nbEnAttente', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))),
                  ],
                ])),
                const Tab(text: 'Saisie directe'),
                const Tab(text: 'Moyennes'),
                const Tab(text: 'Historique'),
              ],
            ),
          ]),
        ),
        const Divider(height: 1, color: AdminTheme.border),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(controller: _tabCtrl, children: [
                  _tabEnAttente(),
                  _SaisieDirecte(onSaved: _loadData),
                  _tabMoyennes(),
                  _tabHistorique(),
                ]),
        ),
      ]),
    );
  }

  Widget _kpiChip(IconData icon, String label, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: fg.withValues(alpha:0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: fg, size: 14),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    ]),
  );

  // ════════════════════════════════════════════════════════════════════════
  // TAB 1 — NOTES EN ATTENTE
  // ════════════════════════════════════════════════════════════════════════
  Widget _tabEnAttente() {
    if (_errorMessage != null) return _erreur();
    final enAttente = _sessions.where((s) => s.statut == 'en_attente').toList();
    if (enAttente.isEmpty) return _vide('Aucune note en attente', 'Toutes les notes ont été traitées.');

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: enAttente.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _carteSoumission(enAttente[i]),
    );
  }

  Widget _carteSoumission(NoteSession s) {
    final notesMoy = s.notes.isEmpty ? 0.0 : s.notes.fold<double>(0, (sum, n) => sum + n.valeur) / s.notes.length;
    final notesBlam = s.notes.where((n) => n.valeur < 7).length;

    return Container(
      decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(AdminTheme.radiusCard), border: Border.all(color: AdminTheme.border), boxShadow: AdminTheme.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.grade_rounded, color: AdminTheme.primary, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.moduleNom, style: AdminTheme.headingSmall),
              const SizedBox(height: 3),
              Text('${s.profPrenoms} ${s.profNom} · ${s.filiereNom} · ${s.niveau}', style: AdminTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('Soumis le ${s.dateFormatee}', style: AdminTheme.caption),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _statusBadge(s.statut),
              if (notesBlam > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: AdminTheme.dangerLight, borderRadius: BorderRadius.circular(10)),
                  child: Text('⚠️ $notesBlam blâmable(s)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AdminTheme.danger))),
              ],
            ]),
          ]),
        ),
        const Divider(height: 1, color: AdminTheme.border),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              const Expanded(flex: 2, child: Text('Étudiant', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminTheme.textSecondary))),
              const SizedBox(width: 8),
              const Text('Matricule', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminTheme.textSecondary)),
              const SizedBox(width: 16),
              const Text('Note /20', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminTheme.textSecondary)),
            ]),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AdminTheme.border),
            ...s.notes.map((n) {
              final ok = n.valeur >= 10;
              final blam = n.valeur < 7;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Expanded(flex: 2, child: Text('${n.prenoms} ${n.nom}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AdminTheme.textPrimary))),
                  const SizedBox(width: 8),
                  Text(n.matricule, style: AdminTheme.caption.copyWith(fontFamily: 'monospace')),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: blam ? AdminTheme.dangerLight : ok ? AdminTheme.successLight : AdminTheme.warningLight, borderRadius: BorderRadius.circular(8)),
                    child: Text('${n.valeur.toStringAsFixed(1)}/20', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: blam ? AdminTheme.danger : ok ? AdminTheme.success : AdminTheme.warning)),
                  ),
                  if (blam) ...[const SizedBox(width: 6), const Icon(Icons.warning_amber_rounded, color: AdminTheme.danger, size: 14)],
                ]),
              );
            }),
            const Divider(height: 1, color: AdminTheme.border),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Moyenne classe :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AdminTheme.textPrimary)),
              const Spacer(),
              Text(notesMoy.toStringAsFixed(2), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: notesMoy >= 10 ? AdminTheme.primary : AdminTheme.danger)),
              const Text('/20', style: TextStyle(fontSize: 12, color: AdminTheme.textMuted)),
            ]),
          ]),
        ),
        const Divider(height: 1, color: AdminTheme.border),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Expanded(child: _btn('Rejeter', Icons.cancel_outlined, AdminTheme.danger, AdminTheme.dangerLight, () => _rejeter(s))),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _btn('Valider & Envoyer aux étudiants', Icons.send_rounded, AdminTheme.success, AdminTheme.successLight, () => _confirmerEnvoi(s))),
          ]),
        ),
      ]),
    );
  }

  Future<void> _rejeter(NoteSession s) async {
    final motifCtrl = TextEditingController();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.cancel_outlined, color: AdminTheme.danger),
          SizedBox(width: 10),
          Text('Rejeter la session', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Indiquez le motif du rejet pour ${s.moduleNom}. Il sera transmis au professeur.',
              style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: motifCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ex : Notes incohérentes pour plusieurs étudiants...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    final result = await ApiService.rejeterSessionNotes(s.id, motif: motifCtrl.text.trim());
    if (result['success'] == true) {
      _snack('Soumission rejetée.');
      _loadData();
    } else {
      _snack(result['error'] as String? ?? 'Erreur.', isError: true);
    }
  }

  void _confirmerEnvoi(NoteSession s) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.send_rounded, color: AdminTheme.primary),
        SizedBox(width: 10),
        Text('Confirmer l\'envoi', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Envoyer les notes de ${s.moduleNom} à ${s.notes.length} étudiant(s) ?', style: const TextStyle(fontSize: 14, color: AdminTheme.textSecondary)),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            const Icon(Icons.security_rounded, color: AdminTheme.primary, size: 16),
            const SizedBox(width: 8),
            const Expanded(child: Text('Chaque étudiant reçoit uniquement sa propre note.', style: TextStyle(fontSize: 12, color: AdminTheme.primary, fontWeight: FontWeight.w600))),
          ])),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: AdminTheme.textSecondary))),
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            final result = await ApiService.validerSessionNotes(s.id);
            if (result['success'] == true) {
              _snack('✅ Notes envoyées individuellement à ${s.notes.length} étudiant(s) !');
              _loadData();
            } else {
              _snack(result['error'] as String? ?? 'Erreur.', isError: true);
            }
          },
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text('Confirmer l\'envoi'),
          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ],
    ));
  }

  // ════════════════════════════════════════════════════════════════════════
  // TAB 3 — MOYENNES
  // ════════════════════════════════════════════════════════════════════════
  Widget _tabMoyennes() {
    if (_moyennes.isEmpty) return _vide('Aucune moyenne disponible', 'Les moyennes apparaîtront dès que des notes seront validées.');

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        color: AdminTheme.surface,
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Moyennes générales', style: AdminTheme.headingSmall),
            Text('${_moyennes.length} étudiants avec des notes validées', style: AdminTheme.bodyMedium),
          ])),
        ]),
      ),
      const Divider(height: 1, color: AdminTheme.border),
      Expanded(child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _moyennes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final e = _moyennes[i];
          final rank = i + 1;
          String medal = '';
          if (rank == 1) {
            medal = '🥇';
          } else if (rank == 2) {
            medal = '🥈';
          } else if (rank == 3) {
            medal = '🥉';
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: rank <= 3 ? AdminTheme.primaryLight.withValues(alpha:0.5) : AdminTheme.surface,
              borderRadius: BorderRadius.circular(AdminTheme.radiusCard),
              border: Border.all(color: rank <= 3 ? AdminTheme.primary.withValues(alpha:0.2) : AdminTheme.border),
              boxShadow: AdminTheme.cardShadow,
            ),
            child: Row(children: [
              SizedBox(width: 36, child: Center(child: rank <= 3
                  ? Text(medal, style: const TextStyle(fontSize: 22))
                  : Text('#$rank', style: AdminTheme.caption.copyWith(fontWeight: FontWeight.bold)))),
              const SizedBox(width: 12),
              Container(width: 42, height: 42, decoration: const BoxDecoration(color: AdminTheme.primaryLight, shape: BoxShape.circle),
                child: Center(child: Text(
                  '${e.prenoms.isNotEmpty ? e.prenoms[0] : "?"}${e.nom.isNotEmpty ? e.nom[0] : "?"}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AdminTheme.primary)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${e.prenoms} ${e.nom}', style: AdminTheme.headingSmall),
                Text('${e.filiereNom} · ${e.niveau} · ${e.nbNotes} note(s)', style: AdminTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (e.moyenne / 20).clamp(0.0, 1.0), minHeight: 5,
                    backgroundColor: AdminTheme.border,
                    color: e.moyenne >= 14 ? AdminTheme.primary : e.moyenne >= 10 ? AdminTheme.info : AdminTheme.danger,
                  ),
                ),
              ])),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(e.moyenne.toStringAsFixed(2), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: e.moyenne >= 14 ? AdminTheme.primary : e.moyenne >= 10 ? AdminTheme.info : AdminTheme.danger)),
                const Text('/20', style: TextStyle(fontSize: 11, color: AdminTheme.textMuted)),
              ]),
            ]),
          );
        },
      )),
    ]);
  }

  // ════════════════════════════════════════════════════════════════════════
  // TAB 4 — HISTORIQUE
  // ════════════════════════════════════════════════════════════════════════
  Widget _tabHistorique() {
    final validees = _sessions.where((s) => s.statut == 'validee').toList();
    if (validees.isEmpty) return _vide('Aucun historique', 'Les notes validées apparaîtront ici.');

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: validees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final s = validees[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(AdminTheme.radiusCard), border: Border.all(color: AdminTheme.border), boxShadow: AdminTheme.cardShadow),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AdminTheme.successLight, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.check_circle_rounded, color: AdminTheme.success, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.moduleNom, style: AdminTheme.headingSmall),
              Text('${s.profPrenoms} ${s.profNom} · ${s.filiereNom}', style: AdminTheme.bodyMedium),
              Text('Validé le ${s.dateFormatee} · ${s.notes.length} étudiant(s)', style: AdminTheme.caption),
            ])),
            AdminTheme.badge('Envoyée', AdminTheme.success, AdminTheme.successLight),
          ]),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  Widget _statusBadge(String statut) {
    Color fg; String label;
    switch (statut) {
      case 'validee': fg = AdminTheme.success; label = 'Validée'; break;
      case 'rejetee': fg = AdminTheme.danger; label = 'Rejetée'; break;
      default: fg = AdminTheme.warning; label = 'En attente';
    }
    return AdminTheme.badge(label, fg, fg.withValues(alpha:0.1));
  }

  Widget _btn(String label, IconData icon, Color fg, Color bg, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: fg.withValues(alpha:0.3))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: fg, size: 16),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
      ]),
    ),
  );

  Widget _vide(String titre, String sub) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 72, height: 72, decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(18)),
      child: const Icon(Icons.grade_outlined, color: AdminTheme.primary, size: 36)),
    const SizedBox(height: 16),
    Text(titre, style: AdminTheme.headingMedium),
    const SizedBox(height: 8),
    Text(sub, style: const TextStyle(fontSize: 14, color: AdminTheme.textSecondary)),
  ]));

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
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _sauvegarder,
              icon: _isSaving ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded, size: 16),
              label: const Text('Sauvegarder'),
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusButton))),
            ),
          ]),
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

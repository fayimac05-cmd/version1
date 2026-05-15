import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_etudiants.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES
// ════════════════════════════════════════════════════════════════════════════
class SoumissionNotes {
  final String id, professeur, filiere, module, niveau, dateSoumission;
  String statut; // en_attente, validee, rejetee
  final List<Map<String, dynamic>> notes; // {matricule, nom, prenoms, note}

  SoumissionNotes({
    required this.id, required this.professeur, required this.filiere,
    required this.module, required this.niveau, required this.dateSoumission,
    this.statut = 'en_attente', required this.notes,
  });
}

// ── Données mock ─────────────────────────────────────────────────────────
final List<SoumissionNotes> adminSoumissions = [
  SoumissionNotes(
    id: 'S001', professeur: 'OUÉDRAOGO Mamadou',
    filiere: 'Réseaux Informatiques et Télécom', module: 'Réseaux & Protocoles',
    niveau: 'Licence 2', dateSoumission: '29/04/2025', statut: 'en_attente',
    notes: [
      {'matricule': '24IST-O2/1851', 'nom': 'KOURAOGO', 'prenoms': 'Ibrahim', 'note': 14.5},
      {'matricule': '24IST-O2/1234', 'nom': 'TRAORÉ', 'prenoms': 'Fatimata', 'note': 17.0},
      {'matricule': '24IST-O2/1789', 'nom': 'OUÉDRAOGO', 'prenoms': 'Hamidou', 'note': 9.5},
    ],
  ),
  SoumissionNotes(
    id: 'S002', professeur: 'SAWADOGO Issa',
    filiere: 'Réseaux Informatiques et Télécom', module: 'Programmation Web',
    niveau: 'Licence 2', dateSoumission: '28/04/2025', statut: 'en_attente',
    notes: [
      {'matricule': '24IST-O2/1851', 'nom': 'KOURAOGO', 'prenoms': 'Ibrahim', 'note': 16.0},
      {'matricule': '24IST-O2/1234', 'nom': 'TRAORÉ', 'prenoms': 'Fatimata', 'note': 18.5},
      {'matricule': '24IST-O2/1789', 'nom': 'OUÉDRAOGO', 'prenoms': 'Hamidou', 'note': 11.0},
    ],
  ),
  SoumissionNotes(
    id: 'S003', professeur: 'COMPAORÉ Brahima',
    filiere: 'Électrotechnique', module: 'Électronique de Puissance',
    niveau: 'Licence 2', dateSoumission: '27/04/2025', statut: 'validee',
    notes: [
      {'matricule': '24IST-O2/1789', 'nom': 'OUÉDRAOGO', 'prenoms': 'Hamidou', 'note': 12.0},
    ],
  ),
];

// ════════════════════════════════════════════════════════════════════════════
// PAGE NOTES & MOYENNES
// ════════════════════════════════════════════════════════════════════════════
class AdminNotes extends StatefulWidget {
  const AdminNotes({super.key});
  @override State<AdminNotes> createState() => _AdminNotesState();
}

class _AdminNotesState extends State<AdminNotes>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  int get _nbEnAttente =>
      adminSoumissions.where((s) => s.statut == 'en_attente').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Column(children: [
        // ── Header ────────────────────────────────────────────────────
        Container(
          color: AdminTheme.surface,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Notes & Moyennes', style: AdminTheme.headingLarge),
                Text('Gestion du flux des notes — réception, validation, envoi',
                    style: AdminTheme.bodyMedium),
              ])),
              // KPIs rapides
              _kpiChip(Icons.hourglass_top_rounded, '$_nbEnAttente en attente',
                  AdminTheme.warning, AdminTheme.warningLight),
              const SizedBox(width: 8),
              _kpiChip(Icons.check_circle_rounded,
                  '${adminSoumissions.where((s) => s.statut == 'validee').length} validées',
                  AdminTheme.success, AdminTheme.successLight),
            ]),
            const SizedBox(height: 16),
            // Règle d'or
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AdminTheme.infoLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AdminTheme.info.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.security_rounded, color: AdminTheme.info, size: 16),
                const SizedBox(width: 8),
                const Expanded(child: Text(
                  '⚠️ Règle d\'or : Chaque étudiant reçoit UNIQUEMENT sa propre note. Aucun étudiant ne peut voir la note d\'un autre.',
                  style: TextStyle(fontSize: 11, color: AdminTheme.info,
                      fontWeight: FontWeight.w600),
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
                      decoration: BoxDecoration(color: AdminTheme.warning,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text('$_nbEnAttente', style: const TextStyle(
                          fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))),
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

        // ── Contenu ───────────────────────────────────────────────────
        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _tabEnAttente(),
          _tabSaisieDirecte(),
          _tabMoyennes(),
          _tabHistorique(),
        ])),
      ]),
    );
  }

  Widget _kpiChip(IconData icon, String label, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.3))),
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
    final enAttente = adminSoumissions.where((s) => s.statut == 'en_attente').toList();
    if (enAttente.isEmpty) return _vide('Aucune note en attente', 'Toutes les notes ont été traitées.');

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: enAttente.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _carteSoumission(enAttente[i]),
    );
  }

  Widget _carteSoumission(SoumissionNotes s) {
    final notesMoy = s.notes.isEmpty ? 0.0 :
        s.notes.fold<double>(0, (sum, n) => sum + (n['note'] as double)) / s.notes.length;
    final notesBlam = s.notes.where((n) => (n['note'] as double) < 7).length;

    return Container(
      decoration: BoxDecoration(color: AdminTheme.surface,
          borderRadius: BorderRadius.circular(AdminTheme.radiusCard),
          border: Border.all(color: AdminTheme.border),
          boxShadow: AdminTheme.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(color: AdminTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.grade_rounded, color: AdminTheme.primary, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.module, style: AdminTheme.headingSmall),
              const SizedBox(height: 3),
              Text('${s.professeur} · ${s.filiere} · ${s.niveau}',
                  style: AdminTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('Soumis le ${s.dateSoumission}', style: AdminTheme.caption),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _statusBadge(s.statut),
              if (notesBlam > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: AdminTheme.dangerLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('⚠️ $notesBlam blâmable(s)', style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, color: AdminTheme.danger))),
              ],
            ]),
          ]),
        ),

        const Divider(height: 1, color: AdminTheme.border),

        // Notes tableau
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // En-tête tableau
            Row(children: [
              const Expanded(flex: 2, child: Text('Étudiant', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AdminTheme.textSecondary))),
              const SizedBox(width: 8),
              const Text('Matricule', style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w700, color: AdminTheme.textSecondary)),
              const SizedBox(width: 16),
              const Text('Note /20', style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w700, color: AdminTheme.textSecondary)),
            ]),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AdminTheme.border),
            ...s.notes.map((n) {
              final note = n['note'] as double;
              final ok   = note >= 10;
              final blam = note < 7;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Expanded(flex: 2, child: Text(
                    '${n['prenoms']} ${n['nom']}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: AdminTheme.textPrimary))),
                  const SizedBox(width: 8),
                  Text(n['matricule'] as String, style: AdminTheme.caption.copyWith(
                      fontFamily: 'monospace')),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: blam ? AdminTheme.dangerLight
                          : ok ? AdminTheme.successLight : AdminTheme.warningLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${note.toStringAsFixed(1)}/20',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                            color: blam ? AdminTheme.danger
                                : ok ? AdminTheme.success : AdminTheme.warning)),
                  ),
                  if (blam) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.warning_amber_rounded,
                        color: AdminTheme.danger, size: 14),
                  ],
                ]),
              );
            }),
            const Divider(height: 1, color: AdminTheme.border),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Moyenne classe :', style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w700, color: AdminTheme.textPrimary)),
              const Spacer(),
              Text(notesMoy.toStringAsFixed(2), style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: notesMoy >= 10 ? AdminTheme.primary : AdminTheme.danger)),
              const Text('/20', style: TextStyle(fontSize: 12, color: AdminTheme.textMuted)),
            ]),
          ]),
        ),

        const Divider(height: 1, color: AdminTheme.border),

        // Actions
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Expanded(child: _btn('Rejeter', Icons.cancel_outlined,
                AdminTheme.danger, AdminTheme.dangerLight, () {
              setState(() => s.statut = 'rejetee');
              _snack('Soumission rejetée. Prof notifié.');
            })),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _btn('Valider & Envoyer aux étudiants',
                Icons.send_rounded, AdminTheme.success, AdminTheme.successLight, () {
              _confirmerEnvoi(s);
            })),
          ]),
        ),
      ]),
    );
  }

  void _confirmerEnvoi(SoumissionNotes s) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.send_rounded, color: AdminTheme.primary),
        SizedBox(width: 10),
        Text('Confirmer l\'envoi', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Envoyer les notes de **${s.module}** à ${s.notes.length} étudiant(s) ?',
            style: const TextStyle(fontSize: 14, color: AdminTheme.textSecondary)),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AdminTheme.primaryLight,
              borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            const Icon(Icons.security_rounded, color: AdminTheme.primary, size: 16),
            const SizedBox(width: 8),
            const Expanded(child: Text('Chaque étudiant reçoit uniquement sa propre note.',
                style: TextStyle(fontSize: 12, color: AdminTheme.primary,
                    fontWeight: FontWeight.w600))),
          ])),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: AdminTheme.textSecondary))),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            setState(() => s.statut = 'validee');
            _snack('✅ Notes envoyées individuellement à ${s.notes.length} étudiant(s) !');
          },
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text('Confirmer l\'envoi'),
          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary,
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ],
    ));
  }

  // ════════════════════════════════════════════════════════════════════════
  // TAB 2 — SAISIE DIRECTE
  // ════════════════════════════════════════════════════════════════════════
  Widget _tabSaisieDirecte() {
    return _SaisieDirecte(onSaved: () => setState(() {}));
  }

  // ════════════════════════════════════════════════════════════════════════
  // TAB 3 — MOYENNES
  // ════════════════════════════════════════════════════════════════════════
  Widget _tabMoyennes() {
    // Calcul des moyennes par étudiant
    final etudiants = adminEtudiants.where((e) => e.notes.isNotEmpty).toList();
    etudiants.sort((a, b) {
      final moyA = _calcMoy(a.notes);
      final moyB = _calcMoy(b.notes);
      return moyB.compareTo(moyA);
    });

    return Column(children: [
      // Bouton envoi groupé
      Container(
        padding: const EdgeInsets.all(16),
        color: AdminTheme.surface,
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Moyennes générales', style: AdminTheme.headingSmall),
            Text('${etudiants.length} étudiants avec des notes',
                style: AdminTheme.bodyMedium),
          ])),
          ElevatedButton.icon(
            onPressed: () => _snack('📩 Moyennes envoyées à tous les étudiants !'),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Envoyer toutes les moyennes'),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary,
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminTheme.radiusButton))),
          ),
        ]),
      ),
      const Divider(height: 1, color: AdminTheme.border),
      Expanded(child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: etudiants.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final e   = etudiants[i];
          final moy = _calcMoy(e.notes);
          final rank = i + 1;
          String medal = '';
          if (rank == 1) medal = '🥇';
          else if (rank == 2) medal = '🥈';
          else if (rank == 3) medal = '🥉';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: rank <= 3 ? AdminTheme.primaryLight.withOpacity(0.5)
                  : AdminTheme.surface,
              borderRadius: BorderRadius.circular(AdminTheme.radiusCard),
              border: Border.all(color: rank <= 3
                  ? AdminTheme.primary.withOpacity(0.2) : AdminTheme.border),
              boxShadow: AdminTheme.cardShadow,
            ),
            child: Row(children: [
              // Rang
              SizedBox(width: 36, child: Center(child: rank <= 3
                  ? Text(medal, style: const TextStyle(fontSize: 22))
                  : Text('#$rank', style: AdminTheme.caption.copyWith(
                      fontWeight: FontWeight.bold)))),
              const SizedBox(width: 12),
              // Avatar
              Container(width: 42, height: 42,
                decoration: BoxDecoration(color: AdminTheme.primaryLight,
                    shape: BoxShape.circle),
                child: Center(child: Text('${e.prenoms[0]}${e.nom[0]}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                        color: AdminTheme.primary)))),
              const SizedBox(width: 12),
              // Infos
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${e.prenoms} ${e.nom}', style: AdminTheme.headingSmall),
                Text('${e.filiere} · ${e.niveau}', style: AdminTheme.bodyMedium,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                // Barre progression
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (moy / 20).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: AdminTheme.border,
                    color: moy >= 14 ? AdminTheme.primary
                        : moy >= 10 ? AdminTheme.info : AdminTheme.danger,
                  ),
                ),
              ])),
              const SizedBox(width: 16),
              // Moyenne
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(moy.toStringAsFixed(2), style: TextStyle(fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: moy >= 14 ? AdminTheme.primary
                        : moy >= 10 ? AdminTheme.info : AdminTheme.danger)),
                const Text('/20', style: TextStyle(fontSize: 11,
                    color: AdminTheme.textMuted)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _snack('📩 Moyenne envoyée à ${e.prenoms} !'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AdminTheme.primaryLight,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.send_rounded, color: AdminTheme.primary, size: 12),
                      SizedBox(width: 4),
                      Text('Envoyer', style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w700, color: AdminTheme.primary)),
                    ]),
                  ),
                ),
              ]),
            ]),
          );
        },
      )),
    ]);
  }

  double _calcMoy(List<Map<String, dynamic>> notes) {
    if (notes.isEmpty) return 0;
    final total = notes.fold<double>(0,
        (s, n) => s + (n['note'] as double) * (n['coef'] as int));
    final coefs = notes.fold<int>(0, (s, n) => s + (n['coef'] as int));
    return total / coefs;
  }

  // ════════════════════════════════════════════════════════════════════════
  // TAB 4 — HISTORIQUE
  // ════════════════════════════════════════════════════════════════════════
  Widget _tabHistorique() {
    final validees = adminSoumissions.where((s) => s.statut == 'validee').toList();
    if (validees.isEmpty) return _vide('Aucun historique', 'Les notes validées apparaîtront ici.');

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: validees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final s = validees[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AdminTheme.surface,
              borderRadius: BorderRadius.circular(AdminTheme.radiusCard),
              border: Border.all(color: AdminTheme.border),
              boxShadow: AdminTheme.cardShadow),
          child: Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(color: AdminTheme.successLight,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.check_circle_rounded,
                  color: AdminTheme.success, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.module, style: AdminTheme.headingSmall),
              Text('${s.professeur} · ${s.filiere}', style: AdminTheme.bodyMedium),
              Text('Validé le ${s.dateSoumission} · ${s.notes.length} étudiant(s)',
                  style: AdminTheme.caption),
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
      case 'validee':  fg = AdminTheme.success; label = 'Validée'; break;
      case 'rejetee':  fg = AdminTheme.danger;  label = 'Rejetée'; break;
      default:         fg = AdminTheme.warning; label = 'En attente';
    }
    return AdminTheme.badge(label, fg, fg.withOpacity(0.1));
  }

  Widget _btn(String label, IconData icon, Color fg, Color bg,
      VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fg.withOpacity(0.3))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: fg, size: 16),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w700, color: fg)),
      ]),
    ),
  );

  Widget _vide(String titre, String sub) => Center(child: Column(
    mainAxisSize: MainAxisSize.min, children: [
    Container(width: 72, height: 72,
      decoration: BoxDecoration(color: AdminTheme.primaryLight,
          borderRadius: BorderRadius.circular(18)),
      child: const Icon(Icons.grade_outlined, color: AdminTheme.primary, size: 36)),
    const SizedBox(height: 16),
    Text(titre, style: AdminTheme.headingMedium),
    const SizedBox(height: 8),
    Text(sub, style: const TextStyle(fontSize: 14, color: AdminTheme.textSecondary)),
  ]));

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: AdminTheme.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
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
  String _filiereSelected = 'Réseaux Informatiques et Télécom';
  String _moduleSelected  = 'Base de Données';
  final Map<String, TextEditingController> _controllers = {};

  final _filieres = ['Réseaux Informatiques et Télécom', 'Électrotechnique',
      'Marketing & Communication', 'Gestion Comptable et Financière'];
  final _modules  = ['Base de Données', 'Sécurité Informatique',
      'Architecture Réseaux', 'Algorithmique Avancée'];

  List<Etudiant> get _etudiantsFiliere => adminEtudiants
      .where((e) => e.filiere == _filiereSelected && e.statut == 'actif')
      .toList();

  @override
  Widget build(BuildContext context) {
    // Init controllers
    for (final e in _etudiantsFiliere) {
      _controllers.putIfAbsent(e.matricule, () => TextEditingController());
    }

    return Column(children: [
      // Filtres
      Container(
        color: AdminTheme.surface,
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(child: _dropField('Filière', _filiereSelected, _filieres,
              (v) => setState(() => _filiereSelected = v!))),
          const SizedBox(width: 12),
          Expanded(child: _dropField('Module', _moduleSelected, _modules,
              (v) => setState(() => _moduleSelected = v!))),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _sauvegarder,
            icon: const Icon(Icons.save_rounded, size: 16),
            label: const Text('Sauvegarder'),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary,
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminTheme.radiusButton))),
          ),
        ]),
      ),
      const Divider(height: 1, color: AdminTheme.border),

      // En-tête tableau
      Container(
        color: AdminTheme.surfaceAlt,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(children: [
          const Expanded(flex: 2, child: Text('Étudiant', style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: AdminTheme.textSecondary))),
          const Text('Matricule', style: TextStyle(fontSize: 12,
              fontWeight: FontWeight.w700, color: AdminTheme.textSecondary)),
          const SizedBox(width: 60),
          SizedBox(width: 100, child: Text(_moduleSelected,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: AdminTheme.primary),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ),
      const Divider(height: 1, color: AdminTheme.border),

      // Lignes étudiants
      Expanded(child: _etudiantsFiliere.isEmpty
          ? _videFiliere()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _etudiantsFiliere.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AdminTheme.border),
              itemBuilder: (_, i) {
                final e   = _etudiantsFiliere[i];
                final ctrl = _controllers[e.matricule]!;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Expanded(flex: 2, child: Row(children: [
                      Container(width: 34, height: 34,
                        decoration: BoxDecoration(color: AdminTheme.primaryLight,
                            shape: BoxShape.circle),
                        child: Center(child: Text('${e.prenoms[0]}${e.nom[0]}',
                            style: const TextStyle(fontSize: 11,
                                fontWeight: FontWeight.bold, color: AdminTheme.primary)))),
                      const SizedBox(width: 10),
                      Expanded(child: Text('${e.prenoms} ${e.nom}',
                          style: AdminTheme.headingSmall.copyWith(fontSize: 13))),
                    ])),
                    Text(e.matricule, style: AdminTheme.caption.copyWith(
                        fontFamily: 'monospace')),
                    const SizedBox(width: 16),
                    SizedBox(width: 90, child: Container(
                      decoration: BoxDecoration(
                        color: AdminTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AdminTheme.border),
                      ),
                      child: TextField(
                        controller: ctrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                            color: AdminTheme.primary),
                        decoration: const InputDecoration(
                          hintText: '—',
                          hintStyle: TextStyle(color: AdminTheme.textMuted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                          suffixText: '/20',
                          suffixStyle: TextStyle(fontSize: 11, color: AdminTheme.textMuted),
                        ),
                      ),
                    )),
                  ]),
                );
              },
            )),
    ]);
  }

  Widget _dropField(String hint, String value, List<String> items,
      ValueChanged<String?> onChanged) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: AdminTheme.surface,
            borderRadius: BorderRadius.circular(AdminTheme.radiusButton),
            border: Border.all(color: AdminTheme.border)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: value, isExpanded: true,
          style: AdminTheme.bodyLarge,
          items: items.map((v) => DropdownMenuItem(value: v,
              child: Text(v, style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        )),
      );

  Widget _videFiliere() => Center(child: Text(
      'Aucun étudiant actif dans cette filière.',
      style: AdminTheme.bodyMedium));

  void _sauvegarder() {
    int count = 0;
    for (final e in _etudiantsFiliere) {
      final ctrl = _controllers[e.matricule];
      if (ctrl != null && ctrl.text.isNotEmpty) {
        final val = double.tryParse(ctrl.text.replaceAll(',', '.'));
        if (val != null && val >= 0 && val <= 20) count++;
      }
    }
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aucune note saisie.'),
        backgroundColor: AdminTheme.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    widget.onSaved();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ $count note(s) sauvegardée(s) pour $_moduleSelected'),
      backgroundColor: AdminTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

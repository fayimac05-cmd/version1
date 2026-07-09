// ============================================================
// admin_secondaire.dart — Gestion Collège & Lycée (ensemble)
// Besoins couverts :
//   - Classes de la 6e à la Tle (cycle Collège / Lycée, séries)
//   - Élèves du secondaire
//   - Enseignants par matière
//   - Trimestres : saisie, conseils de classe, publication bulletins
// ============================================================

import 'package:flutter/material.dart';
import 'admin_theme.dart';
import 'admin_widgets.dart';

class AdminSecondaire extends StatefulWidget {
  const AdminSecondaire({super.key});

  @override
  State<AdminSecondaire> createState() => _AdminSecondaireState();
}

class _AdminSecondaireState extends State<AdminSecondaire> {
  int _tab = 0; // 0 Classes, 1 Élèves, 2 Enseignants, 3 Trimestres
  String _cycle = 'Tous'; // Tous | Collège | Lycée
  final _searchCtrl = TextEditingController();
  String _query = '';

  // ── Données (mock — à connecter à l'API) ────────────────────────────────
  final List<Map<String, dynamic>> _classes = [
    {'nom': '6e A', 'cycle': 'Collège', 'niveau': '6e', 'effectif': 52, 'profPrincipal': 'M. Ouédraogo Karim', 'salle': 'B1'},
    {'nom': '5e B', 'cycle': 'Collège', 'niveau': '5e', 'effectif': 48, 'profPrincipal': 'Mme Kaboré Alima', 'salle': 'B2'},
    {'nom': '4e A', 'cycle': 'Collège', 'niveau': '4e', 'effectif': 45, 'profPrincipal': 'M. Sawadogo Issa', 'salle': 'B3'},
    {'nom': '3e A', 'cycle': 'Collège', 'niveau': '3e', 'effectif': 50, 'profPrincipal': 'Mme Zongo Awa', 'salle': 'B4'},
    {'nom': '2nde C', 'cycle': 'Lycée', 'niveau': '2nde', 'effectif': 42, 'profPrincipal': 'M. Traoré Adama', 'salle': 'C1'},
    {'nom': '1ère D', 'cycle': 'Lycée', 'niveau': '1ère', 'effectif': 38, 'profPrincipal': 'Mme Compaoré Mariam', 'salle': 'C2'},
    {'nom': 'Tle D', 'cycle': 'Lycée', 'niveau': 'Tle', 'effectif': 35, 'profPrincipal': 'M. Nikiéma Paul', 'salle': 'C3'},
  ];

  final List<Map<String, dynamic>> _eleves = [
    {'nom': 'OUÉDRAOGO Fatimata', 'classe': '3e A', 'cycle': 'Collège', 'statut': 'Inscrit'},
    {'nom': 'KABORÉ Abdoul', 'classe': '6e A', 'cycle': 'Collège', 'statut': 'Inscrit'},
    {'nom': 'SAWADOGO Aïcha', 'classe': 'Tle D', 'cycle': 'Lycée', 'statut': 'Inscrit'},
    {'nom': 'ZONGO Boureima', 'classe': '2nde C', 'cycle': 'Lycée', 'statut': 'En attente'},
    {'nom': 'TRAORÉ Salif', 'classe': '1ère D', 'cycle': 'Lycée', 'statut': 'Inscrit'},
    {'nom': 'COMPAORÉ Rasmata', 'classe': '5e B', 'cycle': 'Collège', 'statut': 'Inscrit'},
  ];

  final List<Map<String, dynamic>> _enseignants = [
    {'nom': 'M. Ouédraogo Karim', 'matiere': 'Mathématiques', 'classes': '6e A, 3e A, Tle D', 'cycle': 'Collège & Lycée'},
    {'nom': 'Mme Kaboré Alima', 'matiere': 'Français', 'classes': '5e B, 4e A', 'cycle': 'Collège'},
    {'nom': 'M. Traoré Adama', 'matiere': 'Physique-Chimie', 'classes': '2nde C, 1ère D, Tle D', 'cycle': 'Lycée'},
    {'nom': 'Mme Zongo Awa', 'matiere': 'Histoire-Géographie', 'classes': '3e A, 2nde C', 'cycle': 'Collège & Lycée'},
    {'nom': 'M. Nikiéma Paul', 'matiere': 'SVT', 'classes': '1ère D, Tle D', 'cycle': 'Lycée'},
  ];

  final List<Map<String, dynamic>> _trimestres = [
    {'libelle': 'Trimestre 1', 'periode': 'Oct. — Déc. 2025', 'statut': 'Publié', 'conseil': 'Tenu le 18/12/2025'},
    {'libelle': 'Trimestre 2', 'periode': 'Janv. — Mars 2026', 'statut': 'Publié', 'conseil': 'Tenu le 27/03/2026'},
    {'libelle': 'Trimestre 3', 'periode': 'Avr. — Juin 2026', 'statut': 'Saisie en cours', 'conseil': 'Prévu le 26/06/2026'},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int get _totalEleves =>
      _classes.fold(0, (s, c) => s + (c['effectif'] as int));

  bool _matchCycle(String cycle) =>
      _cycle == 'Tous' || cycle.contains(_cycle);

  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminTheme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Collège & Lycée',
            subtitle:
                'Gestion du secondaire — classes, élèves, enseignants et trimestres',
            trailing: AdminAddButton(
              label: 'Nouvelle classe',
              onTap: _dialogNouvelleClasse,
            ),
          ),
          // ── KPIs ──────────────────────────────────────────────────────
          Container(
            color: AdminTheme.surface,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  AdminKpiChip(
                    icon: Icons.school_rounded,
                    label: '$_totalEleves élèves',
                    foreground: AdminTheme.primary,
                    background: AdminTheme.primaryLight,
                  ),
                  const SizedBox(width: 8),
                  AdminKpiChip(
                    icon: Icons.meeting_room_rounded,
                    label: '${_classes.length} classes',
                    foreground: const Color(0xFF7C3AED),
                    background: const Color(0xFFF5F3FF),
                  ),
                  const SizedBox(width: 8),
                  AdminKpiChip(
                    icon: Icons.supervisor_account_rounded,
                    label: '${_enseignants.length} enseignants',
                    foreground: const Color(0xFF0891B2),
                    background: const Color(0xFFECFEFF),
                  ),
                  const SizedBox(width: 8),
                  const AdminKpiChip(
                    icon: Icons.emoji_events_rounded,
                    label: '82 % réussite T2',
                    foreground: Color(0xFF15803D),
                    background: Color(0xFFF0FDF4),
                  ),
                ],
              ),
            ),
          ),
          // ── Onglets + filtre cycle ────────────────────────────────────
          Container(
            color: AdminTheme.surface,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _tabChip(0, 'Classes', Icons.meeting_room_outlined),
                        const SizedBox(width: 8),
                        _tabChip(1, 'Élèves', Icons.school_outlined),
                        const SizedBox(width: 8),
                        _tabChip(2, 'Enseignants',
                            Icons.supervisor_account_outlined),
                        const SizedBox(width: 8),
                        _tabChip(3, 'Trimestres', Icons.task_outlined),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Filtre Collège / Lycée
                for (final c in const ['Tous', 'Collège', 'Lycée']) ...[
                  AdminFilterChip(
                    label: c,
                    active: _cycle == c,
                    onTap: () => setState(() => _cycle = c),
                  ),
                  if (c != 'Lycée') const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          adminDivider,
          Expanded(child: _buildTab()),
        ],
      ),
    );
  }

  Widget _tabChip(int index, String label, IconData icon) {
    final active = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AdminTheme.primary : AdminTheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? AdminTheme.primary : AdminTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 15,
                color: active ? Colors.white : AdminTheme.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color:
                        active ? Colors.white : AdminTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildTab() {
    switch (_tab) {
      case 0:
        return _buildClasses();
      case 1:
        return _buildEleves();
      case 2:
        return _buildEnseignants();
      default:
        return _buildTrimestres();
    }
  }

  // ── Onglet Classes ───────────────────────────────────────────────────
  Widget _buildClasses() {
    final list =
        _classes.where((c) => _matchCycle(c['cycle'] as String)).toList();
    if (list.isEmpty) {
      return const AdminEmptyState(
          icon: Icons.meeting_room_outlined,
          message: 'Aucune classe pour ce cycle.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final c = list[i];
        final lycee = c['cycle'] == 'Lycée';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AdminTheme.cardDecoration,
          child: Row(
            children: [
              AdminIconBox(
                  icon: lycee
                      ? Icons.account_balance_rounded
                      : Icons.apartment_rounded,
                  alt: lycee),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(c['nom'],
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AdminTheme.textPrimary)),
                        const SizedBox(width: 8),
                        AdminTheme.badge(
                          c['cycle'],
                          lycee
                              ? const Color(0xFFB7950B)
                              : AdminTheme.primary,
                          lycee
                              ? AdminTheme.accentLight
                              : AdminTheme.primaryLight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prof principal : ${c['profPrincipal']}  ·  Salle ${c['salle']}',
                      style: const TextStyle(
                          fontSize: 12, color: AdminTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${c['effectif']}',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AdminTheme.primary)),
                  const Text('élèves',
                      style: TextStyle(
                          fontSize: 11, color: AdminTheme.textMuted)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Onglet Élèves ────────────────────────────────────────────────────
  Widget _buildEleves() {
    final list = _eleves
        .where((e) =>
            _matchCycle(e['cycle'] as String) &&
            (e['nom'] as String).toLowerCase().contains(_query))
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: AdminSearchBar(
            controller: _searchCtrl,
            hintText: 'Rechercher un élève...',
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const AdminEmptyState(message: 'Aucun élève trouvé.')
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final e = list[i];
                    final inscrit = e['statut'] == 'Inscrit';
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: AdminTheme.cardDecoration,
                      child: Row(
                        children: [
                          const AdminIconBox(icon: Icons.person_rounded),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e['nom'],
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AdminTheme.textPrimary)),
                                const SizedBox(height: 2),
                                Text('${e['classe']} — ${e['cycle']}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AdminTheme.textSecondary)),
                              ],
                            ),
                          ),
                          AdminTheme.badge(
                            e['statut'],
                            inscrit
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB7950B),
                            inscrit
                                ? const Color(0xFFF0FDF4)
                                : AdminTheme.accentLight,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Onglet Enseignants ───────────────────────────────────────────────
  Widget _buildEnseignants() {
    final list = _enseignants
        .where((e) => _matchCycle(e['cycle'] as String))
        .toList();
    if (list.isEmpty) {
      return const AdminEmptyState(
          icon: Icons.supervisor_account_outlined,
          message: 'Aucun enseignant pour ce cycle.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final e = list[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: AdminTheme.cardDecoration,
          child: Row(
            children: [
              const AdminIconBox(icon: Icons.co_present_rounded, alt: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e['nom'],
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AdminTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Classes : ${e['classes']}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AdminTheme.textSecondary)),
                  ],
                ),
              ),
              AdminTheme.badge(e['matiere'], AdminTheme.primary,
                  AdminTheme.primaryLight),
            ],
          ),
        );
      },
    );
  }

  // ── Onglet Trimestres ────────────────────────────────────────────────
  Widget _buildTrimestres() {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _trimestres.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final t = _trimestres[i];
        final publie = t['statut'] == 'Publié';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AdminTheme.cardDecoration,
          child: Row(
            children: [
              AdminIconBox(
                  icon: publie
                      ? Icons.task_alt_rounded
                      : Icons.pending_actions_rounded,
                  alt: !publie),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${t['libelle']} — ${t['periode']}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AdminTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Conseil de classe : ${t['conseil']}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AdminTheme.textSecondary)),
                  ],
                ),
              ),
              if (publie)
                AdminTheme.badge('Bulletins publiés',
                    const Color(0xFF15803D), const Color(0xFFF0FDF4))
              else
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => t['statut'] = 'Publié');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Bulletins du ${t['libelle']} publiés aux parents et élèves.')),
                    );
                  },
                  style: AdminTheme.primaryButtonStyle,
                  icon: const Icon(Icons.send_rounded, size: 15),
                  label: const Text('Publier les bulletins'),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Dialog : nouvelle classe ─────────────────────────────────────────
  void _dialogNouvelleClasse() {
    final nomCtrl = TextEditingController();
    final profCtrl = TextEditingController();
    final salleCtrl = TextEditingController();
    String cycle = 'Collège';
    String niveau = '6e';
    const niveauxCollege = ['6e', '5e', '4e', '3e'];
    const niveauxLycee = ['2nde', '1ère', 'Tle'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) {
          final niveaux =
              cycle == 'Collège' ? niveauxCollege : niveauxLycee;
          if (!niveaux.contains(niveau)) niveau = niveaux.first;
          return AlertDialog(
            title: const Text('Nouvelle classe'),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: cycle,
                          decoration:
                              const InputDecoration(labelText: 'Cycle'),
                          items: const [
                            DropdownMenuItem(
                                value: 'Collège', child: Text('Collège')),
                            DropdownMenuItem(
                                value: 'Lycée', child: Text('Lycée')),
                          ],
                          onChanged: (v) => setSt(() => cycle = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: niveau,
                          decoration:
                              const InputDecoration(labelText: 'Niveau'),
                          items: niveaux
                              .map((n) => DropdownMenuItem(
                                  value: n, child: Text(n)))
                              .toList(),
                          onChanged: (v) => setSt(() => niveau = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nomCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nom de la classe (ex : 6e A, Tle C)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: profCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Professeur principal'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: salleCtrl,
                    decoration: const InputDecoration(labelText: 'Salle'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: AdminTheme.primaryButtonStyle,
                onPressed: () {
                  if (nomCtrl.text.trim().isEmpty) return;
                  setState(() {
                    _classes.add({
                      'nom': nomCtrl.text.trim(),
                      'cycle': cycle,
                      'niveau': niveau,
                      'effectif': 0,
                      'profPrincipal': profCtrl.text.trim().isEmpty
                          ? 'À affecter'
                          : profCtrl.text.trim(),
                      'salle': salleCtrl.text.trim().isEmpty
                          ? '—'
                          : salleCtrl.text.trim(),
                    });
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Classe ${nomCtrl.text.trim()} ($cycle) créée.')),
                  );
                },
                child: const Text('Créer la classe'),
              ),
            ],
          );
        },
      ),
    );
  }
}

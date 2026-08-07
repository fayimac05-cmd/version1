// ============================================================
// admin_primaire.dart — Gestion de la section Primaire
// Besoins couverts :
//   - Classes du CP1 au CM2 (un maître titulaire par classe)
//   - Écoliers (âge, contact parent, cantine)
//   - Maîtres & maîtresses titulaires
//   - Cantine : inscriptions et menu de la semaine
// ============================================================

import 'package:flutter/material.dart';
import 'admin_theme.dart';
import 'admin_widgets.dart';

class AdminPrimaire extends StatefulWidget {
  const AdminPrimaire({super.key});

  @override
  State<AdminPrimaire> createState() => _AdminPrimaireState();
}

class _AdminPrimaireState extends State<AdminPrimaire> {
  int _tab = 0; // 0 Classes, 1 Écoliers, 2 Maîtres, 3 Cantine
  final _searchCtrl = TextEditingController();
  String _query = '';

  // ── Données (mock — à connecter à l'API) ────────────────────────────────
  final List<Map<String, dynamic>> _classes = [
    {'nom': 'CP1 A', 'maitre': 'Mme Ilboudo Salamata', 'effectif': 45, 'salle': 'P1'},
    {'nom': 'CP2 A', 'maitre': 'Mme Ouattara Rosalie', 'effectif': 43, 'salle': 'P2'},
    {'nom': 'CE1 A', 'maitre': 'M. Bationo Éric', 'effectif': 40, 'salle': 'P3'},
    {'nom': 'CE2 A', 'maitre': 'Mme Sana Joséphine', 'effectif': 42, 'salle': 'P4'},
    {'nom': 'CM1 A', 'maitre': 'M. Kafando Daniel', 'effectif': 38, 'salle': 'P5'},
    {'nom': 'CM2 A', 'maitre': 'Mme Nana Bernadette', 'effectif': 41, 'salle': 'P6'},
  ];

  final List<Map<String, dynamic>> _ecoliers = [
    {'nom': 'DIALLO Aminata', 'classe': 'CP1 A', 'age': 6, 'parent': '+226 70 11 22 33', 'cantine': true},
    {'nom': 'OUÉDRAOGO Moussa', 'classe': 'CE1 A', 'age': 8, 'parent': '+226 76 44 55 66', 'cantine': true},
    {'nom': 'KABORÉ Alizèta', 'classe': 'CM2 A', 'age': 11, 'parent': '+226 78 77 88 99', 'cantine': false},
    {'nom': 'SAWADOGO Yacouba', 'classe': 'CP2 A', 'age': 7, 'parent': '+226 70 12 34 56', 'cantine': true},
    {'nom': 'ZONGO Mariam', 'classe': 'CM1 A', 'age': 10, 'parent': '+226 71 98 76 54', 'cantine': false},
    {'nom': 'TRAORÉ Inoussa', 'classe': 'CE2 A', 'age': 9, 'parent': '+226 79 55 44 33', 'cantine': true},
  ];

  final List<Map<String, String>> _menuCantine = [
    {'jour': 'Lundi', 'plat': 'Riz sauce tomate + poisson'},
    {'jour': 'Mardi', 'plat': 'Tô sauce gombo + viande'},
    {'jour': 'Mercredi', 'plat': 'Haricots + galettes'},
    {'jour': 'Jeudi', 'plat': 'Riz gras + poulet'},
    {'jour': 'Vendredi', 'plat': 'Spaghetti + œufs'},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int get _totalEcoliers =>
      _classes.fold(0, (s, c) => s + (c['effectif'] as int));

  int get _inscritsCantine =>
      _ecoliers.where((e) => e['cantine'] as bool).length;

  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminTheme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Primaire',
            subtitle:
                'Gestion du primaire — classes CP1 à CM2, écoliers, maîtres et cantine',
            trailing: AdminAddButton(
              label: 'Nouvel écolier',
              onTap: _dialogNouvelEcolier,
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
                    icon: Icons.child_care_rounded,
                    label: '$_totalEcoliers écoliers',
                    foreground: AdminTheme.primary,
                    background: AdminTheme.primaryLight,
                  ),
                  const SizedBox(width: 8),
                  AdminKpiChip(
                    icon: Icons.meeting_room_rounded,
                    label: '${_classes.length} classes (CP1 → CM2)',
                    foreground: const Color(0xFF7C3AED),
                    background: const Color(0xFFF5F3FF),
                  ),
                  const SizedBox(width: 8),
                  AdminKpiChip(
                    icon: Icons.co_present_rounded,
                    label: '${_classes.length} maîtres titulaires',
                    foreground: const Color(0xFF0891B2),
                    background: const Color(0xFFECFEFF),
                  ),
                  const SizedBox(width: 8),
                  AdminKpiChip(
                    icon: Icons.restaurant_rounded,
                    label: '$_inscritsCantine inscrits cantine',
                    foreground: const Color(0xFF15803D),
                    background: const Color(0xFFF0FDF4),
                  ),
                ],
              ),
            ),
          ),
          // ── Onglets ───────────────────────────────────────────────────
          Container(
            color: AdminTheme.surface,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _tabChip(0, 'Classes', Icons.meeting_room_outlined),
                  const SizedBox(width: 8),
                  _tabChip(1, 'Écoliers', Icons.child_care_outlined),
                  const SizedBox(width: 8),
                  _tabChip(2, 'Maîtres & Maîtresses',
                      Icons.co_present_outlined),
                  const SizedBox(width: 8),
                  _tabChip(3, 'Cantine', Icons.restaurant_outlined),
                ],
              ),
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
        return _buildEcoliers();
      case 2:
        return _buildMaitres();
      default:
        return _buildCantine();
    }
  }

  // ── Onglet Classes ───────────────────────────────────────────────────
  Widget _buildClasses() {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _classes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final c = _classes[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AdminTheme.cardDecoration,
          child: Row(
            children: [
              const AdminIconBox(icon: Icons.auto_stories_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['nom'],
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AdminTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      'Titulaire : ${c['maitre']}  ·  Salle ${c['salle']}',
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
                  const Text('écoliers',
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

  // ── Onglet Écoliers ──────────────────────────────────────────────────
  Widget _buildEcoliers() {
    final list = _ecoliers
        .where((e) => (e['nom'] as String).toLowerCase().contains(_query))
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: AdminSearchBar(
            controller: _searchCtrl,
            hintText: 'Rechercher un écolier...',
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const AdminEmptyState(message: 'Aucun écolier trouvé.')
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final e = list[i];
                    final cantine = e['cantine'] as bool;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: AdminTheme.cardDecoration,
                      child: Row(
                        children: [
                          const AdminIconBox(icon: Icons.face_rounded),
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
                                Text(
                                  '${e['classe']} · ${e['age']} ans · Parent : ${e['parent']}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AdminTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          AdminTheme.badge(
                            cantine ? 'Cantine' : 'Sans cantine',
                            cantine
                                ? const Color(0xFF15803D)
                                : AdminTheme.textMuted,
                            cantine
                                ? const Color(0xFFF0FDF4)
                                : AdminTheme.surfaceAlt,
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

  // ── Onglet Maîtres & Maîtresses ──────────────────────────────────────
  Widget _buildMaitres() {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _classes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final c = _classes[i];
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
                    Text(c['maitre'],
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AdminTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text('${c['effectif']} écoliers · Salle ${c['salle']}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AdminTheme.textSecondary)),
                  ],
                ),
              ),
              AdminTheme.badge('Titulaire ${c['nom']}', AdminTheme.primary,
                  AdminTheme.primaryLight),
            ],
          ),
        );
      },
    );
  }

  // ── Onglet Cantine ───────────────────────────────────────────────────
  Widget _buildCantine() {
    final inscrits = _ecoliers.where((e) => e['cantine'] as bool).toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Menu de la semaine
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AdminTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  AdminIconBox(icon: Icons.restaurant_menu_rounded),
                  SizedBox(width: 12),
                  Text('Menu de la semaine',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AdminTheme.textPrimary)),
                ],
              ),
              const SizedBox(height: 14),
              for (final m in _menuCantine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(m['jour']!,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AdminTheme.primary)),
                      ),
                      Expanded(
                        child: Text(m['plat']!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AdminTheme.textSecondary)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Écoliers inscrits à la cantine (${inscrits.length})',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AdminTheme.textPrimary)),
        const SizedBox(height: 10),
        for (final e in inscrits)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: AdminTheme.cardDecoration,
            child: Row(
              children: [
                const AdminIconBox(icon: Icons.restaurant_rounded),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('${e['nom']} — ${e['classe']}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AdminTheme.textPrimary)),
                ),
                AdminTheme.badge('Abonné', const Color(0xFF15803D),
                    const Color(0xFFF0FDF4)),
              ],
            ),
          ),
      ],
    );
  }

  // ── Dialog : nouvel écolier ──────────────────────────────────────────
  void _dialogNouvelEcolier() {
    final nomCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final parentCtrl = TextEditingController();
    String classe = _classes.first['nom'] as String;
    bool cantine = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Nouvel écolier'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nom et prénom'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: classe,
                        decoration:
                            const InputDecoration(labelText: 'Classe'),
                        items: _classes
                            .map((c) => DropdownMenuItem(
                                value: c['nom'] as String,
                                child: Text(c['nom'] as String)))
                            .toList(),
                        onChanged: (v) => setSt(() => classe = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Âge'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: parentCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Téléphone du parent'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: cantine,
                  onChanged: (v) => setSt(() => cantine = v),
                  title: const Text('Inscrire à la cantine',
                      style: TextStyle(fontSize: 14)),
                  contentPadding: EdgeInsets.zero,
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
                  _ecoliers.add({
                    'nom': nomCtrl.text.trim(),
                    'classe': classe,
                    'age': int.tryParse(ageCtrl.text) ?? 6,
                    'parent': parentCtrl.text.trim().isEmpty
                        ? '—'
                        : parentCtrl.text.trim(),
                    'cantine': cantine,
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Écolier ${nomCtrl.text.trim()} inscrit en $classe.')),
                );
              },
              child: const Text('Inscrire'),
            ),
          ],
        ),
      ),
    );
  }
}

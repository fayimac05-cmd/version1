import 'package:flutter/material.dart';
import '../services/professor_service.dart';
import '../theme/app_palette.dart';
import 'appel_qr_screen.dart';

class AppelTab extends StatefulWidget {
  const AppelTab({super.key, this.initialClasse});

  /// Classe présélectionnée depuis l'onglet "Mes Classes".
  final Map<String, dynamic>? initialClasse;

  @override
  State<AppelTab> createState() => _AppelTabState();
}

class _AppelTabState extends State<AppelTab> {
  List<dynamic> _classes = [];
  List<dynamic> _modules = [];
  List<dynamic> _students = [];
  List<dynamic> _historique = [];
  bool _loading = true;
  bool _loadingStudents = false;
  bool _saving = false;
  String _searchQuery = '';

  List<dynamic> get _historiqueFiltre {
    if (_searchQuery.isEmpty) return _historique;
    final q = _searchQuery.toLowerCase();
    return _historique.where((a) {
      final mod = (a['module_nom'] ?? '').toString().toLowerCase();
      final fil = (a['filiere_nom'] ?? '').toString().toLowerCase();
      final date = (a['date_appel'] ?? '').toString().toLowerCase();
      return mod.contains(q) || fil.contains(q) || date.contains(q);
    }).toList();
  }

  String? _classeId;
  String? _classeNom;
  String? _niveau;
  String? _moduleId;

  // matricule -> statut (present/absent/retard)
  final Map<String, String> _statuts = {};

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    final classesResult = await ProfessorService.getClasses();
    final modulesResult = await ProfessorService.getModules();
    final histResult = await ProfessorService.getAppels();
    if (!mounted) return;
    setState(() {
      _classes = classesResult['success'] == true ? classesResult['data'] as List<dynamic> : [];
      _modules = modulesResult['success'] == true ? modulesResult['data'] as List<dynamic> : [];
      _historique = histResult['success'] == true ? histResult['data'] as List<dynamic> : [];
      _loading = false;
    });
    _appliquerPreselection();
  }

  bool _preselectionAppliquee = false;

  void _appliquerPreselection() {
    final init = widget.initialClasse;
    if (init == null || _classeId != null || _preselectionAppliquee) return;
    _preselectionAppliquee = true;
    final matches = _classes.where((c) => c['id'].toString() == init['id'].toString());
    if (matches.isEmpty) return;
    final c = matches.first;
    setState(() {
      _classeId = c['id'].toString();
      _classeNom = c['nom'];
      _niveau = c['niveau'];
    });
    _chargerEtudiants();
  }

  Future<void> _chargerEtudiants() async {
    if (_classeId == null) return;
    setState(() {
      _loadingStudents = true;
      _students = [];
      _statuts.clear();
    });
    final result = await ProfessorService.getStudentsByFiliere(
      int.parse(_classeId!),
      niveau: _niveau,
    );
    if (!mounted) return;
    final data = result['success'] == true ? result['data'] as List<dynamic> : [];
    for (final s in data) {
      _statuts[s['matricule']] = 'present';
    }
    setState(() {
      _students = data;
      _loadingStudents = false;
    });
  }

  Future<void> _enregistrerAppel() async {
    if (_classeId == null || _moduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une classe et un module.')));
      return;
    }
    setState(() => _saving = true);

    final presences = _students
        .map((s) => {'matricule': s['matricule'], 'statut': _statuts[s['matricule']] ?? 'present'})
        .toList();

    final res = await ProfessorService.createAppel({
      'filiere_id': int.parse(_classeId!),
      'filiere_nom': _classeNom,
      'niveau': _niveau,
      'module_id': int.parse(_moduleId!),
      'presences': presences,
    });

    if (!mounted) return;
    setState(() => _saving = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appel enregistré avec succès.'), backgroundColor: Color(0xFF10B981)));
      setState(() {
        _students = [];
        _classeId = null;
        _moduleId = null;
      });
      _chargerDonnees();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error'] ?? 'Erreur lors de l\'enregistrement.'), backgroundColor: Colors.red));
    }
  }

  Future<void> _showAppelDetail(dynamic appel) async {
    final modified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AppelDetailSheet(appelId: appel['id'].toString()),
    );
    if (modified == true) {
      _chargerDonnees();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0A3D91), Color(0xFF1565C0)]),
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        ),
        child: SafeArea(bottom: false, child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Faire l\'appel', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            Text('${_historique.length} appel(s) enregistré(s)', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75))),
          ]),
        )),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _selectionCard(),
                  if (_loadingStudents) const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
                  if (!_loadingStudents && _classeId != null && _students.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
                      child: const Row(children: [
                        Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                        SizedBox(width: 10),
                        Expanded(child: Text(
                          'Aucun étudiant inscrit dans cette classe. Vérifiez que les étudiants ont bien une filière affectée (Admin → Étudiants).',
                          style: TextStyle(fontSize: 12, color: Color(0xFF92400E)))),
                      ]),
                    ),
                  if (!_loadingStudents && _students.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    ..._students.map((s) => _EtudiantPresenceRow(
                          etudiant: s,
                          statut: _statuts[s['matricule']] ?? 'present',
                          onChanged: (v) => setState(() => _statuts[s['matricule']] = v),
                        )),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.fact_check_rounded),
                        label: Text(_saving ? 'Enregistrement...' : 'Enregistrer l\'appel',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _saving ? null : _enregistrerAppel,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_historique.isNotEmpty) ...[
                    Align(alignment: Alignment.centerLeft,
                        child: Text('Historique des appels',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Rechercher par module, filière, ou date...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._historiqueFiltre.map((a) => _AppelHistoriqueCard(appel: a, onTap: () => _showAppelDetail(a))),
                  ],
                ]),
              ),
      ),
    ]);
  }

  Widget _selectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(children: [
        DropdownButtonFormField<String>(
          value: _classeId != null && _niveau != null ? '${_classeId}_$_niveau' : null,
          hint: const Text('Sélectionner une classe'),
          decoration: InputDecoration(
            labelText: 'Classe / Filière',
            prefixIcon: const Icon(Icons.groups_outlined, color: AppPalette.blue),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: _classes.map<DropdownMenuItem<String>>((c) => DropdownMenuItem(
              value: '${c['id']}_${c['niveau']}', child: Text('${c['nom']} - ${c['niveau']}', overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) {
            final c = _classes.firstWhere((x) => '${x['id']}_${x['niveau']}' == v);
            setState(() {
              _classeId = c['id'].toString();
              _classeNom = c['nom'];
              _niveau = c['niveau'];
            });
            _chargerEtudiants();
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _moduleId,
          hint: const Text('Sélectionner un module'),
          decoration: InputDecoration(
            labelText: 'Module',
            prefixIcon: const Icon(Icons.menu_book_outlined, color: AppPalette.blue),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: _modules.map<DropdownMenuItem<String>>((m) => DropdownMenuItem(
              value: m['id'].toString(), child: Text('${m['nom']}', overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => setState(() => _moduleId = v),
        ),
        if (_classeId != null && _moduleId != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text('Appel par QR code',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPalette.blue,
                side: const BorderSide(color: AppPalette.blue, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final module = _modules.firstWhere(
                    (m) => m['id'].toString() == _moduleId,
                    orElse: () => {'nom': ''});
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AppelQrScreen(
                    filiereId: int.parse(_classeId!),
                    filiereNom: _classeNom ?? '',
                    niveau: _niveau,
                    moduleId: int.parse(_moduleId!),
                    moduleNom: module['nom'] ?? '',
                  ),
                )).then((_) => _chargerDonnees());
              },
            ),
          ),
        ],
      ]),
    );
  }
}

class _EtudiantPresenceRow extends StatelessWidget {
  const _EtudiantPresenceRow({required this.etudiant, required this.statut, required this.onChanged});
  final dynamic etudiant;
  final String statut;
  final ValueChanged<String> onChanged;

  static const _options = [
    {'value': 'present', 'label': 'Présent', 'color': Color(0xFF10B981)},
    {'value': 'absent', 'label': 'Absent', 'color': Color(0xFFEF4444)},
    {'value': 'retard', 'label': 'Retard', 'color': Color(0xFFF59E0B)},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 16, backgroundColor: AppPalette.lightBlue,
              child: Text('${etudiant['prenoms']}'.isNotEmpty ? '${etudiant['prenoms']}'[0] : '?',
                  style: const TextStyle(color: AppPalette.blue, fontWeight: FontWeight.w700, fontSize: 12))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${etudiant['prenoms']} ${etudiant['nom']}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
            Row(children: [
              Text('${etudiant['matricule']}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              if ((etudiant['total_absences'] ?? 0) > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFFECACA))),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, size: 10, color: Color(0xFFEF4444)),
                    const SizedBox(width: 2),
                    Text('${etudiant['total_absences']} absence${(etudiant['total_absences'] ?? 0) > 1 ? 's' : ''}', 
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                  ]),
                ),
              ],
            ]),
          ])),
        ]),
        const SizedBox(height: 8),
        Row(children: _options.map((o) {
          final isActive = statut == o['value'];
          final color = o['color'] as Color;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o['value'] as String),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? color : color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(o['label'] as String,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : color)),
              ),
            ),
          );
        }).toList()),
      ]),
    );
  }
}

class _AppelHistoriqueCard extends StatelessWidget {
  const _AppelHistoriqueCard({required this.appel, required this.onTap});
  final dynamic appel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = (appel['date_appel'] ?? '').toString().split('T').first;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.fact_check_rounded, color: Color(0xFF0EA5E9), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${appel['module_nom'] ?? ''} · ${appel['filiere_nom'] ?? ''} - ${appel['niveau'] ?? ''}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ])),
          _pill('${appel['nb_presents'] ?? 0}P', const Color(0xFF10B981)),
          const SizedBox(width: 4),
          _pill('${appel['nb_absents'] ?? 0}A', const Color(0xFFEF4444)),
        ]),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _AppelDetailSheet extends StatefulWidget {
  const _AppelDetailSheet({required this.appelId});
  final String appelId;

  @override
  State<_AppelDetailSheet> createState() => _AppelDetailSheetState();
}

class _AppelDetailSheetState extends State<_AppelDetailSheet> {
  bool _loading = true;
  bool _saving = false;
  bool _editMode = false;
  dynamic _appel;
  List<dynamic> _presences = [];

  @override
  void initState() {
    super.initState();
    _chargerDetails();
  }

  Future<void> _chargerDetails() async {
    final res = await ProfessorService.getAppelDetail(widget.appelId);
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        _appel = res['data'];
        _presences = res['data']['presences'] ?? [];
      }
      _loading = false;
    });
  }

  Future<void> _sauvegarder() async {
    setState(() => _saving = true);
    final presences = _presences.map((p) => {
      'matricule': p['matricule'],
      'statut': p['statut']
    }).toList();
    
    final res = await ProfessorService.updateAppel(widget.appelId, presences);
    if (!mounted) return;
    
    setState(() => _saving = false);
    if (res['success'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['error'] ?? 'Erreur'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Détails de l\'appel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  if (_appel != null) ...[
                    Text('${_appel['module_nom'] ?? ''} - ${_appel['filiere_nom'] ?? ''} (${_appel['niveau'] ?? ''})', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ]),
              ),
              if (!_loading && _presences.isNotEmpty && !_editMode)
                TextButton.icon(
                  onPressed: () => setState(() => _editMode = true),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Modifier'),
                )
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Divider(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _presences.isEmpty
                  ? const Center(child: Text('Aucun détail trouvé'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _presences.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final p = _presences[i];
                        if (_editMode) {
                          return _EtudiantPresenceRow(
                            etudiant: p,
                            statut: p['statut'] ?? 'present',
                            onChanged: (val) {
                              setState(() {
                                p['statut'] = val;
                              });
                            },
                          );
                        }
                        
                        final isPresent = p['statut'] == 'present';
                        final isAbs = p['statut'] == 'absent';
                        final color = isPresent ? const Color(0xFF10B981) : (isAbs ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('${p['prenoms']} ${p['nom']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('${p['matricule']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: Text((p['statut'] ?? '').toString().toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        );
                      },
                    ),
        ),
        if (_editMode) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _saving ? null : () {
                      setState(() {
                        _editMode = false;
                      });
                      _chargerDetails(); // discard changes
                    },
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _saving ? null : _sauvegarder,
                    child: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
                  ),
                ),
              ],
            ),
          )
        ]
      ]),
    );
  }
}

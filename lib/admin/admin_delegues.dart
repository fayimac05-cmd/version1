import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import '../widgets/delegue_badge.dart';

const List<String> kNiveauxDelegues = [
  'Licence 1', 'Licence 2', 'Licence 3', 'Master 1', 'Master 2',
];

class AdminDelegues extends StatefulWidget {
  const AdminDelegues({super.key});

  @override
  State<AdminDelegues> createState() => _AdminDeleguesState();
}

class _AdminDeleguesState extends State<AdminDelegues> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Gestion des Délégués', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppPalette.blue,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppPalette.blue,
          tabs: const [
            Tab(text: 'Nommer'),
            Tab(text: 'Liste des délégués'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _NommerTab(),
          _ListeDeleguesTab(),
        ],
      ),
    );
  }
}

// ── Onglet Nommer ──────────────────────────────────────────────────────────

class _NommerTab extends StatefulWidget {
  const _NommerTab();

  @override
  State<_NommerTab> createState() => _NommerTabState();
}

class _NommerTabState extends State<_NommerTab> {
  List<Map<String, dynamic>> _filieres = [];
  List<dynamic> _tousLesEtudiants = [];
  bool _loading = true;

  String? _filiereId;
  String? _filiereNom;
  String? _niveau;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final resFilieres = await ApiService.getFilieres();
    final resEtudiants = await ApiService.getEtudiants();
    if (!mounted) return;
    setState(() {
      _filieres = resFilieres['success'] == true
          ? List<Map<String, dynamic>>.from(resFilieres['data'])
          : [];
      _tousLesEtudiants = resEtudiants['success'] == true ? resEtudiants['data'] as List<dynamic> : [];
      _loading = false;
    });
  }

  List<dynamic> get _etudiantsFiltres {
    if (_filiereNom == null || _niveau == null) return [];
    return _tousLesEtudiants
        .where((e) => e['filiere'] == _filiereNom && e['niveau'] == _niveau)
        .toList();
  }

  Future<void> _confirmerNomination(dynamic etudiant, String role) async {
    final roleLabel = role == 'delegue' ? 'Délégué' : 'Délégué Adjoint';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Nommer $roleLabel ?'),
        content: Text(
          '${etudiant['prenoms']} ${etudiant['nom']} deviendra $roleLabel pour $_filiereNom - $_niveau.\n\n'
          'Si un $roleLabel existe déjà pour cette filière/niveau, il perdra automatiquement ce statut.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppPalette.blue, foregroundColor: Colors.white),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final res = await ApiService.nommerDelegue(
      etudiantId: etudiant['id'].toString(),
      role: role,
      filiereId: _filiereId!,
      niveau: _niveau!,
    );
    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${etudiant['prenoms']} ${etudiant['nom']} est maintenant $roleLabel.'),
        backgroundColor: const Color(0xFF10B981),
      ));
      _charger();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['error']?.toString() ?? 'Erreur lors de la nomination.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Column(children: [
            DropdownButtonFormField<String>(
              initialValue: _filiereId,
              hint: const Text('Sélectionner une filière'),
              decoration: InputDecoration(
                labelText: 'Filière',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _filieres.map((f) => DropdownMenuItem(
                value: f['id'].toString(),
                child: Text('${f['nom']}'),
              )).toList(),
              onChanged: (v) {
                final f = _filieres.firstWhere((x) => x['id'].toString() == v);
                setState(() {
                  _filiereId = v;
                  _filiereNom = f['nom'];
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _niveau,
              hint: const Text('Sélectionner un niveau'),
              decoration: InputDecoration(
                labelText: 'Niveau',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: kNiveauxDelegues.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
              onChanged: (v) => setState(() => _niveau = v),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        if (_filiereNom != null && _niveau != null) ...[
          Text('Étudiants — $_filiereNom · $_niveau',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          if (_etudiantsFiltres.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucun étudiant dans cette filière/niveau.', style: TextStyle(color: Color(0xFF94A3B8))),
            )
          else
            ..._etudiantsFiltres.map((e) => _EtudiantNominationRow(
                  etudiant: e,
                  niveau: _niveau!,
                  onNommerDelegue: () => _confirmerNomination(e, 'delegue'),
                  onNommerAdjoint: () => _confirmerNomination(e, 'delegue_adjoint'),
                )),
        ],
      ]),
    );
  }
}

class _EtudiantNominationRow extends StatelessWidget {
  const _EtudiantNominationRow({
    required this.etudiant,
    required this.niveau,
    required this.onNommerDelegue,
    required this.onNommerAdjoint,
  });

  final dynamic etudiant;
  final String niveau;
  final VoidCallback onNommerDelegue;
  final VoidCallback onNommerAdjoint;

  @override
  Widget build(BuildContext context) {
    final role = etudiant['role']?.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: AppPalette.lightBlue,
          child: Text(
            '${etudiant['prenoms']}'.isNotEmpty ? '${etudiant['prenoms']}'[0] : '?',
            style: const TextStyle(color: AppPalette.blue, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text('${etudiant['prenoms']} ${etudiant['nom']}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
              const SizedBox(width: 6),
              DelegueBadge(role: role, niveau: niveau, compact: true),
            ]),
          ]),
        ),
        const SizedBox(width: 6),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
          onSelected: (v) => v == 'delegue' ? onNommerDelegue() : onNommerAdjoint(),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'delegue', child: Text('Nommer Délégué')),
            PopupMenuItem(value: 'delegue_adjoint', child: Text('Nommer Adjoint')),
          ],
        ),
      ]),
    );
  }
}

// ── Onglet Liste des délégués ───────────────────────────────────────────────

class _ListeDeleguesTab extends StatefulWidget {
  const _ListeDeleguesTab();

  @override
  State<_ListeDeleguesTab> createState() => _ListeDeleguesTabState();
}

class _ListeDeleguesTabState extends State<_ListeDeleguesTab> {
  List<dynamic> _delegues = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final res = await ApiService.getDelegues();
    if (!mounted) return;
    setState(() {
      _delegues = res['success'] == true ? res['data'] as List<dynamic> : [];
      _loading = false;
    });
  }

  Future<void> _revoquer(dynamic d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Retirer le statut ?'),
        content: Text('${d['prenoms']} ${d['nom']} redeviendra un étudiant normal.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final res = await ApiService.revoquerDelegue(d['id'].toString());
    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Statut retiré.'),
        backgroundColor: Color(0xFF10B981),
      ));
      _charger();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['error']?.toString() ?? 'Erreur.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _charger,
      child: _delegues.isEmpty
          ? ListView(children: const [
              Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('Aucun délégué nommé pour le moment.', style: TextStyle(color: Color(0xFF94A3B8)))),
              ),
            ])
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppPalette.blue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Text('${_delegues.length} délégué(s)/adjoint(s) au total',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                  ]),
                ),
                ..._delegues.map((d) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Flexible(child: Text('${d['prenoms']} ${d['nom']}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                              const SizedBox(width: 6),
                              DelegueBadge(role: d['etudiant_role'], niveau: d['niveau'], compact: true),
                            ]),
                            const SizedBox(height: 4),
                            Text('${d['matricule'] ?? ''}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                            const SizedBox(height: 2),
                            Text('${d['filiere_nom'] ?? ''} · ${d['niveau'] ?? ''} · ${d['domaine'] ?? ''}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ]),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
                          onPressed: () => _revoquer(d),
                        ),
                      ]),
                    )),
              ],
            ),
    );
  }
}

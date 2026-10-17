import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import '../widgets/bde_badge.dart';

// ════════════════════════════════════════════════════════════════════════════
// GESTION DU BUREAU DES ÉTUDIANTS (BDE) — nomination président(e)/adjoint(e)/
// membre, calquée sur admin_delegues.dart. Contrairement au délégué (scopé
// filière+niveau), le BDE est établissement entier : un seul président et un
// seul adjoint à la fois, pas de sélection de filière/niveau nécessaire.
// ════════════════════════════════════════════════════════════════════════════
class AdminBdeMembres extends StatefulWidget {
  const AdminBdeMembres({super.key});

  @override
  State<AdminBdeMembres> createState() => _AdminBdeMembresState();
}

class _AdminBdeMembresState extends State<AdminBdeMembres> with SingleTickerProviderStateMixin {
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
        title: const Text('Bureau des Étudiants', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: const Color(0xFF7C3AED),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF7C3AED),
          tabs: const [
            Tab(text: 'Nommer'),
            Tab(text: 'Membres du BDE'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _NommerBdeTab(),
          _ListeBdeTab(),
        ],
      ),
    );
  }
}

// ── Onglet Nommer — liste tous les étudiants (recherche), pas de filière/niveau ──

class _NommerBdeTab extends StatefulWidget {
  const _NommerBdeTab();

  @override
  State<_NommerBdeTab> createState() => _NommerBdeTabState();
}

class _NommerBdeTabState extends State<_NommerBdeTab> {
  List<dynamic> _tousLesEtudiants = [];
  bool _loading = true;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final res = await ApiService.getEtudiants();
    if (!mounted) return;
    setState(() {
      _tousLesEtudiants = res['success'] == true ? res['data'] as List<dynamic> : [];
      _loading = false;
    });
  }

  List<dynamic> get _etudiantsFiltres {
    if (_recherche.trim().isEmpty) return _tousLesEtudiants;
    final q = _recherche.trim().toLowerCase();
    return _tousLesEtudiants.where((e) {
      final nom = '${e['prenoms'] ?? ''} ${e['nom'] ?? ''}'.toLowerCase();
      final matricule = '${e['matricule'] ?? ''}'.toLowerCase();
      return nom.contains(q) || matricule.contains(q);
    }).toList();
  }

  Future<void> _confirmerNomination(dynamic etudiant, String role) async {
    final roleLabel = role == 'bde_president'
        ? 'Délégué(e) Général(e) BDE'
        : role == 'bde_adjoint'
            ? 'Adjoint(e) Délégué(e) Général(e) BDE'
            : 'Membre BDE';
    final avertissement = role == 'bde_membre'
        ? ''
        : '\n\nSi un(e) $roleLabel existe déjà, il/elle perdra automatiquement ce statut.';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Nommer $roleLabel ?'),
        content: Text('${etudiant['prenoms']} ${etudiant['nom']} deviendra $roleLabel.$avertissement'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final headers = await ApiService.getHeaders();
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/etudiants/${etudiant['id']}/nommer-bde'),
        headers: headers,
        body: jsonEncode({'role': role}),
      );
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (!mounted) return;
      if (res.statusCode == 200 && body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${etudiant['prenoms']} ${etudiant['nom']} est maintenant $roleLabel.'),
          backgroundColor: const Color(0xFF10B981),
        ));
        _charger();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(body['message']?.toString() ?? 'Erreur lors de la nomination.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Serveur injoignable.'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          onChanged: (v) => setState(() => _recherche = v),
          decoration: InputDecoration(
            hintText: 'Rechercher un(e) étudiant(e) (nom ou matricule)...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      Expanded(
        child: _etudiantsFiltres.isEmpty
            ? const Center(child: Text('Aucun étudiant trouvé.', style: TextStyle(color: Color(0xFF94A3B8))))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _etudiantsFiltres.length,
                itemBuilder: (_, i) => _EtudiantNominationBdeRow(
                  etudiant: _etudiantsFiltres[i],
                  onNommer: (role) => _confirmerNomination(_etudiantsFiltres[i], role),
                ),
              ),
      ),
    ]);
  }
}

class _EtudiantNominationBdeRow extends StatelessWidget {
  const _EtudiantNominationBdeRow({required this.etudiant, required this.onNommer});

  final dynamic etudiant;
  final void Function(String role) onNommer;

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
              BdeBadge(role: role, compact: true),
            ]),
            Text('${etudiant['filiere'] ?? ''} · ${etudiant['niveau'] ?? ''}',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
          ]),
        ),
        const SizedBox(width: 6),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
          onSelected: onNommer,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'bde_president', child: Text('Nommer Délégué(e) Général(e)')),
            PopupMenuItem(value: 'bde_adjoint', child: Text('Nommer Adjoint(e)')),
            PopupMenuItem(value: 'bde_membre', child: Text('Ajouter comme Membre')),
          ],
        ),
      ]),
    );
  }
}

// ── Onglet Membres du BDE ────────────────────────────────────────────────────

class _ListeBdeTab extends StatefulWidget {
  const _ListeBdeTab();

  @override
  State<_ListeBdeTab> createState() => _ListeBdeTabState();
}

class _ListeBdeTabState extends State<_ListeBdeTab> {
  List<dynamic> _membres = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.get(Uri.parse('${ApiService.baseUrl}/etudiants/bde'), headers: headers);
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (!mounted) return;
      setState(() {
        _membres = res.statusCode == 200 && body['success'] == true ? body['data'] as List<dynamic> : [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revoquer(dynamic m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Retirer le statut ?'),
        content: Text('${m['prenoms']} ${m['nom']} redeviendra un étudiant normal.'),
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

    try {
      final headers = await ApiService.getHeaders();
      final res = await http.patch(Uri.parse('${ApiService.baseUrl}/etudiants/${m['id']}/revoquer-bde'), headers: headers);
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (!mounted) return;
      if (res.statusCode == 200 && body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Statut retiré.'), backgroundColor: Color(0xFF10B981)));
        _charger();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(body['message']?.toString() ?? 'Erreur.'), backgroundColor: Colors.red));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Serveur injoignable.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _charger,
      child: _membres.isEmpty
          ? ListView(children: const [
              Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('Aucun membre BDE nommé pour le moment.', style: TextStyle(color: Color(0xFF94A3B8)))),
              ),
            ])
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Text('${_membres.length} membre(s) du BDE au total',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                  ]),
                ),
                ..._membres.map((m) => Container(
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
                              Flexible(child: Text('${m['prenoms']} ${m['nom']}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                              const SizedBox(width: 6),
                              BdeBadge(role: m['etudiant_role']?.toString(), compact: true),
                            ]),
                            const SizedBox(height: 4),
                            Text('${m['matricule'] ?? ''}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                            const SizedBox(height: 2),
                            Text('${m['filiere_nom'] ?? ''} · ${m['niveau'] ?? ''}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ]),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
                          onPressed: () => _revoquer(m),
                        ),
                      ]),
                    )),
              ],
            ),
    );
  }
}

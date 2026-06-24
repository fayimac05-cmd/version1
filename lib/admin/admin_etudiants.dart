import 'package:flutter/material.dart';
import '../models/etudiant_model.dart'; // Import crucial
import '../services/api_service.dart';
import '../admin/admin_theme.dart';

class AdminEtudiants extends StatefulWidget {
  const AdminEtudiants({super.key});
  @override State<AdminEtudiants> createState() => _AdminEtudiantsState();
}

class _AdminEtudiantsState extends State<AdminEtudiants> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Etudiant> _filteredList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _chargerEtudiants();
  }

  Future<void> _chargerEtudiants() async {
    setState(() => _loading = true);
    final data = await ApiService.getEtudiants();
    setState(() {
      adminEtudiants = data.map((e) => etudiantFromApi(Map<String, dynamic>.from(e as Map))).toList();
      _filteredList = adminEtudiants;
      _loading = false;
    });
  }

  // --- Fonctions manquantes ---
  void _inscrireEtudiant() { /* Ton ancienne logique ici */ }
  void _ouvrirFiche(Etudiant e) { /* Ton ancienne logique ici */ }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(children: [
        _buildHeader(),
        Expanded(child: TabBarView(controller: _tabs, children: [
          _buildListView(_filteredList),
          _buildListView(_filteredList.where((e) => e.role != 'etudiant').toList()),
        ])),
      ]),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.all(24),
    color: Colors.white,
    child: Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Annuaire Étudiants', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        Text('${adminEtudiants.length} inscrits', style: const TextStyle(color: Colors.grey)),
      ]),
      const Spacer(),
      FilledButton.icon(onPressed: _inscrireEtudiant, icon: const Icon(Icons.add), label: const Text('Inscrire'))
    ]),
  );

  Widget _buildListView(List<Etudiant> items) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: items.length,
    itemBuilder: (_, i) => _carteEtudiantModerne(items[i]),
  );

  Widget _carteEtudiantModerne(Etudiant e) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: CircleAvatar(child: Text(e.prenoms[0])),
      title: Text("${e.prenoms} ${e.nom}"),
      subtitle: Text(e.matricule),
      trailing: IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _ouvrirFiche(e)),
    ),
  );
}
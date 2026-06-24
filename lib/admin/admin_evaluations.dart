import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_filieres.dart';
import '../models/evaluation_model.dart'; // Import du modèle

class AdminEvaluations extends StatefulWidget {
  const AdminEvaluations({super.key});
  @override State<AdminEvaluations> createState() => _AdminEvaluationsState();
}

class _AdminEvaluationsState extends State<AdminEvaluations> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(children: [
        _buildHeader(),
        Container(height: 1, color: const Color(0xFFE5E7EB)),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: adminEvaluations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _cartePeriode(adminEvaluations[i]),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Évaluation des Professeurs', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const Text('Évaluations anonymes', style: TextStyle(color: Color(0xFF6B7280))),
      ])),
      FilledButton.icon(
        onPressed: _ouvrirPeriode,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ouvrir une période'),
      ),
    ]),
  );

  Widget _cartePeriode(PeriodeEvaluation ev) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        ListTile(
          leading: Icon(ev.ouverte ? Icons.lock_open : Icons.lock, color: ev.ouverte ? Colors.green : Colors.grey),
          title: Text(ev.filiere, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Du ${ev.dateDebut} au ${ev.dateFin}'),
          trailing: Switch(value: ev.ouverte, onChanged: (v) => setState(() => ev.ouverte = v)),
        ),
        // Ajouter ici le code d'affichage des résultats que tu avais...
      ]),
    );
  }

  void _ouvrirPeriode() {
    final debutCtrl = TextEditingController();
    final finCtrl = TextEditingController();
    String filiereSelected = adminFilieres.isNotEmpty ? adminFilieres.first.nom : '';

    showModalBottomSheet(context: context, builder: (ctx) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: debutCtrl, decoration: const InputDecoration(labelText: 'Date début')),
        TextField(controller: finCtrl, decoration: const InputDecoration(labelText: 'Date fin')),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            if (debutCtrl.text.isNotEmpty && finCtrl.text.isNotEmpty) {
              setState(() => adminEvaluations.add(PeriodeEvaluation(
                id: 'EV${adminEvaluations.length + 1}',
                filiere: filiereSelected,
                dateDebut: debutCtrl.text,
                dateFin: finCtrl.text,
                ouverte: true,
                resultats: {}
              )));
              Navigator.pop(ctx);
            }
          },
          child: const Text('Valider'),
        )
      ]),
    ));
  }
}
import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class PaiementScolariteScreen extends StatefulWidget {
  const PaiementScolariteScreen({super.key});
  @override
  State<PaiementScolariteScreen> createState() =>
      _PaiementScolariteScreenState();
}

class _PaiementScolariteScreenState extends State<PaiementScolariteScreen> {
  final List<Map<String, dynamic>> frais = [
    {'libelle': 'Frais d\'inscription', 'montant': 50000, 'statut': 'non_payé'},
    {'libelle': 'Mensualité Janvier', 'montant': 25000, 'statut': 'payé'},
  ];

  void _payer(Map<String, dynamic> frais) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Paiement Orange Money'),
        content: Text(
          'Payer ${frais['montant']} FCFA pour ${frais['libelle']} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => frais['statut'] = 'payé');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Paiement réussi pour ${frais['libelle']} !'),
                ),
              );
            },
            child: const Text('Payer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiements Scolarité')),
      body: ListView.builder(
        itemCount: frais.length,
        itemBuilder: (context, i) {
          final f = frais[i];
          return ListTile(
            title: Text(f['libelle']),
            subtitle: Text('${f['montant']} FCFA — ${f['statut']}'),
            trailing: f['statut'] == 'non_payé'
                ? ElevatedButton(
                    onPressed: () => _payer(f),
                    child: const Text('Payer'),
                  )
                : const Icon(Icons.check_circle, color: Colors.green),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../admin/reclamation_commun.dart';

/// Suivi des réclamations de l'étudiant connecté : liste, nouvelle réclamation,
/// détail avec échanges et réponse de l'administration.
/// (Même nom de classe qu'avant : la navigation existante continue de fonctionner.)
class MesReclamationsPage extends StatelessWidget {
  const MesReclamationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        title: const Text('Mes réclamations', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: const ReclamationsListe(role: 'etudiant'),
    );
  }
}
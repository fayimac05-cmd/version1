import 'package:flutter/material.dart';
import '../admin/reclamation_commun.dart';

// Écran professeur : réclamations transmises par l'administration.
// Le professeur traite, commente, puis « Valider et retourner à l'administration ».
class ProfesseurReclamations extends StatelessWidget {
  const ProfesseurReclamations({super.key});

  @override
  Widget build(BuildContext context) => const ReclamationsListe(role: 'professeur');
}

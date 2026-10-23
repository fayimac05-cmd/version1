import 'package:flutter/material.dart';
import 'reclamation_commun.dart';

// Écran administration : reçoit les réclamations, les transmet au professeur
// concerné ou les rejette, vérifie le retour du professeur et répond à l'étudiant.
class AdminReclamations extends StatelessWidget {
  const AdminReclamations({super.key});

  @override
  Widget build(BuildContext context) => const ReclamationsListe(role: 'admin');
}
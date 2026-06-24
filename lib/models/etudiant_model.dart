import 'package:flutter/material.dart';

class Etudiant {
  final String matricule, nom, prenoms, filiere, domaine, niveau;
  String email, telephone, dateNaissance, nationalite, adresse;
  final String nomParent, telParent, emailParent;
  String statut, role;
  String? filiereRole;
  final List<Map<String, dynamic>> notes;
  final List<String> badges;

  Etudiant({
    required this.matricule, required this.nom, required this.prenoms,
    required this.filiere, required this.domaine, required this.niveau,
    required this.email, required this.telephone,
    required this.dateNaissance, required this.nationalite, required this.adresse,
    required this.nomParent, required this.telParent, required this.emailParent,
    this.statut = 'actif', this.role = 'etudiant', this.filiereRole,
    this.notes = const [], this.badges = const [],
  });

  bool get estDelegue => role == 'delegue' || role == 'delegue_adjoint';
  String get roleLabel {
    switch (role) {
      case 'delegue': return 'Délégué(e)';
      case 'delegue_adjoint': return 'Adjoint(e) Délégué(e)';
      default: return 'Étudiant(e)';
    }
  }
}

List<Etudiant> adminEtudiants = [];

Etudiant etudiantFromApi(Map<String, dynamic> j) => Etudiant(
  matricule: j['matricule'] ?? '',
  nom: j['nom'] ?? '',
  prenoms: j['prenoms'] ?? '',
  filiere: j['filiere'] ?? '',
  domaine: j['domaine'] ?? '',
  niveau: j['niveau'] ?? '',
  email: j['email'] ?? '',
  telephone: j['telephone'] ?? '',
  dateNaissance: j['dateNaissance'] ?? '',
  nationalite: j['nationalite'] ?? 'Burkinabè',
  adresse: j['adresse'] ?? '',
  nomParent: j['nomParent'] ?? '',
  telParent: j['telParent'] ?? '',
  emailParent: j['emailParent'] ?? '',
  statut: j['statut'] ?? 'actif',
  role: j['role'] ?? 'etudiant',
  filiereRole: j['filiereRole'],
);
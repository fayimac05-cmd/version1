class StudentProfile {
  const StudentProfile({
    required this.nom,
    required this.prenoms,
    required this.matricule,
    required this.email,
    required this.telephone,
    required this.filiere,
    required this.motDePasse,
    this.domaine = '',
    this.role = 'etudiant',
  });

  final String nom;
  final String prenoms;
  final String matricule;
  final String email;
  final String telephone;
  final String filiere;
  final String motDePasse;
  final String domaine;
  final String role;
}

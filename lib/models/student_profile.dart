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
    this.niveau = '',
    this.role = 'etudiant',
    this.filiereRole,
  });

  final String nom;
  final String prenoms;
  final String matricule;
  final String email;
  final String telephone;
  final String filiere;
  final String motDePasse;
  final String domaine;
  final String niveau;

  // ── Rôle dans l'établissement ──────────────────────────────────────
  // 'etudiant'        → étudiant normal
  // 'delegue'         → délégué(e) de filière
  // 'delegue_adjoint' → adjoint(e) délégué(e) de filière
  // 'bde_president'   → Délégué(e) Général(e) BDE (peut publier Canal BDE)
  // 'bde_adjoint'     → Adjoint(e) Délégué(e) Général(e) (peut publier Canal BDE)
  // 'bde_membre'      → membre BDE (étudiant normal côté discussions)
  // 'admin'           → administrateur
  // 'professeur'      → professeur
  // 'parent'          → parent
  final String role;

  // Filière pour laquelle ce délégué a les droits d'écriture
  // Null pour les autres rôles
  final String? filiereRole;

  // ── Helpers ────────────────────────────────────────────────────────
  bool get estDelegue =>
      role == 'delegue' || role == 'delegue_adjoint';

  bool peutEcrireCanal(String filiereCanal) =>
      estDelegue &&
      (filiereRole == filiereCanal || filiereRole == filiere);

  bool get peutPublierBDE =>
      role == 'bde_president' || role == 'bde_adjoint';

  bool get estBDE =>
      role == 'bde_president' ||
      role == 'bde_adjoint' ||
      role == 'bde_membre';

  String get roleLabel {
    switch (role) {
      case 'delegue':         return 'Délégué(e)';
      case 'delegue_adjoint': return 'Adjoint(e) Délégué(e)';
      case 'bde_president':   return 'Délégué(e) Général(e) BDE';
      case 'bde_adjoint':     return 'Adjoint(e) Délégué(e) Général(e) BDE';
      case 'bde_membre':      return 'Membre BDE';
      case 'admin':           return 'Administrateur';
      case 'professeur':      return 'Professeur';
      case 'parent':          return 'Parent';
      default:                return 'Étudiant(e)';
    }
  }

  String get roleBadgeEmoji {
    switch (role) {
      case 'delegue':         return '🎖️';
      case 'delegue_adjoint': return '🏅';
      case 'bde_president':   return '👑';
      case 'bde_adjoint':     return '⭐';
      case 'bde_membre':      return '🎉';
      default:                return '';
    }
  }

  StudentProfile copyWith({
    String? nom,
    String? prenoms,
    String? matricule,
    String? email,
    String? telephone,
    String? filiere,
    String? motDePasse,
    String? domaine,
    String? niveau,
    String? role,
    String? filiereRole,
  }) =>
      StudentProfile(
        nom: nom ?? this.nom,
        prenoms: prenoms ?? this.prenoms,
        matricule: matricule ?? this.matricule,
        email: email ?? this.email,
        telephone: telephone ?? this.telephone,
        filiere: filiere ?? this.filiere,
        motDePasse: motDePasse ?? this.motDePasse,
        domaine: domaine ?? this.domaine,
        niveau: niveau ?? this.niveau,
        role: role ?? this.role,
        filiereRole: filiereRole ?? this.filiereRole,
      );
}

// ════════════════════════════════════════════════════════════════════════════
// ADMIN DATA — Modèles & Données simulées ScolarHub IST Ouaga 2000
// ════════════════════════════════════════════════════════════════════════════

// ── Modèle Filière ────────────────────────────────────────────────────────
class AdminFiliere {
  final String id;
  final String nom;
  final String niveau;
  final String domaine;
  final String anneeAcademique;
  final List<AdminModule> modules;

  const AdminFiliere({
    required this.id,
    required this.nom,
    required this.niveau,
    required this.domaine,
    required this.anneeAcademique,
    required this.modules,
  });
}

// ── Modèle Module ─────────────────────────────────────────────────────────
class AdminModule {
  final String id;
  final String nom;
  final String code;
  final int coefficient;
  final int volumeHoraire;
  final String profNom;

  const AdminModule({
    required this.id,
    required this.nom,
    required this.code,
    required this.coefficient,
    required this.volumeHoraire,
    required this.profNom,
  });
}

// ── Modèle Étudiant ───────────────────────────────────────────────────────
class AdminEtudiant {
  final String matricule;
  final String nom;
  final String prenoms;
  final String email;
  final String telephone;
  final String filiereId;
  final String filiere;
  final String domaine;
  final String niveau;
  String statut; // actif / suspendu / renvoyé

  AdminEtudiant({
    required this.matricule,
    required this.nom,
    required this.prenoms,
    required this.email,
    required this.telephone,
    required this.filiereId,
    required this.filiere,
    required this.domaine,
    required this.niveau,
    this.statut = 'actif',
  });
}

// ── Modèle Professeur ─────────────────────────────────────────────────────
class AdminProf {
  final String id;
  final String nom;
  final String prenoms;
  final String telephone;
  final String email;
  final List<String> filieres;
  final List<String> modules;

  const AdminProf({
    required this.id,
    required this.nom,
    required this.prenoms,
    required this.telephone,
    required this.email,
    required this.filieres,
    required this.modules,
  });
}

// ── Modèle Réclamation ────────────────────────────────────────────────────
class AdminReclamation {
  final String id;
  final String etudiantMatricule;
  final String etudiantNom;
  final String module;
  final String filiere;
  final String type; // note / moyenne
  final String description;
  final String dateCreation;
  String statut; // en_attente / transmise_prof / resolue / rejetee
  String? reponse;

  AdminReclamation({
    required this.id,
    required this.etudiantMatricule,
    required this.etudiantNom,
    required this.module,
    required this.filiere,
    required this.type,
    required this.description,
    required this.dateCreation,
    this.statut = 'en_attente',
    this.reponse,
  });
}

// ════════════════════════════════════════════════════════════════════════════
// DONNÉES SIMULÉES
// ════════════════════════════════════════════════════════════════════════════

final List<AdminFiliere> adminFilieres = [
  // ── Sciences & Technologies ─────────────────────────────────────────────
  AdminFiliere(
    id: 'RIT-L2',
    nom: 'Réseaux Informatiques et Télécom',
    niveau: 'Licence 2',
    domaine: 'Sciences & Technologies',
    anneeAcademique: '2024-2025',
    modules: [
      const AdminModule(id: 'm1', nom: 'Réseaux & Protocoles', code: 'RES301', coefficient: 3, volumeHoraire: 45, profNom: 'OUÉDRAOGO Mamadou'),
      const AdminModule(id: 'm2', nom: 'Programmation Orientée Objet', code: 'POO302', coefficient: 3, volumeHoraire: 45, profNom: 'SAWADOGO Issa'),
      const AdminModule(id: 'm3', nom: 'Base de Données Avancée', code: 'BDA303', coefficient: 2, volumeHoraire: 30, profNom: 'TRAORÉ Saidou'),
      const AdminModule(id: 'm4', nom: 'Sécurité Informatique', code: 'SEC304', coefficient: 2, volumeHoraire: 30, profNom: 'KABORÉ Adama'),
      const AdminModule(id: 'm5', nom: 'Anglais Technique', code: 'ANG305', coefficient: 1, volumeHoraire: 20, profNom: 'ZONGO Marie'),
    ],
  ),
  AdminFiliere(
    id: 'ELEC-L2',
    nom: 'Electrotechnique',
    niveau: 'Licence 2',
    domaine: 'Sciences & Technologies',
    anneeAcademique: '2024-2025',
    modules: [
      const AdminModule(id: 'm6', nom: 'Électronique de Puissance', code: 'EP301', coefficient: 3, volumeHoraire: 45, profNom: 'COMPAORÉ Brahima'),
      const AdminModule(id: 'm7', nom: 'Machines Électriques', code: 'ME302', coefficient: 3, volumeHoraire: 45, profNom: 'OUATTARA Luc'),
      const AdminModule(id: 'm8', nom: 'Automatismes Industriels', code: 'AI303', coefficient: 2, volumeHoraire: 30, profNom: 'TAPSOBA Noël'),
    ],
  ),
  AdminFiliere(
    id: 'GC-L2',
    nom: 'Génie Civil',
    niveau: 'Licence 2',
    domaine: 'Sciences & Technologies',
    anneeAcademique: '2024-2025',
    modules: [
      const AdminModule(id: 'm9', nom: 'Résistance des Matériaux', code: 'RDM301', coefficient: 3, volumeHoraire: 45, profNom: 'BÉLEM Roger'),
      const AdminModule(id: 'm10', nom: 'Topographie', code: 'TOP302', coefficient: 2, volumeHoraire: 30, profNom: 'KINDA Sylvain'),
    ],
  ),
  // ── Sciences de Gestion ─────────────────────────────────────────────────
  AdminFiliere(
    id: 'MKT-L2',
    nom: 'Marketing',
    niveau: 'Licence 2',
    domaine: 'Sciences de Gestion',
    anneeAcademique: '2024-2025',
    modules: [
      const AdminModule(id: 'm11', nom: 'Marketing Stratégique', code: 'MKS301', coefficient: 3, volumeHoraire: 45, profNom: 'SOME Clarisse'),
      const AdminModule(id: 'm12', nom: 'Études de Marché', code: 'EDM302', coefficient: 2, volumeHoraire: 30, profNom: 'OUÉDRAOGO Fatou'),
      const AdminModule(id: 'm13', nom: 'Communication Publicitaire', code: 'PUB303', coefficient: 2, volumeHoraire: 30, profNom: 'ILBOUDO Sandra'),
    ],
  ),
  AdminFiliere(
    id: 'FIN-L2',
    nom: 'Finance Comptabilité',
    niveau: 'Licence 2',
    domaine: 'Sciences de Gestion',
    anneeAcademique: '2024-2025',
    modules: [
      const AdminModule(id: 'm14', nom: 'Comptabilité Générale', code: 'CG301', coefficient: 3, volumeHoraire: 45, profNom: 'NABÉ Constant'),
      const AdminModule(id: 'm15', nom: 'Fiscalité', code: 'FIS302', coefficient: 2, volumeHoraire: 30, profNom: 'YAMEOGO Paul'),
      const AdminModule(id: 'm16', nom: 'Analyse Financière', code: 'AF303', coefficient: 3, volumeHoraire: 45, profNom: 'KONÉ Aminata'),
    ],
  ),
];

// ── Étudiants simulés ────────────────────────────────────────────────────
List<AdminEtudiant> adminEtudiants = [
  AdminEtudiant(
    matricule: '24IST-O2/1851',
    nom: 'KOURAOGO', prenoms: 'Ibrahim',
    email: 'ibrahim.kouraogo@ist.bf', telephone: '70001851',
    filiereId: 'RIT-L2', filiere: 'Réseaux Informatiques et Télécom',
    domaine: 'Sciences & Technologies', niveau: 'Licence 2',
  ),
  AdminEtudiant(
    matricule: '24IST-O2/1234',
    nom: 'TRAORÉ', prenoms: 'Fatimata',
    email: 'fatimata.traore@ist.bf', telephone: '76001234',
    filiereId: 'RIT-L2', filiere: 'Réseaux Informatiques et Télécom',
    domaine: 'Sciences & Technologies', niveau: 'Licence 2',
  ),
  AdminEtudiant(
    matricule: '24IST-O2/1002',
    nom: 'SAWADOGO', prenoms: 'Aminata',
    email: 'aminata.sawadogo@ist.bf', telephone: '65001002',
    filiereId: 'RIT-L2', filiere: 'Réseaux Informatiques et Télécom',
    domaine: 'Sciences & Technologies', niveau: 'Licence 2',
  ),
  AdminEtudiant(
    matricule: '24IST-O2/2050',
    nom: 'OUÉDRAOGO', prenoms: 'Issouf',
    email: 'issouf.ouedraogo@ist.bf', telephone: '70002050',
    filiereId: 'ELEC-L2', filiere: 'Electrotechnique',
    domaine: 'Sciences & Technologies', niveau: 'Licence 2',
    statut: 'suspendu',
  ),
  AdminEtudiant(
    matricule: '23IST-O2/0987',
    nom: 'SAWADOGO', prenoms: 'Moussa',
    email: 'moussa.sawadogo@ist.bf', telephone: '60000987',
    filiereId: 'FIN-L2', filiere: 'Finance Comptabilité',
    domaine: 'Sciences de Gestion', niveau: 'Licence 3',
  ),
  AdminEtudiant(
    matricule: '24IST-O2/3010',
    nom: 'KABORÉ', prenoms: 'Djeneba',
    email: 'djeneba.kabore@ist.bf', telephone: '75003010',
    filiereId: 'MKT-L2', filiere: 'Marketing',
    domaine: 'Sciences de Gestion', niveau: 'Licence 2',
  ),
];

// ── Professeurs simulés ───────────────────────────────────────────────────
final List<AdminProf> adminProfs = [
  const AdminProf(
    id: 'P001',
    nom: 'OUÉDRAOGO', prenoms: 'Mamadou',
    telephone: '70123456', email: 'mamadou.ouedraogo@ist.bf',
    filieres: ['Réseaux Informatiques et Télécom'],
    modules: ['Réseaux & Protocoles'],
  ),
  const AdminProf(
    id: 'P002',
    nom: 'SAWADOGO', prenoms: 'Issa',
    telephone: '76234567', email: 'issa.sawadogo@ist.bf',
    filieres: ['Réseaux Informatiques et Télécom'],
    modules: ['Programmation Orientée Objet'],
  ),
  const AdminProf(
    id: 'P003',
    nom: 'COMPAORÉ', prenoms: 'Brahima',
    telephone: '65345678', email: 'brahima.compaore@ist.bf',
    filieres: ['Electrotechnique'],
    modules: ['Électronique de Puissance'],
  ),
  const AdminProf(
    id: 'P004',
    nom: 'SOME', prenoms: 'Clarisse',
    telephone: '70456789', email: 'clarisse.some@ist.bf',
    filieres: ['Marketing'],
    modules: ['Marketing Stratégique'],
  ),
];

// ── Réclamations simulées ─────────────────────────────────────────────────
List<AdminReclamation> adminReclamations = [
  AdminReclamation(
    id: 'R001',
    etudiantMatricule: '24IST-O2/1851',
    etudiantNom: 'KOURAOGO Ibrahim',
    module: 'Réseaux & Protocoles',
    filiere: 'Réseaux Informatiques et Télécom',
    type: 'note',
    description: 'Ma note de TD (4.5/20) ne correspond pas à ma copie. J\'avais eu 12/20 selon le barème communiqué.',
    dateCreation: '28/04/2025',
    statut: 'en_attente',
  ),
  AdminReclamation(
    id: 'R002',
    etudiantMatricule: '24IST-O2/1234',
    etudiantNom: 'TRAORÉ Fatimata',
    module: 'Programmation Orientée Objet',
    filiere: 'Réseaux Informatiques et Télécom',
    type: 'moyenne',
    description: 'La moyenne affichée (8.2) ne prend pas en compte mon devoir du 15 mars.',
    dateCreation: '27/04/2025',
    statut: 'transmise_prof',
    reponse: 'Transmis au professeur SAWADOGO Issa pour vérification.',
  ),
  AdminReclamation(
    id: 'R003',
    etudiantMatricule: '24IST-O2/3010',
    etudiantNom: 'KABORÉ Djeneba',
    module: 'Marketing Stratégique',
    filiere: 'Marketing',
    type: 'note',
    description: 'Absence injustifiée notée alors que j\'avais un certificat médical remis à la scolarité.',
    dateCreation: '26/04/2025',
    statut: 'resolue',
    reponse: 'Vérification effectuée. Note corrigée de 0 à 11/20. Certificat validé.',
  ),
];

// ── Statistiques rapides ──────────────────────────────────────────────────
Map<String, dynamic> getAdminStats() {
  final total = adminEtudiants.length;
  final actifs = adminEtudiants.where((e) => e.statut == 'actif').length;
  final suspendus = adminEtudiants.where((e) => e.statut == 'suspendu').length;
  final renvoyes = adminEtudiants.where((e) => e.statut == 'renvoyé').length;
  final reclamationsEnAttente = adminReclamations.where((r) => r.statut == 'en_attente').length;
  return {
    'totalEtudiants': total,
    'actifs': actifs,
    'suspendus': suspendus,
    'renvoyes': renvoyes,
    'totalFilieres': adminFilieres.length,
    'totalProfs': adminProfs.length,
    'reclamationsEnAttente': reclamationsEnAttente,
  };
}

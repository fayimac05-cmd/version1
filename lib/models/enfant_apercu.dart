/// Aperçu d'un enfant rattaché au parent connecté — renvoyé par
/// GET /api/parents/mes-enfants (voir parents.controller.js::getMesEnfants).
class EnfantApercu {
  final String etudiantId;
  final String matricule;
  final String nom;
  final String prenoms;
  final String filiere;
  final String niveau;
  final double? moyenne;
  final double? tauxPresence;
  final int notesNonLues;
  final int bulletinsNonLus;

  EnfantApercu({
    required this.etudiantId,
    required this.matricule,
    required this.nom,
    required this.prenoms,
    required this.filiere,
    required this.niveau,
    this.moyenne,
    this.tauxPresence,
    this.notesNonLues = 0,
    this.bulletinsNonLus = 0,
  });

  String get nomComplet => '$prenoms $nom'.trim();

  factory EnfantApercu.fromJson(Map<String, dynamic> json) => EnfantApercu(
        etudiantId: json['etudiant_id']?.toString() ?? '',
        matricule: json['matricule'] ?? '',
        nom: json['nom'] ?? '',
        prenoms: json['prenoms'] ?? '',
        filiere: json['filiere_nom'] ?? '',
        niveau: json['niveau'] ?? '',
        moyenne: json['moyenne'] != null ? double.tryParse(json['moyenne'].toString()) : null,
        tauxPresence: json['taux_presence'] != null ? double.tryParse(json['taux_presence'].toString()) : null,
        notesNonLues: int.tryParse(json['notes_non_lues']?.toString() ?? '0') ?? 0,
        bulletinsNonLus: int.tryParse(json['bulletins_non_lus']?.toString() ?? '0') ?? 0,
      );
}

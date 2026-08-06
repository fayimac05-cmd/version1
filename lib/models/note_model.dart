class NoteEtudiant {
  final String? id;
  final String matricule;
  final double valeur;
  final String module;

  NoteEtudiant({
    this.id,
    required this.matricule,
    required this.valeur,
    required this.module,
  });

  /// Sérialisation vers Supabase (insert/update)
  Map<String, dynamic> toJson() => {
        'matricule': matricule,
        'valeur': valeur,
        'module': module,
      };

  /// Désérialisation depuis Supabase (select)
  factory NoteEtudiant.fromJson(Map<String, dynamic> json) {
    return NoteEtudiant(
      id: json['id']?.toString(),
      matricule: json['matricule'] as String,
      valeur: (json['valeur'] as num).toDouble(),
      module: json['module'] as String,
    );
  }
}
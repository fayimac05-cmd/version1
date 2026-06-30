import '../admin/admin_parents.dart';
import '../models/etudiant_model.dart';

class ParentsService {
  // Liste interne (remplacée plus tard par un appel API)
  final List<Parent> _parents = List.from(adminParents);

  List<Parent> get allParents => _parents;

  // Validation métier : vérifier si l'enfant existe
  bool enfantExiste(String matricule) {
    return adminEtudiants.any((e) => e.matricule == matricule.toUpperCase());
  }

  // Logique d'ajout sécurisée
  void ajouterParent(Parent nouveauParent) {
    _parents.add(nouveauParent);
  }

  // Logique de recherche
  List<Parent> filtrerParents(String query) {
    if (query.isEmpty) return _parents;
    final q = query.toLowerCase();
    return _parents.where((p) => 
        p.nom.toLowerCase().contains(q) || 
        p.prenoms.toLowerCase().contains(q) || 
        p.matriculeEnfant.toLowerCase().contains(q)
    ).toList();
  }
}
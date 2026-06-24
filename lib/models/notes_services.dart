import '../models/note_model.dart';

class NotesService {
  // Simulation d'une base de données locale ou distante
  final List<NoteEtudiant> _baseNotes = [];

  // Logique métier : Calculer une moyenne
  double calculerMoyenne(List<double> notes) {
    if (notes.isEmpty) return 0.0;
    return notes.reduce((a, b) => a + b) / notes.length;
  }

  // Logique métier : Valider une note
  bool estNoteValide(String saisie) {
    final valeur = double.tryParse(saisie.replaceAll(',', '.'));
    return valeur != null && valeur >= 0 && valeur <= 20;
  }

  // Logique de stockage
  Future<void> sauvegarderNote(NoteEtudiant note) async {
    // Ici, plus tard, tu feras : await FirebaseFirestore.instance.collection('notes')...
    _baseNotes.add(note);
  }
}
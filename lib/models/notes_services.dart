import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note_model.dart';

class NotesService {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Logique métier : Calculer une moyenne ──
  double calculerMoyenne(List<double> notes) {
    if (notes.isEmpty) return 0.0;
    return notes.reduce((a, b) => a + b) / notes.length;
  }

  // ── Logique métier : Valider une note ──
  bool estNoteValide(String saisie) {
    final valeur = double.tryParse(saisie.replaceAll(',', '.'));
    return valeur != null && valeur >= 0 && valeur <= 20;
  }

  // ── Sauvegarder une note dans Supabase ──
  Future<void> sauvegarderNote(NoteEtudiant note) async {
    await _client.from('notes').insert(note.toJson());
  }

  // ── Récupérer toutes les notes d'un étudiant ──
  Future<List<NoteEtudiant>> fetchNotes(String matricule) async {
    final data = await _client
        .from('notes')
        .select()
        .eq('matricule', matricule)
        .order('created_at', ascending: false);
    return (data as List).map((e) => NoteEtudiant.fromJson(e)).toList();
  }

  // ── Supprimer une note ──
  Future<void> supprimerNote(String noteId) async {
    await _client.from('notes').delete().eq('id', noteId);
  }
}
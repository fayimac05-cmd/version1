import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

/// Service Supabase centralisé pour Scholarhub.
/// Fournit CRUD pour les tables : etudiants, profs, parents, notes, events.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  SupabaseService._internal();
  factory SupabaseService() => _instance;

  SupabaseClient get client => Supabase.instance.client;

  // ── Étudiant ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getEtudiant(String matricule) async {
    final data = await client
        .from('etudiants')
        .select()
        .eq('matricule', matricule)
        .maybeSingle();
    return data;
  }

  Future<List<Map<String, dynamic>>> getAllEtudiants() async {
    final data =
        await client.from('etudiants').select().order('nom');
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> updateEtudiant(
      String matricule, Map<String, dynamic> updates) async {
    await client
        .from('etudiants')
        .update(updates)
        .eq('matricule', matricule);
  }

  // ── Inscription Étudiant Supabase ─────────────────────────────────────────

  Future<Map<String, dynamic>> registerEtudiant({
    required String nom,
    required String prenoms,
    required String matricule,
    required String email,
    required String telephone,
    required String filiere,
    required String niveau,
    required String motDePasse,
  }) async {
    // 1. Vérifier si le matricule existe déjà
    final existing = await client
        .from('etudiants')
        .select('matricule')
        .eq('matricule', matricule)
        .maybeSingle();

    if (existing != null) {
      return {'success': false, 'message': 'Ce matricule est déjà inscrit.'};
    }

    // 2. Insérer le nouvel étudiant dans Supabase
    final newStudent = {
      'nom': nom.toUpperCase(),
      'prenoms': prenoms,
      'matricule': matricule,
      'email': email,
      'telephone': telephone,
      'filiere': filiere,
      'niveau': niveau,
      'mot_de_passe': motDePasse,
      'role': 'etudiant',
      'created_at': DateTime.now().toIso8601String(),
    };

    await client.from('etudiants').insert(newStudent);
    return {'success': true, 'user': newStudent};
  }

  // ── Connexion Étudiant Supabase ───────────────────────────────────────────

  Future<Map<String, dynamic>> loginEtudiant({
    required String matricule,
    String? motDePasse,
  }) async {
    final matClean = matricule.toUpperCase();
    Map<String, dynamic>? user;

    // 1. Chercher dans la table 'users'
    try {
      user = await client
          .from('users')
          .select()
          .eq('matricule', matClean)
          .maybeSingle();
    } catch (_) {}

    // 2. Si non trouvé, chercher dans 'etudiants'
    if (user == null) {
      try {
        user = await client
            .from('etudiants')
            .select()
            .eq('matricule', matClean)
            .maybeSingle();
      } catch (_) {}
    }

    if (user == null) {
      return {'success': false, 'message': 'Matricule non reconnu.'};
    }

    final String pwd = (user['mot_de_passe'] ?? user['motDePasse'] ?? user['password'] ?? '').toString();
    final bool hasNoPassword = pwd.trim().isEmpty || pwd == 'null';
    final bool premiereFois = user['premiere_fois'] == true || user['premierefois'] == true || hasNoPassword;

    // Si première connexion / aucun mot de passe défini dans Supabase
    if (premiereFois || hasNoPassword) {
      if (motDePasse == null || motDePasse.trim().isEmpty) {
        return {
          'success': true,
          'isFirstConnection': true,
          'user': user,
          'message': 'Première connexion détectée.'
        };
      }
    }

    // Si un mot de passe existe dans Supabase, il est requis
    if (motDePasse == null || motDePasse.trim().isEmpty) {
      return {'success': false, 'message': 'Veuillez saisir votre mot de passe.'};
    }

    if (pwd != motDePasse) {
      return {'success': false, 'message': 'Mot de passe incorrect.'};
    }

    return {'success': true, 'user': user};
  }

  Future<Map<String, dynamic>> finaliserPremiereConnexion({
    required String matricule,
    required String email,
    required String telephone,
    required String motDePasse,
  }) async {
    final matClean = matricule.toUpperCase();

    // 1. Retrouver l'étudiant pour obtenir son user_id
    final etudiant = await getEtudiant(matClean);
    if (etudiant == null) {
      return {'success': false, 'message': 'Matricule introuvable.'};
    }

    // 2. Mettre à jour la table 'users' (mot de passe + email + tel)
    final userId = etudiant['user_id'];
    if (userId != null) {
      await client
          .from('users')
          .update({
            'mot_de_passe': motDePasse,
            'email': email,
            'tel': telephone,
          })
          .eq('id', userId);
    }

    // 3. Mettre à jour la table 'etudiants' (email + tel + premierefois)
    await client
        .from('etudiants')
        .update({
          'email': email,
          'tel': telephone,
          'premierefois': false,
        })
        .eq('matricule', matClean);

    final user = await getEtudiant(matClean);
    return {'success': true, 'user': user ?? {}};
  }

  // ── Photo de Profil Supabase ──────────────────────────────────────────────

  /// Upload une photo de profil dans le bucket `profile_photos` et retourne son URL publique.
  Future<String> uploadProfilePhoto(File file, String matricule) async {
    final path = 'public/$matricule.jpg';
    await client.storage.from('profile_photos').upload(path, file,
        fileOptions: const FileOptions(upsert: true));
    final url = client.storage.from('profile_photos').getPublicUrl(path);
    // Mettre à jour l'URL de la photo dans la table etudiants
    await updateEtudiant(matricule, {'photo_url': url});
    return url;
  }


  // ── Professeur ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getProf(
      String nom, String prenoms, String telephone) async {
    final data = await client
        .from('profs')
        .select()
        .eq('nom', nom)
        .eq('prenoms', prenoms)
        .eq('telephone', telephone)
        .maybeSingle();
    return data;
  }

  Future<List<Map<String, dynamic>>> getAllProfs() async {
    final data = await client.from('profs').select().order('nom');
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ── Parent ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getParent(
      String nom, String prenoms, String telephone) async {
    final data = await client
        .from('parents')
        .select()
        .eq('nom', nom)
        .eq('prenoms', prenoms)
        .eq('telephone', telephone)
        .maybeSingle();
    return data;
  }

  // ── Notes ─────────────────────────────────────────────────────────────────

  Future<void> insertNote(Map<String, dynamic> note) async {
    await client.from('notes').insert(note);
  }

  Future<List<Map<String, dynamic>>> getNotesByMatricule(
      String matricule) async {
    final data = await client
        .from('notes')
        .select()
        .eq('matricule', matricule)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> deleteNote(String noteId) async {
    await client.from('notes').delete().eq('id', noteId);
  }

  // ── Événements ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getEvents() async {
    final data = await client
        .from('events')
        .select()
        .order('date', ascending: true);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<String> createEvent(Map<String, dynamic> event) async {
    final data = await client
        .from('events')
        .insert(event)
        .select('id')
        .single();
    return data['id'] as String;
  }

  Future<void> updateEvent(
      String eventId, Map<String, dynamic> updates) async {
    await client.from('events').update(updates).eq('id', eventId);
  }

  Future<void> deleteEvent(String eventId) async {
    await client.from('events').delete().eq('id', eventId);
  }

  // ── Upload image (Supabase Storage) ───────────────────────────────────────

  /// Upload une image dans le bucket `event_images` et retourne son URL publique.
  Future<String> uploadEventImage(File file, String fileName) async {
    final path = 'public/$fileName';
    await client.storage.from('event_images').upload(path, file,
        fileOptions: const FileOptions(upsert: true));
    final url =
        client.storage.from('event_images').getPublicUrl(path);
    return url;
  }
}

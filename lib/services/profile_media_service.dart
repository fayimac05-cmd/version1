import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

/// Service centralisé pour la gestion des photos de profil et de couverture,
/// pour tous les rôles (Étudiant, Professeur, Administrateur, Parent).
///
/// ✅ RÉÉCRIT — l'ancienne version passait directement par le client
/// Supabase (RLS bloquant les écritures en silence), ciblait une table
/// 'profs' inexistante (la vraie table s'appelle 'professeurs'), et
/// utilisait le matricule comme clé de cache locale — vide pour les
/// professeurs depuis la refonte du login (connexion par nom+prénom+tél,
/// plus de matricule généré), ce qui faisait partager LA MÊME photo à tous
/// les professeurs sans matricule.
///
/// Désormais : upload via le backend authentifié par JWT (req.user.id,
/// toujours présent, quel que soit le rôle), persistance directe dans
/// users.photo_url / users.cover_url — la même table utilisée partout
/// ailleurs dans l'app. La source de vérité est le serveur : chargée une
/// fois à la connexion (StudentProfile.photoUrl / .coverUrl) et mise à jour
/// localement après chaque upload réussi (voir ProfileHeaderCover).
class ProfileMediaService {
  ProfileMediaService._();
  static final ProfileMediaService instance = ProfileMediaService._();

  final ImagePicker _picker = ImagePicker();

  /// Notifieur global, conservé pour compatibilité avec d'éventuels autres
  /// écrans qui écouteraient un changement de photo (aucun connu à ce jour
  /// en dehors de ProfileHeaderCover, qui gère désormais son propre état
  /// local directement).
  static final ValueNotifier<int> mediaNotifier = ValueNotifier<int>(0);

  void _notifyChange() => mediaNotifier.value++;

  /// Sélecteur d'image cross-platform garanti (ImagePicker avec fallback FilePicker).
  Future<XFile?> _pickImageCrossPlatform(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) return picked;
    } catch (e) {
      debugPrint('[ProfileMediaService] ImagePicker notice ($e), attempting FilePicker fallback...');
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: kIsWeb,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        if (file.path != null && file.path!.isNotEmpty) {
          return XFile(file.path!);
        } else if (file.bytes != null) {
          return XFile.fromData(file.bytes!, name: file.name);
        }
      }
    } catch (e) {
      debugPrint('[ProfileMediaService] FilePicker error: $e');
    }
    return null;
  }

  /// Choisit et envoie une nouvelle photo de profil au backend.
  /// Renvoie la nouvelle URL Cloudinary en cas de succès, ou `null` si
  /// l'utilisateur annule la sélection. Lève une exception en cas d'échec
  /// de l'envoi (à afficher à l'utilisateur par l'appelant).
  Future<String?> pickAndSaveProfilePhoto({ImageSource source = ImageSource.gallery}) async {
    final picked = await _pickImageCrossPlatform(source);
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    final res = await ApiService.uploadPhotoProfil(bytes, picked.name);
    if (res['success'] != true) {
      throw Exception(res['error'] ?? 'Erreur lors de l\'envoi de la photo.');
    }
    _notifyChange();
    return res['url'] as String?;
  }

  /// Choisit et envoie une nouvelle photo de couverture au backend.
  Future<String?> pickAndSaveCoverPhoto({ImageSource source = ImageSource.gallery}) async {
    final picked = await _pickImageCrossPlatform(source);
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    final res = await ApiService.uploadPhotoCouverture(bytes, picked.name);
    if (res['success'] != true) {
      throw Exception(res['error'] ?? 'Erreur lors de l\'envoi de la couverture.');
    }
    _notifyChange();
    return res['url'] as String?;
  }

  /// Supprime la photo de profil côté serveur.
  Future<bool> deleteProfilePhoto() async {
    final res = await ApiService.deletePhotoProfil();
    if (res['success'] == true) _notifyChange();
    return res['success'] == true;
  }

  /// Supprime la photo de couverture côté serveur.
  Future<bool> deleteCoverPhoto() async {
    final res = await ApiService.deletePhotoCouverture();
    if (res['success'] == true) _notifyChange();
    return res['success'] == true;
  }
}
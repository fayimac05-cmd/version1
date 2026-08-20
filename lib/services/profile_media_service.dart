import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service centralisé pour la gestion robuste, persistante en BD et réactive
/// des photos de profil et des photos de couverture pour tous les rôles
/// (Étudiant, Professeur, Administrateur, Parent, etc.) sur Web, Desktop & Mobile.
class ProfileMediaService {
  ProfileMediaService._();
  static final ProfileMediaService instance = ProfileMediaService._();

  final ImagePicker _picker = ImagePicker();

  /// Notifieur global pour rafraîchir instantanément toutes les vues
  /// lors de l'ajout, modification ou suppression d'une photo.
  static final ValueNotifier<int> mediaNotifier = ValueNotifier<int>(0);

  void _notifyChange() {
    mediaNotifier.value++;
  }

  String _cleanKey(String matricule) {
    final mat = matricule.trim();
    if (mat.isEmpty) return 'STUDENT_DEFAULT';
    return mat.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  /// Sélecteur d'image cross-platform garanti (ImagePicker avec fallback FilePicker)
  Future<XFile?> _pickImageCrossPlatform(ImageSource source) async {
    // 1. Tenter avec ImagePicker
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) return picked;
    } catch (e) {
      debugPrint('[ProfileMediaService] ImagePicker notice ($e), attempting FilePicker fallback...');
    }

    // 2. Tenter avec FilePicker (nativement supporté sur Web, Windows Desktop, macOS, Linux)
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

  // ─── GESTION PHOTO DE PROFIL ───────────────────────────────────────────────

  /// Récupère le chemin ou l'URL de la photo de profil sauvegardée pour ce matricule.
  /// Si absente du stockage local, interroge Supabase BD et Storage.
  Future<String?> getProfilePhotoPath(String matricule) async {
    final safeMat = _cleanKey(matricule);
    final key = 'profile_photo_$safeMat';

    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(key);
      if (path != null && path.isNotEmpty) {
        if (kIsWeb ||
            path.startsWith('http://') ||
            path.startsWith('https://') ||
            path.startsWith('data:') ||
            path.startsWith('blob:')) {
          return path;
        }
        if (!kIsWeb) {
          final file = File(path);
          if (await file.exists()) {
            return path;
          }
        }
      }

      // Si non trouvée localement, tenter de récupérer depuis Supabase DB/Storage sans bloquer
      try {
        final remoteUrl = await _fetchRemoteProfilePhotoUrl(safeMat, matricule);
        if (remoteUrl != null && remoteUrl.isNotEmpty) {
          await prefs.setString(key, remoteUrl);
          return remoteUrl;
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('[ProfileMediaService] getProfilePhotoPath error: $e');
    }
    return null;
  }

  /// Choisit et sauvegarde une nouvelle photo de profil (Galerie ou Caméra).
  Future<String?> pickAndSaveProfilePhoto(
    String matricule, {
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final picked = await _pickImageCrossPlatform(source);
      if (picked == null) return null;

      final safeMat = _cleanKey(matricule);
      final bytes = await picked.readAsBytes();
      String savedPathOrUrl;

      if (kIsWeb) {
        final base64Str = base64Encode(bytes);
        final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
        final mime = (ext.toLowerCase() == 'png') ? 'image/png' : 'image/jpeg';
        savedPathOrUrl = 'data:$mime;base64,$base64Str';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final ext = picked.path.contains('.') ? picked.path.split('.').last : 'jpg';
        final targetFile = File(
            '${directory.path}/avatar_${safeMat}_${DateTime.now().millisecondsSinceEpoch}.$ext');

        await targetFile.writeAsBytes(bytes, flush: true);
        savedPathOrUrl = targetFile.path;
      }

      // Sauvegarde locale dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_photo_$safeMat', savedPathOrUrl);

      _notifyChange();

      // Synchronisation Supabase BD et Storage en arrière-plan sans bloquer
      Future.microtask(() => _syncBytesToSupabase(
          'profile_photos', 'public/$safeMat.jpg', bytes, safeMat, matricule, 'photo_url'));

      return savedPathOrUrl;
    } catch (e) {
      debugPrint('[ProfileMediaService] pickAndSaveProfilePhoto error: $e');
      rethrow;
    }
  }

  /// Supprime la photo de profil locale et distante (BD + Supabase Storage).
  Future<bool> deleteProfilePhoto(String matricule) async {
    try {
      final safeMat = _cleanKey(matricule);
      final prefs = await SharedPreferences.getInstance();
      final currentPath = prefs.getString('profile_photo_$safeMat');
      if (currentPath != null && !kIsWeb && !currentPath.startsWith('http') && !currentPath.startsWith('data:')) {
        final file = File(currentPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await prefs.remove('profile_photo_$safeMat');
      _notifyChange();

      // Suppression en Base de Données & Storage Supabase
      Future.microtask(() => _deleteProfilePhotoFromSupabase(safeMat, matricule));

      return true;
    } catch (e) {
      debugPrint('[ProfileMediaService] deleteProfilePhoto error: $e');
      return false;
    }
  }

  // ─── GESTION PHOTO DE COUVERTURE ───────────────────────────────────────────

  /// Récupère le chemin ou l'URL de la bannière de couverture.
  /// Si absente du stockage local, interroge Supabase BD et Storage.
  Future<String?> getCoverPhotoPath(String matricule) async {
    final safeMat = _cleanKey(matricule);
    final key = 'cover_photo_$safeMat';

    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(key);
      if (path != null && path.isNotEmpty) {
        if (kIsWeb ||
            path.startsWith('http://') ||
            path.startsWith('https://') ||
            path.startsWith('data:') ||
            path.startsWith('blob:')) {
          return path;
        }
        if (!kIsWeb) {
          final file = File(path);
          if (await file.exists()) {
            return path;
          }
        }
      }

      // Si non trouvée localement, tenter de récupérer depuis Supabase DB/Storage sans bloquer
      try {
        final remoteUrl = await _fetchRemoteCoverPhotoUrl(safeMat, matricule);
        if (remoteUrl != null && remoteUrl.isNotEmpty) {
          await prefs.setString(key, remoteUrl);
          return remoteUrl;
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('[ProfileMediaService] getCoverPhotoPath error: $e');
    }
    return null;
  }

  /// Choisit et sauvegarde une nouvelle photo de couverture (Galerie ou Caméra).
  Future<String?> pickAndSaveCoverPhoto(
    String matricule, {
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final picked = await _pickImageCrossPlatform(source);
      if (picked == null) return null;

      final safeMat = _cleanKey(matricule);
      final bytes = await picked.readAsBytes();
      String savedPathOrUrl;

      if (kIsWeb) {
        final base64Str = base64Encode(bytes);
        final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
        final mime = (ext.toLowerCase() == 'png') ? 'image/png' : 'image/jpeg';
        savedPathOrUrl = 'data:$mime;base64,$base64Str';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final ext = picked.path.contains('.') ? picked.path.split('.').last : 'jpg';
        final targetFile = File(
            '${directory.path}/cover_${safeMat}_${DateTime.now().millisecondsSinceEpoch}.$ext');

        await targetFile.writeAsBytes(bytes, flush: true);
        savedPathOrUrl = targetFile.path;
      }

      // Sauvegarde dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cover_photo_$safeMat', savedPathOrUrl);

      _notifyChange();

      // Synchronisation Supabase BD et Storage en arrière-plan sans bloquer
      Future.microtask(() => _syncBytesToSupabase(
          'cover_photos', 'covers/$safeMat.jpg', bytes, safeMat, matricule, 'cover_url'));

      return savedPathOrUrl;
    } catch (e) {
      debugPrint('[ProfileMediaService] pickAndSaveCoverPhoto error: $e');
      rethrow;
    }
  }

  /// Supprime la photo de couverture locale et distante (BD + Supabase Storage).
  Future<bool> deleteCoverPhoto(String matricule) async {
    try {
      final safeMat = _cleanKey(matricule);
      final prefs = await SharedPreferences.getInstance();
      final currentPath = prefs.getString('cover_photo_$safeMat');
      if (currentPath != null && !kIsWeb && !currentPath.startsWith('http') && !currentPath.startsWith('data:')) {
        final file = File(currentPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await prefs.remove('cover_photo_$safeMat');
      _notifyChange();

      // Suppression en Base de Données & Storage Supabase
      Future.microtask(() => _deleteCoverPhotoFromSupabase(safeMat, matricule));

      return true;
    } catch (e) {
      debugPrint('[ProfileMediaService] deleteCoverPhoto error: $e');
      return false;
    }
  }

  // ─── SYNCHRONISATION & RÉCUPÉRATION SUPABASE ───────────────────────────────

  Future<String?> _fetchRemoteProfilePhotoUrl(
      String safeMat, String rawMatricule) async {
    try {
      final client = Supabase.instance.client;
      final searchMat = rawMatricule.isEmpty ? safeMat : rawMatricule;

      // 1. Chercher dans les tables 'etudiants', 'users', 'profs', 'parents'
      for (final table in ['etudiants', 'users', 'profs', 'parents']) {
        try {
          final res = await client
              .from(table)
              .select('photo_url, avatar_url')
              .or('matricule.eq.$searchMat,matricule.eq.$safeMat')
              .maybeSingle();
          if (res != null) {
            final url = (res['photo_url'] ?? res['avatar_url'])?.toString();
            if (url != null && url.isNotEmpty) return url;
          }
        } catch (_) {}
      }

      // 2. Vérifier si le fichier existe réellement dans le bucket Supabase Storage
      try {
        final list = await client.storage.from('profile_photos').list(path: 'public');
        final targetName = '$safeMat.jpg';
        final exists = list.any((item) => item.name == targetName);
        if (exists) {
          final path = 'public/$targetName';
          return client.storage.from('profile_photos').getPublicUrl(path);
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('[ProfileMediaService] _fetchRemoteProfilePhotoUrl error: $e');
    }
    return null;
  }

  Future<String?> _fetchRemoteCoverPhotoUrl(
      String safeMat, String rawMatricule) async {
    try {
      final client = Supabase.instance.client;
      final searchMat = rawMatricule.isEmpty ? safeMat : rawMatricule;

      // 1. Chercher dans les tables 'etudiants', 'users', 'profs', 'parents'
      for (final table in ['etudiants', 'users', 'profs', 'parents']) {
        try {
          final res = await client
              .from(table)
              .select('cover_url')
              .or('matricule.eq.$searchMat,matricule.eq.$safeMat')
              .maybeSingle();
          if (res != null) {
            final url = res['cover_url']?.toString();
            if (url != null && url.isNotEmpty) return url;
          }
        } catch (_) {}
      }

      // 2. Vérifier si le fichier existe réellement dans le bucket Supabase Storage
      try {
        final list = await client.storage.from('cover_photos').list(path: 'covers');
        final targetName = '$safeMat.jpg';
        final exists = list.any((item) => item.name == targetName);
        if (exists) {
          final path = 'covers/$targetName';
          return client.storage.from('cover_photos').getPublicUrl(path);
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('[ProfileMediaService] _fetchRemoteCoverPhotoUrl error: $e');
    }
    return null;
  }

  Future<void> _syncBytesToSupabase(
      String bucket, String path, Uint8List bytes, String safeMat, String rawMatricule, String dbColumn) async {
    try {
      final client = Supabase.instance.client;
      await client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );

      final url = client.storage.from(bucket).getPublicUrl(path);

      final prefs = await SharedPreferences.getInstance();
      final currentKey = dbColumn == 'photo_url' ? 'profile_photo_$safeMat' : 'cover_photo_$safeMat';
      final currentVal = prefs.getString(currentKey);
      if (currentVal == null || currentVal.startsWith('data:')) {
        await prefs.setString(currentKey, url);
      }

      final searchMat = rawMatricule.isEmpty ? safeMat : rawMatricule;
      for (final table in ['etudiants', 'profs', 'parents', 'users']) {
        try {
          await client
              .from(table)
              .update({dbColumn: url})
              .or('matricule.eq.$searchMat,matricule.eq.$safeMat');
        } catch (_) {}
      }

      _notifyChange();
    } catch (e) {
      debugPrint('[ProfileMediaService] _syncBytesToSupabase notice: $e');
    }
  }

  Future<void> _deleteProfilePhotoFromSupabase(
      String safeMat, String rawMatricule) async {
    try {
      final client = Supabase.instance.client;
      await client.storage.from('profile_photos').remove(['public/$safeMat.jpg']);

      final searchMat = rawMatricule.isEmpty ? safeMat : rawMatricule;
      for (final table in ['etudiants', 'profs', 'parents', 'users']) {
        try {
          await client
              .from(table)
              .update({'photo_url': null})
              .or('matricule.eq.$searchMat,matricule.eq.$safeMat');
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[ProfileMediaService] _deleteProfilePhotoFromSupabase notice: $e');
    }
  }

  Future<void> _deleteCoverPhotoFromSupabase(
      String safeMat, String rawMatricule) async {
    try {
      final client = Supabase.instance.client;
      await client.storage.from('cover_photos').remove(['covers/$safeMat.jpg']);

      final searchMat = rawMatricule.isEmpty ? safeMat : rawMatricule;
      for (final table in ['etudiants', 'profs', 'parents', 'users']) {
        try {
          await client
              .from(table)
              .update({'cover_url': null})
              .or('matricule.eq.$searchMat,matricule.eq.$safeMat');
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[ProfileMediaService] _deleteCoverPhotoFromSupabase notice: $e');
    }
  }
}

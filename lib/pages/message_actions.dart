import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'video_message.dart';

// ════════════════════════════════════════════════════════════════════════
// ACTIONS COMMUNES AUX MESSAGES (canaux, groupes, admin)
//  • lireFichierMessage / estTelechargeable : analyse d'un "[FICHIER]type|url|nom"
//  • telechargerMessage    : télécharge l'image / vidéo / document / audio
//  • texteAPartager        : texte lisible à copier / partager (nom + lien)
//  • preparerFichiersMessage : sélection MULTIPLE + envoi (upload) des fichiers,
//                              renvoie la liste des contenus "[FICHIER]…" à poster
// ════════════════════════════════════════════════════════════════════════

const int kMaxFichiersParEnvoi = 10;

class FichierMessage {
  const FichierMessage(this.type, this.url, this.nom);
  final String type;
  final String url;
  final String nom;
}

FichierMessage? lireFichierMessage(String contenu) {
  if (!contenu.startsWith('[FICHIER]')) return null;
  final parts = contenu.substring(9).split('|');
  if (parts.length < 2 || parts[1].isEmpty) return null;
  final nom = parts.length > 2 ? parts.sublist(2).join('|') : 'Fichier';
  return FichierMessage(parts[0], parts[1], nom);
}

bool estTelechargeable(String contenu) => lireFichierMessage(contenu) != null;

Future<void> telechargerMessage(BuildContext context, String contenu) async {
  final f = lireFichierMessage(contenu);
  if (f == null) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('Téléchargement de ${f.nom}…'),
    duration: const Duration(seconds: 2),
  ));
  await ouvrirFichier(context, f.url, telecharger: true);
}

/// Texte lisible d'un message : pour un fichier → « nom + lien », pour un GIF → le lien.
String texteAPartager(String contenu) {
  final f = lireFichierMessage(contenu);
  if (f != null) return '${f.nom}\n${f.url}';
  if (contenu.startsWith('[GIF]')) return contenu.substring(5);
  return contenu;
}

class _FichierChoisi {
  _FichierChoisi(this.bytes, this.nom, this.type);
  final List<int> bytes;
  final String nom;
  final String type;
}

const _extVideo = ['mp4', 'mov', 'avi', 'mkv', '3gp', 'webm'];

String _typeDepuisNom(String nom) {
  final ext = nom.contains('.') ? nom.split('.').last.toLowerCase() : '';
  return _extVideo.contains(ext) ? 'video' : 'image';
}

/// Ouvre le sélecteur (plusieurs fichiers possibles, sauf caméra), téléverse chaque
/// fichier puis renvoie les contenus "[FICHIER]type|url|nom" prêts à être postés.
/// Liste vide si annulation ou échec total.
Future<List<String>> preparerFichiersMessage(BuildContext context, String categorie) async {
  final messenger = ScaffoldMessenger.of(context);
  final choisis = <_FichierChoisi>[];
  try {
    if (categorie == 'camera') {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );
      if (picked == null) return [];
      choisis.add(_FichierChoisi(await picked.readAsBytes(), picked.name, 'image'));
    } else {
      final FilePickerResult? result;
      if (categorie == 'media') {
        result = await FilePicker.platform.pickFiles(type: FileType.media, allowMultiple: true, withData: true);
      } else if (categorie == 'audio') {
        result = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true, withData: true);
      } else {
        result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);
      }
      if (result == null || result.files.isEmpty) return [];
      var fichiers = result.files;
      if (fichiers.length > kMaxFichiersParEnvoi) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Maximum $kMaxFichiersParEnvoi fichiers à la fois : les premiers seront envoyés.'),
        ));
        fichiers = fichiers.take(kMaxFichiersParEnvoi).toList();
      }
      for (final f in fichiers) {
        final bytes = f.bytes;
        if (bytes == null || bytes.isEmpty) continue;
        final type = categorie == 'media'
            ? _typeDepuisNom(f.name)
            : (categorie == 'audio' ? 'audio' : 'document');
        choisis.add(_FichierChoisi(bytes, f.name, type));
      }
    }
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text('Erreur lors de la sélection du fichier.')));
    return [];
  }
  if (choisis.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text('Impossible de lire le fichier sélectionné.')));
    return [];
  }

  final contenus = <String>[];
  var echecs = 0;
  String? derniereErreur;
  for (var i = 0; i < choisis.length; i++) {
    final f = choisis[i];
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(choisis.length == 1
          ? 'Envoi en cours…'
          : 'Envoi ${i + 1}/${choisis.length} : ${f.nom}'),
      duration: const Duration(seconds: 60),
    ));
    final upload = await ApiService.uploaderFichierMessage(f.bytes, f.nom);
    if (upload['success'] == true && upload['url'] != null) {
      contenus.add('[FICHIER]${f.type}|${upload['url']}|${f.nom}');
    } else {
      echecs++;
      derniereErreur = upload['error']?.toString();
    }
  }
  messenger.hideCurrentSnackBar();
  if (echecs > 0) {
    messenger.showSnackBar(SnackBar(
      content: Text(echecs == choisis.length
          ? (derniereErreur ?? 'Échec de l\'envoi du fichier.')
          : '$echecs fichier(s) non envoyé(s) sur ${choisis.length}.'),
    ));
  }
  return contenus;
}

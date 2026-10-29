import 'dart:convert';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Appels ajoutés avec la gestion du logo et des mots de passe.
class ApiExtra {
  ApiExtra._();

  /// Change le mot de passe du compte connecté (ancien mot de passe exigé).
  static Future<Map<String, dynamic>> changerMotDePasse(String ancien, String nouveau) async {
    try {
      final headers = await ApiService.getHeaders();
      final r = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/change-password'),
        headers: headers,
        body: jsonEncode({'ancienMotDePasse': ancien, 'nouveauMotDePasse': nouveau}),
      );
      final body = r.body.isEmpty ? {} : jsonDecode(utf8.decode(r.bodyBytes));
      if (r.statusCode == 200) return {'success': true};
      return {'success': false, 'error': (body is Map ? body['message'] : null) ?? 'Changement impossible.'};
    } catch (_) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  // ── Photo d'accueil (page de bienvenue après le code de l'établissement) ──
  static Future<String> getPhotoAccueil() async {
    try {
      final headers = await ApiService.getHeaders();
      final r = await http.get(Uri.parse('${ApiService.baseUrl}/upload/photo-accueil'), headers: headers);
      if (r.statusCode == 200) return (jsonDecode(utf8.decode(r.bodyBytes))['url'] ?? '').toString();
    } catch (_) {}
    return '';
  }

  static Future<Map<String, dynamic>> uploadPhotoAccueil(List<int> bytes, String filename) async {
    try {
      final token = await ApiService.getToken();
      final request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/upload/photo-accueil'));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      final response = await http.Response.fromStream(await request.send());
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) return {'success': true, 'url': body['url']};
      return {'success': false, 'error': body['message'] ?? "Erreur lors de l'envoi de la photo."};
    } catch (_) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<bool> supprimerPhotoAccueil() async {
    try {
      final headers = await ApiService.getHeaders();
      final r = await http.delete(Uri.parse('${ApiService.baseUrl}/upload/photo-accueil'), headers: headers);
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Administration : efface le mot de passe d'un étudiant ([id] = id de la table etudiants).
  static Future<Map<String, dynamic>> reinitialiserMotDePasseEtudiant(String id) =>
      _reinitialiser('etudiants', id);

  /// Administration : efface le mot de passe d'un professeur.
  static Future<Map<String, dynamic>> reinitialiserMotDePasseProfesseur(String id) =>
      _reinitialiser('professeurs', id);

  static Future<Map<String, dynamic>> _reinitialiser(String ressource, String id) async {
    try {
      final headers = await ApiService.getHeaders();
      final r = await http.post(
        Uri.parse('${ApiService.baseUrl}/$ressource/$id/reinitialiser-mdp'),
        headers: headers,
      );
      final body = r.body.isEmpty ? {} : jsonDecode(utf8.decode(r.bodyBytes));
      if (r.statusCode == 200) return {'success': true, 'message': body['message']};
      return {'success': false, 'error': (body is Map ? body['message'] : null) ?? 'Réinitialisation impossible.'};
    } catch (_) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  /// Super Admin : efface le mot de passe d'un membre. Il en choisira un nouveau
  /// à sa prochaine connexion (comme à sa première connexion).
  static Future<Map<String, dynamic>> reinitialiserMotDePasseMembre(String id) async {
    try {
      final headers = await ApiService.getHeaders();
      final r = await http.post(
        Uri.parse('${ApiService.baseUrl}/membres/$id/reinitialiser-mdp'),
        headers: headers,
      );
      final body = r.body.isEmpty ? {} : jsonDecode(utf8.decode(r.bodyBytes));
      if (r.statusCode == 200) return {'success': true, 'message': body['message']};
      return {'success': false, 'error': (body is Map ? body['message'] : null) ?? 'Réinitialisation impossible.'};
    } catch (_) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }
}

/// Fenêtre « Changer mon mot de passe ».
/// [ancien] : si l'ancien mot de passe est déjà connu (première connexion), on ne le redemande pas.
/// [obligatoire] : impossible à fermer tant que le mot de passe n'est pas changé.
/// Renvoie true si le mot de passe a été changé.
Future<bool> afficherChangementMotDePasse(
  BuildContext context, {
  String? ancien,
  bool obligatoire = false,
}) async {
  final ancienCtrl = TextEditingController();
  final nouveauCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  String? erreur;
  bool envoi = false;
  bool voir = false;

  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: !obligatoire,
    builder: (ctx) => PopScope(
      canPop: !obligatoire,
      child: StatefulBuilder(builder: (ctx, setS) {
        Future<void> valider() async {
          final anc = ancien ?? ancienCtrl.text;
          if (anc.isEmpty) { setS(() => erreur = "Saisissez votre mot de passe actuel."); return; }
          if (nouveauCtrl.text.length < 8) { setS(() => erreur = 'Le nouveau mot de passe doit contenir au moins 8 caractères.'); return; }
          if (nouveauCtrl.text != confirmCtrl.text) { setS(() => erreur = 'Les deux mots de passe ne correspondent pas.'); return; }
          if (nouveauCtrl.text == anc) { setS(() => erreur = "Le nouveau mot de passe doit être différent de l'ancien."); return; }
          setS(() { envoi = true; erreur = null; });
          final r = await ApiExtra.changerMotDePasse(anc, nouveauCtrl.text);
          if (r['success'] == true) {
            if (ctx.mounted) Navigator.of(ctx).pop(true);
          } else {
            setS(() { envoi = false; erreur = r['error']?.toString() ?? 'Erreur.'; });
          }
        }

        InputDecoration deco(String label) => InputDecoration(
              labelText: label,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            );

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(obligatoire ? 'Choisissez votre mot de passe' : 'Changer mon mot de passe',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (obligatoire)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Votre mot de passe actuel est provisoire. Remplacez-le par un mot de passe que vous seul connaissez pour continuer.',
                      style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.45),
                    ),
                  ),
                if (ancien == null) ...[
                  TextField(controller: ancienCtrl, obscureText: !voir, decoration: deco('Mot de passe actuel')),
                  const SizedBox(height: 12),
                ],
                TextField(controller: nouveauCtrl, obscureText: !voir, decoration: deco('Nouveau mot de passe (8 caractères min.)')),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  obscureText: !voir,
                  decoration: deco('Confirmer le nouveau mot de passe'),
                  onSubmitted: (_) { if (!envoi) valider(); },
                ),
                Row(children: [
                  Checkbox(value: voir, onChanged: (v) => setS(() => voir = v == true)),
                  const Text('Afficher les mots de passe', style: TextStyle(fontSize: 13)),
                ]),
                if (erreur != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
                    child: Text(erreur!, style: const TextStyle(color: Color(0xFFC62828), fontSize: 13)),
                  ),
              ]),
            ),
          ),
          actions: [
            if (!obligatoire)
              TextButton(onPressed: envoi ? null : () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: envoi ? null : valider,
              child: envoi
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Enregistrer'),
            ),
          ],
        );
      }),
    ),
  );
  ancienCtrl.dispose();
  nouveauCtrl.dispose();
  confirmCtrl.dispose();
  return ok == true;
}


/// Fenêtre de recadrage : l'utilisateur déplace / redimensionne le cadre, choisit un format,
/// puis valide. Renvoie l'image recadrée (PNG), ou null s'il annule.
Future<Uint8List?> afficherRecadrage(
  BuildContext context,
  Uint8List image, {
  String titre = "Recadrer l'image",
  List<MapEntry<String, double?>>? formats,
  double? formatInitial,
}) async {
  final choix = formats ??
      const [
        MapEntry('Libre', null),
        MapEntry('16:9', 16 / 9),
        MapEntry('4:3', 4 / 3),
        MapEntry('1:1', 1.0),
      ];
  double? ratio = formatInitial;
  var controller = CropController();
  bool envoi = false;
  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      final taille = MediaQuery.of(ctx).size;
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: taille.width > 860 ? 820 : taille.width - 32,
          height: taille.height * 0.86,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titre, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text("Déplacez et ajustez le cadre : seule la partie dans le cadre sera enregistrée.",
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                for (final f in choix)
                  ChoiceChip(
                    label: Text(f.key),
                    selected: ratio == f.value,
                    onSelected: envoi
                        ? null
                        : (_) => setS(() {
                              ratio = f.value;
                              controller = CropController(); // le cadre repart avec le nouveau format
                            }),
                  ),
              ]),
              const SizedBox(height: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Crop(
                    key: ValueKey(ratio),
                    image: image,
                    controller: controller,
                    aspectRatio: ratio,
                    baseColor: const Color(0xFF0F172A),
                    maskColor: Colors.black.withAlpha(120),
                    onCropped: (result) {
                      switch (result) {
                        case CropSuccess(:final croppedImage):
                          if (ctx.mounted) Navigator.of(ctx).pop(croppedImage);
                        case CropFailure():
                          debugPrint('Recadrage impossible.');
                          setS(() => envoi = false);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                  onPressed: envoi ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: envoi
                      ? null
                      : () {
                          setS(() => envoi = true);
                          controller.crop();
                        },
                  child: envoi
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Valider'),
                ),
              ]),
            ]),
          ),
        ),
      );
    }),
  );
}
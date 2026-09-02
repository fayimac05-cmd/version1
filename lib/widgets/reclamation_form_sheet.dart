import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';

class BulletinReclamationContext {
  final String universite;
  final String filiere;
  final String domaine;
  final String semestre;
  final String annee;
  final double moyenneGenerale;
  final List<Map<String, dynamic>> matieres;

  const BulletinReclamationContext({
    required this.universite,
    required this.filiere,
    required this.domaine,
    required this.semestre,
    required this.annee,
    required this.moyenneGenerale,
    required this.matieres,
  });
}

void showBulletinReclamationSheet(
  BuildContext context, {
  required BulletinReclamationContext bulletin,
  Map<String, dynamic>? matierePrefill,
  bool contestMoyenne = false,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BulletinReclamationSheet(
      bulletin: bulletin,
      matierePrefill: matierePrefill,
      contestMoyenne: contestMoyenne,
    ),
  );
}

class _BulletinReclamationSheet extends StatefulWidget {
  final BulletinReclamationContext bulletin;
  final Map<String, dynamic>? matierePrefill;
  final bool contestMoyenne;

  const _BulletinReclamationSheet({
    required this.bulletin,
    this.matierePrefill,
    this.contestMoyenne = false,
  });

  @override
  State<_BulletinReclamationSheet> createState() => _BulletinReclamationSheetState();
}

class _BulletinReclamationSheetState extends State<_BulletinReclamationSheet> {
  String? _moduleNom;
  String? _typeNote;
  final _partiesCtrl = TextEditingController();
  final _justifCtrl = TextEditingController();
  final Set<String> _modulesContestes = {};
  bool _loading = false;
  bool _envoye = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final _types = [
    'Devoir sur table',
    'Travaux Pratiques (TP)',
    'Examen partiel',
    'Examen final',
  ];

  bool get _isMoyenne => widget.contestMoyenne;

  @override
  void initState() {
    super.initState();
    if (widget.matierePrefill != null) {
      _moduleNom = widget.matierePrefill!['nom'] as String?;
    }
  }

  @override
  void dispose() {
    _partiesCtrl.dispose();
    _justifCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) setState(() => _imageFile = File(picked.path));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erreur lors de la sélection de l\'image'),
          backgroundColor: Color(0xFFC62828),
        ));
      }
    }
  }

  void _pickImageSource() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF15803D)),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppPalette.blue),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _envoyer() async {
    if (_isMoyenne) {
      if (_modulesContestes.isEmpty || _justifCtrl.text.trim().isEmpty) {
        _erreur('Sélectionnez au moins un module et ajoutez une justification.');
        return;
      }
    } else {
      if (_moduleNom == null ||
          _typeNote == null ||
          _partiesCtrl.text.trim().isEmpty ||
          _justifCtrl.text.trim().isEmpty) {
        _erreur('Veuillez remplir tous les champs obligatoires.');
        return;
      }
    }

    setState(() => _loading = true);

    String? photoUrl;
    if (_imageFile != null) {
      final upload = await ApiService.uploadCopieExamen(_imageFile!);
      if (!upload['success']) {
        setState(() => _loading = false);
        _erreur(upload['error'] ?? 'Erreur upload pièce jointe.');
        return;
      }
      photoUrl = upload['url'] as String?;
    }

    final Map<String, dynamic> result;
    if (_isMoyenne) {
      final modules = widget.bulletin.matieres
          .where((m) => _modulesContestes.contains(m['nom']))
          .map((m) => {'nom': m['nom'], 'note': m['note']})
          .toList();
      result = await ApiService.creerReclamation(
        type: 'moyenne',
        justification: _justifCtrl.text.trim(),
        semestre: widget.bulletin.semestre,
        annee: widget.bulletin.annee,
        filiere: widget.bulletin.filiere,
        noteActuelle: widget.bulletin.moyenneGenerale,
        modulesContestes: modules,
        photoUrl: photoUrl,
      );
    } else {
      final mat = widget.bulletin.matieres.firstWhere(
        (m) => m['nom'] == _moduleNom,
        orElse: () => {'note': null},
      );
      result = await ApiService.creerReclamation(
        type: 'note',
        moduleNom: _moduleNom,
        typeEval: _typeNote,
        partiesContestees: _partiesCtrl.text.trim(),
        justification: _justifCtrl.text.trim(),
        noteActuelle: (mat['note'] as num?)?.toDouble(),
        semestre: widget.bulletin.semestre,
        annee: widget.bulletin.annee,
        filiere: widget.bulletin.filiere,
        photoUrl: photoUrl,
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      setState(() => _envoye = true);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.of(context).pop();
    } else {
      _erreur(result['error'] ?? 'Erreur lors de l\'envoi.');
    }
  }

  void _erreur(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFC62828),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.bulletin;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: _envoye ? _confirmation() : _form(b),
      ),
    );
  }

  Widget _form(BulletinReclamationContext b) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isMoyenne ? 'Contester ma moyenne' : 'Réclamation de note',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Votre réclamation sera transmise à l\'administration.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppPalette.blue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppPalette.blue.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                _infoLigne('Établissement', b.universite),
                const SizedBox(height: 8),
                _infoLigne('Filière', b.filiere),
                const SizedBox(height: 8),
                _infoLigne('Semestre', b.semestre),
                const SizedBox(height: 8),
                _infoLigne('Année', b.annee),
                if (!_isMoyenne && _moduleNom != null) ...[
                  const SizedBox(height: 8),
                  _infoLigne('Module', _moduleNom!),
                ],
                if (_isMoyenne) ...[
                  const SizedBox(height: 8),
                  _infoLigne('Moyenne', '${b.moyenneGenerale.toStringAsFixed(2)} / 20'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_isMoyenne) ...[
            _lbl('Modules contestés *'),
            ...b.matieres.map((m) {
              final nom = m['nom'] as String;
              final sel = _modulesContestes.contains(nom);
              return GestureDetector(
                onTap: () => setState(() {
                  if (sel) {
                    _modulesContestes.remove(nom);
                  } else {
                    _modulesContestes.add(nom);
                  }
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sel ? AppPalette.lightBlue : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? AppPalette.blue : const Color(0xFFE2E8F0),
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        sel ? Icons.check_circle : Icons.circle_outlined,
                        color: sel ? AppPalette.blue : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(nom, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      Text(
                        '${(m['note'] as num).toStringAsFixed(1)} / 20',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ] else ...[
            if (widget.matierePrefill == null) ...[
              _lbl('Module concerné *'),
              DropdownButtonFormField<String>(
                initialValue: _moduleNom,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: b.matieres
                    .map((m) => DropdownMenuItem(
                          value: m['nom'] as String,
                          child: Text(m['nom'] as String, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _moduleNom = v),
              ),
              const SizedBox(height: 18),
            ],
            _lbl('Type de note *'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((t) {
                final sel = _typeNote == t;
                return GestureDetector(
                  onTap: () => setState(() => _typeNote = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppPalette.blue : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? AppPalette.blue : const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            _lbl('Parties contestées *'),
            _champ(_partiesCtrl, 'Ex: Question 3 et 4, exercice 2...', maxLines: 2),
          ],
          const SizedBox(height: 18),
          _lbl('Justification *'),
          _champ(
            _justifCtrl,
            _isMoyenne
                ? 'Pourquoi contestez-vous cette moyenne ?'
                : 'Pourquoi pensez-vous que la note est incorrecte ?',
            maxLines: 3,
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _pickImageSource,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_imageFile!, width: 40, height: 40, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.attach_file, color: Color(0xFF64748B), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _imageFile != null ? 'Pièce jointe sélectionnée' : 'Pièce jointe (optionnel)',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _envoyer,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text(
                _loading ? 'Envoi en cours...' : 'Envoyer la réclamation',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _confirmation() => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1DB954)),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Réclamation envoyée !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            const Text(
              'Votre réclamation a été transmise à l\'administration.\nVous serez notifié de la réponse.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.55),
            ),
          ],
        ),
      );

  Widget _infoLigne(String lbl, String val) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(lbl, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      );
}

Widget _lbl(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
      ),
    );

Widget _champ(TextEditingController ctrl, String hint, {int maxLines = 1}) => Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );

BulletinReclamationContext bulletinContextFromMap(Map<String, dynamic> b) {
  return BulletinReclamationContext(
    universite: b['universite']?.toString() ?? '',
    filiere: b['filiere']?.toString() ?? '',
    domaine: b['domaine']?.toString() ?? '',
    semestre: b['semestre']?.toString() ?? '',
    annee: b['annee']?.toString() ?? '',
    moyenneGenerale: (b['moyenne_generale'] as num?)?.toDouble() ?? 0,
    matieres: List<Map<String, dynamic>>.from(b['matieres'] as List? ?? []),
  );
}

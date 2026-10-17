import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';

/// Formulaire de contestation (note, moyenne ou absence) — ouvert en fenêtre
/// modale depuis l'endroit concerné (ex. "Contester cette note" sur une
/// carte de MesNotesPage). Pré-rempli avec ce qu'on sait déjà côté client ;
/// seule la justification est obligatoire à saisir.
class ReclamationFormSheet extends StatefulWidget {
  const ReclamationFormSheet({
    super.key,
    required this.type,
    this.moduleId,
    this.moduleNom,
    this.noteActuelle,
    this.semestre,
    this.annee,
  });

  final String type; // 'note' | 'moyenne' | 'absence'
  final String? moduleId;
  final String? moduleNom;
  final double? noteActuelle;
  final String? semestre;
  final String? annee;

  @override
  State<ReclamationFormSheet> createState() => _ReclamationFormSheetState();
}

class _ReclamationFormSheetState extends State<ReclamationFormSheet> {
  final _partiesCtrl = TextEditingController();
  final _typeEvalCtrl = TextEditingController();
  final _justificationCtrl = TextEditingController();
  bool _envoi = false;

  @override
  void dispose() {
    _partiesCtrl.dispose();
    _typeEvalCtrl.dispose();
    _justificationCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (_justificationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ La justification est obligatoire.'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    setState(() => _envoi = true);
    final result = await ApiService.creerReclamation(
      moduleId: widget.moduleId ?? '',
      moduleNom: widget.moduleNom ?? '',
      type: widget.type,
      typeEval: _typeEvalCtrl.text.trim().isEmpty ? null : _typeEvalCtrl.text.trim(),
      noteActuelle: widget.noteActuelle,
      semestre: widget.semestre,
      annee: widget.annee,
      partiesContestees: _partiesCtrl.text.trim().isEmpty ? null : _partiesCtrl.text.trim(),
      justification: _justificationCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _envoi = false);
    if (result['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Réclamation envoyée à l\'administration.'), backgroundColor: Color(0xFF10B981)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error']?.toString() ?? 'Erreur lors de l\'envoi.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              const Icon(Icons.flag_outlined, color: Color(0xFFB45309)),
              const SizedBox(width: 10),
              const Expanded(child: Text('Contester une note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (widget.moduleNom != null && widget.moduleNom!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.moduleNom!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppPalette.blue)),
                      if (widget.noteActuelle != null)
                        Text('Note actuelle : ${widget.noteActuelle}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      if (widget.semestre != null)
                        Text(widget.semestre!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _typeEvalCtrl,
                  decoration: InputDecoration(
                    labelText: 'Type d\'évaluation (optionnel)',
                    hintText: 'Ex. Examen final, TD2...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _partiesCtrl,
                  decoration: InputDecoration(
                    labelText: 'Parties contestées (optionnel)',
                    hintText: 'Ex. Exercice 2 et 3',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _justificationCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Justification *',
                    hintText: 'Expliquez pourquoi vous contestez cette note...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _envoi ? null : _envoyer,
                    icon: _envoi
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    label: const Text('Envoyer la réclamation', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppPalette.blue, padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';

/// Formulaire d'évaluation d'UN professeur — 4 critères notés par étoiles
/// (1 à 5) + commentaire libre optionnel. Anonyme pour l'administration :
/// seul le blocage des votes multiples utilise l'identité de l'étudiant,
/// jamais affichée aux résultats.
class EvaluationProfFormSheet extends StatefulWidget {
  const EvaluationProfFormSheet({
    super.key,
    required this.periodeId,
    required this.professeurId,
    required this.professeurNom,
    required this.onSoumis,
  });

  final String periodeId;
  final String professeurId;
  final String professeurNom;
  final VoidCallback onSoumis;

  @override
  State<EvaluationProfFormSheet> createState() => _EvaluationProfFormSheetState();
}

class _EvaluationProfFormSheetState extends State<EvaluationProfFormSheet> {
  static const _criteres = [
    ('pedagogie', 'Pédagogie'),
    ('ponctualite', 'Ponctualité'),
    ('disponibilite', 'Disponibilité'),
    ('clarte', 'Clarté des explications'),
  ];

  final Map<String, int> _notes = {};
  final _commentaireCtrl = TextEditingController();
  bool _envoi = false;

  @override
  void dispose() {
    _commentaireCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    for (final c in _criteres) {
      if (!_notes.containsKey(c.$1)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Notez tous les critères avant d\'envoyer.'), backgroundColor: Colors.redAccent),
        );
        return;
      }
    }
    setState(() => _envoi = true);
    final result = await ApiService.soumettreEvaluationProf(
      periodeId: widget.periodeId,
      professeurId: widget.professeurId,
      criteres: _notes,
      commentaire: _commentaireCtrl.text.trim().isEmpty ? null : _commentaireCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _envoi = false);
    if (result['success'] == true) {
      Navigator.pop(context);
      widget.onSoumis();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Merci ! Votre évaluation a été envoyée anonymement.'), backgroundColor: Color(0xFF10B981)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error']?.toString() ?? 'Erreur lors de l\'envoi.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Widget _etoiles(String cle) {
    final valeur = _notes[cle] ?? 0;
    return Row(
      children: List.generate(5, (i) {
        final n = i + 1;
        return GestureDetector(
          onTap: () => setState(() => _notes[cle] = n),
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              n <= valeur ? Icons.star_rounded : Icons.star_border_rounded,
              color: const Color(0xFFF59E0B),
              size: 30,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              const Icon(Icons.rate_review_outlined, color: AppPalette.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Évaluer', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                  Text(widget.professeurNom, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ]),
              ),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                  child: const Row(children: [
                    Icon(Icons.shield_outlined, size: 16, color: AppPalette.blue),
                    SizedBox(width: 8),
                    Expanded(child: Text('Votre réponse est anonyme — l\'administration ne verra que la moyenne globale.', style: TextStyle(fontSize: 11.5, color: AppPalette.blue))),
                  ]),
                ),
                const SizedBox(height: 20),
                ..._criteres.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.$2, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        _etoiles(c.$1),
                      ]),
                    )),
                const SizedBox(height: 6),
                TextField(
                  controller: _commentaireCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Commentaire (optionnel)',
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
                    label: const Text('Envoyer mon évaluation', style: TextStyle(color: Colors.white)),
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

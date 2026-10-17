import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../services/api_service.dart';

/// Partie 1 — "Prévision de moyenne" : un tableau PAR ÉTUDIANT (pas un seul
/// grand tableau partagé), listant chaque module de son semestre en ligne,
/// avec ses notes réelles (autant qu'il y en a — pas de colonnes "Note 1/2/3"
/// vides si un module n'a qu'un seul devoir) et sa moyenne simple, sans
/// coefficient. Lecture seule.
class AdminPrevisionMoyenne extends StatefulWidget {
  const AdminPrevisionMoyenne({
    super.key,
    required this.filiereId,
    required this.niveau,
    required this.semestre,
    required this.anneeAcademique,
  });

  final String filiereId;
  final String niveau;
  final String semestre;
  final String anneeAcademique;

  @override
  State<AdminPrevisionMoyenne> createState() => _AdminPrevisionMoyenneState();
}

class _AdminPrevisionMoyenneState extends State<AdminPrevisionMoyenne> {
  bool _loading = true;
  bool _envoi = false;
  String? _erreur;
  List<dynamic> _etudiants = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _erreur = null; });
    final result = await ApiService.getPrevisionMoyenne(
      filiereId: widget.filiereId,
      niveau: widget.niveau,
      semestre: widget.semestre,
      anneeAcademique: widget.anneeAcademique,
    );
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        _etudiants = data['etudiants'] as List<dynamic>;
      } else {
        _erreur = result['error']?.toString() ?? 'Erreur lors du chargement.';
      }
      _loading = false;
    });
  }

  Future<void> _envoyerAuxEtudiants() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Envoyer la prévision', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          'Les étudiants de ce groupe seront notifiés et pourront consulter leurs moyennes par module (sans coefficient) — ce n\'est pas le bulletin final, elle continuera d\'évoluer avec les nouvelles notes.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    setState(() => _envoi = true);
    final result = await ApiService.envoyerPrevision(
      filiereId: widget.filiereId,
      niveau: widget.niveau,
      semestre: widget.semestre,
      anneeAcademique: widget.anneeAcademique,
    );
    if (!mounted) return;
    setState(() => _envoi = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['success'] == true ? '✅ Prévision envoyée aux étudiants.' : (result['error']?.toString() ?? 'Erreur lors de l\'envoi.')),
        backgroundColor: result['success'] == true ? const Color(0xFF1A3C34) : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A2E),
        title: const Text('Prévision de moyenne', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        actions: [
          if (!_loading && _erreur == null && _etudiants.isNotEmpty)
            TextButton.icon(
              onPressed: _envoi ? null : _envoyerAuxEtudiants,
              icon: _envoi
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded, size: 16),
              label: const Text('Envoyer'),
            ),
        ],
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          color: Colors.white,
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, color: AdminTheme.info, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.semestre} · ${widget.anneeAcademique} — moyennes par module, sans coefficient. Lecture seule.',
                style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
              ),
            ),
          ]),
        ),
        const Divider(height: 1, color: AdminTheme.border),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _erreur != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_erreur!, style: const TextStyle(color: AdminTheme.danger)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _charger, child: const Text('Réessayer')),
                    ]))
                  : _etudiants.isEmpty
                      ? const Center(child: Text('Aucun étudiant trouvé pour ce groupe.', style: TextStyle(fontSize: 13, color: AdminTheme.textMuted)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _etudiants.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (_, i) => _carteEtudiant(_etudiants[i] as Map<String, dynamic>),
                        ),
        ),
      ]),
    );
  }

  Widget _carteEtudiant(Map<String, dynamic> e) {
    final modules = (e['modules'] as List<dynamic>? ?? []);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.border),
        boxShadow: AdminTheme.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── En-tête : identité de l'étudiant ──────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(color: AdminTheme.primaryLight, shape: BoxShape.circle),
              child: Center(child: Text(
                '${(e['prenoms']?.toString().isNotEmpty == true) ? e['prenoms'][0] : '?'}${(e['nom']?.toString().isNotEmpty == true) ? e['nom'][0] : '?'}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.primary),
              )),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${e['prenoms']} ${e['nom']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                Text('${e['matricule']}', style: const TextStyle(fontSize: 11.5, color: AdminTheme.textMuted, fontFamily: 'monospace')),
              ]),
            ),
          ]),
        ),
        const Divider(height: 1, color: AdminTheme.border),

        // ── Tableau : un module par ligne ─────────────────────────────────
        if (modules.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Aucun module avec des notes validées pour ce semestre.', style: TextStyle(fontSize: 12, color: AdminTheme.textMuted, fontStyle: FontStyle.italic)),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(children: [
              const Row(children: [
                Expanded(flex: 4, child: Text('MODULE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AdminTheme.textMuted))),
                Expanded(flex: 4, child: Text('NOTES', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AdminTheme.textMuted))),
                Expanded(flex: 2, child: Text('MOYENNE', textAlign: TextAlign.end, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AdminTheme.textMuted))),
              ]),
              const SizedBox(height: 8),
              ...modules.map((m) {
                final notes = (m['notes'] as List<dynamic>? ?? []).where((n) => n != null).toList();
                final moyenne = m['moyenne_module'];
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                  child: Row(children: [
                    Expanded(flex: 4, child: Text('${m['module_nom']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                    Expanded(
                      flex: 4,
                      child: notes.isEmpty
                          ? const Text('—', style: TextStyle(fontSize: 13, color: AdminTheme.textMuted))
                          : Text(notes.join(' · '), style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        moyenne != null ? (moyenne as num).toStringAsFixed(2) : '—',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AdminTheme.primary),
                      ),
                    ),
                  ]),
                );
              }),
            ]),
          ),
      ]),
    );
  }
}
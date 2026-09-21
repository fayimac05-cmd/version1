import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import 'evaluation_prof_form_sheet.dart';

/// Liste des professeurs à évaluer pour la période ouverte de la filière de
/// l'étudiant. Un seul professeur à la fois — clic ouvre son formulaire.
class EvaluationsAFairePage extends StatefulWidget {
  const EvaluationsAFairePage({super.key});

  @override
  State<EvaluationsAFairePage> createState() => _EvaluationsAFairePageState();
}

class _EvaluationsAFairePageState extends State<EvaluationsAFairePage> {
  bool _loading = true;
  String? _erreur;
  Map<String, dynamic>? _data; // {periode_id, filiere_nom, date_fin, professeurs}

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _erreur = null; });
    final result = await ApiService.getEvaluationsAFaire();
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        _data = result['data'] as Map<String, dynamic>?;
      } else {
        _erreur = result['error']?.toString() ?? 'Erreur lors du chargement.';
      }
      _loading = false;
    });
  }

  String _formatDate(dynamic iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso.toString());
    if (dt == null) return iso.toString();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  void _evaluer(Map<String, dynamic> prof) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EvaluationProfFormSheet(
        periodeId: _data!['periode_id'].toString(),
        professeurId: prof['id'].toString(),
        professeurNom: '${prof['prenoms']} ${prof['nom']}',
        onSoumis: _charger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        title: const Text('Évaluer mes professeurs', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_erreur!, style: const TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _charger, child: const Text('Réessayer')),
                ]))
              : _data == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.event_busy_rounded, size: 48, color: Color(0xFFCBD5E1)),
                          const SizedBox(height: 12),
                          const Text('Aucune période d\'évaluation ouverte pour l\'instant.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                        ]),
                      ),
                    )
                  : Column(children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          const Icon(Icons.info_outline_rounded, color: AppPalette.blue, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Évaluations anonymes pour ${_data!['filiere_nom']} — clôture le ${_formatDate(_data!['date_fin'])}.',
                              style: const TextStyle(fontSize: 12.5, color: AppPalette.blue),
                            ),
                          ),
                        ]),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: (_data!['professeurs'] as List).length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final prof = (_data!['professeurs'] as List)[i] as Map<String, dynamic>;
                            final dejaEvalue = prof['deja_evalue'] == true;
                            return Container(
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor: dejaEvalue ? const Color(0xFFECFDF5) : AppPalette.lightBlue,
                                  child: Icon(dejaEvalue ? Icons.check_rounded : Icons.person_outline_rounded, color: dejaEvalue ? const Color(0xFF10B981) : AppPalette.blue),
                                ),
                                title: Text('${prof['prenoms']} ${prof['nom']}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                                subtitle: Text(dejaEvalue ? 'Déjà évalué — merci !' : 'Pas encore évalué', style: TextStyle(fontSize: 11.5, color: dejaEvalue ? const Color(0xFF10B981) : const Color(0xFF94A3B8))),
                                trailing: dejaEvalue ? null : const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                                onTap: dejaEvalue ? null : () => _evaluer(prof),
                              ),
                            );
                          },
                        ),
                      ),
                    ]),
    );
  }
}

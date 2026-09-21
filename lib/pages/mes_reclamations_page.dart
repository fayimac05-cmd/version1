import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';

/// Suivi des réclamations soumises par l'étudiant connecté, avec leur statut
/// et la réponse de l'administration une fois traitées.
class MesReclamationsPage extends StatefulWidget {
  const MesReclamationsPage({super.key});

  @override
  State<MesReclamationsPage> createState() => _MesReclamationsPageState();
}

class _MesReclamationsPageState extends State<MesReclamationsPage> {
  bool _loading = true;
  String? _erreur;
  List<dynamic> _reclamations = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _erreur = null; });
    final result = await ApiService.getMesReclamations();
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        _reclamations = result['data'] as List<dynamic>;
      } else {
        _erreur = result['error']?.toString() ?? 'Erreur lors du chargement.';
      }
      _loading = false;
    });
  }

  (String, Color, Color) _styleStatut(String statut) {
    switch (statut) {
      case 'en_attente': return ('En attente', const Color(0xFFB45309), const Color(0xFFFFF7E6));
      case 'en_cours': return ('En cours', const Color(0xFF0C4A6E), const Color(0xFFE0F2FE));
      case 'resolu': return ('Résolue', const Color(0xFF047857), const Color(0xFFECFDF5));
      case 'rejete': return ('Rejetée', const Color(0xFFB91C1C), const Color(0xFFFEF2F2));
      default: return (statut, const Color(0xFF64748B), const Color(0xFFF1F5F9));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        title: const Text('Mes réclamations', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_erreur!, style: const TextStyle(color: Colors.redAccent)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _charger, child: const Text('Réessayer')),
                  ]),
                ))
              : _reclamations.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFCBD5E1)),
                          const SizedBox(height: 12),
                          const Text('Aucune réclamation envoyée', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        ]),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _charger,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reclamations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final r = _reclamations[i];
                          final style = _styleStatut(r['statut']?.toString() ?? '');
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text('${r['module_nom'] ?? 'Module'}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(color: style.$3, borderRadius: BorderRadius.circular(20)),
                                  child: Text(style.$1, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: style.$2)),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              Text('${r['justification'] ?? ''}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                              if (r['reponse'] != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  width: double.infinity,
                                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    const Text('Réponse de l\'administration', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                                    const SizedBox(height: 3),
                                    Text('${r['reponse']}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155))),
                                  ]),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                'Soumis le ${(r['created_at']?.toString() ?? '').split('T').first}',
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';

/// "Prévision de mes moyennes" — moyennes par module (sans coefficient),
/// calculées en direct, pour les semestres où l'administration a
/// explicitement rendu la prévision visible. Ce n'est PAS le bulletin
/// final : ça évolue tant que de nouvelles notes arrivent.
class MesPrevisionsPage extends StatefulWidget {
  const MesPrevisionsPage({super.key});

  @override
  State<MesPrevisionsPage> createState() => _MesPrevisionsPageState();
}

class _MesPrevisionsPageState extends State<MesPrevisionsPage> {
  bool _loading = true;
  String? _erreur;
  List<dynamic> _previsions = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _erreur = null; });
    final result = await ApiService.getMesPrevisions();
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        _previsions = result['data'] as List<dynamic>;
      } else {
        _erreur = result['error']?.toString() ?? 'Erreur lors du chargement.';
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        title: const Text('Prévision de mes moyennes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_erreur!, style: const TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _charger, child: const Text('Réessayer')),
                ]))
              : _previsions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.query_stats_rounded, size: 48, color: Color(0xFFCBD5E1)),
                          const SizedBox(height: 12),
                          const Text('Aucune prévision disponible pour l\'instant.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                        ]),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _charger,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _previsions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, i) => _cartePrevision(_previsions[i] as Map<String, dynamic>),
                      ),
                    ),
    );
  }

  Widget _cartePrevision(Map<String, dynamic> p) {
    final modules = (p['modules'] as List<dynamic>? ?? []);
    final dateEnvoi = p['date_envoi']?.toString().split('T').first ?? '';

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppPalette.blue, borderRadius: BorderRadius.circular(20)),
              child: Text('${p['semestre']}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('${p['annee_academique']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)))),
          ]),
        ),
        if (dateEnvoi.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text('Envoyée le $dateEnvoi — évolue avec les nouvelles notes', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
          ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        if (modules.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Aucun module avec des notes validées pour ce semestre.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(children: [
              const Row(children: [
                Expanded(flex: 4, child: Text('MODULE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)))),
                Expanded(flex: 4, child: Text('NOTES', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)))),
                Expanded(flex: 2, child: Text('MOYENNE', textAlign: TextAlign.end, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)))),
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
                          ? const Text('—', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)))
                          : Text(notes.join(' · '), style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        moyenne != null ? (moyenne as num).toStringAsFixed(2) : '—',
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: moyenne != null && (moyenne as num) >= 10 ? const Color(0xFF10B981) : AppPalette.blue),
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

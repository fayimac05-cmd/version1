import 'package:flutter/material.dart';
import '../services/annuel_service.dart';

/// Archives de l'étudiant : ses années passées, avec décision et bulletins.
/// Lecture seule : rien ne peut être modifié ici.
class ArchivesPage extends StatefulWidget {
  const ArchivesPage({super.key});
  @override
  State<ArchivesPage> createState() => _ArchivesPageState();
}

class _ArchivesPageState extends State<ArchivesPage> {
  List<dynamic> _annees = [];
  bool _charge = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _charge = true;
      _erreur = null;
    });
    final r = await AnnuelService.mesAnnees();
    if (!mounted) return;
    setState(() {
      _charge = false;
      if (r['success'] == true) {
        _annees = (r['data'] as List?) ?? [];
      } else {
        _erreur = r['error']?.toString();
      }
    });
  }

  static String _decision(dynamic d) {
    switch ('$d') {
      case 'admis':
        return 'Admis';
      case 'redoublant':
        return 'Redoublant';
      case 'diplome':
        return 'Diplômé';
      case 'abandon':
        return 'Abandon';
      default:
        return 'En cours';
    }
  }

  static Color _couleur(dynamic d) {
    switch ('$d') {
      case 'admis':
        return const Color(0xFF15803D);
      case 'diplome':
        return const Color(0xFF1D4ED8);
      case 'redoublant':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Mes archives')),
      body: _charge
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
              ? Center(child: Text(_erreur!))
              : _annees.isEmpty
                  ? const Center(child: Text('Aucune année archivée.', style: TextStyle(color: Color(0xFF64748B))))
                  : RefreshIndicator(
                      onRefresh: _charger,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _annees.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final a = _annees[i];
                          final c = _couleur(a['decision']);
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => ArchiveAnneePage(annee: '${a['annee_academique']}'))),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(children: [
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('${a['annee_academique']}',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                    const SizedBox(height: 2),
                                    Text('${a['filiere_nom'] ?? ''} · ${a['niveau'] ?? ''}',
                                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                                  ]),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                  child: Text(_decision(a['decision']),
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c)),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

/// Détail d'une année archivée : bulletins (normaux et après rattrapage) et notes par module.
class ArchiveAnneePage extends StatefulWidget {
  final String annee;
  const ArchiveAnneePage({super.key, required this.annee});
  @override
  State<ArchiveAnneePage> createState() => _ArchiveAnneePageState();
}

class _ArchiveAnneePageState extends State<ArchiveAnneePage> {
  Map<String, dynamic> _data = {};
  bool _charge = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final r = await AnnuelService.monAnnee(widget.annee);
    if (!mounted) return;
    setState(() {
      _charge = false;
      if (r['success'] == true) {
        _data = Map<String, dynamic>.from((r['data'] as Map?) ?? {});
      } else {
        _erreur = r['error']?.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bulletins = (_data['bulletins'] as List?) ?? [];
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: Text('Année ${widget.annee}')),
      body: _charge
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
              ? Center(child: Text(_erreur!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('${_data['filiere_nom'] ?? ''} · ${_data['niveau'] ?? ''}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),
                    if (bulletins.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(child: Text('Aucun bulletin publié pour cette année.', style: TextStyle(color: Color(0xFF64748B)))),
                      ),
                    for (final b in bulletins) ...[_bulletin(b), const SizedBox(height: 12)],
                  ],
                ),
    );
  }

  Widget _bulletin(dynamic b) {
    final ok = '${b['statut']}' == 'valide';
    final apres = '${b['session_type']}' == 'rattrapage';
    final modules = (b['detail_modules'] as List?) ?? [];
    final moy = double.tryParse('${b['moyenne_generale']}');
    final c = ok ? const Color(0xFF15803D) : const Color(0xFFC62828);
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
              child: Text('${b['semestre']}${apres ? ' · après rattrapage' : ''}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            ),
            Text(moy == null ? '—' : '${moy.toStringAsFixed(2)} / 20',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(ok ? 'Validé' : 'Non validé', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: c)),
            ),
          ]),
        ),
        if (modules.isNotEmpty) const Divider(height: 1, color: Color(0xFFE2E8F0)),
        for (final m in modules)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(children: [
              Expanded(child: Text('${m['module_nom']}', style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
              Text(
                double.tryParse('${m['moyenne_module']}') == null
                    ? '—'
                    : double.parse('${m['moyenne_module']}').toStringAsFixed(2),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
            ]),
          ),
        if ('${b['appreciation'] ?? ''}'.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Text('Appréciation : ${b['appreciation']}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
          ),
      ]),
    );
  }
}

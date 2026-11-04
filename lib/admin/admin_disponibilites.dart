import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

/// Marqueur « nouveautés » : un professeur est « non vu » si ses heures libres
/// ont changé depuis la dernière ouverture de la page par cet administrateur.
class DisposNonVues {
  static const _cle = 'dispos_vues_v1';

  static Map<String, String> _signatures(List data) {
    final m = <String, String>{};
    for (final e in data) {
      if (e is Map && e['disponibilites'] is List && (e['disponibilites'] as List).isNotEmpty) {
        m['${e['id']}'] = '${e['disponibilites']}';
      }
    }
    return m;
  }

  static Future<Map<String, String>> _vues() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getStringList(_cle) ?? [];
      return {for (final l in raw) if (l.contains('|')) l.substring(0, l.indexOf('|')): l.substring(l.indexOf('|') + 1)};
    } catch (_) {
      return {};
    }
  }

  /// Nombre de professeurs dont les heures libres sont nouvelles ou modifiées.
  static Future<int> compter() async {
    final r = await ApiService.getDisponibilitesProfesseurs();
    if (r['success'] != true || r['data'] is! List) return 0;
    final sig = _signatures(r['data'] as List);
    final vues = await _vues();
    return sig.entries.where((e) => vues[e.key] != e.value).length;
  }

  /// Marque tout ce qui est affiché comme vu.
  static Future<void> toutMarquerVu(List data) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_cle, _signatures(data).entries.map((e) => '${e.key}|${e.value}').toList());
    } catch (_) {}
  }
}

/// Heures libres transmises par les professeurs (écran « Mon programme /
/// heures libres » côté professeur). L'administration s'en sert pour
/// construire les emplois du temps.
class AdminDisponibilites extends StatefulWidget {
  /// Appelé après marquage « vu » (le menu retire alors son marqueur).
  final VoidCallback? onVu;
  const AdminDisponibilites({super.key, this.onVu});
  @override
  State<AdminDisponibilites> createState() => _AdminDisponibilitesState();
}

class _AdminDisponibilitesState extends State<AdminDisponibilites> {
  static const _navy = Color(0xFF0B1E4D);
  static const _jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

  bool _loading = true;
  String? _erreur;
  List<Map<String, dynamic>> _profs = [];
  String _q = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _erreur = null;
    });
    final r = await ApiService.getDisponibilitesProfesseurs();
    if (!mounted) return;
    if (r['success'] != true) {
      setState(() {
        _loading = false;
        _erreur = (r['error'] ?? 'Chargement impossible.').toString();
      });
      return;
    }
    await DisposNonVues.toutMarquerVu(r['data'] as List);
    widget.onVu?.call();
    final liste = (r['data'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((p) => _creneaux(p).isNotEmpty)
        .toList()
      ..sort((a, b) => _nom(a).compareTo(_nom(b)));
    setState(() {
      _profs = liste;
      _loading = false;
    });
  }

  String _nom(Map<String, dynamic> p) =>
      '${p['nom'] ?? ''} ${p['prenoms'] ?? ''}'.trim().toUpperCase();

  List<Map<String, dynamic>> _creneaux(Map<String, dynamic> p) {
    var d = p['disponibilites'];
    if (d is! List) return [];
    return d.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // « · transmis le 05/11 » d'après users.disponibilites_maj
  String _transmisLe(Map<String, dynamic> p) {
    final d = DateTime.tryParse('${p['disponibilites_maj'] ?? ''}')?.toLocal();
    if (d == null) return '';
    return ' · transmis le ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  String _jour(Map<String, dynamic> c) => (c['jour'] ?? c['day'] ?? '').toString().trim();

  // Le format exact peut varier : on accepte « 08:00–10:00 » ou début/fin séparés.
  String _heure(Map<String, dynamic> c) {
    final direct = c['creneau'] ?? c['horaire'] ?? c['label'] ?? c['plage'];
    if (direct != null && direct.toString().isNotEmpty) return direct.toString();
    final d = c['heureDebut'] ?? c['debut'] ?? c['start'];
    final f = c['heureFin'] ?? c['fin'] ?? c['end'];
    if (d != null || f != null) return '${d ?? '--'}–${f ?? '--'}';
    return c.values.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final visibles = _profs.where((p) => q.isEmpty || _nom(p).toLowerCase().contains(q)).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Expanded(
                child: Text('Disponibilités des professeurs',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _navy)),
              ),
              IconButton(onPressed: _charger, tooltip: 'Actualiser', icon: const Icon(Icons.refresh_rounded)),
            ]),
            const Text('Heures libres transmises par les professeurs, pour construire les emplois du temps.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un professeur…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _contenu(visibles)),
          ],
        ),
      ),
    );
  }

  Widget _contenu(List<Map<String, dynamic>> visibles) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_erreur != null) {
      return Center(child: Text(_erreur!, style: const TextStyle(color: Color(0xFFDC2626))));
    }
    if (visibles.isEmpty) {
      return const Center(
        child: Text("Aucun professeur n'a encore transmis ses heures libres.",
            style: TextStyle(color: Color(0xFF64748B))),
      );
    }
    return ListView.separated(
      itemCount: visibles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _carteProf(visibles[i]),
    );
  }

  Widget _carteProf(Map<String, dynamic> p) {
    final cr = _creneaux(p);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: CircleAvatar(
            backgroundColor: _navy.withValues(alpha: 0.1),
            child: Text(_nom(p).isEmpty ? '?' : _nom(p)[0], style: const TextStyle(color: _navy, fontWeight: FontWeight.w900)),
          ),
          title: Text(_nom(p), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _navy)),
          subtitle: Text('${cr.length} créneau${cr.length > 1 ? 'x' : ''} libre${cr.length > 1 ? 's' : ''}${_transmisLe(p)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          children: [
            for (final j in _jours)
              if (cr.any((c) => _jour(c) == j))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 84,
                        child: Text(j, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                      ),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final c in cr.where((c) => _jour(c) == j))
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(_heure(c),
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF047857))),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
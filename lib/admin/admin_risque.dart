import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Détection précoce du décrochage scolaire.
/// Croise moyenne générale et assiduité (60 derniers jours) pour donner
/// un score de risque par étudiant, avec alerte étudiant + SMS parent.
class AdminRisque extends StatefulWidget {
  const AdminRisque({super.key});

  @override
  State<AdminRisque> createState() => _AdminRisqueState();
}

class _AdminRisqueState extends State<AdminRisque> {
  List<dynamic> _etudiants = [];
  bool _loading = true;
  String? _error;
  String _filtre = 'tous'; // tous | critique | eleve | modere

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ApiService.getEtudiantsARisque();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _etudiants = result['data'] as List<dynamic>;
      } else {
        _error = result['error'];
      }
    });
  }

  List<dynamic> get _filtres {
    if (_filtre == 'tous') return _etudiants;
    return _etudiants.where((e) => e['niveau_risque'] == _filtre).toList();
  }

  Future<void> _alerter(Map<String, dynamic> e) async {
    final msgCtrl = TextEditingController();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Alerter ${e['prenoms']} ${e['nom']}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Une notification sera envoyée à l\'étudiant et un SMS au parent.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: msgCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Message personnalisé (facultatif)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('Envoyer l\'alerte'),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;

    final result = await ApiService.alerterEtudiantRisque(
      e['etudiant_id'] as int,
      message: msgCtrl.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['success'] == true
          ? 'Alerte envoyée (notification${result['sms_parent'] == true ? ' + SMS parent' : ''}).'
          : result['error'] ?? 'Erreur lors de l\'envoi.'),
      backgroundColor: result['success'] == true ? const Color(0xFF10B981) : Colors.red,
    ));
  }

  static const _couleurs = {
    'critique': Color(0xFFDC2626),
    'eleve': Color(0xFFF59E0B),
    'modere': Color(0xFF0EA5E9),
    'faible': Color(0xFF10B981),
  };

  static const _labels = {
    'critique': 'Critique',
    'eleve': 'Élevé',
    'modere': 'Modéré',
    'faible': 'Faible',
  };

  @override
  Widget build(BuildContext context) {
    final nbCritique = _etudiants.where((e) => e['niveau_risque'] == 'critique').length;
    final nbEleve = _etudiants.where((e) => e['niveau_risque'] == 'eleve').length;
    final nbModere = _etudiants.where((e) => e['niveau_risque'] == 'modere').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(children: [
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Élèves à risque de décrochage',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  SizedBox(height: 4),
                  Text('Score croisant moyenne générale et assiduité (60 derniers jours)',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ]),
              ),
              IconButton(
                onPressed: _charger,
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0A3D91)),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              _statCard('Critique', nbCritique, _couleurs['critique']!),
              const SizedBox(width: 10),
              _statCard('Élevé', nbEleve, _couleurs['eleve']!),
              const SizedBox(width: 10),
              _statCard('Modéré', nbModere, _couleurs['modere']!),
            ]),
            const SizedBox(height: 16),
            Wrap(spacing: 8, children: [
              for (final f in ['tous', 'critique', 'eleve', 'modere'])
                ChoiceChip(
                  label: Text(f == 'tous' ? 'Tous' : _labels[f]!),
                  selected: _filtre == f,
                  selectedColor: const Color(0xFF0A3D91),
                  labelStyle: TextStyle(
                      color: _filtre == f ? Colors.white : const Color(0xFF334155),
                      fontSize: 12, fontWeight: FontWeight.w600),
                  onSelected: (_) => setState(() => _filtre = f),
                ),
            ]),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
            if (!_loading && _error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
              ),
            if (!_loading && _error == null && _filtres.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Aucun étudiant dans cette catégorie. 🎉',
                    style: TextStyle(color: Color(0xFF64748B)))),
              ),
            if (!_loading) ..._filtres.map((e) => _etudiantCard(e as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(children: [
          Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }

  Widget _etudiantCard(Map<String, dynamic> e) {
    final niveau = e['niveau_risque'] as String? ?? 'faible';
    final color = _couleurs[niveau] ?? _couleurs['faible']!;
    final score = e['score'] ?? 0;
    final moyenne = e['moyenne'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: niveau == 'faible' ? 0.0 : 0.35)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$score',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${e['prenoms'] ?? ''} ${e['nom'] ?? ''}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              const SizedBox(height: 2),
              Text('${e['matricule'] ?? ''} · ${e['filiere_nom'] ?? 'Sans filière'}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_labels[niveau] ?? niveau,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _indicateur(Icons.school_outlined,
              moyenne != null ? 'Moy. $moyenne/20' : 'Pas de note'),
          const SizedBox(width: 14),
          _indicateur(Icons.event_busy_outlined,
              '${e['nb_absences'] ?? 0} abs. / ${e['nb_seances'] ?? 0} séances (${e['taux_absence'] ?? 0}%)'),
          const SizedBox(width: 14),
          _indicateur(Icons.schedule_outlined, '${e['nb_retards'] ?? 0} retard(s)'),
        ]),
        if (niveau == 'critique' || niveau == 'eleve') ...[
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            if ((e['tel_parent'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text('Parent : ${e['nom_parent'] ?? ''} (${e['tel_parent']})',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ),
            OutlinedButton.icon(
              onPressed: () => _alerter(e),
              icon: const Icon(Icons.notification_important_outlined, size: 16),
              label: const Text('Alerter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _indicateur(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: const Color(0xFF64748B)),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
    ]);
  }
}

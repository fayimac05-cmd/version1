import 'package:flutter/material.dart';
import '../services/rattrapage_service.dart';

/// Onglet « Rattrapage » de l'étudiant :
///  • sa situation (est-il concerné ? pour quels modules ? à quelles dates ?) ;
///  • ses notes de rattrapage, une fois validées par l'administration.
/// Le serveur ne renvoie que les données de l'étudiant connecté.
class RattrapageEtudiant extends StatefulWidget {
  const RattrapageEtudiant({super.key});
  @override
  State<RattrapageEtudiant> createState() => _RattrapageEtudiantState();
}

class _RattrapageEtudiantState extends State<RattrapageEtudiant> {
  static const Color _texte = Color(0xFF0F172A);
  static const Color _gris = Color(0xFF64748B);
  static const Color _bord = Color(0xFFE2E8F0);
  static const Color _orange = Color(0xFFD97706);
  static const Color _vert = Color(0xFF15803D);

  bool _chargement = true;
  String? _erreur;
  Map<String, dynamic> _situation = {};
  List<dynamic> _notes = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    final r = await Future.wait([RattrapageService.maSituation(), RattrapageService.mesNotes()]);
    if (!mounted) return;
    setState(() {
      _chargement = false;
      if (r[0]['success'] == true) {
        _situation = Map<String, dynamic>.from((r[0]['data'] as Map?) ?? {});
      } else {
        _erreur = r[0]['error']?.toString();
      }
      _notes = r[1]['success'] == true ? ((r[1]['data'] as List?) ?? []) : [];
    });
  }

  String _date(dynamic v) {
    final d = DateTime.tryParse('${v ?? ''}');
    if (d == null) return '';
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) return const Center(child: CircularProgressIndicator());
    if (_erreur != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_erreur!, style: const TextStyle(fontSize: 13, color: _gris)),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _charger, child: const Text('Réessayer')),
        ]),
      );
    }

    final enRattrapage = _situation['en_rattrapage'] == true;
    final semestres = (_situation['semestres'] as List?) ?? [];
    final debut = _date(_situation['date_debut']);
    final fin = _date(_situation['date_fin']);

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (!enRattrapage)
            _carte(
              couleur: _vert,
              icone: Icons.check_circle_outline_rounded,
              titre: 'Tu n\'es pas concerné(e) par le rattrapage',
              corps: 'Aucun semestre à repasser pour l\'année en cours.',
            )
          else ...[
            _carte(
              couleur: _orange,
              icone: Icons.replay_circle_filled_rounded,
              titre: 'Tu es en rattrapage',
              corps: (debut.isNotEmpty && fin.isNotEmpty)
                  ? 'Session du $debut au $fin. Prépare les modules ci-dessous.'
                  : 'Les dates du rattrapage seront communiquées par l\'administration.',
            ),
            const SizedBox(height: 14),
            for (final s in semestres) ...[_blocSemestre(s), const SizedBox(height: 12)],
          ],
          const SizedBox(height: 10),
          const Text('Mes notes de rattrapage',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _texte)),
          const SizedBox(height: 4),
          const Text('Elles apparaissent ici une fois validées par l\'administration.',
              style: TextStyle(fontSize: 12, color: _gris)),
          const SizedBox(height: 10),
          if (_notes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: Text('Aucune note de rattrapage publiée pour l\'instant.', style: TextStyle(fontSize: 13, color: _gris))),
            )
          else
            for (final n in _notes) ...[_ligneNote(n), const SizedBox(height: 8)],
        ],
      ),
    );
  }

  Widget _carte({required Color couleur, required IconData icone, required String titre, required String corps}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icone, color: couleur, size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titre, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: couleur)),
            const SizedBox(height: 4),
            Text(corps, style: const TextStyle(fontSize: 12.5, color: _texte, height: 1.4)),
          ]),
        ),
      ]),
    );
  }

  Widget _blocSemestre(dynamic s) {
    final modules = (s['modules'] as List?) ?? [];
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Text('Semestre ${'${s['semestre']}'.replaceFirst('S', '')} — modules à repasser',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _texte)),
        ),
        const Divider(height: 1, color: _bord),
        for (final m in modules)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(children: [
              Expanded(child: Text('${m['module_nom']}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _texte))),
              Text(
                m['moyenne_normale'] == null ? '—' : '${(m['moyenne_normale'] as num).toStringAsFixed(2)} / 20',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFC62828)),
              ),
            ]),
          ),
      ]),
    );
  }

  Widget _ligneNote(dynamic n) {
    final v = double.tryParse('${n['valeur']}');
    final ok = v != null && v >= 10;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _bord)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${n['module_nom']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _texte)),
            const SizedBox(height: 2),
            Text('${n['semestre']} · ${n['annee_academique']}', style: const TextStyle(fontSize: 11.5, color: _gris)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: ok ? const Color(0xFFF0FDF4) : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            v == null ? '—' : '${v.toStringAsFixed(2)} / 20',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ok ? const Color(0xFF15803D) : const Color(0xFFC62828)),
          ),
        ),
      ]),
    );
  }
}

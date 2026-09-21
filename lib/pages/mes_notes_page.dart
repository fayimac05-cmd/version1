import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/student_profile.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import 'reclamation_form_sheet.dart';
import 'mes_reclamations_page.dart';
import 'mes_previsions_page.dart';

/// Écran "Mes notes" — extrait de home_tab.dart (anciennement classe privée
/// `_NotesPage`, qui recevait ses données déjà chargées par HomeTab). Se
/// charge maintenant lui-même (notes publiées + statut lu/non lu), pour
/// être ouvrable depuis n'importe où (ex. clic sur une notification
/// "Nouvelle note publiée"), pas seulement depuis l'accueil.
class MesNotesPage extends StatefulWidget {
  const MesNotesPage({super.key, required this.profile});
  final StudentProfile profile;

  @override
  State<MesNotesPage> createState() => _MesNotesPageState();
}

class _MesNotesPageState extends State<MesNotesPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _notes = [];
  Set<String> _lues = {};
  int _onglet = 0;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  String _noteKey(Map<String, dynamic> note) {
    final id = note['id'] ?? note['note_id'] ?? note['evaluation_id'];
    return id.toString();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.getMesNotes();
      if (result['success'] != true) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final notes = List<Map<String, dynamic>>.from(result['data'] as List);

      Set<String> lues = <String>{};
      try {
        final lectureRows = await Supabase.instance.client
            .from('notes_lectures')
            .select('note_key')
            .eq('etudiant_matricule', widget.profile.matricule.trim());
        lues = (lectureRows as List)
            .map((e) => (e as Map)['note_key']?.toString())
            .whereType<String>()
            .toSet();
      } catch (_) {
        // Table de suivi "lu" absente ou injoignable : les notes restent
        // visibles, simplement toutes marquées non lues.
      }

      if (!mounted) return;
      setState(() {
        _notes = notes;
        _lues = lues;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _marquerCommeLues(List<Map<String, dynamic>> notes) async {
    if (notes.isEmpty) return;
    final matricule = widget.profile.matricule.trim();
    if (matricule.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    final rows = notes.map((note) => {
      'etudiant_matricule': matricule,
      'note_key': _noteKey(note),
      'lu_at': now,
    }).toList();

    setState(() {
      _lues = {..._lues, ...notes.map(_noteKey)};
    });

    try {
      await Supabase.instance.client
          .from('notes_lectures')
          .upsert(rows, onConflict: 'etudiant_matricule,note_key');
    } catch (_) {
      // Table absente pendant la mise en place du projet — le fonctionnement
      // visuel reste disponible.
    }
  }

  String _titreNote(Map<String, dynamic> note) {
    for (final key in [
      'module_nom',
      'matiere_nom',
      'matiere',
      'cours',
      'module',
      'ue',
      'intitule',
    ]) {
      final value = note[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return 'Note publiée';
  }

  String _profNote(Map<String, dynamic> note) {
    final prenoms = (note['prof_prenoms'] ?? '').toString().trim();
    final nom = (note['prof_nom'] ?? '').toString().trim();
    final full = [prenoms, nom].where((s) => s.isNotEmpty).join(' ');
    return full.isNotEmpty ? full : '';
  }

  String _semestreNote(Map<String, dynamic> note) {
    return (note['semestre'] ?? '').toString().trim();
  }

  String _mentionNote(Map<String, dynamic> note) {
    return (note['mention'] ?? '').toString().trim();
  }

  String _dateNote(Map<String, dynamic> note) {
    for (final key in [
      'date_session',
      'date_note',
      'date_evaluation',
      'created_at',
      'date',
    ]) {
      final raw = note[key]?.toString();
      if (raw == null || raw.isEmpty) continue;
      try {
        return DateFormat('dd/MM/yyyy').format(DateTime.parse(raw).toLocal());
      } catch (_) {}
    }
    return '';
  }

  String _valeur(Map<String, dynamic> note) {
    final value = note['valeur'] ?? note['note'] ?? note['score'];
    if (value == null) return '--';
    final n = double.tryParse(value.toString());
    if (n == null) return value.toString();
    return n.toStringAsFixed(n % 1 == 0 ? 0 : 2).replaceAll('.', ',');
  }

  String _coefficient(Map<String, dynamic> note) {
    final value = note['coefficient'] ?? note['coef'];
    return value == null ? '' : 'Coef. ${value.toString()}';
  }

  List<Map<String, dynamic>> get _nonLues =>
      _notes.where((note) => !_lues.contains(_noteKey(note))).toList();

  List<Map<String, dynamic>> get _historique =>
      _notes.where((note) => _lues.contains(_noteKey(note))).toList();

  Future<void> _lireNotes(List<Map<String, dynamic>> notes) async {
    if (notes.isEmpty) return;
    setState(() {
      _lues.addAll(notes.map(_noteKey));
    });
    await _marquerCommeLues(notes);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final notes = _onglet == 0 ? _nonLues : _historique;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        title: const Text(
          'Mes notes',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.query_stats_rounded, size: 20),
            tooltip: 'Prévision de mes moyennes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MesPrevisionsPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.rate_review_outlined, size: 20),
            tooltip: 'Mes réclamations',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MesReclamationsPage()),
            ),
          ),
          if (_nonLues.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Text(
                  '${_nonLues.length} nouvelle${_nonLues.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppPalette.lightBlue,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Expanded(child: _tab('Nouvelles', 0, _nonLues.length)),
                Expanded(child: _tab('Historique', 1, _historique.length)),
              ],
            ),
          ),
          if (_onglet == 0 && _nonLues.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _lireNotes(_nonLues),
                  icon: const Icon(Icons.done_all_rounded, size: 17),
                  label: const Text('Tout marquer comme lu'),
                ),
              ),
            ),
          Expanded(
            child: notes.isEmpty
                ? _emptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: notes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 9),
                    itemBuilder: (_, index) => _noteCard(notes[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, int index, int count) {
    final active = _onglet == index;
    return GestureDetector(
      onTap: () => setState(() => _onglet = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? AppPalette.blue : AppPalette.grey,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: index == 0
                      ? const Color(0xFFDC2626)
                      : AppPalette.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _noteCard(Map<String, dynamic> note) {
    final isRead = _lues.contains(_noteKey(note));

    return GestureDetector(
      onTap: () => _lireNotes([note]),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? const Color(0xFFE2E8F0)
                : const Color(0xFFFECACA),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isRead
                    ? AppPalette.lightBlue
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.grade_rounded,
                color: isRead
                    ? AppPalette.blue
                    : const Color(0xFFDC2626),
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titreNote(note),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF172033),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (_profNote(note).isNotEmpty) 'Prof. ${_profNote(note)}',
                      if (_semestreNote(note).isNotEmpty) _semestreNote(note),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppPalette.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        _dateNote(note),
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppPalette.grey,
                        ),
                      ),
                      if (_coefficient(note).isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          _coefficient(note),
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppPalette.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_mentionNote(note).isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppPalette.lightBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _mentionNote(note),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.blue,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _valeur(note),
                  style: TextStyle(
                    color: isRead
                        ? const Color(0xFF172033)
                        : const Color(0xFFDC2626),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isRead ? 'Lu' : 'Nouveau',
                  style: TextStyle(
                    color: isRead
                        ? AppPalette.grey
                        : const Color(0xFFDC2626),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _ouvrirContestation(note),
                icon: const Icon(Icons.flag_outlined, size: 15, color: Color(0xFFB45309)),
                label: const Text('Contester cette note', style: TextStyle(fontSize: 11.5, color: Color(0xFFB45309), fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _ouvrirContestation(Map<String, dynamic> note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReclamationFormSheet(
        type: 'note',
        moduleId: (note['module_id'] ?? '').toString(),
        moduleNom: _titreNote(note),
        noteActuelle: double.tryParse(_valeur(note).replaceAll(',', '.')),
        semestre: _semestreNote(note).isNotEmpty ? _semestreNote(note) : null,
        annee: note['annee_academique']?.toString(),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _onglet == 0
                  ? Icons.mark_email_read_outlined
                  : Icons.history_rounded,
              size: 48,
              color: const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 12),
            Text(
              _onglet == 0
                  ? 'Aucune nouvelle note'
                  : 'Aucune note dans l\u2019historique',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

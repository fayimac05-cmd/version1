import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

const Color _navy = Color(0xFF0B1E4D);
const Color _blue = Color(0xFF1565E0);
const Color _bord = Color(0xFFE2E8F0);
const Color _gris = Color(0xFF64748B);

const List<String> _typesDate = ['Académique', 'Examens', 'Résultats', 'Vacances', 'Urgent'];
const List<String> _mois = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

Color _couleurType(String t) {
  switch (t) {
    case 'Examens': return const Color(0xFF7C3AED);
    case 'Résultats': return const Color(0xFF10B981);
    case 'Vacances': return const Color(0xFFF59E0B);
    case 'Urgent': return const Color(0xFFEF4444);
    default: return _blue;
  }
}

DateTime? _lireDate(String? s) {
  if (s == null || s.length < 10) return null;
  return DateTime.tryParse(s.substring(0, 10));
}

String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')} ${_mois[d.month - 1]} ${d.year}';
String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Libellé d'une date ou d'une période, ex. « 04 nov. 2026 → 15 nov. 2026 ».
String libelleDate(String? debut, String? fin) {
  final d = _lireDate(debut);
  if (d == null) return '';
  final f = _lireDate(fin);
  if (f == null || f == d) return _fmt(d);
  return '${_fmt(d)} → ${_fmt(f)}';
}

/// Écran de gestion du calendrier académique (administration).
/// À afficher dans la page « Emplois du temps » : il se charge seul et ne dépend d'aucun Scaffold.
class CalendrierAcademiqueAdmin extends StatefulWidget {
  const CalendrierAcademiqueAdmin({super.key});
  @override
  State<CalendrierAcademiqueAdmin> createState() => _CalendrierAcademiqueAdminState();
}

class _CalendrierAcademiqueAdminState extends State<CalendrierAcademiqueAdmin> {
  bool _chargement = true;
  String? _erreur;
  List<Map<String, dynamic>> _dates = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _chargement = true; _erreur = null; });
    try {
      final r = await http.get(Uri.parse('${ApiService.baseUrl}/calendrier'), headers: await ApiService.getHeaders());
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      if (r.statusCode != 200) throw Exception(body is Map ? body['message'] : 'Erreur');
      if (!mounted) return;
      setState(() {
        _dates = (body['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _erreur = 'Impossible de charger le calendrier.'; _chargement = false; });
    }
  }

  void _msg(String texte, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texte),
      backgroundColor: ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
    ));
  }

  Future<void> _editer([Map<String, dynamic>? existant]) async {
    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _FormulaireDate(existant: existant),
    );
    if (res == null) return;
    try {
      final headers = await ApiService.getHeaders();
      final url = existant == null
          ? '${ApiService.baseUrl}/calendrier'
          : '${ApiService.baseUrl}/calendrier/${existant['id']}';
      final r = existant == null
          ? await http.post(Uri.parse(url), headers: headers, body: jsonEncode(res))
          : await http.put(Uri.parse(url), headers: headers, body: jsonEncode(res));
      final body = r.body.isEmpty ? {} : jsonDecode(utf8.decode(r.bodyBytes));
      if (r.statusCode == 200 || r.statusCode == 201) {
        _msg(existant == null ? 'Date ajoutée.' : 'Date modifiée.');
        _charger();
      } else {
        _msg((body is Map ? body['message'] : null)?.toString() ?? 'Enregistrement impossible.', ok: false);
      }
    } catch (_) {
      _msg('Serveur injoignable.', ok: false);
    }
  }

  Future<void> _supprimer(Map<String, dynamic> d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Supprimer cette date ?'),
        content: Text('« ${d['titre']} » ne sera plus visible par les étudiants.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Supprimer', style: TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final r = await http.delete(Uri.parse('${ApiService.baseUrl}/calendrier/${d['id']}'), headers: await ApiService.getHeaders());
      if (r.statusCode == 200) {
        _msg('Date supprimée.');
        _charger();
      } else {
        _msg('Suppression impossible.', ok: false);
      }
    } catch (_) {
      _msg('Serveur injoignable.', ok: false);
    }
  }

  bool _estPassee(Map<String, dynamic> d) {
    final fin = _lireDate(d['date_fin']?.toString()) ?? _lireDate(d['date_debut']?.toString());
    if (fin == null) return false;
    final now = DateTime.now();
    return fin.isBefore(DateTime(now.year, now.month, now.day));
  }

  @override
  Widget build(BuildContext context) {
    final avenir = _dates.where((d) => !_estPassee(d)).toList();
    final passees = _dates.where(_estPassee).toList().reversed.toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
        spacing: 12, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('Calendrier académique', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _navy)),
            SizedBox(height: 2),
            Text('Ces dates apparaissent dans « Dates importantes » chez vos étudiants.', style: TextStyle(fontSize: 12.5, color: _gris)),
          ]),
          ElevatedButton.icon(
            onPressed: () => _editer(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Ajouter une date', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      if (_chargement)
        const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
      else if (_erreur != null)
        Center(child: Column(children: [
          Text(_erreur!, style: const TextStyle(color: _gris)),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: _charger, child: const Text('Réessayer')),
        ]))
      else if (_dates.isEmpty)
        _vide()
      else ...[
        if (avenir.isNotEmpty) ...[
          _titreGroupe('À venir (${avenir.length})'),
          for (final d in avenir) _carte(d, false),
        ],
        if (passees.isNotEmpty) ...[
          const SizedBox(height: 10),
          _titreGroupe('Passées (${passees.length})'),
          for (final d in passees) _carte(d, true),
        ],
      ],
    ]);
  }

  Widget _vide() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _bord)),
    child: Column(children: const [
      Icon(Icons.event_busy_rounded, size: 40, color: Color(0xFF94A3B8)),
      SizedBox(height: 10),
      Text('Aucune date enregistrée', style: TextStyle(fontWeight: FontWeight.w700, color: _navy)),
      SizedBox(height: 4),
      Text('Ajoutez la rentrée, les examens, les délibérations, les vacances…', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: _gris)),
    ]),
  );

  Widget _titreGroupe(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _gris, letterSpacing: 0.3)),
  );

  Widget _carte(Map<String, dynamic> d, bool passee) {
    final type = (d['type'] ?? 'Académique').toString();
    final c = _couleurType(type);
    final desc = (d['description'] ?? '').toString();
    return Opacity(
      opacity: passee ? 0.6 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _bord)),
        child: Row(children: [
          Container(width: 4, height: 46, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text((d['titre'] ?? '').toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _navy)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(type, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: c)),
              ),
            ]),
            const SizedBox(height: 3),
            Text(libelleDate(d['date_debut']?.toString(), d['date_fin']?.toString()),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _gris)),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(desc, style: const TextStyle(fontSize: 12, color: _gris)),
            ],
          ])),
          IconButton(tooltip: 'Modifier', icon: const Icon(Icons.edit_outlined, size: 19, color: _gris), onPressed: () => _editer(d)),
          IconButton(tooltip: 'Supprimer', icon: const Icon(Icons.delete_outline_rounded, size: 19, color: Color(0xFFDC2626)), onPressed: () => _supprimer(d)),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Formulaire d'ajout / modification
// ════════════════════════════════════════════════════════════════════════════
class _FormulaireDate extends StatefulWidget {
  final Map<String, dynamic>? existant;
  const _FormulaireDate({this.existant});
  @override
  State<_FormulaireDate> createState() => _FormulaireDateState();
}

class _FormulaireDateState extends State<_FormulaireDate> {
  final _titre = TextEditingController();
  final _desc = TextEditingController();
  String _type = 'Académique';
  DateTime? _debut;
  DateTime? _fin;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    final e = widget.existant;
    if (e != null) {
      _titre.text = (e['titre'] ?? '').toString();
      _desc.text = (e['description'] ?? '').toString();
      final t = (e['type'] ?? 'Académique').toString();
      _type = _typesDate.contains(t) ? t : 'Académique';
      _debut = _lireDate(e['date_debut']?.toString());
      _fin = _lireDate(e['date_fin']?.toString());
    }
  }

  @override
  void dispose() {
    _titre.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _choisir(bool debut) async {
    final base = (debut ? _debut : (_fin ?? _debut)) ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() {
      if (debut) { _debut = d; } else { _fin = d; }
    });
  }

  void _valider() {
    if (_titre.text.trim().isEmpty) { setState(() => _erreur = 'Le titre est requis.'); return; }
    if (_debut == null) { setState(() => _erreur = 'Choisissez la date (ou la date de début).'); return; }
    if (_fin != null && _fin!.isBefore(_debut!)) { setState(() => _erreur = 'La date de fin doit être après la date de début.'); return; }
    Navigator.pop(context, {
      'titre': _titre.text.trim(),
      'description': _desc.text.trim(),
      'type': _type,
      'date_debut': _iso(_debut!),
      'date_fin': _fin == null ? '' : _iso(_fin!),
    });
  }

  Widget _champDate(String label, DateTime? v, VoidCallback onTap, {VoidCallback? onClear}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: onClear != null && v != null
            ? IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: onClear)
            : const Icon(Icons.calendar_today_rounded, size: 18),
      ),
      child: Text(v == null ? 'Choisir…' : _fmt(v), style: TextStyle(color: v == null ? _gris : _navy)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existant == null ? 'Ajouter une date' : 'Modifier la date'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              controller: _titre,
              maxLength: 120,
              decoration: InputDecoration(labelText: 'Titre *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: InputDecoration(labelText: 'Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              items: [for (final t in _typesDate) DropdownMenuItem(value: t, child: Text(t))],
              onChanged: (v) => setState(() => _type = v ?? 'Académique'),
            ),
            const SizedBox(height: 12),
            _champDate('Date (ou début) *', _debut, () => _choisir(true)),
            const SizedBox(height: 12),
            _champDate('Date de fin (facultatif)', _fin, () => _choisir(false), onClear: () => setState(() => _fin = null)),
            const SizedBox(height: 12),
            TextField(
              controller: _desc,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(labelText: 'Description (facultatif)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            ),
            if (_erreur != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_erreur!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12.5)),
              ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _valider,
          style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
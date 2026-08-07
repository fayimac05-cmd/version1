import 'package:flutter/material.dart';
import '../services/professor_service.dart';
import '../utils/snackbar_helper.dart';

/// Programme hebdomadaire du professeur : il coche ses créneaux LIBRES
/// puis les transmet à l'administration (qui les voit dans Professeurs →
/// Heures libres et peut s'en servir pour construire l'emploi du temps).
class ProgrammeScreen extends StatefulWidget {
  const ProgrammeScreen({super.key});

  @override
  State<ProgrammeScreen> createState() => _ProgrammeScreenState();
}

class _ProgrammeScreenState extends State<ProgrammeScreen> {
  static const List<String> _jours = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi',
  ];

  // Créneaux alignés sur les plages usuelles de l'emploi du temps
  static const List<(String, String)> _creneaux = [
    ('08:00', '10:00'),
    ('10:15', '12:15'),
    ('13:00', '15:00'),
    ('15:15', '17:15'),
  ];

  // Clés 'jour|debut' des créneaux marqués libres
  final Set<String> _libres = {};
  bool _chargement = true;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final res = await ProfessorService.getDisponibilites();
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        for (final c in (res['data'] as List)) {
          _libres.add('${c['jour']}|${c['debut']}');
        }
      }
      _chargement = false;
    });
  }

  Future<void> _transmettre() async {
    setState(() => _envoi = true);
    final creneaux = <Map<String, String>>[];
    for (final jour in _jours) {
      for (final (debut, fin) in _creneaux) {
        if (_libres.contains('$jour|$debut')) {
          creneaux.add({'jour': jour, 'debut': debut, 'fin': fin});
        }
      }
    }
    final res = await ProfessorService.saveDisponibilites(creneaux);
    if (!mounted) return;
    setState(() => _envoi = false);
    if (res['success'] == true) {
      showAppSnackBar(context,
          '✅ ${creneaux.length} créneau(x) libre(s) transmis à l\'administration.');
    } else {
      showAppSnackBar(context, res['error'] as String? ?? 'Erreur lors de la transmission.',
          backgroundColor: const Color(0xFFDC2626));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D91),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mon programme',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : Column(children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded,
                      color: Color(0xFF1D4ED8), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Touchez les créneaux où vous êtes LIBRE, puis transmettez-les '
                      'à l\'administration pour la construction de l\'emploi du temps.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), height: 1.4),
                    ),
                  ),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: _jours.map(_carteJour).toList(),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _envoi ? null : _transmettre,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _envoi
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _envoi
                            ? 'Transmission...'
                            : 'Transmettre mes heures libres (${_libres.length})',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
    );
  }

  Widget _carteJour(String jour) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(jour,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _creneaux.map((c) {
            final (debut, fin) = c;
            final cle = '$jour|$debut';
            final libre = _libres.contains(cle);
            return GestureDetector(
              onTap: () => setState(() {
                if (libre) {
                  _libres.remove(cle);
                } else {
                  _libres.add(cle);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: libre ? const Color(0xFF10B981) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: libre
                          ? const Color(0xFF10B981)
                          : const Color(0xFFE5E7EB)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(libre ? Icons.check_circle_rounded : Icons.circle_outlined,
                      size: 14,
                      color: libre ? Colors.white : const Color(0xFF9CA3AF)),
                  const SizedBox(width: 6),
                  Text('$debut–$fin',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: libre ? Colors.white : const Color(0xFF4B5563))),
                ]),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }
}

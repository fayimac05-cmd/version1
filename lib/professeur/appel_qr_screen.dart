import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/professor_service.dart';
import '../theme/app_palette.dart';

/// Session d'appel par QR code : le prof projette le QR + code à 6 chiffres,
/// les étudiants pointent depuis leur téléphone, le suivi est en direct.
/// À la clôture, les non-pointés sont marqués absents (notification + SMS parent).
class AppelQrScreen extends StatefulWidget {
  const AppelQrScreen({
    super.key,
    required this.filiereId,
    required this.filiereNom,
    required this.niveau,
    required this.moduleId,
    required this.moduleNom,
  });

  final int filiereId;
  final String filiereNom;
  final String? niveau;
  final int moduleId;
  final String moduleNom;

  @override
  State<AppelQrScreen> createState() => _AppelQrScreenState();
}

class _AppelQrScreenState extends State<AppelQrScreen> {
  String? _sessionId;
  String? _code;
  String? _token;
  bool _loading = true;
  bool _cloture = false;
  String? _error;
  int _nbAttendus = 0;
  List<dynamic> _presences = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _ouvrirSession();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _ouvrirSession() async {
    final result = await ProfessorService.ouvrirSessionQr({
      'filiere_id': widget.filiereId,
      'filiere_nom': widget.filiereNom,
      'niveau': widget.niveau,
      'module_id': widget.moduleId,
    });
    if (!mounted) return;
    if (result['success'] != true) {
      setState(() {
        _loading = false;
        _error = result['error'];
      });
      return;
    }
    setState(() {
      _loading = false;
      _sessionId = result['session_id'];
      _code = result['code'];
      _token = result['token'];
    });
    // Suivi en direct par sondage toutes les 4 s.
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _rafraichir());
    _rafraichir();
  }

  Future<void> _rafraichir() async {
    if (_sessionId == null || _cloture) return;
    final result = await ProfessorService.getSessionQr(_sessionId!);
    if (!mounted || result['success'] != true) return;
    final data = result['data'] as Map<String, dynamic>;
    setState(() {
      _nbAttendus = data['nb_attendus'] ?? 0;
      _presences = (data['presences'] as List<dynamic>?) ?? [];
    });
  }

  Future<void> _cloturer() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clôturer l\'appel ?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          'Les ${_nbAttendus - _presences.length} étudiant(s) qui n\'ont pas pointé '
          'seront marqués absents. Leurs parents recevront un SMS.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('Clôturer'),
          ),
        ],
      ),
    );
    if (confirme != true || _sessionId == null || !mounted) return;

    final result = await ProfessorService.cloturerSessionQr(_sessionId!);
    if (!mounted) return;
    if (result['success'] == true) {
      _pollTimer?.cancel();
      setState(() => _cloture = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Appel clôturé. ${result['nb_absents'] ?? 0} absent(s) notifié(s).'),
        backgroundColor: const Color(0xFF10B981),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'] ?? 'Erreur lors de la clôture.'),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Appel QR — ${widget.moduleNom}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppPalette.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, style: const TextStyle(color: Colors.red))))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (!_cloture) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)],
                        ),
                        child: Column(children: [
                          Text('${widget.filiereNom} · ${widget.niveau ?? ''}',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                          const SizedBox(height: 14),
                          if (_token != null)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: QrImageView(
                                  data: _token!,
                                  size: 250,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                          const SizedBox(height: 14),
                          const Text('ou saisir le code :',
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 6),
                          Text(
                            _code ?? '',
                            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800,
                                letterSpacing: 10, color: Color(0xFF0A3D91)),
                          ),
                          const SizedBox(height: 6),
                          const Text('Session valable 10 minutes',
                              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Pointages : ${_presences.length}/$_nbAttendus',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A))),
                      if (!_cloture)
                        ElevatedButton.icon(
                          onPressed: _cloturer,
                          icon: const Icon(Icons.stop_circle_outlined, size: 18),
                          label: const Text('Clôturer', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                    ]),
                    const SizedBox(height: 10),
                    if (_presences.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('En attente des premiers pointages...',
                            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)))),
                      ),
                    ..._presences.map((p) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            Icon(
                              p['statut'] == 'present'
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 20,
                              color: p['statut'] == 'present'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('${p['prenoms'] ?? ''} ${p['nom'] ?? ''}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A))),
                            ),
                            Text('${p['matricule'] ?? ''}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          ]),
                        )),
                  ],
                ),
    );
  }
}

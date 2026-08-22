import 'package:flutter/material.dart';
import '../../services/parent_service.dart';
import 'parent_styles.dart';

class ParentGradesTab extends StatefulWidget {
  final String nomEnfant;
  final String? etudiantId;

  const ParentGradesTab({
    super.key,
    required this.nomEnfant,
    this.etudiantId,
  });

  @override
  State<ParentGradesTab> createState() => _ParentGradesTabState();
}

class _ParentGradesTabState extends State<ParentGradesTab> {
  late Future<Map<String, dynamic>> _notesFuture;

  @override
  void initState() {
    super.initState();
    _notesFuture = _fetchNotes();
  }

  Future<Map<String, dynamic>> _fetchNotes() async {
    if (widget.etudiantId == null || widget.etudiantId!.isEmpty) {
      return {'success': false, 'error': 'Identifiant étudiant non disponible.'};
    }
    return ParentService.getEnfantNotes(widget.etudiantId!);
  }

  Color _statusColor(double? valeur) {
    if (valeur == null) return ParentStyles.textMuted;
    if (valeur >= 10) return ParentStyles.success;
    if (valeur >= 8) return ParentStyles.warning;
    return ParentStyles.danger;
  }

  Color _statusBgColor(double? valeur) {
    if (valeur == null) return const Color(0xFFF1F5F9);
    if (valeur >= 10) return ParentStyles.successLight;
    if (valeur >= 8) return ParentStyles.warningLight;
    return ParentStyles.dangerLight;
  }

  String _statusLabel(double? valeur) {
    if (valeur == null) return 'En attente';
    if (valeur >= 10) return 'Validé';
    if (valeur >= 8) return 'En danger';
    return 'Blâmable';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParentStyles.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF1E293B),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _notesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!['success'] != true) {
            final error = snapshot.data?['error'] ?? 'Impossible de charger les notes.';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(error, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() => _notesFuture = _fetchNotes()),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<dynamic> notes = snapshot.data!['data'] ?? [];

          if (notes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grading_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Aucune note disponible pour le moment.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Calcul de la moyenne générale
          final notesAvecValeur = notes
              .where((n) => n['valeur'] != null)
              .map((n) => double.tryParse(n['valeur'].toString()) ?? 0.0)
              .toList();
          final moyenne = notesAvecValeur.isEmpty
              ? null
              : notesAvecValeur.reduce((a, b) => a + b) / notesAvecValeur.length;

          return RefreshIndicator(
            onRefresh: () async => setState(() => _notesFuture = _fetchNotes()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Carte de la moyenne générale
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Moyenne Générale',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              moyenne != null ? moyenne.toStringAsFixed(2) : '-',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.nomEnfant,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.school_rounded, color: Colors.white38, size: 60),
                    ],
                  ),
                ),

                // Liste des notes
                ...notes.map((note) {
                  final valeur = note['valeur'] != null
                      ? double.tryParse(note['valeur'].toString())
                      : null;
                  final module = note['module_nom'] ?? 'Module inconnu';
                  final prof = '${note['prof_prenoms'] ?? ''} ${note['prof_nom'] ?? ''}'.trim();
                  final dateStr = note['date_session'] != null
                      ? DateTime.tryParse(note['date_session'].toString())
                          ?.toLocal()
                          .toString()
                          .substring(0, 10)
                      : null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        // Note
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _statusBgColor(valeur),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            valeur?.toStringAsFixed(1) ?? '-',
                            style: TextStyle(
                              color: _statusColor(valeur),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Info module
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                module,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              if (prof.isNotEmpty)
                                Text(
                                  'Prof. $prof',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              if (dateStr != null)
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Badge statut
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusBgColor(valeur),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel(valeur),
                            style: TextStyle(
                              color: _statusColor(valeur),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

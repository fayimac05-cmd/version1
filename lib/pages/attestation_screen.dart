import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import 'pdf_viewer_screen.dart';

class AttestationScreen extends StatefulWidget {
  final StudentProfile profile;
  const AttestationScreen({super.key, required this.profile});

  @override
  State<AttestationScreen> createState() => _AttestationScreenState();
}

class _AttestationScreenState extends State<AttestationScreen> {
  final List<Map<String, dynamic>> _attestations = [
    {
      'type': 'Attestation d\'inscription',
      'annee': '2024-2025',
      'statut': 'Prêt',
      'dateDemande': '20 Oct 2024',
      'fichier': 'attestation_inscription_2024_2025.pdf',
      'color': AppPalette.blue,
      'sigle': 'IST',
      'pages': '1 page',
      'taille': '420 KB',
    },
    {
      'type': 'Certificat de scolarité',
      'annee': '2024-2025',
      'statut': 'Prêt',
      'dateDemande': '15 Nov 2024',
      'fichier': 'certificat_scolarite_2024_2025.pdf',
      'color': AppPalette.blue,
      'sigle': 'IST',
      'pages': '1 page',
      'taille': '380 KB',
    },
    {
      'type': 'Attestation de réussite L1',
      'annee': '2023-2024',
      'statut': 'En cours',
      'dateDemande': '20 Juin 2026',
      'fichier': 'attestation_reussite_L1.pdf',
      'color': AppPalette.yellow,
      'sigle': 'IST',
      'pages': '1 page',
      'taille': '510 KB',
    },
  ];

  void _demanderAttestation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewRequestSheet(
        onSuccess: (newRequest) {
          setState(() {
            _attestations.insert(0, newRequest);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Attestations d\'inscription',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppPalette.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Banner Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppPalette.blue.withOpacity(0.06),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppPalette.blue, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Vos documents officiels signés numériquement par l\'IST. Prêts à être téléchargés ou partagés.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppPalette.blue.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _attestations.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune attestation disponible.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _attestations.length,
                    itemBuilder: (context, index) {
                      final item = _attestations[index];
                      final isReady = item['statut'] == 'Prêt';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: (isReady
                                        ? AppPalette.blue
                                        : AppPalette.yellow)
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isReady
                                    ? Icons.assignment_turned_in_rounded
                                    : Icons.hourglass_empty_rounded,
                                color: isReady
                                    ? AppPalette.blue
                                    : const Color(0xFFD97706),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              item['type'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            subtitle: Text(
                              'Année : ${item['annee']} • Demandé le : ${item['dateDemande']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isReady
                                    ? const Color(0xFF15803D).withOpacity(0.1)
                                    : const Color(0xFFD97706).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item['statut'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isReady
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFD97706),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(color: Color(0xFFF1F5F9)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.file_present_rounded,
                                          size: 16,
                                          color: Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            item['fichier'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                              fontStyle: FontStyle.italic,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '${item['taille']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (isReady)
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      PdfViewerScreen(pdf: item),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.visibility,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                            label: const Text('Consulter'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppPalette.blue,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              elevation: 0,
                                            ),
                                          )
                                        else
                                          Text(
                                            'Traitement en cours par l\'administration...',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: const Color(0xFFD97706)
                                                  .withOpacity(0.9),
                                              fontWeight: FontWeight.w500,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton.extended(
          onPressed: _demanderAttestation,
          backgroundColor: AppPalette.blue,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Demander un document',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _NewRequestSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onSuccess;
  const _NewRequestSheet({required this.onSuccess});

  @override
  State<_NewRequestSheet> createState() => _NewRequestSheetState();
}

class _NewRequestSheetState extends State<_NewRequestSheet> {
  String _selectedType = 'Attestation d\'inscription';
  String _selectedAnnee = '2024-2025';
  String _selectedMotif = 'Usage administratif';
  bool _isLoading = false;

  final List<String> _types = [
    'Attestation d\'inscription',
    'Certificat de scolarité',
    'Attestation de réussite',
  ];

  final List<String> _annees = [
    '2024-2025',
    '2023-2024',
  ];

  final List<String> _motifs = [
    'Usage administratif',
    'Dossier de bourse',
    'Demande de visa',
    'Autre motif personnel',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle indicator
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Nouvelle Demande',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Remplissez ce formulaire pour soumettre une demande officielle de document académique.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),

            // Type de document
            const Text(
              'Type de document',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppPalette.blue),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: 16),

            // Année académique
            const Text(
              'Année académique',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedAnnee,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppPalette.blue),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _annees
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedAnnee = val);
              },
            ),
            const SizedBox(height: 16),

            // Motif de demande
            const Text(
              'Motif de la demande',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedMotif,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppPalette.blue),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _motifs
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedMotif = val);
              },
            ),
            const SizedBox(height: 28),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            await Future.delayed(
                                const Duration(milliseconds: 1500));
                            if (!mounted) return;

                            final Map<String, dynamic> newRequest = {
                              'type': _selectedType,
                              'annee': _selectedAnnee,
                              'statut': 'En cours',
                              'dateDemande': 'Aujourd\'hui',
                              'fichier':
                                  '${_selectedType.replaceAll(' ', '_').replaceAll('\'', '_').toLowerCase()}_${_selectedAnnee.replaceAll('-', '_')}.pdf',
                              'color': AppPalette.yellow,
                              'sigle': 'IST',
                              'pages': '1 page',
                              'taille': '250 KB',
                            };

                            widget.onSuccess(newRequest);
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: const [
                                    Icon(Icons.check_circle_rounded,
                                        color: Colors.white),
                                    SizedBox(width: 10),
                                    Text(
                                        'Demande enregistrée. En attente de signature.'),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF15803D),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Soumettre',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../services/parent_service.dart';
import 'parent_styles.dart';

class ParentBulletinsTab extends StatefulWidget {
  final String nomEnfant;
  final String etudiantId;

  const ParentBulletinsTab({
    super.key,
    required this.nomEnfant,
    required this.etudiantId,
  });

  @override
  State<ParentBulletinsTab> createState() => _ParentBulletinsTabState();
}

class _ParentBulletinsTabState extends State<ParentBulletinsTab> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ParentService.getEnfantBulletins(widget.etudiantId);
  }

  Color _couleurStatut(String? statut) {
    switch (statut) {
      case 'Validé':
        return ParentStyles.success;
      case 'Ajourné':
        return ParentStyles.warning;
      case 'Invalidé':
        return ParentStyles.danger;
      default:
        return ParentStyles.textMuted;
    }
  }

  Color _fondStatut(String? statut) {
    switch (statut) {
      case 'Validé':
        return ParentStyles.successLight;
      case 'Ajourné':
        return ParentStyles.warningLight;
      case 'Invalidé':
        return ParentStyles.dangerLight;
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParentStyles.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Bulletins · ${widget.nomEnfant}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E293B)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!['success'] != true) {
            final error = snapshot.data?['error'] ?? 'Impossible de charger les bulletins.';
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
                      onPressed: () => setState(() => _future = ParentService.getEnfantBulletins(widget.etudiantId)),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<dynamic> bulletins = snapshot.data!['data'] ?? [];
          if (bulletins.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Aucun bulletin publié pour le moment.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                setState(() => _future = ParentService.getEnfantBulletins(widget.etudiantId)),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bulletins.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final b = bulletins[i];
                final moyenne = b['moyenne_generale'] != null ? double.tryParse(b['moyenne_generale'].toString()) : null;
                final statut = b['statut'] as String?;
                final datePub = b['date_publication'] != null
                    ? DateTime.tryParse(b['date_publication'].toString())?.toLocal().toString().substring(0, 10)
                    : null;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: ParentStyles.cardDecoration(),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(color: _fondStatut(statut), borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        child: Text(
                          moyenne?.toStringAsFixed(1) ?? '-',
                          style: TextStyle(color: _couleurStatut(statut), fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${b['semestre'] ?? ''} · ${b['annee_academique'] ?? ''}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: ParentStyles.textDark),
                            ),
                            if (datePub != null)
                              Text('Publié le $datePub', style: const TextStyle(fontSize: 12, color: ParentStyles.textMuted)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: _fondStatut(statut), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          statut ?? '—',
                          style: TextStyle(color: _couleurStatut(statut), fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_palette.dart';
import '../admin/admin_theme.dart';
import '../pages/create_event_page.dart';
import '../services/api_service.dart';

// Déclaration globale de la couleur émeraude
const Color emeraldColor = Color(0xFF10B981);

// ════════════════════════════════════════════════════════════════════════════
// WIDGET PRINCIPAL — Gestion des événements BDE (données du backend)
// ════════════════════════════════════════════════════════════════════════════
class AdminBDE extends StatefulWidget {
  const AdminBDE({super.key});
  @override State<AdminBDE> createState() => _AdminBDEState();
}

class _AdminBDEState extends State<AdminBDE> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _evenements = [];
  List<Map<String, dynamic>> _inscriptions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadEvenements();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadEvenements() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    final results = await Future.wait([
      ApiService.getEvenements(),
      ApiService.getHistoriqueInscriptions(),
    ]);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (results[0]['success'] == true) {
        _evenements = (results[0]['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      } else {
        _errorMessage = results[0]['error'] as String?;
      }
      if (results[1]['success'] == true) {
        _inscriptions = (results[1]['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      }
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Map<String, dynamic>> get _enAttente =>
      _evenements.where((e) => e['statut'] == 'en_attente').toList();

  @override
  Widget build(BuildContext context) {
    final isMobile = AdminTheme.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BDE & Événements',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                          SizedBox(height: 4),
                          Text('Créez des événements et validez ceux proposés par les étudiants',
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading ? null : _loadEvenements,
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
                      tooltip: 'Actualiser',
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateEventPage()),
                        );
                        if (result != null) {
                          _showSnack('🚀 Événement créé et approuvé — il est visible dans le carrousel étudiant.');
                          _loadEvenements();
                        }
                      },
                      icon: const Icon(Icons.add_rounded, size: 18, color: AdminTheme.iconFgAlt),
                      label: const Text('Nouvel événement',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminTheme.iconFgAlt)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.iconBgAlt,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TabBar(
                  controller: _tab,
                  labelColor: AdminTheme.iconBg,
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: AdminTheme.iconFgAlt,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(text: 'Tous les événements (${_evenements.length})'),
                    Tab(text: 'À valider (${_enAttente.length})'),
                    Tab(text: 'Historique (${_inscriptions.length})'),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFE2E8F0)),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : TabBarView(
                        controller: _tab,
                        children: [
                          _buildListe(_evenements, isMobile),
                          _buildListe(_enAttente, isMobile),
                          _buildHistorique(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 32),
            const SizedBox(height: 12),
            Text(_errorMessage ?? 'Erreur',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadEvenements, child: const Text('Réessayer')),
          ],
        ),
      );

  Widget _buildListe(List<Map<String, dynamic>> items, bool isMobile) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: AdminTheme.iconBg, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.celebration_outlined, color: AdminTheme.iconFg, size: 26),
            ),
            const SizedBox(height: 16),
            const Text('Aucun événement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            const Text('Cliquez sur « Nouvel événement » pour en créer un.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => _carteEvenement(items[i], isMobile),
    );
  }

  Widget _carteEvenement(Map<String, dynamic> e, bool isMobile) {
    final statut = e['statut'] as String? ?? 'en_attente';
    final inscrits = int.tryParse(e['inscrits']?.toString() ?? '') ?? 0;
    final capacite = int.tryParse(e['capacite']?.toString() ?? '') ?? 0;
    final prix = double.tryParse(e['prix']?.toString() ?? '') ?? 0;
    final date = DateTime.tryParse(e['date_debut'] ?? '');
    final pct = capacite > 0 ? (inscrits / capacite).clamp(0.0, 1.0) : 0.0;

    Color statusColor;
    String statusLabel;
    switch (statut) {
      case 'approuve':
        statusColor = emeraldColor;
        statusLabel = 'Approuvé';
        break;
      case 'annule':
        statusColor = Colors.redAccent;
        statusLabel = 'Annulé';
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'En attente';
    }

    final auteur = [e['auteur_prenoms'], e['auteur_nom']]
        .where((x) => x != null && x.toString().isNotEmpty)
        .join(' ');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statut == 'en_attente' ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e['titre'] ?? '',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _infoChip(Icons.calendar_today_outlined,
                            date != null ? DateFormat('dd MMM yyyy · HH:mm').format(date) : '—'),
                        _infoChip(Icons.location_on_outlined,
                            (e['lieu'] ?? '').toString().isNotEmpty ? e['lieu'] : 'Lieu à confirmer'),
                        _infoChip(Icons.confirmation_number_outlined,
                            prix > 0 ? '${prix.toStringAsFixed(0)} FCFA' : 'Gratuit'),
                        if (auteur.isNotEmpty) _infoChip(Icons.person_outline, auteur),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(statusLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(pct > 0.8 ? emeraldColor : AppPalette.blue),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$inscrits / ${capacite > 0 ? capacite : '∞'} inscrits',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (statut == 'en_attente')
                TextButton.icon(
                  onPressed: () => _changerStatut(e, 'approuve'),
                  icon: const Icon(Icons.check_circle_outline, size: 15, color: emeraldColor),
                  label: const Text('Approuver',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: emeraldColor)),
                ),
              if (statut == 'approuve')
                TextButton.icon(
                  onPressed: () => _changerStatut(e, 'annule'),
                  icon: const Icon(Icons.cancel_outlined, size: 15, color: Color(0xFFF59E0B)),
                  label: const Text('Annuler l\'événement',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                ),
              if (statut == 'annule')
                TextButton.icon(
                  onPressed: () => _changerStatut(e, 'approuve'),
                  icon: const Icon(Icons.restore_rounded, size: 15, color: emeraldColor),
                  label: const Text('Réactiver',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: emeraldColor)),
                ),
              const Spacer(),
              IconButton(
                onPressed: () => _confirmerSuppression(e),
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Historique des inscriptions (même contenu que la page Annonces) ────
  Widget _buildHistorique() {
    if (_inscriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: AdminTheme.iconBg, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.history_rounded, color: AdminTheme.iconFg, size: 26),
            ),
            const SizedBox(height: 16),
            const Text('Aucune inscription', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            const Text('Les inscriptions des étudiants aux événements apparaîtront ici.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _inscriptions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildInscriptionCard(_inscriptions[i]),
    );
  }

  Widget _buildInscriptionCard(Map<String, dynamic> ins) {
    final nomComplet = [ins['prenoms'], ins['nom']]
        .where((x) => x != null && x.toString().isNotEmpty)
        .join(' ');
    final date = DateTime.tryParse(ins['createdAt'] ?? '');
    final prix = double.tryParse(ins['prix']?.toString() ?? '') ?? 0;
    final details = [
      if ((ins['matricule'] ?? '').toString().isNotEmpty) 'Matricule : ${ins['matricule']}',
      if ((ins['email'] ?? '').toString().isNotEmpty) ins['email'],
      if ((ins['telephone'] ?? '').toString().isNotEmpty) ins['telephone'],
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: emeraldColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.how_to_reg_rounded, color: emeraldColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nomComplet.isEmpty ? 'Étudiant' : nomComplet,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text('S\'est inscrit à « ${ins['evenement_titre'] ?? ''} »',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(details, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(date != null ? _formatDisplayDate(date) : '',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: emeraldColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(prix > 0 ? '${prix.toStringAsFixed(0)} FCFA' : 'Gratuit',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: emeraldColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDisplayDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Widget _infoChip(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      );

  Future<void> _changerStatut(Map<String, dynamic> e, String statut) async {
    final result = await ApiService.updateEvenementStatut(e['id'].toString(), statut);
    if (!mounted) return;
    if (result['success'] == true) {
      _showSnack(statut == 'approuve'
          ? '🚀 Événement approuvé — il apparaît maintenant dans le carrousel étudiant.'
          : 'Événement annulé.');
      _loadEvenements();
    } else {
      _showSnack(result['error'] as String? ?? 'Erreur lors de la mise à jour.', isError: true);
    }
  }

  void _confirmerSuppression(Map<String, dynamic> e) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Confirmer la suppression', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Supprimer l\'événement « ${e['titre']} » ? Les inscriptions associées seront perdues.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ApiService.deleteEvenement(e['id'].toString());
              if (!mounted) return;
              if (result['success'] == true) {
                _showSnack('Événement supprimé.');
                _loadEvenements();
              } else {
                _showSnack(result['error'] as String? ?? 'Erreur lors de la suppression.', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

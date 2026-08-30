import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../pages/create_event_page.dart';
import '../services/api_service.dart';

// ════════════════════════════════════════════════════════════════════════════
// ENUMS & CONFIGURATIONS MÉTIER
// ════════════════════════════════════════════════════════════════════════════
enum PorteeAnnonce { globale, filiere, niveau }
enum StatutAnnonce { brouillon, publie }

const Color _emeraldColor = Color(0xFF10B981);

const List<Map<String, String>> cibleRoleOptions = [
  {'val': 'tous', 'label': 'Tout l\'établissement'},
  {'val': 'etudiant', 'label': 'Étudiants'},
  {'val': 'professeur', 'label': 'Professeurs'},
  {'val': 'bde', 'label': 'BDE'},
];

final List<String> istNiveaux = ['Licence 1', 'Licence 2', 'Licence 3', 'Master 1', 'Master 2'];

class Annonce {
  final String id;
  String titre, contenu;
  String cibleRole;
  String? filiereId, filiereNom, niveau;
  StatutAnnonce statut;
  final DateTime dateCreation;
  List<String> fichiers;

  Annonce({
    required this.id, required this.titre, required this.contenu,
    required this.cibleRole, required this.statut,
    required this.dateCreation, this.filiereId, this.filiereNom, this.niveau,
    List<String>? fichiers,
  }) : fichiers = fichiers ?? [];

  factory Annonce.fromJson(Map<String, dynamic> json) {
    return Annonce(
      id: json['id'].toString(),
      titre: json['titre'] ?? '',
      contenu: json['contenu'] ?? '',
      cibleRole: json['cibleRole'] ?? 'tous',
      filiereId: json['filiere']?.toString(),
      filiereNom: json['filiere_nom'],
      niveau: json['niveau'],
      statut: json['statut'] == 'publie' ? StatutAnnonce.publie : StatutAnnonce.brouillon,
      dateCreation: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      fichiers: (json['fichiers'] as List<dynamic>? ?? []).map((f) => f.toString()).toList(),
    );
  }

  PorteeAnnonce get portee {
    if (filiereId != null && filiereId!.isNotEmpty) return PorteeAnnonce.filiere;
    if (niveau != null && niveau!.isNotEmpty) return PorteeAnnonce.niveau;
    return PorteeAnnonce.globale;
  }
}

class AnnonceUiConfig {
  final String label;
  final IconData icon;
  final Color color;
  const AnnonceUiConfig({required this.label, required this.icon, required this.color});

  static AnnonceUiConfig getCibleConfig(String cibleRole) {
    switch (cibleRole) {
      case 'etudiant':
        return const AnnonceUiConfig(label: 'Étudiants', icon: Icons.school_outlined, color: AdminTheme.iconBg);
      case 'professeur':
        return const AnnonceUiConfig(label: 'Professeurs', icon: Icons.assignment_ind_outlined, color: Colors.purple);
      case 'bde':
        return const AnnonceUiConfig(label: 'BDE', icon: Icons.groups_outlined, color: _emeraldColor);
      default:
        return const AnnonceUiConfig(label: 'Tout l\'établissement', icon: Icons.campaign_outlined, color: Colors.redAccent);
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// VUE PRINCIPALE — TABLEAU DE BORD DES ANNONCES
// ════════════════════════════════════════════════════════════════════════════
class AdminAnnonces extends StatefulWidget {
  const AdminAnnonces({super.key});
  @override State<AdminAnnonces> createState() => _AdminAnnoncesState();
}

class _AdminAnnoncesState extends State<AdminAnnonces> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _searchQuery = '';
  List<Annonce> _annonces = [];
  List<Map<String, dynamic>> _filieres = [];
  List<Map<String, dynamic>> _inscriptions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    final results = await Future.wait([
      ApiService.getAnnonces(),
      ApiService.getFilieres(),
      ApiService.getHistoriqueInscriptions(),
    ]);
    final annoncesResult = results[0];
    final filieresResult = results[1];
    final inscriptionsResult = results[2];

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (annoncesResult['success'] == true) {
        _annonces = (annoncesResult['data'] as List<dynamic>)
            .map((j) => Annonce.fromJson(j as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = annoncesResult['error'] as String?;
      }
      if (filieresResult['success'] == true) {
        _filieres = (filieresResult['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      }
      if (inscriptionsResult['success'] == true) {
        _inscriptions = (inscriptionsResult['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      }
    });
  }

  List<Annonce> get _filteredAnnonces {
    var list = List<Annonce>.from(_annonces);
    if (_searchQuery.isNotEmpty) {
      list = list.where((a) =>
          a.titre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.contenu.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    return list;
  }

  List<Annonce> _getAnnoncesByStatut(StatutAnnonce? statut) => statut == null
      ? _filteredAnnonces
      : _filteredAnnonces.where((a) => a.statut == statut).toList();

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

  @override
  Widget build(BuildContext context) {
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Canal de Communication', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text('Diffusez des notes d\'information ciblées par filière et niveau d\'études', style: TextStyle(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading ? null : _loadData,
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
                      tooltip: 'Actualiser',
                    ),
                    const SizedBox(width: 8),
                    IntrinsicWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCreateButton(),
                          const SizedBox(height: 8),
                          _buildCreateEventButton(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher une annonce par mot-clé...',
                      hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                      prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TabBar(
                  controller: _tabs,
                  labelColor: AdminTheme.iconBg,
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: AdminTheme.iconFgAlt,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(text: 'Toutes les annonces (${_filteredAnnonces.length})'),
                    Tab(text: 'En ligne (${_getAnnoncesByStatut(StatutAnnonce.publie).length})'),
                    Tab(text: 'Brouillons (${_getAnnoncesByStatut(StatutAnnonce.brouillon).length})'),
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
                        controller: _tabs,
                        children: [
                          _buildListView(_getAnnoncesByStatut(null)),
                          _buildListView(_getAnnoncesByStatut(StatutAnnonce.publie)),
                          _buildListView(_getAnnoncesByStatut(StatutAnnonce.brouillon)),
                          _buildHistoriqueView(),
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
            Text(_errorMessage ?? 'Erreur', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadData, child: const Text('Réessayer')),
          ],
        ),
      );

  Widget _buildCreateButton() => ElevatedButton.icon(
        onPressed: () => _openFormModal(),
        icon: const Icon(Icons.add_rounded, size: 18, color: AdminTheme.iconFgAlt),
        label: const Text('Nouvelle annonce', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminTheme.iconFgAlt)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminTheme.iconBgAlt,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      );

  // ── Historique des inscriptions aux événements ─────────────────────────
  Widget _buildHistoriqueView() {
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
              color: _emeraldColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.how_to_reg_rounded, color: _emeraldColor, size: 18),
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
                  color: _emeraldColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(prix > 0 ? '${prix.toStringAsFixed(0)} FCFA' : 'Gratuit',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _emeraldColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateEventButton() => ElevatedButton.icon(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEventPage()),
          );
          if (result != null) {
            _showSnack('🚀 Événement créé et approuvé — visible dans le carrousel étudiant.');
          }
        },
        icon: const Icon(Icons.celebration_outlined, size: 18, color: Colors.white),
        label: const Text('Créer un événement',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      );

  Widget _buildListView(List<Annonce> annonces) {
    if (annonces.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: AdminTheme.iconBg, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.campaign_outlined, color: AdminTheme.iconFg, size: 26)),
            const SizedBox(height: 16),
            const Text('Flux vide', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            const Text('Aucune publication ne correspond à ce critère.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: annonces.length,
      itemBuilder: (_, i) => _buildAnnonceCard(annonces[i]),
    );
  }

  Widget _buildAnnonceCard(Annonce a) {
    final cibleConfig = AnnonceUiConfig.getCibleConfig(a.cibleRole);
    final statusColor = a.statut == StatutAnnonce.publie ? _emeraldColor : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: cibleConfig.color.withValues(alpha:0.08), borderRadius: BorderRadius.circular(8)),
                  child: Icon(cibleConfig.icon, color: cibleConfig.color, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.titre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8, runSpacing: 4,
                        children: [
                          _buildCardTag(cibleConfig.label, cibleConfig.color),
                          _buildCardTag(_getCibleText(a), const Color(0xFF475569), isFilled: false),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha:0.1), borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        children: [
                          Container(width: 5, height: 5, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text(a.statut == StatutAnnonce.publie ? 'En ligne' : 'Brouillon', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_formatDisplayDate(a.dateCreation), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(a.contenu, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5)),
          ),
          if (a.fichiers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Wrap(spacing: 8, runSpacing: 6, children: a.fichiers.map((f) => _buildPjBadge(f)).toList()),
            ),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => _openFormModal(annonce: a),
                  icon: const Icon(Icons.edit_outlined, size: 15, color: AdminTheme.iconBg),
                  label: const Text('Éditer l\'annonce', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.iconBg)),
                ),
                const SizedBox(width: 8),
                if (a.statut == StatutAnnonce.brouillon)
                  TextButton.icon(
                    onPressed: () => _togglePublication(a, StatutAnnonce.publie),
                    icon: const Icon(Icons.rocket_launch_outlined, size: 15, color: _emeraldColor),
                    label: const Text('Publier l\'annonce', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _emeraldColor)),
                  ),
                if (a.statut == StatutAnnonce.publie)
                  TextButton.icon(
                    onPressed: () => _togglePublication(a, StatutAnnonce.brouillon),
                    icon: const Icon(Icons.inventory_2_outlined, size: 15, color: Color(0xFFF59E0B)),
                    label: const Text('Déposer en brouillon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showDeleteConfirmation(a),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                  style: IconButton.styleFrom(hoverColor: Colors.red.withValues(alpha:0.05)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTag(String text, Color color, {bool isFilled = true}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isFilled ? color.withValues(alpha:0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isFilled ? null : Border.all(color: color.withValues(alpha:0.3)),
        ),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      );

  Widget _buildPjBadge(String fileUrl) {
    final name = fileUrl.split('/').last;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_file_rounded, size: 14, color: Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Future<void> _togglePublication(Annonce a, StatutAnnonce newStatus) async {
    final result = newStatus == StatutAnnonce.publie
        ? await ApiService.publishAnnonce(a.id)
        : await ApiService.updateAnnonce(a.id, {'statut': 'brouillon'});
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() => a.statut = newStatus);
      _showSnack(newStatus == StatutAnnonce.publie
          ? '🚀 L\'avis d\'information a été publié sur les terminaux étudiants.'
          : '💾 Document consigné dans vos brouillons.');
    } else {
      _showSnack(result['error'] as String? ?? 'Erreur lors de la mise à jour.', isError: true);
    }
  }

  void _openFormModal({Annonce? annonce}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormulaireAnnonce(
        annonce: annonce,
        filieres: _filieres,
        onSave: (data, finalStatus) async {
          final payload = {
            ...data,
            'statut': finalStatus == StatutAnnonce.publie ? 'publie' : 'brouillon',
          };
          Map<String, dynamic> result;
          if (annonce != null) {
            result = await ApiService.updateAnnonce(annonce.id, payload);
          } else {
            result = await ApiService.createAnnonce(payload);
          }
          if (!mounted) return false;
          if (result['success'] == true) {
            Navigator.pop(context);
            _showSnack(finalStatus == StatutAnnonce.publie
                ? '🚀 L\'avis d\'information a été publié sur les terminaux étudiants.'
                : '💾 Document consigné dans vos brouillons.');
            _loadData();
            return true;
          } else {
            _showSnack(result['error'] as String? ?? 'Erreur lors de l\'enregistrement.', isError: true);
            return false;
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(Annonce a) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Confirmer la suppression', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Êtes-vous sûr de vouloir détruire l\'annonce « ${a.titre} » ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ApiService.deleteAnnonce(a.id);
              if (!mounted) return;
              if (result['success'] == true) {
                setState(() => _annonces.removeWhere((x) => x.id == a.id));
                _showSnack('Annonce supprimée avec succès.');
              } else {
                _showSnack(result['error'] as String? ?? 'Erreur lors de la suppression.', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0),
            child: const Text('Supprimer définitivement', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getCibleText(Annonce a) {
    switch (a.portee) {
      case PorteeAnnonce.globale: return 'Tous les étudiants';
      case PorteeAnnonce.filiere: return 'Filière : ${a.filiereNom ?? a.filiereId}';
      case PorteeAnnonce.niveau:  return 'Niveau : ${a.niveau}';
    }
  }

  String _formatDisplayDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PANNEAU FORMULAIRE D'ÉDITION
// ════════════════════════════════════════════════════════════════════════════
class _FormulaireAnnonce extends StatefulWidget {
  final Annonce? annonce;
  final List<Map<String, dynamic>> filieres;
  final Future<bool> Function(Map<String, dynamic>, StatutAnnonce) onSave;
  const _FormulaireAnnonce({this.annonce, required this.filieres, required this.onSave});

  @override State<_FormulaireAnnonce> createState() => _FormulaireAnnonceState();
}

class _FormulaireAnnonceState extends State<_FormulaireAnnonce> {
  final _titreController = TextEditingController();
  final _contenuController = TextEditingController();

  String _selectedCibleRole = 'tous';
  PorteeAnnonce _selectedPortee = PorteeAnnonce.globale;
  String? _selectedFiliere, _selectedNiveau;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.annonce != null) {
      final a = widget.annonce!;
      _titreController.text = a.titre;
      _contenuController.text = a.contenu;
      _selectedCibleRole = a.cibleRole;
      _selectedPortee = a.portee;
      _selectedFiliere = a.filiereId;
      _selectedNiveau = a.niveau;
    }
  }

  @override
  void dispose() {
    _titreController.dispose(); _contenuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 48, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(
              children: [
                Text(widget.annonce == null ? 'Éditer une nouvelle note' : 'Modifier la note existante', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9)),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFE2E8F0)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Titre de l\'avis officiel'),
                  const SizedBox(height: 6),
                  _buildTextField(controller: _titreController, hint: 'Ex: Délibérations des examens de fin de cycle...'),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Texte ou corps de l\'annonce'),
                  const SizedBox(height: 6),
                  _buildBigTextArea(),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Rôle destinataire'),
                  const SizedBox(height: 8),
                  _buildCibleRoleSelector(),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Cible de diffusion'),
                  const SizedBox(height: 8),
                  _buildPorteeSelector(),
                  if (_selectedPortee == PorteeAnnonce.filiere) ...[
                    const SizedBox(height: 14),
                    _buildSectionLabel('Sélectionner la filière IST concernée'),
                    const SizedBox(height: 6),
                    _buildFiliereDropdown(),
                  ],
                  if (_selectedPortee == PorteeAnnonce.niveau) ...[
                    const SizedBox(height: 14),
                    _buildSectionLabel('Sélectionner le niveau académique'),
                    const SizedBox(height: 6),
                    _buildNiveauDropdown(),
                  ],
                ],
              ),
            ),
          ),
          _buildFooterActions(),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)));

  Widget _buildTextField({required TextEditingController controller, required String hint}) => Container(
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)), border: InputBorder.none, contentPadding: const EdgeInsets.all(12)),
        ),
      );

  Widget _buildBigTextArea() => Container(
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: TextField(
          controller: _contenuController, maxLines: 5,
          style: const TextStyle(fontSize: 14, height: 1.5),
          decoration: const InputDecoration(hintText: 'Rédigez l\'intégralité de la note ici...', hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)), border: InputBorder.none, contentPadding: EdgeInsets.all(14)),
        ),
      );

  Widget _buildCibleRoleSelector() {
    return Row(
      children: cibleRoleOptions.map((e) {
        final isSelected = _selectedCibleRole == e['val'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedCibleRole = e['val']!),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AdminTheme.iconBg : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? AdminTheme.iconBg : const Color(0xFFE2E8F0)),
              ),
              child: Text(e['label']!, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF475569))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPorteeSelector() {
    final options = [
      {'val': PorteeAnnonce.globale, 'label': 'Tout l\'établissement'},
      {'val': PorteeAnnonce.filiere, 'label': 'Par filière spécifique'},
      {'val': PorteeAnnonce.niveau, 'label': 'Par niveau d\'étude'},
    ];
    return Row(
      children: options.map((o) {
        final isSelected = _selectedPortee == o['val'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedPortee = o['val'] as PorteeAnnonce;
              _selectedFiliere = null; _selectedNiveau = null;
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? AdminTheme.iconBg : const Color(0xFFD1D5DB), width: isSelected ? 1.5 : 1),
              ),
              child: Center(
                child: Text(
                  o['label'] as String,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? AdminTheme.iconBg : const Color(0xFF475569)),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFiliereDropdown() => _buildDropdownContainer(
        child: DropdownButton<String>(
          value: _selectedFiliere,
          hint: const Text('Choisir la filière', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
          isExpanded: true, underline: const SizedBox(),
          items: widget.filieres.map((f) => DropdownMenuItem(value: f['id'].toString(), child: Text(f['nom']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)))).toList(),
          onChanged: (v) => setState(() => _selectedFiliere = v),
        ),
      );

  Widget _buildNiveauDropdown() => _buildDropdownContainer(
        child: DropdownButton<String>(
          value: _selectedNiveau,
          hint: const Text('Choisir le niveau d\'études', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
          isExpanded: true, underline: const SizedBox(),
          items: istNiveaux.map((n) => DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)))).toList(),
          onChanged: (v) => setState(() => _selectedNiveau = v),
        ),
      );

  Widget _buildDropdownContainer({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: DropdownButtonHideUnderline(child: child),
      );

  Widget _buildFooterActions() => Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => _executeSavingProcedure(StatutAnnonce.brouillon),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), side: const BorderSide(color: Color(0xFFCBD5E1))),
                child: const Text('Sauvegarder en brouillon', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _executeSavingProcedure(StatutAnnonce.publie),
                style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.iconBgAlt, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                child: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.iconFgAlt))
                    : const Text('Publier immédiatement', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminTheme.iconFgAlt)),
              ),
            ),
          ],
        ),
      );

  void _executeSavingProcedure(StatutAnnonce finalStatus) {
    final title = _titreController.text.trim();
    final body = _contenuController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Veuillez remplir les champs obligatoires (Titre et Corps de texte).'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'titre': title,
      'contenu': body,
      'cibleRole': _selectedCibleRole,
      'filiere': _selectedPortee == PorteeAnnonce.filiere ? _selectedFiliere : null,
      'niveau': _selectedPortee == PorteeAnnonce.niveau ? _selectedNiveau : null,
    };

    widget.onSave(payload, finalStatus).then((success) {
      if (mounted && !success) setState(() => _isSaving = false);
    });
  }
}

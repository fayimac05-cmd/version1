import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';

// ════════════════════════════════════════════════════════════════════════════
// ENUMS & CONFIGURATIONS MÉTIER HAUT DE GAMME
// ════════════════════════════════════════════════════════════════════════════
enum TypeAnnonce { urgent, academique, evenement, horaire }
enum PorteeAnnonce { globale, filiere, niveau }
enum StatutAnnonce { brouillon, publie }

// Définition d'une couleur émeraude premium stable (Tailwind Emerald)
const Color _emeraldColor = Color(0xFF10B981);

class PieceJointe {
  final String nom, type; 
  final String? url;
  PieceJointe({required this.nom, required this.type, this.url});
}

class Annonce {
  final String id;
  String titre, contenu;
  TypeAnnonce type;
  PorteeAnnonce portee;
  String? filiereId, niveau;
  StatutAnnonce statut;
  final DateTime dateCreation;
  List<PieceJointe> piecesJointes;

  Annonce({
    required this.id, required this.titre, required this.contenu,
    required this.type, required this.portee, required this.statut,
    required this.dateCreation, this.filiereId, this.niveau,
    List<PieceJointe>? piecesJointes,
  }) : piecesJointes = piecesJointes ?? [];
}

class AnnonceUiConfig {
  final String label;
  final IconData icon;
  final Color color;
  const AnnonceUiConfig({required this.label, required this.icon, required this.color});

  static AnnonceUiConfig getTypeConfig(TypeAnnonce type) {
    switch (type) {
      case TypeAnnonce.urgent:
        return const AnnonceUiConfig(label: 'Crucial / Alerte', icon: Icons.gpp_maybe_rounded, color: Colors.redAccent);
      case TypeAnnonce.academique:
        return const AnnonceUiConfig(label: 'Note Académique', icon: Icons.assignment_outlined, color: AdminTheme.iconBg);
      case TypeAnnonce.evenement:
        return const AnnonceUiConfig(label: 'Événement campus', icon: Icons.local_activity_outlined, color: Colors.purple);
      case TypeAnnonce.horaire:
        return const AnnonceUiConfig(label: 'Emploi du temps', icon: Icons.date_range_rounded, color: _emeraldColor);
    }
  }

  static AnnonceUiConfig getPjConfig(String type) {
    switch (type) {
      case 'pdf':   return const AnnonceUiConfig(label: 'PDF', icon: Icons.picture_as_pdf_rounded, color: Colors.redAccent);
      case 'word':  return const AnnonceUiConfig(label: 'Word', icon: Icons.description_rounded, color: Colors.blueAccent);
      case 'image': return const AnnonceUiConfig(label: 'Image', icon: Icons.image_outlined, color: _emeraldColor);
      case 'video': return const AnnonceUiConfig(label: 'Vidéo', icon: Icons.play_circle_outline_rounded, color: Colors.purple);
      case 'lien':  return const AnnonceUiConfig(label: 'Lien', icon: Icons.link_rounded, color: Colors.cyan);
      default:      return const AnnonceUiConfig(label: 'Fichier', icon: Icons.attach_file_rounded, color: Color(0xFF64748B));
    }
  }
}

final List<Map<String, String>> istFilieres = [
  {'id': 'RIT', 'nom': 'Réseaux Informatiques et Télécommunications (RIT)'},
  {'id': 'IDA', 'nom': 'Informatique de Gestion et Développements d\'Applications (IDA)'},
  {'id': 'ELT', 'nom': 'Génie Électrique · Électrotechnique (ELT)'},
  {'id': 'AGE', 'nom': 'Administration et Gestion des Entreprises (AGE)'},
  {'id': 'GEC', 'nom': 'Gestion des Entreprises et Administrations (GEC)'},
];

final List<String> istNiveaux = ['Licence 1', 'Licence 2', 'Licence 3', 'Master 1', 'Master 2'];

final List<Annonce> _globalAnnoncesList = [
  Annonce(
    id: 'A001', titre: 'Calendrier final des examens du Semestre 4',
    contenu: 'Le secrétariat général informe les étudiants que le calendrier officiel du S4 est validé. Les épreuves débuteront le lundi suivant au campus de l\'IST Ouaga 2000.',
    type: TypeAnnonce.urgent, portee: PorteeAnnonce.globale, statut: StatutAnnonce.publie,
    dateCreation: DateTime.now().subtract(const Duration(hours: 2)),
    piecesJointes: [PieceJointe(nom: 'Planning_General_S4_IST.pdf', type: 'pdf')],
  ),
  Annonce(
    id: 'A002', titre: 'Notes de rattrapages disponibles — Session Mai',
    contenu: 'Les fiches de notes après délibération pour la filière Réseaux (RIT) L2 sont consultables. Veuillez signaler toute réclamation sous 48h.',
    type: TypeAnnonce.academique, portee: PorteeAnnonce.filiere, filiereId: 'RIT', statut: StatutAnnonce.publie,
    dateCreation: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

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

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  List<Annonce> get _filteredAnnonces {
    var list = List<Annonce>.from(_globalAnnoncesList);
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
                    _buildCreateButton(),
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
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFE2E8F0)),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildListView(_getAnnoncesByStatut(null)),
                _buildListView(_getAnnoncesByStatut(StatutAnnonce.publie)),
                _buildListView(_getAnnoncesByStatut(StatutAnnonce.brouillon)),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
    final typeConfig = AnnonceUiConfig.getTypeConfig(a.type);
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
                  decoration: BoxDecoration(color: typeConfig.color.withValues(alpha:0.08), borderRadius: BorderRadius.circular(8)),
                  child: Icon(typeConfig.icon, color: typeConfig.color, size: 18),
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
                          _buildCardTag(typeConfig.label, typeConfig.color),
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
          if (a.piecesJointes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Wrap(spacing: 8, runSpacing: 6, children: a.piecesJointes.map((p) => _buildPjBadge(p)).toList()),
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
                    onPressed: () => setState(() => a.statut = StatutAnnonce.publie),
                    icon: const Icon(Icons.rocket_launch_outlined, size: 15, color: _emeraldColor),
                    label: const Text('Publier l\'annonce', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _emeraldColor)),
                  ),
                if (a.statut == StatutAnnonce.publie)
                  TextButton.icon(
                    onPressed: () => setState(() => a.statut = StatutAnnonce.brouillon),
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

  Widget _buildPjBadge(PieceJointe p) {
    final cfg = AnnonceUiConfig.getPjConfig(p.type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.icon, size: 14, color: cfg.color),
          const SizedBox(width: 6),
          Text(p.nom, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  void _openFormModal({Annonce? annonce}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormulaireAnnonce(
        annonce: annonce,
        onSave: (processedAnnonce, finalStatus) {
          setState(() {
            if (annonce != null) {
              final index = _globalAnnoncesList.indexWhere((x) => x.id == annonce.id);
              if (index != -1) {
                _globalAnnoncesList[index] = processedAnnonce..statut = finalStatus;
              }
            } else {
              _globalAnnoncesList.insert(0, processedAnnonce..statut = finalStatus);
            }
          });
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
            onPressed: () {
              Navigator.pop(context);
              setState(() => _globalAnnoncesList.removeWhere((x) => x.id == a.id));
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
      case PorteeAnnonce.filiere: return 'Filière : ${a.filiereId}';
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
// PANNEAU FORMULAIRE D'ÉDITION RESTRUCTURÉ
// ════════════════════════════════════════════════════════════════════════════
class _FormulaireAnnonce extends StatefulWidget {
  final Annonce? annonce;
  final void Function(Annonce, StatutAnnonce) onSave;
  const _FormulaireAnnonce({this.annonce, required this.onSave});

  @override State<_FormulaireAnnonce> createState() => _FormulaireAnnonceState();
}

class _FormulaireAnnonceState extends State<_FormulaireAnnonce> {
  final _titreController = TextEditingController();
  final _contenuController = TextEditingController();
  final _lienController = TextEditingController();

  TypeAnnonce _selectedType = TypeAnnonce.academique;
  PorteeAnnonce _selectedPortee = PorteeAnnonce.globale;
  String? _selectedFiliere, _selectedNiveau;
  final List<PieceJointe> _attachmentsList = [];

  @override
  void initState() {
    super.initState();
    if (widget.annonce != null) {
      final a = widget.annonce!;
      _titreController.text = a.titre;
      _contenuController.text = a.contenu;
      _selectedType = a.type;
      _selectedPortee = a.portee;
      _selectedFiliere = a.filiereId;
      _selectedNiveau = a.niveau;
      _attachmentsList.addAll(a.piecesJointes);
    }
  }

  @override
  void dispose() {
    _titreController.dispose(); _contenuController.dispose(); _lienController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
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
                  _buildSectionLabel('Catégorie de l\'information'),
                  const SizedBox(height: 8),
                  _buildTypeSelector(),
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
                  const SizedBox(height: 20),
                  _buildSectionLabel('Ajouter des pièces jointes justificatives'),
                  const SizedBox(height: 10),
                  _buildPjActionsGrid(),
                  if (_attachmentsList.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._attachmentsList.map((p) => _buildAttachmentItem(p)),
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

  Widget _buildTypeSelector() {
    final elements = [
      {'val': TypeAnnonce.academique, 'label': 'Scolarité', 'icon': Icons.assignment_outlined},
      {'val': TypeAnnonce.urgent, 'label': 'Alerte', 'icon': Icons.gpp_maybe_rounded},
      {'val': TypeAnnonce.evenement, 'label': 'Événement', 'icon': Icons.local_activity_outlined},
      {'val': TypeAnnonce.horaire, 'label': 'Planning', 'icon': Icons.date_range_rounded},
    ];
    return Row(
      children: elements.map((e) {
        final isSelected = _selectedType == e['val'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = e['val'] as TypeAnnonce),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AdminTheme.iconBg : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? AdminTheme.iconBg : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Icon(e['icon'] as IconData, color: isSelected ? Colors.white : const Color(0xFF475569), size: 18),
                  const SizedBox(height: 4),
                  Text(e['label'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF475569))),
                ],
              ),
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
          hint: const Text('Choisir la filière (ex: RIT, IDA)', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
          isExpanded: true, underline: const SizedBox(),
          items: istFilieres.map((f) => DropdownMenuItem(value: f['id'], child: Text(f['nom']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)))).toList(),
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

  Widget _buildPjActionsGrid() {
    final tools = [
      {'type': 'pdf', 'label': 'Fichier PDF', 'icon': Icons.picture_as_pdf_rounded},
      {'type': 'word', 'label': 'Doc Word', 'icon': Icons.description_rounded},
      {'type': 'image', 'label': 'Illustration', 'icon': Icons.image_rounded},
      {'type': 'lien', 'label': 'Lien web', 'icon': Icons.link_rounded},
    ];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: tools.map((t) => ActionChip(
            elevation: 0, pressElevation: 0,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFE2E8F0))),
            avatar: Icon(t['icon'] as IconData, size: 14, color: const Color(0xFF475569)),
            label: Text(t['label'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            onPressed: () => _handleAttachmentAddition(t['type'] as String),
          )).toList(),
    );
  }

  Widget _buildAttachmentItem(PieceJointe p) {
    final cfg = AnnonceUiConfig.getPjConfig(p.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: cfg.color.withValues(alpha:0.04), borderRadius: BorderRadius.circular(8), border: Border.all(color: cfg.color.withValues(alpha:0.15))),
      child: Row(
        children: [
          Icon(cfg.icon, size: 16, color: cfg.color),
          const SizedBox(width: 10),
          Expanded(child: Text(p.nom, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
          GestureDetector(onTap: () => setState(() => _attachmentsList.remove(p)), child: const Icon(Icons.cancel_rounded, size: 16, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  void _handleAttachmentAddition(String type) {
    if (type == 'lien') {
      _lienController.clear();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Insérer une URL externe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: _buildTextField(controller: _lienController, hint: 'https://example.com/ressource'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                final url = _lienController.text.trim();
                if (url.isNotEmpty) {
                  setState(() => _attachmentsList.add(PieceJointe(nom: url, type: 'lien', url: url)));
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.iconBgAlt, foregroundColor: AdminTheme.iconFgAlt),
              child: const Text('Lier la ressource', style: TextStyle(color: AdminTheme.iconFgAlt)),
            ),
          ],
        ),
      );
      return;
    }
    
    final mockNames = {'pdf': 'Note_Synthese_Ist.pdf', 'word': 'Formulaire_Inscription.docx', 'image': 'Affiche_Evenement.png'};
    setState(() => _attachmentsList.add(PieceJointe(nom: mockNames[type] ?? 'Fichier_Attache', type: type)));
  }

  Widget _buildFooterActions() => Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _executeSavingProcedure(StatutAnnonce.brouillon),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), side: const BorderSide(color: Color(0xFFCBD5E1))),
                child: const Text('Sauvegarder en brouillon', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _executeSavingProcedure(StatutAnnonce.publie),
                style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.iconBgAlt, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                child: const Text('Publier immédiatement', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminTheme.iconFgAlt)),
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
    
    final formattedAnnonce = Annonce(
      id: widget.annonce?.id ?? 'A${DateTime.now().millisecondsSinceEpoch}',
      titre: title, contenu: body,
      type: _selectedType, portee: _selectedPortee,
      filiereId: _selectedFiliere, niveau: _selectedNiveau,
      statut: finalStatus,
      dateCreation: widget.annonce?.dateCreation ?? DateTime.now(),
      piecesJointes: List.from(_attachmentsList),
    );
    
    widget.onSave(formattedAnnonce, finalStatus);
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(finalStatus == StatutAnnonce.publie ? '🚀 L\'avis d\'information a été publié sur les terminaux étudiants.' : '💾 Document consigné dans vos brouillons.'),
        backgroundColor: const Color(0xFF1E293B), behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
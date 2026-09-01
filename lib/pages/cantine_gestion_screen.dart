import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';

class CantineGestionScreen extends StatefulWidget {
  final StudentProfile profile;
  final VoidCallback? onLogout;

  const CantineGestionScreen({
    super.key,
    required this.profile,
    this.onLogout,
  });

  @override
  State<CantineGestionScreen> createState() => _CantineGestionScreenState();
}

class _CantineGestionScreenState extends State<CantineGestionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = true;
  List<dynamic> _menuList = [];
  List<dynamic> _commandesList = [];
  String _filterStatut = 'Toutes';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerToutesDonnees();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _chargerToutesDonnees() async {
    setState(() => _loading = true);

    final menuRes = await ApiService.getCantineMenu();
    final cmdRes = await ApiService.getAllCommandesCantine();

    if (mounted) {
      setState(() {
        _loading = false;
        if (menuRes['success'] == true) _menuList = menuRes['data'] ?? [];
        if (cmdRes['success'] == true) _commandesList = cmdRes['data'] ?? [];
      });
    }
  }

  // ── Modals & Actions Menu ──────────────────────────────────────────────────

  void _ouvrirDialogPlat({Map<String, dynamic>? platExistant}) {
    final isEdit = platExistant != null;
    final nomCtrl = TextEditingController(text: platExistant?['nom'] ?? '');
    final descCtrl = TextEditingController(text: platExistant?['description'] ?? '');
    final prixCtrl = TextEditingController(
        text: platExistant != null ? platExistant['prix'].toString() : '');
    final emojiCtrl = TextEditingController(text: platExistant?['emoji'] ?? '🍽️');
    String categorie = platExistant?['categorie'] ?? 'Plat principal';
    bool disponible = platExistant?['disponible'] ?? true;

    final categories = ['Plat principal', 'Petit déjeuner', 'Entrée', 'Dessert', 'Boisson'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(isEdit ? Icons.edit_rounded : Icons.add_circle_rounded,
                    color: const Color(0xFF0A3D91)),
                const SizedBox(width: 10),
                Text(isEdit ? 'Modifier le plat' : 'Ajouter au menu',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom du plat / produit *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description / Ingrédients',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: prixCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Prix (FCFA) *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: emojiCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Icône/Emoji',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: categorie,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => categorie = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Disponible en stock',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(disponible ? 'Affiché et commandable' : 'Masqué / Épuisé',
                        style: const TextStyle(fontSize: 11)),
                    value: disponible,
                    activeThumbColor: const Color(0xFF2E7D32),
                    onChanged: (val) => setDialogState(() => disponible = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A3D91)),
                onPressed: () async {
                  if (nomCtrl.text.trim().isEmpty || prixCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez remplir le nom et le prix.')),
                    );
                    return;
                  }

                  final payload = {
                    'nom': nomCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'prix': double.tryParse(prixCtrl.text.trim()) ?? 0,
                    'categorie': categorie,
                    'emoji': emojiCtrl.text.trim().isEmpty ? '🍽️' : emojiCtrl.text.trim(),
                    'disponible': disponible,
                  };

                  Navigator.pop(context);

                  if (isEdit) {
                    await ApiService.updateCantinePlat(platExistant['id'].toString(), payload);
                  } else {
                    await ApiService.addCantinePlat(payload);
                  }
                  _chargerToutesDonnees();
                },
                child: Text(isEdit ? 'Enregistrer' : 'Ajouter',
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleDisponibilite(Map<String, dynamic> plat) async {
    final String id = plat['id'].toString();
    final bool novelState = !(plat['disponible'] ?? true);
    await ApiService.updateCantinePlat(id, {'disponible': novelState});
    _chargerToutesDonnees();
  }

  Future<void> _supprimerPlat(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce plat ?'),
        content: const Text('Cette action retirera définitivement ce plat du menu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.deleteCantinePlat(id);
      _chargerToutesDonnees();
    }
  }

  // ── Status modification ───────────────────────────────────────────────────

  Future<void> _changerStatutCommande(String id, String nouveauStatut) async {
    await ApiService.updateStatutCommandeCantine(id, nouveauStatut);
    _chargerToutesDonnees();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D91),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Espace Cantinière',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Bienvenue ${widget.profile.prenoms} • Restauration IST',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        actions: [
          if (widget.onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              onPressed: widget.onLogout,
              tooltip: 'Déconnexion',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppPalette.yellow,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Menu (${_menuList.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Commandes (${_commandesList.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGestionMenuTab(),
                _buildGestionCommandesTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _ouvrirDialogPlat(),
              backgroundColor: const Color(0xFF0A3D91),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Nouveau plat',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  // ── Tab 1 : Gestion du Menu ────────────────────────────────────────────────

  Widget _buildGestionMenuTab() {
    return RefreshIndicator(
      onRefresh: _chargerToutesDonnees,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF0A3D91)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Ajoutez et contrôlez les plats du menu. Désactivez les plats en rupture pour avertir immédiatement les étudiants.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_menuList.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Aucun plat au menu pour l\'instant. Cliquez sur + pour en ajouter.'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _menuList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final plat = _menuList[idx] as Map<String, dynamic>;
                return _buildAdminPlatTile(plat);
              },
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAdminPlatTile(Map<String, dynamic> plat) {
    final String id = plat['id'].toString();
    final String nom = plat['nom'] ?? '';
    final String desc = plat['description'] ?? '';
    final num prix = plat['prix'] ?? 0;
    final String categorie = plat['categorie'] ?? 'Plat principal';
    final String emoji = plat['emoji'] ?? '🍽️';
    final bool disponible = plat['disponible'] ?? true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: disponible ? Colors.transparent : Colors.red.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(nom,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A3D91).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(categorie,
                          style: const TextStyle(
                              color: Color(0xFF0A3D91), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (desc.isNotEmpty)
                  Text(desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Text('$prix FCFA',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Interrupteur En stock / Rupture
          Column(
            children: [
              Switch(
                value: disponible,
                activeThumbColor: const Color(0xFF2E7D32),
                onChanged: (_) => _toggleDisponibilite(plat),
              ),
              Text(disponible ? 'En stock' : 'Épuisé',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: disponible ? Colors.green : Colors.red)),
            ],
          ),

          // Menu popup Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
            onSelected: (val) {
              if (val == 'edit') _ouvrirDialogPlat(platExistant: plat);
              if (val == 'delete') _supprimerPlat(id);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 2 : Gestion des Commandes ──────────────────────────────────────────

  Widget _buildGestionCommandesTab() {
    final statuts = ['Toutes', 'en_attente', 'en_preparation', 'prete', 'servie'];

    final filteredCmds = _filterStatut == 'Toutes'
        ? _commandesList
        : _commandesList.where((c) => c['statut'] == _filterStatut).toList();

    return RefreshIndicator(
      onRefresh: _chargerToutesDonnees,
      child: Column(
        children: [
          // Barres de filtres
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: statuts.map((st) {
                  final isSelected = _filterStatut == st;
                  String label = st;
                  if (st == 'en_attente') label = 'En attente';
                  if (st == 'en_preparation') label = 'En prépa';
                  if (st == 'prete') label = 'Prêtes';
                  if (st == 'servie') label = 'Servies';

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _filterStatut = st);
                      },
                      selectedColor: const Color(0xFF0A3D91),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF374151),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: filteredCmds.isEmpty
                ? const Center(
                    child: Text('Aucune commande enregistrée sous ce statut.'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredCmds.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final cmd = filteredCmds[idx] as Map<String, dynamic>;
                      return _buildAdminOrderTile(cmd);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminOrderTile(Map<String, dynamic> cmd) {
    final String id = cmd['id'].toString();
    final String nomEtud = cmd['etudiant_nom'] ?? 'Étudiant';
    final String mat = cmd['etudiant_matricule'] ?? 'N/A';
    final String code = cmd['code_retrait'] ?? 'CAN-XXXX';
    final String statut = cmd['statut'] ?? 'en_attente';
    final num total = cmd['montant_total'] ?? 0;
    final List<dynamic> items = cmd['items'] ?? [];

    Color color;
    String statusLbl;
    switch (statut) {
      case 'prete':
        color = const Color(0xFF2E7D32);
        statusLbl = 'Prête à servir';
        break;
      case 'en_preparation':
        color = const Color(0xFF1976D2);
        statusLbl = 'En préparation';
        break;
      case 'servie':
        color = Colors.grey;
        statusLbl = 'Servie / Terminée';
        break;
      case 'annulee':
        color = Colors.red;
        statusLbl = 'Annulée';
        break;
      default:
        color = Colors.orange;
        statusLbl = 'En attente';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header commande
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nomEtud,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(mat, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: Text(code,
                      style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
                ),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...items.map((it) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('• ${it['quantite']} × ${it['nom_plat']}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('${(it['prix_unitaire'] as num) * (it['quantite'] as num)} FCFA',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  );
                }),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Statut : $statusLbl',
                        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
                    Text('Total : $total FCFA',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0A3D91))),
                  ],
                ),
                const SizedBox(height: 12),

                // Boutons d'action rapide selon le statut actuel
                Row(
                  children: [
                    if (statut == 'en_attente')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _changerStatutCommande(id, 'en_preparation'),
                          icon: const Icon(Icons.soup_kitchen, size: 16, color: Colors.white),
                          label: const Text('En cuisine',
                              style: TextStyle(color: Colors.white, fontSize: 11)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
                        ),
                      ),
                    if (statut == 'en_attente' || statut == 'en_preparation') ...[
                      if (statut == 'en_attente') const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _changerStatutCommande(id, 'prete'),
                          icon: const Icon(Icons.check_circle, size: 16, color: Colors.white),
                          label: const Text('Prête à servir',
                              style: TextStyle(color: Colors.white, fontSize: 11)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                        ),
                      ),
                    ],
                    if (statut == 'prete')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _changerStatutCommande(id, 'servie'),
                          icon: const Icon(Icons.task_alt, size: 16, color: Colors.white),
                          label: const Text('Marquer comme Servie',
                              style: TextStyle(color: Colors.white, fontSize: 12)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';

class CantineStudentScreen extends StatefulWidget {
  final StudentProfile profile;

  const CantineStudentScreen({super.key, required this.profile});

  @override
  State<CantineStudentScreen> createState() => _CantineStudentScreenState();
}

class _CantineStudentScreenState extends State<CantineStudentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loadingMenu = true;
  String? _errorMessage;

  List<dynamic> _menuList = [];
  List<dynamic> _myOrders = [];
  String _selectedCategorie = 'Tous';

  // Panier : platId -> { 'plat': Map, 'quantite': int }
  final Map<String, Map<String, dynamic>> _panier = {};

  final List<String> _categories = [
    'Tous',
    'Plat principal',
    'Petit déjeuner',
    'Entrée',
    'Dessert',
    'Boisson',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerDonnees();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    setState(() {
      _loadingMenu = true;
      _errorMessage = null;
    });

    final menuRes = await ApiService.getCantineMenu();
    final cmdRes = await ApiService.getMesCommandesCantine(
      etudiantId: widget.profile.matricule,
      matricule: widget.profile.matricule,
    );

    if (mounted) {
      setState(() {
        _loadingMenu = false;
        if (menuRes['success'] == true) {
          _menuList = menuRes['data'] ?? [];
        } else {
          _errorMessage = menuRes['error'];
        }

        if (cmdRes['success'] == true) {
          _myOrders = cmdRes['data'] ?? [];
        }
      });
    }
  }

  int get _cartTotalCount {
    return _panier.values.fold(0, (sum, item) => sum + (item['quantite'] as int));
  }

  double get _cartTotalPrice {
    return _panier.values.fold(0.0, (sum, item) {
      final plat = item['plat'] as Map<String, dynamic>;
      final qty = item['quantite'] as int;
      final prix = (plat['prix'] is num) ? (plat['prix'] as num).toDouble() : 0.0;
      return sum + (prix * qty);
    });
  }

  void _ajouterAuPanier(Map<String, dynamic> plat) {
    final String id = plat['id'].toString();
    setState(() {
      if (_panier.containsKey(id)) {
        _panier[id]!['quantite'] = (_panier[id]!['quantite'] as int) + 1;
      } else {
        _panier[id] = {'plat': plat, 'quantite': 1};
      }
    });
  }

  void _retirerDuPanier(Map<String, dynamic> plat) {
    final String id = plat['id'].toString();
    if (!_panier.containsKey(id)) return;
    setState(() {
      final currentQty = _panier[id]!['quantite'] as int;
      if (currentQty > 1) {
        _panier[id]!['quantite'] = currentQty - 1;
      } else {
        _panier.remove(id);
      }
    });
  }

  Future<void> _passerCommande() async {
    if (_panier.isEmpty) return;

    final List<Map<String, dynamic>> itemsPayload = _panier.values.map((entry) {
      final plat = entry['plat'] as Map<String, dynamic>;
      final qty = entry['quantite'] as int;
      return {
        'menu_id': plat['id'].toString(),
        'nom_plat': plat['nom'],
        'prix_unitaire': plat['prix'],
        'quantite': qty,
      };
    }).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final response = await ApiService.creerCommandeCantine({
      'etudiant_id': widget.profile.matricule,
      'etudiant_nom': '${widget.profile.prenoms} ${widget.profile.nom}',
      'etudiant_matricule': widget.profile.matricule,
      'montant_total': _cartTotalPrice,
      'items': itemsPayload,
    });

    if (mounted) Navigator.of(context).pop(); // Fermer le loader

    if (response['success'] == true) {
      setState(() {
        _panier.clear();
      });
      _chargerDonnees();
      _tabController.animateTo(1); // Basculer sur l'onglet Mes commandes

      final newCmd = response['data'];
      final code = newCmd?['code_retrait'] ?? 'CAN-XXXX';

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => _buildSuccesOrderSheet(code),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Échec de la commande'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D91),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cantine IST Ouaga',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Restauration & Commandes en ligne',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
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
                  const Icon(Icons.restaurant_menu_rounded, size: 18),
                  const SizedBox(width: 6),
                  const Text('Menu du jour'),
                  if (_cartTotalCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: AppPalette.yellow,
                        shape: BoxShape.circle,
                      ),
                      child: Text('$_cartTotalCount',
                          style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_rounded, size: 18),
                  SizedBox(width: 6),
                  Text('Mes Tickets'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMenuTab(),
          _buildOrdersTab(),
        ],
      ),
      bottomNavigationBar: _panier.isNotEmpty && _tabController.index == 0
          ? _buildCartFloatingBar()
          : null,
    );
  }

  // ── Onglet Menu ─────────────────────────────────────────────────────────────

  Widget _buildMenuTab() {
    if (_loadingMenu) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _menuList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _chargerDonnees, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    final filteredMenu = _selectedCategorie == 'Tous'
        ? _menuList
        : _menuList.where((p) => p['categorie'] == _selectedCategorie).toList();

    return RefreshIndicator(
      onRefresh: _chargerDonnees,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bandeau d'information du jour
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text('🍲', style: TextStyle(fontSize: 26))),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Service de Restauration',
                            style: TextStyle(
                                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('Commandez à l\'avance et retirez rapidement votre repas au guichet.',
                            style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Filtres par catégories
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final cat = _categories[idx];
                  final isSelected = _selectedCategorie == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategorie = cat);
                    },
                    selectedColor: const Color(0xFF0A3D91),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF4B5563),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                        color: isSelected ? const Color(0xFF0A3D91) : const Color(0xFFE5E7EB)),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Liste des plats
            if (filteredMenu.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.no_meals_rounded, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Aucun plat disponible dans cette catégorie.',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredMenu.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final plat = filteredMenu[idx] as Map<String, dynamic>;
                  return _buildPlatCard(plat);
                },
              ),
            const SizedBox(height: 80), // Espace bottom bar
          ],
        ),
      ),
    );
  }

  Widget _buildPlatCard(Map<String, dynamic> plat) {
    final String id = plat['id'].toString();
    final String nom = plat['nom'] ?? 'Plat';
    final String desc = plat['description'] ?? '';
    final num prix = plat['prix'] ?? 0;
    final String emoji = plat['emoji'] ?? '🍽️';
    final bool disponible = plat['disponible'] ?? true;
    final int qtyInCart = _panier[id]?['quantite'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: qtyInCart > 0
            ? Border.all(color: const Color(0xFF0A3D91), width: 1.5)
            : Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          // Emoji / Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),

          // Détails plat
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(nom,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                    ),
                    if (!disponible)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Épuisé',
                            style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                ],
                const SizedBox(height: 8),
                Text('$prix FCFA',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0A3D91))),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Bouton Ajout / Sélecteur Quantité
          if (!disponible)
            const SizedBox.shrink()
          else if (qtyInCart == 0)
            ElevatedButton(
              onPressed: () => _ajouterAuPanier(plat),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A3D91),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                elevation: 0,
              ),
              child: const Text('Ajouter', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 16, color: Color(0xFF1F2937)),
                    onPressed: () => _retirerDuPanier(plat),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                  Text('$qtyInCart',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16, color: Color(0xFF0A3D91)),
                    onPressed: () => _ajouterAuPanier(plat),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Panier Flottant ─────────────────────────────────────────────────────────

  Widget _buildCartFloatingBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total panier ($_cartTotalCount)',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('${_cartTotalPrice.toInt()} FCFA',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0A3D91))),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showCartSummarySheet(),
              icon: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18),
              label: const Text('Commander',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A3D91),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCartSummarySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0A3D91)),
                    const SizedBox(width: 10),
                    const Text('Récapitulatif de votre commande',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 24),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _panier.length,
                    separatorBuilder: (_, __) => const Divider(height: 12),
                    itemBuilder: (context, idx) {
                      final item = _panier.values.toList()[idx];
                      final plat = item['plat'] as Map<String, dynamic>;
                      final qty = item['quantite'] as int;
                      final prix = (plat['prix'] as num).toInt();

                      return Row(
                        children: [
                          Text(plat['emoji'] ?? '🍽️', style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(plat['nom'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('$prix FCFA × $qty',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                          Text('${prix * qty} FCFA',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      );
                    },
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Montant Total',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    Text('${_cartTotalPrice.toInt()} FCFA',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0A3D91))),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _passerCommande();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Valider ma commande',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuccesOrderSheet(String codeRetrait) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Commande validée !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Présentez ce code de retrait au guichet de la cantine :',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF0A3D91), width: 2),
            ),
            child: Text(codeRetrait,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFF0A3D91))),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A3D91),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Consulter mes tickets', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Onglet Mes Commandes ──────────────────────────────────────────────────

  Widget _buildOrdersTab() {
    if (_myOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _chargerDonnees,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Aucune commande enregistrée',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            const Text('Vos commandes validées apparaîtront ici avec leur code de retrait.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _chargerDonnees,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _myOrders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, idx) {
          final order = _myOrders[idx] as Map<String, dynamic>;
          return _buildOrderTicketCard(order);
        },
      ),
    );
  }

  Widget _buildOrderTicketCard(Map<String, dynamic> order) {
    final String code = order['code_retrait'] ?? 'CAN-0000';
    final String statut = order['statut'] ?? 'en_attente';
    final num total = order['montant_total'] ?? 0;
    final String dateStr = order['created_at'] != null
        ? DateTime.tryParse(order['created_at'].toString())
                ?.toLocal()
                .toString()
                .substring(0, 16)
                .replaceAll('T', ' à ') ??
            ''
        : '';
    final List<dynamic> items = order['items'] ?? [];

    Color badgeColor;
    String statusText;
    IconData statusIcon;

    switch (statut) {
      case 'prete':
        badgeColor = const Color(0xFF2E7D32);
        statusText = 'Prête à servir !';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'en_preparation':
        badgeColor = const Color(0xFF1976D2);
        statusText = 'En préparation...';
        statusIcon = Icons.soup_kitchen_rounded;
        break;
      case 'servie':
        badgeColor = Colors.grey;
        statusText = 'Servie / Retirée';
        statusIcon = Icons.task_alt_rounded;
        break;
      case 'annulee':
        badgeColor = Colors.red;
        statusText = 'Annulée';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        badgeColor = Colors.orange;
        statusText = 'En attente...';
        statusIcon = Icons.access_time_filled_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête ticket avec code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: badgeColor, size: 20),
                const SizedBox(width: 8),
                Text(statusText,
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor, width: 1),
                  ),
                  child: Text(code,
                      style: TextStyle(
                          color: badgeColor, fontWeight: FontWeight.w900, fontSize: 14)),
                ),
              ],
            ),
          ),

          // Liste des éléments
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...items.map((it) {
                  final String nom = it['nom_plat'] ?? 'Article';
                  final int qty = it['quantite'] ?? 1;
                  final num px = it['prix_unitaire'] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$qty × $nom', style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                        Text('${px * qty} FCFA', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Créé le $dateStr',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    Text('Total: $total FCFA',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0A3D91))),
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

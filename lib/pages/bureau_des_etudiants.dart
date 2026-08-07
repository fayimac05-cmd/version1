import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../theme/app_palette.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import 'create_event_page.dart';
import 'create_announcement_page.dart';
import 'event_registration_page.dart';

class BureauDesEtudiantsScreen extends StatefulWidget {
  const BureauDesEtudiantsScreen({super.key});

  @override
  State<BureauDesEtudiantsScreen> createState() =>
      _BureauDesEtudiantsScreenState();
}

class _BureauDesEtudiantsScreenState extends State<BureauDesEtudiantsScreen> {
  int _currentIndex = 0;
  List<EventModel> _events = [];
  List<Map<String, dynamic>> _annonces = [];
  List<Map<String, dynamic>> _inscriptions = [];
  bool _isLoading = true;

  static const primaryBlue = AppPalette.blue;
  static const textDark = Color(0xFF0F172A);
  static const textLight = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService.getEvenements(),
      ApiService.getAnnonces(statut: 'publie'),
      ApiService.getHistoriqueInscriptions(),
    ]);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (results[0]['success'] == true) {
        _events = (results[0]['data'] as List<dynamic>)
            .map((j) => EventModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      if (results[1]['success'] == true) {
        _annonces = (results[1]['data'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
      }
      if (results[2]['success'] == true) {
        _inscriptions = (results[2]['data'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
      }
    });
  }

  List<Widget> get _pages => [
    _buildAccueilBDE(),
    _buildPageEvenements(),
    _buildPageAnnonces(),
    _buildPageProfil(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Container(
            height: 76,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: _buildNavItem(0, Icons.home_filled, 'Accueil')),
                Expanded(child: _buildNavItem(1, Icons.event, 'Evenements')),
                Expanded(
                  child: _buildNavItem(2, Icons.announcement, 'Annonces'),
                ),
                Expanded(
                  child: _buildNavItem(3, Icons.account_circle, 'Profil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E1E1E) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccueilBDE() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 120,
        ),
        children: [
          // Header Bienvenue
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tableau de bord BDE',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                Text(
                  'Suivi des activités et annonces',
                  style: TextStyle(fontSize: 14, color: textLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildCardVentesApprouvees(),
          const SizedBox(height: 16),
          _buildCardAnnoncesGestion(),
          const SizedBox(height: 16),
          _buildCardHistoriqueInscriptions(),
        ],
      ),
    );
  }

  // ── Historique des inscriptions aux événements ─────────────────────────
  Widget _buildCardHistoriqueInscriptions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 18, color: primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Historique des inscriptions (${_inscriptions.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_inscriptions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Aucune inscription aux événements pour le moment.',
                  style: TextStyle(fontSize: 13, color: textLight),
                ),
              ),
            )
          else
            for (int i = 0; i < _inscriptions.length; i++) ...[
              if (i > 0) const Divider(height: 24, color: Color(0xFFF1F5F9)),
              _buildInscriptionItem(_inscriptions[i]),
            ],
        ],
      ),
    );
  }

  Widget _buildInscriptionItem(Map<String, dynamic> ins) {
    final nomComplet = [ins['prenoms'], ins['nom']]
        .where((x) => x != null && x.toString().isNotEmpty)
        .join(' ');
    final date = DateTime.tryParse(ins['createdAt'] ?? '');
    final prix = double.tryParse(ins['prix']?.toString() ?? '') ?? 0;
    final details = [
      if ((ins['matricule'] ?? '').toString().isNotEmpty) ins['matricule'],
      if ((ins['telephone'] ?? '').toString().isNotEmpty) ins['telephone'],
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.how_to_reg_rounded, color: primaryBlue, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nomComplet.isEmpty ? 'Étudiant' : nomComplet,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'S\'est inscrit à « ${ins['evenement_titre'] ?? ''} »',
                style: const TextStyle(fontSize: 12, color: textLight),
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(details, style: const TextStyle(fontSize: 11, color: textLight)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              date != null ? DateFormat('dd MMM · HH:mm').format(date) : '',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                prix > 0 ? '${prix.toStringAsFixed(0)} FCFA' : 'Gratuit',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF166534),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPageEvenements() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 120,
        ),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateEventPage(),
                  ),
                );
                if (result != null && result is EventModel) {
                  _loadData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                '+ Créer un événement',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCardEvenements(withButton: false),
          const SizedBox(height: 16),
          _buildCardEvenements(
            title: 'Événements à venir',
            withButton: false,
            isUpcoming: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPageAnnonces() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 120,
        ),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateAnnouncementPage(),
                  ),
                );
                if (result == true) _loadData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                '+ Nouvelle annonce',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCardAnnoncesGestion(),
        ],
      ),
    );
  }

  Widget _buildCardAnnoncesGestion() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: primaryBlue),
                  SizedBox(width: 8),
                  Text(
                    'Annonces Approuvées',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('En cours de développement...')),
                ),
                child: const Text(
                  'Voir tout',
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_annonces.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Aucune annonce publiée pour le moment.',
                  style: TextStyle(fontSize: 13, color: textLight),
                ),
              ),
            )
          else
            for (int i = 0; i < _annonces.length; i++) ...[
              if (i > 0) const Divider(height: 24, color: Color(0xFFF1F5F9)),
              _buildAnnonceItem(
                icon: Icons.campaign_outlined,
                title: _annonces[i]['titre'] ?? '',
                subtitle: _formatAnnonceSubtitle(_annonces[i]),
                status: 'Diffusé',
                statusBg: const Color(0xFFDCFCE7),
                statusColor: const Color(0xFF166534),
              ),
            ],
        ],
      ),
    );
  }

  String _formatAnnonceSubtitle(Map<String, dynamic> annonce) {
    final date = DateTime.tryParse(annonce['createdAt'] ?? '');
    final dateStr = date != null ? DateFormat('dd MMM yyyy').format(date) : '';
    final categorie = annonce['categorie'];
    return categorie != null && categorie.toString().isNotEmpty
        ? '$dateStr · $categorie'
        : dateStr;
  }

  Widget _buildAnnonceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required Color statusBg,
    required Color statusColor,
    bool canEdit = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryBlue, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!canEdit)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  if (canEdit)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('En cours de développement...'),
                            ),
                          ),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: primaryBlue,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: textLight),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardEvenements({
    String title = 'Événements en cours',
    bool withButton = true,
    bool isUpcoming = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: primaryBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            () {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final visibles = _events
                  .where((e) => isUpcoming
                      ? e.date.isAfter(today.add(const Duration(days: 1)))
                      : !e.date.isAfter(today.add(const Duration(days: 1))))
                  .toList();
              if (visibles.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Aucun événement dans cette catégorie.',
                      style: TextStyle(fontSize: 13, color: textLight),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (int i = 0; i < visibles.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildEventItem(event: visibles[i]),
                  ],
                ],
              );
            }(),
          ],
          if (withButton) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateEventPage(),
                  ),
                );
                if (result != null && result is EventModel) {
                  _loadData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                '+ Créer un événement',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventItem({required EventModel event}) {
    final title = event.name;
    final subtitle =
        '${DateFormat('dd MMM yyyy').format(event.date)}${event.location.isNotEmpty ? ' · ${event.location}' : ''}';
    final count =
        '${event.inscrits} / ${event.capacite > 0 ? event.capacite : '∞'}';
    final status = event.status;
    Color statusBg;
    Color statusColor;
    switch (status) {
      case 'Approuvé':
        statusBg = const Color(0xFFDCFCE7);
        statusColor = const Color(0xFF166534);
        break;
      case 'Annulé':
        statusBg = const Color(0xFFFEE2E2);
        statusColor = const Color(0xFF991B1B);
        break;
      default:
        statusBg = const Color(0xFFFEF3C7);
        statusColor = const Color(0xFF92400E);
    }
    final XFile? image = event.image;
    final String? imageUrl = event.imageUrl;

    return InkWell(
      onTap: () async {
        final registered = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventRegistrationPage(event: event),
          ),
        );
        if (registered == true) _loadData();
      },
      child: _buildEventItemContent(
        title: title,
        subtitle: subtitle,
        count: count,
        status: status,
        statusBg: statusBg,
        statusColor: statusColor,
        image: image,
        imageUrl: imageUrl,
      ),
    );
  }

  Widget _buildEventItemContent({
    required String title,
    required String subtitle,
    required String count,
    required String status,
    required Color statusBg,
    required Color statusColor,
    XFile? image,
    String? imageUrl,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (imageUrl != null || image != null)
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFFF1F5F9),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: imageUrl != null
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : kIsWeb
                          ? Image.network(image!.path, fit: BoxFit.cover)
                          : Image.file(File(image!.path), fit: BoxFit.cover),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: textLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardVentesApprouvees() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, size: 18, color: primaryBlue),
              SizedBox(width: 8),
              Text(
                'Ventes (Événements Approuvés)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressItem('Soirée Cult.', 0.80, '120/150'),
          const SizedBox(height: 16),
          _buildProgressItem('Sport Day', 0.50, '40/80'),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: primaryBlue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Seuls les événements validés par l\'administration sont listés ici pour le suivi des ventes.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textLight,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, double progress, String percent) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: textLight),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 36,
          child: Text(
            percent,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildPageProfil() {
    return Stack(
      children: [
        // Header background with curved bottom
        Container(
          height: 200,
          decoration: const BoxDecoration(
            color: primaryBlue,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 32),
                          const Text(
                            'Profil',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 32),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Profile Picture
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFF8FAFC),
                            width: 4,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Name and Subtitle
                    const Center(
                      child: Text(
                        'Aïcha OUÉDRAOGO',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.circle, size: 8, color: Colors.grey),
                        const SizedBox(width: 6),
                        const Text(
                          'Delegué Général, IST',
                          style: TextStyle(fontSize: 13, color: textLight),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Account Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha:0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mon Compte',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildProfileItem(
                              Icons.person_outline,
                              'Données personnelles',
                            ),
                            const Divider(height: 24, color: Color(0xFFF1F5F9)),
                            _buildProfileItem(
                              Icons.settings_outlined,
                              'Paramètres',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Logout Button (FIXÉ EN BAS)
              Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 16,
                ), // Espace réduit
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Se déconnecter',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(
    IconData icon,
    String title, {
    bool showArrow = true,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textDark,
            ),
          ),
        ),
        if (showArrow)
          const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Color(0xFF94A3B8),
          ),
      ],
    );
  }
}

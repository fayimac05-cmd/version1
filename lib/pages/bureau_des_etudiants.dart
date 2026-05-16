import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import 'create_event_page.dart';
import 'create_announcement_page.dart';

class BureauDesEtudiantsScreen extends StatefulWidget {
  const BureauDesEtudiantsScreen({super.key});

  @override
  State<BureauDesEtudiantsScreen> createState() => _BureauDesEtudiantsScreenState();
}

class _BureauDesEtudiantsScreenState extends State<BureauDesEtudiantsScreen> {
  int _currentIndex = 0;

  static const primaryBlue = AppPalette.blue;
  static const accentYellow = AppPalette.yellow;
  static const textDark = Color(0xFF0F172A);
  static const textLight = Color(0xFF64748B);

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
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: _buildNavItem(0, Icons.home_filled, 'Accueil')),
                Expanded(child: _buildNavItem(1, Icons.event, 'Evenements')),
                Expanded(child: _buildNavItem(2, Icons.announcement, 'Annonces')),
                Expanded(child: _buildNavItem(3, Icons.account_circle, 'Profil')),
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
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
        children: [
          // Header Bienvenue
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tableau de bord BDE',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
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
        ],
      ),
    );
  }

  Widget _buildPageEvenements() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateEventPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('+ Créer un événement', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          _buildCardEvenements(withButton: false),
          const SizedBox(height: 16),
          _buildCardEvenements(title: 'Événements à venir', withButton: false, isUpcoming: true),
        ],
      ),
    );
  }

  Widget _buildPageAnnonces() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateAnnouncementPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('+ Nouvelle annonce', style: TextStyle(fontWeight: FontWeight.w600)),
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
            color: Colors.black.withOpacity(0.03),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Voir tout', style: TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildAnnonceItem(
            icon: Icons.campaign_outlined,
            title: 'Résultats Concours Photo BDE',
            subtitle: '08 Jan 2025 · 312 vues',
            status: 'Diffusé',
            statusBg: const Color(0xFFDCFCE7),
            statusColor: const Color(0xFF166534),
            canEdit: true,
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildAnnonceItem(
            icon: Icons.schedule_outlined,
            title: 'Rappel : Soirée Culturelle J-3',
            subtitle: '09 Jan 2025 · 180 vues',
            status: 'Diffusé',
            statusBg: const Color(0xFFDCFCE7),
            statusColor: const Color(0xFF166534),
            canEdit: true,
          ),
        ],
      ),
    );
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
                    child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark)),
                  ),
                  const SizedBox(width: 8),
                  if (!canEdit)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ),
                  if (canEdit)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined, size: 18, color: primaryBlue),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: textLight)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardEvenements({String title = 'Événements en cours', bool withButton = true, bool isUpcoming = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!isUpcoming) ...[
            _buildEventItem(
              title: 'Soirée Culturelle',
              subtitle: '12 Jan 2025 · Salle polyvalente',
              count: '120 / 150',
              status: 'Approuvé',
              statusBg: const Color(0xFFDCFCE7),
              statusColor: const Color(0xFF166534),
            ),
            const Divider(height: 24, color: Color(0xFFF1F5F9)),
            _buildEventItem(
              title: 'Cérémonie Prix BDE',
              subtitle: '20 Jan 2025 · Amphi A',
              count: '87 / 120',
              status: 'En attente',
              statusBg: const Color(0xFFFEF3C7),
              statusColor: const Color(0xFF92400E),
            ),
            const Divider(height: 24, color: Color(0xFFF1F5F9)),
            _buildEventItem(
              title: 'Journée Sport',
              subtitle: '28 Jan 2025 · Terrain',
              count: '40 / 80',
              status: 'Ouvert',
              statusBg: const Color(0xFFDBEAFE),
              statusColor: const Color(0xFF1E40AF),
            ),
          ] else ...[
            _buildEventItem(
              title: 'Gala de fin d\'année',
              subtitle: '15 Juin 2025 · Grand Amphi',
              count: '0 / 500',
              status: 'Planifié',
              statusBg: const Color(0xFFF1F5F9),
              statusColor: const Color(0xFF475569),
            ),
            const Divider(height: 24, color: Color(0xFFF1F5F9)),
            _buildEventItem(
              title: 'Forum Entreprises',
              subtitle: '10 Avr 2025 · Hall Principal',
              count: '0 / 200',
              status: 'Ouvert',
              statusBg: const Color(0xFFDBEAFE),
              statusColor: const Color(0xFF1E40AF),
            ),
            const Divider(height: 24, color: Color(0xFFF1F5F9)),
            _buildEventItem(
              title: 'Tournoi E-sport',
              subtitle: '05 Mar 2025 · Salle Info',
              count: '12 / 32',
              status: 'En attente',
              statusBg: const Color(0xFFFEF3C7),
              statusColor: const Color(0xFF92400E),
            ),
          ],
          if (withButton) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateEventPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('+ Créer un événement', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventItem({
    required String title,
    required String subtitle,
    required String count,
    required String status,
    required Color statusBg,
    required Color statusColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: textLight)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(count, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
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
            color: Colors.black.withOpacity(0.03),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
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
                    style: TextStyle(fontSize: 12, color: textLight, height: 1.4),
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
          child: Text(label, style: const TextStyle(fontSize: 13, color: textLight)),
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
          child: Text(percent, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark), textAlign: TextAlign.right),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 32),
                          const Text(
                            'Profil',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                          border: Border.all(color: const Color(0xFFF8FAFC), width: 4),
                        ),
                        child: const Center(
                          child: Icon(Icons.person, size: 50, color: primaryBlue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Name and Subtitle
                    const Center(
                      child: Text(
                        'Aïcha OUÉDRAOGO',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
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
                              color: Colors.black.withOpacity(0.03),
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
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                            ),
                            const SizedBox(height: 16),
                            _buildProfileItem(Icons.person_outline, 'Données personnelles'),
                            const Divider(height: 24, color: Color(0xFFF1F5F9)),
                            _buildProfileItem(Icons.settings_outlined, 'Paramètres'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Logout Button (FIXÉ EN BAS)
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16), // Espace réduit
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
                        Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
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

  Widget _buildProfileItem(IconData icon, String title, {bool showArrow = true}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textDark),
          ),
        ),
        if (showArrow)
          const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
      ],
    );
  }
}

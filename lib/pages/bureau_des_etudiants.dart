import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class BureauDesEtudiantsScreen extends StatefulWidget {
  const BureauDesEtudiantsScreen({super.key});

  @override
  State<BureauDesEtudiantsScreen> createState() => _BureauDesEtudiantsScreenState();
}

class _BureauDesEtudiantsScreenState extends State<BureauDesEtudiantsScreen> {
  int _currentIndex = 0;

  static const bdeGreen = Color(0xFF1A4331); // Vert foncé BDE
  static const textDark = Color(0xFF0F172A);
  static const textLight = Color(0xFF64748B);

  List<Widget> get _pages => [
    _buildAccueilBDE(),
    const Center(child: Text('Validations', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    const Center(child: Text('Événements', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    const Center(child: Text('Objectifs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
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
            height: 74,
            decoration: BoxDecoration(
              color: AppPalette.blue.withOpacity(0.9),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.blue.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.home_rounded),
                    _buildNavItem(1, Icons.check_circle_outline_rounded),
                    _buildNavItem(2, Icons.calendar_month_outlined),
                    _buildNavItem(3, Icons.track_changes_rounded),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
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
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
          size: 30,
        ),
      ),
    );
  }

  Widget _buildAccueilBDE() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
        children: [
          _buildCardEvenements(),
          const SizedBox(height: 16),
          _buildCardVentes(),
        ],
      ),
    );
  }

  Widget _buildCardEvenements() {
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
              const Icon(Icons.circle, size: 10, color: bdeGreen),
              const SizedBox(width: 8),
              const Text(
                'Événements en cours',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: bdeGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('+ Créer un événement', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
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

  Widget _buildCardVentes() {
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
              const Icon(Icons.circle, size: 10, color: bdeGreen),
              const SizedBox(width: 8),
              const Text(
                'Ventes par événement',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressItem('Soirée Cult.', 0.80, '80%'),
          const SizedBox(height: 16),
          _buildProgressItem('Prix BDE', 0.72, '72%'),
          const SizedBox(height: 16),
          _buildProgressItem('Sport', 0.50, '50%'),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.qr_code_2, color: bdeGreen, size: 64),
                const SizedBox(height: 12),
                const Text(
                  'Scanner à l\'entrée pour contrôle',
                  style: TextStyle(fontSize: 13, color: textLight),
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
              valueColor: const AlwaysStoppedAnimation<Color>(bdeGreen),
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
}

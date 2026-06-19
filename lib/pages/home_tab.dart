import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import '../pages/canal_screen.dart';
import '../widgets/weekly_program_quick_widget.dart';
import 'groupe_filiere_screen.dart';
import 'tickets_screen.dart';
import 'notifications_page.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.profile});
  final StudentProfile profile;

  String get _salutation {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Blue gradient header
            _buildHeader(context),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Feature grid
                  _buildFeatureGrid(context),
                  const SizedBox(height: 24),
                  // Events section
                  _buildEventsSection(),
                  const SizedBox(height: 20),
                  // Weekly program
                  const WeeklyProgramQuickWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final initiales =
        '${profile.prenoms.isNotEmpty ? profile.prenoms[0] : ''}'
        '${profile.nom.isNotEmpty ? profile.nom[0] : ''}'
            .toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        gradient: AppPalette.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          child: Column(
            children: [
              // Top row: menu + notification
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.menu, color: Colors.white, size: 26),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => NotificationsPage()),
                    ),
                    child: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 26),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text('3',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Profile row
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppPalette.yellow, width: 3),
                    ),
                    child: Center(
                      child: Text(initiales,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppPalette.blue)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$_salutation,',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.85))),
                        Text('${profile.prenoms} ${profile.nom}',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                          profile.niveau.isNotEmpty
                              ? '${profile.niveau} ${profile.filiere}'
                              : profile.filiere,
                          style: const TextStyle(
                              fontSize: 13, color: AppPalette.yellow),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      _FeatureItem(
        icon: Icons.school_outlined,
        label: 'Infos\nacadémiques',
        onTap: () {},
      ),
      _FeatureItem(
        icon: Icons.assignment_outlined,
        label: 'Mes\ndevoirs',
        onTap: () {},
      ),
      _FeatureItem(
        icon: Icons.calendar_month_outlined,
        label: 'Emploi du\ntemps',
        onTap: () {},
      ),
      _FeatureItem(
        icon: Icons.event_outlined,
        label: 'Événements',
        onTap: () {},
      ),
    ];

    return Column(
      children: [
        // 2x2 grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.5,
          children: features.map((f) => _buildFeatureCard(f)).toList(),
        ),
        const SizedBox(height: 14),
        // Full-width card for "Résultats"
        _buildWideFeatureCard(
          icon: Icons.bar_chart_rounded,
          label: 'Résultats',
          onTap: () {},
        ),
        const SizedBox(height: 14),
        // Quick access row
        Row(
          children: [
            Expanded(
              child: _buildSmallCard(
                icon: Icons.groups_rounded,
                label: 'Groupe',
                color: AppPalette.blue,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => GroupeFiliere(profile: profile))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSmallCard(
                icon: Icons.confirmation_number_outlined,
                label: 'Tickets',
                color: const Color(0xFFF97316),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => TicketsScreen(profile: profile))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSmallCard(
                icon: Icons.forum_rounded,
                label: 'Canaux',
                color: AppPalette.midBlue,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CanalScreen(profile: profile))),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(_FeatureItem feature) {
    return GestureDetector(
      onTap: feature.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppPalette.lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(feature.icon, color: AppPalette.blue, size: 22),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(feature.label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.black,
                          height: 1.2)),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppPalette.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right,
                      color: Colors.white, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideFeatureCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppPalette.lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppPalette.blue, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.black)),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppPalette.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right,
                  color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.blue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Événements à venir',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Row(
                children: [
                  Text('Voir tout',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8))),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.8), size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Event card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Date
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppPalette.lightBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    children: [
                      Text('25',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppPalette.blue)),
                      Text('MAI',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppPalette.blue)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Event info
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Conseil pédagogique',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppPalette.black)),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 12, color: AppPalette.grey),
                          SizedBox(width: 4),
                          Text('Salle A-204 · 10:00 AM',
                              style: TextStyle(
                                  fontSize: 12, color: AppPalette.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Bell icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppPalette.softYellow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_active,
                      color: AppPalette.yellow, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Page dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dot(true),
              const SizedBox(width: 6),
              _dot(false),
              const SizedBox(width: 6),
              _dot(false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(bool active) {
    return Container(
      width: active ? 8 : 6,
      height: active ? 8 : 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.4),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _FeatureItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

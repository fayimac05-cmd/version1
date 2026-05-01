import 'package:flutter/material.dart';

import '../models/student_profile.dart';
import '../theme/app_palette.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.profile, required this.onLogout});

  final StudentProfile profile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: const BoxDecoration(color: AppPalette.blue),
            child: Column(
              children: [
                Text(
                  'Profil',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppPalette.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppPalette.yellow,
                  child: Text(
                    _initials(profile),
                    style: const TextStyle(
                      color: AppPalette.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${profile.prenoms} ${profile.nom}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppPalette.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.yellow.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Etudiant(e)',
                    style: TextStyle(
                      color: AppPalette.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profile.filiere,
                  style: const TextStyle(color: AppPalette.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.softYellow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(value: '4', label: 'Matieres'),
                      _StatItem(value: '4', label: 'Validees'),
                      _StatItem(value: '14.25', label: 'Moyenne'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppPalette.lightBlue),
                    borderRadius: BorderRadius.circular(18),
                    color: AppPalette.white,
                  ),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'INFORMATIONS PERSONNELLES',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      _profileTile(
                        Icons.person_outline,
                        'Nom complet',
                        '${profile.prenoms} ${profile.nom}',
                      ),
                      _profileTile(
                        Icons.badge_outlined,
                        'Identifiant',
                        profile.matricule,
                      ),
                      _profileTile(Icons.mail_outline, 'Email', profile.email),
                      _profileTile(
                        Icons.phone_outlined,
                        'Telephone',
                        profile.telephone,
                      ),
                      _profileTile(
                        Icons.school_outlined,
                        'Filiere',
                        profile.filiere,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onLogout,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.blue,
                      foregroundColor: AppPalette.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Se deconnecter'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(StudentProfile student) {
    final first = student.prenoms.isNotEmpty ? student.prenoms[0] : '';
    final second = student.nom.isNotEmpty ? student.nom[0] : '';
    return '$first$second'.toUpperCase();
  }

  Widget _profileTile(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppPalette.lightBlue)),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: AppPalette.lightBlue,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(icon, color: AppPalette.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppPalette.blue,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppPalette.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

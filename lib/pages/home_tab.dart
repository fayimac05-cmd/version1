import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import '../widgets/banner_widget.dart';
import '../pages/canal_screen.dart';
import '../widgets/weekly_program_quick_widget.dart';
import 'groupe_filiere_screen.dart';
import 'tickets_screen.dart';
import 'notifications_page.dart';
import 'chat_ia_screen.dart'; // Importation de l'écran IA
import 'bulletin_screen.dart'; // Importation de l'écran Bulletins

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.profile});
  final StudentProfile profile;

  // Nouvelle Palette "Premium Academic"
  static const Color _brandBlue = Color(0xFF1E40AF); // Bleu Institutionnel Royal
  static const Color _accentOrange = Color(0xFFF97316); // Orange d'alerte/action
  static const Color _textMain = Color(0xFF0F172A); // Ardoise Foncé
  static const Color _textMuted = Color(0xFF64748B); // Gris de soutien
  static const Color _bgComponent = Color(0xFFF8FAFC); // Fond de carte ultra clean
  static const Color _border = Color(0xFFE2E8F0); 

  String get _salutation {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  String _dateAujourdhui() {
    const jours = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
    const mois  = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    final now = DateTime.now();
    return '${jours[now.weekday % 7]}, ${now.day} ${mois[now.month - 1]}';
  }

  static const _agendaItems = [
    {'heure': '08:00', 'titre': 'Algorithmique', 'lieu': 'Salle B204', 'type': 'cours'},
    {'heure': '09:55', 'titre': 'Réseaux Info', 'lieu': 'Amphi A', 'type': 'en_cours'},
    {'heure': '12:30', 'titre': 'Pause déjeuner', 'lieu': 'Cafétéria', 'type': 'pause'},
    {'heure': '14:00', 'titre': 'Examen mi-parcours', 'lieu': 'Salle C101', 'type': 'exam'},
    {'heure': '15:15', 'titre': 'TP Base données', 'lieu': 'Salle Info 1', 'type': 'cours'},
  ];

  static const _modulesItems = [
    {'nom': 'Algorithmique', 'note': '15.5', 'progress': 0.78},
    {'nom': 'Réseaux', 'note': '13.0', 'progress': 0.65},
    {'nom': 'Base de données', 'note': '18.0', 'progress': 0.90},
    {'nom': 'Systèmes', 'note': '9.0', 'progress': 0.45},
    {'nom': 'Maths', 'note': '14.5', 'progress': 0.72},
    {'nom': 'Anglais', 'note': '16.0', 'progress': 0.80},
  ];

  @override
  Widget build(BuildContext context) {
    final initiales =
        '${profile.prenoms.isNotEmpty ? profile.prenoms[0] : ''}'
        '${profile.nom.isNotEmpty ? profile.nom[0] : ''}'.toUpperCase();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── HEADER HAUT DE GAMME ─────────────────────────────────
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_brandBlue, Color(0xFF3B82F6)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _brandBlue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
                ),
                child: Center(child: Text(initiales, style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$_salutation,', style: const TextStyle(fontSize: 13, color: _textMuted)),
                Text('${profile.prenoms} ${profile.nom}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textMain, letterSpacing: -0.5)),
              ])),
              
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotificationsPage())),
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Stack(alignment: Alignment.center, children: [
                    const Icon(Icons.notifications_none_rounded, color: _textMain, size: 22),
                    Positioned(top: 11, right: 12, child: Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(color: _accentOrange, shape: BoxShape.circle))),
                  ]),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            // ── CARTE ACADÉMIQUE AVEC DÉGRADÉ PREMIUM NOBLE ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1E40AF), 
                    Color(0xFF0F172A), 
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E40AF).withOpacity(0.25), 
                    blurRadius: 20, 
                    offset: const Offset(0, 8)
                  )
                ],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(
                    child: Text(profile.filiere.isNotEmpty ? profile.filiere.toUpperCase() : 'INGÉNIERIE LOGICIELLE', 
                      style: TextStyle(color: Colors.white.withOpacity(0.93), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Niveau L2', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 22),
                Text('Moyenne Générale', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  textBaseline: TextBaseline.alphabetic, 
                  crossAxisAlignment: CrossAxisAlignment.baseline, 
                  children: [
                    const Text('14.52', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    const SizedBox(width: 4),
                    Text('/20', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                Container(width: double.infinity, height: 1, color: Colors.white.withOpacity(0.12)),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _badgeInfoCible('146', 'Crédits ECTS'),
                  _badgeInfoCible('0', 'Absences'),
                  _badgeInfoCible('Top 10%', 'Rang'),
                ])
              ]),
            ),

            const SizedBox(height: 26),

            // ── SERVICES ACADÉMIQUES STYLE PREMIUM BENTO GRID ──
            const Text('Services Académiques', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textMain)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupeFiliere(profile: profile))),
                child: _serviceButton(Icons.diversity_3_rounded, 'Ma Classe', 'Filière'))),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TicketsScreen(profile: profile))),
                child: _serviceButton(Icons.receipt_long_rounded, 'Scolarité', 'Finances'))),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CanalScreen(profile: profile))),
                child: _serviceButton(Icons.chat_bubble_outline_rounded, 'Canaux', 'Discussions', badge: '5'))),
            ]),

            const SizedBox(height: 16),

            // ── NOUVEAU : OUTILS ET APPRENTISSAGE DE L'ÉTUDIANT (IA & BULLETINS) ──
            Row(children: [
              // ─── CARTE ASSISTANT IA ───
              Expanded(
                child: _buildExtendedServiceCard(
                  context,
                  title: 'Assistant IA',
                  subtitle: 'Discuter avec l\'IA',
                  icon: Icons.smart_toy_rounded,
                  color: const Color(0xFF6366F1), // Joli Violet Technologique
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ChatIAScreen(profile: profile)),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // ─── CARTE BULLETINS ───
              Expanded(
                child: _buildExtendedServiceCard(
                  context,
                  title: 'Bulletins',
                  subtitle: 'Notes semestrielles',
                  icon: Icons.assignment_rounded,
                  color: const Color(0xFF0EA5E9), // Bleu Océan Lumineux
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BulletinScreen()),
                    );
                  },
                ),
              ),
            ]),

            const SizedBox(height: 28),

            // ── AGENDA DESIGN FRAGMENTÉ ─────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Emploi du temps', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textMain)),
                SizedBox(height: 2),
                Text('Votre journée chronologique', style: TextStyle(fontSize: 12, color: _textMuted)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: _bgComponent, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
                child: Text(_dateAujourdhui(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textMain)),
              ),
            ]),
            const SizedBox(height: 20),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _agendaItems.length,
              itemBuilder: (context, index) {
                final item = _agendaItems[index];
                final type = item['type'];
                final isCurrent = type == 'en_cours';
                
                if (type == 'pause') {
                  return Padding(
                    padding: const EdgeInsets.only(left: 60, bottom: 20, top: 4),
                    child: Row(children: [
                      const Icon(Icons.coffee_rounded, size: 16, color: _textMuted),
                      const SizedBox(width: 8),
                      Text('${item['titre']} — ${item['lieu']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textMuted, fontStyle: FontStyle.italic)),
                    ]),
                  );
                }

                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                    width: 48,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(item['heure']!, style: TextStyle(fontSize: 13, fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500, color: isCurrent ? _brandBlue : _textMuted)),
                    ),
                  ),
                  Column(children: [
                    const SizedBox(height: 16),
                    Container(
                      width: isCurrent ? 12 : 8, height: isCurrent ? 12 : 8,
                      decoration: BoxDecoration(
                        color: isCurrent ? _brandBlue : (type == 'exam' ? _accentOrange : Colors.white),
                        shape: BoxShape.circle,
                        border: Border.all(color: type == 'exam' ? _accentOrange : _brandBlue, width: isCurrent ? 3 : 2),
                      ),
                    ),
                    Container(width: 2, height: 55, color: _border),
                  ]),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isCurrent ? _brandBlue.withOpacity(0.04) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isCurrent ? _brandBlue.withOpacity(0.3) : _border, width: isCurrent ? 1.5 : 1),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item['titre']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textMain)),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.meeting_room_outlined, size: 13, color: _textMuted),
                            const SizedBox(width: 4),
                            Text(item['lieu']!, style: const TextStyle(fontSize: 12, color: _textMuted)),
                          ]),
                        ])),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: _brandBlue, borderRadius: BorderRadius.circular(8)),
                            child: const Text('En cours', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        if (type == 'exam')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: _accentOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Text('EXAMEN', style: TextStyle(color: _accentOrange, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ]),
                    ),
                  )
                ]);
              },
            ),

            const SizedBox(height: 20),

            // ── SUIVI DES MODULES ───────────────────────────────────────
            const Text('Suivi des Modules', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textMain)),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, mainAxisExtent: 90,
              ),
              itemCount: _modulesItems.length,
              itemBuilder: (context, index) {
                final m = _modulesItems[index];
                final noteVal = double.tryParse(m['note'] as String) ?? 0.0;
                final isWarning = noteVal < 10.0;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _bgComponent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(m['nom'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${m['note']}/20', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isWarning ? _accentOrange : _textMain)),
                        Text('${((m['progress'] as double) * 100).toInt()}% validé', style: const TextStyle(fontSize: 10, color: _textMuted)),
                      ]),
                      SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(
                          value: m['progress'] as double,
                          strokeWidth: 3,
                          backgroundColor: _border,
                          valueColor: AlwaysStoppedAnimation<Color>(isWarning ? _accentOrange : _brandBlue),
                        ),
                      )
                    ]),
                  ]),
                );
              },
            ),

            const SizedBox(height: 28),

            // ── ÉVÉNEMENTS & BANNER EXTÉRIEURS ───────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Événements du campus', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textMain)),
              Text('Voir tout', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _brandBlue)),
            ]),
            const SizedBox(height: 12),
            const BannerWidget(),
            const SizedBox(height: 12),
            const WeeklyProgramQuickWidget(),
          ]),
        ),
      ),
    );
  }

  Widget _badgeInfoCible(String valeur, String libelle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(valeur, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(height: 1),
      Text(libelle, style: TextStyle(color: Colors.white.withOpacity(0.73), fontSize: 10)),
    ],
  );

  Widget _serviceButton(IconData icon, String titre, String sousTitre, {String? badge}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20), 
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: _textMain.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 4), 
        )
      ]
    ),
    child: Stack(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: _brandBlue.withOpacity(0.08), 
            borderRadius: BorderRadius.circular(12)
          ),
          child: Icon(icon, color: _brandBlue, size: 21),
        ),
        const SizedBox(height: 14),
        Text(titre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textMain), maxLines: 1),
        const SizedBox(height: 1),
        Text(sousTitre, style: const TextStyle(fontSize: 10, color: _textMuted, fontWeight: FontWeight.w500)),
      ]),
      if (badge != null)
        Positioned(top: 0, right: 0, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(color: _accentOrange, borderRadius: BorderRadius.circular(8)),
          child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
        ))
    ]),
  );

  // Widget personnalisé pour dessiner le duo de cartes (IA et Bulletins)
  Widget _buildExtendedServiceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: _textMain.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textMain),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: _textMuted, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
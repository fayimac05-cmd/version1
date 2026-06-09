import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import '../widgets/banner_widget.dart';
import '../pages/canal_screen.dart';
import '../widgets/weekly_program_quick_widget.dart';
import 'groupe_filiere_screen.dart';
import 'tickets_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.profile});
  final StudentProfile profile;

  static const Color _orange = Color(0xFFF97316);

  // Taille fixe des cartes — identique pour agenda et modules
  static const double _cardW = 140.0;
  static const double _cardH = 120.0;

  String get _salutation {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  String _dateAujourdhui() {
    const jours = ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'];
    const mois  = ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'];
    final now = DateTime.now();
    return '${jours[now.weekday - 1]} ${now.day} ${mois[now.month - 1]}';
  }

  // Agenda : bleu = cours normal, orange = exam/spécial, blanc = pause
  static const _agendaItems = [
    {'heure': '08:00', 'titre': 'Algorithmique',     'lieu': 'Salle B204',   'style': 'bleu',   'tag': ''},
    {'heure': '09:55', 'titre': 'Réseaux Info',       'lieu': 'Amphi A',      'style': 'bleu',   'tag': 'En cours'},
    {'heure': '12:30', 'titre': 'Pause déjeuner',     'lieu': 'Cafétéria',    'style': 'blanc',  'tag': ''},
    {'heure': '14:00', 'titre': 'Examen mi-parcours', 'lieu': 'Salle C101',   'style': 'orange', 'tag': 'Exam'},
    {'heure': '15:15', 'titre': 'TP Base données',    'lieu': 'Salle Info 1', 'style': 'bleu',   'tag': ''},
    {'heure': '',      'titre': '+2 cours demain',    'lieu': 'Voir planning', 'style': 'orange', 'tag': ''},
  ];

  // Modules : alternance bleu / blanc / orange
  static const _modulesItems = [
    {'nom': 'Algorithmique',   'note': '15.5', 'progress': 0.78, 'style': 'blanc'},
    {'nom': 'Réseaux',         'note': '13.0', 'progress': 0.65, 'style': 'blanc'},
    {'nom': 'Base de données', 'note': '18.0', 'progress': 0.90, 'style': 'blanc'},
    {'nom': 'Systèmes',        'note': '9.0',  'progress': 0.45, 'style': 'blanc'},
    {'nom': 'Maths',           'note': '14.5', 'progress': 0.72, 'style': 'blanc'},
    {'nom': 'Anglais',         'note': '16.0', 'progress': 0.80, 'style': 'blanc'},
  ];

  Color _bg(String style) {
    if (style == 'bleu')   return AppPalette.blue;
    if (style == 'orange') return _orange;
    return Colors.white;
  }

  Color _textColor(String style) =>
      style == 'blanc' ? const Color(0xFF0F172A) : Colors.white;

  Color _subColor(String style) =>
      style == 'blanc' ? const Color(0xFF94A3B8) : Colors.white70;

  @override
  Widget build(BuildContext context) {
    final initiales =
        '${profile.prenoms.isNotEmpty ? profile.prenoms[0] : ''}'
        '${profile.nom.isNotEmpty ? profile.nom[0] : ''}'.toUpperCase();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(
                      color: AppPalette.blue, shape: BoxShape.circle),
                  child: Center(child: Text(initiales, style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$_salutation, ${profile.prenoms} 👋',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
                  Text(profile.filiere.isNotEmpty ? profile.filiere : 'IST Ouaga 2000',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                Stack(children: [
                  Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: const Icon(Icons.notifications_outlined,
                        color: Color(0xFF64748B), size: 20)),
                  Positioned(top: 8, right: 8, child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: _orange, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5)))),
                ]),
              ]),
            ),

            // ── Stats ────────────────────────────────────────────────
            Row(children: [
              Expanded(child: _statCard('14.5', 'Moyenne', AppPalette.blue)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('146',  'Crédits', _orange)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('L2',   'Niveau',  AppPalette.blue)),
            ]),

            const SizedBox(height: 14),

            // ── Accès rapide ─────────────────────────────────────────
            const Text('Accès rapide', style: TextStyle(fontSize: 14,
                fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => GroupeFiliere(profile: profile))),
                child: _carteAction(Icons.groups_rounded, AppPalette.blue, 'Groupe Filière', '🔒 Privé'))),
              const SizedBox(width: 8),
              Expanded(child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => TicketsScreen(profile: profile))),
                child: _carteAction(Icons.confirmation_number_outlined, _orange, 'Tickets', '🟠 Orange Money'))),
              const SizedBox(width: 8),
              Expanded(child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CanalScreen(profile: profile))),
                child: _carteAction(Icons.forum_rounded, AppPalette.blue, 'Canaux', '5 non lus'))),
            ]),

            const SizedBox(height: 16),

            // ── Conteneur Agenda + Modules ───────────────────────────
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                    blurRadius: 10, offset: const Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── AGENDA ─────────────────────────────────────────
                SizedBox(
                  width: _cardW * 2 + 8,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Agenda', style: TextStyle(fontSize: 14,
                          fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text(_dateAujourdhui(), style: const TextStyle(
                          fontSize: 10, color: Color(0xFF94A3B8))),
                    ]),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _agendaItems.map((item) {
                        final style = item['style'] as String;
                        final tag   = item['tag'] as String;
                        final bg    = _bg(style);
                        final tc    = _textColor(style);
                        final sc    = _subColor(style);
                        return SizedBox(
                          width: _cardW, height: _cardH,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(14),
                              border: style == 'blanc'
                                  ? Border.all(color: const Color(0xFFE2E8F0)) : null,
                              boxShadow: style == 'blanc' ? [] : [BoxShadow(
                                  color: bg.withOpacity(0.28),
                                  blurRadius: 6, offset: const Offset(0, 3))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  Text(item['heure'] as String,
                                      style: TextStyle(fontSize: 9,
                                          color: sc, fontWeight: FontWeight.w500)),
                                  const Spacer(),
                                  if (tag.isNotEmpty) Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: style == 'blanc'
                                          ? _orange.withOpacity(0.1)
                                          : Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(tag, style: TextStyle(fontSize: 8,
                                        color: style == 'blanc' ? _orange : Colors.white,
                                        fontWeight: FontWeight.bold))),
                                ]),
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(item['titre'] as String,
                                      style: TextStyle(fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: tc, height: 1.2),
                                      maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 3),
                                  Row(children: [
                                    Icon(Icons.location_on_outlined, size: 9, color: sc),
                                    const SizedBox(width: 2),
                                    Expanded(child: Text(item['lieu'] as String,
                                        style: TextStyle(fontSize: 9, color: sc),
                                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  ]),
                                ]),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ]),
                ),

                const SizedBox(width: 12),
                Container(width: 1, height: _cardH * 3 + 8 * 2 + 30,
                    color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 12),

                // ── MODULES ────────────────────────────────────────
                SizedBox(
                  width: _cardW * 2 + 8,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Modules', style: TextStyle(fontSize: 14,
                        fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _modulesItems.map((m) {
                        final style = m['style'] as String;
                        final bg    = _bg(style);
                        final tc    = _textColor(style);
                        final sc    = _subColor(style);
                        final p     = m['progress'] as double;
                        final barColor = style == 'blanc' ? AppPalette.blue : Colors.white;
                        return SizedBox(
                          width: _cardW, height: _cardH,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(14),
                              border: style == 'blanc'
                                  ? Border.all(color: const Color(0xFFE2E8F0)) : null,
                              boxShadow: style == 'blanc' ? [] : [BoxShadow(
                                  color: bg.withOpacity(0.28),
                                  blurRadius: 6, offset: const Offset(0, 3))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(m['nom'] as String,
                                    style: TextStyle(fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: tc, height: 1.2),
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('${m['note']}/20',
                                      style: TextStyle(fontSize: 14,
                                          fontWeight: FontWeight.bold, color: tc)),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: p, minHeight: 4,
                                      backgroundColor: barColor.withOpacity(0.2),
                                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text('${(p * 100).toInt()}%',
                                      style: TextStyle(fontSize: 9, color: sc)),
                                ]),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ]),
                ),

              ]),
            ),

            const SizedBox(height: 16),

            // ── Événements ───────────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Événements', style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const Text('Voir tout', style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w600, color: _orange)),
            ]),
            const SizedBox(height: 8),
            const BannerWidget(),
            const SizedBox(height: 10),
            const WeeklyProgramQuickWidget(),
            const SizedBox(height: 16),

            // ── Bannière motivation ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppPalette.blue,
                  borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Continuez comme ça ! 💪',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text('Top 10% de votre filière.',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
                Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 22)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _statCard(String val, String label, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: c.withOpacity(0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: c.withOpacity(0.15)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
          color: c, letterSpacing: -0.5)),
      Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
    ]),
  );

  Widget _carteAction(IconData icon, Color c, String titre, String sub) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: Colors.white, size: 20),
      const SizedBox(height: 8),
      Text(titre, style: const TextStyle(fontSize: 11,
          fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1),
      const SizedBox(height: 2),
      Text(sub, style: const TextStyle(fontSize: 9, color: Colors.white70)),
    ]),
  );
}

import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import '../pages/event_detail_screen.dart';

class BannerWidget extends StatefulWidget {
  const BannerWidget({super.key});

  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget> {
  int _current = 0;
  late PageController _ctrl;

  static const List<Map<String, dynamic>> events = [
    {
      'titre':  '🎵 Soirée étudiante BDE',
      'date':   'Vendredi 02 Mai 2026',
      'lieu':   'Campus IST',
      'type':   'BDE',
      'color':  Color(0xFF7C3AED),
      'detail': 'Grande soirée organisée par le Bureau des Étudiants. Entrée avec ticket Orange Money !',
      'ticket': true,
      'prix':   '500 FCFA',
    },
    {
      'titre':  '🏢 Visite Sonabel',
      'date':   'Mercredi 30 Avril 2026',
      'lieu':   'Siège Sonabel, Ouagadougou',
      'type':   'Admin',
      'color':  Color(0xFF0A4DA2),
      'detail': 'Visite pédagogique pour les étudiants de filière ST.',
      'ticket': false,
      'prix':   '',
    },
    {
      'titre':  '🎓 Cérémonie remise de diplômes',
      'date':   'Samedi 03 Mai 2026',
      'lieu':   'Salle des fêtes IST',
      'type':   'Admin',
      'color':  Color(0xFF15803D),
      'detail': 'Cérémonie officielle de la promotion 2023-2024.',
      'ticket': true,
      'prix':   '1 000 FCFA',
    },
    {
      'titre':  '⚽ Journée sportive',
      'date':   'Jeudi 01 Mai 2026',
      'lieu':   'Terrain universitaire',
      'type':   'BDE',
      'color':  Color(0xFFD97706),
      'detail': 'Foot, basket, athlétisme. Venez nombreux !',
      'ticket': false,
      'prix':   '',
    },
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return false;
      final next = (_current + 1) % events.length;
      _ctrl.animateToPage(next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut);
      setState(() => _current = next);
      return true;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 130,
        child: PageView.builder(
          controller: _ctrl,
          onPageChanged: (i) => setState(() => _current = i),
          itemCount: events.length,
          itemBuilder: (_, i) {
            final e = events[i];
            return GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => EventDetailScreen(event: e),
              )),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [e['color'] as Color, (e['color'] as Color).withOpacity(0.72)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(
                    color: (e['color'] as Color).withOpacity(0.3),
                    blurRadius: 12, offset: const Offset(0, 4),
                  )],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(e['titre'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                            color: Colors.white, letterSpacing: -0.2),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(e['type'],
                          style: const TextStyle(fontSize: 11, color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.calendar_today, size: 13, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(e['date'], style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ]),
                  const SizedBox(height: 5),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: Colors.white70),
                    const SizedBox(width: 6),
                    Flexible(child: Text(e['lieu'],
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                        overflow: TextOverflow.ellipsis)),
                    const Spacer(),
                    const Text('Voir détails →',
                        style: TextStyle(fontSize: 11, color: Colors.white70,
                            fontStyle: FontStyle.italic)),
                  ]),
                ]),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(events.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _current == i ? 20 : 6, height: 6,
            decoration: BoxDecoration(
              color: _current == i ? AppPalette.yellow : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(3),
            ),
          ))),
    ]);
  }
}

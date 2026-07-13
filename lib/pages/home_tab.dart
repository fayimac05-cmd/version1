import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import 'tickets_screen.dart';
import 'notifications_page.dart';
import 'chat_ia_screen.dart';
import 'bulletin_screen.dart';
import 'courses_tab.dart';
import 'groupe_filiere_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.profile});
  final StudentProfile profile;
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final PageController _eventsCtrl = PageController(viewportFraction: 0.82);
  final PageController _quotesCtrl = PageController(viewportFraction: 0.90);
  final PageController _newsCtrl   = PageController(viewportFraction: 0.92);
  int _eventPage = 0;
  final int _quotePage = 0;
  Timer? _autoScroll;
  Timer? _quoteScroll;

  // Annonces du backend
  List<Map<String, dynamic>> _annonces = [];
  bool _annoncesLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnnonces();
    _autoScroll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_eventPage + 1) % _events.length;
      _eventsCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
    _quoteScroll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_quotePage + 1) % _quotes.length;
      _quotesCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  Future<void> _fetchAnnonces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/annonces'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _annonces = List<Map<String, dynamic>>.from(data['data'] ?? []);
            _annoncesLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _annoncesLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _annoncesLoading = false);
    }
  }

  @override
  void dispose() {
    _eventsCtrl.dispose();
    _quotesCtrl.dispose();
    _newsCtrl.dispose();
    _autoScroll?.cancel();
    _quoteScroll?.cancel();
    super.dispose();
  }

  String get _salutation {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  // ── Data ────────────────────────────────────────────────────────────────────

  static const _quotes = [
    _QuoteData(
      '"La jeunesse d\'un pays est sa richesse la plus précieuse. Investir dans son éducation, c\'est construire l\'avenir.',
      'Thomas Sankara',
      'Président du Burkina Faso',
    ),
    _QuoteData(
      '"Un peuple sans éducation est un peuple sans âme. Le savoir est la lumière qui guide nos pas vers la liberté."',
      'Norbert Zongo',
      'Journaliste & Écrivain burkinabé',
    ),
    _QuoteData(
      '"Nabonswendé a dit : celui qui ne sème pas ne récolte pas. Le travail est la seule voie vers la dignité."',
      'Proverbe Mossi',
      'Tradition orale du Burkina Faso',
    ),
    _QuoteData(
      '"L\'école est la forge où l\'on fabrique les artisans du changement. Chaque étudiant porte en lui l\'espoir d\'une nation."',
      'Ablassé Ouédraogo',
      'Diplomate & Homme politique burkinabé',
    ),
    _QuoteData(
      '"Le travail honnête et l\'étude assidue sont les deux piliers sur lesquels repose la grandeur d\'un peuple."',
      'Gérard Kango Ouédraogo',
      'Homme d\'État burkinabé',
    ),
  ];

  static const _events = [
    _EventData('🎓', '25 Jan', 'Journée portes ouvertes',
        'Venez découvrir notre établissement et rencontrer les enseignants.',
        'Amphi A · 9h00'),
    _EventData('🤖', '30 Jan', 'Conférence IA',
        "L'avenir de l'intelligence artificielle dans l'éducation.",
        'Salle 101 · 14h00'),
    _EventData('💻', '5 Fév', 'Tournoi de code',
        'Compétition inter-filières de programmation. Inscriptions ouvertes.',
        'Labo Info · 10h00'),
    _EventData('🏆', '12 Fév', 'Remise des diplômes',
        'Cérémonie de remise des diplômes de la promotion 2024.',
        'Grand Amphi · 15h00'),
  ];

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF4FB),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildActionRow(context),
                const SizedBox(height: 8),
                _buildThreeRow(context),
                const SizedBox(height: 16),
                _buildCantineBtn(context),
                const SizedBox(height: 16),
                _buildFiliereBtn(context),
                const SizedBox(height: 16),
                _buildEventsCarousel(),
                const SizedBox(height: 16),
                _buildActualitesCarousel(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final initiales =
        '${widget.profile.prenoms.isNotEmpty ? widget.profile.prenoms[0] : ''}'
        '${widget.profile.nom.isNotEmpty ? widget.profile.nom[0] : ''}'
            .toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A3D91), Color(0xFF1565C0)],
        ),
        borderRadius:
            BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          // Bulles décoratives
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07)),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 80,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.yellow.withValues(alpha: 0.15)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppPalette.yellow, width: 2),
                    ),
                    child: Center(
                      child: Text(initiales,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0A3D91))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$_salutation,',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8))),
                        Text(
                            '${widget.profile.prenoms} ${widget.profile.nom}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        Text(
                          widget.profile.niveau.isNotEmpty
                              ? '${widget.profile.niveau} · ${widget.profile.filiere}'
                              : widget.profile.filiere,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.7)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _headerBtn(
                    child: Stack(children: [
                      const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 18),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppPalette.yellow,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF0A3D91), width: 1.5),
                          ),
                        ),
                      ),
                    ]),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => NotificationsPage())),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerBtn({required Widget child, VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: child),
        ),
      );

  // ── Action row ────────────────────────────────────────────────────────────

  Widget _buildActionRow(BuildContext context) {
    return Row(children: [
      Expanded(child: _actionCard(Icons.bar_chart_rounded, 'Résultats', () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BulletinScreen())))),
      const SizedBox(width: 8),
      Expanded(child: _actionCard(Icons.confirmation_number_outlined, 'Tickets', () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => TicketsScreen(profile: widget.profile))))),
    ]);
  }

  Widget _actionCard(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF1A3F6F).withValues(alpha: 0.12), width: 0.5),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppPalette.lightBlue,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppPalette.blue, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2A3A)))),
            const Text('›',
                style: TextStyle(fontSize: 18, color: Color(0xFFAABBCC))),
          ]),
        ),
      );

  // ── Three quick cards ─────────────────────────────────────────────────────

  Widget _buildThreeRow(BuildContext context) {
    final items = [
      (Icons.description_outlined, 'Bulletins',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BulletinScreen()))),
      (Icons.menu_book_rounded, 'Cours',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoursesTab()))),
      (Icons.smart_toy_outlined, 'Chat IA',
          () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ChatIAScreen(profile: widget.profile)))),
    ];
    return Row(
      children: List.generate(items.length, (i) {
        final (icon, label, onTap) = items[i];
        return Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              margin: EdgeInsets.only(right: i < items.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF1A3F6F).withValues(alpha: 0.12),
                    width: 0.5),
              ),
              child: Column(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: AppPalette.lightBlue,
                      borderRadius: BorderRadius.circular(9)),
                  child: Icon(icon, color: AppPalette.blue, size: 16),
                ),
                const SizedBox(height: 6),
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2A3A))),
              ]),
            ),
          ),
        );
      }),
    );
  }

  // ── Cantine bouton ────────────────────────────────────────────────────────

  Widget _buildCantineBtn(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCantineSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A3D91), Color(0xFF1976D2)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppPalette.blue.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.restaurant_menu_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Menu de la cantine',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text('Voir le menu du jour',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(8)),
            child: const Text('Ouvert',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: AppPalette.yellow,
                borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.arrow_forward_rounded,
                color: Color(0xFF3A2A00), size: 16),
          ),
        ]),
      ),
    );
  }

  // ── Ma filière bouton ─────────────────────────────────────────────────────

  Widget _buildFiliereBtn(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => GroupeFiliere(profile: widget.profile))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF0A3D91)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppPalette.blue.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.groups_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ma filière',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text(
                  widget.profile.filiere.isNotEmpty
                      ? 'Canal ${widget.profile.filiere}'
                      : 'Canal de la filière',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: AppPalette.yellow,
                borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.arrow_forward_rounded,
                color: Color(0xFF3A2A00), size: 16),
          ),
        ]),
      ),
    );
  }

  void _showCantineSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CantineSheet(),
    );
  }

  // ── Events carousel ───────────────────────────────────────────────────────

  Widget _buildEventsCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Événements à venir', 'Voir tout'),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _eventsCtrl,
            itemCount: _events.length,
            onPageChanged: (i) => setState(() => _eventPage = i),
            itemBuilder: (_, i) => _eventCard(_events[i]),
          ),
        ),
        const SizedBox(height: 10),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _events.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _eventPage == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _eventPage == i
                    ? AppPalette.blue
                    : AppPalette.blue.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _eventCard(_EventData ev) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A3D91), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: AppPalette.blue.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          // Bulle déco
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text(ev.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(ev.date,
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600)),
                ),
              ]),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ev.titre,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 3),
                  Text(ev.desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.75))),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.location_on_outlined,
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.7)),
                    const SizedBox(width: 3),
                    Text(ev.lieu,
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.7))),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                        color: AppPalette.yellow,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text('Participer',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3A2A00))),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Actualités carousel (depuis le backend) ──────────────────────────────

  static const _typeConfig = {
    'urgent': (Icons.warning_amber_rounded, Color(0xFFEF4444), Color(0xFFFEF2F2), 'Urgent'),
    'event':  (Icons.event_rounded,         Color(0xFF8B5CF6), Color(0xFFF5F3FF), 'Événement'),
    'info':   (Icons.info_outline_rounded,  Color(0xFF0A4DA2), Color(0xFFEFF6FF), 'Info'),
  };

  Widget _buildActualitesCarousel() {
    final items = _annonces.isNotEmpty ? _annonces : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Annonces du campus',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A2A3A))),
            GestureDetector(
              onTap: _fetchAnnonces,
              child: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF1A3F6F)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_annoncesLoading)
          const SizedBox(height: 130,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        else if (items == null || items.isEmpty)
          _annonceVide()
        else
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _annonceCard(items[i]),
            ),
          ),
      ],
    );
  }

  Widget _annonceCard(Map<String, dynamic> a) {
    final type = a['type'] as String? ?? 'info';
    final cfg = _typeConfig[type] ?? _typeConfig['info']!;
    final (icon, color, bgColor, label) = cfg;

    // Formatage de la date
    String dateStr = '';
    try {
      final dt = DateTime.parse(a['created_at'] as String);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) {
        dateStr = 'Il y a ${diff.inMinutes} min';
      } else if (diff.inHours < 24) {
        dateStr = 'Il y a ${diff.inHours}h';
      } else {
        dateStr = 'Il y a ${diff.inDays}j';
      }
    } catch (_) {}

    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['titre'] as String? ?? '',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2A3A), height: 1.3)),
                const Spacer(),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(5)),
                    child: Text(label,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                  ),
                  const SizedBox(width: 6),
                  Text(dateStr, style: const TextStyle(fontSize: 9, color: Color(0xFFAABBCC))),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _annonceVide() {
    return SizedBox(
      height: 100,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.campaign_outlined, size: 32, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 6),
          Text('Aucune annonce pour l\'instant',
              style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionHeader(String titre, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(titre,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2A3A))),
        Text(action,
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF1A3F6F),
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Cantine bottom sheet ────────────────────────────────────────────────────

class _CantineSheet extends StatelessWidget {
  const _CantineSheet();

  static const _menu = [
    ('☀️', 'Petit déjeuner', [
      ['Croissant', '200 FCFA'],
      ['Pain au chocolat', '250 FCFA'],
      ['Café au lait', '150 FCFA'],
    ]),
    ('🍽️', 'Déjeuner', [
      ['Riz gras', '500 FCFA'],
      ['Poisson braisé', '800 FCFA'],
      ['Salade verte', '300 FCFA'],
    ]),
    ('🌙', 'Dîner', [
      ['Yassa poulet', '700 FCFA'],
      ['Thiéboudienne', '800 FCFA'],
      ['Soupe légumes', '400 FCFA'],
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2)),
          ),
          // Sheet header (gradient)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A3D91), Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Icon(Icons.restaurant_menu_rounded,
                  color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Menu du jour',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    Text('Jeudi 26 Juin 2026',
                        style: TextStyle(
                            fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('Ouvert',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _menu.map((m) {
                  final (emoji, titre, plats) = m;
                  return _mealSection(emoji, titre, plats);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _mealSection(String emoji, String titre, List<List<String>> plats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.lightBlue, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: AppPalette.lightBlue,
                  borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 8),
            Text(titre,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2A3A))),
          ]),
          const SizedBox(height: 10),
          ...plats.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p[0],
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF555566))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppPalette.softYellow,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(p[1],
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4A3000))),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Data models ──────────────────────────────────────────────────────────────

class _QuoteData {
  final String citation, auteur, titre;
  const _QuoteData(this.citation, this.auteur, this.titre);
}

class _EventData {
  final String emoji, date, titre, desc, lieu;
  const _EventData(this.emoji, this.date, this.titre, this.desc, this.lieu);
}


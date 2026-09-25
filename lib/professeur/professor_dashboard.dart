import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student_profile.dart';
import '../services/professor_service.dart';
import '../theme/app_palette.dart';

class ProfessorDashboard extends StatefulWidget {
  const ProfessorDashboard({
    super.key,
    required this.profile,
    this.onClasses,
    this.onCours,
    this.onAppel,
    this.onNotes,
    this.onMessages,
    this.onProfil,
  });

  final StudentProfile profile;
  final VoidCallback? onClasses;
  final VoidCallback? onCours;
  final VoidCallback? onAppel;
  final VoidCallback? onNotes;
  final VoidCallback? onMessages;
  final VoidCallback? onProfil;

  @override
  State<ProfessorDashboard> createState() => _ProfessorDashboardState();
}

class _ProfessorDashboardState extends State<ProfessorDashboard> {
  bool _loading = true;
  String? _error;
  List<dynamic> _classes = [];
  List<dynamic> _cours = [];
  List<dynamic> _sessions = [];
  List<dynamic> _appels = [];
  List<Map<String, dynamic>> _coursDuJour = [];
  List<_RecentItem> _recentActivitiesCache = [];
  final ScrollController _scrollController = ScrollController();

  // ── Couleurs de la maquette — sidebar/bandeaux en bleu marine plein,
  // pastilles de statut, cartes d'action pleines (voir Nommer/etc. ailleurs
  // dans l'app pour la même logique de tokens locaux hors AppPalette).
  static const Color _navy = Color(0xFF0B1E4D);
  static const Color _navyText = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _faint = Color(0xFF94A3B8);
  static const Color _border = Color(0xFFE5EBF3);
  static const Color _amber = Color(0xFFF5A623);
  static const Color _green = Color(0xFF10B981);

  static const List<String> _joursFr = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  static const List<IconData> _icones = [
    Icons.calculate_rounded,
    Icons.router_rounded,
    Icons.settings_suggest_rounded,
    Icons.menu_book_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _chargerDashboard();
  }

  Future<void> _chargerDashboard() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        ProfessorService.getClasses(),
        ProfessorService.getCours(),
        ProfessorService.getGradeSessions(),
        ProfessorService.getAppels(),
      ]);

      if (!mounted) return;

      setState(() {
        _classes = _extractList(results[0]);
        _cours = _extractList(results[1]);
        _sessions = _extractList(results[2]);
        _appels = _extractList(results[3]);
        _recentActivitiesCache = _buildRecentActivitiesCache();
        _loading = false;
      });

      await _chargerProgrammeDuJour();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger certaines données.';
      });
    }
  }

  Future<void> _chargerProgrammeDuJour() async {
    try {
      final filiere = widget.profile.filiere.trim();
      final niveau = widget.profile.niveau.trim();

      if (filiere.isEmpty || niveau.isEmpty) {
        if (mounted) setState(() => _coursDuJour = []);
        return;
      }

      final row = await Supabase.instance.client
          .from('edt')
          .select('creneaux')
          .ilike('filiere_nom', filiere)
          .ilike('niveau', niveau)
          .eq('archive', false)
          .order('createdAt', ascending: false)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      final raw = row?['creneaux'];
      final today = _joursFr[DateTime.now().weekday - 1];
      final list = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .where((e) => e['jour']?.toString().trim() == today)
              .toList()
          : <Map<String, dynamic>>[];

      list.sort(
        (a, b) => (a['heureDebut']?.toString() ?? '')
            .compareTo(b['heureDebut']?.toString() ?? ''),
      );

      setState(() => _coursDuJour = list);
    } catch (_) {
      if (mounted) setState(() => _coursDuJour = []);
    }
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is! Map || response['success'] != true) return [];
    final data = response['data'];
    return data is List ? List<dynamic>.from(data) : [];
  }

  String get _prenom => widget.profile.prenoms.trim().isEmpty
      ? 'Professeur'
      : widget.profile.prenoms.trim();

  String get _nomComplet {
    final prenoms = widget.profile.prenoms.trim();
    final nom = widget.profile.nom.trim();
    final value = '$prenoms $nom'.trim();
    return value.isEmpty ? 'Professeur' : value;
  }

  String get _initiale {
    final prenoms = widget.profile.prenoms.trim();
    final nom = widget.profile.nom.trim();
    if (prenoms.isNotEmpty) return prenoms[0].toUpperCase();
    if (nom.isNotEmpty) return nom[0].toUpperCase();
    return 'P';
  }

  int get _totalEtudiants {
    var total = 0;
    for (final item in _classes) {
      if (item is! Map) continue;
      final values = [
        item['nombre_etudiants'],
        item['nb_etudiants'],
        item['nombreEtudiants'],
        item['effectif'],
        item['student_count'],
        item['students_count'],
      ];
      for (final value in values) {
        final parsed = int.tryParse(value?.toString() ?? '');
        if (parsed != null) {
          total += parsed;
          break;
        }
      }
    }
    return total;
  }

  String _courseName(dynamic item) {
    if (item is! Map) return 'Cours';
    final title = item['titre']?.toString().trim() ?? '';
    final module = item['module_nom']?.toString().trim() ?? '';
    if (title.isNotEmpty) return title;
    if (module.isNotEmpty) return module;
    return 'Cours';
  }

  String _className(dynamic item) {
    if (item is! Map) return 'Classe';
    final candidates = [item['nom'], item['classe_nom'], item['libelle'], item['filiere_nom']];
    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return 'Classe';
  }

  String _firstText(List<dynamic> values, {required String fallback}) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  String _sessionName(dynamic item) {
    if (item is! Map) return 'Session de notes';
    for (final value in [item['titre'], item['nom'], item['module_nom']]) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return 'Session de notes';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F7FB),
      child: SafeArea(
        bottom: false,
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          interactive: true,
          child: RefreshIndicator(
            onRefresh: _chargerDashboard,
            color: AppPalette.blue,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1380),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopRow(),
                      const SizedBox(height: 20),
                      if (_loading) ...[
                        const LinearProgressIndicator(minHeight: 2),
                        const SizedBox(height: 14),
                      ],
                      if (_error != null) ...[
                        _buildError(),
                        const SizedBox(height: 14),
                      ],
                      _buildStats(),
                      const SizedBox(height: 26),
                      _sectionTitle('Actions rapides', 'Accédez rapidement aux principales fonctionnalités.'),
                      const SizedBox(height: 12),
                      _buildQuickActions(),
                      const SizedBox(height: 26),
                      _buildLowerContent(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── En-tête léger : "Bonjour, X" à gauche, cloche + profil à droite —
  // sur le fond de page, sans bandeau bleu plein (contrairement à l'ancienne
  // version qui empilait deux blocs bleus l'un sur l'autre).
  Widget _buildTopRow() {
    final photoUrl = widget.profile.photoUrl?.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bonjour, $_prenom 👋',
                  style: const TextStyle(color: _navyText, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('Voici un aperçu de votre activité académique aujourd\'hui.',
                  style: TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            onTap: widget.onMessages,
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: Stack(clipBehavior: Clip.none, children: [
                const Center(child: Icon(Icons.notifications_none_rounded, color: _navyText, size: 22)),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: widget.onProfil,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: AppPalette.blue.withValues(alpha: 0.14),
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl == null || photoUrl.isEmpty
                    ? Text(_initiale, style: const TextStyle(color: AppPalette.blue, fontWeight: FontWeight.w900, fontSize: 15))
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_nomComplet, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _navyText, fontSize: 13.5, fontWeight: FontWeight.w800)),
                  Text('Professeur${widget.profile.matricule.isNotEmpty ? " • ${widget.profile.matricule}" : ""}',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _faint, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900 ? 4 : width >= 560 ? 2 : 1;
        final gap = 14.0;
        final cardWidth = (width - gap * (columns - 1)) / columns;
        final stats = [
          _DashboardStat('${_classes.length}', 'Classes', 'Enseignées', Icons.groups_rounded, AppPalette.blue, widget.onClasses),
          _DashboardStat('${_cours.length}', 'Cours', 'Publiés', Icons.menu_book_rounded, _amber, widget.onCours),
          _DashboardStat(_totalEtudiants > 0 ? '$_totalEtudiants' : '—', 'Étudiants', 'Au total', Icons.person_rounded, _green, widget.onClasses),
          _DashboardStat('${_sessions.length}', 'Notes', 'À compléter', Icons.fact_check_rounded, const Color(0xFF7C3AED), widget.onNotes),
        ];
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: stats.map((stat) => SizedBox(width: cardWidth, child: _statCard(stat))).toList(),
        );
      },
    );
  }

  Widget _statCard(_DashboardStat stat) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: stat.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: stat.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
                    child: Icon(stat.icon, color: stat.color, size: 21),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(color: stat.color.withValues(alpha: 0.10), shape: BoxShape.circle),
                    child: Icon(Icons.chevron_right_rounded, color: stat.color, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(stat.value, style: const TextStyle(color: _navyText, fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(stat.label, style: const TextStyle(color: _navyText, fontSize: 13, fontWeight: FontWeight.w700)),
              Text(stat.sublabel, style: const TextStyle(color: _faint, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: _navyText, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: _faint, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ── 3 cartes pleines, exactement comme la maquette : Appel (bleu),
  // Notes (ambre), Publier un cours (bleu clair).
  Widget _buildQuickActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 3 : 1;
        final gap = 14.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final actions = [
          _quickCard(
            width: width,
            title: 'Faire l\'appel',
            subtitle: 'Gérer la présence des étudiants',
            icon: Icons.how_to_reg_rounded,
            bg: AppPalette.blue,
            fg: Colors.white,
            sub: Colors.white70,
            onTap: widget.onAppel,
          ),
          _quickCard(
            width: width,
            title: 'Saisir les notes',
            subtitle: 'Évaluer vos étudiants',
            icon: Icons.edit_note_rounded,
            bg: _amber,
            fg: const Color(0xFF3A2A00),
            sub: const Color(0xFF6B5215),
            onTap: widget.onNotes,
          ),
          _quickCard(
            width: width,
            title: 'Publier un cours',
            subtitle: 'Partager un nouveau support',
            icon: Icons.menu_book_rounded,
            bg: AppPalette.lightBlue,
            fg: _navyText,
            sub: _muted,
            onTap: widget.onCours,
          ),
        ];
        return Wrap(spacing: gap, runSpacing: gap, children: actions);
      },
    );
  }

  Widget _quickCard({
    required double width,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bg,
    required Color fg,
    required Color sub,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: width,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: fg.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: fg, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(color: fg, fontSize: 14.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: sub, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: fg.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: Icon(Icons.chevron_right_rounded, color: fg, size: 18),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildLowerContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 980;

        if (!desktop) {
          return Column(
            children: [
              _buildProgramme(),
              const SizedBox(height: 14),
              _buildRecentActivity(),
              const SizedBox(height: 14),
              _buildBanner(),
              const SizedBox(height: 14),
              _buildUpcomingClasses(),
              const SizedBox(height: 14),
              _buildLastActivities(),
              const SizedBox(height: 14),
              _buildMotivationCard(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  _buildProgramme(),
                  const SizedBox(height: 14),
                  _buildRecentActivity(),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildBanner(),
                  const SizedBox(height: 14),
                  _buildUpcomingClasses(),
                  const SizedBox(height: 14),
                  _buildLastActivities(),
                  const SizedBox(height: 14),
                  _buildMotivationCard(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Bandeau citation (remplace la photo du campus qu'on n'a pas encore —
  // même traitement dégradé bleu marine + citation, en attendant une vraie
  // image si tu veux en fournir une).
  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1E4D), Color(0xFF1E3A8A)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('« L\'éducation est l\'arme la plus puissante pour changer le monde. »',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, height: 1.4)),
          const SizedBox(height: 8),
          Text('— Nelson Mandela', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildProgramme() {
    final visible = _coursDuJour.take(3).toList();
    final hasMore = _coursDuJour.length > 3;

    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: AppPalette.blue.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.calendar_month_rounded, color: AppPalette.blue, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Aujourd\'hui', style: TextStyle(color: _navyText, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    const Text('Vos prochains cours', style: TextStyle(color: _faint, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (hasMore)
                TextButton(
                  onPressed: _showAllCourses,
                  style: TextButton.styleFrom(foregroundColor: AppPalette.blue, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5)),
                  child: const Text('Voir tout', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(children: [
                const Icon(Icons.event_available_rounded, size: 34, color: Color(0xFFCBD5E1)),
                const SizedBox(height: 8),
                const Text('Aucun cours prévu aujourd\'hui.', style: TextStyle(color: _muted, fontSize: 12)),
              ]),
            )
          else
            for (var i = 0; i < visible.length; i++) _programmeRow(visible[i], i),
        ],
      ),
    );
  }

  String get _jourAujourdhui => _joursFr[DateTime.now().weekday - 1];

  // ── Statut du créneau : "En cours" (vert) si l'heure actuelle y est,
  // "À venir" (bleu clair) si c'est plus tard aujourd'hui, "Terminé" (gris)
  // si déjà passé — la maquette ne montre que les deux premiers cas mais un
  // cours déjà passé doit rester lisible plutôt que de garder "À venir".
  ({String label, Color bg, Color fg}) _statutCreneau(String debut, String fin) {
    final now = TimeOfDay.now();
    int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
    TimeOfDay? parse(String v) {
      final parts = v.split(':');
      if (parts.length < 2) return null;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) return null;
      return TimeOfDay(hour: h, minute: m);
    }

    final d = parse(debut);
    final f = parse(fin);
    final nowM = toMinutes(now);
    if (d != null && f != null && nowM >= toMinutes(d) && nowM <= toMinutes(f)) {
      return (label: 'En cours', bg: const Color(0xFFD1FAE5), fg: const Color(0xFF059669));
    }
    if (d != null && nowM > toMinutes(d)) {
      return (label: 'Terminé', bg: const Color(0xFFF1F5F9), fg: _faint);
    }
    return (label: 'À venir', bg: const Color(0xFFDCEAFE), fg: AppPalette.blue);
  }

  Widget _programmeRow(Map<String, dynamic> item, int index) {
    final debut = item['heureDebut']?.toString() ?? '';
    final fin = item['heureFin']?.toString() ?? '';
    final matiere = _firstText([
      item['matiere'], item['cours'], item['module'], item['module_nom'], item['titre'],
    ], fallback: 'Cours');
    final classe = _firstText([
      item['classe'], item['classe_nom'], item['filiere_nom'], item['niveau'],
    ], fallback: 'Classe');
    final salle = item['salle']?.toString().trim() ?? '';
    final statut = _statutCreneau(debut, fin);
    final icone = _icones[index % _icones.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE8EEF5)),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: AppPalette.blue, borderRadius: BorderRadius.circular(12)),
          child: Icon(icone, color: Colors.white, size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(debut.isEmpty ? '--:--' : debut, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700)),
                if (fin.isNotEmpty) Text(' - $fin', style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 2),
              Text(matiere, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _navyText, fontSize: 13.5, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Row(children: [
                Flexible(child: Text(classe, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _faint, fontSize: 10.5, fontWeight: FontWeight.w600))),
                if (salle.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.location_on_rounded, size: 11, color: _faint),
                  Text(salle, style: const TextStyle(color: _faint, fontSize: 10.5, fontWeight: FontWeight.w600)),
                ],
              ]),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: statut.bg, borderRadius: BorderRadius.circular(20)),
            child: Text(statut.label, style: TextStyle(color: statut.fg, fontSize: 10, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 6),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 18),
        ]),
      ]),
    );
  }

  Widget _cardHeading(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: AppPalette.blue.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: AppPalette.blue, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _navyText, fontSize: 13, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _faint, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final items = _allRecentActivities();

    if (items.isEmpty) {
      return _whiteCard(
        child: Column(children: [
          _cardHeading(Icons.history_rounded, 'Activité récente', 'Vos dernières actions'),
          const SizedBox(height: 22),
          const Icon(Icons.history_rounded, size: 40, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 9),
          const Text('Aucune activité récente à afficher.', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 12)),
        ]),
      );
    }

    final visible = items.take(4).toList();
    final hasMore = items.length > 4;

    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _cardHeading(Icons.history_rounded, 'Activité récente', 'Vos dernières actions')),
            if (hasMore)
              TextButton(
                onPressed: _showAllActivities,
                style: TextButton.styleFrom(foregroundColor: AppPalette.blue, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5)),
                child: const Text('Voir tout', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ),
          ]),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 650) {
                return Column(children: [
                  for (var i = 0; i < visible.length; i++) _activityRow(visible[i], showDivider: i != visible.length - 1),
                ]);
              }
              final gap = 10.0;
              final width = (constraints.maxWidth - gap * (visible.length - 1)) / visible.length;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < visible.length; i++) ...[
                    SizedBox(width: width, child: _activityTile(visible[i])),
                    if (i != visible.length - 1) const SizedBox(width: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<_RecentItem> _buildRecentActivitiesCache() {
    final items = <_RecentItem>[];

    for (final item in _cours) {
      items.add(_RecentItem(Icons.menu_book_rounded, _amber, _courseName(item), 'Cours publié'));
    }

    for (final item in _sessions) {
      final status = item is Map ? item['statut']?.toString().trim() ?? '' : '';
      items.add(_RecentItem(Icons.fact_check_rounded, const Color(0xFF7C3AED), _sessionName(item), status.isEmpty ? 'Session de notes' : status));
    }

    for (final item in _appels) {
      items.add(_RecentItem(Icons.how_to_reg_rounded, _green, 'Appel', _className(item)));
    }

    return items;
  }

  List<_RecentItem> _allRecentActivities() => _recentActivitiesCache;

  Widget _activityTile(_RecentItem item) {
    return Container(
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE8EEF5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: item.color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(height: 9),
          Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _navyText, fontSize: 11.5, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _faint, fontSize: 9.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _activityRow(_RecentItem item, {bool showDivider = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: showDivider ? const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F3F7)))) : null,
      child: Row(children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(color: item.color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(11)),
          child: Icon(item.icon, color: item.color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _navyText, fontSize: 12.5, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right,
              style: const TextStyle(color: _faint, fontSize: 10.5, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _buildUpcomingClasses() {
    final visible = _classes.take(3).toList();
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _cardHeading(Icons.calendar_today_rounded, 'Prochaines classes', 'Votre espace d\'enseignement')),
            if (widget.onClasses != null)
              TextButton(
                onPressed: widget.onClasses,
                style: TextButton.styleFrom(foregroundColor: AppPalette.blue, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4)),
                child: const Text('Voir tout', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ),
          ]),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Aucune classe disponible.', style: TextStyle(color: _faint, fontSize: 11)),
            )
          else
            ...visible.map((item) => Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F3F7)))),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: AppPalette.blue.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.groups_rounded, color: AppPalette.blue, size: 17),
                ),
                const SizedBox(width: 9),
                Expanded(child: Text(_className(item), maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _navyText, fontSize: 11.5, fontWeight: FontWeight.w800))),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 18),
              ]),
            )),
        ],
      ),
    );
  }

  Widget _buildLastActivities() {
    final visible = _allRecentActivities().take(4).toList();
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _cardHeading(Icons.history_toggle_off_rounded, 'Mes dernières activités', 'Un aperçu de vos dernières actions')),
            if (visible.isNotEmpty)
              TextButton(
                onPressed: _showAllActivities,
                style: TextButton.styleFrom(foregroundColor: AppPalette.blue, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4)),
                child: const Text('Voir tout', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ),
          ]),
          const SizedBox(height: 7),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('Aucune activité disponible.', style: TextStyle(color: _faint, fontSize: 11)),
            )
          else
            ...visible.map((item) => _activityRow(item, showDivider: item != visible.last)),
        ],
      ),
    );
  }

  Future<void> _showAllCourses() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vos prochains cours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _navyText)),
              const SizedBox(height: 10),
              for (var i = 0; i < _coursDuJour.length; i++) _programmeRow(_coursDuJour[i], i),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAllActivities() async {
    if (!mounted) return;
    final items = _allRecentActivities();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          children: [
            const Text('Toutes les activités', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _navyText)),
            const SizedBox(height: 8),
            ...items.map((item) => _activityRow(item, showDivider: item != items.last)),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(color: _amber, borderRadius: BorderRadius.circular(18)),
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
          right: -10, bottom: -14,
          child: Icon(Icons.school_rounded, color: Colors.white.withValues(alpha: 0.22), size: 64),
        ),
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Vous faites la différence !', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900)),
              SizedBox(height: 3),
              Text('Chaque effort compte dans la réussite de vos étudiants.',
                  style: TextStyle(color: Colors.white, fontSize: 11, height: 1.35, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _whiteCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: child,
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFFECACA))),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
        const SizedBox(width: 8),
        const Expanded(child: Text('Certaines données n\'ont pas pu être chargées.', style: TextStyle(color: Color(0xFF991B1B), fontSize: 11.5, fontWeight: FontWeight.w600))),
        IconButton(onPressed: _chargerDashboard, icon: const Icon(Icons.refresh_rounded, color: Color(0xFFDC2626), size: 20)),
      ]),
    );
  }
}

class _DashboardStat {
  const _DashboardStat(this.value, this.label, this.sublabel, this.icon, this.color, this.onTap);
  final String value;
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}

class _RecentItem {
  const _RecentItem(this.icon, this.color, this.title, this.subtitle);
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}
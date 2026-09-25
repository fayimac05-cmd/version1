import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import '../models/student_profile.dart';
import '../services/api_service.dart';
import '../services/professor_service.dart';
import '../theme/app_palette.dart';
import '../widgets/profile_header_cover.dart';
import 'appel_tab.dart';
import 'notes_tab.dart';
import 'programme_screen.dart';
import 'upload_course_screen.dart';
import 'professeur_liste_etudiants.dart';
import '../admin/admin_messages.dart';
import '../pages/discussion_privee_page.dart';
import 'professor_dashboard.dart';

// ── Shell principal ────────────────────────────────────────────────────────

class ProfessorShell extends StatefulWidget {
  const ProfessorShell({super.key, required this.profile, required this.onLogout});
  final StudentProfile profile;
  final VoidCallback onLogout;

  @override
  State<ProfessorShell> createState() => _ProfessorShellState();
}

class _ProfessorShellState extends State<ProfessorShell> {
  // 0 = Accueil, 1 = Classes, 2 = Cours, 3 = Appel,
  // 4 = Notes, 5 = Messages, 6 = Profil.
  int _currentTab = 0;

  // Classe présélectionnée depuis "Mes Classes" pour l'appel ou les notes.
  Map<String, dynamic>? _classePreselectionnee;

  void _ouvrirDepuisClasse(int tab, Map<String, dynamic> classe) {
    setState(() {
      _classePreselectionnee = classe;
      _currentTab = tab;
    });
  }

  Widget _buildCurrentPage() {
    switch (_currentTab) {
      case 0:
        return ProfessorDashboard(
          profile: widget.profile,
          onClasses: () => _goTo(1),
          onCours: () => _goTo(2),
          onAppel: () => _goTo(3),
          onNotes: () => _goTo(4),
          onMessages: () => _goTo(5),
          onProfil: () => _goTo(6),
        );
      case 1:
        return _ClassesTab(
          profile: widget.profile,
          onFaireAppel: (c) => _ouvrirDepuisClasse(3, c),
          onSaisirNotes: (c) => _ouvrirDepuisClasse(4, c),
        );
      case 2:
        return _CoursTab(profile: widget.profile);
      case 3:
        return AppelTab(profile: widget.profile, initialClasse: _classePreselectionnee);
      case 4:
        return NotesTab(profile: widget.profile, initialClasse: _classePreselectionnee);
      case 5:
        return const AdminMessages(role: 'professeur');
      case 6:
        return _ProfilTab(profile: widget.profile, onLogout: widget.onLogout);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _buildCurrentPage();
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;

        if (desktop) {
          return Scaffold(
            backgroundColor: const Color(0xFFF4F7FB),
            body: Row(
              children: [
                _buildDesktopSidebar(),
                Expanded(
                  child: page,
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FB),
          body: page,
          bottomNavigationBar: _buildNav(),
        );
      },
    );
  }

  void _goTo(int index) {
    setState(() {
      _currentTab = index;
      if (index != 3 && index != 4) {
        _classePreselectionnee = null;
      }
    });
  }

  Widget _buildDesktopSidebar() {
    final photoUrl = widget.profile.photoUrl?.trim();
    final nom = widget.profile.prenoms.trim().isNotEmpty
        ? widget.profile.prenoms.trim()
        : widget.profile.nom.trim();

    return Container(
      width: 252,
      // ✅ Fond bleu marine plein (au lieu du dégradé) — plus proche de la
      // maquette, et cohérent avec le bandeau/les cartes du tableau de bord
      // qui utilisent maintenant le même bleu marine (0xFF0B1E4D).
      color: const Color(0xFF0B1E4D),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: const Icon(Icons.school_rounded, color: AppPalette.yellow, size: 25),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Text(
                      'ScholarHub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null || photoUrl.isEmpty
                          ? Text(
                              _sidebarInitiale(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Espace professeur', style: TextStyle(color: Color(0xFFB9CBE8), fontSize: 10, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(nom.isEmpty ? 'Professeur' : nom.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Padding(
                padding: EdgeInsets.only(left: 10, bottom: 9),
                child: Text('MENU PRINCIPAL', style: TextStyle(color: Color(0xFF7895BD), fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _sideItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Tableau de bord', 0),
                      _sideItem(Icons.groups_outlined, Icons.groups_rounded, 'Classes', 1),
                      _sideItem(Icons.menu_book_outlined, Icons.menu_book_rounded, 'Cours', 2),
                      _sideItem(Icons.how_to_reg_outlined, Icons.how_to_reg_rounded, 'Appel', 3),
                      _sideItem(Icons.fact_check_outlined, Icons.fact_check_rounded, 'Notes', 4),
                      _sideItem(Icons.forum_outlined, Icons.forum_rounded, 'Messages', 5),
                      _sideItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil', 6),
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPalette.yellow.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppPalette.yellow.withValues(alpha: 0.12)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, color: AppPalette.yellow, size: 20),
                    SizedBox(width: 9),
                    Expanded(child: Text('Votre espace enseignant, au même endroit.', style: TextStyle(color: Color(0xFFDCE8FA), fontSize: 10.5, height: 1.35, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sidebarInitiale() {
    final prenoms = widget.profile.prenoms.trim();
    final nom = widget.profile.nom.trim();
    if (prenoms.isNotEmpty) return prenoms[0].toUpperCase();
    if (nom.isNotEmpty) return nom[0].toUpperCase();
    return 'P';
  }

  Widget _sideItem(IconData icon, IconData activeIcon, String label, int index) {
    final active = _currentTab == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _goTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
          decoration: BoxDecoration(
            color: active ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: active ? Border.all(color: Colors.white.withValues(alpha: 0.08)) : null,
          ),
          child: Row(
            children: [
              Icon(active ? activeIcon : icon, size: 19, color: active ? Colors.white : const Color(0xFF9DB4D5)),
              const SizedBox(width: 11),
              Expanded(child: Text(label, style: TextStyle(color: active ? Colors.white : const Color(0xFF9DB4D5), fontSize: 12.5, fontWeight: active ? FontWeight.w800 : FontWeight.w600))),
              if (active) Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppPalette.yellow, shape: BoxShape.circle)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Row(
            children: [
              Expanded(child: _navItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Accueil', 0, AppPalette.blue)),
              Expanded(child: _navItem(Icons.groups_outlined, Icons.groups_rounded, 'Classes', 1, AppPalette.blue)),
              Expanded(child: _navItem(Icons.menu_book_outlined, Icons.menu_book_rounded, 'Cours', 2, const Color(0xFFD97706))),
              Expanded(child: _navItem(Icons.how_to_reg_outlined, Icons.how_to_reg_rounded, 'Appel', 3, const Color(0xFF0EA5E9))),
              Expanded(child: _navItem(Icons.fact_check_outlined, Icons.fact_check_rounded, 'Notes', 4, const Color(0xFF10B981))),
              Expanded(child: _navItem(Icons.forum_outlined, Icons.forum_rounded, 'Messages', 5, const Color(0xFF0891B2))),
              Expanded(child: _navItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil', 6, const Color(0xFF42A5F5))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, IconData activeIcon, String label, int index, Color color) {
    final isActive = _currentTab == index;
    return GestureDetector(
      onTap: () => _goTo(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 34,
            decoration: BoxDecoration(color: isActive ? color.withValues(alpha: 0.13) : const Color(0xFFF4F5F7), borderRadius: BorderRadius.circular(10)),
            child: Icon(isActive ? activeIcon : icon, size: 20, color: isActive ? color : const Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(fontSize: 9, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? color : const Color(0xFF9CA3AF)),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── Header commun ──────────────────────────────────────────────────────────

class _ProfHeader extends StatelessWidget {
  const _ProfHeader({required this.title, required this.subtitle, this.trailing});
  final String title, subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A3D91), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(children: [
        Positioned(top: -30, right: -30,
          child: Container(width: 120, height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07)))),
        Positioned(bottom: -20, right: 60,
          child: Container(width: 70, height: 70,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppPalette.yellow.withValues(alpha: 0.12)))),
        SafeArea(bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75))),
              ])),
              if (trailing != null) trailing!,
            ]),
          )),
      ]),
    );
  }
}

// ── Onglet Classes ─────────────────────────────────────────────────────────

class _ClassesTab extends StatefulWidget {
  const _ClassesTab({required this.profile, required this.onFaireAppel, required this.onSaisirNotes});
  final StudentProfile profile;
  final ValueChanged<Map<String, dynamic>> onFaireAppel;
  final ValueChanged<Map<String, dynamic>> onSaisirNotes;

  @override
  State<_ClassesTab> createState() => _ClassesTabState();
}

class _ClassesTabState extends State<_ClassesTab> {
  static const Color _navyText = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _faint = Color(0xFF94A3B8);
  static const Color _border = Color(0xFFE5EBF3);

  static const List<String> _joursFr = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

  // Icône + couleur par classe, cycliques (façon maquette : chaque matière a
  // sa propre couleur d'icône).
  static const List<IconData> _icones = [
    Icons.device_hub_rounded, Icons.calculate_rounded, Icons.settings_rounded,
    Icons.storage_rounded, Icons.public_rounded, Icons.code_rounded, Icons.psychology_rounded,
  ];
  static const List<Color> _couleurs = [
    AppPalette.blue, Color(0xFFF5A623), Color(0xFF10B981),
    Color(0xFF7C3AED), Color(0xFF0891B2), Color(0xFFDB2777), Color(0xFF6366F1),
  ];

  List<dynamic> _classes = [];
  List<dynamic> _modules = [];
  bool _loading = true;
  String? _erreur;

  // Prochain cours par classe (clé = filiere_id-niveau), rempli après coup
  // une fois les modules connus (voir _chargerProchainsCoursDeTouteLesClasses).
  final Map<String, Map<String, dynamic>?> _prochainsCours = {};

  String _recherche = '';
  String _filiereFiltre = 'Toutes les filières';
  String _niveauFiltre = 'Tous les niveaux';
  String _tri = 'Nom (A-Z)';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _erreur = null;
    });
    final results = await Future.wait([
      ProfessorService.getClasses(),
      ProfessorService.getModules(),
    ]);
    if (!mounted) return;
    final classesRes = results[0];
    final modulesRes = results[1];
    setState(() {
      _classes = classesRes['success'] == true ? classesRes['data'] as List<dynamic> : [];
      _modules = modulesRes['success'] == true ? modulesRes['data'] as List<dynamic> : [];
      _erreur = classesRes['success'] == true ? null : (classesRes['error']?.toString() ?? 'Erreur lors du chargement.');
      _loading = false;
    });
    _chargerProchainsCoursDeTouteLesClasses();
  }

  // ── Modules réellement enseignés par CE prof pour une classe donnée —
  // c'est ce qui permet de savoir, dans l'EDT de la filière+niveau (qui
  // peut contenir des créneaux d'autres profs), lesquels lui appartiennent.
  List<dynamic> _modulesDeLaClasse(dynamic classe) {
    final filiereId = classe['id']?.toString();
    final niveau = classe['niveau']?.toString();
    return _modules.where((m) => m['filiere_id']?.toString() == filiereId && m['niveau']?.toString() == niveau).toList();
  }

  String _cleClasse(dynamic classe) => '${classe['id']}-${classe['niveau']}';

  Future<void> _chargerProchainsCoursDeTouteLesClasses() async {
    // ✅ CORRIGÉ — un setState() par classe dans la boucle (donc plusieurs
    // setState() rapprochés pendant qu'une souris réelle est sur la page)
    // déclenchait une assertion de mouse_tracker.dart sur Flutter Web,
    // rendant l'écran blanc en boucle. On regroupe tout en un seul
    // setState() une fois tous les appels terminés.
    final mises = <String, Map<String, dynamic>?>{};
    for (final classe in _classes) {
      final moduleNoms = _modulesDeLaClasse(classe).map((m) => m['nom']?.toString().trim().toLowerCase()).where((n) => n != null && n.isNotEmpty).toSet();
      if (moduleNoms.isEmpty) continue; // aucun module assigné ici : pas de créneau à lui attribuer
      mises[_cleClasse(classe)] = await _chargerProchainCours(classe['nom']?.toString() ?? '', classe['niveau']?.toString() ?? '', moduleNoms);
    }
    if (!mounted || mises.isEmpty) return;
    setState(() => _prochainsCours.addAll(mises));
  }

  // Cherche, dans l'EDT le plus récent de cette filière+niveau, le prochain
  // créneau dont la matière correspond à un module de CE prof — pas
  // n'importe quel créneau de la filière (qui peut appartenir à un collègue).
  Future<Map<String, dynamic>?> _chargerProchainCours(String filiere, String niveau, Set<String?> moduleNoms) async {
    try {
      final row = await Supabase.instance.client
          .from('edt')
          .select('creneaux')
          .ilike('filiere_nom', filiere)
          .ilike('niveau', niveau)
          .eq('archive', false)
          .order('createdAt', ascending: false)
          .limit(1)
          .maybeSingle();

      final raw = row?['creneaux'];
      if (raw is! List) return null;

      final creneaux = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) {
            final matiere = (e['matiere'] ?? e['cours'] ?? e['module'] ?? e['module_nom'] ?? e['titre'])?.toString().trim().toLowerCase();
            return matiere != null && moduleNoms.contains(matiere);
          })
          .toList();
      if (creneaux.isEmpty) return null;

      final aujourdhui = DateTime.now();
      final jourAujourdhui = _joursFr[aujourdhui.weekday - 1];
      final heureActuelle = TimeOfDay.now();
      int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
      TimeOfDay? parse(String? v) {
        final parts = (v ?? '').split(':');
        if (parts.length < 2) return null;
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h == null || m == null) return null;
        return TimeOfDay(hour: h, minute: m);
      }

      // Le prochain créneau : d'abord aujourd'hui s'il n'est pas terminé,
      // sinon le prochain jour de la semaine (en boucle) qui a un créneau.
      for (var offset = 0; offset < 7; offset++) {
        final jourCible = _joursFr[(aujourdhui.weekday - 1 + offset) % 7];
        final duJour = creneaux.where((c) => c['jour']?.toString().trim() == jourCible).toList()
          ..sort((a, b) => (a['heureDebut']?.toString() ?? '').compareTo(b['heureDebut']?.toString() ?? ''));
        for (final c in duJour) {
          if (offset == 0 && jourCible == jourAujourdhui) {
            final fin = parse(c['heureFin']?.toString());
            if (fin != null && toMinutes(fin) < toMinutes(heureActuelle)) continue; // déjà terminé aujourd'hui
          }
          return {
            ...c,
            '_jourLabel': offset == 0 ? 'Aujourd\'hui' : offset == 1 ? 'Demain' : jourCible,
          };
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _str(dynamic map, String key) {
    if (map is! Map) return '';
    final value = map[key];
    if (value == null) return '';
    return value.toString();
  }

  List<String> get _filieresDisponibles =>
      ['Toutes les filières', ..._classes.map((c) => _str(c, 'nom')).where((n) => n.isNotEmpty).toSet()];
  List<String> get _niveauxDisponibles =>
      ['Tous les niveaux', ..._classes.map((c) => _str(c, 'niveau')).where((n) => n.isNotEmpty).toSet()];

  List<dynamic> get _classesFiltrees {
    var list = _classes.where((c) {
      if (_filiereFiltre != 'Toutes les filières' && _str(c, 'nom') != _filiereFiltre) return false;
      if (_niveauFiltre != 'Tous les niveaux' && _str(c, 'niveau') != _niveauFiltre) return false;
      if (_recherche.trim().isNotEmpty) {
        final q = _recherche.trim().toLowerCase();
        if (!_str(c, 'nom').toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();
    if (_tri == 'Nom (A-Z)') {
      list.sort((a, b) => _str(a, 'nom').compareTo(_str(b, 'nom')));
    } else if (_tri == 'Étudiants (+)') {
      list.sort((a, b) => (int.tryParse('${b['nb_etudiants']}') ?? 0).compareTo(int.tryParse('${a['nb_etudiants']}') ?? 0));
    }
    return list;
  }

  int get _totalEtudiants => _classes.fold<int>(0, (sum, c) => sum + (int.tryParse('${c['nb_etudiants']}') ?? 0));
  int get _totalFilieres => _classes.map((c) => c['id']?.toString()).toSet().length;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F7FB),
      child: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _erreur != null
                ? _ErrorState(message: _erreur!, onRetry: _charger)
                : RefreshIndicator(
                    onRefresh: _charger,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1380),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTopRow(),
                              const SizedBox(height: 22),
                              const Text('Mes classes', style: TextStyle(color: _navyText, fontSize: 24, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              const Text('Gérez vos classes et suivez vos étudiants.', style: TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 20),
                              _buildStatsEtBanniere(),
                              const SizedBox(height: 20),
                              _buildFiltres(),
                              const SizedBox(height: 16),
                              if (_classesFiltrees.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 60),
                                  child: Center(child: Column(children: [
                                    Icon(Icons.groups_outlined, size: 56, color: Color(0xFFCBD5E1)),
                                    SizedBox(height: 12),
                                    Text('Aucune classe ne correspond à ta recherche.', style: TextStyle(color: _faint, fontSize: 13)),
                                  ])),
                                )
                              else
                                for (var i = 0; i < _classesFiltrees.length; i++) ...[
                                  _classeRow(_classesFiltrees[i], i),
                                  const SizedBox(height: 12),
                                ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildTopRow() {
    final photoUrl = widget.profile.photoUrl?.trim();
    final nomComplet = '${widget.profile.prenoms} ${widget.profile.nom}'.trim();
    return Row(children: [
      Expanded(
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
          child: Row(children: [
            const Icon(Icons.search_rounded, size: 19, color: _faint),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _recherche = v),
                decoration: const InputDecoration(
                  hintText: 'Rechercher une classe, une filière...',
                  hintStyle: TextStyle(color: _faint, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 16),
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _border)),
        child: const Icon(Icons.notifications_none_rounded, color: _navyText, size: 22),
      ),
      const SizedBox(width: 12),
      Row(children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: AppPalette.blue.withValues(alpha: 0.14),
          backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl == null || photoUrl.isEmpty
              ? Text(nomComplet.isNotEmpty ? nomComplet[0].toUpperCase() : 'P', style: const TextStyle(color: AppPalette.blue, fontWeight: FontWeight.w900))
              : null,
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nomComplet.isEmpty ? 'Professeur' : nomComplet, style: const TextStyle(color: _navyText, fontSize: 13.5, fontWeight: FontWeight.w800)),
          Text('Professeur${widget.profile.matricule.isNotEmpty ? " • ${widget.profile.matricule}" : ""}', style: const TextStyle(color: _faint, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ]),
    ]);
  }

  Widget _buildStatsEtBanniere() {
    return LayoutBuilder(builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 900;
      final stats = Wrap(
        spacing: 12, runSpacing: 12,
        children: [
          _statCard('${_classes.length}', 'Classes', 'au total', Icons.groups_rounded, AppPalette.blue),
          _statCard('$_totalEtudiants', 'Étudiants', 'au total', Icons.diversity_3_rounded, const Color(0xFFF5A623)),
          _statCard('${_modules.length}', 'Modules', 'enseignés', Icons.menu_book_rounded, const Color(0xFF10B981)),
          _statCard('$_totalFilieres', 'Filières', 'concernées', Icons.school_rounded, const Color(0xFF7C3AED)),
        ],
      );
      final banniere = _buildBanniere();
      if (!desktop) {
        return Column(children: [stats, const SizedBox(height: 12), banniere]);
      }
      // Alignement "start" au lieu de "stretch" : pas besoin d'IntrinsicHeight
      // (coûteux, surtout combiné à un Wrap) pour éviter le bug d'affichage
      // vide — les deux colonnes s'affichent simplement à leur propre hauteur.
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 7, child: stats),
        const SizedBox(width: 12),
        Expanded(flex: 3, child: banniere),
      ]);
    });
  }

  Widget _statCard(String value, String label, String sublabel, IconData icon, Color color) {
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 19)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: _navyText, fontSize: 11.5, fontWeight: FontWeight.w700)),
            Text(sublabel, style: const TextStyle(color: _faint, fontSize: 9.5, fontWeight: FontWeight.w500)),
          ])),
        ]),
      ),
    );
  }

  Widget _buildBanniere() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0B1E4D), Color(0xFF1E3A8A)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('« L\'éducation est l\'arme la plus puissante pour changer le monde. »',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, height: 1.4)),
        const SizedBox(height: 6),
        Text('— Nelson Mandela', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 10.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildFiltres() {
    return LayoutBuilder(builder: (context, constraints) {
      final wrap = constraints.maxWidth < 900;
      final children = [
        _dropdown(_filiereFiltre, _filieresDisponibles, (v) => setState(() => _filiereFiltre = v!), Icons.filter_alt_outlined),
        _dropdown(_niveauFiltre, _niveauxDisponibles, (v) => setState(() => _niveauFiltre = v!), Icons.school_outlined),
        _dropdown(_tri, const ['Nom (A-Z)', 'Étudiants (+)'], (v) => setState(() => _tri = v!), Icons.swap_vert_rounded, prefix: 'Trier par : '),
      ];
      if (wrap) return Wrap(spacing: 10, runSpacing: 10, children: children);
      return Row(children: [for (final c in children) ...[Expanded(child: c), const SizedBox(width: 10)]]);
    });
  }

  Widget _dropdown(String value, List<String> options, ValueChanged<String?> onChanged, IconData icon, {String prefix = ''}) {
    // ✅ CORRIGÉ — DropdownButton est un déclencheur connu de l'assertion
    // mouse_tracker.dart:199 sur Flutter Web (plusieurs sur un même écran
    // aggrave le problème). PopupMenuButton offre le même comportement
    // visuel sans ce bug.
    // ✅ Valeur retenue absente de la liste actuelle → repli sur la
    // première option plutôt que de transmettre une valeur orpheline.
    final safeValue = options.contains(value) ? value : (options.isNotEmpty ? options.first : value);
    return Container(
      height: 44,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: PopupMenuButton<String>(
        initialValue: safeValue,
        onSelected: onChanged,
        tooltip: '',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) => options
            .map((o) => PopupMenuItem<String>(
                  value: o,
                  child: Text('$prefix$o', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ))
            .toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: AppPalette.blue),
            const SizedBox(width: 6),
            Flexible(
              child: Text('$prefix$safeValue',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _navyText, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, color: _faint, size: 18),
          ]),
        ),
      ),
    );
  }

  Widget _classeRow(dynamic classe, int index) {
    final icone = _icones[index % _icones.length];
    final couleur = _couleurs[index % _couleurs.length];
    final nbModules = _modulesDeLaClasse(classe).length;
    final nbEtudiants = int.tryParse('${classe['nb_etudiants']}') ?? 0;
    final prochain = _prochainsCours[_cleClasse(classe)];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final icon = Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(14)),
          child: Icon(icone, color: Colors.white, size: 24),
        );
        final titre = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${classe['nom'] ?? ''}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _navyText)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppPalette.lightBlue, borderRadius: BorderRadius.circular(20)),
            child: Text('${classe['niveau'] ?? ''}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppPalette.blue)),
          ),
        ]);
        final compteurs = Row(mainAxisSize: MainAxisSize.min, children: [
          _compteur(Icons.groups_rounded, '$nbEtudiants', 'Étudiants'),
          const SizedBox(width: 22),
          _compteur(Icons.menu_book_rounded, '$nbModules', 'Modules'),
        ]);
        final prochainWidget = SizedBox(width: 190, child: _prochainCoursBloc(prochain));
        final bouton = SizedBox(
          height: 40,
          child: ElevatedButton(
            onPressed: () => _showClasseDetail(context, classe),
            style: ElevatedButton.styleFrom(backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16)),
            child: const Text('Voir les détails', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        );

        if (compact) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [icon, const SizedBox(width: 12), Expanded(child: titre)]),
            const SizedBox(height: 12),
            compteurs,
            const SizedBox(height: 10),
            _prochainCoursBloc(prochain),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: bouton),
          ]);
        }

        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          icon,
          const SizedBox(width: 14),
          Expanded(flex: 3, child: titre),
          compteurs,
          const SizedBox(width: 16),
          prochainWidget,
          const SizedBox(width: 12),
          bouton,
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
        ]);
      }),
    );
  }

  Widget _compteur(IconData icon, String value, String label) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: _faint),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: _navyText, fontSize: 13, fontWeight: FontWeight.w800)),
      ]),
      Text(label, style: const TextStyle(color: _faint, fontSize: 9.5, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _prochainCoursBloc(Map<String, dynamic>? prochain) {
    if (prochain == null) {
      return const Text('Aucun cours programmé', style: TextStyle(color: _faint, fontSize: 11, fontWeight: FontWeight.w600));
    }
    final matiere = (prochain['matiere'] ?? prochain['cours'] ?? prochain['module'] ?? prochain['titre'])?.toString() ?? '';
    final salle = prochain['salle']?.toString().trim() ?? '';
    final debut = prochain['heureDebut']?.toString() ?? '';
    final jourLabel = prochain['_jourLabel']?.toString() ?? '';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Prochain cours', style: TextStyle(color: _faint, fontSize: 10, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text('$jourLabel • $debut', style: const TextStyle(color: AppPalette.blue, fontSize: 11.5, fontWeight: FontWeight.w800)),
      if (matiere.isNotEmpty) Text(matiere, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _navyText, fontSize: 11, fontWeight: FontWeight.w600)),
      if (salle.isNotEmpty) Text(salle, style: const TextStyle(color: _faint, fontSize: 10)),
    ]);
  }

  void _showClasseDetail(BuildContext context, dynamic classe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClasseDetailSheet(
        classe: classe,
        onFaireAppel: widget.onFaireAppel,
        onSaisirNotes: widget.onSaisirNotes,
      ),
    );
  }
}

class _ClasseDetailSheet extends StatefulWidget {
  const _ClasseDetailSheet({required this.classe, required this.onFaireAppel, required this.onSaisirNotes});
  final dynamic classe;
  final ValueChanged<Map<String, dynamic>> onFaireAppel;
  final ValueChanged<Map<String, dynamic>> onSaisirNotes;

  @override
  State<_ClasseDetailSheet> createState() => _ClasseDetailSheetState();
}

class _ClasseDetailSheetState extends State<_ClasseDetailSheet> {
  List<dynamic> _etudiants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _chargerEtudiants();
  }

  Future<void> _chargerEtudiants() async {
    final res = await ProfessorService.getStudentsByFiliere(
      int.parse('${widget.classe['id']}'),
      niveau: widget.classe['niveau']?.toString(),
    );
    if (!mounted) return;
    setState(() {
      _etudiants = res['success'] == true ? res['data'] as List<dynamic> : [];
      _loading = false;
    });
  }

  void _lancerAction(ValueChanged<Map<String, dynamic>> action) {
    Navigator.pop(context);
    action(Map<String, dynamic>.from(widget.classe as Map));
  }

  void _ajouterModule() {
    final nomCtrl = TextEditingController();
    final coefCtrl = TextEditingController(text: '2');
    final vhCtrl = TextEditingController(text: '30');
    bool envoi = false;

    showDialog(context: context, builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Nouveau module — ${widget.classe['nom']}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nomCtrl,
            decoration: InputDecoration(
              labelText: 'Nom du module',
              prefixIcon: const Icon(Icons.menu_book_outlined, color: AppPalette.blue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(
              controller: coefCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Coefficient',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: TextField(
              controller: vhCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Volume (h)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )),
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: envoi ? null : () async {
              if (nomCtrl.text.trim().isEmpty) return;
              setDialogState(() => envoi = true);
              final messenger = ScaffoldMessenger.of(context);
              final res = await ApiService.createModule(
                nom: nomCtrl.text.trim(),
                coefficient: int.tryParse(coefCtrl.text) ?? 2,
                volumeHoraire: int.tryParse(vhCtrl.text) ?? 30,
                filiereId: int.tryParse('${widget.classe['id']}'),
                filiereNom: '${widget.classe['nom']}',
              );
              if (!dialogCtx.mounted) return;
              if (!mounted || !dialogCtx.mounted) return;
              if (res['success'] == true) {
                Navigator.pop(dialogCtx);
                messenger.showSnackBar(SnackBar(
                    content: Text('Module "${nomCtrl.text.trim()}" ajouté à ${widget.classe['nom']}.'),
                    backgroundColor: const Color(0xFF10B981)));
              } else {
                setDialogState(() => envoi = false);
                messenger.showSnackBar(SnackBar(
                    content: Text(res['error']?.toString() ?? 'Erreur lors de l\'ajout du module.'),
                    backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: envoi
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Ajouter'),
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${widget.classe['nom'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            Text(_loading ? 'Chargement des étudiants...' : '${_etudiants.length} étudiant(s) dans cette classe',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: ElevatedButton.icon(
                icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                label: const Text('Faire l\'appel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _lancerAction(widget.onFaireAppel),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(
                icon: const Icon(Icons.fact_check_rounded, size: 18),
                label: const Text('Saisir les notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _lancerAction(widget.onSaisirNotes),
              )),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.library_add_outlined, size: 18),
                label: const Text('Ajouter un module', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.blue,
                  side: const BorderSide(color: AppPalette.blue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _ajouterModule,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Liste des étudiants (PDF)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfesseurListeEtudiantsScreen(classe: Map<String, dynamic>.from(widget.classe as Map))),
                  );
                },
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        const Divider(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _etudiants.isEmpty
                  ? const Center(child: Text('Aucun étudiant trouvé', style: TextStyle(color: Color(0xFF94A3B8))))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _etudiants.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final e = _etudiants[i];
                        final prenoms = '${e['prenoms'] ?? ''}';
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: AppPalette.lightBlue,
                            child: Text(prenoms.isNotEmpty ? prenoms[0] : '?',
                                style: const TextStyle(color: AppPalette.blue, fontWeight: FontWeight.w700)),
                          ),
                          title: Text('$prenoms ${e['nom'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('${e['matricule'] ?? ''}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          trailing: IconButton(
                            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppPalette.blue, size: 20),
                            tooltip: 'Écrire en privé',
                            onPressed: () {
                              final userId = e['user_id']?.toString() ?? e['id']?.toString() ?? '';
                              if (userId.isEmpty) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DiscussionPriveePage(
                                    destinataireId: userId,
                                    destinataireNom: '$prenoms ${e['nom'] ?? ''}'.trim(),
                                    destinataireRole: 'Étudiant',
                                    destinataireSousTitre: e['matricule']?.toString(),
                                    themeColor: const Color(0xFF1E40AF),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
        ),
      ]),
    );
  }
}

// ── Onglet Cours ───────────────────────────────────────────────────────────

class _CoursTab extends StatefulWidget {
  const _CoursTab({required this.profile});
  final StudentProfile profile;

  @override
  State<_CoursTab> createState() => _CoursTabState();
}

class _CoursTabState extends State<_CoursTab> {
  static const Color _navyText = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _faint = Color(0xFF94A3B8);
  static const Color _border = Color(0xFFE5EBF3);
  static const Color _amber = Color(0xFFF5A623);

  static const List<IconData> _icones = [
    Icons.device_hub_rounded, Icons.calculate_rounded, Icons.settings_rounded,
    Icons.storage_rounded, Icons.public_rounded, Icons.code_rounded, Icons.psychology_rounded,
  ];
  static const List<Color> _couleurs = [
    AppPalette.blue, Color(0xFFF5A623), Color(0xFF10B981),
    Color(0xFF7C3AED), Color(0xFF0891B2), Color(0xFFDB2777), Color(0xFF6366F1),
  ];

  List<dynamic> _cours = [];
  List<dynamic> _classes = [];
  bool _loading = true;
  String? _erreur;
  String _recherche = '';
  String _filiereFiltre = 'Toutes les filières';
  String _moduleFiltre = 'Tous les modules';

  @override
  void initState() {
    super.initState();
    _chargerCours();
  }

  Future<void> _chargerCours() async {
    setState(() {
      _loading = true;
      _erreur = null;
    });
    final results = await Future.wait([ProfessorService.getCours(), ProfessorService.getClasses()]);
    if (!mounted) return;
    final coursRes = results[0];
    final classesRes = results[1];
    setState(() {
      _cours = coursRes['success'] == true ? coursRes['data'] as List<dynamic> : [];
      _classes = classesRes['success'] == true ? classesRes['data'] as List<dynamic> : [];
      _erreur = coursRes['success'] == true ? null : (coursRes['error']?.toString() ?? 'Erreur lors du chargement.');
      _loading = false;
    });
  }

  Future<void> _ajouterCours() async {
    final publie = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const UploadCourseScreen()),
    );
    if (publie == true) _chargerCours();
  }

  // Étudiants réellement concernés par ce cours — cross-référencé avec
  // getClasses() (nb_etudiants réel) via filière+niveau, comme pour le
  // "prochain cours" dans l'onglet Classes : aucune donnée inventée.
  int? _etudiantsPourCours(dynamic cours) {
    for (final c in _classes) {
      if (c['nom']?.toString() == cours['filiere_nom']?.toString() && c['niveau']?.toString() == cours['niveau']?.toString()) {
        return int.tryParse('${c['nb_etudiants']}');
      }
    }
    return null;
  }

  // ── Extraction de chaîne défensive : jamais de null qui remonte, jamais de
  // crash si l'élément n'est pas la Map attendue (source du plantage
  // précédent sur le filtre module).
  String _str(dynamic map, String key) {
    if (map is! Map) return '';
    final value = map[key];
    if (value == null) return '';
    return value.toString();
  }

  List<String> get _filieresDisponibles =>
      ['Toutes les filières', ..._cours.map((c) => _str(c, 'filiere_nom')).where((n) => n.isNotEmpty).toSet()];

  List<String> get _modulesDisponibles =>
      ['Tous les modules', ..._cours.map((c) => _str(c, 'module_nom')).where((n) => n.isNotEmpty).toSet()];

  List<dynamic> get _coursFiltres {
    return _cours.where((c) {
      if (_filiereFiltre != 'Toutes les filières' && _str(c, 'filiere_nom') != _filiereFiltre) return false;
      if (_moduleFiltre != 'Tous les modules' && _str(c, 'module_nom') != _moduleFiltre) return false;
      if (_recherche.trim().isNotEmpty) {
        final q = _recherche.trim().toLowerCase();
        final titre = _str(c, 'titre').toLowerCase();
        final module = _str(c, 'module_nom').toLowerCase();
        if (!titre.contains(q) && !module.contains(q)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => _str(b, 'date_creation').compareTo(_str(a, 'date_creation')));
  }

  int get _totalEtudiants {
    final vus = <String>{};
    var total = 0;
    for (final c in _cours) {
      final cle = '${c['filiere_nom']}-${c['niveau']}';
      if (vus.contains(cle)) continue;
      vus.add(cle);
      total += _etudiantsPourCours(c) ?? 0;
    }
    return total;
  }

  int get _totalFilieres => _cours.map((c) => c['filiere_id']?.toString()).toSet().length;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F7FB),
      child: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _erreur != null
                ? _ErrorState(message: _erreur!, onRetry: _chargerCours)
                : RefreshIndicator(
                    onRefresh: _chargerCours,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1380),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTopRow(),
                              const SizedBox(height: 22),
                              Row(children: [
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    const Text('Mes cours', style: TextStyle(color: _navyText, fontSize: 24, fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 4),
                                    const Text('Gérez et suivez tous vos supports de cours.', style: TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w500)),
                                  ]),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _ajouterCours,
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Nouveau cours', style: TextStyle(fontWeight: FontWeight.w700)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 20),
                              _buildStatsEtDerniers(),
                              const SizedBox(height: 20),
                              _buildFiltres(),
                              const SizedBox(height: 16),
                              if (_coursFiltres.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 50),
                                  child: Center(child: Column(children: [
                                    const Icon(Icons.menu_book_outlined, size: 56, color: Color(0xFFCBD5E1)),
                                    const SizedBox(height: 12),
                                    Text(_cours.isEmpty ? 'Aucun cours publié.' : 'Aucun cours ne correspond à ta recherche.',
                                        style: const TextStyle(color: _faint, fontSize: 13)),
                                    if (_cours.isEmpty) ...[
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.add_rounded, size: 18),
                                        label: const Text('Publier un cours'),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                        onPressed: _ajouterCours,
                                      ),
                                    ],
                                  ])),
                                )
                              else
                                for (var i = 0; i < _coursFiltres.length; i++) ...[
                                  _coursRow(_coursFiltres[i], i),
                                  const SizedBox(height: 12),
                                ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildTopRow() {
    final photoUrl = widget.profile.photoUrl?.trim();
    final nomComplet = '${widget.profile.prenoms} ${widget.profile.nom}'.trim();
    return Row(children: [
      Expanded(
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
          child: Row(children: [
            const Icon(Icons.search_rounded, size: 19, color: _faint),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _recherche = v),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un cours, un module...',
                  hintStyle: TextStyle(color: _faint, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 16),
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _border)),
        child: const Icon(Icons.notifications_none_rounded, color: _navyText, size: 22),
      ),
      const SizedBox(width: 12),
      Row(children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: AppPalette.blue.withValues(alpha: 0.14),
          backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl == null || photoUrl.isEmpty
              ? Text(nomComplet.isNotEmpty ? nomComplet[0].toUpperCase() : 'P', style: const TextStyle(color: AppPalette.blue, fontWeight: FontWeight.w900))
              : null,
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nomComplet.isEmpty ? 'Professeur' : nomComplet, style: const TextStyle(color: _navyText, fontSize: 13.5, fontWeight: FontWeight.w800)),
          Text('Professeur${widget.profile.matricule.isNotEmpty ? " • ${widget.profile.matricule}" : ""}', style: const TextStyle(color: _faint, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ]),
    ]);
  }

  Widget _buildStatsEtDerniers() {
    return LayoutBuilder(builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 900;
      final stats = Wrap(spacing: 12, runSpacing: 12, children: [
        _statCard('${_cours.length}', 'Cours', 'publiés', Icons.menu_book_rounded, AppPalette.blue),
        _statCard('$_totalEtudiants', 'Étudiants', 'concernés', Icons.diversity_3_rounded, _amber),
        _statCard('$_totalFilieres', 'Filières', 'concernées', Icons.school_rounded, const Color(0xFF7C3AED)),
      ]);
      final droite = Column(children: [
        _buildStatistiquesParFiliere(),
        const SizedBox(height: 12),
        _buildDerniersCours(),
      ]);
      if (!desktop) {
        return Column(children: [stats, const SizedBox(height: 12), droite]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 7, child: stats),
        const SizedBox(width: 12),
        Expanded(flex: 3, child: droite),
      ]);
    });
  }

  // ── Répartition réelle des cours par filière — pas de "Brouillon" (aucun
  // statut n'existe dans les données), juste ce qui est vraiment publié,
  // groupé par filière concernée.
  Widget _buildStatistiquesParFiliere() {
    final parFiliere = <String, int>{};
    for (final c in _cours) {
      final f = c['filiere_nom']?.toString() ?? 'Autre';
      parFiliere[f] = (parFiliere[f] ?? 0) + 1;
    }
    final entries = parFiliere.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = _cours.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.bar_chart_rounded, size: 17, color: AppPalette.blue),
          const SizedBox(width: 7),
          const Text('Statistiques des cours', style: TextStyle(color: _navyText, fontSize: 13.5, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 4),
        const Text('Répartition par filière', style: TextStyle(color: _faint, fontSize: 10.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          const Text('Rien à afficher.', style: TextStyle(color: _faint, fontSize: 11.5))
        else ...[
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(alignment: Alignment.center, children: [
                CustomPaint(
                  size: const Size(140, 140),
                  painter: _DonutChartPainter(
                    valeurs: [for (final e in entries) e.value],
                    couleurs: [for (var i = 0; i < entries.length; i++) _couleurs[i % _couleurs.length]],
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$total', style: const TextStyle(color: _navyText, fontSize: 26, fontWeight: FontWeight.w900)),
                  const Text('Total', style: TextStyle(color: _faint, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < entries.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == entries.length - 1 ? 0 : 9),
              child: Row(children: [
                Container(width: 9, height: 9, decoration: BoxDecoration(color: _couleurs[i % _couleurs.length], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(entries[i].key, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _navyText, fontSize: 11.5, fontWeight: FontWeight.w600))),
                Text('${entries[i].value}', style: const TextStyle(color: _navyText, fontSize: 12, fontWeight: FontWeight.w800)),
                if (total > 0) ...[
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 34,
                    child: Text('(${(entries[i].value / total * 100).round()}%)', textAlign: TextAlign.right,
                        style: const TextStyle(color: _faint, fontSize: 9.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
            ),
        ],
      ]),
    );
  }

  Widget _statCard(String value, String label, String sublabel, IconData icon, Color color) {
    return SizedBox(
      width: 190,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 19)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: _navyText, fontSize: 11.5, fontWeight: FontWeight.w700)),
            Text(sublabel, style: const TextStyle(color: _faint, fontSize: 9.5, fontWeight: FontWeight.w500)),
          ])),
        ]),
      ),
    );
  }

  Widget _buildDerniersCours() {
    final derniers = _coursFiltres.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Derniers cours publiés', style: TextStyle(color: _navyText, fontSize: 13.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        if (derniers.isEmpty)
          const Text('Rien à afficher.', style: TextStyle(color: _faint, fontSize: 11.5))
        else
          for (var i = 0; i < derniers.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == derniers.length - 1 ? 0 : 10),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: _couleurs[i % _couleurs.length], borderRadius: BorderRadius.circular(10)),
                  child: Icon(_icones[i % _icones.length], color: Colors.white, size: 16),
                ),
                const SizedBox(width: 9),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${derniers[i]['titre'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _navyText, fontSize: 11.5, fontWeight: FontWeight.w800)),
                  Text((derniers[i]['date_creation'] ?? '').toString().split('T').first,
                      style: const TextStyle(color: _faint, fontSize: 9.5, fontWeight: FontWeight.w600)),
                ])),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 16),
              ]),
            ),
      ]),
    );
  }

  Widget _buildFiltres() {
    return Wrap(spacing: 10, runSpacing: 10, children: [
      _dropdown(_filiereFiltre, _filieresDisponibles, (v) => setState(() => _filiereFiltre = v!), Icons.filter_alt_outlined),
      _dropdown(_moduleFiltre, _modulesDisponibles, (v) => setState(() => _moduleFiltre = v!), Icons.menu_book_outlined),
    ]);
  }

  Widget _dropdown(String value, List<String> options, ValueChanged<String?> onChanged, IconData icon) {
    // ✅ Si la valeur retenue n'existe plus dans la liste actuelle des
    // options (ex. liste de modules qui a changé après un rechargement),
    // on retombe sur la première option plutôt que de transmettre une
    // valeur orpheline à PopupMenuButton.
    final safeValue = options.contains(value) ? value : (options.isNotEmpty ? options.first : value);
    return SizedBox(
      width: 260,
      child: Container(
        height: 44,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
        child: PopupMenuButton<String>(
          initialValue: safeValue,
          onSelected: onChanged,
          tooltip: '',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (context) => options.map((o) => PopupMenuItem<String>(value: o, child: Text(o, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))).toList(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 15, color: AppPalette.blue),
              const SizedBox(width: 6),
              Flexible(child: Text(safeValue, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _navyText, fontSize: 12.5, fontWeight: FontWeight.w700))),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, color: _faint, size: 18),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _coursRow(dynamic cours, int index) {
    final date = (cours['date_creation'] ?? '').toString().split('T').first;
    final etudiants = _etudiantsPourCours(cours);
    final icone = _icones[index % _icones.length];
    final couleur = _couleurs[index % _couleurs.length];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final icon = Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(14)),
          child: Icon(icone, color: Colors.white, size: 24),
        );
        final titre = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${cours['titre'] ?? ''}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _navyText)),
          const SizedBox(height: 4),
          Text('${cours['module_nom'] ?? ''}', style: const TextStyle(fontSize: 11.5, color: _muted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppPalette.lightBlue, borderRadius: BorderRadius.circular(20)),
              child: Text('${cours['niveau'] ?? ''}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppPalette.blue)),
            ),
            const SizedBox(width: 8),
            Flexible(child: Text('${cours['filiere_nom'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: _faint, fontWeight: FontWeight.w500))),
          ]),
        ]);
        final meta = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_today_outlined, size: 12, color: _faint),
            const SizedBox(width: 4),
            Text(date, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
          if (etudiants != null) ...[
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.groups_rounded, size: 12, color: _faint),
              const SizedBox(width: 4),
              Text('$etudiants étudiants', style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ],
        ]);
        final actions = Row(mainAxisSize: MainAxisSize.min, children: [
          _CoursSupprimerButton(cours: cours, onDeleted: _chargerCours),
        ]);

        if (compact) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [icon, const SizedBox(width: 12), Expanded(child: titre)]),
            const SizedBox(height: 10),
            meta,
            const SizedBox(height: 10),
            actions,
          ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          icon,
          const SizedBox(width: 14),
          Expanded(flex: 3, child: titre),
          meta,
          const SizedBox(width: 14),
          actions,
        ]);
      }),
    );
  }
}

// ── Donut de répartition (façon maquette) — dessine un anneau segmenté
// proportionnellement aux valeurs fournies, une couleur par segment.
class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({required this.valeurs, required this.couleurs});
  final List<int> valeurs;
  final List<Color> couleurs;

  @override
  void paint(Canvas canvas, Size size) {
    final total = valeurs.fold<int>(0, (a, b) => a + b);
    if (total <= 0) return;
    final rect = Offset.zero & size;
    const largeurAnneau = 16.0;
    var angleDepart = -math.pi / 2;
    for (var i = 0; i < valeurs.length; i++) {
      final sweep = (valeurs[i] / total) * 2 * math.pi;
      final paint = Paint()
        ..color = couleurs[i % couleurs.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = largeurAnneau
        ..strokeCap = valeurs.length == 1 ? StrokeCap.butt : StrokeCap.butt;
      // Léger espace entre segments pour la lisibilité (sauf s'il n'y en a qu'un).
      final espace = valeurs.length > 1 ? 0.035 : 0.0;
      canvas.drawArc(
        rect.deflate(largeurAnneau / 2),
        angleDepart + espace / 2,
        (sweep - espace).clamp(0.0, 2 * math.pi),
        false,
        paint,
      );
      angleDepart += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.valeurs != valeurs || oldDelegate.couleurs != couleurs;
}

class _CoursSupprimerButton extends StatefulWidget {
  const _CoursSupprimerButton({required this.cours, required this.onDeleted});
  final dynamic cours;
  final VoidCallback onDeleted;

  @override
  State<_CoursSupprimerButton> createState() => _CoursSupprimerButtonState();
}

class _CoursSupprimerButtonState extends State<_CoursSupprimerButton> {
  bool _deleting = false;

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce cours ?'),
        content: Text('Le cours "${widget.cours['titre']}" sera définitivement supprimé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _deleting = true);
    final res = await ProfessorService.deleteCours(widget.cours['id'].toString());
    if (!mounted) return;
    if (res['success'] == true) {
      widget.onDeleted();
    } else {
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'] ?? 'Erreur'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _deleting
        ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2))
        : IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
            tooltip: 'Supprimer',
            onPressed: _delete,
          );
  }
}

// ── État d'erreur réutilisable ─────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, size: 54, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onRetry,
          ),
        ]),
      ),
    );
  }
}

// ── Onglet Profil ──────────────────────────────────────────────────────────

class _ProfilTab extends StatefulWidget {
  const _ProfilTab({required this.profile, required this.onLogout});
  final StudentProfile profile;
  final VoidCallback onLogout;

  @override
  State<_ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<_ProfilTab> {
  StudentProfile get profile => widget.profile;
  int _nbClasses = 0;
  int _nbCours = 0;
  int _nbSessions = 0;

  @override
  void initState() {
    super.initState();
    _chargerStats();
  }

  Future<void> _chargerStats() async {
    final classesRes = await ProfessorService.getClasses();
    final coursRes = await ProfessorService.getCours();
    final sessionsRes = await ProfessorService.getGradeSessions();
    if (!mounted) return;
    setState(() {
      _nbClasses = classesRes['success'] == true ? (classesRes['data'] as List).length : 0;
      _nbCours = coursRes['success'] == true ? (coursRes['data'] as List).length : 0;
      _nbSessions = sessionsRes['success'] == true ? (sessionsRes['data'] as List).length : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _ProfHeader(title: 'Mon Profil', subtitle: 'Espace personnel enseignant'),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
          // Cover + Avatar Premium
            ProfileHeaderCover(
              matricule: profile.matricule,
              nomComplet: '${profile.prenoms} ${profile.nom}',
              roleLabel: profile.filiere.isNotEmpty ? profile.filiere : 'Enseignant',
              initiales: '${profile.prenoms.isNotEmpty ? profile.prenoms[0] : ''}${profile.nom.isNotEmpty ? profile.nom[0] : ''.toUpperCase()}',
              badgeText: 'Professeur',
              accentColor: AppPalette.blue,
              bannerGradient: const [Color(0xFF0D1B4B), Color(0xFF1565C0), Color(0xFF42A5F5)],
              initialPhotoUrl: profile.photoUrl,
              initialCoverUrl: profile.coverUrl,
            ),
            const SizedBox(height: 24),
            // Infos
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
              ),
              child: Column(children: [
                _profilLigne(Icons.badge_outlined, 'Matricule', profile.matricule),
                const Divider(height: 1, indent: 56),
                _profilLigne(Icons.domain_rounded, 'Département', profile.filiere),
                const Divider(height: 1, indent: 56),
                _profilLigne(Icons.groups_rounded, 'Classes', '$_nbClasses classe(s)'),
                const Divider(height: 1, indent: 56),
                _profilLigne(Icons.menu_book_rounded, 'Cours publiés', '$_nbCours support(s)'),
              ]),
            ),
            const SizedBox(height: 24),
            // Stats
            Row(children: [
              _statCard('$_nbClasses', 'Classes', Icons.groups_rounded, AppPalette.blue),
              const SizedBox(width: 12),
              _statCard('$_nbCours', 'Cours', Icons.menu_book_rounded, const Color(0xFFD97706)),
              const SizedBox(width: 12),
              _statCard('$_nbSessions', 'Sessions notes', Icons.fact_check_rounded, const Color(0xFF10B981)),
            ]),
            const SizedBox(height: 24),
            // Programme hebdomadaire : déclarer et transmettre ses heures libres
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProgrammeScreen())),
                icon: const Icon(Icons.edit_calendar_rounded, size: 20),
                label: const Text('Mon programme / heures libres',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 52,
              child: OutlinedButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                label: const Text('Se déconnecter', style: TextStyle(color: Color(0xFFEF4444), fontSize: 15, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _profilLigne(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: AppPalette.lightBlue, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppPalette.blue, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        ])),
      ]),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ]),
      ),
    );
  }
}
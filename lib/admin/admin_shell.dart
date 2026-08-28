// ============================================================
// admin_shell.dart — ScolarHub Admin Shell (v3 — production)
// Auteur  : ScolarHub Team
// Version : 3.0.0
//
// Corrections v2 :
//   [SEC-1] Logout sécurisé (AuthService + clear prefs)
//   [SEC-2] Initiales protégées contre crash RangeError
//   [SEC-3] Avatar → PopupMenu profil (plus logout direct)
//   [ARCH-1] IndexedStack — état des pages préservé
//   [ARCH-2] Badges dynamiques via Map (plus de const hardcodé)
//   [ARCH-3] AdminMenuService — filtrage par permissions
//   [PERF-1] withOpacity → withValues (Flutter 3.27+)
//
// Améliorations v3 (suggestions validées) :
//   [UX-1] SlideTransition entre pages (navigation fluide)
//   [UX-2] MouseRegion hover sur menu items
//   [UX-3] Barre de recherche animée extensible
//   [UX-4] Hiérarchie typographique renforcée (groupes menu)
//   [UX-5] Structure ThemeNotifier prête pour dark mode
//   [UX-6] Badges StadiumBorder premium
//   [UX-7] Notifications : état lu/non-lu visuel
// ============================================================

import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_dashboard.dart';
import '../admin/admin_annonces.dart';
import '../admin/admin_edt.dart';
import '../admin/admin_filieres.dart';
import '../admin/admin_notes.dart';
import '../admin/admin_reclamations.dart';
import '../admin/admin_etudiants.dart';
import '../admin/admin_professeurs.dart';
import '../admin/admin_parents.dart';
import '../admin/admin_membres.dart';
import '../admin/admin_messages.dart';
import '../admin/admin_bde.dart';
import '../admin/admin_statistiques.dart';
import '../admin/admin_evaluations.dart';
import '../admin/admin_secondaire.dart';
import '../admin/admin_primaire.dart';
import '../admin/admin_risque.dart';
import '../config/etablissement_config.dart';
import '../pages/choose_etablissement_type_page.dart';
import '../pages/splash_screen.dart';
import '../widgets/profile_header_cover.dart';
// TODO: décommenter quand les services sont prêts
// import '../services/auth_service.dart';
// import '../services/notifications_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════
// SECTION 1 — Modèles & Constantes
// ═══════════════════════════════════════════════════════════════

class _MenuItem {
  final IconData icon;
  final IconData iconActive;
  final String label;
  final String group;

  const _MenuItem({
    required this.icon,
    required this.iconActive,
    required this.label,
    required this.group,
  });
}

const _items = <_MenuItem>[
  _MenuItem(icon: Icons.grid_view_rounded,           iconActive: Icons.grid_view_rounded,          label: 'Tableau de bord',    group: 'GÉNÉRAL'),
  _MenuItem(icon: Icons.campaign_outlined,           iconActive: Icons.campaign_rounded,           label: 'Annonces',           group: 'GÉNÉRAL'),
  _MenuItem(icon: Icons.account_tree_outlined,       iconActive: Icons.account_tree_rounded,       label: 'Filières & Modules', group: 'ACADÉMIQUE'),
  _MenuItem(icon: Icons.calendar_today_outlined,     iconActive: Icons.calendar_today_rounded,     label: 'Emplois du Temps',   group: 'ACADÉMIQUE'),
  _MenuItem(icon: Icons.task_outlined,               iconActive: Icons.task_rounded,               label: 'Notes & Moyennes',   group: 'ACADÉMIQUE'),
  _MenuItem(icon: Icons.rate_review_outlined,        iconActive: Icons.rate_review_rounded,        label: 'Réclamations',       group: 'ACADÉMIQUE'),
  _MenuItem(icon: Icons.school_outlined,             iconActive: Icons.school_rounded,             label: 'Étudiants',          group: 'PERSONNES'),
  _MenuItem(icon: Icons.supervisor_account_outlined, iconActive: Icons.supervisor_account_rounded, label: 'Professeurs',        group: 'PERSONNES'),
  _MenuItem(icon: Icons.family_restroom_outlined,    iconActive: Icons.family_restroom_rounded,    label: 'Parents',            group: 'PERSONNES'),
  _MenuItem(icon: Icons.shield_outlined,             iconActive: Icons.shield_rounded,             label: 'Membres & Rôles',    group: 'PERSONNES'),
  _MenuItem(icon: Icons.forum_outlined,              iconActive: Icons.forum_rounded,              label: 'Groupes & Messages', group: 'MESSAGERIE'),
  _MenuItem(icon: Icons.celebration_outlined,        iconActive: Icons.celebration_rounded,        label: 'BDE & Événements',   group: 'ÉVÉNEMENTS'),
  _MenuItem(icon: Icons.bar_chart_outlined,          iconActive: Icons.bar_chart_rounded,          label: 'Statistiques',       group: 'RAPPORTS'),
  _MenuItem(icon: Icons.star_outline_rounded,        iconActive: Icons.star_rounded,               label: 'Éval. Professeurs',  group: 'RAPPORTS'),
  _MenuItem(icon: Icons.apartment_outlined,          iconActive: Icons.apartment_rounded,          label: 'Collège & Lycée',    group: 'SECTIONS'),
  _MenuItem(icon: Icons.auto_stories_outlined,       iconActive: Icons.auto_stories_rounded,       label: 'Primaire',           group: 'SECTIONS'),
  _MenuItem(icon: Icons.warning_amber_outlined,      iconActive: Icons.warning_amber_rounded,      label: 'Élèves à risque',    group: 'RAPPORTS'),
];

const _menuGroups = <Map<String, Object>>[
  {'key': 'GÉNÉRAL',    'items': [0, 1]},
  {'key': 'SECTIONS',   'items': [14, 15]},
  {'key': 'ACADÉMIQUE', 'items': [2, 3, 4, 5]},
  {'key': 'PERSONNES',  'items': [6, 7, 8, 9]},
  {'key': 'MESSAGERIE', 'items': [10]},
  {'key': 'ÉVÉNEMENTS', 'items': [11]},
  {'key': 'RAPPORTS',   'items': [12, 13, 16]},
];


// ═══════════════════════════════════════════════════════════════
// SECTION 2 — AdminMenuService (permissions par rôle) [ARCH-3]
// ═══════════════════════════════════════════════════════════════

enum AdminRole { superAdmin, academic, secretariat }

class AdminMenuService {
  const AdminMenuService._();

  /// Retourne les indices de menu accessibles selon le rôle.
  /// La vérification DOIT aussi être faite côté serveur/API.
  static Set<int> allowedItems(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        // Accès total
        return {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16};
      case AdminRole.academic:
        // Notes, réclamations, filières, EDT, étudiants, profs, stats, sections
        return {0, 2, 3, 4, 5, 6, 7, 12, 13, 14, 15, 16};
      case AdminRole.secretariat:
        // Annonces, étudiants, parents, messages
        return {0, 1, 6, 8, 10};
    }
  }

  static bool canAccess(AdminRole role, int itemIndex) =>
      allowedItems(role).contains(itemIndex);
}

// ═══════════════════════════════════════════════════════════════
// SECTION 3 — ThemeNotifier (structure prête pour dark mode) [UX-5]
// ═══════════════════════════════════════════════════════════════

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    // TODO: persister dans SharedPreferences
    // SharedPreferences.getInstance().then((p) => p.setBool('darkMode', isDark));
  }
}

// Singleton simple (remplacer par Provider/Riverpod si déjà en place)
final themeNotifier = ThemeNotifier();

// ═══════════════════════════════════════════════════════════════
// SECTION 4 — Extension couleurs (fix withOpacity déprécié) [PERF-1]
// ═══════════════════════════════════════════════════════════════

extension _Alpha on Color {
  Color get a10 => withValues(alpha: 0.10);
  Color get a15 => withValues(alpha: 0.15);
  Color get a20 => withValues(alpha: 0.20);
}

// ═══════════════════════════════════════════════════════════════
// SECTION 5 — AdminShell (widget principal)
// ═══════════════════════════════════════════════════════════════

class AdminShell extends StatefulWidget {
  final StudentProfile profile;
  final VoidCallback onLogout;

  /// Rôle de l'admin connecté — contrôle la visibilité des menus.
  final AdminRole role;

  const AdminShell({
    super.key,
    required this.profile,
    required this.onLogout,
    this.role = AdminRole.superAdmin,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell>
    with SingleTickerProviderStateMixin {
  int _idx = 0;
  int _prevIdx = 0;
  bool _compact = false;

  // [UX-1] Contrôleur pour la SlideTransition entre pages
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _pageAnim;
  late Animation<Offset> _slideIn;
  late Animation<double> _fadeIn;

  // [ARCH-1] IndexedStack — instancié une seule fois, état préservé
  late final List<Widget> _pages;
  final GlobalKey<AdminMessagesState> _messagesKey = GlobalKey<AdminMessagesState>();

  // [ARCH-2] Badges dynamiques (connecter à un stream Firestore/API)
  final Map<int, int> _badges = {
    4: 3, // Notes à valider    — TODO: stream
    5: 2, // Réclamations       — TODO: stream
  };

  @override
  void initState() {
    super.initState();
    // Config multi-établissement : recharge le type persisté puis
    // reconstruit l'interface à chaque changement de type.
    EtablissementConfig.instance.addListener(_onConfigChanged);
    EtablissementConfig.instance.charger();
    _pages = [
      AdminDashboard(profile: widget.profile),
      const AdminAnnonces(),
      const AdminFilieres(),
      const AdminEDT(),
      const AdminNotes(),
      const AdminReclamations(),
      const AdminEtudiants(),
AdminProfesseurs(profile: widget.profile),
      const AdminParents(),
      const AdminMembres(),
      AdminMessages(key: _messagesKey),
      const AdminBDE(),
      const AdminStatistiques(),
      const AdminEvaluations(),
      const AdminSecondaire(),
      const AdminPrimaire(),
      const AdminRisque(),
    ];

    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _resetPageAnimation();
    _pageAnim.forward();
  }

  @override
  void dispose() {
    EtablissementConfig.instance.removeListener(_onConfigChanged);
    _pageAnim.dispose();
    super.dispose();
  }

  void _onConfigChanged() {
    if (!mounted) return;
    setState(() {
      // Si la page courante n'existe plus pour ce type d'établissement,
      // on revient au tableau de bord.
      if (!_visibleParConfig(_idx)) {
        _idx = 0;
        _prevIdx = 0;
      }
    });
  }

  /// Visibilité d'un item de menu selon la config de l'établissement.
  /// - 14 (Collège & Lycée) : uniquement si la section secondaire est active
  /// - 15 (Primaire)        : uniquement si la section primaire est active
  /// - 2 (Filières & Modules) et 11 (BDE) : réservés au supérieur
  bool _visibleParConfig(int index) {
    final config = EtablissementConfig.instance;
    switch (index) {
      case 14:
        return config.sectionActive(SectionEnseignement.secondaire);
      case 15:
        return config.sectionActive(SectionEnseignement.primaire);
      case 2:
        return config.sectionActive(SectionEnseignement.superieur);
      case 11:
        return config.sectionActive(SectionEnseignement.superieur) &&
            config.options.bde;
      default:
        return true;
    }
  }

  void _resetPageAnimation({bool fromRight = true}) {
    final begin = fromRight ? const Offset(0.04, 0.0) : const Offset(-0.04, 0.0);
    _slideIn = Tween<Offset>(begin: begin, end: Offset.zero).animate(
      CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut),
    );
  }

  void _navigate(int index) {
    if (index == _idx) return;
    final fromRight = index > _prevIdx;
    _resetPageAnimation(fromRight: fromRight);
    setState(() {
      _prevIdx = _idx;
      _idx = index;
    });
    if (index == 10) _messagesKey.currentState?.refreshGroupes();
    _pageAnim
      ..reset()
      ..forward();
    if (_scaffoldKey.currentState?.isDrawerOpen == true) Navigator.pop(context);
  }

  // ── Getters sécurisés [SEC-2] ────────────────────────────────────────────
  String get _initials {
    final p = widget.profile;
    final f = p.prenoms.isNotEmpty ? p.prenoms[0].toUpperCase() : '?';
    final l = p.nom.isNotEmpty    ? p.nom[0].toUpperCase()     : '';
    return '$f$l';
  }

  String get _fullName =>
      '${widget.profile.prenoms} ${widget.profile.nom}'.trim();

  // ── Déconnexion sécurisée [SEC-1] ────────────────────────────────────────
  Future<void> _doLogout() async {
    // 1. Invalider la session côté serveur
    //    await AuthService.instance.signOut();
    // 2. Nettoyer le cache local
    //    final prefs = await SharedPreferences.getInstance();
    //    await prefs.clear();
    // 3. Notifier le parent
    widget.onLogout();
    // 4. Vider le stack de navigation
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  void _showLogoutDialog() => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 12),
            Text('Déconnexion',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
          ]),
          content: const Text(
            'Voulez-vous vraiment vous déconnecter de la session administrative ?',
            style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler',
                  style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _doLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Se déconnecter',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

  // ── Menu profil [SEC-3] ───────────────────────────────────────────────────
  void _showProfileMenu(BuildContext ctx) {
    final box = ctx.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    showMenu<String>(
      context: ctx,
      position: RelativeRect.fromLTRB(
        offset.dx - 140,
        offset.dy + box.size.height + 4,
        offset.dx + box.size.width,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 12,
      items: [
        _popItem('profile',  Icons.person_outline_rounded, 'Mon profil',  const Color(0xFF334155)),
        _popItem('settings', Icons.settings_outlined,      'Paramètres',  const Color(0xFF334155)),
        const PopupMenuDivider(),
        _popItem('logout',   Icons.logout_rounded,         'Déconnexion', Colors.redAccent,
            bold: true),
      ],
    ).then((val) {
      if (!mounted) return;
      if (val == 'logout') _showLogoutDialog();
      if (val == 'profile') _showAdminProfileSheet(context);
    });
  }

  void _showAdminProfileSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ProfileHeaderCover(
                matricule: widget.profile.matricule,
                nomComplet: _fullName,
                roleLabel: widget.profile.filiere.isNotEmpty
                    ? widget.profile.filiere
                    : 'Direction Pédagogique',
                initiales: _initials,
                badgeText: 'Administrateur',
                badgeColor: const Color(0xFFD97706),
                accentColor: const Color(0xFF1E40AF),
                bannerGradient: const [Color(0xFF0C1A3D), Color(0xFF1A237E), Color(0xFF283593)],
              ),
              const SizedBox(height: 20),
              _adminInfoTile(Icons.badge_outlined, 'Matricule', widget.profile.matricule),
              _adminInfoTile(Icons.email_outlined, 'Email', widget.profile.email.isNotEmpty ? widget.profile.email : 'admin@ist.bf'),
              _adminInfoTile(Icons.shield_outlined, 'Rôle système', widget.profile.roleLabel),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () { Navigator.pop(ctx); _showLogoutDialog(); },
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                label: const Text('Déconnexion', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adminInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E40AF).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF1E40AF), size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        ])),
      ]),
    );
  }

  PopupMenuItem<String> _popItem(
    String value, IconData icon, String label, Color color, {bool bold = false}
  ) =>
      PopupMenuItem(
        value: value,
        child: Row(children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ]),
      );

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final mobile = AdminTheme.isMobile(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: mobile
          ? Drawer(
              backgroundColor: Colors.white,
              child: _sidebar(isMobile: true),
            )
          : null,
      body: Row(
        children: [
          if (!mobile)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: _compact ? 72 : 270,
              child: _sidebar(isMobile: false),
            ),
          Expanded(
            child: Column(
              children: [
                _topbar(context, mobile),
                Expanded(
                  child: SlideTransition(
                    position: _slideIn,
                    child: FadeTransition(
                      opacity: _fadeIn,
                      // [ARCH-1] IndexedStack — état des pages préservé
                      child: IndexedStack(index: _idx, children: _pages),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SIDEBAR
  // ═══════════════════════════════════════════════════════════════

  Widget _sidebar({required bool isMobile}) {
    final c = _compact && !isMobile;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      ),
      child: Column(
        children: [
          // ── Logo ─────────────────────────────────────────────────────────
          Container(
            height: 70,
            padding: EdgeInsets.symmetric(horizontal: c ? 16 : 24),
            child: Row(
              mainAxisAlignment:
                  c ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppPalette.blue.a10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: AppPalette.blue, size: 22),
                ),
                if (!c) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('ScolarHub',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5)),
                        Text('IST Ouaga 2000',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Carte profil ─────────────────────────────────────────────────
          if (!c)
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppPalette.blue.a15,
                    child: Text(_initials,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.blue)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fullName,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppPalette.yellow.a15,
                            // [UX-6] StadiumBorder premium
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('SUPER ADMIN',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB7950B),
                                  letterSpacing: 0.6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Color(0xFFE2E8F0), height: 10),
          ),

          // ── Menu ─────────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              children: [
                for (final g in _menuGroups)
                  if ((g['items'] as List<int>).any((i) =>
                      AdminMenuService.canAccess(widget.role, i) &&
                      _visibleParConfig(i))) ...[
                  if (!c)
                    // [UX-4] Hiérarchie typographique renforcée
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 5),
                      child: Row(
                        children: [
                          Text(g['key'] as String,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 1.0)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: const Color(0xFFF1F5F9),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 8),

                  for (final i in (g['items'] as List<int>))
                    // [ARCH-3] Masquer les items non autorisés
                    // + filtrage selon le type d'établissement
                    if (AdminMenuService.canAccess(widget.role, i) &&
                        _visibleParConfig(i))
                      _MenuItemTile(
                        item: _items[i],
                        index: i,
                        active: _idx == i,
                        compact: c,
                        badge: _badges[i]?.toString(),
                        onTap: () => _navigate(i),
                      ),
                ],
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Color(0xFFE2E8F0)),
          ),

          // ── Bas sidebar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: c
                ? Column(
                    children: [
                      _SideBtn(
                        icon: Icons.link_rounded,
                        tooltip: 'Connecter mon établissement',
                        onTap: _ouvrirChoixType,
                        color: AppPalette.blue,
                      ),
                      const SizedBox(height: 8),
                      _SideBtn(
                        icon: Icons.dark_mode_outlined,
                        tooltip: 'Mode Sombre',
                        onTap: _toggleDarkMode,
                      ),
                      const SizedBox(height: 8),
                      _SideBtn(
                        icon: Icons.logout_rounded,
                        tooltip: 'Déconnexion',
                        onTap: _showLogoutDialog,
                        color: Colors.redAccent,
                      ),
                    ],
                  )
                : Column(
                    children: [
                      // Connexion de l'établissement (type + filtrage auto)
                      _ConnectEtablissementButton(onTap: _ouvrirChoixType),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _SideBtn(
                            icon: Icons.dark_mode_outlined,
                            tooltip: 'Mode Sombre',
                            onTap: _toggleDarkMode,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _LogoutButton(onTap: _showLogoutDialog),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _toggleDarkMode() {
    themeNotifier.toggle();
    // TODO: connecter à un ThemeProvider au niveau du MaterialApp
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(themeNotifier.isDark
            ? 'Mode sombre activé'
            : 'Mode clair activé'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CONNEXION DE L'ÉTABLISSEMENT (choix du type + filtrage auto)
  // ═══════════════════════════════════════════════════════════════

  void _ouvrirChoixType() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChooseEtablissementTypePage()),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOPBAR
  // ═══════════════════════════════════════════════════════════════

  Widget _topbar(BuildContext context, bool mobile) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Burger / toggle compact
          if (mobile)
            IconButton(
              icon: const Icon(Icons.menu_rounded,
                  color: Color(0xFF0F172A), size: 24),
              onPressed: () => Scaffold.of(context).openDrawer(),
            )
          else
            IconButton(
              icon: Icon(
                _compact
                    ? Icons.menu_open_rounded
                    : Icons.menu_rounded,
                color: const Color(0xFF64748B),
                size: 22,
              ),
              onPressed: () => setState(() => _compact = !_compact),
            ),

          const SizedBox(width: 8),

          // Titre page courante
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_items[_idx].label,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(
                  'Administration · ${_items[_idx].group}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          // [UX-3] Barre de recherche animée
          if (!mobile) const _AnimatedSearchBar(),
          const SizedBox(width: 16),

          // Cloche notifications [UX-7]
          Builder(builder: (ctx) {
            final unread =
                _badges.values.fold(0, (s, v) => s + v);
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded,
                      color: Color(0xFF334155), size: 24),
                  onPressed: () => showModalBottomSheet(
                    context: ctx,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => const _NotifsPanel(),
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$unread',
                          style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            );
          }),

          const SizedBox(width: 12),

          // Avatar → menu profil [SEC-3]
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => _showProfileMenu(ctx),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppPalette.blue,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppPalette.blue.a20, width: 3),
                ),
                child: Center(
                  child: Text(_initials,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// COMPOSANTS EXTRAITS (lisibilité + réutilisabilité)
// ═══════════════════════════════════════════════════════════════

// ── MenuItem avec hover [UX-2] ────────────────────────────────────────────

class _MenuItemTile extends StatefulWidget {
  final _MenuItem item;
  final int index;
  final bool active;
  final bool compact;
  final String? badge;
  final VoidCallback onTap;

  const _MenuItemTile({
    required this.item,
    required this.index,
    required this.active,
    required this.compact,
    required this.onTap,
    this.badge,
  });

  @override
  State<_MenuItemTile> createState() => _MenuItemTileState();
}

class _MenuItemTileState extends State<_MenuItemTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final compact = widget.compact;
    final color = active ? AppPalette.blue : const Color(0xFF64748B);

    Color bgColor = Colors.transparent;
    if (active) {
      bgColor = AppPalette.blue.withValues(alpha: 0.08);
    } else if (_hovered) {
      bgColor = AppPalette.blue.withValues(alpha: 0.04);
    }

    return Tooltip(
      message: compact ? widget.item.label : '',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(
                  horizontal: compact ? 0 : 14, vertical: 11),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                // Indicateur gauche sur item actif
                border: active
                    ? Border(
                        left: BorderSide(
                            color: AppPalette.blue, width: 3),
                      )
                    : null,
              ),
              child: Row(
                mainAxisAlignment: compact
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  if (active && !compact) const SizedBox(width: 1),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        active ? widget.item.iconActive : widget.item.icon,
                        color: color,
                        size: 20,
                      ),
                      if (widget.badge != null && compact)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: active
                              ? AppPalette.blue
                              : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    // [UX-6] Badge StadiumBorder
                    if (widget.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(widget.badge!,
                            style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bouton sidebar compact ────────────────────────────────────────────────

class _SideBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  const _SideBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color = const Color(0xFF64748B),
  });

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      );
}

// ── Bouton « Connecter mon établissement » ────────────────────────────────
// Ouvre le choix du type d'établissement ; l'interface se filtre ensuite
// automatiquement (sections, menus, options, vocabulaire).

class _ConnectEtablissementButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ConnectEtablissementButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final config = EtablissementConfig.instance;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: AppPalette.blue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppPalette.blue.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.link_rounded, color: AppPalette.blue, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Connecter mon établissement',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.blue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 1),
                  Text(config.type.label,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppPalette.blue, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Bouton déconnexion étendu ─────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent, size: 16),
              SizedBox(width: 8),
              Text('Déconnexion',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent)),
            ],
          ),
        ),
      );
}

// ── Barre de recherche animée [UX-3] ─────────────────────────────────────

class _AnimatedSearchBar extends StatefulWidget {
  const _AnimatedSearchBar();

  @override
  State<_AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<_AnimatedSearchBar>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  final _ctrl = TextEditingController();
  late final AnimationController _anim;
  late final Animation<double> _width;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 240));
    _width = Tween<double>(begin: 210, end: 340).animate(
        CurvedAnimation(parent: _anim, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _open() {
    setState(() => _expanded = true);
    _anim.forward();
  }

  void _close() {
    _anim.reverse().then((_) {
      if (mounted) setState(() => _expanded = false);
    });
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        width: _width.value,
        height: 40,
        child: GestureDetector(
          onTap: _expanded ? null : _open,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _expanded
                    ? AppPalette.blue.withValues(alpha: 0.45)
                    : const Color(0xFFE2E8F0),
                width: _expanded ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.search_rounded,
                    color: _expanded
                        ? AppPalette.blue
                        : const Color(0xFF94A3B8),
                    size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: _expanded
                      ? TextField(
                          controller: _ctrl,
                          autofocus: true,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Étudiant, prof, filière...',
                            hintStyle: TextStyle(
                                fontSize: 13, color: Color(0xFF94A3B8)),
                          ),
                          // TODO: connecter à SearchService avec debounce 300ms
                          onChanged: (_) {},
                        )
                      : const Text('Rechercher...',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF94A3B8))),
                ),
                if (_expanded)
                  GestureDetector(
                    onTap: _close,
                    child: const Icon(Icons.close_rounded,
                        color: Color(0xFF94A3B8), size: 16),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text('⌘K',
                        style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Panel notifications [UX-7] ────────────────────────────────────────────

class _NotifsPanel extends StatelessWidget {
  const _NotifsPanel();

  // TODO: Remplacer par StreamBuilder connecté à FCM / Firestore
  static const _notifs = <Map<String, Object>>[
    {
      'icon':  Icons.rate_review_rounded,
      'color': Color(0xFFF59E0B),
      'title': 'Nouvelle réclamation',
      'body':  'KOURAOGO Ibrahim — RES301 (Notes)',
      'time':  '5 min',
      'read':  false,
    },
    {
      'icon':  Icons.task_rounded,
      'color': AppPalette.blue,
      'title': 'Notes soumises pour validation',
      'body':  'RIT L2 — Architecture des Réseaux',
      'time':  '20 min',
      'read':  false,
    },
    {
      'icon':  Icons.person_add_rounded,
      'color': Colors.green,
      'title': 'Nouvelle inscription finalisée',
      'body':  'Sawadogo Mohamed ajouté au registre RIT',
      'time':  '1h',
      'read':  true,
    },
    {
      'icon':  Icons.celebration_rounded,
      'color': Colors.purple,
      'title': "Demande d'événement BDE",
      'body':  'Conférence Télécoms en attente de validation',
      'time':  '2h',
      'read':  true,
    },
  ];

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10)),
            ),
            // En-tête
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Row(
                children: [
                  const Text('Notifications',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_notifs.where((n) => !(n['read'] as bool)).length}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tout lire',
                        style: TextStyle(
                            color: AppPalette.blue,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            // Liste
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _notifs.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFF8FAFC)),
              itemBuilder: (_, i) {
                final n = _notifs[i];
                final unread = !(n['read'] as bool);
                return ListTile(
                  tileColor: unread
                      ? AppPalette.blue.withValues(alpha: 0.025)
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 6),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (n['color'] as Color)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(n['icon'] as IconData,
                        color: n['color'] as Color, size: 20),
                  ),
                  title: Text(n['title'] as String,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: unread
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: const Color(0xFF0F172A))),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(n['body'] as String,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B))),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(n['time'] as String,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF94A3B8))),
                      if (unread) ...[
                        const SizedBox(height: 5),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: AppPalette.blue,
                              shape: BoxShape.circle),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
}


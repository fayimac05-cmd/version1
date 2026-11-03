import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import 'home_tab.dart';
import 'profile_tab.dart';
import 'canal_screen.dart';
import 'chat_ia_screen.dart';
import 'app_drawer.dart';
import '../services/annuel_service.dart';
import 'reinscription_page.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({
    super.key,
    required this.profile,
    required this.onLogout,
  });

  final StudentProfile profile;
  final VoidCallback onLogout;

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _currentTab = 0;
  int _canauxUnread = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Copie mutable du profil, tenue à jour après un changement de photo/
  // couverture (voir _onPhotoChanged) — propage la nouvelle photo à TOUTE
  // l'app (accueil, canaux, drawer...), pas seulement à l'écran Profil.
  late StudentProfile _profile = widget.profile;

  // Rempli quand l'étudiant doit se réinscrire (ou est diplômé) : l'app est alors remplacée
  // par l'écran de réinscription, avec accès aux archives en lecture seule.
  Map<String, dynamic>? _blocage;

  @override
  void initState() {
    super.initState();
    _rafraichirPhotos();
    _verifierReinscription();
  }

  Future<void> _verifierReinscription() async {
    final r = await AnnuelService.monStatut();
    if (!mounted || r['success'] != true) return; // hors-ligne ou erreur : on ne bloque jamais
    final d = Map<String, dynamic>.from((r['data'] as Map?) ?? {});
    final parcours = '${d['parcours']}';
    final bloque = parcours == 'diplome' || parcours == 'abandon' || d['a_jour'] == false;
    setState(() => _blocage = bloque ? d : null);
  }

  /// Relit la photo et la couverture depuis le serveur (GET /auth/me) et les
  /// propage à toute l'app. Indispensable quand le profil gardé en mémoire
  /// (connexion, session restaurée) n'a pas les photos : sans ça, l'étudiant
  /// ne voit pas ses propres photos alors que les autres les voient.
  Future<void> _rafraichirPhotos() async {
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.get(Uri.parse('${ApiService.baseUrl}/auth/me'), headers: headers);
      if (res.statusCode != 200 || !mounted) return;
      final d = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final photo = (d['photo_url'] ?? '').toString();
      final cover = (d['cover_url'] ?? '').toString();
      final photoNew = photo.isEmpty ? null : photo;
      final coverNew = cover.isEmpty ? null : cover;
      if (photoNew == _profile.photoUrl && coverNew == _profile.coverUrl) return;
      _onPhotoChanged(photoNew, coverNew);
    } catch (e) {
      debugPrint('[StudentShell] photos /auth/me: $e'); // hors-ligne : on garde l'existant
    }
  }

  void _onPhotoChanged(String? photoUrl, String? coverUrl) {
    setState(() {
      _profile = _profile.copyWith(photoUrl: photoUrl, coverUrl: coverUrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_blocage != null) {
      return ReinscriptionPage(
        statut: _blocage!,
        onLogout: widget.onLogout,
        onActualiser: _verifierReinscription,
      );
    }
    final pages = [
      HomeTab(
        profile: _profile,
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      CanalScreen(
        profile: _profile,
        onUnreadChanged: (count) {
          if (_canauxUnread != count) setState(() => _canauxUnread = count);
        },
      ),
      ChatIAScreen(profile: _profile, showBack: false),
      ProfileTab(
        profile: _profile,
        onLogout: widget.onLogout,
        onPhotoChanged: _onPhotoChanged,
        onBack: () => setState(() => _currentTab = 0), // retour à l'accueil
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      // Menu latéral : regroupe Planning, Chat IA, Révisions IA, Tickets
      drawer: AppDrawer(profile: _profile),
      // ✅ CORRIGÉ — IndexedStack au lieu d'AnimatedSwitcher+KeyedSubtree :
      // l'ancienne version détruisait et recréait entièrement l'écran de
      // l'onglet à chaque changement (clé différente à chaque fois), ce qui
      // effaçait l'état local de ProfileHeaderCover (photo/couverture tout
      // juste changées) dès qu'on quittait l'onglet Profil puis y revenait —
      // elles redémarraient alors depuis widget.profile.photoUrl, jamais mis
      // à jour. IndexedStack garde tous les onglets vivants en mémoire, donc
      // cet état survit — même comportement que ParentShell, où ça
      // fonctionnait déjà.
      body: IndexedStack(
        index: _currentTab,
        children: pages,
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _navItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Accueil',
                index: 0,
                activeColor: AppPalette.blue,
              ),
              _navItem(
                icon: Icons.forum_outlined,
                activeIcon: Icons.forum_rounded,
                label: 'Canaux',
                index: 1,
                activeColor: AppPalette.yellow,
                showDot: _canauxUnread > 0,
              ),
              _navItem(
                icon: Icons.smart_toy_outlined,
                activeIcon: Icons.smart_toy_rounded,
                label: 'Chat IA',
                index: 2,
                activeColor: AppPalette.blue,
              ),
              _navItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
                index: 3,
                activeColor: const Color(0xFF42A5F5),
                photoUrl: _profile.photoUrl, // la photo de l'étudiant remplace l'icône
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required Color activeColor,
    int? badge,
    bool showDot = false,
    String? photoUrl,
  }) {
    final isActive = _currentTab == index;
    final bgColor = isActive
        ? activeColor.withValues(alpha: 0.13)
        : const Color(0xFFF4F5F7);

    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 36,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: (photoUrl != null && photoUrl.isNotEmpty)
                        ? Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isActive ? activeColor : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  isActive ? activeIcon : icon,
                                  size: 22,
                                  color: isActive ? activeColor : const Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                          )
                        : Icon(
                            isActive ? activeIcon : icon,
                            size: 22,
                            color: isActive ? activeColor : const Color(0xFF9CA3AF),
                          ),
                  ),
                ),
                if (showDot)
                  Positioned(
                    top: 1,
                    right: 1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  )
                else if (badge != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppPalette.yellow,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text('$badge',
                            style: const TextStyle(
                                color: Color(0xFF3A2A00),
                                fontSize: 8,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : const Color(0xFF9CA3AF),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
 
import 'package:intl/intl.dart';
import '../models/student_profile.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../theme/app_palette.dart';
import 'event_registration_page.dart';
import 'notifications_page.dart';
import 'bulletin_screen.dart';
import 'courses_tab.dart';
import 'groupe_filiere_screen.dart';
import 'checkin_screen.dart';
import 'planning_tab.dart';
import 'cantine_sheet.dart';
import 'mes_notes_page.dart';
 
class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.profile, this.onMenuTap});
 
  final StudentProfile profile;
  final VoidCallback? onMenuTap;
 
  @override
  State<HomeTab> createState() => _HomeTabState();
}
 
class _HomeTabState extends State<HomeTab> {
  final PageController _eventsCtrl = PageController(viewportFraction: 0.88);
  final PageController _annoncesCtrl = PageController(viewportFraction: 0.88);
  int _eventPage = 0;
  int _annoncePage = 0;
  Timer? _autoScroll;
  Timer? _annoncesAutoScroll;
  Timer? _notifsPoll;
 
  List<Map<String, dynamic>> _annonces = [];
  bool _annoncesLoading = true;
  List<EventModel> _evenements = [];

  // ── Cloche de notifications (badge rouge avec compteur) ──────────────────
  int _notifsNonLues = 0;
  // ── Badge non-lu de "Ma filière" ──────────────────────────────────────
  int _nonLusMaFiliere = 0;
 
  bool _apercuLoading = true;
  double? _moyenne;
  double? _tauxPresence;
  List<Map<String, dynamic>> _coursDuJour = [];
 
  // ── Notes publiées / historique ─────────────────────────────────────────
  List<Map<String, dynamic>> _notesPubliees = [];
  Set<String> _notesLues = <String>{};
  bool _notesLoading = true;
 
  int get _notesNonLues => _notesPubliees
      .where((note) => !_notesLues.contains(_noteKey(note)))
      .length;
 
  static const _joursFr = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];
 
  int get _carouselLength => _evenements.length;
 
  @override
  void initState() {
    super.initState();
    _fetchAnnonces();
    _fetchEvenements();
    _fetchApercuEtProchainCours();
    _fetchNotesNonLues();
    _fetchNotifsNonLues();
    _fetchNonLusMaFiliere();
    // Temps réel : une nouvelle notification incrémente le badge immédiatement.
    SocketService().onNotification(_onNouvelleNotification);
    // Filet de sécurité indépendant du socket : re-synchronise le compteur
    // toutes les 30s, même si la connexion temps réel a un souci ponctuel.
    _notifsPoll = Timer.periodic(const Duration(seconds: 30), (_) => _fetchNotifsNonLues());
 
    _autoScroll = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _carouselLength <= 1) return;
      final next = (_eventPage + 1) % _carouselLength;
      _eventsCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });

    _annoncesAutoScroll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _annonces.length <= 1) return;
      final next = (_annoncePage + 1) % _annonces.length;
      if (_annoncesCtrl.hasClients) {
        _annoncesCtrl.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }
 
  @override
  void dispose() {
    _eventsCtrl.dispose();
    _annoncesCtrl.dispose();
    _autoScroll?.cancel();
    _annoncesAutoScroll?.cancel();
    _notifsPoll?.cancel();
    // ⚠️ Passer le callback précis, pas juste le nom de l'événement — sinon
    // ça retire aussi l'écouteur de NotificationsPage (et inversement) si
    // les deux sont actifs en même temps. Voir socket_service.dart::off.
    SocketService().off('notification', _onNouvelleNotification);
    super.dispose();
  }

  Future<void> _fetchNotifsNonLues() async {
    final n = await ApiService.getNombreNotificationsNonLues();
    if (mounted) setState(() => _notifsNonLues = n);
  }

  Future<void> _fetchNonLusMaFiliere() async {
    try {
      final headers = await ApiService.getHeaders();
      final me = await http.get(Uri.parse('${ApiService.baseUrl}/auth/me'), headers: headers);
      if (me.statusCode != 200) return;
      final filiereId = jsonDecode(me.body)['filiere_id'];
      if (filiereId == null) return;
      final n = await ApiService.getNombreNonLusGroupe(filiereId.toString());
      if (mounted) setState(() => _nonLusMaFiliere = n);
    } catch (_) {
      // Silencieux — juste un badge, pas d'écran d'erreur pour ça.
    }
  }

  void _onNouvelleNotification(dynamic data) {
    if (!mounted) return;
    setState(() => _notifsNonLues += 1);
  }

  Future<void> _ouvrirNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NotificationsPage(profile: widget.profile)),
    );
    // Au retour, resynchronise le badge (certaines ont pu être marquées lues).
    if (mounted) _fetchNotifsNonLues();
  }
 
  Future<void> _fetchAnnonces() async {
    try {
      final result = await ApiService.getAnnonces(statut: 'publiee');
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _annonces = List<Map<String, dynamic>>.from(result['data'] as List);
          _annoncesLoading = false;
        });
      } else {
        setState(() => _annoncesLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _annoncesLoading = false);
    }
  }
 
  Future<void> _fetchEvenements() async {
    final result = await ApiService.getEvenements(statut: 'approuve');
    if (!mounted || result['success'] != true) return;
 
    final events = (result['data'] as List<dynamic>)
        .map((j) => EventModel.fromJson(j as Map<String, dynamic>))
        .toList();
 
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
 
    setState(() {
      _evenements = events.where((e) => !e.date.isBefore(today)).toList();
      if (_eventPage >= _carouselLength) _eventPage = 0;
    });
  }
 
  String _noteKey(Map<String, dynamic> note) {
    final id = note['id'] ?? note['note_id'] ?? note['evaluation_id'];
    return id.toString();
  }
 
  // ✅ CORRIGÉ — l'ancienne version interrogeait directement
  // `vue_notes_etudiants` SANS aucun filtre par étudiant
  // (client.from('vue_notes_etudiants').select()), ce qui remontait les
  // notes de TOUS les étudiants du système, pas seulement les siennes
  // (bug découvert le 07/09 : badge "11 notes" pour un seul devoir créé).
  // Remplacé par ApiService.getMesNotes(), déjà scopé par le JWT côté
  // backend et déjà utilisé par le reste de cet écran (voir
  // _fetchApercuEtProchainCours ci-dessous) et par lib/pages/notes_tab.dart.
  Future<void> _fetchNotesNonLues() async {
    try {
      final result = await ApiService.getMesNotes();
      if (result['success'] != true) {
        if (mounted) setState(() => _notesLoading = false);
        return;
      }
      final notes = List<Map<String, dynamic>>.from(result['data'] as List);
 
      Set<String> lues = <String>{};
      try {
        final lectureRows = await Supabase.instance.client
            .from('notes_lectures')
            .select('note_key')
            .eq('etudiant_matricule', widget.profile.matricule.trim());
 
        lues = (lectureRows as List)
            .map((e) => (e as Map)['note_key']?.toString())
            .whereType<String>()
            .toSet();
      } catch (_) {
        // Table de suivi "lu" absente ou injoignable : les notes restent
        // visibles, simplement toutes marquées non lues.
      }
 
      if (!mounted) return;
      setState(() {
        _notesPubliees = notes;
        _notesLues = lues;
        _notesLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _notesLoading = false);
    }
  }
 
  Future<void> _marquerNotesCommeLues(
    List<Map<String, dynamic>> notes,
  ) async {
    if (notes.isEmpty) return;
 
    final matricule = widget.profile.matricule.trim();
    if (matricule.isEmpty) return;
 
    final now = DateTime.now().toIso8601String();
 
    final rows = notes.map((note) {
      return {
        'etudiant_matricule': matricule,
        'note_key': _noteKey(note),
        'lu_at': now,
      };
    }).toList();
 
    // Mise à jour locale immédiate : le badge disparaît sans attendre le
    // réseau. L'upsert assure ensuite la conservation dans l'historique.
    setState(() {
      _notesLues = {
        ..._notesLues,
        ...notes.map(_noteKey),
      };
    });
 
    try {
      await Supabase.instance.client
          .from('notes_lectures')
          .upsert(
            rows,
            onConflict: 'etudiant_matricule,note_key',
          );
    } catch (_) {
      // La table peut être absente pendant la mise en place du projet.
      // Le fonctionnement visuel reste disponible.
    }
  }
 
  Future<void> _ouvrirNotes(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MesNotesPage(profile: widget.profile),
      ),
    );

    if (mounted) {
      await _fetchNotesNonLues();
    }
  }
 
  Future<void> _fetchApercuEtProchainCours() async {
    try {
      final client = Supabase.instance.client;
      final jourAuj = _joursFr[DateTime.now().weekday - 1];
 
      // ✅ CORRIGÉ — la moyenne/présence passaient par un lookup Supabase
      // direct sur `etudiants` (RLS activé sans politique, bloqué en
      // silence pour la clé publique — découvert le 03/09). Remplacé par
      // ApiService.getMonApercu(), qui passe par le backend (scopé par le
      // JWT). `edt` reste en accès direct : table catalogue/planning, une
      // politique de lecture publique a été ajoutée dessus.
      final results = await Future.wait<dynamic>([
        ApiService.getMonApercu(),
        client
            .from('edt')
            .select('creneaux')
            .ilike('filiere_nom', widget.profile.filiere.trim())
            .ilike('niveau', widget.profile.niveau.trim())
            .eq('archive', false)
            .order('createdAt', ascending: false)
            .limit(1)
            .maybeSingle(),
      ]);
 
      final apercuResult = results[0] as Map<String, dynamic>;
      final edtActif = results[1] as Map<String, dynamic>?;
 
      final tousLesCreneaux = edtActif != null
          ? (edtActif['creneaux'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList()
          : <Map<String, dynamic>>[];
 
      final coursJour =
          tousLesCreneaux.where((c) => c['jour'] == jourAuj).toList()
            ..sort(
              (a, b) => (a['heureDebut']?.toString() ?? '')
                  .compareTo(b['heureDebut']?.toString() ?? ''),
            );
 
      double? moyenne;
      double? tauxPresence;
      if (apercuResult['success'] == true) {
        final data = apercuResult['data'] as Map<String, dynamic>?;
        moyenne = data?['moyenne'] != null
            ? double.tryParse(data!['moyenne'].toString())
            : null;
        tauxPresence = data?['tauxPresence'] != null
            ? double.tryParse(data!['tauxPresence'].toString())
            : null;
      }
 
      if (!mounted) return;
      setState(() {
        _moyenne = moyenne;
        _tauxPresence = tauxPresence;
        _coursDuJour = coursJour;
        _apercuLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _apercuLoading = false);
    }
  }
 
  Map<String, dynamic>? get _prochainCours {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
 
    for (final c in _coursDuJour) {
      final fin = _parseHeure(c['heureFin'] as String?);
      if (fin == null) continue;
 
      if (fin.hour * 60 + fin.minute > nowMinutes) {
        return c;
      }
    }
 
    return null;
  }
 
  TimeOfDay? _parseHeure(String? raw) {
    if (raw == null || raw.isEmpty) return null;
 
    final parts = raw.split(':');
    if (parts.length < 2) return null;
 
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
 
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }
 
  String _formatHeure(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}h${t.minute.toString().padLeft(2, '0')}';
 
  String get _salutation {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }
 
  static const _events = [
    _EventData(
      '🎓',
      '25 Jan',
      'Journée portes ouvertes',
      'Venez découvrir notre établissement et rencontrer les enseignants.',
      'Amphi A · 9h00',
    ),
    _EventData(
      '🤖',
      '30 Jan',
      'Conférence IA',
      "L'avenir de l'intelligence artificielle dans l'éducation.",
      'Salle 101 · 14h00',
    ),
    _EventData(
      '💻',
      '5 Fév',
      'Tournoi de code',
      'Compétition inter-filières de programmation.',
      'Labo Info · 10h00',
    ),
    _EventData(
      '🏆',
      '12 Fév',
      'Remise des diplômes',
      'Cérémonie de remise des diplômes.',
      'Grand Amphi · 15h00',
    ),
  ];
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: RefreshIndicator(
        color: AppPalette.blue,
        onRefresh: () async {
          await Future.wait([
            _fetchAnnonces(),
            _fetchEvenements(),
            _fetchApercuEtProchainCours(),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 105),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildProchainCours(context),
                  const SizedBox(height: 20),
                  _buildApercuDuJour(),
                  const SizedBox(height: 20),
                  _buildAccesRapides(context),
                  const SizedBox(height: 22),
                  _buildEventsCarousel(),
                  const SizedBox(height: 22),
                  _buildCantineEtFiliereRow(context),
                  const SizedBox(height: 22),
                  _buildActualitesCarousel(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
 
Widget _buildHeader(BuildContext context) {
    final initiales =
        '${widget.profile.prenoms.isNotEmpty ? widget.profile.prenoms[0] : ''}'
        '${widget.profile.nom.isNotEmpty ? widget.profile.nom[0] : ''}'
            .toUpperCase();
 
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: widget.onMenuTap,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppPalette.lightBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.menu_rounded,
                    color: AppPalette.blue, size: 24),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 58, height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.lightBlue,
                border: Border.all(
                  color: AppPalette.blue.withValues(alpha: 0.22),
                  width: 2.5,
                ),
                image: widget.profile.photoUrl != null &&
                        widget.profile.photoUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(widget.profile.photoUrl!),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: widget.profile.photoUrl == null ||
                      widget.profile.photoUrl!.isEmpty
                  ? Center(
                      child: Text(initiales,
                          style: const TextStyle(
                            color: AppPalette.blue,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          )))
                  : null,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_salutation,',
                      style: const TextStyle(
                          fontSize: 12, color: AppPalette.grey)),
                  const SizedBox(height: 1),
                  Text('${widget.profile.prenoms} ${widget.profile.nom}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172033),
                      )),
                  if (widget.profile.filiere.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(widget.profile.filiere,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.blue,
                        )),
                  ],
                  if (widget.profile.niveau.isNotEmpty)
                    Text(widget.profile.niveau,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppPalette.grey,
                        )),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _ouvrirNotifications,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppPalette.lightGrey,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Center(
                      child: Icon(Icons.notifications_none_rounded,
                          color: Color(0xFF334155), size: 25),
                    ),
                    if (_notifsNonLues > 0)
                      Positioned(
                        top: -2, right: -2,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          height: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _notifsNonLues > 99 ? '99+' : '$_notifsNonLues',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
 
Widget _buildProchainCours(BuildContext context) {
    if (_apercuLoading) return _loadingCard(height: 205);
 
    final cours = _prochainCours;
 
    if (cours == null) {
      return Container(
        height: 164,
        padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
        decoration: BoxDecoration(
          gradient: AppPalette.blueGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppPalette.blue.withValues(alpha: 0.18),
              blurRadius: 18, offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_rounded,
                  color: Colors.white, size: 29),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PROCHAIN COURS',
                      style: TextStyle(
                        color: AppPalette.yellow,
                        fontSize: 11, fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      )),
                  SizedBox(height: 8),
                  Text("Aucun cours restant aujourd'hui",
                      maxLines: 2,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.w800,
                      )),
                  SizedBox(height: 5),
                  Text('Profite de ton temps libre ✨',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            _courseDecoration(),
          ],
        ),
      );
    }
 
    final debut = _parseHeure(cours['heureDebut'] as String?);
    final fin = _parseHeure(cours['heureFin'] as String?);
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final debutMinutes = debut == null ? 0 : debut.hour * 60 + debut.minute;
    final finMinutes = fin == null ? 0 : fin.hour * 60 + fin.minute;
 
    final badge = nowMinutes < debutMinutes
        ? 'Dans ${debutMinutes - nowMinutes} min'
        : nowMinutes <= finMinutes ? 'En cours' : '';
 
    final matiere = cours['matiere']?.toString().trim().isNotEmpty == true
        ? cours['matiere'].toString() : 'Cours';
    final salle = cours['salle']?.toString() ?? '';
    final horaire = debut != null && fin != null
        ? '${_formatHeure(debut)} - ${_formatHeure(fin)}' : '';
 
    return Container(
      height: 218,
      padding: const EdgeInsets.fromLTRB(22, 19, 15, 17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0A43B5), Color(0xFF2469ED)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppPalette.blue.withValues(alpha: 0.22),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -55, right: -40,
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -34, right: 10,
            child: Container(
              width: 92, height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.17),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('PROCHAIN COURS',
                              style: TextStyle(
                                color: AppPalette.yellow,
                                fontSize: 11, fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              )),
                        ),
                        if (badge.isNotEmpty)
                          Text(badge,
                              style: const TextStyle(
                                color: AppPalette.yellow,
                                fontSize: 10, fontWeight: FontWeight.w800,
                              )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(matiere,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white, fontSize: 19,
                          fontWeight: FontWeight.w800,
                        )),
                    const SizedBox(height: 11),
                    if (horaire.isNotEmpty)
                      _whiteInfo(Icons.access_time_rounded, horaire),
                    if (salle.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      _whiteInfo(Icons.location_on_outlined, salle),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 2, bottom: 2,
            child: Row(
              children: [
                _courseDecoration(),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CoursesTab()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Voir le planning',
                            style: TextStyle(
                              color: AppPalette.blue,
                              fontSize: 11, fontWeight: FontWeight.w800,
                            )),
                        SizedBox(width: 7),
                        Icon(Icons.arrow_forward_rounded,
                            color: AppPalette.blue, size: 16),
                      ],
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
 
  Widget _courseDecoration() {
    return SizedBox(
      width: 88, height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 80, height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const Icon(Icons.calendar_month_rounded,
              color: Colors.white, size: 43),
          const Positioned(
            right: 10, bottom: 8,
            child: Icon(Icons.access_time_filled_rounded,
                color: AppPalette.yellow, size: 20),
          ),
        ],
      ),
    );
  }
 
  Widget _buildApercuDuJour() {
    final cours = _apercuLoading ? '--' : '${_coursDuJour.length}';
    final presence = _apercuLoading || _tauxPresence == null
        ? '--'
        : '${_tauxPresence!.round()}%';
    final moyenne = _apercuLoading || _moyenne == null
        ? '--'
        : _moyenne!.toStringAsFixed(1).replaceAll('.', ',');
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Aperçu du jour', 'Aujourd’hui'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _apercuCard(
                Icons.menu_book_rounded,
                cours,
                'Cours',
                AppPalette.blue,
                AppPalette.lightBlue,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _apercuCard(
                Icons.check_circle_rounded,
                presence,
                'Présence',
                const Color(0xFF16A34A),
                const Color(0xFFE9F8EE),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _apercuCard(
                Icons.star_rounded,
                moyenne,
                'Moyenne',
                const Color(0xFFF59E0B),
                const Color(0xFFFFF4DF),
              ),
            ),
          ],
        ),
      ],
    );
  }
 
  Widget _apercuCard(
    IconData icon,
    String value,
    String label,
    Color color,
    Color background,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 5),
      decoration: _cardDecoration(radius: 16),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppPalette.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildAccesRapides(BuildContext context) {
    final items = [
      _QuickAction(
        Icons.bar_chart_rounded,
        'Résultats',
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BulletinScreen()),
        ),
      ),
      _QuickAction(
        Icons.qr_code_scanner_rounded,
        'Présence',
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CheckinScreen()),
        ),
      ),
      _QuickAction(
        Icons.menu_book_rounded,
        'Cours',
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CoursesTab()),
        ),
      ),
      _QuickAction(
        Icons.description_outlined,
        'Bulletins',
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BulletinScreen()),
        ),
      ),
      _QuickAction(
        Icons.calendar_month_rounded,
        'Planning',
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlanningTab(profile: widget.profile),
          ),
        ),
      ),
      _QuickAction(
        Icons.grade_rounded,
        'Notes',
        () => _ouvrirNotes(context),
        badge: _notesNonLues,
      ),
    ];
 
    // Grille pleine largeur (3 colonnes par ligne, comme "Aperçu du jour")
    // au lieu d'un Wrap centré à taille fixe.
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 3) {
      final rowItems = items.skip(i).take(3).toList();
      final rowChildren = <Widget>[];
      for (var j = 0; j < 3; j++) {
        if (j > 0) rowChildren.add(const SizedBox(width: 9));
        if (j < rowItems.length) {
          rowChildren.add(
            Expanded(
              child: _accesRapideCard(
                rowItems[j].icon,
                rowItems[j].label,
                rowItems[j].onTap,
                badge: rowItems[j].badge,
              ),
            ),
          );
        } else {
          rowChildren.add(const Expanded(child: SizedBox.shrink()));
        }
      }
      rows.add(Row(children: rowChildren));
      if (i + 3 < items.length) rows.add(const SizedBox(height: 9));
    }
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Accès rapides', 'Personnaliser'),
        const SizedBox(height: 12),
        ...rows,
      ],
    );
  }
 
  Widget _accesRapideCard(
    IconData icon,
    String label,
    VoidCallback onTap, {
    int badge = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 92,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            decoration: _cardDecoration(radius: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppPalette.lightBlue,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    color: AppPalette.blue,
                    size: 19,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172033),
                  ),
                ),
              ],
            ),
          ),
          if (badge > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 24),
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF5F7FB), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
 
Widget _buildCantineEtFiliereRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _squareActionCard(
            gradientColors: const [Color(0xFF7C22E8), Color(0xFFC026D3)],
            icon: Icons.restaurant_menu_rounded,
            title: 'Menu cantine',
            subtitle: 'Menu du jour',
            badge: 'Ouvert',
            badgeColor: const Color(0xFF2E8B3C),
            watermarkIcon: Icons.lunch_dining_rounded,
            imageAsset: 'assets/images/cantine_food.png',
            onTap: () => _showCantineSheet(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _squareActionCard(
            gradientColors: const [Color(0xFF1261D1), Color(0xFF0A3D91)],
            icon: Icons.groups_rounded,
            title: 'Ma filière',
            subtitle: widget.profile.filiere.isNotEmpty
                ? widget.profile.filiere : 'Canal de la filière',
            watermarkIcon: Icons.groups_rounded,
            imageAsset: 'assets/images/students_group.png',
            unreadCount: _nonLusMaFiliere,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupeFiliere(profile: widget.profile),
                ),
              );
              // Au retour, l'écran a marqué la lecture côté serveur —
              // resynchronise le badge (doit repasser à 0).
              if (mounted) _fetchNonLusMaFiliere();
            },
          ),
        ),
      ],
    );
  }
 
  Widget _squareActionCard({
    required List<Color> gradientColors,
    required IconData icon,
    required String title,
    required String subtitle,
    required IconData watermarkIcon,
    required VoidCallback onTap,
    String? imageAsset,
    String? badge,
    Color? badgeColor,
    int? unreadCount,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 184,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withValues(alpha: 0.22),
              blurRadius: 16, offset: const Offset(0, 7),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (imageAsset != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (bounds) =>
                          const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            stops: [0.0, 0.22, 0.46, 0.75, 1.0],
                            colors: [
                              Colors.transparent,
                              Color(0x45FFFFFF),
                              Color(0xB5FFFFFF),
                              Color(0xE8FFFFFF),
                              Colors.white,
                            ],
                          ).createShader(bounds),
                      child: Image.asset(
                        imageAsset,
                        width: 245,
                        height: 184,
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                        errorBuilder: (_, __, ___) => Icon(
                          watermarkIcon,
                          size: 90,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.center,
                      colors: [
                        gradientColors.first.withValues(alpha: 0.20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -26, right: -25,
              child: Container(
                width: 82, height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            if (unreadCount != null && unreadCount > 0)
              Positioned(
                top: 10, right: 10,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 37, height: 37,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.17),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(icon, color: Colors.white, size: 19),
                      ),
                      const Spacer(),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: badgeColor ?? Colors.green,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(badge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9, fontWeight: FontWeight.w800,
                              )),
                        ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 150,
                    child: Text(title,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w800,
                        )),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    width: 155,
                    child: Text(subtitle,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5, fontWeight: FontWeight.w500,
                          height: 1.25,
                        )),
                  ),
                  const Spacer(),
                  Container(
                    width: 35, height: 35,
                    decoration: const BoxDecoration(
                      color: AppPalette.yellow, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Color(0xFF3A2A00), size: 17),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
 
Widget _buildEventsCarousel() {
    if (_carouselLength == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Événements à venir', 'Voir tout'),
          const SizedBox(height: 10),
          Container(
            height: 112,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppPalette.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppPalette.borderGrey),
            ),
            child: const Center(
              child: Text(
                'Aucun événement prévu pour le moment.',
                style: TextStyle(color: AppPalette.grey, fontSize: 13),
              ),
            ),
          ),
        ],
      );
    }
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Événements à venir', 'Voir tout'),
        const SizedBox(height: 10),
        SizedBox(
          height: 112,
          child: PageView.builder(
            controller: _eventsCtrl,
            itemCount: _carouselLength,
            onPageChanged: (i) => setState(() => _eventPage = i),
            itemBuilder: (_, i) {
              return _eventCard(
                _toEventData(_evenements[i]),
                model: _evenements[i],
              );
            },
          ),
        ),
        const SizedBox(height: 9),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _carouselLength,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _eventPage == i ? 18 : 6,
              height: 5,
              decoration: BoxDecoration(
                color: _eventPage == i
                    ? AppPalette.blue
                    : AppPalette.blue.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  _EventData _toEventData(EventModel e) {
    final heure =
        '${e.time.hour.toString().padLeft(2, '0')}h${e.time.minute.toString().padLeft(2, '0')}';
    final lieu =
        e.location.isNotEmpty ? e.location : 'Lieu à confirmer';

    final desc = e.description.isNotEmpty
        ? e.description
        : e.price > 0
            ? 'Ticket : ${e.price.toStringAsFixed(0)} FCFA'
            : 'Entrée gratuite';

    return _EventData(
      '🎉',
      DateFormat('dd MMM').format(e.date),
      e.name,
      desc,
      '$lieu · $heure',
      imageUrl: e.imageUrl,
    );
  }

  Widget _eventCard(_EventData event, {EventModel? model}) {
    return GestureDetector(
      onTap: () async {
        if (model != null) {
          final registered = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventRegistrationPage(event: model),
            ),
          );
          if (registered == true) _fetchEvenements();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: _cardDecoration(radius: 17),
        child: Row(
          children: [
            SizedBox(
              width: 62,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(event.date.split(' ').first,
                      style: const TextStyle(
                        color: AppPalette.blue,
                        fontSize: 25, fontWeight: FontWeight.w800,
                      )),
                  Text(
                    event.date.split(' ').length > 1
                        ? event.date.split(' ').sublist(1).join(' ').toUpperCase()
                        : '',
                    style: const TextStyle(
                      color: AppPalette.grey,
                      fontSize: 9, fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 58, color: AppPalette.borderGrey),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: AppPalette.lightBlue, shape: BoxShape.circle),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                    ? (event.imageUrl!.startsWith('data:image')
                        ? Image.memory(
                            base64Decode(event.imageUrl!.split(',').last),
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(event.emoji,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                          )
                        : Image.network(
                            event.imageUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(event.emoji,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                          ))
                    : Center(
                        child: Text(event.emoji,
                            style: const TextStyle(fontSize: 20)),
                      ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.titre,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF172033),
                        fontSize: 13, fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 4),
                  Text(event.desc,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppPalette.grey, fontSize: 9.5)),
                  const SizedBox(height: 5),
                  Text(event.lieu,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppPalette.grey, fontSize: 9)),
                ],
              ),
            ),
            if (model != null)
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF64748B), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActualitesCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Annonces du campus',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172033),
              ),
            ),
            GestureDetector(
              onTap: _fetchAnnonces,
              child: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: AppPalette.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_annoncesLoading)
          const SizedBox(
            height: 110,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_annonces.isEmpty)
          _annonceVide()
        else
          SizedBox(
            height: 118,
            child: PageView.builder(
              controller: _annoncesCtrl,
              onPageChanged: (i) => setState(() => _annoncePage = i),
              itemCount: _annonces.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _annonceCard(_annonces[i]),
              ),
            ),
          ),
      ],
    );
  }

  static const _typeConfig = {
    'urgent': (
      Icons.warning_amber_rounded,
      Color(0xFFEF4444),
      Color(0xFFFEF2F2),
      'Urgent'
    ),
    'event': (
      Icons.event_rounded,
      Color(0xFF8B5CF6),
      Color(0xFFF5F3FF),
      'Événement'
    ),
    'info': (
      Icons.info_outline_rounded,
      Color(0xFF0A4DA2),
      Color(0xFFEFF6FF),
      'Info'
    ),
  };

  void _afficherDetailsAnnonce(Map<String, dynamic> annonce) {
    final type = annonce['type'] as String? ?? 'info';
    final cfg = _typeConfig[type] ?? _typeConfig['info']!;
    final (icon, color, bgColor, label) = cfg;

    final titre = annonce['titre'] as String? ?? 'Annonce';
    final contenu = annonce['contenu'] as String? ??
        annonce['description'] as String? ??
        'Aucun détail disponible pour cette annonce.';
    final auteurNom = annonce['auteur_nom'] ?? annonce['auteur']?['nom'] ?? '';
    final auteurPrenom = annonce['auteur_prenoms'] ?? annonce['auteur']?['prenoms'] ?? '';
    final auteurStr = '$auteurPrenom $auteurNom'.trim();

    String dateStr = '';
    try {
      final raw = annonce['created_at'] as String? ?? annonce['createdAt'] as String?;
      if (raw != null) {
        final dt = DateTime.parse(raw);
        dateStr = DateFormat('dd/MM/yyyy à HH:mm').format(dt);
      }
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (dateStr.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (auteurStr.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Par $auteurStr',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                titre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    contenu,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF334155),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _annonceCard(Map<String, dynamic> annonce) {
    final type = annonce['type'] as String? ?? 'info';
    final cfg = _typeConfig[type] ?? _typeConfig['info']!;
    final (icon, color, bgColor, label) = cfg;

    String dateStr = '';
    try {
      final raw = annonce['created_at'] as String? ?? annonce['createdAt'] as String?;
      if (raw != null) {
        final dt = DateTime.parse(raw);
        final diff = DateTime.now().difference(dt);

        if (diff.inMinutes < 60) {
          dateStr = 'Il y a ${diff.inMinutes} min';
        } else if (diff.inHours < 24) {
          dateStr = 'Il y a ${diff.inHours}h';
        } else {
          dateStr = 'Il y a ${diff.inDays}j';
        }
      }
    } catch (_) {}

    final titre = annonce['titre'] as String? ?? '';
    final contenu = (annonce['contenu'] as String? ?? annonce['description'] as String? ?? '').trim();

    return GestureDetector(
      onTap: () => _afficherDetailsAnnonce(annonce),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(radius: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF172033),
                      height: 1.2,
                    ),
                  ),
                  if (contenu.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Expanded(
                      child: Text(
                        contenu,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dateStr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: Color(0xFFA0AEC0),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
 
Widget _annonceVide() {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFD9E0EA)),
      ),
      child: const Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined,
                size: 22, color: Color(0xFFCBD5E1)),
            SizedBox(width: 9),
            Text("Aucune annonce pour l'instant",
                style: TextStyle(
                  fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
 
  Widget _sectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172033),
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppPalette.blue,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
 
  Widget _whiteInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
 
 
 
  Widget _loadingCard({double height = 130}) {
    return Container(
      height: height,
      decoration: _cardDecoration(radius: 20),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
 
  BoxDecoration _cardDecoration({double radius = 18}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: const Color(0xFFE2E8F0),
        width: 0.7,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 9,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
 
  void _showCantineSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CantineSheet(),
    );
  }
}
class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;
 
  const _QuickAction(
    this.icon,
    this.label,
    this.onTap, {
    this.badge = 0,
  });
}
 
class _EventData {
  final String emoji;
  final String date;
  final String titre;
  final String desc;
  final String lieu;
  final String? imageUrl;
 
  const _EventData(
    this.emoji,
    this.date,
    this.titre,
    this.desc,
    this.lieu, {
    this.imageUrl,
  });
}
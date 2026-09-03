import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/student_profile.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../theme/app_palette.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES INTERNES
// ════════════════════════════════════════════════════════════════════════════
class _FiliereInfo {
  final int id;
  final String nom;
  final String? description;
  _FiliereInfo({required this.id, required this.nom, this.description});
}

enum _TypeMsg { texte }

class _Msg {
  final String id;
  final String auteurId, auteurNom;
  final String contenu;
  final _TypeMsg type;
  final DateTime heure;
  final bool estMoi;
  Map<String, String> reactions;

  _Msg({
    required this.id,
    required this.auteurId,
    required this.auteurNom,
    required this.contenu,
    required this.type,
    required this.heure,
    required this.estMoi,
    Map<String, String>? reactions,
  }) : reactions = reactions ?? {};

  _Msg copyWith({Map<String, String>? reactions}) => _Msg(
        id: id,
        auteurId: auteurId,
        auteurNom: auteurNom,
        contenu: contenu,
        type: type,
        heure: heure,
        estMoi: estMoi,
        reactions: reactions ?? this.reactions,
      );
}

// ════════════════════════════════════════════════════════════════════════════
// ÉCRAN DE LISTE DES GROUPES (Prof)
// ════════════════════════════════════════════════════════════════════════════
class ProfGroupeScreen extends StatefulWidget {
  final StudentProfile profile;
  const ProfGroupeScreen({super.key, required this.profile});

  @override
  State<ProfGroupeScreen> createState() => _ProfGroupeScreenState();
}

class _ProfGroupeScreenState extends State<ProfGroupeScreen> {
  List<_FiliereInfo> _filieres = [];
  bool _loading = true;
  String? _erreur;

  // Couleurs
  static const _blue = Color(0xFF1E40AF);
  static const _bgPage = Color(0xFFF8FAFC);
  static const _border = Color(0xFFE2E8F0);
  static const _textMuted = Color(0xFF64748B);

  final List<Color> _palette = const [
    Color(0xFF1E40AF),
    Color(0xFF0891B2),
    Color(0xFF059669),
    Color(0xFF7C3AED),
    Color(0xFFDC2626),
    Color(0xFFD97706),
  ];

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
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/messages/groupe/mes-filieres'),
        headers: headers,
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        final List data = body['data'] as List? ?? [];
        setState(() {
          _filieres = data
              .map((f) => _FiliereInfo(
                    id: (f['id'] as num).toInt(),
                    nom: f['nom'] as String? ?? 'Filière',
                    description: f['description'] as String?,
                  ))
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _erreur = 'Erreur ${res.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erreur = 'Impossible de charger les filières';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: Column(children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E40AF), Color(0xFF1565C0)],
              ),
            ),
            child: Row(children: [
              if (Navigator.canPop(context))
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.school_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mes Groupes Étudiants',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      Text('Prof. ${widget.profile.prenoms} ${widget.profile.nom}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500)),
                    ]),
              ),
              // Bouton refresh
              GestureDetector(
                onTap: _charger,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),

          // ── Bannière info ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.06),
              border: const Border(
                  bottom: BorderSide(color: _border)),
            ),
            child: const Row(children: [
              Icon(Icons.groups_rounded, color: _blue, size: 16),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Vos groupes de discussion avec les étudiants de chaque filière',
                  style: TextStyle(
                      fontSize: 12,
                      color: _blue,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ]),
          ),

          // ── Contenu ───────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _erreur != null
                    ? _buildErreur()
                    : _filieres.isEmpty
                        ? _buildVide()
                        : _buildListe(),
          ),
        ]),
      ),
    );
  }

  Widget _buildErreur() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_off_rounded,
              color: Color(0xFFCBD5E1), size: 48),
          const SizedBox(height: 16),
          Text(_erreur!,
              style: const TextStyle(color: _textMuted, fontSize: 14)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _charger,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Réessayer'),
          ),
        ]),
      );

  Widget _buildVide() => const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.school_outlined, color: Color(0xFFCBD5E1), size: 56),
          SizedBox(height: 16),
          Text('Aucune filière assignée',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B))),
          SizedBox(height: 6),
          Text(
              'Contactez l\'administration pour\nbénéficier d\'un accès groupe',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
        ]),
      );

  Widget _buildListe() => ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _filieres.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) => _carteFiliere(_filieres[i], i),
      );

  Widget _carteFiliere(_FiliereInfo f, int idx) {
    final couleur = _palette[idx % _palette.length];
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _ProfChatFiliere(
            profile: widget.profile,
            filiere: f,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.groups_rounded, color: couleur, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.nom,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text(
                    f.description ?? 'Groupe de discussion avec vos étudiants',
                    style: const TextStyle(
                        fontSize: 12, color: _textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: couleur.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 11, color: couleur),
                      const SizedBox(width: 4),
                      Text('Ouvrir la discussion',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: couleur)),
                    ]),
                  ),
                ]),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              color: _textMuted.withValues(alpha: 0.4), size: 16),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CHAT FILIÈRE (Prof)
// ════════════════════════════════════════════════════════════════════════════
class _ProfChatFiliere extends StatefulWidget {
  final StudentProfile profile;
  final _FiliereInfo filiere;
  const _ProfChatFiliere({required this.profile, required this.filiere});

  @override
  State<_ProfChatFiliere> createState() => _ProfChatFiliereState();
}

class _ProfChatFiliereState extends State<_ProfChatFiliere> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_Msg> _messages = [];
  String? _myUserId;
  bool _loading = true;

  String get _nomProf =>
      '${widget.profile.prenoms} ${widget.profile.nom}';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _myUserId = await ApiService.getUserId();
    await _chargerMessages();
    await _connecterSocket();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _chargerMessages() async {
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.get(
        Uri.parse(
            '${ApiService.baseUrl}/messages/groupe/${widget.filiere.id}'),
        headers: headers,
      );
      if (!mounted || res.statusCode != 200) return;
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      final List data = body['data'] as List? ?? [];
      setState(() {
        _messages.clear();
        for (final m in data) {
          _messages.add(_depuisJson(m as Map<String, dynamic>));
        }
      });
      _scrollBas();
    } catch (_) {}
  }

  Future<void> _connecterSocket() async {
    await SocketService().connect();
    SocketService().joinRoom('filiere:${widget.filiere.id}');
    SocketService().onGroupeMessage((data) {
      if (!mounted) return;
      final json = data is Map<String, dynamic>
          ? data
          : jsonDecode(data.toString()) as Map<String, dynamic>;
      if (json['filiere_id']?.toString() != widget.filiere.id.toString()) return;
      if (_myUserId != null &&
          json['auteur_id']?.toString() == _myUserId) return;
      setState(() => _messages.add(_depuisJson(json)));
      Future.delayed(const Duration(milliseconds: 100), _scrollBas);
    });
  }

  _Msg _depuisJson(Map<String, dynamic> json) {
    final estMoi =
        _myUserId != null && json['auteur_id']?.toString() == _myUserId;
    return _Msg(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      auteurId: json['auteur_id']?.toString() ?? '',
      auteurNom: estMoi
          ? _nomProf
          : '${json['prenoms'] ?? ''} ${json['nom'] ?? ''}'.trim(),
      contenu: json['contenu']?.toString() ?? '',
      type: _TypeMsg.texte,
      heure:
          (DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now())
              .toLocal(),
      estMoi: estMoi,
    );
  }

  @override
  void dispose() {
    SocketService().off('message:groupe');
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollBas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _envoyer() async {
    final texte = _inputCtrl.text.trim();
    if (texte.isEmpty) return;
    _inputCtrl.clear();

    final msgLocal = _Msg(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      auteurId: _myUserId ?? '',
      auteurNom: _nomProf,
      contenu: texte,
      type: _TypeMsg.texte,
      heure: DateTime.now(),
      estMoi: true,
    );
    setState(() => _messages.add(msgLocal));
    _scrollBas();

    try {
      final headers = await ApiService.getHeaders();
      final res = await http.post(
        Uri.parse(
            '${ApiService.baseUrl}/messages/groupe/${widget.filiere.id}'),
        headers: headers,
        body: jsonEncode({'contenu': texte}),
      );
      if (res.statusCode != 201 && mounted) {
        setState(() => _messages.remove(msgLocal));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Échec de l\'envoi')));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _messages.remove(msgLocal));
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serveur injoignable')));
    }
  }

  String _initiales(String nom) {
    final parts = nom.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nom.isNotEmpty ? nom[0].toUpperCase() : '?';
  }

  String _formatHeure(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  bool _memeJour(DateTime a, DateTime b) =>
      a.day == b.day && a.month == b.month && a.year == b.year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF4FF),
      appBar: AppBar(
        backgroundColor: AppPalette.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.groups_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.filiere.nom,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const Text('Groupe Prof ↔ Étudiants',
                      style: TextStyle(fontSize: 10, color: Colors.white70)),
                ]),
          ),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: Colors.white.withValues(alpha: 0.2)),
        ),
      ),
      body: Column(children: [
        // Bandeau prof
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppPalette.blue.withValues(alpha: 0.08),
          child: Row(children: [
            const Icon(Icons.school_rounded,
                color: AppPalette.blue, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Vous participez en tant que Prof. $_nomProf',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppPalette.blue,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ]),
        ),

        // Liste messages
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? const Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              color: Color(0xFFCBD5E1), size: 48),
                          SizedBox(height: 12),
                          Text('Aucun message pour l\'instant',
                              style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13)),
                          SizedBox(height: 4),
                          Text('Soyez le premier à écrire !',
                              style: TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 12)),
                        ]))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final msg = _messages[i];
                        final showDate = i == 0 ||
                            !_memeJour(
                                _messages[i - 1].heure, msg.heure);
                        return Column(children: [
                          if (showDate) _separateurDate(msg.heure),
                          _bulle(msg),
                        ]);
                      }),
        ),

        // Zone de saisie
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _inputCtrl,
                  maxLines: 4,
                  minLines: 1,
                  style: const TextStyle(
                      fontSize: 15, color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    hintText: 'Message à vos étudiants...',
                    hintStyle: TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _envoyer(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _envoyer,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppPalette.blue,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: AppPalette.blue.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _separateurDate(DateTime dt) {
    final now = DateTime.now();
    final label = _memeJour(dt, now)
        ? 'Aujourd\'hui'
        : _memeJour(dt, now.subtract(const Duration(days: 1)))
            ? 'Hier'
            : '${dt.day}/${dt.month}/${dt.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _bulle(_Msg msg) {
    final estMoi = msg.estMoi;
    // Un badge "Prof" pour distinguer le prof des étudiants
    final isProf = estMoi;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              estMoi ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!estMoi) ...[
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    AppPalette.blue.withValues(alpha: 0.15),
                child: Text(_initiales(msg.auteurNom),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.blue)),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                  crossAxisAlignment: estMoi
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Nom + badge
                    if (!estMoi)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: Text(msg.auteurNom,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppPalette.blue)),
                      )
                    else
                      Padding(
                        padding:
                            const EdgeInsets.only(right: 4, bottom: 4),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Prof',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF059669))),
                              ),
                              const SizedBox(width: 4),
                              Text(msg.auteurNom,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B))),
                            ]),
                      ),

                    // Bulle
                    Container(
                      constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.72),
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      decoration: BoxDecoration(
                        color: isProf
                            ? AppPalette.blue
                            : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft:
                              Radius.circular(estMoi ? 18 : 4),
                          bottomRight:
                              Radius.circular(estMoi ? 4 : 18),
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2)),
                        ],
                        border: estMoi
                            ? null
                            : Border.all(
                                color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(msg.contenu,
                          style: TextStyle(
                              fontSize: 14,
                              color:
                                  estMoi ? Colors.white : const Color(0xFF0F172A),
                              height: 1.4)),
                    ),

                    // Heure
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 4, left: 4),
                      child: Text(_formatHeure(msg.heure),
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF94A3B8))),
                    ),
                  ]),
            ),
            if (estMoi) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF059669)
                    .withValues(alpha: 0.15),
                child: Text(_initiales(_nomProf),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669))),
              ),
            ],
          ]),
    );
  }
}

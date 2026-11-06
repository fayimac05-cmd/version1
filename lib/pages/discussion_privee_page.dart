import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../theme/app_palette.dart';
import 'emoji_gif_sticker_picker.dart';

class DiscussionPriveePage extends StatefulWidget {
  final String destinataireId;
  final String destinataireNom;
  final String? destinataireRole;
  final String? destinataireSousTitre;
  final String? destinatairePhotoUrl;
  final Color? themeColor;

  const DiscussionPriveePage({
    super.key,
    required this.destinataireId,
    required this.destinataireNom,
    this.destinataireRole,
    this.destinataireSousTitre,
    this.destinatairePhotoUrl,
    this.themeColor,
  });

  @override
  State<DiscussionPriveePage> createState() => _DiscussionPriveePageState();
}

class _DiscussionPriveePageState extends State<DiscussionPriveePage> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _hasText = false;
  bool _loading = true;
  bool _showEmoji = false;
  String? _myUserId;

  final List<Map<String, dynamic>> _messages = [];
  bool _modeSelection = false;
  final Set<String> _selectionnes = {};
  Map<String, dynamic>? _reponseA; // message ciblé : {id, texte, auteur}

  Color get _primaryColor => widget.themeColor ?? AppPalette.blue;

  String get _initiales {
    final parts = widget.destinataireNom.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return widget.destinataireNom.isNotEmpty ? widget.destinataireNom[0].toUpperCase() : '?';
  }

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() {
      final has = _msgCtrl.text.trim().isNotEmpty;
      if (has != _hasText && mounted) setState(() => _hasText = has);
    });
    _init();
  }

  Future<void> _init() async {
    _myUserId = await ApiService.getUserId();
    await _chargerMessages();
    await _connecterSocket();
  }

  @override
  void dispose() {
    SocketService().off('message:prive');
    SocketService().off('message:read');
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _connecterSocket() async {
    await SocketService().connect();

    SocketService().onPrivateMessage((data) {
      if (!mounted) return;
      final json = data is Map<String, dynamic>
          ? data
          : jsonDecode(data.toString()) as Map<String, dynamic>;

      final expId = json['expediteur_id']?.toString();
      final destId = json['destinataire_id']?.toString();

      // On n'accepte que les messages de cette conversation
      if (expId != widget.destinataireId && destId != widget.destinataireId) return;
      if (_myUserId != null && expId == _myUserId) return;

      final msgId = json['id']?.toString() ?? UniqueKey().toString();
      if (_messages.any((m) => m['id'] == msgId)) return;

      setState(() {
        _messages.add({
          'id': msgId,
          'texte': json['contenu']?.toString() ?? '',
          'estMoi': false,
          'heure': _formatHeure(json['created_at']),
          'lu': true,
          'photoUrl': json['photo_url']?.toString(),
          ..._champsReponse(json),
        });
      });

      // Accusé de lecture automatique
      SocketService().sendReadReceipt(widget.destinataireId);
      ApiService.post('/messages/prives/read/${widget.destinataireId}');
      _scrollBas();
    });

    SocketService().onMessageRead((data) {
      if (!mounted) return;
      final json = data is Map<String, dynamic> ? data : {};
      final dest = json['destinataire_id']?.toString();
      if (dest == widget.destinataireId) {
        setState(() {
          for (final m in _messages) {
            if (m['estMoi'] == true) m['lu'] = true;
          }
        });
      }
    });
  }

  Future<void> _chargerMessages() async {
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/messages/prives/${widget.destinataireId}'),
        headers: headers,
      );
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        final list = (body is Map ? body['data'] : body) as List? ?? [];
        setState(() {
          _messages.clear();
          for (final m in list) {
            final senderId = m['expediteur_id']?.toString();
            final estMoi = _myUserId != null && senderId == _myUserId;
            _messages.add({
              'id': m['id']?.toString() ?? UniqueKey().toString(),
              'texte': m['contenu']?.toString() ?? '',
              'estMoi': estMoi,
              'heure': _formatHeure(m['created_at']),
              'lu': m['is_read'] == true || estMoi == false,
              'photoUrl': m['photo_url']?.toString(),
              ..._champsReponse(m),
            });
          }
          _loading = false;
        });

        // Marquer comme lus
        SocketService().sendReadReceipt(widget.destinataireId);
        await ApiService.post('/messages/prives/read/${widget.destinataireId}');
        _scrollBas();
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('[DiscussionPriveePage] Erreur chargement: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // Champs de la réponse ciblée renvoyés par le serveur.
  Map<String, dynamic> _champsReponse(dynamic m) {
    final id = m['reponse_a_id'];
    if (id == null) return {};
    final texte = m['reponse_texte']?.toString();
    return {
      'reponseId': id.toString(),
      'reponseTexte': texte ?? 'Message supprimé',
      'reponseAuteur': m['reponse_auteur']?.toString() ?? '',
    };
  }

  String _formatHeure(dynamic raw) {
    if (raw == null) return _now();
    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    if (dt == null) return _now();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _now() {
    final t = TimeOfDay.now();
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
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
    final texte = _msgCtrl.text.trim();
    if (texte.isEmpty) return;
    final rep = _reponseA;

    final tempId = 'T${DateTime.now().millisecondsSinceEpoch}';
    final localMsg = {
      'id': tempId,
      'texte': texte,
      'estMoi': true,
      'heure': _now(),
      'lu': false,
      if (rep != null) 'reponseId': rep['id'],
      if (rep != null) 'reponseTexte': rep['texte'],
      if (rep != null) 'reponseAuteur': rep['auteur'],
    };

    setState(() {
      _messages.add(localMsg);
      _hasText = false;
      _reponseA = null;
    });
    _msgCtrl.clear();
    _scrollBas();

    // Envoi HTTP : le serveur persiste (avec la réponse ciblée) et notifie
    // le destinataire en temps réel par socket.
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/messages/prives/${widget.destinataireId}'),
        headers: headers,
        body: jsonEncode({
          'contenu': texte,
          if (rep != null) 'reponse_a_id': int.tryParse(rep['id'].toString()),
        }),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        final data = body is Map ? body['data'] : null;
        if (data != null && data['id'] != null) {
          localMsg['id'] = data['id'].toString();
        }
      }
    } catch (e) {
      debugPrint('[DiscussionPriveePage] Erreur envoi HTTP: $e');
    }
  }

  // ── GIF réel (URL publique GIPHY, envoyé via le même canal texte) ─────
  Future<void> _envoyerGif(String url) async {
    setState(() => _showEmoji = false);
    final contenu = '[GIF]$url';
    final tempId = 'T${DateTime.now().millisecondsSinceEpoch}';
    final localMsg = {
      'id': tempId,
      'texte': contenu,
      'estMoi': true,
      'heure': _now(),
      'lu': false,
    };
    setState(() => _messages.add(localMsg));
    _scrollBas();
    SocketService().sendPrivateMessage(widget.destinataireId, {'contenu': contenu});
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/messages/prives/${widget.destinataireId}'),
        headers: headers,
        body: jsonEncode({'contenu': contenu}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        final data = body is Map ? body['data'] : null;
        if (data != null && data['id'] != null) {
          localMsg['id'] = data['id'].toString();
        }
      }
    } catch (e) {
      debugPrint('[DiscussionPriveePage] Erreur envoi GIF: $e');
    }
  }

  // ── Sticker : fichier local, écho visible seulement pour vous (pas
  // d'upload disponible pour l'instant) ────────────────────────────────
  void _envoyerSticker(String chemin) {
    setState(() {
      _showEmoji = false;
      _messages.add({
        'id': 'T${DateTime.now().millisecondsSinceEpoch}',
        'texte': '[STICKER]$chemin',
        'estMoi': true,
        'heure': _now(),
        'lu': false,
      });
    });
    _scrollBas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: _modeSelection ? _buildAppBarSelection() : _buildAppBar(),
      body: LayoutBuilder(builder: (context, constraints) {
        final conversation = Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) => _buildBulle(_messages[i]),
                        ),
            ),
            if (_reponseA != null)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border(left: BorderSide(color: _primaryColor, width: 4)),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_reponseA!['auteur'].toString(),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _primaryColor)),
                        Text(_reponseA!['texte'].toString(),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569))),
                      ],
                    )),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                      onPressed: () => setState(() => _reponseA = null),
                    ),
                  ]),
                ),
              ),
            _buildZoneSaisie(),
            if (_showEmoji) _buildPanneauEmoji(),
          ],
        );
        if (constraints.maxWidth < 980) return conversation;
        return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: conversation),
          Container(width: 1, color: const Color(0xFFE5E7EB)),
          SizedBox(width: 300, child: _buildPanneauInformations()),
        ]);
      }),
    );
  }

  bool? _enLigne;
  bool _chargeEnLigne = false;

  Future<void> _chargerStatutEnLigne() async {
    if (_chargeEnLigne) return;
    _chargeEnLigne = true;
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.get(Uri.parse('${ApiService.baseUrl}/messages/online'), headers: headers);
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (!mounted) return;
      if (res.statusCode == 200 && body['success'] == true) {
        final ids = (body['data'] as List<dynamic>? ?? []).map((u) => u['id']?.toString()).toSet();
        setState(() => _enLigne = ids.contains(widget.destinataireId));
      }
    } catch (_) {
      // Statut en ligne facultatif — on n'affiche simplement rien en cas d'échec.
    }
  }

  // ── Panneau "Informations" (desktop uniquement) — photo, nom, rôle et
  // statut en ligne réel. Pas de "Fichiers partagés" ni d'actions
  // (appeler, envoyer un fichier, planifier) : aucune de ces capacités
  // n'existe réellement dans la messagerie privée (texte seul, aucune
  // pièce jointe possible ici).
  Widget _buildPanneauInformations() {
    if (_enLigne == null && !_chargeEnLigne) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _chargerStatutEnLigne());
    }
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Informations', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        const SizedBox(height: 18),
        Center(
          child: Column(children: [
            _AvatarBulle(photoUrl: widget.destinatairePhotoUrl, initiale: _initiales.isNotEmpty ? _initiales[0] : '?', couleur: _primaryColor),
            const SizedBox(height: 10),
            Text(widget.destinataireNom, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            if (_enLigne != null)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(color: _enLigne! ? const Color(0xFF10B981) : const Color(0xFF94A3B8), shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(_enLigne! ? 'En ligne' : 'Hors ligne', style: TextStyle(fontSize: 11.5, color: _enLigne! ? const Color(0xFF10B981) : const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
              ]),
          ]),
        ),
        const SizedBox(height: 18),
        if (widget.destinataireRole != null) _infoLigne(Icons.badge_outlined, widget.destinataireRole!),
        if (widget.destinataireSousTitre != null) _infoLigne(Icons.school_outlined, widget.destinataireSousTitre!),
      ]),
    );
  }

  Widget _infoLigne(IconData icon, String texte) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Expanded(child: Text(texte, style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), fontWeight: FontWeight.w600))),
      ]),
    );
  }

  AppBar _buildAppBarSelection() {
    return AppBar(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => setState(() { _modeSelection = false; _selectionnes.clear(); }),
      ),
      title: Text('${_selectionnes.length} sélectionné${_selectionnes.length > 1 ? 's' : ''}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: _selectionnes.isEmpty ? null : _supprimerSelection,
        ),
      ],
    );
  }

  // Appui long sur un message : menu d'actions (comme le canal).
  void _menuMessage(Map<String, dynamic> msg) {
    final id = msg['id']?.toString() ?? '';
    final texte = msg['texte']?.toString() ?? '';
    Widget action(IconData icone, String titre, VoidCallback onTap, {Color? couleur}) => ListTile(
          leading: Icon(icone, color: couleur ?? const Color(0xFF64748B)),
          title: Text(titre, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: couleur ?? const Color(0xFF1E293B))),
          onTap: () { Navigator.pop(context); onTap(); },
        );
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: EdgeInsets.only(top: 8, bottom: 8 + MediaQuery.of(context).padding.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
          action(Icons.reply_rounded, 'Répondre', () {
            if (int.tryParse(id) == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message en cours d\'envoi, réessayez dans un instant')));
              return;
            }
            setState(() => _reponseA = {
                  'id': id,
                  'texte': _apercu(texte),
                  'auteur': msg['estMoi'] == true ? 'Vous' : widget.destinataireNom,
                });
            _focusNode.requestFocus();
          }),
          action(Icons.copy_rounded, 'Copier le texte', () {
            Clipboard.setData(ClipboardData(text: _apercu(texte)));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Texte copié')));
          }),
          action(Icons.check_box_outlined, 'Sélectionner', () => _demarrerSelection(id)),
          action(Icons.delete_outline_rounded, 'Supprimer', () {
            _demarrerSelection(id);
            _supprimerSelection();
          }, couleur: const Color(0xFFDC2626)),
        ]),
      ),
    );
  }

  void _demarrerSelection(String id) {
    setState(() { _modeSelection = true; _selectionnes.clear(); _selectionnes.add(id); });
  }

  void _basculerSelection(String id) {
    setState(() {
      if (_selectionnes.contains(id)) {
        _selectionnes.remove(id);
        if (_selectionnes.isEmpty) _modeSelection = false;
      } else {
        _selectionnes.add(id);
      }
    });
  }

  Future<void> _supprimerSelection() async {
    final idsSelectionnes = _selectionnes.toList();
    final tousMoi = idsSelectionnes.every((id) {
      for (final m in _messages) {
        if (m['id']?.toString() == id) return m['estMoi'] == true;
      }
      return false;
    });
    final choix = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: EdgeInsets.only(top: 8, bottom: 8 + MediaQuery.of(context).padding.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('${idsSelectionnes.length} message${idsSelectionnes.length > 1 ? 's' : ''} sélectionné${idsSelectionnes.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ),
          const SizedBox(height: 4),
          ListTile(
            leading: const Icon(Icons.person_remove_outlined, color: Color(0xFF64748B)),
            title: const Text('Supprimer pour moi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            onTap: () => Navigator.pop(context, 'moi'),
          ),
          if (tousMoi)
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626)),
              title: const Text('Supprimer pour tout le monde', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFDC2626))),
              onTap: () => Navigator.pop(context, 'tous'),
            ),
          ListTile(
            leading: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
            title: const Text('Annuler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            onTap: () => Navigator.pop(context, null),
          ),
        ]),
      ),
    );
    if (choix == null) return;

    setState(() {
      _messages.removeWhere((m) => idsSelectionnes.contains(m['id']?.toString()));
      _modeSelection = false;
      _selectionnes.clear();
    });

    final headers = await ApiService.getHeaders();
    for (final id in idsSelectionnes) {
      final idNumerique = int.tryParse(id);
      if (idNumerique == null) continue; // message pas encore confirmé par le serveur
      try {
        if (choix == 'tous') {
          await http.delete(Uri.parse('${ApiService.baseUrl}/messages/prive/$idNumerique'), headers: headers);
        } else {
          await http.post(Uri.parse('${ApiService.baseUrl}/messages/prive/$idNumerique/masquer'), headers: headers);
        }
      } catch (_) {}
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: Colors.white24,
            backgroundImage: (widget.destinatairePhotoUrl != null && widget.destinatairePhotoUrl!.isNotEmpty)
                ? NetworkImage(widget.destinatairePhotoUrl!)
                : null,
            child: (widget.destinatairePhotoUrl == null || widget.destinatairePhotoUrl!.isEmpty)
                ? Text(
                    _initiales,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.destinataireNom,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    if (widget.destinataireRole != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.destinataireRole!,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (widget.destinataireSousTitre != null)
                      Expanded(
                        child: Text(
                          widget.destinataireSousTitre!,
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_outline_rounded, color: _primaryColor, size: 30),
          ),
          const SizedBox(height: 12),
          Text(
            'Démarrez la conversation avec',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          Text(
            widget.destinataireNom,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Les échanges sont directs et confidentiels.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBulle(Map<String, dynamic> msg) {
    final estMoi = msg['estMoi'] == true;
    final lu = msg['lu'] == true;
    final id = msg['id']?.toString() ?? '';
    final selectionne = _selectionnes.contains(id);

    return GestureDetector(
      onTap: _modeSelection ? () => _basculerSelection(id) : null,
      onLongPress: _modeSelection ? null : () => _menuMessage(msg),
      child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_modeSelection) ...[
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                selectionne ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 20,
                color: selectionne ? _primaryColor : const Color(0xFFCBD5E1),
              ),
            ),
          ],
          Expanded(child: Row(
        mainAxisAlignment: estMoi ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!estMoi) ...[
            _AvatarBulle(
              photoUrl: msg['photoUrl'] as String?,
              initiale: _initiales.isNotEmpty ? _initiales[0] : '?',
              couleur: _primaryColor,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              decoration: BoxDecoration(
                color: estMoi ? _primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(estMoi ? 14 : 2),
                  bottomRight: Radius.circular(estMoi ? 2 : 14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (msg['reponseId'] != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        color: (estMoi ? Colors.white : _primaryColor).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(left: BorderSide(color: estMoi ? Colors.white70 : _primaryColor, width: 3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((msg['reponseAuteur']?.toString() ?? '').isNotEmpty)
                            Text(msg['reponseAuteur'].toString(),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700,
                                    color: estMoi ? Colors.white : _primaryColor)),
                          Text(_apercu(msg['reponseTexte']?.toString() ?? ''),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: estMoi ? Colors.white70 : const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  _contenuTexte(msg['texte']?.toString() ?? '', estMoi),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg['heure']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 9,
                          color: estMoi ? Colors.white70 : const Color(0xFF94A3B8),
                        ),
                      ),
                      if (estMoi) ...[
                        const SizedBox(width: 4),
                        Icon(
                          lu ? Icons.done_all_rounded : Icons.done_rounded,
                          size: 13,
                          color: lu ? const Color(0xFF7DD3FC) : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
          )),
        ],
      ),
      ),
    );
  }

  String _apercu(String t) {
    if (t.startsWith('[GIF]')) return 'GIF';
    if (t.startsWith('[STICKER]')) return '🏷️ Sticker';
    if (t.startsWith('[FICHIER]')) return '📎 Fichier';
    return t;
  }

  Widget _contenuTexte(String texte, bool estMoi) {
    if (texte.startsWith('[GIF]')) {
      final url = texte.substring(5);
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url, width: 160, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Text('[GIF]', style: TextStyle(fontSize: 13, color: estMoi ? Colors.white70 : const Color(0xFF64748B))),
        ),
      );
    }
    if (texte.startsWith('[STICKER]')) {
      final chemin = texte.substring(9);
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: kIsWeb
            ? Image.network(chemin, width: 120, height: 120, fit: BoxFit.cover)
            : Image.file(File(chemin), width: 120, height: 120, fit: BoxFit.cover),
      );
    }
    return Text(
      texte,
      style: TextStyle(
        fontSize: 14,
        color: estMoi ? Colors.white : const Color(0xFF0F172A),
        height: 1.35,
      ),
    );
  }

  Widget _buildZoneSaisie() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Champ large façon WhatsApp : émoji à l'intérieur, bouton rond à côté.
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        setState(() => _showEmoji = !_showEmoji);
                      },
                      child: SizedBox(
                        width: 44,
                        height: 48,
                        child: Icon(
                          _showEmoji ? Icons.keyboard_rounded : Icons.sentiment_satisfied_alt_rounded,
                          color: const Color(0xFF64748B),
                          size: 24,
                        ),
                      ),
                    ),
                    Expanded(
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (e) {
                          if (e is KeyDownEvent &&
                              e.logicalKey == LogicalKeyboardKey.enter &&
                              !HardwareKeyboard.instance.isShiftPressed) {
                            _envoyer();
                          }
                        },
                        child: TextField(
                          controller: _msgCtrl,
                          focusNode: _focusNode,
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          onTap: () {
                            if (_showEmoji) setState(() => _showEmoji = false);
                          },
                          style: const TextStyle(fontSize: 16, color: Color(0xFF0F172A)),
                          decoration: const InputDecoration(
                            hintText: 'Écrire un message...',
                            hintStyle: TextStyle(fontSize: 15, color: Color(0xFF94A3B8)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(left: 2, right: 14, top: 14, bottom: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _hasText ? _envoyer : null,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _hasText ? _primaryColor : const Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanneauEmoji() {
    return EmojiGifStickerPicker(
      onEmoji: (emoji) {
        _msgCtrl.text += emoji;
        _msgCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _msgCtrl.text.length));
      },
      onEnvoiDirect: (type, valeur) {
        if (type == 'gif') {
          _envoyerGif(valeur);
        } else {
          _envoyerSticker(valeur);
        }
      },
    );
  }
}

/// Petit avatar rond pour les bulles de message — affiche la vraie photo de
/// profil de l'expéditeur si elle existe (et charge correctement), sinon
/// retombe sur l'initiale de son nom.
class _AvatarBulle extends StatelessWidget {
  final String? photoUrl;
  final String initiale;
  final Color couleur;
  const _AvatarBulle({required this.photoUrl, required this.initiale, required this.couleur});

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return CircleAvatar(
        radius: 12,
        backgroundColor: couleur.withValues(alpha: 0.15),
        child: Text(initiale, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: couleur)),
      );
    }
    return ClipOval(
      child: Image.network(
        photoUrl!,
        width: 24,
        height: 24,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(
          radius: 12,
          backgroundColor: couleur.withValues(alpha: 0.15),
          child: Text(initiale, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: couleur)),
        ),
      ),
    );
  }
}
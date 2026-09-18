import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../theme/app_palette.dart';

class DiscussionPriveePage extends StatefulWidget {
  final String destinataireId;
  final String destinataireNom;
  final String? destinataireRole;
  final String? destinataireSousTitre;
  final Color? themeColor;

  const DiscussionPriveePage({
    super.key,
    required this.destinataireId,
    required this.destinataireNom,
    this.destinataireRole,
    this.destinataireSousTitre,
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

    final tempId = 'T${DateTime.now().millisecondsSinceEpoch}';
    final localMsg = {
      'id': tempId,
      'texte': texte,
      'estMoi': true,
      'heure': _now(),
      'lu': false,
    };

    setState(() {
      _messages.add(localMsg);
      _hasText = false;
    });
    _msgCtrl.clear();
    _scrollBas();

    // 1. Émission Socket temps réel
    SocketService().sendPrivateMessage(widget.destinataireId, {'contenu': texte});

    // 2. Persistance HTTP REST
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/messages/prives/${widget.destinataireId}'),
        headers: headers,
        body: jsonEncode({'contenu': texte}),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBE5DD),
      appBar: _buildAppBar(),
      body: Column(
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
          _buildZoneSaisie(),
          if (_showEmoji) _buildPanneauEmoji(),
        ],
      ),
    );
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
            child: Text(
              _initiales,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: estMoi ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!estMoi) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: _primaryColor.withValues(alpha: 0.15),
              child: Text(
                _initiales.isNotEmpty ? _initiales[0] : '?',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _primaryColor),
              ),
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
                  Text(
                    msg['texte']?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: estMoi ? Colors.white : const Color(0xFF0F172A),
                      height: 1.35,
                    ),
                  ),
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
      ),
    );
  }

  Widget _buildZoneSaisie() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(
                _showEmoji ? Icons.keyboard_rounded : Icons.sentiment_satisfied_alt_rounded,
                color: const Color(0xFF64748B),
              ),
              onPressed: () => setState(() => _showEmoji = !_showEmoji),
            ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
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
                    maxLines: null,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      hintText: 'Écrire un message...',
                      hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _hasText ? _envoyer : null,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _hasText ? _primaryColor : const Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanneauEmoji() {
    const emojis = [
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '😉',
      '😊', '😇', '🥰', '😍', '😘', '😋', '😛', '😜', '🤪', '🤑',
      '🤗', '🤔', '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '😌',
      '😔', '😴', '🥺', '😢', '😭', '😱', '😡', '😠', '💀', '👍',
      '👎', '❤️', '🔥', '💯', '🎉', '🙏', '✅', '👏', '💪', '🤝',
      '👌', '🫶', '🤞', '✌️', '⭐', '🌟', '🎯', '📚', '🎓', '📝'
    ];

    return Container(
      height: 200,
      color: Colors.white,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: emojis.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () {
            _msgCtrl.text += emojis[i];
            _msgCtrl.selection = TextSelection.fromPosition(
              TextPosition(offset: _msgCtrl.text.length),
            );
          },
          child: Center(child: Text(emojis[i], style: const TextStyle(fontSize: 22))),
        ),
      ),
    );
  }
}

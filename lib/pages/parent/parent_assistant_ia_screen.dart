import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_palette.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLE MESSAGE
// ════════════════════════════════════════════════════════════════════════════
class _Message {
  final String texte;
  final bool estIA;
  final DateTime heure;
  final bool estErreur;

  const _Message({
    required this.texte,
    required this.estIA,
    required this.heure,
    this.estErreur = false,
  });
}

// ════════════════════════════════════════════════════════════════════════════
// ASSISTANT IA PARENT
// Analyse les notes de l'enfant et alerte en temps réel sur ses performances.
// ════════════════════════════════════════════════════════════════════════════
class ParentAssistantIAScreen extends StatefulWidget {
  const ParentAssistantIAScreen({super.key, required this.nomEnfant});

  final String nomEnfant;

  @override
  State<ParentAssistantIAScreen> createState() =>
      _ParentAssistantIAScreenState();
}

class _ParentAssistantIAScreenState extends State<ParentAssistantIAScreen> {
  final List<_Message> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _enChargement = false;

  // Notes de l'enfant (mêmes données que l'onglet Notes du parent)
  final List<Map<String, dynamic>> _notes = [
    {'matiere': 'Mathématiques Appliquées', 'note': 15.5},
    {'matiere': 'Réseaux Informatiques', 'note': 12.0},
    {'matiere': 'Programmation Orientée Objet', 'note': 9.5},
    {'matiere': 'Anglais Technique', 'note': 8.0},
  ];

  double get _moyenne =>
      _notes.map((n) => n['note'] as double).reduce((a, b) => a + b) /
      _notes.length;

  List<Map<String, dynamic>> get _modulesEnDanger =>
      _notes.where((n) => (n['note'] as double) < 10).toList();

  List<Map<String, dynamic>> get _modulesASurveiller => _notes
      .where((n) => (n['note'] as double) >= 10 && (n['note'] as double) < 12)
      .toList();

  // Contexte transmis à l'IA avec chaque question du parent
  String get _contexteEnfant {
    final detail = _notes
        .map((n) => '${n['matiere']} : ${n['note']}/20')
        .join(', ');
    return 'Tu parles au parent de ${widget.nomEnfant}, étudiant(e) en Licence '
        'Informatique. Notes actuelles : $detail. Moyenne générale : '
        '${_moyenne.toStringAsFixed(2)}/20. Réponds en tant que conseiller '
        'pédagogique qui aide ce parent à suivre et améliorer les performances '
        'de son enfant.';
  }

  final List<Map<String, String>> _suggestions = [
    {
      'texte': '📊 Analyse ses notes',
      'query':
          'Analyse les notes de mon enfant et explique-moi sa situation académique.',
    },
    {
      'texte': '🚨 Matières en difficulté',
      'query':
          'Quelles matières de mon enfant nécessitent une attention urgente et pourquoi ?',
    },
    {
      'texte': '🏠 Comment l\'aider à la maison',
      'query':
          'Comment puis-je aider mon enfant à progresser à la maison, concrètement ?',
    },
    {
      'texte': '📅 Plan de soutien',
      'query':
          'Propose un plan de soutien sur un mois pour remonter ses notes faibles.',
    },
    {
      'texte': '✅ Ses points forts',
      'query':
          'Quels sont les points forts de mon enfant et comment les encourager ?',
    },
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      _Message(
        texte: _bilanInitial(),
        estIA: true,
        heure: DateTime.now(),
      ),
    );
  }

  String _bilanInitial() {
    final danger = _modulesEnDanger;
    final surveiller = _modulesASurveiller;
    final buffer = StringBuffer()
      ..writeln('Bonjour ! 👋')
      ..writeln('')
      ..writeln(
          'Je suis l\'assistant IA de suivi de **${widget.nomEnfant}**. J\'analyse ses notes en continu et je vous alerte dès qu\'une performance évolue.')
      ..writeln('')
      ..writeln('**Bilan en temps réel :**')
      ..writeln(
          '• Moyenne générale : **${_moyenne.toStringAsFixed(2)}/20**');
    for (final n in danger) {
      buffer.writeln('• 🚨 ${n['matiere']} : **${n['note']}/20** — en danger');
    }
    for (final n in surveiller) {
      buffer.writeln(
          '• ⚠️ ${n['matiere']} : **${n['note']}/20** — à surveiller');
    }
    buffer
      ..writeln('')
      ..writeln('Comment puis-je vous aider aujourd\'hui ?');
    return buffer.toString();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Appel API IA (backend /api/ia/chat) ───────────────────────────────
  Future<void> _envoyer(String texte) async {
    if (texte.trim().isEmpty || _enChargement) return;

    final messageUser = texte.trim();
    _inputCtrl.clear();

    setState(() {
      _messages.add(
        _Message(texte: messageUser, estIA: false, heure: DateTime.now()),
      );
      _enChargement = true;
    });
    _scrollBas();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('http://localhost:5000/api/ia/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': '[$_contexteEnfant]\n\n$messageUser'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final reponse = data['reponse'] as String;
        setState(() {
          _messages.add(
            _Message(texte: reponse, estIA: true, heure: DateTime.now()),
          );
          _enChargement = false;
        });
      } else {
        _ajouterErreur('Erreur ${response.statusCode}. Réessayez plus tard.');
      }
    } catch (e) {
      _ajouterErreur('Connexion impossible. Vérifiez votre réseau.');
    }

    _scrollBas();
  }

  void _ajouterErreur(String msg) {
    setState(() {
      _messages.add(
        _Message(
          texte: msg,
          estIA: true,
          heure: DateTime.now(),
          estErreur: true,
        ),
      );
      _enChargement = false;
    });
  }

  void _scrollBas() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _bandeauAlertes(),
            if (_messages.length == 1) _suggestionsRapides(),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: _messages.length + (_enChargement ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _messages.length) return _bulleChargement();
                  return _bulleMessage(_messages[i]);
                },
              ),
            ),
            _zoneSaisie(),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A3D91), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assistant IA Parent',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4ADE80),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Surveillance en temps réel — ${widget.nomEnfant}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text('Moy.',
                    style: TextStyle(fontSize: 10, color: Colors.white70)),
                Text(
                  _moyenne.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bandeau d'alertes performance (temps réel) ──────────────────────────
  Widget _bandeauAlertes() {
    final alertes = <Widget>[];
    for (final n in _modulesEnDanger) {
      alertes.add(_puceAlerte(
        icon: Icons.error_rounded,
        couleur: const Color(0xFFC62828),
        texte: '${n['matiere']} : ${n['note']}/20',
      ));
    }
    for (final n in _modulesASurveiller) {
      alertes.add(_puceAlerte(
        icon: Icons.warning_rounded,
        couleur: const Color(0xFFD97706),
        texte: '${n['matiere']} : ${n['note']}/20',
      ));
    }
    if (alertes.isEmpty) {
      alertes.add(_puceAlerte(
        icon: Icons.check_circle_rounded,
        couleur: const Color(0xFF15803D),
        texte: 'Aucune alerte : toutes les notes sont bonnes 🎉',
      ));
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.notifications_active_rounded,
                  size: 16, color: Color(0xFFC62828)),
              SizedBox(width: 6),
              Text(
                'Alertes performance',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < alertes.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  alertes[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _puceAlerte({
    required IconData icon,
    required Color couleur,
    required String texte,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: couleur),
          const SizedBox(width: 6),
          Text(
            texte,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: couleur,
            ),
          ),
        ],
      ),
    );
  }

  // ── Suggestions ─────────────────────────────────────────────────────────
  Widget _suggestionsRapides() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Questions fréquentes',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map(
                  (s) => GestureDetector(
                    onTap: () => _envoyer(s['query']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppPalette.lightBlue,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppPalette.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        s['texte']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppPalette.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Zone de saisie ──────────────────────────────────────────────────────
  Widget _zoneSaisie() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _inputCtrl,
                maxLines: 3,
                minLines: 1,
                onSubmitted: _envoyer,
                style:
                    const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                decoration: const InputDecoration(
                  hintText: 'Posez votre question sur votre enfant...',
                  hintStyle:
                      TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _enChargement ? null : () => _envoyer(_inputCtrl.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _enChargement
                    ? const Color(0xFFE2E8F0)
                    : AppPalette.blue,
                shape: BoxShape.circle,
                boxShadow: _enChargement
                    ? []
                    : [
                        BoxShadow(
                          color: AppPalette.blue.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Icon(
                _enChargement ? Icons.hourglass_empty : Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bulles ──────────────────────────────────────────────────────────────
  Widget _bulleMessage(_Message msg) {
    final estIA = msg.estIA;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            estIA ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (estIA) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: msg.estErreur
                    ? const Color(0xFFEF4444)
                    : AppPalette.blue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                msg.estErreur ? Icons.error_outline : Icons.smart_toy_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  estIA ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: msg.estErreur
                        ? const Color(0xFFFFEBEE)
                        : estIA
                            ? Colors.white
                            : AppPalette.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(estIA ? 4 : 18),
                      bottomRight: Radius.circular(estIA ? 18 : 4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: estIA && !msg.estErreur
                        ? Border.all(color: const Color(0xFFE2E8F0))
                        : null,
                  ),
                  child: _texteFormate(
                    msg.texte,
                    couleur: msg.estErreur
                        ? const Color(0xFFC62828)
                        : estIA
                            ? const Color(0xFF0F172A)
                            : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatHeure(msg.heure),
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          if (!estIA) ...[
            const SizedBox(width: 10),
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppPalette.yellow,
              child: Icon(Icons.family_restroom,
                  size: 18, color: AppPalette.blue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bulleChargement() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppPalette.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(),
                const SizedBox(width: 5),
                _dot(),
                const SizedBox(width: 5),
                _dot(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.4, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        builder: (_, v, __) => Opacity(
          opacity: v,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppPalette.blue,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );

  // ── Texte formaté (gère **gras** et retours à la ligne) ─────────────────
  Widget _texteFormate(String texte, {required Color couleur}) {
    final lignes = texte.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lignes.map((ligne) {
        if (ligne.contains('**')) {
          final parts = ligne.split('**');
          return Wrap(
            children: parts
                .asMap()
                .entries
                .map(
                  (e) => Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 15,
                      color: couleur,
                      height: 1.55,
                      fontWeight:
                          e.key.isOdd ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                )
                .toList(),
          );
        }
        return Text(
          ligne,
          style: TextStyle(fontSize: 15, color: couleur, height: 1.55),
        );
      }).toList(),
    );
  }

  String _formatHeure(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

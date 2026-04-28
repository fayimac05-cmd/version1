import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/student_profile.dart';
import '../theme/app_palette.dart';

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
// PAGE CHAT IA
// ════════════════════════════════════════════════════════════════════════════
class ChatIAScreen extends StatefulWidget {
  final StudentProfile profile;
  const ChatIAScreen({super.key, required this.profile});

  @override
  State<ChatIAScreen> createState() => _ChatIAScreenState();
}

class _ChatIAScreenState extends State<ChatIAScreen> {

  final List<_Message>     _messages     = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController   _scrollCtrl   = ScrollController();
  bool _enChargement = false;

  // ── Contexte académique d'Ibrahim passé à Claude ─────────────────────
  String get _contexteEtudiant => '''
Tu es le conseiller académique IA de ScolarHub pour l'IST (Institut Supérieur de Technologies), Campus Ouaga 2000, Burkina Faso.

Étudiant : ${widget.profile.prenoms} ${widget.profile.nom}
Matricule : ${widget.profile.matricule}
Filière : ${widget.profile.filiere}
Domaine : ${widget.profile.domaine.isNotEmpty ? widget.profile.domaine : 'Sciences & Technologies'}
Niveau : Licence 2 — Semestre 3 — Année 2024/2025

Notes actuelles :
- Algorithmique & Structures de données (INFO101) : 14.5/20 — Coeff 3 ✅ Validé
- Base de données (INFO102) : 8.0/20 — Coeff 3 ⚠️ En danger
- Réseaux informatiques (INFO103) : 4.5/20 — Coeff 2 🚨 Blâmable
- Mathématiques discrètes (MATH201) : 12.0/20 — Coeff 2 ✅ Validé
- Anglais technique (ANG101) : 16.0/20 — Coeff 1 ✅ Validé
- Programmation Orientée Objet (INFO104) : 9.5/20 — Coeff 3 ⚠️ En danger
- Systèmes d\'exploitation (INFO105) : En attente — Coeff 2
Moyenne générale pondérée : ~10.6/20 (modules notés)

Ton rôle :
- Analyser la situation académique de l\'étudiant
- Proposer des plans de révision personnalisés
- Féliciter les bons résultats
- Alerter sur les modules critiques (Réseaux : 4.5/20 — urgence !)
- Donner des conseils de méthode de travail
- Répondre en français, de manière bienveillante et motivante
- Être précis, concret et adapté au contexte burkinabè
- Ne jamais inventer des notes ou des informations non fournies
- Répondre de façon concise (max 200 mots sauf si demande détaillée)
''';

  // ── Questions suggérées ───────────────────────────────────────────────
  final List<Map<String, dynamic>> _suggestions = [
    {'texte': '📊 Analyse mes notes', 'query': 'Analyse ma situation académique actuelle et dis-moi comment je me situe.'},
    {'texte': '🚨 Module en danger', 'query': 'J\'ai 4.5/20 en Réseaux informatiques. Que dois-je faire en urgence ?'},
    {'texte': '📅 Plan de révision', 'query': 'Crée-moi un plan de révision personnalisé pour rattraper mes modules en difficulté.'},
    {'texte': '✅ Points positifs', 'query': 'Quels sont mes points forts cette année ? Comment les maintenir ?'},
    {'texte': '🎯 Objectifs S4', 'query': 'Pour le semestre 4, quels objectifs dois-je me fixer pour valider mon année ?'},
    {'texte': '📝 Conseil POO', 'query': 'J\'ai 9.5/20 en Programmation OO. Comment progresser rapidement ?'},
  ];

  @override
  void initState() {
    super.initState();
    // Message de bienvenue
    _messages.add(_Message(
      texte: 'Bonjour ${widget.profile.prenoms} ! 👋\n\n'
          'Je suis ton conseiller académique IA. J\'ai accès à ton bilan du Semestre 3.\n\n'
          '**Situation rapide :**\n'
          '• ✅ 3 modules validés\n'
          '• ⚠️ 2 modules en danger\n'
          '• 🚨 1 module blâmable (Réseaux : 4.5/20)\n\n'
          'Comment puis-je t\'aider aujourd\'hui ?',
      estIA: true,
      heure: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Appel API Claude ──────────────────────────────────────────────────
  Future<void> _envoyer(String texte) async {
    if (texte.trim().isEmpty || _enChargement) return;

    final messageUser = texte.trim();
    _inputCtrl.clear();

    setState(() {
      _messages.add(_Message(texte: messageUser, estIA: false, heure: DateTime.now()));
      _enChargement = true;
    });
    _scrollBas();

    try {
      // Construire l'historique pour Claude
      final List<Map<String, String>> historique = [];
      for (final msg in _messages.where((m) => !m.estErreur)) {
        historique.add({
          'role': msg.estIA ? 'assistant' : 'user',
          'content': msg.texte,
        });
      }

      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 600,
          'system': _contexteEtudiant,
          'messages': historique,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reponse = data['content'][0]['text'] as String;
        setState(() {
          _messages.add(_Message(texte: reponse, estIA: true, heure: DateTime.now()));
          _enChargement = false;
        });
      } else {
        _ajouterErreur('Erreur ${response.statusCode}. Réessayez dans un instant.');
      }
    } catch (e) {
      _ajouterErreur('Connexion impossible. Vérifiez votre réseau.');
    }

    _scrollBas();
  }

  void _ajouterErreur(String msg) {
    setState(() {
      _messages.add(_Message(texte: msg, estIA: true, heure: DateTime.now(), estErreur: true));
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

  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(children: [

        // ── Header ────────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Conseiller IA', style: TextStyle(fontSize: 20,
                  fontWeight: FontWeight.bold, color: Colors.white,
                  letterSpacing: -0.3)),
              const SizedBox(height: 3),
              Row(children: [
                Container(width: 8, height: 8,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFF4ADE80)),
                ),
                const SizedBox(width: 6),
                const Text('En ligne — Analyse basée sur tes notes',
                    style: TextStyle(fontSize: 12, color: Colors.white70)),
              ]),
            ])),
            // Badge notes
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(children: [
                const Text('Moy.', style: TextStyle(fontSize: 10, color: Colors.white70)),
                const Text('10.6', style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.bold, color: Colors.white)),
              ]),
            ),
          ]),
        ),

        // ── Suggestions rapides (seulement si 1 message) ──────────────
        if (_messages.length == 1)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Questions fréquentes',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B))),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8,
                children: _suggestions.map((s) => GestureDetector(
                  onTap: () => _envoyer(s['query']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                    ),
                    child: Text(s['texte']!,
                        style: const TextStyle(fontSize: 13,
                            color: Color(0xFF7C3AED), fontWeight: FontWeight.w600)),
                  ),
                )).toList(),
              ),
            ]),
          ),

        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // ── Messages ──────────────────────────────────────────────────
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

        // ── Zone de saisie ────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                blurRadius: 10, offset: const Offset(0, -2))],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                  maxLines: 3,
                  minLines: 1,
                  onSubmitted: _envoyer,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    hintText: 'Pose ta question...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _enChargement ? null : () => _envoyer(_inputCtrl.text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: _enChargement
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF7C3AED),
                  shape: BoxShape.circle,
                  boxShadow: _enChargement ? [] : [
                    BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.4),
                        blurRadius: 8, offset: const Offset(0, 3))
                  ],
                ),
                child: Icon(
                  _enChargement ? Icons.hourglass_empty : Icons.send_rounded,
                  color: Colors.white, size: 22,
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Bulle message ─────────────────────────────────────────────────────
  Widget _bulleMessage(_Message msg) {
    final estIA = msg.estIA;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: estIA ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [

          if (estIA) ...[
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: msg.estErreur
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF7C3AED),
                shape: BoxShape.circle,
              ),
              child: Icon(
                msg.estErreur ? Icons.error_outline : Icons.smart_toy_rounded,
                color: Colors.white, size: 18,
              ),
            ),
            const SizedBox(width: 10),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: estIA
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: msg.estErreur
                        ? const Color(0xFFFFEBEE)
                        : estIA
                            ? Colors.white
                            : const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.only(
                      topLeft:    const Radius.circular(18),
                      topRight:   const Radius.circular(18),
                      bottomLeft: Radius.circular(estIA ? 4 : 18),
                      bottomRight: Radius.circular(estIA ? 18 : 4),
                    ),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8, offset: const Offset(0, 2))],
                    border: estIA && !msg.estErreur
                        ? Border.all(color: const Color(0xFFE2E8F0))
                        : null,
                  ),
                  child: _texteFormate(msg.texte,
                      couleur: msg.estErreur
                          ? const Color(0xFFC62828)
                          : estIA
                              ? const Color(0xFF0F172A)
                              : Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatHeure(msg.heure),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          if (!estIA) ...[
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppPalette.yellow,
              child: Text(
                '${widget.profile.prenoms[0]}${widget.profile.nom[0]}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                    color: AppPalette.blue),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Bulle chargement ──────────────────────────────────────────────────
  Widget _bulleChargement() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(width: 36, height: 36,
          decoration: const BoxDecoration(
              color: Color(0xFF7C3AED), shape: BoxShape.circle),
          child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _dot(0), const SizedBox(width: 5),
            _dot(200), const SizedBox(width: 5),
            _dot(400),
          ]),
        ),
      ]),
    );
  }

  Widget _dot(int delayMs) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.4, end: 1.0),
    duration: const Duration(milliseconds: 600),
    curve: Curves.easeInOut,
    builder: (_, v, __) => Opacity(
      opacity: v,
      child: Container(width: 8, height: 8,
          decoration: const BoxDecoration(
              color: Color(0xFF7C3AED), shape: BoxShape.circle)),
    ),
  );

  // ── Texte formaté (gère **bold** et \n) ──────────────────────────────
  Widget _texteFormate(String texte, {required Color couleur}) {
    final lignes = texte.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lignes.map((ligne) {
        if (ligne.contains('**')) {
          final parts = ligne.split('**');
          return Wrap(children: parts.asMap().entries.map((e) => Text(
            e.value,
            style: TextStyle(
              fontSize: 15, color: couleur, height: 1.55,
              fontWeight: e.key.isOdd ? FontWeight.bold : FontWeight.normal,
            ),
          )).toList());
        }
        return Text(ligne, style: TextStyle(
            fontSize: 15, color: couleur, height: 1.55));
      }).toList(),
    );
  }

  String _formatHeure(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

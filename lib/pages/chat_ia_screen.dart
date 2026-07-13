import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/student_profile.dart';
import '../theme/app_palette.dart';

import 'package:shared_preferences/shared_preferences.dart';

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

  Map<String, dynamic> toJson() => {
    'texte': texte,
    'estIA': estIA,
    'heure': heure.toIso8601String(),
    'estErreur': estErreur,
  };

  factory _Message.fromJson(Map<String, dynamic> json) => _Message(
    texte: json['texte'] as String,
    estIA: json['estIA'] as bool,
    heure: DateTime.parse(json['heure'] as String),
    estErreur: json['estErreur'] as bool? ?? false,
  );
}

// ════════════════════════════════════════════════════════════════════════════
// PAGE CHAT IA
// ════════════════════════════════════════════════════════════════════════════
class ChatIAScreen extends StatefulWidget {
  final StudentProfile profile;
  final bool showBack;
  const ChatIAScreen({super.key, required this.profile, this.showBack = true});

  @override
  State<ChatIAScreen> createState() => _ChatIAScreenState();
}

class _ChatIAScreenState extends State<ChatIAScreen> {
  final List<_Message> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _enChargement = false;

  // ── Questions suggérées ───────────────────────────────────────────────
  // Chaque question possède une réponse locale ('reponse') utilisée en mode
  // hors ligne, quand le serveur ou l'IA est indisponible.
  final List<Map<String, dynamic>> _suggestions = [
    {
      'texte': '📊 Analyse mes notes',
      'query':
          'Analyse ma situation académique actuelle et dis-moi comment je me situe.',
      'reponse':
          'Voici comment analyser ta situation académique toi-même :\n\n'
          '**1. Consulte tes résultats** dans l\'onglet Résultats ou Bulletins de l\'app.\n\n'
          '**2. Classe tes modules en 3 catégories :**\n'
          '• ✅ Validés (moyenne ≥ 10) : maintiens le rythme\n'
          '• ⚠️ En danger (entre 8 et 10) : quelques efforts ciblés suffisent\n'
          '• 🚨 Critiques (< 8) : priorité absolue pour le rattrapage\n\n'
          '**3. Vérifie les coefficients** : un module à fort coefficient pèse plus dans ta moyenne générale. Concentre tes efforts là où l\'impact est le plus grand.\n\n'
          '💡 Pour une analyse personnalisée détaillée, reviens me voir quand la connexion sera rétablie.',
    },
    {
      'texte': '🚨 Module en danger',
      'query':
          'J\'ai un module en grande difficulté. Que dois-je faire en urgence ?',
      'reponse':
          'Plan d\'urgence pour un module en difficulté :\n\n'
          '**Cette semaine :**\n'
          '• Identifie précisément les chapitres où tu perds des points (reprends tes copies)\n'
          '• Parle au professeur : demande-lui les points essentiels à maîtriser\n'
          '• Trouve un camarade fort dans ce module pour réviser en binôme\n\n'
          '**Les 2 semaines suivantes :**\n'
          '• 45 min par jour sur CE module, en commençant par les bases\n'
          '• Refais les TD et anciens sujets d\'examen, pas seulement le cours\n'
          '• Note chaque erreur dans un carnet et relis-le avant chaque séance\n\n'
          '**À l\'examen :** commence par les questions que tu maîtrises pour sécuriser des points.\n\n'
          '💪 Un module se rattrape presque toujours quand on s\'y prend avant les examens.',
    },
    {
      'texte': '📅 Plan de révision',
      'query':
          'Crée-moi un plan de révision personnalisé pour rattraper mes modules en difficulté.',
      'reponse':
          'Voici une méthode de plan de révision efficace :\n\n'
          '**Étape 1 — Fais le bilan (30 min)**\n'
          'Liste tes modules du plus faible au plus fort avec leurs coefficients.\n\n'
          '**Étape 2 — Répartis ton temps (règle 50/30/20)**\n'
          '• 50 % du temps sur les modules critiques\n'
          '• 30 % sur les modules moyens\n'
          '• 20 % pour entretenir tes points forts\n\n'
          '**Étape 3 — Planifie des sessions courtes**\n'
          '• 2 à 3 sessions de 45 min par jour valent mieux qu\'une nuit blanche\n'
          '• Alterne les matières pour rester concentré(e)\n'
          '• Garde une demi-journée de repos par semaine\n\n'
          '**Étape 4 — Contrôle chaque dimanche**\n'
          'Teste-toi sur ce que tu as révisé : si tu ne peux pas l\'expliquer simplement, ce n\'est pas acquis.\n\n'
          '📌 La régularité bat l\'intensité : 3 semaines de travail constant transforment une moyenne.',
    },
    {
      'texte': '✅ Points positifs',
      'query':
          'Quels sont mes points forts cette année ? Comment les maintenir ?',
      'reponse':
          'Pour identifier et entretenir tes points forts :\n\n'
          '**Les repérer :**\n'
          '• Les modules où ta moyenne dépasse 12 sans effort excessif\n'
          '• Les matières où tu aides spontanément les autres\n'
          '• Les cours où tu poses des questions parce que ça t\'intéresse\n\n'
          '**Les maintenir sans y passer trop de temps :**\n'
          '• Une révision rapide hebdomadaire suffit (20-30 min)\n'
          '• Reste actif en cours : c\'est ta meilleure révision gratuite\n'
          '• Explique les notions aux camarades — enseigner, c\'est consolider\n\n'
          '**Les valoriser :**\n'
          '• Ces modules sécurisent ta moyenne générale et compensent les plus faibles\n'
          '• Ils orientent souvent vers ta future spécialisation : note ce qui te plaît vraiment.\n\n'
          '🌟 Un point fort entretenu est une assurance pour tes examens.',
    },
    {
      'texte': '🎯 Objectifs semestre',
      'query':
          'Pour le prochain semestre, quels objectifs dois-je me fixer pour valider mon année ?',
      'reponse':
          'Comment fixer de bons objectifs pour le semestre :\n\n'
          '**1. L\'objectif chiffré**\n'
          'Calcule la moyenne nécessaire pour valider ton année, puis fixe-toi un objectif légèrement au-dessus (marge de sécurité de 1 point).\n\n'
          '**2. Décompose par module**\n'
          '• Modules critiques : viser d\'abord 10, pas 15\n'
          '• Modules moyens : gagner 1 à 2 points\n'
          '• Points forts : maintenir le niveau\n\n'
          '**3. Des objectifs de moyens, pas seulement de résultats**\n'
          '• « Assister à tous les TD » dépend de toi à 100 %\n'
          '• « Rendre tous les devoirs à temps » aussi\n'
          '• Les notes suivront ces habitudes\n\n'
          '**4. Un point d\'étape par mois**\n'
          'Compare tes notes de contrôle continu à ton objectif et ajuste.\n\n'
          '🎯 Un objectif réaliste et suivi vaut mieux qu\'une ambition abandonnée en semaine 2.',
    },
    {
      'texte': '📝 Méthode de travail',
      'query':
          'Comment progresser rapidement dans un module technique difficile ?',
      'reponse':
          'Méthode pour progresser vite dans un module technique :\n\n'
          '**1. La pratique avant la théorie**\n'
          'Dans les matières techniques (programmation, réseaux, électronique…), on apprend en faisant : refais chaque TP jusqu\'à le réussir sans aide.\n\n'
          '**2. La règle des 20 minutes**\n'
          'Bloqué(e) sur un exercice ? Cherche seul(e) 20 minutes maximum, puis demande de l\'aide (camarade, professeur, documentation). Rester bloqué des heures démotive sans faire progresser.\n\n'
          '**3. Le carnet d\'erreurs**\n'
          'Note chaque erreur rencontrée et sa solution. Le relire avant un examen vaut toutes les fiches de révision.\n\n'
          '**4. Expliquer pour vérifier**\n'
          'Si tu peux expliquer une notion à un camarade sans notes, elle est acquise. Sinon, retravaille-la.\n\n'
          '⚡ 30 minutes de pratique quotidienne battent 4 heures le week-end.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _chargerHistorique();
  }

  Future<void> _chargerHistorique() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('chat_history');
    if (data != null && data.isNotEmpty) {
      setState(() {
        _messages.clear();
        for (var msgJson in data) {
          try {
            _messages.add(_Message.fromJson(jsonDecode(msgJson)));
          } catch (e) {
            // Ignorer les erreurs de parsing
          }
        }
      });
      // Scroll to bottom après le chargement
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollBas());
    } else {
      // Message de bienvenue initial
      setState(() {
        _messages.add(
          _Message(
            texte:
                'Bonjour ${widget.profile.prenoms} ! 👋\n\n'
                'Je suis ton conseiller académique IA. J\'ai accès à ton bilan du Semestre 3.\n\n'
                '**Situation rapide :**\n'
                '• ✅ 3 modules validés\n'
                '• ⚠️ 2 modules en danger\n'
                '• 🚨 1 module blâmable (Réseaux : 4.5/20)\n\n'
                'Comment puis-je t\'aider aujourd\'hui ?',
            estIA: true,
            heure: DateTime.now(),
          ),
        );
      });
    }
  }

  Future<void> _sauvegarderHistorique() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _messages.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList('chat_history', data);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Appel API Claude / OpenAI ─────────────────────────────────────────
  // [reponseHorsLigne] : réponse locale affichée si le serveur ou l'IA est
  // indisponible (mode hors ligne des questions suggérées).
  Future<void> _envoyer(String texte, {String? reponseHorsLigne}) async {
    if (texte.trim().isEmpty || _enChargement) return;

    final messageUser = texte.trim();
    _inputCtrl.clear();

    setState(() {
      _messages.add(
        _Message(texte: messageUser, estIA: false, heure: DateTime.now()),
      );
      _enChargement = true;
    });
    _sauvegarderHistorique();
    _scrollBas();

    try {
      // Use the backend /api/ia/chat endpoint to avoid exposing API keys in the client
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('http://localhost:5000/api/ia/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': messageUser}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String reponse = data['reponse'] as String;

        setState(() {
          _messages.add(
            _Message(texte: reponse, estIA: true, heure: DateTime.now()),
          );
          _enChargement = false;
        });
        _sauvegarderHistorique();
      } else if (reponseHorsLigne != null) {
        _ajouterReponseHorsLigne(reponseHorsLigne);
      } else {
        _ajouterErreur(
          'Erreur ${response.statusCode}. Vérifiez votre clé API.',
        );
      }
    } catch (e) {
      if (reponseHorsLigne != null) {
        _ajouterReponseHorsLigne(reponseHorsLigne);
      } else {
        _ajouterErreur('Connexion impossible. Vérifiez votre réseau.');
      }
    }

    _scrollBas();
  }

  void _ajouterReponseHorsLigne(String reponse) {
    setState(() {
      _messages.add(
        _Message(
          texte: '📡 **Mode hors ligne** — conseil général, l\'assistant IA '
              'est momentanément indisponible.\n\n$reponse',
          estIA: true,
          heure: DateTime.now(),
        ),
      );
      _enChargement = false;
    });
    _sauvegarderHistorique();
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
    _sauvegarderHistorique();
  }

  Widget _puceSuggestion(Map<String, dynamic> s) {
    return GestureDetector(
      onTap: () => _envoyer(
        s['query'] as String,
        reponseHorsLigne: s['reponse'] as String?,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          s['texte'] as String,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF7C3AED),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
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
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
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
            child: Stack(children: [
              Positioned(top: -20, right: -20,
                child: Container(width: 100, height: 100,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06)))),
              Row(
              children: [
                if (widget.showBack)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Conseiller IA',
                        style: TextStyle(
                          fontSize: 20,
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
                          const Text(
                            'En ligne — Analyse basée sur tes notes',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge notes
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Moy.',
                        style: TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                      const Text(
                        '10.6',
                        style: TextStyle(
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
            ]),
          ),

          // ── Suggestions rapides (toujours accessibles) ────────────────
          // Grille complète au premier message, puis rangée horizontale
          // compacte pour rester disponibles à tout moment (mode hors ligne).
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                if (_messages.length <= 1)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _suggestions.map((s) => _puceSuggestion(s)).toList(),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _suggestions
                          .map((s) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _puceSuggestion(s),
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.06),
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
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Pose ta question...',
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
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
                          : const Color(0xFF7C3AED),
                      shape: BoxShape.circle,
                      boxShadow: _enChargement
                          ? []
                          : [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withValues(alpha:0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: Icon(
                      _enChargement
                          ? Icons.hourglass_empty
                          : Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
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

  // ── Bulle message ─────────────────────────────────────────────────────
  Widget _bulleMessage(_Message msg) {
    final estIA = msg.estIA;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: estIA
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (estIA) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: msg.estErreur
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF7C3AED),
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
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(estIA ? 4 : 18),
                      bottomRight: Radius.circular(estIA ? 18 : 4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.06),
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
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.blue,
                ),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF7C3AED),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 18,
            ),
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
                  color: Colors.black.withValues(alpha:0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                const SizedBox(width: 5),
                _dot(200),
                const SizedBox(width: 5),
                _dot(400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delayMs) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.4, end: 1.0),
    duration: const Duration(milliseconds: 600),
    curve: Curves.easeInOut,
    builder: (_, v, __) => Opacity(
      opacity: v,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF7C3AED),
          shape: BoxShape.circle,
        ),
      ),
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
                      fontWeight: e.key.isOdd
                          ? FontWeight.bold
                          : FontWeight.normal,
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

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';

/// Assistant IA de révision : liste les cours de la filière de l'étudiant
/// et génère, pour chacun, un quiz interactif ou une fiche de révision.
class RevisionIAScreen extends StatefulWidget {
  const RevisionIAScreen({super.key});

  @override
  State<RevisionIAScreen> createState() => _RevisionIAScreenState();
}

class _RevisionIAScreenState extends State<RevisionIAScreen> {
  List<dynamic> _supports = [];
  bool _loading = true;
  bool _offline = false;
  String? _error;
  String? _generatingId; // id du support en cours de génération

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ApiService.getSupportsRevision();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _offline = result['offline'] == true;
      if (result['success'] == true) {
        _supports = result['data'] as List<dynamic>;
      } else {
        _error = result['error'];
      }
    });
  }

  Future<void> _generer(Map<String, dynamic> support, String type) async {
    setState(() => _generatingId = support['id'].toString());
    final result = await ApiService.genererRevision(support['id'].toString(), type);
    if (!mounted) return;
    setState(() => _generatingId = null);

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'] ?? 'Erreur lors de la génération.'),
          backgroundColor: Colors.red));
      return;
    }

    if (type == 'quiz') {
      final questions = (result['quiz']?['questions'] as List<dynamic>?) ?? [];
      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Quiz vide, réessayez.'), backgroundColor: Colors.red));
        return;
      }
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => _QuizScreen(titre: support['titre'], questions: questions)));
    } else {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => _FicheScreen(titre: support['titre'], fiche: result['fiche'] ?? '')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Révisions IA',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppPalette.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_offline)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10)),
                child: const Row(children: [
                  Icon(Icons.wifi_off_rounded, size: 18, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Expanded(child: Text('Mode hors-ligne : dernières données connues.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E)))),
                ]),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF0A3D91), Color(0xFF1565C0)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Choisis un cours : l\'IA génère un quiz de 5 questions ou une fiche de révision à partir de son contenu.',
                    style: TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator())),
            if (!_loading && _error != null)
              Padding(padding: const EdgeInsets.all(24),
                  child: Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))),
            if (!_loading && _error == null && _supports.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text(
                    'Aucun cours disponible pour votre filière pour le moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B)))),
              ),
            ..._supports.map((s) => _supportCard(s as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }

  Widget _supportCard(Map<String, dynamic> s) {
    final enCours = _generatingId == s['id'].toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
                color: AppPalette.lightBlue, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.menu_book_rounded, color: AppPalette.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s['titre'] ?? '',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 2),
              Text(s['module_nom'] ?? '',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        if (enCours)
          const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Text('L\'IA prépare ta révision...',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ]),
          ))
        else
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _generer(s, 'quiz'),
                icon: const Icon(Icons.quiz_outlined, size: 16),
                label: const Text('Quiz', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.blue,
                  side: const BorderSide(color: AppPalette.blue),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _generer(s, 'fiche'),
                icon: const Icon(Icons.summarize_outlined, size: 16),
                label: const Text('Fiche', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ),
          ]),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Quiz interactif
// ═══════════════════════════════════════════════════════════════

class _QuizScreen extends StatefulWidget {
  const _QuizScreen({required this.titre, required this.questions});
  final String? titre;
  final List<dynamic> questions;

  @override
  State<_QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<_QuizScreen> {
  int _index = 0;
  int _score = 0;
  int? _selection; // choix sélectionné pour la question courante
  bool _repondu = false;
  bool _termine = false;

  Map<String, dynamic> get _question =>
      widget.questions[_index] as Map<String, dynamic>;

  void _valider(int choix) {
    if (_repondu) return;
    setState(() {
      _selection = choix;
      _repondu = true;
      if (choix == (_question['bonne_reponse'] ?? -1)) _score++;
    });
  }

  void _suivant() {
    if (_index + 1 >= widget.questions.length) {
      setState(() => _termine = true);
    } else {
      setState(() {
        _index++;
        _selection = null;
        _repondu = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Quiz — ${widget.titre ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppPalette.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _termine ? _resultat() : _questionView(),
    );
  }

  Widget _resultat() {
    final total = widget.questions.length;
    final pct = total > 0 ? (_score / total * 100).round() : 0;
    final ok = pct >= 60;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (ok ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                  .withValues(alpha: 0.12),
            ),
            child: Center(
              child: Text('$_score/$total',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                      color: ok ? const Color(0xFF10B981) : const Color(0xFFF59E0B))),
            ),
          ),
          const SizedBox(height: 20),
          Text(ok ? 'Bien joué ! 🎉' : 'Continue à réviser 💪',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text('Tu as obtenu $pct% de bonnes réponses.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retour aux cours',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _questionView() {
    final choix = (_question['choix'] as List<dynamic>?) ?? [];
    final bonne = _question['bonne_reponse'] ?? -1;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LinearProgressIndicator(
          value: (_index + 1) / widget.questions.length,
          backgroundColor: const Color(0xFFE2E8F0),
          color: AppPalette.blue,
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 14),
        Text('Question ${_index + 1}/${widget.questions.length}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        Text(_question['question'] ?? '',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A), height: 1.4)),
        const SizedBox(height: 20),
        ...List.generate(choix.length, (i) {
          Color border = const Color(0xFFE2E8F0);
          Color bg = Colors.white;
          if (_repondu) {
            if (i == bonne) {
              border = const Color(0xFF10B981);
              bg = const Color(0xFFECFDF5);
            } else if (i == _selection) {
              border = const Color(0xFFEF4444);
              bg = const Color(0xFFFEF2F2);
            }
          } else if (i == _selection) {
            border = AppPalette.blue;
          }
          return GestureDetector(
            onTap: () => _valider(i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border, width: 1.5),
              ),
              child: Row(children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppPalette.lightBlue,
                  ),
                  child: Center(child: Text(String.fromCharCode(65 + i),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: AppPalette.blue))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('${choix[i]}',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)))),
                if (_repondu && i == bonne)
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                if (_repondu && i == _selection && i != bonne)
                  const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 20),
              ]),
            ),
          );
        }),
        if (_repondu && (_question['explication'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppPalette.blue),
              const SizedBox(width: 8),
              Expanded(child: Text('${_question['explication']}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1E3A8A), height: 1.4))),
            ]),
          ),
        ],
        if (_repondu) ...[
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _suivant,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _index + 1 >= widget.questions.length ? 'Voir mon score' : 'Question suivante',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Fiche de révision
// ═══════════════════════════════════════════════════════════════

class _FicheScreen extends StatelessWidget {
  const _FicheScreen({required this.titre, required this.fiche});
  final String? titre;
  final String fiche;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Fiche — ${titre ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppPalette.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          // Rendu Markdown simplifié : titres et gras mis en évidence.
          child: SelectableText.rich(
            TextSpan(children: _renduSimple(fiche)),
          ),
        ),
      ),
    );
  }

  List<TextSpan> _renduSimple(String texte) {
    final spans = <TextSpan>[];
    for (final ligne in texte.split('\n')) {
      if (ligne.startsWith('#')) {
        spans.add(TextSpan(
          text: '${ligne.replaceFirst(RegExp(r'^#+\s*'), '')}\n',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
              color: Color(0xFF0A3D91), height: 1.8),
        ));
      } else if (ligne.trim().startsWith('-') || ligne.trim().startsWith('*')) {
        spans.add(TextSpan(
          text: '• ${ligne.replaceFirst(RegExp(r'^\s*[-*]\s*'), '').replaceAll('**', '')}\n',
          style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.6),
        ));
      } else {
        spans.add(TextSpan(
          text: '${ligne.replaceAll('**', '')}\n',
          style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5),
        ));
      }
    }
    return spans;
  }
}

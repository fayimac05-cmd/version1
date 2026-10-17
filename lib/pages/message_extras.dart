import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ════════════════════════════════════════════════════════════════════════
// CRÉATION D'UN SONDAGE — entièrement configurable par le créateur :
// choix unique/multiple, anonyme ou non, avec ou sans date de clôture.
// ════════════════════════════════════════════════════════════════════════
class CreationSondageSheet extends StatefulWidget {
  const CreationSondageSheet({super.key});

  @override
  State<CreationSondageSheet> createState() => _CreationSondageSheetState();
}

class _CreationSondageSheetState extends State<CreationSondageSheet> {
  final _questionCtrl = TextEditingController();
  final List<TextEditingController> _optionsCtrl = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _choixMultiple = false;
  bool _anonyme = false;
  DateTime? _dateCloture;
  bool _envoi = false;

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _optionsCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  void _ajouterOption() {
    if (_optionsCtrl.length >= 12) return;
    setState(() => _optionsCtrl.add(TextEditingController()));
  }

  void _retirerOption(int i) {
    if (_optionsCtrl.length <= 2) return;
    setState(() => _optionsCtrl.removeAt(i).dispose());
  }

  Future<void> _choisirDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final heure = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
    if (!mounted) return;
    setState(() => _dateCloture = DateTime(date.year, date.month, date.day, heure?.hour ?? 18, heure?.minute ?? 0));
  }

  Future<void> _valider() async {
    final question = _questionCtrl.text.trim();
    final options = _optionsCtrl.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ La question est requise.'), backgroundColor: Colors.redAccent));
      return;
    }
    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Au moins 2 options sont requises.'), backgroundColor: Colors.redAccent));
      return;
    }
    setState(() => _envoi = true);
    final result = await ApiService.creerSondage(
      question: question,
      options: options,
      choixMultiple: _choixMultiple,
      anonyme: _anonyme,
      dateCloture: _dateCloture,
    );
    if (!mounted) return;
    setState(() => _envoi = false);
    if (result['success'] == true) {
      Navigator.pop(context, result['id'].toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']?.toString() ?? 'Erreur.'), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
            ),
            const Row(children: [
              Icon(Icons.poll_outlined, color: Color(0xFF0D6EFD)),
              SizedBox(width: 8),
              Text('Créer un sondage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: [
                  TextField(
                    controller: _questionCtrl,
                    decoration: InputDecoration(
                      labelText: 'Question',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Options', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  ...List.generate(_optionsCtrl.length, (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          Expanded(
                            child: TextField(
                              controller: _optionsCtrl[i],
                              decoration: InputDecoration(
                                hintText: 'Option ${i + 1}',
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          if (_optionsCtrl.length > 2)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 20),
                              onPressed: () => _retirerOption(i),
                            ),
                        ]),
                      )),
                  if (_optionsCtrl.length < 12)
                    TextButton.icon(
                      onPressed: _ajouterOption,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Ajouter une option'),
                    ),
                  const Divider(height: 28),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Choix multiple', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Autoriser plusieurs réponses par personne', style: TextStyle(fontSize: 11.5)),
                    value: _choixMultiple,
                    onChanged: (v) => setState(() => _choixMultiple = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sondage anonyme', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Personne ne verra qui a voté quoi, seuls les totaux', style: TextStyle(fontSize: 11.5)),
                    value: _anonyme,
                    onChanged: (v) => setState(() => _anonyme = v),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date de clôture (optionnel)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _dateCloture != null
                          ? '${_dateCloture!.day}/${_dateCloture!.month}/${_dateCloture!.year} à ${_dateCloture!.hour.toString().padLeft(2, '0')}:${_dateCloture!.minute.toString().padLeft(2, '0')}'
                          : 'Aucune — le sondage reste ouvert jusqu\'à clôture manuelle',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    trailing: _dateCloture != null
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => setState(() => _dateCloture = null),
                          )
                        : const Icon(Icons.calendar_today_outlined, size: 18),
                    onTap: _choisirDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _envoi ? null : _valider,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD), padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _envoi
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Envoyer le sondage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// AFFICHAGE + VOTE — rendu dans une bulle de message
// ════════════════════════════════════════════════════════════════════════
class SondageWidget extends StatefulWidget {
  const SondageWidget({super.key, required this.sondageId});
  final String sondageId;

  @override
  State<SondageWidget> createState() => _SondageWidgetState();
}

class _SondageWidgetState extends State<SondageWidget> {
  bool _loading = true;
  String? _erreur;
  Map<String, dynamic>? _sondage;
  final Set<String> _selection = {};
  bool _vote = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _erreur = null; });
    final result = await ApiService.getSondage(widget.sondageId);
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        _sondage = result['data'] as Map<String, dynamic>;
        _selection
          ..clear()
          ..addAll((_sondage!['mes_votes'] as List<dynamic>).map((e) => e.toString()));
      } else {
        _erreur = result['error']?.toString() ?? 'Sondage introuvable.';
      }
      _loading = false;
    });
  }

  Future<void> _voter() async {
    if (_selection.isEmpty) return;
    setState(() => _vote = true);
    final result = await ApiService.voterSondage(widget.sondageId, _selection.toList());
    if (!mounted) return;
    setState(() => _vote = false);
    if (result['success'] == true) {
      await _charger();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']?.toString() ?? 'Erreur lors du vote.')));
    }
  }

  Future<void> _cloturer() async {
    final result = await ApiService.cloturerSondage(widget.sondageId);
    if (!mounted) return;
    if (result['success'] == true) {
      await _charger();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']?.toString() ?? 'Erreur.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_erreur != null || _sondage == null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(_erreur ?? 'Sondage introuvable.', style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
      );
    }
    final s = _sondage!;
    final options = s['options'] as List<dynamic>;
    final totalVotants = (s['total_votants'] as num?)?.toInt() ?? 0;
    final cloture = s['cloture'] == true;
    final choixMultiple = s['choix_multiple'] == true;
    final anonyme = s['anonyme'] == true;
    final estCreateur = s['est_createur'] == true;
    final dejaVote = (s['mes_votes'] as List).isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.poll_outlined, size: 16, color: Color(0xFF0D6EFD)),
            const SizedBox(width: 6),
            Expanded(child: Text(s['question']?.toString() ?? '',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF111B21)))),
          ]),
          const SizedBox(height: 2),
          Text(
            [
              choixMultiple ? 'Choix multiple' : 'Choix unique',
              anonyme ? 'Anonyme' : null,
              cloture ? 'Clôturé' : null,
            ].whereType<String>().join(' · '),
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF8696A0)),
          ),
          const SizedBox(height: 10),
          ...options.map((o) {
            final id = o['id'].toString();
            final texte = o['texte']?.toString() ?? '';
            final nbVotes = (o['nb_votes'] as num?)?.toInt() ?? 0;
            final pourcentage = totalVotants > 0 ? nbVotes / totalVotants : 0.0;
            final selectionne = _selection.contains(id);
            final peutVoter = !cloture;

            return GestureDetector(
              onTap: !peutVoter ? null : () {
                setState(() {
                  if (choixMultiple) {
                    if (selectionne) {
                      _selection.remove(id);
                    } else {
                      _selection.add(id);
                    }
                  } else {
                    _selection
                      ..clear()
                      ..add(id);
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selectionne ? const Color(0xFF0D6EFD) : Colors.transparent, width: 1.5),
                ),
                child: Stack(children: [
                  if (dejaVote || cloture)
                    Positioned.fill(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: pourcentage.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D6EFD).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  Row(children: [
                    if (peutVoter)
                      Icon(
                        selectionne
                            ? (choixMultiple ? Icons.check_box_rounded : Icons.radio_button_checked_rounded)
                            : (choixMultiple ? Icons.check_box_outline_blank_rounded : Icons.radio_button_unchecked_rounded),
                        size: 18,
                        color: selectionne ? const Color(0xFF0D6EFD) : const Color(0xFF94A3B8),
                      ),
                    if (peutVoter) const SizedBox(width: 8),
                    Expanded(child: Text(texte, style: const TextStyle(fontSize: 13, color: Color(0xFF111B21)))),
                    if (dejaVote || cloture)
                      Text('${(pourcentage * 100).round()}%',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0D6EFD))),
                  ]),
                ]),
              ),
            );
          }),
          const SizedBox(height: 4),
          Row(children: [
            Text('$totalVotants vote(s)', style: const TextStyle(fontSize: 10.5, color: Color(0xFF8696A0))),
            const Spacer(),
            if (!cloture && !dejaVote)
              TextButton(
                onPressed: _vote || _selection.isEmpty ? null : _voter,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), minimumSize: Size.zero),
                child: _vote
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Voter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            if (estCreateur && !cloture)
              TextButton(
                onPressed: _cloturer,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), minimumSize: Size.zero),
                child: const Text('Clôturer', style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w700)),
              ),
          ]),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// VISIONNEUSE PLEIN ÉCRAN — image agrandie, zoom au pincement, fermeture
// par le bouton ou en balayant vers le bas.
// ════════════════════════════════════════════════════════════════════════
class VisionneuseImage extends StatelessWidget {
  const VisionneuseImage({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 200) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// INFOS DU MESSAGE — qui a vu ce message, et à quelle heure.
// ════════════════════════════════════════════════════════════════════════
class InfosMessageSheet extends StatefulWidget {
  const InfosMessageSheet({super.key, required this.type, required this.messageId, required this.heureEnvoi});
  final String type;
  final String messageId;
  final String heureEnvoi;

  @override
  State<InfosMessageSheet> createState() => _InfosMessageSheetState();
}

class _InfosMessageSheetState extends State<InfosMessageSheet> {
  bool _loading = true;
  String? _erreur;
  List<dynamic> _lecteurs = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _erreur = null; });
    final result = await ApiService.getLecteursMessage(widget.type, widget.messageId);
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        _lecteurs = result['data'] as List<dynamic>;
      } else {
        _erreur = result['error']?.toString() ?? 'Erreur lors du chargement.';
      }
      _loading = false;
    });
  }

  String _formatHeure(dynamic iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso.toString())?.toLocal();
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
          child: Row(children: [
            const Icon(Icons.visibility_outlined, size: 18, color: const Color(0xFF0D6EFD)),
            const SizedBox(width: 8),
            Text('Vu par (${_lecteurs.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('Envoyé à ${widget.heureEnvoi}', style: const TextStyle(fontSize: 11, color: Color(0xFF8696A0))),
          ]),
        ),
        const Divider(height: 1),
        Flexible(
          child: _loading
              ? const Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())
              : _erreur != null
                  ? Padding(padding: const EdgeInsets.all(20), child: Text(_erreur!, style: const TextStyle(color: Colors.redAccent)))
                  : _lecteurs.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Personne n\'a encore vu ce message.', style: TextStyle(fontSize: 13, color: Color(0xFF8696A0))),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: _lecteurs.length,
                          itemBuilder: (_, i) {
                            final l = _lecteurs[i] as Map<String, dynamic>;
                            final nom = '${l['prenoms'] ?? ''} ${l['nom'] ?? ''}'.trim();
                            final photo = l['photo_url']?.toString();
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFFE7F1FF),
                                backgroundImage: (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
                                child: (photo == null || photo.isEmpty)
                                    ? Text(nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D6EFD)))
                                    : null,
                              ),
                              title: Text(nom.isNotEmpty ? nom : 'Utilisateur', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                              trailing: Text(_formatHeure(l['lu_at']), style: const TextStyle(fontSize: 11.5, color: Color(0xFF8696A0))),
                            );
                          },
                        ),
        ),
        SizedBox(height: 8 + MediaQuery.of(context).padding.bottom),
      ]),
    );
  }
}

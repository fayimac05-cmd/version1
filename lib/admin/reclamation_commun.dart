import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import '../services/api_service.dart';
import 'admin_theme.dart';

// ════════════════════════════════════════════════════════════════════════════
// RÉCLAMATIONS — éléments communs (étudiant / administration / professeur)
// ════════════════════════════════════════════════════════════════════════════

const List<String> kCategoriesReclamation = [
  'Notes & Moyennes', 'Accès & Connexion', 'Documents', 'Inscription', 'Paiement', 'Autre',
];

/// Seules ces catégories peuvent être transmises à un professeur.
/// Inscription, Paiement et Accès & Connexion relèvent de l'administration.
const List<String> kCategoriesTransmissibles = ['Notes & Moyennes', 'Documents', 'Autre'];

String fmtDateRecl(dynamic iso, {bool heure = false}) {
  if (iso == null) return '';
  final dt = DateTime.tryParse(iso.toString())?.toLocal();
  if (dt == null) return iso.toString();
  String d2(int n) => n.toString().padLeft(2, '0');
  final d = '${d2(dt.day)}/${d2(dt.month)}/${dt.year}';
  return heure ? '$d ${d2(dt.hour)}:${d2(dt.minute)}' : d;
}

// ── API ─────────────────────────────────────────────────────────────────────
class ReclamationsApi {
  static Future<Map<String, dynamic>> _req(
      String method, String path, {Map<String, dynamic>? body}) async {
    try {
      final headers = await ApiService.getHeaders();
      final uri = Uri.parse('${ApiService.baseUrl}/reclamations$path');
      late http.Response r;
      switch (method) {
        case 'POST':  r = await http.post(uri, headers: headers, body: jsonEncode(body ?? {})); break;
        case 'PATCH': r = await http.patch(uri, headers: headers, body: jsonEncode(body ?? {})); break;
        default:      r = await http.get(uri, headers: headers);
      }
      final data = jsonDecode(utf8.decode(r.bodyBytes));
      if (data is Map && data['success'] == true) return Map<String, dynamic>.from(data);
      return {'success': false, 'error': (data is Map ? data['message'] : null) ?? 'Erreur (${r.statusCode}).'};
    } catch (_) {
      return {'success': false, 'error': 'Serveur injoignable.'};
    }
  }

  static Future<Map<String, dynamic>> liste(String role) =>
      _req('GET', role == 'admin' ? '' : role == 'professeur' ? '/professeur/mes' : '/mes-reclamations');
  static Future<Map<String, dynamic>> detail(String id) => _req('GET', '/$id');
  static Future<Map<String, dynamic>> creer(Map<String, dynamic> body) => _req('POST', '', body: body);
  static Future<Map<String, dynamic>> message(String id, String contenu, {bool interne = false}) =>
      _req('POST', '/$id/messages', body: {'contenu': contenu, 'interne': interne});
  static Future<Map<String, dynamic>> candidats(String id) => _req('GET', '/$id/professeurs');
  static Future<Map<String, dynamic>> transferer(String id, String profId, String consigne) =>
      _req('PATCH', '/$id/transferer', body: {'prof_id': profId, 'consigne': consigne});
  static Future<Map<String, dynamic>> retour(String id, String commentaire) =>
      _req('PATCH', '/$id/retour', body: {'commentaire': commentaire});
  static Future<Map<String, dynamic>> repondre(String id, String reponse) =>
      _req('PATCH', '/$id/repondre', body: {'reponse': reponse});
  static Future<Map<String, dynamic>> rejeter(String id, String motif) =>
      _req('PATCH', '/$id/rejeter', body: {'motif': motif});

  static Future<Map<String, dynamic>> envoyerPiece(String id, PlatformFile f) async {
    try {
      if (f.bytes == null) return {'success': false, 'error': 'Fichier illisible.'};
      final token = await ApiService.getToken();
      final req = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/reclamations/$id/pieces'));
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      final ext = (f.extension ?? '').toLowerCase();
      final mime = ext == 'pdf' ? 'application/pdf' : ext == 'png' ? 'image/png' : 'image/jpeg';
      req.files.add(http.MultipartFile.fromBytes('file', f.bytes!,
          filename: f.name, contentType: MediaType.parse(mime)));
      final res = await http.Response.fromStream(await req.send());
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is Map && data['success'] == true) return {'success': true};
      return {'success': false, 'error': (data is Map ? data['message'] : null) ?? 'Échec de l\'envoi.'};
    } catch (_) {
      return {'success': false, 'error': 'Échec de l\'envoi du fichier.'};
    }
  }

}

// ── Modèle ──────────────────────────────────────────────────────────────────
class Recl {
  final Map<String, dynamic> j;
  Recl(this.j);

  String get id => j['id']?.toString() ?? '';
  String get numero => j['numero']?.toString() ?? 'RCL-${id.length > 6 ? id.substring(0, 6).toUpperCase() : id}';
  String get categorie => j['categorie']?.toString() ?? 'Notes & Moyennes';
  String get objet {
    final o = j['objet']?.toString() ?? '';
    if (o.isNotEmpty) return o;
    final m = j['module_nom']?.toString() ?? '';
    final t = j['type']?.toString() ?? '';
    return m.isNotEmpty ? 'Contestation ${t == 'absence' ? 'd\'absence' : t == 'moyenne' ? 'de moyenne' : 'de note'} — $m' : categorie;
  }
  String get description => j['justification']?.toString() ?? '';
  String get statut => j['statut']?.toString() ?? 'en_attente';
  String get etape {
    final e = j['etape']?.toString();
    if (e != null && e.isNotEmpty) return e;
    return statut == 'resolu' || statut == 'rejete' ? 'termine' : statut == 'en_cours' ? 'professeur' : 'admin';
  }
  String get reponse => j['reponse']?.toString() ?? '';
  String get matricule => j['matricule']?.toString() ?? '';
  String get etudiant => '${j['etudiant_prenoms'] ?? ''} ${j['etudiant_nom'] ?? ''}'.trim();
  String get prof => '${j['prof_prenoms'] ?? ''} ${j['prof_nom'] ?? ''}'.trim().isNotEmpty
      ? '${j['prof_prenoms'] ?? ''} ${j['prof_nom'] ?? ''}'.trim()
      : (j['prof_transfere']?.toString() ?? '');
  String get date => fmtDateRecl(j['created_at']);
  int get nbPieces => int.tryParse('${j['nb_pieces'] ?? 0}') ?? 0;
  bool get cloturee => statut == 'resolu' || statut == 'rejete';

  String get statutLabel {
    switch (statut) {
      case 'en_cours': return 'En cours';
      case 'resolu':   return 'Résolue';
      case 'rejete':   return 'Rejetée';
      default:         return 'En attente';
    }
  }
  Color get statutFg {
    switch (statut) {
      case 'en_cours': return AdminTheme.info;
      case 'resolu':   return AdminTheme.success;
      case 'rejete':   return AdminTheme.danger;
      default:         return AdminTheme.warning;
    }
  }
  Color get statutBg {
    switch (statut) {
      case 'en_cours': return AdminTheme.infoLight;
      case 'resolu':   return AdminTheme.successLight;
      case 'rejete':   return AdminTheme.dangerLight;
      default:         return AdminTheme.warningLight;
    }
  }
}

Widget badgeStatut(Recl r) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: r.statutBg, borderRadius: BorderRadius.circular(20)),
      child: Text(r.statutLabel,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: r.statutFg)),
    );

// ── Circuit en 5 étapes ─────────────────────────────────────────────────────
class CircuitReclamation extends StatelessWidget {
  final Recl r;
  const CircuitReclamation({super.key, required this.r});

  @override
  Widget build(BuildContext context) {
    final e = r.etape;
    int actif = e == 'admin' ? 1 : e == 'professeur' ? 2 : e == 'verification' ? 3 : 5;
    final rejetee = r.statut == 'rejete';
    final etapes = <List<String>>[
      ['Étudiant', 'Dépose'],
      ['Administration', rejetee ? 'Rejette' : 'Reçoit et transmet'],
      ['Professeur', 'Traite'],
      ['Administration', 'Vérifie'],
      ['Étudiant', 'Reçoit la réponse'],
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AdminTheme.border)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (int i = 0; i < etapes.length; i++) ...[
            _etape(i + 1, etapes[i][0], etapes[i][1],
                fait: (rejetee ? (i < 2) : i < actif - 1) || (e == 'termine' && !rejetee),
                courant: !r.cloturee && i == actif - 1,
                saute: rejetee && i >= 2 && i < 4),
            if (i < etapes.length - 1)
              Container(width: 26, height: 2, color: AdminTheme.border, margin: const EdgeInsets.only(bottom: 26)),
          ],
        ]),
      ),
    );
  }

  Widget _etape(int n, String titre, String sous, {required bool fait, required bool courant, bool saute = false}) {
    final color = saute ? AdminTheme.textMuted : fait ? AdminTheme.success : courant ? AdminTheme.primary : AdminTheme.textMuted;
    return SizedBox(
      width: 96,
      child: Column(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
              color: fait || courant ? color : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5)),
          child: Center(
            child: fait && !saute
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text('$n',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: courant ? Colors.white : color)),
          ),
        ),
        const SizedBox(height: 6),
        Text(titre, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        Text(sous, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AdminTheme.textSecondary)),
      ]),
    );
  }
}

// ── Carte de liste ──────────────────────────────────────────────────────────
class CarteReclamation extends StatelessWidget {
  final Recl r;
  final String role;
  final VoidCallback onTap;
  const CarteReclamation({super.key, required this.r, required this.role, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final aTraiter = role == 'admin' && (r.statut == 'en_attente' || r.etape == 'verification');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: aTraiter ? AdminTheme.warning.withValues(alpha: 0.5) : AdminTheme.border),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.report_gmailerrorred_rounded, color: AdminTheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(r.numero,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AdminTheme.primary, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(r.categorie,
                      style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: 3),
              Text(r.objet,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(
                role == 'etudiant'
                    ? 'Soumise le ${r.date}'
                    : '${r.etudiant}${r.matricule.isNotEmpty ? ' · ${r.matricule}' : ''} · ${r.date}',
                style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              if (r.prof.isNotEmpty && role != 'professeur')
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text('→ ${r.prof}',
                      style: const TextStyle(fontSize: 11, color: AdminTheme.warning, fontWeight: FontWeight.w600)),
                ),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            badgeStatut(r),
            if (r.nbPieces > 0) ...[
              const SizedBox(height: 6),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.attach_file_rounded, size: 12, color: AdminTheme.info),
                Text('${r.nbPieces}', style: const TextStyle(fontSize: 11, color: AdminTheme.info)),
              ]),
            ],
          ]),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// LISTE (les 3 rôles)
// ════════════════════════════════════════════════════════════════════════════
class ReclamationsListe extends StatefulWidget {
  final String role; // 'etudiant' | 'admin' | 'professeur'
  const ReclamationsListe({super.key, required this.role});

  @override
  State<ReclamationsListe> createState() => _ReclamationsListeState();
}

class _ReclamationsListeState extends State<ReclamationsListe> {
  bool _loading = true;
  String? _erreur;
  List<Recl> _items = [];
  String _q = '';
  String _fCat = 'Toutes';
  String _fStatut = 'Tous';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _erreur = null; });
    final res = await ReclamationsApi.liste(widget.role);
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        _items = (res['data'] as List).map((e) => Recl(Map<String, dynamic>.from(e as Map))).toList();
      } else {
        _erreur = res['error']?.toString();
      }
      _loading = false;
    });
  }

  // Filtre « Catégorie » : le professeur ne voit que les catégories qu'il a réellement reçues.
  List<String> get _categoriesFiltre {
    if (widget.role != 'professeur') return kCategoriesReclamation;
    final presentes = _items.map((r) => r.categorie).toSet();
    return kCategoriesReclamation.where(presentes.contains).toList();
  }

  List<Recl> get _filtrees => _items.where((r) {
        if (_fCat != 'Toutes' && r.categorie != _fCat) return false;
        if (_fStatut != 'Tous' && r.statutLabel != _fStatut) return false;
        final q = _q.toLowerCase();
        if (q.isEmpty) return true;
        return r.numero.toLowerCase().contains(q) || r.objet.toLowerCase().contains(q) ||
            r.etudiant.toLowerCase().contains(q) || r.matricule.toLowerCase().contains(q);
      }).toList();

  int _n(String s) => _items.where((r) => r.statut == s).length;

  Future<void> _ouvrir(Recl r) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => ReclamationDetailPage(id: r.id, role: widget.role)));
    _charger();
  }

  Future<void> _nouvelle() async {
    final ok = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const ReclamationFormPage()));
    if (ok == true) _charger();
  }

  @override
  Widget build(BuildContext context) {
    final titre = widget.role == 'professeur' ? 'Traitement des réclamations' : 'Réclamations';
    final sous = widget.role == 'etudiant'
        ? 'Suivez vos demandes et échangez avec l\'administration.'
        : widget.role == 'professeur'
            ? 'Réclamations transmises par l\'administration.'
            : 'Recevez, transmettez au professeur concerné ou rejetez.';
    final filtres = _filtrees;
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(titre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                  Text(sous, style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary)),
                ]),
              ),
              if (widget.role == 'etudiant')
                ElevatedButton.icon(
                  onPressed: _nouvelle,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nouvelle réclamation'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primary, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              _kpi('Total', _items.length, AdminTheme.primary, AdminTheme.primaryLight),
              _kpi('En attente', _n('en_attente'), AdminTheme.warning, AdminTheme.warningLight),
              _kpi('En cours', _n('en_cours'), AdminTheme.info, AdminTheme.infoLight),
              _kpi('Résolues', _n('resolu'), AdminTheme.success, AdminTheme.successLight),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              SizedBox(
                width: 260, height: 38,
                child: TextField(
                  onChanged: (v) => setState(() => _q = v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher (n°, objet, étudiant)…',
                    hintStyle: const TextStyle(fontSize: 13, color: AdminTheme.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    filled: true, fillColor: AdminTheme.surfaceAlt,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AdminTheme.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AdminTheme.border)),
                  ),
                ),
              ),
              _menu('Catégorie', _fCat, ['Toutes', ..._categoriesFiltre], (v) => setState(() => _fCat = v)),
              _menu('Statut', _fStatut, const ['Tous', 'En attente', 'En cours', 'Résolue', 'Rejetée'], (v) => setState(() => _fStatut = v)),
            ]),
          ]),
        ),
        Container(height: 1, color: AdminTheme.border),
        Expanded(child: _corps(filtres)),
      ]),
    );
  }

  Widget _corps(List<Recl> filtres) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_erreur != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_erreur!, style: const TextStyle(color: AdminTheme.danger)),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _charger, child: const Text('Réessayer')),
        ]),
      );
    }
    if (filtres.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inbox_rounded, size: 40, color: AdminTheme.textMuted),
          SizedBox(height: 8),
          Text('Aucune réclamation', style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filtres.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => CarteReclamation(r: filtres[i], role: widget.role, onTap: () => _ouvrir(filtres[i])),
      ),
    );
  }

  Widget _kpi(String label, int n, Color fg, Color bg) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$n', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: fg)),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
          ]),
        ),
      );

  Widget _menu(String label, String valeur, List<String> options, void Function(String) onSel) =>
      PopupMenuButton<String>(
        onSelected: onSel,
        itemBuilder: (_) => options.map((o) => PopupMenuItem(value: o, child: Text(o))).toList(),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AdminTheme.border)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('$label : $valeur', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            const Icon(Icons.expand_more_rounded, size: 18),
          ]),
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// FORMULAIRE — nouvelle réclamation (étudiant)
// ════════════════════════════════════════════════════════════════════════════
class ReclamationFormPage extends StatefulWidget {
  const ReclamationFormPage({super.key});

  @override
  State<ReclamationFormPage> createState() => _ReclamationFormPageState();
}

class _ReclamationFormPageState extends State<ReclamationFormPage> {
  String? _categorie;
  final _objet = TextEditingController();
  final _desc = TextEditingController();
  final List<PlatformFile> _fichiers = [];
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _objet.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _choisir() async {
    final res = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'], withData: true, allowMultiple: true);
    if (res == null) return;
    setState(() {
      for (final f in res.files) {
        if (_fichiers.length >= 5) break;
        if (f.size > 5 * 1024 * 1024) { _erreur = '« ${f.name} » dépasse 5 Mo.'; continue; }
        _fichiers.add(f);
      }
    });
  }

  Future<void> _envoyer() async {
    if (_categorie == null || _objet.text.trim().isEmpty || _desc.text.trim().isEmpty) {
      setState(() => _erreur = 'Catégorie, objet et description sont obligatoires.');
      return;
    }
    setState(() { _envoi = true; _erreur = null; });
    final res = await ReclamationsApi.creer({
      'categorie': _categorie, 'objet': _objet.text.trim(), 'description': _desc.text.trim(),
    });
    if (res['success'] != true) {
      if (mounted) setState(() { _envoi = false; _erreur = res['error']?.toString(); });
      return;
    }
    final id = res['id'].toString();
    int echecs = 0;
    for (final f in _fichiers) {
      final r = await ReclamationsApi.envoyerPiece(id, f);
      if (r['success'] != true) echecs++;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(echecs == 0
          ? 'Réclamation ${res['numero']} envoyée à l\'administration.'
          : 'Réclamation envoyée, mais $echecs pièce(s) n\'ont pas pu être jointes.'),
      behavior: SnackBarBehavior.floating,
    ));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, foregroundColor: const Color(0xFF1A1A2E),
        title: const Text('Nouvelle réclamation', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Catégorie *'),
              DropdownButtonFormField<String>(
                value: _categorie,
                items: kCategoriesReclamation.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _categorie = v),
                decoration: _deco('Choisir une catégorie'),
              ),
              const SizedBox(height: 16),
              _label('Objet *'),
              TextField(controller: _objet, maxLength: 160, decoration: _deco('Ex. Erreur sur ma note de Réseaux')),
              const SizedBox(height: 8),
              _label('Description *'),
              TextField(
                  controller: _desc, maxLines: 6, maxLength: 1000,
                  decoration: _deco('Décrivez précisément votre demande…')),
              const SizedBox(height: 8),
              _label('Pièces jointes (facultatif)'),
              OutlinedButton.icon(
                onPressed: _fichiers.length >= 5 ? null : _choisir,
                icon: const Icon(Icons.attach_file_rounded, size: 18),
                label: const Text('Ajouter un fichier (JPG, PNG, PDF — 5 Mo max)'),
              ),
              for (int i = 0; i < _fichiers.length; i++)
                ListTile(
                  dense: true, contentPadding: EdgeInsets.zero,
                  leading: Icon(_fichiers[i].extension == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                      color: AdminTheme.info),
                  title: Text(_fichiers[i].name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${(_fichiers[i].size / 1024).round()} Ko'),
                  trailing: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() => _fichiers.removeAt(i))),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AdminTheme.infoLight, borderRadius: BorderRadius.circular(12)),
                child: const Text(
                    'Votre réclamation est d\'abord examinée par l\'administration, qui la traite elle-même ou la transmet au professeur concerné. Vous recevrez la réponse ici et par notification.',
                    style: TextStyle(fontSize: 12.5, color: AdminTheme.info, height: 1.4)),
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 10),
                Text(_erreur!, style: const TextStyle(color: AdminTheme.danger, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: _envoi ? null : () => Navigator.pop(context), child: const Text('Annuler')),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _envoi ? null : _envoyer,
                  icon: _envoi
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Envoyer la réclamation'),
                  style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, foregroundColor: Colors.white),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
      );

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint, filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AdminTheme.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AdminTheme.border)),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// DÉTAIL (les 3 rôles) — circuit, contenu, échanges, actions selon le rôle
// ════════════════════════════════════════════════════════════════════════════
class ReclamationDetailPage extends StatefulWidget {
  final String id;
  final String role;
  const ReclamationDetailPage({super.key, required this.id, required this.role});

  @override
  State<ReclamationDetailPage> createState() => _ReclamationDetailPageState();
}

class _ReclamationDetailPageState extends State<ReclamationDetailPage> {
  Recl? _r;
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _pieces = [];
  bool _loading = true;
  String? _erreur;
  bool _busy = false;
  final _msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final res = await ReclamationsApi.detail(widget.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        final d = Map<String, dynamic>.from(res['data'] as Map);
        _r = Recl(d);
        _messages = (d['messages'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _pieces = (d['pieces'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        _erreur = res['error']?.toString();
      }
    });
  }

  void _snack(String m, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m), backgroundColor: ok ? AdminTheme.success : AdminTheme.danger, behavior: SnackBarBehavior.floating));
  }

  Future<void> _action(Future<Map<String, dynamic>> Function() f, String okMsg) async {
    setState(() => _busy = true);
    final res = await f();
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['success'] == true) {
      _snack(okMsg);
      await _charger();
    } else {
      _snack(res['error']?.toString() ?? 'Erreur.', ok: false);
    }
  }

  Future<void> _envoyerMessage({bool interne = false}) async {
    final t = _msgCtrl.text.trim();
    if (t.isEmpty) return;
    _msgCtrl.clear();
    await _action(() => ReclamationsApi.message(widget.id, t, interne: interne), 'Message envoyé.');
  }

  Future<String?> _saisir(String titre, String hint, {bool obligatoire = true, String ok = 'Valider', Color? couleur}) async {
    final ctrl = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(titre),
        content: TextField(controller: ctrl, maxLines: 5, decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (obligatoire && ctrl.text.trim().isEmpty) return;
              Navigator.pop(c, ctrl.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: couleur ?? AdminTheme.primary, foregroundColor: Colors.white),
            child: Text(ok),
          ),
        ],
      ),
    );
    return res;
  }

  Future<void> _transmettre() async {
    final res = await ReclamationsApi.candidats(widget.id);
    if (!mounted) return;
    if (res['success'] != true) { _snack(res['error']?.toString() ?? 'Erreur.', ok: false); return; }
    final sug = (res['suggeres'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final tous = (res['tous'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    String? choisi = sug.isNotEmpty ? sug.first['id'].toString() : null;
    final consigne = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(builder: (c, setD) {
        String nom(Map<String, dynamic> p) => '${p['prenoms'] ?? ''} ${p['nom'] ?? ''}'.trim();
        return AlertDialog(
          title: const Text('Renvoyer au professeur'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (sug.isNotEmpty) ...[
                  const Text('Professeurs du module concerné',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminTheme.textSecondary)),
                  for (final p in sug)
                    RadioListTile<String>(
                      dense: true, value: p['id'].toString(), groupValue: choisi,
                      title: Text(nom(p)), onChanged: (v) => setD(() => choisi = v),
                    ),
                  const Divider(),
                ],
                DropdownButtonFormField<String>(
                  value: tous.any((p) => p['id'].toString() == choisi) ? choisi : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Ou choisir un autre professeur', border: OutlineInputBorder()),
                  items: tous.map((p) => DropdownMenuItem(value: p['id'].toString(), child: Text(nom(p)))).toList(),
                  onChanged: (v) => setD(() => choisi = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: consigne, maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Consigne pour le professeur (facultatif)', border: OutlineInputBorder()),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: choisi == null ? null : () => Navigator.pop(c, true),
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.info, foregroundColor: Colors.white),
              child: const Text('Transmettre'),
            ),
          ],
        );
      }),
    );
    if (ok == true && choisi != null) {
      await _action(() => ReclamationsApi.transferer(widget.id, choisi!, consigne.text.trim()), 'Transmise au professeur.');
    }
    consigne.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, foregroundColor: const Color(0xFF1A1A2E),
        title: Text(r?.numero ?? 'Réclamation', style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [if (r != null) Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: badgeStatut(r)))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : r == null
              ? Center(child: Text(_erreur ?? 'Introuvable', style: const TextStyle(color: AdminTheme.danger)))
              : Column(children: [
                  Expanded(child: _contenu(r)),
                  _barreActions(r),
                ]),
    );
  }

  Widget _contenu(Recl r) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircuitReclamation(r: r),
            const SizedBox(height: 16),
            _carte(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.objet, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 10),
              _ligne('Catégorie', r.categorie),
              if (widget.role != 'etudiant') _ligne('Étudiant', '${r.etudiant}${r.matricule.isNotEmpty ? ' (${r.matricule})' : ''}'),
              if ((r.j['filiere'] ?? '').toString().isNotEmpty) _ligne('Filière', r.j['filiere'].toString()),
              if ((r.j['module_nom'] ?? '').toString().isNotEmpty) _ligne('Module', r.j['module_nom'].toString()),
              _ligne('Déposée le', fmtDateRecl(r.j['created_at'], heure: true)),
              if (r.prof.isNotEmpty) _ligne('Professeur', r.prof),
              const Divider(height: 22),
              Text(r.description, style: const TextStyle(fontSize: 14, height: 1.5)),
            ])),
            if (_pieces.isNotEmpty) ...[
              const SizedBox(height: 16),
              _titre('Pièces jointes'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final p in _pieces)
                  ActionChip(
                    avatar: Icon((p['mime'] ?? '').toString().contains('pdf') ? Icons.picture_as_pdf_rounded : Icons.image_rounded, size: 16),
                    label: Text((p['nom'] ?? 'Fichier').toString(), overflow: TextOverflow.ellipsis),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text((p['nom'] ?? '').toString()),
                        content: (p['mime'] ?? '').toString().contains('pdf')
                            ? SelectableText('Lien du document :\n${p['url']}')
                            : Image.network(p['url'].toString(), errorBuilder: (_, __, ___) => SelectableText(p['url'].toString())),
                        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Fermer'))],
                      ),
                    ),
                  ),
              ]),
            ],
            if (r.cloturee && r.reponse.isNotEmpty) ...[
              const SizedBox(height: 16),
              _titre(r.statut == 'rejete' ? 'Motif du rejet' : 'Réponse de l\'administration'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: r.statut == 'rejete' ? AdminTheme.dangerLight : AdminTheme.successLight,
                    borderRadius: BorderRadius.circular(12)),
                child: Text(r.reponse,
                    style: TextStyle(height: 1.5, color: r.statut == 'rejete' ? AdminTheme.danger : AdminTheme.success)),
              ),
            ],
            if (widget.role != 'etudiant' && (r.j['prof_commentaire'] ?? '').toString().isNotEmpty && !r.cloturee) ...[
              const SizedBox(height: 16),
              _titre('Retour du professeur'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AdminTheme.warningLight, borderRadius: BorderRadius.circular(12)),
                child: Text(r.j['prof_commentaire'].toString(), style: const TextStyle(height: 1.5)),
              ),
            ],
            const SizedBox(height: 16),
            _titre('Échanges'),
            if (_messages.isEmpty)
              const Text('Aucun échange pour le moment.', style: TextStyle(fontSize: 13, color: AdminTheme.textMuted))
            else
              for (final m in _messages) _bulle(m),
          ]),
        ),
      ),
    );
  }

  Widget _bulle(Map<String, dynamic> m) {
    final role = m['auteur_role']?.toString() ?? '';
    final interne = m['interne'] == true;
    final moi = role == widget.role;
    final nom = role == 'admin' ? 'Administration' : '${m['prenoms'] ?? ''} ${m['nom'] ?? ''}'.trim();
    final bg = interne ? AdminTheme.warningLight : moi ? AdminTheme.primaryLight : Colors.white;
    return Align(
      alignment: moi ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AdminTheme.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${nom.isEmpty ? role : nom}${interne ? ' · interne' : ''} · ${fmtDateRecl(m['created_at'], heure: true)}',
              style: const TextStyle(fontSize: 10.5, color: AdminTheme.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(m['contenu']?.toString() ?? '', style: const TextStyle(fontSize: 13.5, height: 1.4)),
        ]),
      ),
    );
  }

  Widget _barreActions(Recl r) {
    if (r.cloturee) return const SizedBox.shrink();
    final role = widget.role;
    final peutTransmettre = role == 'admin';
    final profPeutRetourner = role == 'professeur' && r.etape == 'professeur';
    final enAttenteProf = role == 'professeur' && r.etape != 'professeur';

    final champ = Row(children: [
      Expanded(
        child: TextField(
          controller: _msgCtrl,
          decoration: InputDecoration(
            hintText: role == 'professeur' ? 'Message à l\'administration…' : role == 'admin' ? 'Message à l\'étudiant…' : 'Ajouter un message…',
            isDense: true, filled: true, fillColor: AdminTheme.surfaceAlt,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ),
      IconButton(
        onPressed: _busy ? null : () => _envoyerMessage(interne: role == 'professeur'),
        icon: const Icon(Icons.send_rounded, color: AdminTheme.primary),
      ),
    ]);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AdminTheme.border))),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!enAttenteProf) champ,
          if (peutTransmettre) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : () async {
                  final m = await _saisir('Rejeter la réclamation', 'Motif du rejet…',
                      obligatoire: false, ok: 'Confirmer le rejet', couleur: AdminTheme.danger);
                  if (m != null) _action(() => ReclamationsApi.rejeter(widget.id, m), 'Réclamation rejetée.');
                },
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Rejeter'),
                style: OutlinedButton.styleFrom(foregroundColor: AdminTheme.danger),
              ),
              // Transmission possible seulement pour les catégories d'ordre académique.
              if (kCategoriesTransmissibles.contains(r.categorie) || r.categorie.isEmpty)
                OutlinedButton.icon(
                  onPressed: _busy ? null : _transmettre,
                  icon: const Icon(Icons.forward_rounded, size: 16),
                  label: Text(r.etape == 'admin' ? 'Renvoyer au professeur' : 'Renvoyer à un professeur'),
                  style: OutlinedButton.styleFrom(foregroundColor: AdminTheme.info),
                ),
              ElevatedButton.icon(
                onPressed: _busy ? null : () async {
                  final m = await _saisir(
                      r.etape == 'verification' ? 'Valider et répondre à l\'étudiant' : 'Répondre à l\'étudiant',
                      'Rédigez la réponse finale…', ok: 'Envoyer la réponse', couleur: AdminTheme.success);
                  if (m != null) _action(() => ReclamationsApi.repondre(widget.id, m), 'Réponse envoyée à l\'étudiant.');
                },
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text(r.etape == 'verification' ? 'Valider et répondre' : 'Répondre directement'),
                style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.success, foregroundColor: Colors.white),
              ),
            ]),
          ],
          if (profPeutRetourner) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : () async {
                  final m = await _saisir('Valider et retourner à l\'administration',
                      'Votre commentaire / conclusion (obligatoire)…', ok: 'Retourner');
                  if (m != null) _action(() => ReclamationsApi.retour(widget.id, m), 'Retournée à l\'administration.');
                },
                icon: const Icon(Icons.undo_rounded, size: 16),
                label: const Text('Valider et retourner à l\'administration'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
          if (enAttenteProf)
            const Text('Vous avez déjà retourné cette réclamation à l\'administration.',
                style: TextStyle(fontSize: 12.5, color: AdminTheme.textSecondary)),
        ]),
      ),
    );
  }

  Widget _carte(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AdminTheme.border)),
        child: child,
      );

  Widget _titre(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF374151))),
      );

  Widget _ligne(String l, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 100, child: Text(l, style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary))),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
        ]),
      );
}
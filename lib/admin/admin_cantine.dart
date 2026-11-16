import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../admin/admin_theme.dart';
import '../services/cantine_service.dart';

class AdminCantine extends StatefulWidget {
  const AdminCantine({super.key});
  @override
  State<AdminCantine> createState() => _AdminCantineState();
}

const _repasOptions = [
  {'val': 'petit_dejeuner', 'label': 'Petit-déjeuner', 'icon': Icons.free_breakfast_rounded},
  {'val': 'dejeuner', 'label': 'Déjeuner', 'icon': Icons.lunch_dining_rounded},
  {'val': 'diner', 'label': 'Dîner', 'icon': Icons.dinner_dining_rounded},
];

const _jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
const _mois = ['Janv.', 'Févr.', 'Mars', 'Avr.', 'Mai', 'Juin', 'Juil.', 'Août', 'Sept.', 'Oct.', 'Nov.', 'Déc.'];

const _bleu = Color(0xFF1E40AF);
const _bleuClair = Color(0xFFEFF4FF);

IconData _iconeCategorie(String c) {
  switch (c) {
    case 'entree':
      return Icons.eco_rounded;
    case 'accompagnement':
      return Icons.rice_bowl_rounded;
    case 'boisson':
      return Icons.local_drink_rounded;
    case 'dessert':
      return Icons.icecream_rounded;
    default:
      return Icons.restaurant_rounded;
  }
}

(Color, Color) _couleursCategorie(String c) {
  switch (c) {
    case 'entree':
      return (const Color(0xFF15803D), const Color(0xFFDCFCE7));
    case 'accompagnement':
      return (const Color(0xFF0E7490), const Color(0xFFCFFAFE));
    case 'boisson':
      return (const Color(0xFF1D4ED8), const Color(0xFFDBEAFE));
    case 'dessert':
      return (const Color(0xFFBE185D), const Color(0xFFFCE7F3));
    default:
      return (const Color(0xFFB45309), const Color(0xFFFEF3C7));
  }
}

String _norm(String t) {
  const a = 'àâäáãéèêëíìîïóòôöõúùûüçñ';
  const b = 'aaaaaeeeeiiiiooooouuuucn';
  var s = t.toLowerCase().trim();
  for (var i = 0; i < a.length; i++) {
    s = s.replaceAll(a[i], b[i]);
  }
  return s;
}

String _prixTexte(int p) {
  final s = p.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '$b FCFA';
}

class _AdminCantineState extends State<AdminCantine> {
  DateTime _date = DateTime.now();
  late String _repas;
  bool _loading = true;
  String? _error;
  List<CantinePlat> _plats = [];
  final Map<String, bool> _publie = {'petit_dejeuner': false, 'dejeuner': false, 'diner': false};
  bool _publication = false;
  bool _reprise = false;

  // Filtre / recherche de la liste
  String _filtre = 'tous';
  final TextEditingController _rechCtrl = TextEditingController();

  // Onglet « Commandes »
  int _onglet = 0; // 0 = menu, 1 = commandes
  List<CantineCommande> _commandes = [];
  String _statutCmd = 'en_cours'; // en_cours | traitee
  DateTime _dateCmd = DateTime.now();
  int _nbEnCours = 0;
  bool _cmdChargement = false;
  String? _cmdErreur;
  final Set<String> _cmdEnTraitement = {};
  final TextEditingController _cmdRech = TextEditingController();
  Timer? _minuteur;

  // Horaires et lieu (affichés aux étudiants)
  final TextEditingController _lieuCtrl = TextEditingController();
  String _ouverture = '07:00';
  String _fermeture = '19:00';
  bool _paramEnvoi = false;

  // Formulaire (ajout ou modification)
  final ScrollController _scroll = ScrollController();
  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _prixCtrl = TextEditingController();
  String _categorie = 'plat_principal';
  bool _disponible = true;
  Uint8List? _imageBytes;
  String _imageNom = 'plat.jpg';
  String? _imageUrl; // photo déjà enregistrée (mode modification)
  CantinePlat? _edition;
  bool _envoi = false;

  String get _dateIso =>
      '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
  String get _dateLongue => '${_jours[_date.weekday - 1]} ${_date.day} ${_mois[_date.month - 1]} ${_date.year}';
  String get _libelleRepas => _repasOptions.firstWhere((r) => r['val'] == _repas)['label'] as String;

  @override
  void initState() {
    super.initState();
    final h = DateTime.now().hour;
    _repas = h < 10 ? 'petit_dejeuner' : (h < 16 ? 'dejeuner' : 'diner');
    _charger();
    _chargerCommandes();
    // Actualisation automatique : nouvelles commandes et pastille du nombre en cours.
    _minuteur = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) _chargerCommandes(silencieux: true);
    });
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    _cmdRech.dispose();
    _nomCtrl.dispose();
    _descCtrl.dispose();
    _prixCtrl.dispose();
    _rechCtrl.dispose();
    _lieuCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Données ─────────────────────────────────────────────────────────────
  Future<void> _charger() async {
    setState(() { _loading = true; _error = null; });
    final r = await CantineService.jour(_dateIso);
    if (!mounted) return;
    if (r['success'] == true) {
      setState(() {
        _plats = List<CantinePlat>.from(r['plats'] as List);
        for (final k in _publie.keys) {
          _publie[k] = (r['publie'] as Map<String, bool>)[k] ?? false;
        }
        final prm = r['parametres'] as CantineParametres;
        _ouverture = prm.ouverture;
        _fermeture = prm.fermeture;
        _lieuCtrl.text = prm.lieu;
        _loading = false;
      });
    } else {
      setState(() { _error = r['error'] as String?; _loading = false; });
    }
  }

  Future<void> _choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (d != null) {
      _reinitialiserFormulaire();
      setState(() => _date = d);
      _charger();
    }
  }

  void _snack(String msg, {bool erreur = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: erreur ? Colors.redAccent : const Color(0xFF1E293B)),
    );
  }

  // ── Reprendre le menu d'un autre jour ───────────────────────────────────
  String _isoDe(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _dateCourte(DateTime d) => '${_jours[d.weekday - 1]} ${d.day} ${_mois[d.month - 1]}';

  Future<void> _reprendreMenu() async {
    final src = await showDatePicker(
      context: context,
      initialDate: _date.subtract(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      helpText: 'Reprendre le menu du…',
    );
    if (src == null || !mounted) return;
    final srcIso = _isoDe(src);
    if (srcIso == _dateIso) {
      _snack('Choisissez un autre jour que celui affiché.', erreur: true);
      return;
    }
    final choix = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reprendre ce menu ?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text("Les plats du ${_dateCourte(src)} seront copiés vers le ${_dateLongue}. "
            "Rien n'est publié : vous pourrez les vérifier avant."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          OutlinedButton(onPressed: () => Navigator.pop(ctx, 'repas'), child: Text(_libelleRepas)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'tous'),
            style: ElevatedButton.styleFrom(backgroundColor: _bleu, foregroundColor: Colors.white, elevation: 0),
            child: const Text('Tous les repas'),
          ),
        ],
      ),
    );
    if (choix == null || !mounted) return;
    setState(() => _reprise = true);
    final r = await CantineService.copier(source: srcIso, cible: _dateIso, repas: choix == 'repas' ? _repas : null);
    if (!mounted) return;
    setState(() {
      _reprise = false;
      if (r['success'] == true) _plats.addAll(List<CantinePlat>.from(r['plats'] as List));
    });
    if (r['success'] == true) {
      _snack(r['message'] as String? ?? 'Menu repris.');
    } else {
      _snack(r['error'] as String? ?? 'Erreur.', erreur: true);
    }
  }

  Widget _barreReprise(bool compact) {
    final bouton = OutlinedButton.icon(
      onPressed: _reprise ? null : _reprendreMenu,
      icon: _reprise
          ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.content_copy_rounded, size: 17),
      label: const Text('Reprendre un menu'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _bleu,
        side: const BorderSide(color: Color(0xFFC7D7F8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: 10),
      decoration: _carte,
      child: Row(children: [
        const Icon(Icons.history_rounded, color: _bleu, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            compact ? "Même menu qu'un autre jour ?" : "Vous servez le même menu qu'un autre jour ? Reprenez-le au lieu de le retaper.",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 10),
        bouton,
      ]),
    );
  }

  List<CantinePlat> get _platsDuRepas => _plats.where((p) => p.repas == _repas).toList();

  List<CantinePlat> get _platsAffiches {
    final q = _norm(_rechCtrl.text);
    return _platsDuRepas.where((p) {
      if (_filtre != 'tous' && p.categorie != _filtre) return false;
      if (q.isNotEmpty && !_norm('${p.nom} ${p.description}').contains(q)) return false;
      return true;
    }).toList();
  }

  // ── Formulaire ──────────────────────────────────────────────────────────
  void _reinitialiserFormulaire() {
    _nomCtrl.clear();
    _descCtrl.clear();
    _prixCtrl.clear();
    _categorie = 'plat_principal';
    _disponible = true;
    _imageBytes = null;
    _imageUrl = null;
    _edition = null;
  }

  Future<void> _choisirImage() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1280);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        _snack('Image trop lourde (2 Mo maximum).', erreur: true);
        return;
      }
      if (!mounted) return;
      setState(() { _imageBytes = bytes; _imageNom = f.name.isEmpty ? 'plat.jpg' : f.name; });
    } catch (_) {
      _snack('Impossible de charger cette image.', erreur: true);
    }
  }

  void _modifierPlat(CantinePlat p) {
    setState(() {
      _edition = p;
      _nomCtrl.text = p.nom;
      _descCtrl.text = p.description;
      _prixCtrl.text = '${p.prix}';
      _categorie = p.categorie;
      _disponible = p.disponible;
      _imageBytes = null;
      _imageUrl = p.imageUrl;
    });
    if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _enregistrerPlat() async {
    final nom = _nomCtrl.text.trim();
    final prix = int.tryParse(_prixCtrl.text.trim().replaceAll(RegExp(r'\s'), ''));
    if (nom.isEmpty || prix == null || prix < 0) {
      _snack('Nom et prix valides requis.', erreur: true);
      return;
    }
    setState(() => _envoi = true);
    String? url = _imageUrl;
    if (_imageBytes != null) {
      final up = await CantineService.televerserImage(_imageBytes!, _imageNom);
      if (up['success'] != true) {
        if (mounted) setState(() => _envoi = false);
        _snack(up['error'] as String? ?? "Échec de l'envoi de la photo.", erreur: true);
        return;
      }
      url = up['url'] as String?;
    }
    final Map<String, dynamic> r;
    if (_edition == null) {
      r = await CantineService.creer(
        date: _dateIso, repas: _repas, nom: nom, prix: prix,
        description: _descCtrl.text.trim(), categorie: _categorie, imageUrl: url, disponible: _disponible,
      );
    } else {
      r = await CantineService.modifier(_edition!.id, {
        'nom': nom, 'prix': prix, 'description': _descCtrl.text.trim(),
        'categorie': _categorie, 'image_url': url ?? '', 'disponible': _disponible,
      });
    }
    if (!mounted) return;
    setState(() => _envoi = false);
    if (r['success'] == true) {
      final plat = r['plat'] as CantinePlat;
      setState(() {
        final i = _plats.indexWhere((x) => x.id == plat.id);
        if (i >= 0) { _plats[i] = plat; } else { _plats.add(plat); }
        _reinitialiserFormulaire();
      });
      _snack(_edition == null ? 'Plat ajouté.' : 'Plat modifié.');
    } else {
      _snack(r['error'] as String? ?? 'Erreur.', erreur: true);
    }
  }

  Future<void> _basculerDisponible(CantinePlat p) async {
    final avant = p.disponible;
    setState(() => p.disponible = !avant);
    final r = await CantineService.modifier(p.id, {'disponible': !avant});
    if (r['success'] != true && mounted) {
      setState(() => p.disponible = avant);
      _snack(r['error'] as String? ?? 'Erreur.', erreur: true);
    }
  }

  Future<void> _supprimerPlat(CantinePlat p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce plat ?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text('« ${p.nom} » sera retiré du menu. Pensez à mettre le menu à jour si il est déjà publié.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.danger, foregroundColor: Colors.white, elevation: 0),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final r = await CantineService.supprimer(p.id);
    if (!mounted) return;
    if (r['success'] == true) {
      setState(() {
        _plats.removeWhere((x) => x.id == p.id);
        if (_edition?.id == p.id) _reinitialiserFormulaire();
      });
      _snack('Plat supprimé.');
    } else {
      _snack(r['error'] as String? ?? 'Erreur.', erreur: true);
    }
  }

  Future<void> _publier() async {
    final dispo = _platsDuRepas.where((p) => p.disponible).length;
    if (dispo == 0) {
      _snack('Ajoutez au moins un plat disponible avant de publier.', erreur: true);
      return;
    }
    setState(() => _publication = true);
    final r = await CantineService.publier(_dateIso, _repas);
    if (!mounted) return;
    setState(() => _publication = false);
    if (r['success'] == true) {
      setState(() => _publie[_repas] = true);
      _snack('${r['message'] ?? 'Menu publié.'} ($dispo plat${dispo > 1 ? 's' : ''})');
    } else {
      _snack(r['error'] as String? ?? 'Erreur lors de la publication.', erreur: true);
    }
  }

  // ── Commandes ───────────────────────────────────────────────────────────
  String get _dateCmdIso =>
      '${_dateCmd.year.toString().padLeft(4, '0')}-${_dateCmd.month.toString().padLeft(2, '0')}-${_dateCmd.day.toString().padLeft(2, '0')}';

  Future<void> _chargerCommandes({bool silencieux = false}) async {
    if (!silencieux) setState(() { _cmdChargement = true; _cmdErreur = null; });
    final r = await CantineService.commandes(statut: _statutCmd, date: _statutCmd == 'en_cours' ? null : _dateCmdIso);
    if (!mounted) return;
    setState(() {
      _cmdChargement = false;
      if (r['success'] == true) {
        _commandes = List<CantineCommande>.from(r['commandes'] as List);
        _nbEnCours = r['en_cours'] as int;
        _cmdErreur = null;
      } else if (!silencieux) {
        _cmdErreur = r['error'] as String?;
      }
    });
  }

  Future<void> _traiter(CantineCommande c) async {
    setState(() => _cmdEnTraitement.add(c.id));
    final r = await CantineService.traiterCommande(c.id);
    if (!mounted) return;
    setState(() => _cmdEnTraitement.remove(c.id));
    if (r['success'] == true) {
      setState(() {
        _commandes.removeWhere((x) => x.id == c.id);
        if (_nbEnCours > 0) _nbEnCours--;
      });
      _snack('Commande ${c.ticket} traitée.');
    } else {
      _snack(r['error'] as String? ?? 'Erreur.', erreur: true);
      _chargerCommandes(silencieux: true);
    }
  }

  Future<void> _choisirDateCmd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dateCmd,
      firstDate: DateTime.now().subtract(const Duration(days: 120)),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(() => _dateCmd = d);
      _chargerCommandes();
    }
  }

  List<CantineCommande> get _commandesAffichees {
    final q = _norm(_cmdRech.text);
    if (q.isEmpty) return _commandes;
    return _commandes.where((c) => _norm('${c.ticket} ${c.nom} ${c.prenoms} ${c.matricule} ${c.filiere}').contains(q)).toList();
  }

  Widget _onglets(bool compact) {
    Widget bouton(int i, IconData icone, String texte, {int pastille = 0}) {
      final actif = _onglet == i;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _onglet = i),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: compact ? 11 : 13),
            decoration: BoxDecoration(
              color: actif ? _bleu : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: actif ? _bleu : const Color(0xFFE2E8F0)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icone, size: 19, color: actif ? Colors.white : _bleu),
              const SizedBox(width: 8),
              Text(texte, style: TextStyle(fontSize: compact ? 13 : 14.5, fontWeight: FontWeight.w800, color: actif ? Colors.white : const Color(0xFF1E293B))),
              if (pastille > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: actif ? Colors.white : const Color(0xFFEF4444), borderRadius: BorderRadius.circular(10)),
                  child: Text('$pastille', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: actif ? _bleu : Colors.white)),
                ),
              ],
            ]),
          ),
        ),
      );
    }

    return Row(children: [
      bouton(0, Icons.restaurant_menu_rounded, 'Menu du jour'),
      const SizedBox(width: 10),
      bouton(1, Icons.receipt_long_rounded, 'Commandes', pastille: _nbEnCours),
    ]);
  }

  Widget _vueCommandes(bool compact, double w) {
    final affichees = _commandesAffichees;
    final colonnes = w >= 1050 ? 3 : (w >= 700 ? 2 : 1);

    Widget puce(String cle, String texte) {
      final actif = _statutCmd == cle;
      return InkWell(
        onTap: () {
          if (_statutCmd == cle) return;
          setState(() => _statutCmd = cle);
          _chargerCommandes();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: actif ? _bleu : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: actif ? _bleu : const Color(0xFFE2E8F0)),
          ),
          child: Text(texte, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: actif ? Colors.white : const Color(0xFF1E293B))),
        ),
      );
    }

    final filtres = Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      puce('en_cours', 'En cours ($_nbEnCours)'),
      puce('traitee', 'Traitées'),
      if (_statutCmd == 'traitee')
        InkWell(
          onTap: _choisirDateCmd,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text('${_dateCmd.day.toString().padLeft(2, '0')}/${_dateCmd.month.toString().padLeft(2, '0')}/${_dateCmd.year}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
    ]);
    final recherche = SizedBox(
      width: compact ? double.infinity : 280,
      child: TextField(
        controller: _cmdRech,
        onChanged: (_) => setState(() {}),
        decoration: _champ('Ticket, nom ou prénom...', Icons.search_rounded).copyWith(
          suffixIcon: _cmdRech.text.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded, size: 16), onPressed: () => setState(() => _cmdRech.clear())),
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: _carte,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.receipt_long_rounded, color: _bleu, size: 22),
          const SizedBox(width: 10),
          const Expanded(child: Text('Commandes des étudiants', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F2A5F)))),
          IconButton(tooltip: 'Actualiser', onPressed: _chargerCommandes, icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B))),
        ]),
        const SizedBox(height: 10),
        if (compact) ...[filtres, const SizedBox(height: 10), recherche] else Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: filtres), const SizedBox(width: 12), recherche]),
        const SizedBox(height: 14),
        if (_cmdChargement)
          const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Center(child: CircularProgressIndicator()))
        else if (_cmdErreur != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Column(children: [
              Text(_cmdErreur!, style: const TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _chargerCommandes, child: const Text('Réessayer')),
            ])),
          )
        else if (affichees.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(child: Column(children: [
              const Icon(Icons.inbox_rounded, size: 36, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 8),
              Text(_commandes.isEmpty ? (_statutCmd == 'en_cours' ? 'Aucune commande en cours.' : 'Aucune commande traitée ce jour-là.') : 'Aucune commande ne correspond à la recherche.',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
            ])),
          )
        else
          LayoutBuilder(builder: (context, c) {
            const ecart = 14.0;
            final largeur = (c.maxWidth - ecart * (colonnes - 1)) / colonnes;
            return Wrap(spacing: ecart, runSpacing: ecart, children: [for (final cmd in affichees) SizedBox(width: largeur, child: _carteCommande(cmd))]);
          }),
      ]),
    );
  }

  Widget _carteCommande(CantineCommande c) {
    final enCours = c.statut == 'en_cours';
    final envoi = _cmdEnTraitement.contains(c.id);
    final parRepas = <String, List<CommandeLigne>>{};
    for (final l in c.lignes) {
      parRepas.putIfAbsent(l.repas, () => []).add(l);
    }
    String libelle(String r) => (_repasOptions.firstWhere((o) => o['val'] == r, orElse: () => {'label': r})['label'] as String);

    final (couleur, fond, texteStatut) = switch (c.statut) {
      'traitee' => (AdminTheme.success, AdminTheme.successLight, 'Traitée'),
      'annulee' => (AdminTheme.danger, AdminTheme.dangerLight, 'Annulée'),
      _ => (AdminTheme.warning, AdminTheme.warningLight, 'En cours'),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: enCours ? const Color(0xFFC7D7F8) : const Color(0xFFE8ECF4), width: enCours ? 1.4 : 1),
        boxShadow: const [BoxShadow(color: Color(0x0F1E293B), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _bleu, borderRadius: BorderRadius.circular(10)),
            child: Text(c.ticket, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('${c.dateFr} à ${c.heure.replaceFirst(':', 'h')}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(20)),
            child: Text(texteStatut, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: couleur)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(c.nomComplet.isEmpty ? 'Étudiant' : c.nomComplet, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F2A5F))),
        Text([c.filiere, c.niveau, if (c.matricule.isNotEmpty) c.matricule].where((e) => e.isNotEmpty).join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const Divider(height: 20),
        for (final e in parRepas.entries) ...[
          Text(libelle(e.key).toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Color(0xFF94A3B8))),
          const SizedBox(height: 4),
          for (final l in e.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: _bleuClair, borderRadius: BorderRadius.circular(7)),
                  child: Text('${l.quantite}×', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _bleu)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(l.nom, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5))),
                const SizedBox(width: 8),
                Text(_prixTexte(l.prix * l.quantite), style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ]),
            ),
          const SizedBox(height: 4),
        ],
        const Divider(height: 14),
        Row(children: [
          const Text('Total', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(_prixTexte(c.total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _bleu)),
        ]),
        if (enCours) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: envoi ? null : () => _traiter(c),
              icon: envoi
                  ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text('Commande traitée'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  // ── Horaires et lieu ────────────────────────────────────────────────────
  Future<void> _choisirHeure(bool ouverture) async {
    final txt = ouverture ? _ouverture : _fermeture;
    final p = txt.split(':');
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.tryParse(p.first) ?? 7, minute: int.tryParse(p.length > 1 ? p[1] : '0') ?? 0),
      builder: (ctx, child) => MediaQuery(data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (t == null) return;
    final v = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    setState(() { if (ouverture) { _ouverture = v; } else { _fermeture = v; } });
  }

  Future<void> _enregistrerHoraires() async {
    final lieu = _lieuCtrl.text.trim();
    if (lieu.isEmpty) {
      _snack('Indiquez le lieu de la cantine.', erreur: true);
      return;
    }
    if (_ouverture.compareTo(_fermeture) >= 0) {
      _snack("L'ouverture doit être avant la fermeture.", erreur: true);
      return;
    }
    setState(() => _paramEnvoi = true);
    final r = await CantineService.enregistrerParametres(CantineParametres(ouverture: _ouverture, fermeture: _fermeture, lieu: lieu));
    if (!mounted) return;
    setState(() => _paramEnvoi = false);
    _snack(r['success'] == true ? 'Horaires enregistrés.' : (r['error'] as String? ?? 'Erreur.'), erreur: r['success'] != true);
  }

  Widget _horaires(bool compact) {
    Widget heure(String label, String valeur, bool ouverture) => InkWell(
          onTap: () => _choisirHeure(ouverture),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.access_time_rounded, size: 17, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text('$label ', style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
              Text(CantineParametres.affiche(valeur), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
            ]),
          ),
        );
    final lieu = TextField(controller: _lieuCtrl, decoration: _champ('Lieu (ex. Restaurant universitaire)', Icons.place_outlined));
    final bouton = ElevatedButton.icon(
      onPressed: _paramEnvoi ? null : _enregistrerHoraires,
      icon: _paramEnvoi
          ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.check_rounded, size: 18),
      label: const Text('Enregistrer'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _bleu, foregroundColor: Colors.white, elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: _carte,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.schedule_rounded, color: _bleu, size: 22),
          SizedBox(width: 10),
          Expanded(child: Text('Horaires et lieu', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F2A5F)))),
        ]),
        const SizedBox(height: 4),
        const Text("Affichés aux étudiants dans le menu du jour (badge « Ouvert » selon l'heure).", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 12),
        if (compact) ...[
          Row(children: [Expanded(child: heure('Ouverture', _ouverture, true)), const SizedBox(width: 8), Expanded(child: heure('Fermeture', _fermeture, false))]),
          const SizedBox(height: 10),
          lieu,
          const SizedBox(height: 10),
          bouton,
        ] else
          Row(children: [
            heure('Ouverture', _ouverture, true),
            const SizedBox(width: 10),
            heure('Fermeture', _fermeture, false),
            const SizedBox(width: 10),
            Expanded(child: lieu),
            const SizedBox(width: 10),
            bouton,
          ]),
      ]),
    );
  }

  // ── Construction ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: LayoutBuilder(builder: (context, box) {
        // Largeur réellement disponible (le menu latéral de l'admin est déjà retiré).
        final w = box.maxWidth;
        final compact = w < 640;
        return _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _etatErreur()
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(compact ? 12 : 20),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1250),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _entete(compact),
                            const SizedBox(height: 12),
                            _onglets(compact),
                            const SizedBox(height: 12),
                            if (_onglet == 1)
                              _vueCommandes(compact, w)
                            else ...[
                              _selecteurRepas(compact),
                              const SizedBox(height: 12),
                              _barreReprise(compact),
                              const SizedBox(height: 12),
                              _formulaire(compact, w),
                              const SizedBox(height: 12),
                              _liste(compact, w),
                              const SizedBox(height: 12),
                              _horaires(compact),
                            ],
                          ]),
                        ),
                      ),
                    ],
                  ),
                );
      }),
    );
  }

  Widget _etatErreur() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 32),
          const SizedBox(height: 12),
          Text(_error ?? 'Erreur', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _charger, child: const Text('Réessayer')),
        ]),
      );

  BoxDecoration get _carte => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF4)),
        boxShadow: const [BoxShadow(color: Color(0x0F1E293B), blurRadius: 12, offset: Offset(0, 4))],
      );

  // ── En-tête ─────────────────────────────────────────────────────────────
  Widget _entete(bool compact) {
    final publie = _publie[_repas] == true;
    final dateBtn = InkWell(
      onTap: _choisirDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF334155)),
          const SizedBox(width: 8),
          Flexible(child: Text(_dateLongue, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)))),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
        ]),
      ),
    );
    final publierBtn = ElevatedButton.icon(
      onPressed: _publication ? null : _publier,
      icon: _publication
          ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.send_rounded, size: 17),
      label: Text(publie ? 'Mettre à jour le menu' : 'Publier le menu'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _bleu, foregroundColor: Colors.white, elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    final titre = Row(children: [
      Container(
        width: compact ? 44 : 56, height: compact ? 44 : 56,
        decoration: BoxDecoration(color: _bleu, borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.restaurant_rounded, color: Colors.white, size: compact ? 24 : 30),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Menu de la cantine', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: compact ? 18 : 24, fontWeight: FontWeight.w800, color: const Color(0xFF0F2A5F))),
          const SizedBox(height: 2),
          const Text('Gérez et publiez les plats proposés aux étudiants.', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
        ]),
      ),
    ]);
    return Container(
      decoration: _carte,
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned(
          right: 0, top: 0, bottom: 0,
          width: compact ? 130 : 640,
          child: Opacity(opacity: compact ? 0.55 : 1, child: CustomPaint(painter: _BandeauPainter(compact ? 1.0 : 0.5))),
        ),
        Padding(
          padding: EdgeInsets.all(compact ? 14 : 18),
          child: compact
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  titre,
                  if (_onglet == 0) ...[
                    const SizedBox(height: 12),
                    dateBtn,
                    const SizedBox(height: 8),
                    publierBtn,
                  ],
                ])
              : Row(children: [
                  Expanded(child: titre),
                  if (_onglet == 0) ...[const SizedBox(width: 16), dateBtn, const SizedBox(width: 12), publierBtn],
                ]),
        ),
      ]),
    );
  }

  // ── Repas ───────────────────────────────────────────────────────────────
  Widget _selecteurRepas(bool compact) {
    return Row(children: [
      for (final r in _repasOptions)
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: r == _repasOptions.last ? 0 : (compact ? 6 : 10)),
            child: _boutonRepas(r, compact),
          ),
        ),
    ]);
  }

  Widget _boutonRepas(Map<String, Object> r, bool compact) {
    final val = r['val'] as String;
    final actif = _repas == val;
    final nb = _plats.where((p) => p.repas == val).length;
    final publie = _publie[val] == true;
    return InkWell(
      onTap: () {
        if (_repas == val) return;
        setState(() { _repas = val; _filtre = 'tous'; _rechCtrl.clear(); _reinitialiserFormulaire(); });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 14, vertical: compact ? 10 : 12),
        decoration: BoxDecoration(
          color: actif ? _bleu : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: actif ? _bleu : const Color(0xFFE2E8F0)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (!compact) ...[Icon(r['icon'] as IconData, size: 18, color: actif ? Colors.white : _bleu), const SizedBox(width: 8)],
            Flexible(
              child: Text(r['label'] as String, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: compact ? 12 : 13.5, fontWeight: FontWeight.w800, color: actif ? Colors.white : const Color(0xFF1E293B))),
            ),
          ]),
          const SizedBox(height: 3),
          Text('$nb plat${nb > 1 ? 's' : ''} · ${publie ? 'Publié' : 'Non publié'}',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: actif ? Colors.white70 : (publie ? AdminTheme.success : const Color(0xFF94A3B8)))),
        ]),
      ),
    );
  }

  // ── Formulaire d'ajout / modification ───────────────────────────────────
  InputDecoration _champ(String label, IconData icone) => InputDecoration(
        hintText: label,
        prefixIcon: Icon(icone, size: 19, color: const Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      );

  Widget _zoneImage(double hauteur, {double? largeur}) {
    final Widget contenu;
    if (_imageBytes != null) {
      contenu = Image.memory(_imageBytes!, fit: BoxFit.cover);
    } else if (_imageUrl != null) {
      contenu = Image.network(_imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Color(0xFF94A3B8)));
    } else {
      contenu = const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_photo_alternate_outlined, size: 30, color: _bleu),
        SizedBox(height: 6),
        Text('Télécharger une image', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _bleu)),
        SizedBox(height: 2),
        Text('PNG, JPG (max 2 Mo)', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
      ]);
    }
    final aImage = _imageBytes != null || _imageUrl != null;
    return SizedBox(
      width: largeur, height: hauteur,
      child: Stack(children: [
        Positioned.fill(
          child: InkWell(
            onTap: _choisirImage,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _bleuClair, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFC7D7F8))),
              child: aImage ? SizedBox.expand(child: contenu) : contenu,
            ),
          ),
        ),
        if (aImage)
          Positioned(
            top: 6, right: 6,
            child: InkWell(
              onTap: () => setState(() { _imageBytes = null; _imageUrl = null; }),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _formulaire(bool compact, double w) {
    final edition = _edition != null;
    final nom = TextField(controller: _nomCtrl, textCapitalization: TextCapitalization.sentences, decoration: _champ('Nom du plat *', Icons.restaurant_rounded));
    final desc = TextField(controller: _descCtrl, maxLines: 2, textCapitalization: TextCapitalization.sentences, decoration: _champ('Description (optionnelle)...', Icons.notes_rounded));
    final categorie = DropdownButtonFormField<String>(
      value: _categorie,
      isExpanded: true,
      decoration: _champ('Catégorie', _iconeCategorie(_categorie)),
      items: [for (final e in categoriesCantine.entries) DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))],
      onChanged: (v) => setState(() => _categorie = v ?? 'plat_principal'),
    );
    final prix = TextField(controller: _prixCtrl, keyboardType: TextInputType.number, decoration: _champ('Prix (FCFA) *', Icons.payments_outlined));
    final dispo = Row(mainAxisSize: MainAxisSize.min, children: [
      Switch(value: _disponible, onChanged: (v) => setState(() => _disponible = v), activeColor: _bleu),
      const Text('Disponible', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    ]);
    final bouton = ElevatedButton.icon(
      onPressed: _envoi ? null : _enregistrerPlat,
      icon: _envoi
          ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Icon(edition ? Icons.check_rounded : Icons.add_rounded, size: 18),
      label: Text(edition ? 'Enregistrer' : 'Ajouter le plat'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _bleu, foregroundColor: Colors.white, elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    final annuler = edition
        ? TextButton(onPressed: () => setState(_reinitialiserFormulaire), child: const Text('Annuler'))
        : const SizedBox.shrink();

    final titre = Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: _bleu, shape: BoxShape.circle),
        child: Icon(edition ? Icons.edit_rounded : Icons.add_rounded, color: Colors.white, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(edition ? 'Modifier le plat' : 'Ajouter un plat', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F2A5F))),
          Text('$_libelleRepas · $_dateLongue', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ]),
      ),
    ]);

    final Widget corps;
    if (w >= 880) {
      corps = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _zoneImage(150, largeur: 190),
        const SizedBox(width: 14),
        Expanded(
          child: Column(children: [
            nom,
            const SizedBox(height: 10),
            desc,
            const SizedBox(height: 10),
            Row(children: [
              Expanded(flex: 3, child: categorie),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: prix),
              const SizedBox(width: 10),
              dispo,
            ]),
          ]),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 200, height: 150,
          child: Stack(clipBehavior: Clip.none, children: [
            const Positioned(right: 0, top: -14, child: SizedBox(width: 190, height: 112, child: CustomPaint(painter: _ClochePainter()))),
            Positioned(right: 0, bottom: 0, child: Row(mainAxisSize: MainAxisSize.min, children: [annuler, bouton])),
          ]),
        ),
      ]);
    } else {
      corps = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _zoneImage(compact ? 130 : 150),
        const SizedBox(height: 10),
        nom,
        const SizedBox(height: 10),
        desc,
        const SizedBox(height: 10),
        if (compact) ...[categorie, const SizedBox(height: 10), prix] else Row(children: [Expanded(child: categorie), const SizedBox(width: 10), Expanded(child: prix)]),
        const SizedBox(height: 6),
        Row(children: [dispo, const Spacer(), annuler]),
        const SizedBox(height: 4),
        bouton,
      ]);
    }

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: _carte,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [titre, const SizedBox(height: 14), corps]),
    );
  }

  // ── Liste des plats ─────────────────────────────────────────────────────
  Widget _filtres(bool compact) {
    Widget puce(String cle, String texte) {
      final actif = _filtre == cle;
      return InkWell(
        onTap: () => setState(() => _filtre = cle),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: actif ? _bleu : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: actif ? _bleu : const Color(0xFFE2E8F0)),
          ),
          child: Text(texte, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: actif ? Colors.white : const Color(0xFF1E293B))),
        ),
      );
    }

    final puces = Wrap(spacing: 8, runSpacing: 8, children: [
      puce('tous', 'Tous'),
      puce('plat_principal', 'Plats principaux'),
      puce('entree', 'Entrées'),
      puce('accompagnement', 'Accompagnements'),
      puce('boisson', 'Boissons'),
      puce('dessert', 'Desserts'),
    ]);
    final recherche = SizedBox(
      width: compact ? double.infinity : 230,
      child: TextField(
        controller: _rechCtrl,
        onChanged: (_) => setState(() {}),
        decoration: _champ('Rechercher un plat...', Icons.search_rounded).copyWith(
          suffixIcon: _rechCtrl.text.isEmpty
              ? null
              : IconButton(icon: const Icon(Icons.close_rounded, size: 16), onPressed: () => setState(() => _rechCtrl.clear())),
        ),
      ),
    );
    return compact
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [puces, const SizedBox(height: 10), recherche])
        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: puces), const SizedBox(width: 12), recherche]);
  }

  Widget _liste(bool compact, double w) {
    final affiches = _platsAffiches;
    final colonnes = w >= 1050 ? 4 : (w >= 780 ? 3 : (w >= 480 ? 2 : 1));
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: _carte,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.restaurant_menu_rounded, color: _bleu, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text('Liste des plats · $_libelleRepas', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F2A5F)))),
          Text('${_platsDuRepas.length} plat${_platsDuRepas.length > 1 ? 's' : ''}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        _filtres(compact),
        const SizedBox(height: 14),
        if (affiches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Column(children: [
                const Icon(Icons.no_meals_rounded, size: 34, color: Color(0xFFCBD5E1)),
                const SizedBox(height: 8),
                Text(_platsDuRepas.isEmpty ? 'Aucun plat pour ce repas. Ajoutez le premier ci-dessus.' : 'Aucun plat ne correspond à ce filtre.',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
              ]),
            ),
          )
        else
          LayoutBuilder(builder: (context, c) {
            const ecart = 14.0;
            final largeur = (c.maxWidth - ecart * (colonnes - 1)) / colonnes;
            return Wrap(
              spacing: ecart, runSpacing: ecart,
              children: [for (final p in affiches) SizedBox(width: largeur, child: _cartePlat(p))],
            );
          }),
      ]),
    );
  }

  Widget _cartePlat(CantinePlat p) {
    final (fg, bg) = _couleursCategorie(p.categorie);
    final enEdition = _edition?.id == p.id;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: enEdition ? _bleu : const Color(0xFFE8ECF4), width: enEdition ? 1.6 : 1),
        boxShadow: const [BoxShadow(color: Color(0x0F1E293B), blurRadius: 10, offset: Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(fit: StackFit.expand, children: [
              if (p.imageUrl != null)
                Image.network(p.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imageVide(p.categorie, fg, bg))
              else
                _imageVide(p.categorie, fg, bg),
              Positioned(
                top: 8, right: 8,
                child: InkWell(
                  onTap: () => _basculerDisponible(p),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.circle, size: 9, color: p.disponible ? AdminTheme.success : AdminTheme.danger),
                      const SizedBox(width: 5),
                      Text(p.disponible ? 'Disponible' : 'Indisponible',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: p.disponible ? AdminTheme.success : AdminTheme.danger)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Icon(_iconeCategorie(p.categorie), size: 17, color: _bleu),
          const SizedBox(width: 6),
          Expanded(child: Text(p.nom, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F2A5F)))),
        ]),
        const SizedBox(height: 4),
        Text(p.description.isEmpty ? 'Aucune description.' : p.description,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: p.description.isEmpty ? const Color(0xFFB6C0CF) : const Color(0xFF64748B))),
        const SizedBox(height: 10),
        Row(children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Text(categoriesCantine[p.categorie] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: fg)),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: _bleuClair, borderRadius: BorderRadius.circular(10)),
            child: Text(_prixTexte(p.prix), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _bleu)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _modifierPlat(p),
              icon: const Icon(Icons.edit_outlined, size: 15),
              label: const Text('Modifier'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _bleu, side: const BorderSide(color: _bleu),
                padding: const EdgeInsets.symmetric(vertical: 10), textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _supprimerPlat(p),
              icon: const Icon(Icons.delete_outline_rounded, size: 15),
              label: const Text('Supprimer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminTheme.danger, side: BorderSide(color: AdminTheme.danger.withValues(alpha: 0.6)),
                padding: const EdgeInsets.symmetric(vertical: 10), textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _imageVide(String categorie, Color fg, Color bg) => Container(
        color: bg,
        alignment: Alignment.center,
        child: Icon(_iconeCategorie(categorie), size: 38, color: fg.withValues(alpha: 0.55)),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// DÉCORS (dessinés en code, aucune image à ajouter au projet)
// ════════════════════════════════════════════════════════════════════════════

/// Bandeau bleu et jaune de l'en-tête (courbes à droite de la carte).
class _BandeauPainter extends CustomPainter {
  /// Étirement horizontal : < 1 rapproche le bandeau du bord gauche de la zone (avant la date).
  final double echelle;
  const _BandeauPainter(this.echelle);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(echelle, 1);
    final w = size.width, h = size.height;
    final zone = Rect.fromLTWH(0, 0, w, h);

    // Large courbe jaune
    final jaune = Path()
      ..moveTo(w * 0.58, 0)
      ..lineTo(w * 0.88, 0)
      ..quadraticBezierTo(w * 0.66, h * 0.62, w * 0.20, h)
      ..lineTo(w * 0.02, h)
      ..quadraticBezierTo(w * 0.50, h * 0.58, w * 0.58, 0)
      ..close();
    canvas.drawPath(
      jaune,
      Paint()..shader = const LinearGradient(colors: [Color(0xFFFFC21A), Color(0xFFFFE08A)], begin: Alignment.topRight, end: Alignment.bottomLeft).createShader(zone),
    );

    // Vague bleue en bas
    final bleu = Path()
      ..moveTo(0, h)
      ..quadraticBezierTo(w * 0.30, h * 0.60, w * 0.74, h * 0.52)
      ..quadraticBezierTo(w * 0.52, h * 0.80, w * 0.46, h)
      ..close();
    canvas.drawPath(
      bleu,
      Paint()..shader = const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)], begin: Alignment.bottomLeft, end: Alignment.topRight).createShader(zone),
    );

    // Petit éclat bleu accroché à la courbe jaune
    final eclat = Path()
      ..moveTo(w * 0.70, h)
      ..quadraticBezierTo(w * 0.74, h * 0.62, w * 0.80, h * 0.52)
      ..quadraticBezierTo(w * 0.86, h * 0.72, w * 0.84, h)
      ..close();
    canvas.drawPath(eclat, Paint()..color = const Color(0xFF2563EB).withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant _BandeauPainter old) => old.echelle != echelle;
}

/// Cloche de service argentée avec soleil jaune derrière.
class _ClochePainter extends CustomPainter {
  const _ClochePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Halo bleuté
    canvas.drawCircle(
      Offset(w * 0.52, h * 0.55), h * 0.62,
      Paint()..shader = RadialGradient(colors: [const Color(0xFFDCE8FF).withValues(alpha: 0.9), const Color(0x00DCE8FF)]).createShader(Rect.fromCircle(center: Offset(w * 0.52, h * 0.55), radius: h * 0.62)),
    );

    // Soleil jaune
    final soleil = Offset(w * 0.66, h * 0.50);
    canvas.drawCircle(
      soleil, h * 0.40,
      Paint()..shader = const LinearGradient(colors: [Color(0xFFFFD34D), Color(0xFFFFB400)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(Rect.fromCircle(center: soleil, radius: h * 0.40)),
    );

    // Rayons à gauche du dôme
    final rayon = Paint()..color = const Color(0xFFFFC21A)..strokeWidth = 3.2..strokeCap = StrokeCap.round;
    for (final a in [-2.55, -2.2, -1.85]) {
      final r1 = h * 0.50, r2 = h * 0.64;
      final c = Offset(w * 0.46, h * 0.52);
      canvas.drawLine(c + Offset(math.cos(a) * r1, math.sin(a) * r1), c + Offset(math.cos(a) * r2, math.sin(a) * r2), rayon);
    }

    // Ombre portée de l'assiette
    canvas.drawOval(Rect.fromLTWH(w * 0.08, h * 0.80, w * 0.84, h * 0.13), Paint()..color = const Color(0x33000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // Assiette
    final assiette = Rect.fromLTWH(w * 0.06, h * 0.74, w * 0.88, h * 0.15);
    canvas.drawOval(
      assiette,
      Paint()..shader = const LinearGradient(colors: [Color(0xFF9AA3B2), Color(0xFFF8FAFC), Color(0xFFB4BCC9), Color(0xFF7C8594)], stops: [0, 0.35, 0.7, 1]).createShader(assiette),
    );

    // Dôme
    final dome = Path()
      ..moveTo(w * 0.13, h * 0.80)
      ..cubicTo(w * 0.10, h * 0.30, w * 0.30, h * 0.14, w * 0.50, h * 0.14)
      ..cubicTo(w * 0.70, h * 0.14, w * 0.90, h * 0.30, w * 0.87, h * 0.80)
      ..close();
    final zoneDome = Rect.fromLTWH(w * 0.10, h * 0.14, w * 0.80, h * 0.66);
    canvas.drawPath(
      dome,
      Paint()..shader = const LinearGradient(colors: [Color(0xFF8E97A6), Color(0xFFE5E9F0), Color(0xFFFFFFFF), Color(0xFFB8C0CC), Color(0xFF7A8394)], stops: [0, 0.22, 0.42, 0.75, 1]).createShader(zoneDome),
    );
    canvas.drawPath(dome, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0x40475569));

    // Reflet sur le dôme
    final reflet = Path()
      ..moveTo(w * 0.22, h * 0.62)
      ..quadraticBezierTo(w * 0.22, h * 0.34, w * 0.40, h * 0.24);
    canvas.drawPath(reflet, Paint()..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round..color = Colors.white.withValues(alpha: 0.85));

    // Poignée
    final poignee = Rect.fromCenter(center: Offset(w * 0.50, h * 0.12), width: w * 0.11, height: h * 0.13);
    canvas.drawOval(poignee, Paint()..shader = const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFF9AA3B2)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(poignee));
    canvas.drawOval(poignee, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = const Color(0x40475569));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
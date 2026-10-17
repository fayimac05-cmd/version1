import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../admin/admin_theme.dart';
import '../pages/create_event_page.dart';
import '../services/api_service.dart';

// ════════════════════════════════════════════════════════════════════════════
// ENUMS & CONFIGURATIONS MÉTIER
// ════════════════════════════════════════════════════════════════════════════
enum PorteeAnnonce { globale, filiere, niveau }
enum StatutAnnonce { brouillon, publie }

const Color _emeraldColor = Color(0xFF10B981);
const Color _navy = Color(0xFF0B1E4D);

const List<Map<String, String>> cibleRoleOptions = [
  {'val': 'tous', 'label': 'Tout l\'établissement'},
  {'val': 'etudiant', 'label': 'Étudiants'},
  {'val': 'professeur', 'label': 'Professeurs'},
  {'val': 'bde', 'label': 'BDE'},
];

final List<String> istNiveaux = ['Licence 1', 'Licence 2', 'Licence 3', 'Master 1', 'Master 2'];

class Annonce {
  final String id;
  String titre, contenu;
  String cibleRole;
  String? filiereId, filiereNom, niveau, categorie;
  StatutAnnonce statut;
  final DateTime dateCreation;
  List<String> fichiers;

  Annonce({
    required this.id, required this.titre, required this.contenu,
    required this.cibleRole, required this.statut,
    required this.dateCreation, this.filiereId, this.filiereNom, this.niveau,
    this.categorie,
    List<String>? fichiers,
  }) : fichiers = fichiers ?? [];

  factory Annonce.fromJson(Map<String, dynamic> json) {
    return Annonce(
      id: json['id'].toString(),
      titre: json['titre'] ?? '',
      contenu: json['contenu'] ?? '',
      cibleRole: json['cibleRole'] ?? 'tous',
      filiereId: json['filiere']?.toString(),
      filiereNom: json['filiere_nom'],
      niveau: json['niveau'],
      categorie: json['categorie']?.toString(),
      statut: json['statut'] == 'publie' ? StatutAnnonce.publie : StatutAnnonce.brouillon,
      dateCreation: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      fichiers: (json['fichiers'] as List<dynamic>? ?? []).map((f) => f.toString()).toList(),
    );
  }

  PorteeAnnonce get portee {
    if (filiereId != null && filiereId!.isNotEmpty) return PorteeAnnonce.filiere;
    if (niveau != null && niveau!.isNotEmpty) return PorteeAnnonce.niveau;
    return PorteeAnnonce.globale;
  }
}

class AnnonceUiConfig {
  final String label;
  final IconData icon;
  final Color color;
  const AnnonceUiConfig({required this.label, required this.icon, required this.color});

  // Catégorie (champ réel `categorie`) ; à défaut, on retombe sur le rôle ciblé.
  static AnnonceUiConfig getConfig(String? categorie, String cibleRole) {
    switch (categorie) {
      case 'generale':
        return const AnnonceUiConfig(label: 'Générale', icon: Icons.campaign_outlined, color: AdminTheme.iconFg);
      case 'etudiants':
        return const AnnonceUiConfig(label: 'Étudiants', icon: Icons.school_outlined, color: Color(0xFF7C3AED));
      case 'evenement':
        return const AnnonceUiConfig(label: 'Événement', icon: Icons.event_outlined, color: _emeraldColor);
      case 'administration':
        return const AnnonceUiConfig(label: 'Administration', icon: Icons.account_balance_outlined, color: Color(0xFFD97706));
      default:
        return getCibleConfig(cibleRole);
    }
  }

  static AnnonceUiConfig getCibleConfig(String cibleRole) {
    switch (cibleRole) {
      case 'etudiant':
        return const AnnonceUiConfig(label: 'Étudiants', icon: Icons.school_outlined, color: Color(0xFF7C3AED));
      case 'professeur':
        return const AnnonceUiConfig(label: 'Professeurs', icon: Icons.assignment_ind_outlined, color: Colors.purple);
      case 'bde':
        return const AnnonceUiConfig(label: 'BDE', icon: Icons.groups_outlined, color: _emeraldColor);
      default:
        return const AnnonceUiConfig(label: 'Générale', icon: Icons.campaign_outlined, color: AdminTheme.iconFg);
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PETIT DROPDOWN RÉUTILISABLE — PopupMenuButton plutôt que DropdownButton.
// Sur Flutter Web, plusieurs DropdownButton sur un même écran (ou des
// setState() rapprochés) déclenchent une assertion de mouse_tracker.dart qui
// fige l'écran. Ce correctif, déjà appliqué ailleurs dans l'admin et côté
// professeur, est repris ici pour tous les filtres/sélecteurs de cette page.
// ════════════════════════════════════════════════════════════════════════════
class _PopupDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final double? width;

  const _PopupDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.width,
  });

  Widget _label() => Text(
        value != null ? labelOf(value as T) : hint,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: value != null ? const Color(0xFF334155) : const Color(0xFF94A3B8),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => items
          .map((it) => PopupMenuItem<T>(
                value: it,
                child: Text(labelOf(it), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ))
          .toList(),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          // Expanded uniquement quand la largeur est bornée (formulaire) ;
          // dans la barre de filtres / la pagination la largeur est libre et
          // un Expanded y provoquerait une erreur de layout (écran blanc).
          if (width != null)
            Expanded(child: _label())
          else
            _label(),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
        ]),
      ),
    );
  }
}

enum _PeriodeFiltre { tout, aujourdhui, semaine, mois }

String _periodeLabel(_PeriodeFiltre p) {
  switch (p) {
    case _PeriodeFiltre.tout: return 'Tout le temps';
    case _PeriodeFiltre.aujourdhui: return 'Aujourd\'hui';
    case _PeriodeFiltre.semaine: return 'Cette semaine';
    case _PeriodeFiltre.mois: return 'Ce mois';
  }
}

// ════════════════════════════════════════════════════════════════════════════
// VUE PRINCIPALE — TABLEAU DE BORD DES ANNONCES
// ════════════════════════════════════════════════════════════════════════════
class AdminAnnonces extends StatefulWidget {
  const AdminAnnonces({super.key});
  @override State<AdminAnnonces> createState() => _AdminAnnoncesState();
}

class _AdminAnnoncesState extends State<AdminAnnonces> {
  String _searchQuery = '';
  List<Annonce> _annonces = [];
  List<Map<String, dynamic>> _filieres = [];
  List<Map<String, dynamic>> _inscriptions = [];
  List<dynamic> _evenements = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Onglet (Annonces / Historique des inscriptions)
  bool _ongletHistorique = false;

  // Filtres (tous branchés sur des champs réellement présents côté backend)
  String? _filtreCible; // null = tous les rôles
  StatutAnnonce? _filtreStatut; // null = tous les statuts
  _PeriodeFiltre _filtrePeriode = _PeriodeFiltre.tout;

  // Pagination
  int _page = 1;
  int _parPage = 4;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    final results = await Future.wait([
      ApiService.getAnnonces(),
      ApiService.getFilieres(),
      ApiService.getHistoriqueInscriptions(),
      ApiService.getEvenements(),
    ]);
    final annoncesResult = results[0];
    final filieresResult = results[1];
    final inscriptionsResult = results[2];
    final evenementsResult = results[3];

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (annoncesResult['success'] == true) {
        _annonces = (annoncesResult['data'] as List<dynamic>)
            .map((j) => Annonce.fromJson(j as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = annoncesResult['error'] as String?;
      }
      if (filieresResult['success'] == true) {
        _filieres = (filieresResult['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      }
      if (inscriptionsResult['success'] == true) {
        _inscriptions = (inscriptionsResult['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      }
      if (evenementsResult['success'] == true) {
        _evenements = evenementsResult['data'] as List<dynamic>;
      }
      _page = 1;
    });
  }

  // ── Filtrage ─────────────────────────────────────────────────────────────
  List<Annonce> get _filteredAnnonces {
    var list = List<Annonce>.from(_annonces);
    if (_searchQuery.isNotEmpty) {
      list = list.where((a) =>
          a.titre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.contenu.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_filtreCible != null) {
      list = list.where((a) => a.cibleRole == _filtreCible).toList();
    }
    if (_filtreStatut != null) {
      list = list.where((a) => a.statut == _filtreStatut).toList();
    }
    if (_filtrePeriode != _PeriodeFiltre.tout) {
      final maintenant = DateTime.now();
      list = list.where((a) {
        final diff = maintenant.difference(a.dateCreation);
        switch (_filtrePeriode) {
          case _PeriodeFiltre.aujourdhui:
            return a.dateCreation.year == maintenant.year &&
                a.dateCreation.month == maintenant.month &&
                a.dateCreation.day == maintenant.day;
          case _PeriodeFiltre.semaine:
            return diff.inDays <= 7;
          case _PeriodeFiltre.mois:
            return diff.inDays <= 31;
          case _PeriodeFiltre.tout:
            return true;
        }
      }).toList();
    }
    list.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    return list;
  }

  List<Annonce> get _pageAnnonces {
    final list = _filteredAnnonces;
    final start = (_page - 1) * _parPage;
    if (start >= list.length) return [];
    final end = (start + _parPage).clamp(0, list.length);
    return list.sublist(start, end);
  }

  // ── KPI — uniquement des valeurs réellement calculables ─────────────────
  bool _estAujourdhui(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  int get _kpiTotal => _annonces.length;

  int get _kpiPublieesAujourdhui =>
      _annonces.where((a) => a.statut == StatutAnnonce.publie && _estAujourdhui(a.dateCreation)).length;

  // "En attente de validation" : les événements BDE soumis par les
  // étudiants et pas encore approuvés — un vrai statut déjà utilisé
  // ailleurs dans l'admin (tableau de bord), pas une donnée inventée pour
  // cette page.
  int get _kpiEvenementsEnAttente =>
      _evenements.where((e) => (e['statut'] ?? '') == 'en_attente').length;

  int get _kpiEvenementsAVenir {
    final maintenant = DateTime.now();
    return _evenements.where((e) {
      if (e['statut'] != 'approuve') return false;
      final d = DateTime.tryParse(e['date_debut']?.toString() ?? '');
      return d != null && d.isAfter(maintenant);
    }).length;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdminTheme.isDesktop(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isDesktop ? 28 : 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _header(isDesktop),
                    const SizedBox(height: 20),
                    _kpiRow(isDesktop),
                    const SizedBox(height: 20),
                    _ongletToggle(),
                    const SizedBox(height: 16),
                    if (_ongletHistorique)
                      _buildHistoriqueView()
                    else ...[
                      _filterBar(isDesktop),
                      const SizedBox(height: 16),
                      _annoncesList(),
                      const SizedBox(height: 14),
                      _pagination(),
                    ],
                  ]),
                ),
    );
  }

  Widget _buildErrorState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 32),
            const SizedBox(height: 12),
            Text(_errorMessage ?? 'Erreur', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadData, child: const Text('Réessayer')),
          ],
        ),
      );

  // ── En-tête ──────────────────────────────────────────────────────────────
  Widget _header(bool isDesktop) {
    final titre = Row(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: AdminTheme.iconBg, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.campaign_rounded, color: AdminTheme.iconFg, size: 24),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Annonces', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text('Consultez toutes les annonces publiées et gérez vos communications.',
              style: TextStyle(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ]),
      ),
    ]);

    final actions = Wrap(spacing: 10, runSpacing: 10, children: [
      OutlinedButton.icon(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventPage()));
          if (result != null) {
            _showSnack('🚀 Événement créé et approuvé — visible dans le carrousel étudiant.');
            _loadData();
          }
        },
        icon: const Icon(Icons.celebration_outlined, size: 17, color: _emeraldColor),
        label: const Text('Créer un événement', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _emeraldColor)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _emeraldColor),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      IconButton(
        onPressed: _isLoading ? null : _loadData,
        icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
        tooltip: 'Actualiser',
        style: IconButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Color(0xFFE2E8F0))),
      ),
      ElevatedButton.icon(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
        label: const Text('Nouvelle annonce', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _navy,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
    ]);

    if (isDesktop) {
      return Row(children: [Expanded(child: titre), const SizedBox(width: 16), actions]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [titre, const SizedBox(height: 14), actions]);
  }

  // ── KPI ──────────────────────────────────────────────────────────────────
  Widget _kpiRow(bool isDesktop) {
    final kpis = [
      {
        'icon': Icons.campaign_rounded, 'bg': AdminTheme.iconBg, 'fg': AdminTheme.iconFg,
        'value': '$_kpiTotal', 'label': 'Total des annonces', 'sub': 'Publiées + brouillons', 'subColor': const Color(0xFF94A3B8),
      },
      {
        'icon': Icons.send_rounded, 'bg': const Color(0xFFF3E8FF), 'fg': Colors.purple,
        'value': '$_kpiPublieesAujourdhui', 'label': 'Publiées aujourd\'hui', 'sub': 'Statut : en ligne', 'subColor': const Color(0xFF94A3B8),
      },
      {
        'icon': Icons.hourglass_top_rounded, 'bg': const Color(0xFFFEF3C7), 'fg': const Color(0xFFD97706),
        'value': '$_kpiEvenementsEnAttente', 'label': 'Événements BDE', 'sub': 'À vérifier', 'subColor': const Color(0xFFD97706),
      },
      {
        'icon': Icons.calendar_month_rounded, 'bg': AdminTheme.iconBg, 'fg': AdminTheme.iconFg,
        'value': '$_kpiEvenementsAVenir', 'label': 'Événements à venir', 'sub': 'Approuvés', 'subColor': const Color(0xFF94A3B8),
      },
    ];

    if (isDesktop) {
      return Row(children: kpis.map((k) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: kpis.indexOf(k) < kpis.length - 1 ? 16 : 0),
          child: _kpiCard(k),
        ),
      )).toList());
    }
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, mainAxisSpacing: 12, crossAxisSpacing: 12,
      childAspectRatio: 1.5, physics: const NeverScrollableScrollPhysics(),
      children: kpis.map((k) => _kpiCard(k)).toList(),
    );
  }

  Widget _kpiCard(Map<String, dynamic> k) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(AdminTheme.radiusCard),
      border: Border.all(color: AdminTheme.border), boxShadow: AdminTheme.cardShadow,
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(color: k['bg'] as Color, borderRadius: BorderRadius.circular(11)),
        child: Icon(k['icon'] as IconData, color: k['fg'] as Color, size: 21),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k['value'] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        const SizedBox(height: 2),
        Text(k['label'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
        const SizedBox(height: 2),
        Text(k['sub'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: k['subColor'] as Color)),
      ])),
    ]),
  );

  // ── Toggle Annonces / Historique ────────────────────────────────────────
  Widget _ongletToggle() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(11)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      _ongletBtn('Annonces (${_annonces.length})', !_ongletHistorique, () => setState(() => _ongletHistorique = false)),
      _ongletBtn('Historique inscriptions (${_inscriptions.length})', _ongletHistorique, () => setState(() => _ongletHistorique = true)),
    ]),
  );

  Widget _ongletBtn(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)] : null,
      ),
      child: Text(label, style: TextStyle(
        fontSize: 12.5, fontWeight: FontWeight.w700,
        color: active ? AdminTheme.iconFg : const Color(0xFF64748B),
      )),
    ),
  );

  // ── Barre de filtres ────────────────────────────────────────────────────
  Widget _filterBar(bool isDesktop) {
    final search = Container(
      height: 42,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: TextField(
        onChanged: (v) => setState(() { _searchQuery = v; _page = 1; }),
        decoration: const InputDecoration(
          hintText: 'Rechercher une annonce...',
          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 18),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );

    final filtres = Wrap(spacing: 10, runSpacing: 10, children: [
      _PopupDropdown<String>(
        value: _filtreCible,
        hint: 'Tous les destinataires',
        items: cibleRoleOptions.map((e) => e['val']!).toList(),
        labelOf: (v) => cibleRoleOptions.firstWhere((e) => e['val'] == v)['label']!,
        onChanged: (v) => setState(() { _filtreCible = v; _page = 1; }),
      ),
      _PopupDropdown<StatutAnnonce>(
        value: _filtreStatut,
        hint: 'Tous les statuts',
        items: const [StatutAnnonce.publie, StatutAnnonce.brouillon],
        labelOf: (v) => v == StatutAnnonce.publie ? 'En ligne' : 'Brouillon',
        onChanged: (v) => setState(() { _filtreStatut = v; _page = 1; }),
      ),
      _PopupDropdown<_PeriodeFiltre>(
        value: _filtrePeriode == _PeriodeFiltre.tout ? null : _filtrePeriode,
        hint: 'Tout le temps',
        items: _PeriodeFiltre.values,
        labelOf: _periodeLabel,
        onChanged: (v) => setState(() { _filtrePeriode = v; _page = 1; }),
      ),
      if (_filtreCible != null || _filtreStatut != null || _filtrePeriode != _PeriodeFiltre.tout)
        TextButton.icon(
          onPressed: () => setState(() { _filtreCible = null; _filtreStatut = null; _filtrePeriode = _PeriodeFiltre.tout; _page = 1; }),
          icon: const Icon(Icons.close_rounded, size: 15, color: Color(0xFF64748B)),
          label: const Text('Réinitialiser', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        ),
    ]);

    if (isDesktop) {
      return Row(children: [Expanded(flex: 2, child: search), const SizedBox(width: 12), Flexible(flex: 3, child: filtres)]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [search, const SizedBox(height: 10), filtres]);
  }

  // ── Liste des annonces ───────────────────────────────────────────────────
  Widget _annoncesList() {
    final items = _pageAnnonces;
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AdminTheme.radiusCard), border: Border.all(color: AdminTheme.border)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: AdminTheme.iconBg, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.campaign_outlined, color: AdminTheme.iconFg, size: 26)),
          const SizedBox(height: 16),
          const Text('Flux vide', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          const Text('Aucune publication ne correspond à ce critère.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        ]),
      );
    }
    return Column(children: items.map((a) => _buildAnnonceCard(a)).toList());
  }

  Widget _buildAnnonceCard(Annonce a) {
    final cibleConfig = AnnonceUiConfig.getConfig(a.categorie, a.cibleRole);
    final statusColor = a.statut == StatutAnnonce.publie ? _emeraldColor : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: cibleConfig.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(cibleConfig.icon, color: cibleConfig.color, size: 20),
          ),
          Positioned(
            top: -3, right: -3,
            child: Container(
              width: 11, height: 11,
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
            ),
          ),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.titre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(a.contenu, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF94A3B8)),
              const SizedBox(width: 5),
              Text(_formatDisplayDate(a.dateCreation), style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
              if (a.fichiers.isNotEmpty) ...[
                const SizedBox(width: 10),
                const Icon(Icons.attach_file_rounded, size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 3),
                Text('${a.fichiers.length}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
              ],
            ]),
          ]),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _buildCardTag(cibleConfig.label, cibleConfig.color),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(a.statut == StatutAnnonce.publie ? 'En ligne' : 'Brouillon', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: statusColor)),
          ),
          const SizedBox(height: 10),
          Row(children: [
            OutlinedButton(
              onPressed: () => _showDetail(a),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Voir plus', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B), size: 19),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'edit') _openForm(annonce: a);
                if (val == 'toggle') _togglePublication(a, a.statut == StatutAnnonce.publie ? StatutAnnonce.brouillon : StatutAnnonce.publie);
                if (val == 'delete') _showDeleteConfirmation(a);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16, color: Color(0xFF334155)), SizedBox(width: 8), Text('Éditer', style: TextStyle(fontSize: 13))])),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(children: [
                    Icon(a.statut == StatutAnnonce.publie ? Icons.inventory_2_outlined : Icons.rocket_launch_outlined, size: 16, color: a.statut == StatutAnnonce.publie ? const Color(0xFFF59E0B) : _emeraldColor),
                    const SizedBox(width: 8),
                    Text(a.statut == StatutAnnonce.publie ? 'Dépublier' : 'Publier', style: const TextStyle(fontSize: 13)),
                  ]),
                ),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent), SizedBox(width: 8), Text('Supprimer', style: TextStyle(fontSize: 13, color: Colors.redAccent))])),
              ],
            ),
          ]),
        ]),
      ]),
    );
  }

  void _showDetail(Annonce a) {
    final cibleConfig = AnnonceUiConfig.getConfig(a.categorie, a.cibleRole);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: cibleConfig.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)), child: Icon(cibleConfig.icon, color: cibleConfig.color, size: 18)),
                const SizedBox(width: 12),
                Expanded(child: Text(a.titre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 18)),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 6, children: [
                _buildCardTag(cibleConfig.label, cibleConfig.color),
                _buildCardTag(_getCibleText(a), const Color(0xFF475569), isFilled: false),
              ]),
              const SizedBox(height: 14),
              Text(a.contenu, style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.6)),
              if (a.fichiers.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 6, children: a.fichiers.map((f) => _buildPjBadge(f)).toList()),
              ],
              const SizedBox(height: 14),
              Text(_formatDisplayDate(a.dateCreation), style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Pagination ───────────────────────────────────────────────────────────
  Widget _pagination() {
    final total = _filteredAnnonces.length;
    if (total == 0) return const SizedBox();
    final totalPages = (total / _parPage).ceil().clamp(1, 999999);
    final start = total == 0 ? 0 : (_page - 1) * _parPage + 1;
    final end = ((_page - 1) * _parPage + _parPage).clamp(0, total);

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12, runSpacing: 10,
      children: [
        Text('Affichage de $start à $end sur $total annonces', style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            onPressed: _page > 1 ? () => setState(() => _page--) : null,
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            style: IconButton.styleFrom(backgroundColor: const Color(0xFFF8FAFC), side: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
          const SizedBox(width: 6),
          for (final p in _pagesToShow(totalPages))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: p == -1
                  ? const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('…', style: TextStyle(color: Color(0xFF94A3B8))))
                  : GestureDetector(
                      onTap: () => setState(() => _page = p),
                      child: Container(
                        width: 32, height: 32, alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: p == _page ? _navy : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: p == _page ? null : Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text('$p', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p == _page ? Colors.white : const Color(0xFF334155))),
                      ),
                    ),
            ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: _page < totalPages ? () => setState(() => _page++) : null,
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            style: IconButton.styleFrom(backgroundColor: const Color(0xFFF8FAFC), side: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
          const SizedBox(width: 12),
          _PopupDropdown<int>(
            value: _parPage,
            hint: '4 par page',
            items: const [4, 8, 12, 20],
            labelOf: (v) => '$v par page',
            onChanged: (v) => setState(() { _parPage = v; _page = 1; }),
          ),
        ]),
      ],
    );
  }

  List<int> _pagesToShow(int totalPages) {
    if (totalPages <= 7) return List.generate(totalPages, (i) => i + 1);
    final set = <int>{1, 2, totalPages - 1, totalPages, _page - 1, _page, _page + 1};
    final list = set.where((p) => p >= 1 && p <= totalPages).toList()..sort();
    final result = <int>[];
    for (var i = 0; i < list.length; i++) {
      if (i > 0 && list[i] - list[i - 1] > 1) result.add(-1);
      result.add(list[i]);
    }
    return result;
  }

  // ── Historique des inscriptions aux événements ─────────────────────────
  Widget _buildHistoriqueView() {
    if (_inscriptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AdminTheme.radiusCard), border: Border.all(color: AdminTheme.border)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: AdminTheme.iconBg, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.history_rounded, color: AdminTheme.iconFg, size: 26),
            ),
            const SizedBox(height: 16),
            const Text('Aucune inscription', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            const Text('Les inscriptions des étudiants aux événements apparaîtront ici.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
      );
    }
    return Column(children: _inscriptions.map((ins) => _buildInscriptionCard(ins)).toList());
  }

  Widget _buildInscriptionCard(Map<String, dynamic> ins) {
    final nomComplet = [ins['prenoms'], ins['nom']]
        .where((x) => x != null && x.toString().isNotEmpty)
        .join(' ');
    final date = DateTime.tryParse(ins['createdAt'] ?? '');
    final prix = double.tryParse(ins['prix']?.toString() ?? '') ?? 0;
    final details = [
      if ((ins['matricule'] ?? '').toString().isNotEmpty) 'Matricule : ${ins['matricule']}',
      if ((ins['email'] ?? '').toString().isNotEmpty) ins['email'],
      if ((ins['telephone'] ?? '').toString().isNotEmpty) ins['telephone'],
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _emeraldColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.how_to_reg_rounded, color: _emeraldColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nomComplet.isEmpty ? 'Étudiant' : nomComplet,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text('S\'est inscrit à « ${ins['evenement_titre'] ?? ''} »',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(details, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(date != null ? _formatDisplayDate(date) : '',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _emeraldColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(prix > 0 ? '${prix.toStringAsFixed(0)} FCFA' : 'Gratuit',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _emeraldColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardTag(String text, Color color, {bool isFilled = true}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isFilled ? color.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isFilled ? null : Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      );

  Widget _buildPjBadge(String fileUrl) {
    final name = fileUrl.split('/').last;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_file_rounded, size: 14, color: Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Future<void> _togglePublication(Annonce a, StatutAnnonce newStatus) async {
    final result = newStatus == StatutAnnonce.publie
        ? await ApiService.publishAnnonce(a.id)
        : await ApiService.updateAnnonce(a.id, {'statut': 'brouillon'});
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() => a.statut = newStatus);
      _showSnack(newStatus == StatutAnnonce.publie
          ? '🚀 L\'avis d\'information a été publié sur les terminaux étudiants.'
          : '💾 Document consigné dans vos brouillons.');
    } else {
      _showSnack(result['error'] as String? ?? 'Erreur lors de la mise à jour.', isError: true);
    }
  }

  void _openForm({Annonce? annonce}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AnnonceFormPage(
          annonce: annonce,
          filieres: _filieres,
          onSave: (data, finalStatus) async {
            final payload = {
              ...data,
              'statut': finalStatus == StatutAnnonce.publie ? 'publie' : 'brouillon',
            };
            Map<String, dynamic> result;
            if (annonce != null) {
              result = await ApiService.updateAnnonce(annonce.id, payload);
            } else {
              result = await ApiService.createAnnonce(payload);
            }
            return result;
          },
        ),
      ),
    );
    if (saved == true) {
      _showSnack('✅ Annonce enregistrée avec succès.');
      _loadData();
    }
  }

  void _showDeleteConfirmation(Annonce a) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Confirmer la suppression', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Êtes-vous sûr de vouloir détruire l\'annonce « ${a.titre} » ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ApiService.deleteAnnonce(a.id);
              if (!mounted) return;
              if (result['success'] == true) {
                setState(() => _annonces.removeWhere((x) => x.id == a.id));
                _showSnack('Annonce supprimée avec succès.');
              } else {
                _showSnack(result['error'] as String? ?? 'Erreur lors de la suppression.', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0),
            child: const Text('Supprimer définitivement', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getCibleText(Annonce a) {
    switch (a.portee) {
      case PorteeAnnonce.globale: return 'Tous les étudiants';
      case PorteeAnnonce.filiere: return 'Filière : ${a.filiereNom ?? a.filiereId}';
      case PorteeAnnonce.niveau:  return 'Niveau : ${a.niveau}';
    }
  }

  String _formatDisplayDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    const mois = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day.toString().padLeft(2, '0')} ${mois[dt.month - 1]} ${dt.year} - $h:$m';
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PAGE DE CRÉATION / ÉDITION — pleine page, 3 colonnes (façon maquette)
// ════════════════════════════════════════════════════════════════════════════
class _AnnonceFormPage extends StatefulWidget {
  final Annonce? annonce;
  final List<Map<String, dynamic>> filieres;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>, StatutAnnonce) onSave;
  const _AnnonceFormPage({this.annonce, required this.filieres, required this.onSave});

  @override State<_AnnonceFormPage> createState() => _AnnonceFormPageState();
}

// Options de catégorie — envoyées au backend (clé "categorie").
const List<Map<String, String>> categorieOptions = [
  {'val': 'generale', 'label': 'Générale'},
  {'val': 'etudiants', 'label': 'Étudiants'},
  {'val': 'evenement', 'label': 'Événement'},
  {'val': 'administration', 'label': 'Administration'},
];

class _AnnonceFormPageState extends State<_AnnonceFormPage> {
  final _titreController = TextEditingController();
  final _contenuController = TextEditingController();
  final _contenuFocus = FocusNode();

  // "Destinataires" — unifie, comme sur la maquette, la portée réelle
  // (toute l'établissement / filière / niveau) ET le rôle ciblé réel
  // (étudiant / professeur / bde) sous un seul choix à 4 options.
  PorteeAnnonce _portee = PorteeAnnonce.globale;
  bool _personnaliser = false;
  String _cibleRole = 'tous';
  String? _selectedFiliere, _selectedNiveau;

  String _categorie = 'generale';
  PlatformFile? _image;
  PlatformFile? _pieceJointe;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.annonce != null) {
      final a = widget.annonce!;
      _titreController.text = a.titre;
      _contenuController.text = a.contenu;
      _cibleRole = a.cibleRole;
      _portee = a.portee;
      _personnaliser = a.cibleRole != 'tous';
      _selectedFiliere = a.filiereId;
      _selectedNiveau = a.niveau;
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _contenuController.dispose();
    _contenuFocus.dispose();
    super.dispose();
  }

  // ── Insertion de formatage léger (markdown) dans la zone de texte ──────
  void _wrapSelection(String before, String after) {
    final text = _contenuController.text;
    final sel = _contenuController.selection;
    if (!sel.isValid) return;
    final start = sel.start, end = sel.end;
    final selected = text.substring(start, end);
    final newText = text.replaceRange(start, end, '$before$selected$after');
    _contenuController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + before.length + selected.length + after.length),
    );
  }

  void _insertAtLineStart(String prefix) {
    final text = _contenuController.text;
    final sel = _contenuController.selection;
    final cursor = sel.isValid ? sel.start : text.length;
    var lineStart = text.lastIndexOf('\n', (cursor - 1).clamp(0, text.length));
    lineStart = lineStart == -1 ? 0 : lineStart + 1;
    final newText = text.replaceRange(lineStart, lineStart, prefix);
    _contenuController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + prefix.length),
    );
  }

  Future<void> _pickImage() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png'], withData: true);
    if (res == null || res.files.isEmpty) return;
    if (res.files.first.size > 5 * 1024 * 1024) { _warn('Image trop lourde (max 5 Mo).'); return; }
    setState(() => _image = res.files.first);
  }

  Future<void> _pickPieceJointe() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;
    if (res.files.first.size > 10 * 1024 * 1024) { _warn('Fichier trop lourd (max 10 Mo).'); return; }
    setState(() => _pieceJointe = res.files.first);
  }

  void _warn(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdminTheme.isDesktop(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(children: [
          _topBar(),
          Container(height: 1, color: const Color(0xFFE2E8F0)),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 28 : 16),
              child: isDesktop ? _desktopGrid() : _mobileStack(),
            ),
          ),
          _footerActions(),
        ]),
      ),
    );
  }

  Widget _topBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: Row(children: [
      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
      const SizedBox(width: 8),
      Container(width: 40, height: 40, decoration: BoxDecoration(color: AdminTheme.iconBg, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.campaign_rounded, color: AdminTheme.iconFg, size: 20)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.annonce == null ? 'Publier une nouvelle annonce' : 'Modifier l\'annonce', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const Text('Rédigez et diffusez votre annonce à la bonne audience.', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
      ]),
    ]),
  );

  Widget _desktopGrid() => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(flex: 3, child: _contentCard()),
    const SizedBox(width: 18),
    Expanded(flex: 2, child: _destinatairesCard()),
    const SizedBox(width: 18),
    Expanded(flex: 2, child: _optionsCard()),
  ]);

  Widget _mobileStack() => Column(children: [
    _contentCard(), const SizedBox(height: 16),
    _destinatairesCard(), const SizedBox(height: 16),
    _optionsCard(),
  ]);

  Widget _cardShell({required String title, required IconData icon, required Widget child}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AdminTheme.radiusCard), border: Border.all(color: AdminTheme.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: AdminTheme.iconFg, size: 17),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
      ]),
      const SizedBox(height: 4),
      const Divider(color: AdminTheme.border),
      const SizedBox(height: 10),
      child,
    ]),
  );

  // ── Colonne 1 : titre + contenu ─────────────────────────────────────────
  Widget _contentCard() => _cardShell(
    title: 'Titre de l\'annonce *',
    icon: Icons.title_rounded,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _textField(controller: _titreController, hint: 'Ex: Résultats du concours d\'entrée 2024'),
      const SizedBox(height: 20),
      const Text('Contenu de l\'annonce *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
      const SizedBox(height: 8),
      _formatToolbar(),
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: TextField(
          controller: _contenuController,
          focusNode: _contenuFocus,
          maxLines: 10,
          minLines: 8,
          maxLength: 2000,
          style: const TextStyle(fontSize: 13.5, height: 1.5),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Écrivez votre annonce ici...',
            hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(14),
          ),
        ),
      ),
    ]),
  );

  Widget _formatToolbar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE2E8F0)),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
    ),
    child: Row(children: [
      _toolBtn(Icons.format_bold_rounded, 'Gras', () => _wrapSelection('**', '**')),
      _toolBtn(Icons.format_italic_rounded, 'Italique', () => _wrapSelection('_', '_')),
      _toolBtn(Icons.format_underlined_rounded, 'Souligné', () => _wrapSelection('__', '__')),
      Container(width: 1, height: 18, color: const Color(0xFFE2E8F0), margin: const EdgeInsets.symmetric(horizontal: 4)),
      _toolBtn(Icons.format_list_bulleted_rounded, 'Liste à puces', () => _insertAtLineStart('- ')),
      _toolBtn(Icons.format_list_numbered_rounded, 'Liste numérotée', () => _insertAtLineStart('1. ')),
      _toolBtn(Icons.link_rounded, 'Lien', () => _wrapSelection('[', '](url)')),
      const Spacer(),
      Text('${_contenuController.text.length}/2000', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _toolBtn(IconData icon, String tooltip, VoidCallback onTap) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 17, color: const Color(0xFF475569))),
    ),
  );

  Widget _textField({required TextEditingController controller, required String hint}) => Container(
    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
    child: TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)), border: InputBorder.none, contentPadding: const EdgeInsets.all(12)),
    ),
  );

  // ── Colonne 2 : Destinataires ───────────────────────────────────────────
  Widget _destinatairesCard() => _cardShell(
    title: 'Destinataires',
    icon: Icons.people_alt_outlined,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Choisissez à qui envoyer cette annonce.', style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
      const SizedBox(height: 10),
      _destinataireOption(
        label: 'Toute l\'établissement',
        sub: 'Tous les étudiants, professeurs et personnels',
        selected: _portee == PorteeAnnonce.globale && !_personnaliser,
        onTap: () => setState(() { _portee = PorteeAnnonce.globale; _personnaliser = false; _cibleRole = 'tous'; }),
      ),
      _destinataireOption(
        label: 'Par filière spécifique',
        sub: 'Une ou plusieurs filières',
        selected: _portee == PorteeAnnonce.filiere,
        onTap: () => setState(() { _portee = PorteeAnnonce.filiere; _personnaliser = false; _cibleRole = 'tous'; }),
      ),
      if (_portee == PorteeAnnonce.filiere) Padding(
        padding: const EdgeInsets.only(left: 30, bottom: 10),
        child: _PopupDropdown<String>(
          value: _selectedFiliere,
          hint: 'Choisir la filière',
          items: widget.filieres.map((f) => f['id'].toString()).toList(),
          labelOf: (id) => widget.filieres.firstWhere((f) => f['id'].toString() == id)['nom'] as String,
          onChanged: (v) => setState(() => _selectedFiliere = v),
          width: double.infinity,
        ),
      ),
      _destinataireOption(
        label: 'Par niveau d\'étude',
        sub: 'Un ou plusieurs niveaux',
        selected: _portee == PorteeAnnonce.niveau,
        onTap: () => setState(() { _portee = PorteeAnnonce.niveau; _personnaliser = false; _cibleRole = 'tous'; }),
      ),
      if (_portee == PorteeAnnonce.niveau) Padding(
        padding: const EdgeInsets.only(left: 30, bottom: 10),
        child: _PopupDropdown<String>(
          value: _selectedNiveau,
          hint: 'Choisir le niveau',
          items: istNiveaux,
          labelOf: (v) => v,
          onChanged: (v) => setState(() => _selectedNiveau = v),
          width: double.infinity,
        ),
      ),
      _destinataireOption(
        label: 'Personnaliser',
        sub: 'Choisir des groupes spécifiques (rôle)',
        selected: _personnaliser,
        onTap: () => setState(() { _personnaliser = true; _portee = PorteeAnnonce.globale; }),
      ),
      if (_personnaliser) Padding(
        padding: const EdgeInsets.only(left: 30),
        child: _PopupDropdown<String>(
          value: _cibleRole == 'tous' ? null : _cibleRole,
          hint: 'Choisir le rôle',
          items: cibleRoleOptions.where((e) => e['val'] != 'tous').map((e) => e['val']!).toList(),
          labelOf: (v) => cibleRoleOptions.firstWhere((e) => e['val'] == v)['label']!,
          onChanged: (v) => setState(() => _cibleRole = v),
          width: double.infinity,
        ),
      ),
    ]),
  );

  Widget _destinataireOption({required String label, required String sub, required bool selected, required VoidCallback onTap}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, size: 19, color: selected ? AdminTheme.iconFg : const Color(0xFFCBD5E1)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? const Color(0xFF0F172A) : const Color(0xFF334155))),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ])),
      ]),
    ),
  );

  // ── Colonne 3 : Options supplémentaires ─────────────────────────────────
  Widget _optionsCard() => _cardShell(
    title: 'Options supplémentaires',
    icon: Icons.tune_rounded,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Ajoutez des informations pour mieux cibler votre annonce.', style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
      const SizedBox(height: 14),
      const Text('Catégorie *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
      const SizedBox(height: 6),
      _PopupDropdown<String>(
        value: _categorie,
        hint: 'Choisir',
        items: categorieOptions.map((c) => c['val']!).toList(),
        labelOf: (v) => categorieOptions.firstWhere((c) => c['val'] == v)['label']!,
        onChanged: (v) => setState(() => _categorie = v),
        width: double.infinity,
      ),
      const SizedBox(height: 16),
      const Text('Image (facultatif)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
      const SizedBox(height: 6),
      _dropzone(
        file: _image,
        icon: Icons.image_outlined,
        label: 'Glissez une image ici ou cliquez',
        hint: 'PNG, JPG (max 5 Mo)',
        onTap: _pickImage,
        onClear: () => setState(() => _image = null),
      ),
      const SizedBox(height: 16),
      const Text('Pièce jointe (facultatif)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
      const SizedBox(height: 6),
      _dropzone(
        file: _pieceJointe,
        icon: Icons.description_outlined,
        label: 'Ajouter un fichier',
        hint: 'PDF, DOC, DOCX (max 10 Mo)',
        onTap: _pickPieceJointe,
        onClear: () => setState(() => _pieceJointe = null),
      ),
    ]),
  );

  Widget _dropzone({
    required PlatformFile? file,
    required IconData icon,
    required String label,
    required String hint,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    if (file != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Row(children: [
          Icon(icon, size: 18, color: AdminTheme.iconFg),
          const SizedBox(width: 8),
          Expanded(child: Text(file.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)), maxLines: 1, overflow: TextOverflow.ellipsis)),
          IconButton(onPressed: onClear, icon: const Icon(Icons.close_rounded, size: 16), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ]),
      );
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 22),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(hint, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  // ── Actions bas de page ─────────────────────────────────────────────────
  Widget _footerActions() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
    child: Row(children: [
      OutlinedButton(
        onPressed: _isSaving ? null : () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), side: const BorderSide(color: Color(0xFFCBD5E1))),
        child: const Text('Annuler', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
      ),
      const Spacer(),
      OutlinedButton(
        onPressed: _isSaving ? null : () => _save(StatutAnnonce.brouillon),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), side: const BorderSide(color: Color(0xFFCBD5E1))),
        child: const Text('Enregistrer en brouillon', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
      ),
      const SizedBox(width: 12),
      ElevatedButton.icon(
        onPressed: _isSaving ? null : () => _save(StatutAnnonce.publie),
        icon: _isSaving
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.send_rounded, size: 16, color: Colors.white),
        label: const Text('Publier l\'annonce', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: _navy, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
      ),
    ]),
  );

  void _save(StatutAnnonce finalStatus) {
    final title = _titreController.text.trim();
    final body = _contenuController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Veuillez remplir les champs obligatoires (Titre et Contenu).'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_portee == PorteeAnnonce.filiere && _selectedFiliere == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Veuillez sélectionner une filière.'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_portee == PorteeAnnonce.niveau && _selectedNiveau == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Veuillez sélectionner un niveau.'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'titre': title,
      'contenu': body,
      'cibleRole': _personnaliser ? _cibleRole : 'tous',
      'filiere': _portee == PorteeAnnonce.filiere ? _selectedFiliere : null,
      'niveau': _portee == PorteeAnnonce.niveau ? _selectedNiveau : null,
      'categorie': _categorie,
    };

    widget.onSave(payload, finalStatus).then((result) async {
      if (!mounted) return;
      if (result['success'] == true) {
        // L'annonce existe : on y rattache l'image et la pièce jointe
        // (POST /annonces/:id/fichier, un fichier par appel).
        final id = widget.annonce?.id ?? (result['data'] is Map ? result['data']['id']?.toString() : null);
        final erreurs = <String>[];
        if (id != null) {
          for (final f in [_image, _pieceJointe]) {
            if (f == null || f.bytes == null) continue;
            final up = await ApiService.uploadAnnonceFichier(id, f.bytes!, f.name);
            if (up['success'] != true) erreurs.add('${f.name} : ${up['error']}');
          }
        }
        if (!mounted) return;
        if (erreurs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Annonce enregistrée, mais fichier non envoyé — ${erreurs.join(' / ')}'),
            backgroundColor: const Color(0xFFD97706), behavior: SnackBarBehavior.floating,
          ));
        }
        Navigator.pop(context, true);
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] as String? ?? 'Erreur lors de l\'enregistrement.'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
        );
      }
    });
  }
}
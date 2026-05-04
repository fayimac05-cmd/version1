import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLE
// ════════════════════════════════════════════════════════════════════════════
class Reclamation {
  final String id, matricule, nomEtudiant, prenoms;
  final String filiere, module, type, texte, date;
  final String? photoUrl;
  String statut;
  String? reponse, dateTraitement, profTransfere;

  Reclamation({
    required this.id,
    required this.matricule,
    required this.nomEtudiant,
    required this.prenoms,
    required this.filiere,
    required this.module,
    required this.type,
    required this.texte,
    required this.date,
    this.photoUrl,
    this.statut = 'en_attente',
    this.reponse,
    this.dateTraitement,
    this.profTransfere,
  });

  String get initiales => '${prenoms[0]}${nomEtudiant[0]}'.toUpperCase();
  String get nomComplet => '$prenoms $nomEtudiant';
}

// ── Données mock ─────────────────────────────────────────────────────────
final List<Reclamation> adminReclamations = [
  Reclamation(
    id: 'R001', matricule: '24IST-O2/1851',
    nomEtudiant: 'KOURAOGO', prenoms: 'Ibrahim',
    filiere: 'Réseaux Informatiques et Télécom',
    module: 'Réseaux & Protocoles', type: 'note', date: '28/04/2026',
    photoUrl: 'copie_reseaux_td1.jpg',
    texte: 'Je conteste ma note de TD. J\'ai rendu le devoir à temps mais '
        'ma note est 8/20 alors que j\'attendais au moins 13/20. '
        'J\'ai joint la photo de ma copie. Merci de vérifier.',
  ),
  Reclamation(
    id: 'R002', matricule: '23IST-O2/0987',
    nomEtudiant: 'SAWADOGO', prenoms: 'Moussa',
    filiere: 'Gestion Comptable et Financière',
    module: 'Comptabilité Générale', type: 'moyenne', date: '27/04/2026',
    texte: 'Ma moyenne de 7.5 ne correspond pas aux notes reçues. '
        'TD1: 12/20, TD2: 10/20, Examen: 8/20. La moyenne devrait être supérieure.',
  ),
  Reclamation(
    id: 'R003', matricule: '24IST-O2/1234',
    nomEtudiant: 'TRAORÉ', prenoms: 'Fatimata',
    filiere: 'Réseaux Informatiques et Télécom',
    module: 'Programmation Web', type: 'note', date: '26/04/2026',
    statut: 'en_cours', profTransfere: 'Prof. OUÉDRAOGO Mamadou',
    photoUrl: 'copie_prog_web_exam.jpg',
    texte: 'Note de 14/20 reçue mais j\'estime avoir obtenu au moins 17/20 '
        'lors de l\'examen final. J\'ai joint ma copie pour vérification.',
  ),
  Reclamation(
    id: 'R004', matricule: '24IST-O2/1456',
    nomEtudiant: 'KABORÉ', prenoms: 'Djeneba',
    filiere: 'Marketing & Communication',
    module: 'Marketing Digital', type: 'note', date: '24/04/2026',
    statut: 'resolu',
    reponse: 'Après vérification, la note a été corrigée à 16/20. Erreur de saisie confirmée.',
    dateTraitement: '25/04/2026',
    texte: 'Erreur sur la note du TP noté. J\'avais 16 sur ma copie mais 12 a été saisi.',
  ),
  Reclamation(
    id: 'R005', matricule: '24IST-O2/1789',
    nomEtudiant: 'OUÉDRAOGO', prenoms: 'Hamidou',
    filiere: 'Électrotechnique',
    module: 'Machines Électriques', type: 'note', date: '23/04/2026',
    statut: 'rejete',
    reponse: 'Après examen du dossier, la note attribuée est correcte et conforme.',
    dateTraitement: '24/04/2026',
    texte: 'Je pense mériter une meilleure note sur l\'examen final.',
  ),
];

// ════════════════════════════════════════════════════════════════════════════
// PAGE
// ════════════════════════════════════════════════════════════════════════════
class AdminReclamations extends StatefulWidget {
  const AdminReclamations({super.key});

  @override
  State<AdminReclamations> createState() => _AdminReclamationsState();
}

class _AdminReclamationsState extends State<AdminReclamations>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _filtreType = 'tous';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<Reclamation> _byStatut(String statut) {
    return adminReclamations.where((r) {
      final matchStatut = r.statut == statut;
      final matchType = _filtreType == 'tous' || r.type == _filtreType;
      final matchQuery = _query.isEmpty ||
          r.nomComplet.toLowerCase().contains(_query.toLowerCase()) ||
          r.matricule.toLowerCase().contains(_query.toLowerCase()) ||
          r.module.toLowerCase().contains(_query.toLowerCase());
      return matchStatut && matchType && matchQuery;
    }).toList();
  }

  List<Reclamation> get _historique {
    return adminReclamations.where((r) {
      return (r.statut == 'resolu' || r.statut == 'rejete') &&
          (_filtreType == 'tous' || r.type == _filtreType);
    }).toList();
  }

  int get _nbAttente => adminReclamations.where((r) => r.statut == 'en_attente').length;
  int get _nbEnCours => adminReclamations.where((r) => r.statut == 'en_cours').length;
  int get _nbResolus => adminReclamations.where((r) => r.statut == 'resolu').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      body: Column(
        children: [
          _buildHeader(),
          Container(height: 1, color: AdminTheme.border),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildListe(_byStatut('en_attente')),
                _buildListe(_byStatut('en_cours')),
                _buildListe(_historique),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Réclamations',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      '${adminReclamations.length} réclamation(s)',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AdminTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _statBadge('$_nbAttente En attente', AdminTheme.warning, AdminTheme.warningLight),
              const SizedBox(width: 6),
              _statBadge('$_nbEnCours En cours', AdminTheme.info, AdminTheme.infoLight),
              const SizedBox(width: 6),
              _statBadge('$_nbResolus Résolues', AdminTheme.success, AdminTheme.successLight),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: AdminTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AdminTheme.border),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Rechercher étudiant, matricule, module...',
                hintStyle: TextStyle(fontSize: 13, color: AdminTheme.textMuted),
                prefixIcon: Icon(Icons.search_rounded, color: AdminTheme.textMuted, size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Type : ', style: TextStyle(fontSize: 13, color: AdminTheme.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              _filtreChip('Tous', _filtreType == 'tous', () => setState(() => _filtreType = 'tous')),
              const SizedBox(width: 6),
              _filtreChip('Notes', _filtreType == 'note', () => setState(() => _filtreType = 'note')),
              const SizedBox(width: 6),
              _filtreChip('Moyennes', _filtreType == 'moyenne', () => setState(() => _filtreType = 'moyenne')),
            ],
          ),
          const SizedBox(height: 10),
          TabBar(
            controller: _tabCtrl,
            labelColor: AdminTheme.primary,
            unselectedLabelColor: AdminTheme.textSecondary,
            indicatorColor: AdminTheme.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: [
              Tab(text: 'File d\'attente ($_nbAttente)'),
              Tab(text: 'En cours ($_nbEnCours)'),
              const Tab(text: 'Historique'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Liste ─────────────────────────────────────────────────────────────
  Widget _buildListe(List<Reclamation> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AdminTheme.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.inbox_rounded, color: AdminTheme.primary, size: 30),
            ),
            const SizedBox(height: 12),
            const Text('Aucune réclamation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('La file est vide.', style: TextStyle(fontSize: 13, color: AdminTheme.textSecondary)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildCarte(items[i]),
    );
  }

  // ── Carte compacte ────────────────────────────────────────────────────
  Widget _buildCarte(Reclamation r) {
    final cfg = _cfgStatut(r.statut);
    final cfgType = _cfgType(r.type);

    return GestureDetector(
      onTap: () => _ouvrirFiche(r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AdminTheme.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: const BoxDecoration(color: AdminTheme.primaryLight, shape: BoxShape.circle),
                child: Center(
                  child: Text(r.initiales, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AdminTheme.primary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(r.nomComplet, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: cfg['bg'] as Color, borderRadius: BorderRadius.circular(8)),
                          child: Text(cfg['label'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cfg['fg'] as Color)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(r.matricule, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AdminTheme.primary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: (cfgType['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(cfgType['label'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cfgType['color'] as Color)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('${r.module} · ${r.filiere}', style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(r.texte, style: const TextStyle(fontSize: 12, color: AdminTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 11, color: AdminTheme.textMuted),
                        const SizedBox(width: 3),
                        Text('Soumis le ${r.date}', style: const TextStyle(fontSize: 10, color: AdminTheme.textMuted)),
                        if (r.photoUrl != null) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.attach_file_rounded, size: 11, color: AdminTheme.info),
                          const SizedBox(width: 3),
                          const Text('Pièce jointe', style: TextStyle(fontSize: 10, color: AdminTheme.info, fontWeight: FontWeight.w600)),
                        ],
                        if (r.profTransfere != null) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.forward_rounded, size: 11, color: AdminTheme.warning),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text('→ ${r.profTransfere}', style: const TextStyle(fontSize: 10, color: AdminTheme.warning, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: AdminTheme.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // FICHE DÉTAILLÉE
  // ════════════════════════════════════════════════════════════════════════
  void _ouvrirFiche(Reclamation r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bsCtx) {
        return StatefulBuilder(
          builder: (ctx, setS) {
            return _FicheReclamation(
              reclamation: r,
              onTransferer: (prof) {
                setS(() {
                  r.statut = 'en_cours';
                  r.profTransfere = prof;
                });
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ Transféré à $prof'), backgroundColor: AdminTheme.info, behavior: SnackBarBehavior.floating),
                );
              },
              onRepondre: (reponse) {
                setS(() {
                  r.statut = 'resolu';
                  r.reponse = reponse;
                  r.dateTraitement = _dateAujourdhui();
                });
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Réclamation résolue'), backgroundColor: AdminTheme.success, behavior: SnackBarBehavior.floating),
                );
              },
              onRejeter: (motif) {
                setS(() {
                  r.statut = 'rejete';
                  r.reponse = motif;
                  r.dateTraitement = _dateAujourdhui();
                });
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Réclamation rejetée'), backgroundColor: AdminTheme.danger, behavior: SnackBarBehavior.floating),
                );
              },
            );
          },
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  Widget _statBadge(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _filtreChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AdminTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AdminTheme.primary : AdminTheme.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : AdminTheme.textSecondary)),
      ),
    );
  }

  Map<String, dynamic> _cfgStatut(String statut) {
    switch (statut) {
      case 'en_attente': return {'label': 'En attente', 'fg': AdminTheme.warning, 'bg': AdminTheme.warningLight};
      case 'en_cours':   return {'label': 'En cours',   'fg': AdminTheme.info,    'bg': AdminTheme.infoLight};
      case 'resolu':     return {'label': 'Résolue',    'fg': AdminTheme.success, 'bg': AdminTheme.successLight};
      case 'rejete':     return {'label': 'Rejetée',    'fg': AdminTheme.danger,  'bg': AdminTheme.dangerLight};
      default:           return {'label': statut,       'fg': AdminTheme.textMuted, 'bg': AdminTheme.surfaceAlt};
    }
  }

  Map<String, dynamic> _cfgType(String type) {
    switch (type) {
      case 'note':    return {'label': 'Note',    'color': AdminTheme.info};
      case 'moyenne': return {'label': 'Moyenne', 'color': AdminTheme.warning};
      default:        return {'label': type,      'color': AdminTheme.textMuted};
    }
  }

  String _dateAujourdhui() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2, '0')}/${n.month.toString().padLeft(2, '0')}/${n.year}';
  }
}

// ════════════════════════════════════════════════════════════════════════════
// WIDGET FICHE DÉTAILLÉE — séparé pour éviter les problèmes de parenthèses
// ════════════════════════════════════════════════════════════════════════════
class _FicheReclamation extends StatelessWidget {
  final Reclamation reclamation;
  final void Function(String prof) onTransferer;
  final void Function(String reponse) onRepondre;
  final void Function(String motif) onRejeter;

  const _FicheReclamation({
    required this.reclamation,
    required this.onTransferer,
    required this.onRepondre,
    required this.onRejeter,
  });

  Reclamation get r => reclamation;

  @override
  Widget build(BuildContext context) {
    final cfg = _cfgStatut(r.statut);
    final cfgType = _cfgType(r.type);
    final peutAgir = r.statut == 'en_attente' || r.statut == 'en_cours';

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AdminTheme.border, borderRadius: BorderRadius.circular(2))),
          // Titre
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Réclamation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      Text('Réf. ${r.id}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AdminTheme.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: cfg['bg'] as Color, borderRadius: BorderRadius.circular(8)),
                  child: Text(cfg['label'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cfg['fg'] as Color)),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(color: AdminTheme.surfaceAlt, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.close_rounded, size: 16, color: AdminTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AdminTheme.border),
          // Corps scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil étudiant
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(color: AdminTheme.primary.withOpacity(0.15), shape: BoxShape.circle),
                          child: Center(child: Text(r.initiales, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.primary))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.nomComplet, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                              const SizedBox(height: 2),
                              Text(r.matricule, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AdminTheme.primary)),
                              Text(r.filiere, style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Détails
                  const Text('Détails', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AdminTheme.border)),
                    child: Column(
                      children: [
                        _ligne('Module', r.module),
                        const Divider(height: 14, color: Color(0xFFE5E7EB)),
                        _ligne('Filière', r.filiere),
                        const Divider(height: 14, color: Color(0xFFE5E7EB)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(width: 130, child: Text('Type', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: (cfgType['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(cfgType['label'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cfgType['color'] as Color)),
                            ),
                          ],
                        ),
                        const Divider(height: 14, color: Color(0xFFE5E7EB)),
                        _ligne('Date de soumission', r.date),
                        if (r.dateTraitement != null) ...[
                          const Divider(height: 14, color: Color(0xFFE5E7EB)),
                          _ligne('Date de traitement', r.dateTraitement!),
                        ],
                        if (r.profTransfere != null) ...[
                          const Divider(height: 14, color: Color(0xFFE5E7EB)),
                          _ligne('Transféré à', r.profTransfere!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Motif
                  const Text('Motif de la réclamation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.format_quote_rounded, color: Color(0xFFD97706), size: 18),
                            SizedBox(width: 6),
                            Text('Déclaration de l\'étudiant', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(r.texte, style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E), height: 1.6)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Photo copie
                  if (r.photoUrl != null) ...[
                    const Text('Pièce jointe — Photo de la copie', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _voirPhoto(context, r),
                      child: Container(
                        width: double.infinity, height: 160,
                        decoration: BoxDecoration(color: AdminTheme.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: AdminTheme.border)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(color: AdminTheme.infoLight, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.image_rounded, color: AdminTheme.info, size: 26),
                            ),
                            const SizedBox(height: 8),
                            Text(r.photoUrl!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdminTheme.info)),
                            const SizedBox(height: 4),
                            const Text('Appuyer pour agrandir', style: TextStyle(fontSize: 11, color: AdminTheme.textMuted)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Réponse si déjà traitée
                  if (r.reponse != null) ...[
                    Text(
                      r.statut == 'rejete' ? 'Motif du rejet' : 'Réponse apportée',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: r.statut == 'rejete' ? AdminTheme.dangerLight : AdminTheme.successLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: r.statut == 'rejete' ? AdminTheme.danger.withOpacity(0.3) : AdminTheme.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            r.statut == 'rejete' ? Icons.cancel_outlined : Icons.check_circle_outline_rounded,
                            color: r.statut == 'rejete' ? AdminTheme.danger : AdminTheme.success,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              r.reponse!,
                              style: TextStyle(fontSize: 13, height: 1.5, color: r.statut == 'rejete' ? AdminTheme.danger : AdminTheme.success),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          // Boutons d'action
          if (peutAgir)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AdminTheme.border))),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _btnAction(context, icon: Icons.send_rounded, label: 'Transférer au prof', color: AdminTheme.info, bg: AdminTheme.infoLight, onTap: () => _dialogTransferer(context))),
                      const SizedBox(width: 10),
                      Expanded(child: _btnAction(context, icon: Icons.reply_rounded, label: 'Répondre', color: AdminTheme.success, bg: AdminTheme.successLight, onTap: () => _dialogRepondre(context))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _btnAction(context, icon: Icons.close_rounded, label: 'Rejeter la réclamation', color: AdminTheme.danger, bg: AdminTheme.dangerLight, fullWidth: true, onTap: () => _dialogRejeter(context)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Vue photo plein écran ─────────────────────────────────────────────
  void _voirPhoto(BuildContext context, Reclamation r) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Center(
                child: Container(
                  color: const Color(0xFF1A1A2E),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_rounded, color: Colors.white54, size: 80),
                      const SizedBox(height: 16),
                      Text(r.photoUrl ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      const Text('Photo de la copie (simulation)', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 16, right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Dialogs actions ───────────────────────────────────────────────────
  void _dialogTransferer(BuildContext context) {
    final profs = ['Prof. OUÉDRAOGO Mamadou', 'Prof. SAWADOGO Issa', 'Prof. KABORÉ Jean-Louis', 'Prof. TRAORÉ Aminata'];
    String? profChoisi;

    showDialog(
      context: context,
      builder: (dCtx) {
        return StatefulBuilder(
          builder: (ctx2, setS2) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Transférer au professeur'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${r.nomComplet} — ${r.module}', style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
                  const SizedBox(height: 14),
                  const Text('Choisir le professeur :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...profs.map((p) {
                    return GestureDetector(
                      onTap: () => setS2(() => profChoisi = p),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: profChoisi == p ? const Color(0xFFEFF6FF) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: profChoisi == p ? const Color(0xFF1D4ED8) : AdminTheme.border),
                        ),
                        child: Text(p, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: profChoisi == p ? const Color(0xFF1D4ED8) : const Color(0xFF374151))),
                      ),
                    );
                  }),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Annuler')),
                ElevatedButton(
                  onPressed: profChoisi == null ? null : () {
                    Navigator.pop(ctx2);
                    onTransferer(profChoisi!);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.info, foregroundColor: Colors.white),
                  child: const Text('Confirmer le transfert'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _dialogRepondre(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Répondre à la réclamation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${r.nomComplet} — ${r.module}', style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: AdminTheme.surfaceAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: AdminTheme.border)),
                child: TextField(
                  controller: ctrl, maxLines: 4,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(hintText: 'Rédigez votre réponse...', hintStyle: TextStyle(fontSize: 13, color: AdminTheme.textMuted), border: InputBorder.none, contentPadding: EdgeInsets.all(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.trim().isEmpty) return;
                Navigator.pop(dCtx);
                onRepondre(ctrl.text.trim());
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.success, foregroundColor: Colors.white),
              child: const Text('Envoyer la réponse'),
            ),
          ],
        );
      },
    );
  }

  void _dialogRejeter(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Rejeter la réclamation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${r.nomComplet} — ${r.module}', style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: AdminTheme.surfaceAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: AdminTheme.border)),
                child: TextField(
                  controller: ctrl, maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(hintText: 'Motif du rejet (optionnel)...', hintStyle: TextStyle(fontSize: 13, color: AdminTheme.textMuted), border: InputBorder.none, contentPadding: EdgeInsets.all(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dCtx);
                onRejeter(ctrl.text.trim().isNotEmpty ? ctrl.text.trim() : 'Réclamation rejetée par l\'administration.');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.danger, foregroundColor: Colors.white),
              child: const Text('Confirmer le rejet'),
            ),
          ],
        );
      },
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────
  Widget _ligne(String label, String valeur) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary))),
        Expanded(child: Text(valeur, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)))),
      ],
    );
  }

  Widget _btnAction(BuildContext context, {required IconData icon, required String label, required Color color, required Color bg, required VoidCallback onTap, bool fullWidth = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _cfgStatut(String statut) {
    switch (statut) {
      case 'en_attente': return {'label': 'En attente', 'fg': AdminTheme.warning, 'bg': AdminTheme.warningLight};
      case 'en_cours':   return {'label': 'En cours',   'fg': AdminTheme.info,    'bg': AdminTheme.infoLight};
      case 'resolu':     return {'label': 'Résolue',    'fg': AdminTheme.success, 'bg': AdminTheme.successLight};
      case 'rejete':     return {'label': 'Rejetée',    'fg': AdminTheme.danger,  'bg': AdminTheme.dangerLight};
      default:           return {'label': statut, 'fg': AdminTheme.textMuted, 'bg': AdminTheme.surfaceAlt};
    }
  }

  Map<String, dynamic> _cfgType(String type) {
    switch (type) {
      case 'note':    return {'label': 'Note',    'color': AdminTheme.info};
      case 'moyenne': return {'label': 'Moyenne', 'color': AdminTheme.warning};
      default:        return {'label': type, 'color': AdminTheme.textMuted};
    }
  }
}

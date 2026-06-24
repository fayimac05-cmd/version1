import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';

class EvenementBDE {
  final String id, titre, date, lieu, description;
  final int billetsTotal, billetsVendus;
  String statut; // en_attente, approuve, rejete, termine
  EvenementBDE({required this.id, required this.titre, required this.date,
      required this.lieu, required this.description,
      required this.billetsTotal, required this.billetsVendus,
      this.statut = 'en_attente'});
}

class PublicationBDE {
  final String id, titre, contenu, auteur, date, type;
  String statut; // en_attente, approuvee, rejetee
  PublicationBDE({required this.id, required this.titre, required this.contenu,
      required this.auteur, required this.date, required this.type,
      this.statut = 'en_attente'});
}

final List<EvenementBDE> adminEvenements = [
  EvenementBDE(id: 'E001', titre: 'Soirée étudiante BDE', date: '02 Mai 2025',
      lieu: 'Campus IST — Salle polyvalente', billetsTotal: 500, billetsVendus: 340,
      description: 'La grande soirée annuelle du BDE avec animations, musique et surprises !',
      statut: 'approuve'),
  EvenementBDE(id: 'E002', titre: 'Tournoi de foot inter-filières', date: '10 Mai 2025',
      lieu: 'Terrain de sport IST', billetsTotal: 0, billetsVendus: 0,
      description: 'Tournoi de football organisé par le BDE. Toutes les filières invitées.',
      statut: 'en_attente'),
  EvenementBDE(id: 'E003', titre: 'Journée découverte entreprises', date: '20 Mai 2025',
      lieu: 'Amphi principal IST', billetsTotal: 200, billetsVendus: 45,
      description: 'Des entreprises partenaires viennent présenter leurs opportunités de stage.',
      statut: 'approuve'),
];

final List<PublicationBDE> adminPublications = [
  PublicationBDE(id: 'PB001', titre: 'Résultats du sondage sur les activités BDE',
      contenu: 'Suite à notre sondage, voici les activités les plus demandées pour ce semestre...',
      auteur: 'BDE — Aïcha OUÉDRAOGO', date: '28/04/2025', type: 'sondage', statut: 'approuvee'),
  PublicationBDE(id: 'PB002', titre: 'Vente de billets — Soirée du 02 Mai',
      contenu: 'Les billets pour la soirée étudiante sont disponibles ! Prix : 2000 FCFA via Orange Money.',
      auteur: 'BDE — Trésorier', date: '27/04/2025', type: 'annonce', statut: 'approuvee'),
  PublicationBDE(id: 'PB003', titre: 'Appel à bénévoles pour le tournoi de foot',
      contenu: 'Nous cherchons des bénévoles pour organiser le tournoi. Contactez le BDE.',
      auteur: 'BDE — Secrétaire', date: '29/04/2025', type: 'appel', statut: 'en_attente'),
  PublicationBDE(id: 'PB004', titre: 'Nouvelles règles de la salle BDE',
      contenu: 'Veuillez prendre note des nouvelles règles d\'utilisation de la salle BDE...',
      auteur: 'BDE — Président', date: '30/04/2025', type: 'info', statut: 'en_attente'),
];

class AdminBDE extends StatefulWidget {
  const AdminBDE({super.key});
  @override State<AdminBDE> createState() => _AdminBDEState();
}

class _AdminBDEState extends State<AdminBDE> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  int get _nbEnAttentePub =>
      adminPublications.where((p) => p.statut == 'en_attente').length;
  int get _nbEnAttenteEv =>
      adminEvenements.where((e) => e.statut == 'en_attente').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('BDE & Événements', style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E))),
                const Text('Gestion du Bureau Des Étudiants',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              ])),
              if (_nbEnAttentePub + _nbEnAttenteEv > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AdminTheme.warningLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AdminTheme.warning.withOpacity(0.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.notifications_active_rounded,
                        color: AdminTheme.warning, size: 14),
                    const SizedBox(width: 5),
                    Text('${_nbEnAttentePub + _nbEnAttenteEv} en attente',
                        style: const TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w700, color: AdminTheme.warning)),
                  ])),
            ]),
            const SizedBox(height: 16),
            // Stats rapides
            Row(children: [
              _statCard('${adminEvenements.where((e) => e.statut == 'approuve').length}',
                  'Événements actifs', AdminTheme.primary, AdminTheme.primaryLight),
              const SizedBox(width: 10),
              _statCard('${adminEvenements.fold(0, (s, e) => s + e.billetsVendus)}',
                  'Billets vendus', AdminTheme.success, AdminTheme.successLight),
              const SizedBox(width: 10),
              _statCard('${adminPublications.where((p) => p.statut == 'en_attente').length}',
                  'Publications en attente', AdminTheme.warning, AdminTheme.warningLight),
            ]),
            const SizedBox(height: 16),
            TabBar(
              controller: _tab,
              labelColor: AdminTheme.primary,
              unselectedLabelColor: const Color(0xFF9CA3AF),
              indicatorColor: AdminTheme.primary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Événements'),
                  if (_nbEnAttenteEv > 0) ...[
                    const SizedBox(width: 6),
                    _badge(_nbEnAttenteEv, AdminTheme.warning),
                  ],
                ])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Publications'),
                  if (_nbEnAttentePub > 0) ...[
                    const SizedBox(width: 6),
                    _badge(_nbEnAttentePub, AdminTheme.warning),
                  ],
                ])),
              ],
            ),
          ]),
        ),
        Container(height: 1, color: const Color(0xFFE5E7EB)),
        Expanded(child: TabBarView(controller: _tab, children: [
          _tabEvenements(),
          _tabPublications(),
        ])),
      ]),
    );
  }

  Widget _badge(int n, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
    child: Text('$n', style: const TextStyle(fontSize: 10,
        color: Colors.white, fontWeight: FontWeight.bold)));

  Widget _statCard(String val, String label, Color fg, Color bg) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: fg)),
        Text(label, style: TextStyle(fontSize: 11,
            fontWeight: FontWeight.w600, color: fg.withOpacity(0.8))),
      ])));

  // ── Onglet Événements ─────────────────────────────────────────────────
  Widget _tabEvenements() => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: adminEvenements.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (_, i) => _carteEvenement(adminEvenements[i]),
  );

  Widget _carteEvenement(EvenementBDE e) {
    final pct = e.billetsTotal > 0 ? e.billetsVendus / e.billetsTotal : 0.0;
    Color sc; String sl;
    switch (e.statut) {
      case 'approuve':  sc = AdminTheme.success; sl = '✅ Approuvé'; break;
      case 'rejete':    sc = AdminTheme.danger;  sl = '❌ Rejeté'; break;
      case 'termine':   sc = AdminTheme.textMuted; sl = 'Terminé'; break;
      default:          sc = AdminTheme.warning; sl = '⏳ En attente';
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: e.statut == 'en_attente'
              ? AdminTheme.warning.withOpacity(0.4) : const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 42, height: 42,
                decoration: BoxDecoration(color: AdminTheme.warningLight,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.celebration_rounded,
                    color: AdminTheme.warning, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.titre, style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                Text('${e.date} · ${e.lieu}', style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6B7280))),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: sc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(sl, style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w700, color: sc))),
            ]),
            const SizedBox(height: 10),
            Text(e.description, style: const TextStyle(
                fontSize: 13, color: Color(0xFF4B5563), height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            if (e.billetsTotal > 0) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.confirmation_number_rounded,
                    size: 14, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text('${e.billetsVendus} / ${e.billetsTotal} billets vendus',
                    style: const TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                const Spacer(),
                Text('${(pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: pct > 0.8 ? AdminTheme.success : AdminTheme.primary)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct, minHeight: 6,
                  backgroundColor: const Color(0xFFE5E7EB),
                  color: pct > 0.8 ? AdminTheme.success : AdminTheme.primary)),
            ],
          ]),
        ),
        if (e.statut == 'en_attente') ...[
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(child: _btn('❌ Rejeter', AdminTheme.danger, AdminTheme.dangerLight,
                () { setState(() => e.statut = 'rejete');
                  _snack('Événement rejeté.'); })),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _btn('✅ Approuver l\'événement',
                  AdminTheme.success, AdminTheme.successLight,
                () { setState(() => e.statut = 'approuve');
                  _snack('✅ Événement approuvé ! BDE notifié.'); })),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── Onglet Publications ───────────────────────────────────────────────
  Widget _tabPublications() => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: adminPublications.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, i) => _cartePublication(adminPublications[i]),
  );

  Widget _cartePublication(PublicationBDE p) {
    Color sc; String sl;
    switch (p.statut) {
      case 'approuvee': sc = AdminTheme.success; sl = '✅ Publiée'; break;
      case 'rejetee':   sc = AdminTheme.danger;  sl = '❌ Rejetée'; break;
      default:          sc = AdminTheme.warning; sl = '⏳ En attente';
    }

    IconData typeIcon;
    switch (p.type) {
      case 'annonce': typeIcon = Icons.campaign_rounded; break;
      case 'sondage': typeIcon = Icons.poll_rounded; break;
      case 'appel':   typeIcon = Icons.volunteer_activism_rounded; break;
      default:        typeIcon = Icons.info_rounded;
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.statut == 'en_attente'
              ? AdminTheme.warning.withOpacity(0.4) : const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(color: AdminTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(typeIcon, color: AdminTheme.primary, size: 18)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.titre, style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                Text('${p.auteur} · ${p.date}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: sc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(sl, style: TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w700, color: sc))),
            ]),
            const SizedBox(height: 8),
            Text(p.contenu, style: const TextStyle(fontSize: 12,
                color: Color(0xFF4B5563), height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
        if (p.statut == 'en_attente') ...[
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          Padding(padding: const EdgeInsets.all(10),
            child: Row(children: [
              Expanded(child: _btn('❌ Rejeter', AdminTheme.danger, AdminTheme.dangerLight,
                () { setState(() => p.statut = 'rejetee');
                  _snack('Publication rejetée.'); })),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _btn('✅ Approuver & Publier',
                  AdminTheme.success, AdminTheme.successLight,
                () { setState(() => p.statut = 'approuvee');
                  _snack('✅ Publication approuvée et publiée !'); })),
            ])),
        ],
      ]),
    );
  }

  Widget _btn(String label, Color fg, Color bg, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8),
              border: Border.all(color: fg.withOpacity(0.3))),
          child: Center(child: Text(label, style: TextStyle(fontSize: 12,
              fontWeight: FontWeight.w700, color: fg)))));

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: AdminTheme.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
}

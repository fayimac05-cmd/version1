import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import '../admin/admin_theme.dart';

// Déclaration globale de la couleur émeraude
const Color emeraldColor = Color(0xFF10B981);

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES DE DONNÉES
// ════════════════════════════════════════════════════════════════════════════
class EvenementBDE {
  final String id, titre, date, lieu, description;
  final int billetsTotal, billetsVendus;
  String statut; 

  EvenementBDE({
    required this.id, required this.titre, required this.date,
    required this.lieu, required this.description,
    required this.billetsTotal, required this.billetsVendus,
    this.statut = 'en_attente',
  });
}

class PublicationBDE {
  final String id, titre, contenu, auteur, date, type;
  String statut;

  PublicationBDE({
    required this.id, required this.titre, required this.contenu,
    required this.auteur, required this.date, required this.type,
    this.statut = 'en_attente',
  });
}

// ════════════════════════════════════════════════════════════════════════════
// DONNÉES SIMULÉES
// ════════════════════════════════════════════════════════════════════════════
final List<EvenementBDE> adminEvenements = [
  EvenementBDE(id: 'E001', titre: 'Soirée étudiante BDE', date: '02 Mai 2025', lieu: 'Campus IST', billetsTotal: 500, billetsVendus: 340, description: 'La grande soirée annuelle.', statut: 'approuve'),
  EvenementBDE(id: 'E002', titre: 'Tournoi de foot', date: '10 Mai 2025', lieu: 'Terrain IST', billetsTotal: 0, billetsVendus: 0, description: 'Tournoi inter-filières.', statut: 'en_attente'),
];

final List<PublicationBDE> adminPublications = [
  PublicationBDE(id: 'PB001', titre: 'Résultats sondage', contenu: 'Voici les activités...', auteur: 'Aïcha O.', date: '28/04/2025', type: 'sondage', statut: 'approuvee'),
  PublicationBDE(id: 'PB003', titre: 'Appel à bénévoles', contenu: 'Nous cherchons des gens...', auteur: 'Secrétaire', date: '29/04/2025', type: 'appel', statut: 'en_attente'),
];

// ════════════════════════════════════════════════════════════════════════════
// WIDGET PRINCIPAL
// ════════════════════════════════════════════════════════════════════════════
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
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AdminTheme.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header (simplifié pour la compilation)
          TabBar(
            controller: _tab,
            tabs: const [Tab(text: 'Événements'), Tab(text: 'Publications')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _tabEvenements(isMobile),
                _tabPublications(isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Onglet Événements ─────────────────────────────────────────────────
  Widget _tabEvenements(bool isMobile) => ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: adminEvenements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, i) => _carteEvenement(adminEvenements[i], isMobile),
      );

  Widget _carteEvenement(EvenementBDE e, bool isMobile) {
    final pct = e.billetsTotal > 0 ? e.billetsVendus / e.billetsTotal : 0.0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        // CORRECTION LIGNE 303 : Parenthèse et ternaire fermés correctement
        border: Border.all(
          color: e.statut == 'en_attente' ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
           Text(e.titre),
           LinearProgressIndicator(value: pct, color: pct > 0.8 ? emeraldColor : AppPalette.blue),
        ],
      ),
    );
  }

  // ── Onglet Publications ───────────────────────────────────────────────
  // Méthode ajoutée pour corriger l'erreur de "method not defined"
  Widget _tabPublications(bool isMobile) => ListView.builder(
        itemCount: adminPublications.length,
        itemBuilder: (_, i) => ListTile(title: Text(adminPublications[i].titre)),
      );
}

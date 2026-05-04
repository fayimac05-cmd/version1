import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import '../widgets/banner_widget.dart';
import '../widgets/fil_actualite_widget.dart';
import '../pages/canal_screen.dart';
import 'groupe_filiere_screen.dart';
import 'tickets_screen.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLE NOTIFICATION PUSH
// ════════════════════════════════════════════════════════════════════════════

enum NotifType { examen, note, cours, inscription, message }

class AppNotification {
  final String id;
  final NotifType type;
  final String titre;
  final String corps;
  final String temps;
  bool lu;

  AppNotification({
    required this.id,
    required this.type,
    required this.titre,
    required this.corps,
    required this.temps,
    this.lu = false,
  });
}

// ════════════════════════════════════════════════════════════════════════════
// HOME TAB
// ════════════════════════════════════════════════════════════════════════════

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.profile});
  final StudentProfile profile;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {

  // ── Notifications push mock ───────────────────────────────────────────
  final List<AppNotification> _notifs = [
    AppNotification(
      id: '1', type: NotifType.examen,
      titre: 'Examen de mi-parcours',
      corps: 'Algorithmes & Structures de données — dans 48h',
      temps: 'Il y a 12 min',
    ),
    AppNotification(
      id: '2', type: NotifType.note,
      titre: 'Note publiée',
      corps: 'Analyse numérique : 16.5/20',
      temps: 'Il y a 2h',
    ),
    AppNotification(
      id: '3', type: NotifType.cours,
      titre: 'Nouveau cours disponible',
      corps: 'Pr. Koanda a posté — Réseaux informatiques',
      temps: 'Il y a 5h',
    ),
  ];

  List<AppNotification> get _notifsNonLues =>
      _notifs.where((n) => !n.lu).toList();

  void _marquerLu(String id) {
    setState(() {
      _notifs.firstWhere((n) => n.id == id).lu = true;
    });
  }

  void _marquerToutLu() {
    setState(() {
      for (final n in _notifs) n.lu = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 32),
      child: Center(
        child: ConstrainedBox(
          // ✅ Limite la largeur max sur tous les écrans
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Bonjour ────────────────────────────────────────────
              Text('Bienvenue ${widget.profile.prenoms}',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                      color: Color(0xFF121212), letterSpacing: -0.4)),
              const SizedBox(height: 4),
              const Text('Institut Supérieur de Technologies — Espace étudiant',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),

              const SizedBox(height: 20),

              // ── Notifications push ─────────────────────────────────
              if (_notifsNonLues.isNotEmpty)
                _NotifsPushSection(
                  notifs: _notifsNonLues,
                  onLu: _marquerLu,
                  onToutLu: _marquerToutLu,
                ),

              if (_notifsNonLues.isNotEmpty) const SizedBox(height: 20),

              // ── Bandeau événements ─────────────────────────────────
              const Text('Événements cette semaine',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: Color(0xFF121212), letterSpacing: -0.2)),
              const SizedBox(height: 12),
              const BannerWidget(),

              const SizedBox(height: 28),

              // ── Accès rapide ───────────────────────────────────────
              const Text('Accès rapide',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: Color(0xFF121212), letterSpacing: -0.2)),
              const SizedBox(height: 12),

              // Ligne 1 — Groupe filière + Tickets
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => GroupeFiliere(profile: widget.profile))),
                  child: _carteAcces(
                    icon: Icons.groups_rounded,
                    couleur: AppPalette.blue,
                    titre: 'Groupe\nFilière',
                    sousTitre: '🔒 100% Privé',
                  ))),
                const SizedBox(width: 14),
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => TicketsScreen(profile: widget.profile))),
                  child: _carteAcces(
                    icon: Icons.confirmation_number_outlined,
                    couleur: const Color(0xFFFF6B00),
                    titre: 'Tickets\nÉvénements',
                    sousTitre: '🟠 Orange Money',
                  ))),
              ]),

              const SizedBox(height: 14),

              // Ligne 2 — Canaux (pleine largeur)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CanalScreen(profile: widget.profile))),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                        blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(children: [
                    Container(width: 44, height: 44,
                      decoration: BoxDecoration(
                          color: AppPalette.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.forum_rounded,
                          color: AppPalette.blue, size: 24)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Canaux & Messages',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Row(children: [
                        _miniTag('🏛️ Admin', AppPalette.blue),
                        const SizedBox(width: 6),
                        _miniTag('🎉 BDE', const Color(0xFF7C3AED)),
                        const SizedBox(width: 6),
                        _miniTag('🔒 Privé', const Color(0xFF059669)),
                      ]),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppPalette.blue,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text('5', style: TextStyle(fontSize: 11,
                          color: Colors.white, fontWeight: FontWeight.bold))),
                  ]),
                )),

              const SizedBox(height: 28),

              // ── Fil d'actualité ────────────────────────────────────
              const Text('Fil d\'actualité',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: Color(0xFF121212), letterSpacing: -0.2)),
              const SizedBox(height: 12),
              FilActualiteWidget(profile: widget.profile),

              const SizedBox(height: 28),

              // ── Résumé rapide ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppPalette.blue, Color(0xFF0E6CD3)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Résumé rapide',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppPalette.white, fontSize: 17)),
                  const SizedBox(height: 10),
                  const Text(
                    'Consultez vos programmes, vos notes et vos ressources depuis un seul espace.',
                    style: TextStyle(color: AppPalette.white, fontSize: 14, height: 1.5),
                  ),
                ]),
              ),
              const SizedBox(height: 28),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _carteAcces({
    required IconData icon, required Color couleur,
    required String titre, required String sousTitre,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 44, height: 44,
        decoration: BoxDecoration(color: couleur.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: couleur, size: 24)),
      const SizedBox(height: 12),
      Text(titre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A), height: 1.2)),
      const SizedBox(height: 6),
      Text(sousTitre, style: const TextStyle(fontSize: 11,
          color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
    ]));

  Widget _miniTag(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(fontSize: 10,
        fontWeight: FontWeight.w600, color: color)));
}

// ════════════════════════════════════════════════════════════════════════════
// SECTION NOTIFICATIONS PUSH
// ════════════════════════════════════════════════════════════════════════════

class _NotifsPushSection extends StatelessWidget {
  const _NotifsPushSection({
    required this.notifs,
    required this.onLu,
    required this.onToutLu,
  });

  final List<AppNotification> notifs;
  final void Function(String) onLu;
  final VoidCallback onToutLu;

  (Color bg, Color ic, IconData icone) _style(NotifType type) {
    switch (type) {
      case NotifType.examen:
        return (const Color(0xFFFCEBEB), const Color(0xFFA32D2D), Icons.alarm_outlined);
      case NotifType.note:
        return (const Color(0xFFFAEEDA), const Color(0xFF854F0B), Icons.star_outline_rounded);
      case NotifType.cours:
        return (const Color(0xFFE6F1FB), const Color(0xFF185FA5), Icons.menu_book_outlined);
      case NotifType.inscription:
        return (const Color(0xFFEAF3DE), const Color(0xFF3B6D11), Icons.check_circle_outline);
      case NotifType.message:
        return (const Color(0xFFEEEDFE), const Color(0xFF534AB7), Icons.chat_bubble_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        // En-tête
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
          child: Row(children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                  color: Color(0xFFE24B4A), shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Notifications',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${notifs.length} nouvelle${notifs.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 11,
                      color: Color(0xFFB91C1C), fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onToutLu,
              child: const Text('Tout lire',
                  style: TextStyle(fontSize: 12, color: Color(0xFF0A4DA2),
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),

        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Liste des notifs
        ...notifs.asMap().entries.map((entry) {
          final i = entry.key;
          final n = entry.value;
          final (bg, ic, icone) = _style(n.type);
          return Column(children: [
            InkWell(
              onTap: () => onLu(n.id),
              borderRadius: i == notifs.length - 1
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16))
                  : BorderRadius.zero,
              child: Container(
                color: const Color(0xFFF8FAFF),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Point bleu non-lu
                  Padding(
                    padding: const EdgeInsets.only(top: 14, right: 6),
                    child: Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                          color: Color(0xFF0A4DA2), shape: BoxShape.circle),
                    ),
                  ),
                  // Icône
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: bg, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icone, color: ic, size: 18)),
                  const SizedBox(width: 10),
                  // Texte
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n.titre, style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(n.corps, style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(n.temps, style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8))),
                  ])),
                  // Bouton fermer
                  GestureDetector(
                    onTap: () => onLu(n.id),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8, top: 2),
                      child: Icon(Icons.close_rounded,
                          size: 16, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ]),
              ),
            ),
            if (i < notifs.length - 1)
              const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 60),
          ]);
        }),
      ]),
    );
  }
}

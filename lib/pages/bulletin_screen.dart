import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_bubble_bg.dart';

// ── Modèles ──────────────────────────────────────────────────────────────────

class _MatiereResultat {
  final String nom;
  final double moyenne;
  final int nbDevoirs;
  const _MatiereResultat({required this.nom, required this.moyenne, required this.nbDevoirs});
}

class _BulletinData {
  final String semestre;
  final String anneeAcademique;
  final double? moyenneGenerale;
  final String statut; // 'valide' | 'ajourne' | 'invalide'
  final String? datePublication;
  final List<_MatiereResultat> matieres;

  const _BulletinData({
    required this.semestre,
    required this.anneeAcademique,
    required this.moyenneGenerale,
    required this.statut,
    required this.datePublication,
    required this.matieres,
  });

  String get statutLabel {
    switch (statut) {
      case 'valide': return 'Validé';
      case 'ajourne': return 'Ajourné';
      case 'invalide': return 'Invalidé';
      default: return statut;
    }
  }

  Color get statutColor {
    switch (statut) {
      case 'valide': return const Color(0xFF10B981);
      case 'ajourne': return const Color(0xFFD97706);
      case 'invalide': return const Color(0xFFC62828);
      default: return const Color(0xFF64748B);
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
class BulletinScreen extends StatefulWidget {
  const BulletinScreen({super.key});
  @override State<BulletinScreen> createState() => _BulletinScreenState();
}

class _BulletinScreenState extends State<BulletinScreen> {
  bool _loading = true;
  bool _erreur = false;
  String _nom = '';
  String _prenoms = '';
  String _filiere = '';
  String _niveau = '';
  List<_BulletinData> _bulletins = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  /// Charge les bulletins PUBLIÉS de l'étudiant connecté, entièrement via
  /// le backend (ApiService) — aucun accès direct à Supabase depuis
  /// Flutter. La table `etudiants` a Row Level Security activé sans
  /// politique définie ; une requête directe avec la clé publique du
  /// frontend est donc bloquée en silence (0 ligne, sans erreur visible).
  /// Le backend, lui, utilise la clé de service et applique la sécurité
  /// via le token JWT (req.user.id) — chaque étudiant ne peut recevoir
  /// que ses propres données.
  Future<void> _charger() async {
    try {
      final bulletinsResult = await ApiService.getMonBulletin();
      if (bulletinsResult['success'] != true) {
        throw Exception(bulletinsResult['error'] ?? 'Erreur bulletin');
      }

      final etudiantInfo = bulletinsResult['etudiant'] as Map<String, dynamic>?;
      final bulletinsBruts = List<Map<String, dynamic>>.from(bulletinsResult['data'] as List);

      final bulletins = <_BulletinData>[];
      for (final b in bulletinsBruts) {
        final semestre = b['semestre'] as String? ?? '';
        final annee = b['annee_academique'] as String? ?? '';

        // Détail des notes par module pour ce semestre — uniquement les
        // sessions déjà validées par l'administration (même règle que
        // "Mes Notes"), scopé côté backend par le JWT.
        final notesResult = await ApiService.getMesNotes(
          semestre: semestre,
          anneeAcademique: annee,
        );

        final Map<String, List<double>> parModule = {};
        if (notesResult['success'] == true) {
          final notesList = List<Map<String, dynamic>>.from(notesResult['data'] as List);
          for (final n in notesList) {
            final mod = n['module_nom'] as String? ?? 'Module';
            final valeur = (n['note'] as num?)?.toDouble();
            if (valeur != null) parModule.putIfAbsent(mod, () => []).add(valeur);
          }
        }
        final matieres = parModule.entries.map((e) {
          final moy = e.value.reduce((a, c) => a + c) / e.value.length;
          return _MatiereResultat(nom: e.key, moyenne: moy, nbDevoirs: e.value.length);
        }).toList();

        bulletins.add(_BulletinData(
          semestre: semestre,
          anneeAcademique: annee,
          moyenneGenerale: b['moyenne_generale'] != null ? double.tryParse(b['moyenne_generale'].toString()) : null,
          statut: b['statut'] as String? ?? '',
          datePublication: (b['date_publication'] as String?)?.split('T').first,
          matieres: matieres,
        ));
      }

      // Le plus récent en premier.
      bulletins.sort((a, b) => '${b.anneeAcademique}${b.semestre}'.compareTo('${a.anneeAcademique}${a.semestre}'));

      if (!mounted) return;
      setState(() {
        _nom = etudiantInfo?['nom'] as String? ?? '';
        _prenoms = etudiantInfo?['prenoms'] as String? ?? '';
        _filiere = etudiantInfo?['filiere_nom'] as String? ?? '';
        _niveau = etudiantInfo?['niveau'] as String? ?? '';
        _bulletins = bulletins;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _erreur = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF1E40AF);
    const Color bgSlate = Color(0xFFF8FAFC);
    const Color textMain = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgSlate,
      appBar: blueAppBar('Relevés de Notes', context: context),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erreur
              ? _etatErreur()
              : _bulletins.isEmpty
                  ? _etatVide()
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: PageView.builder(
                        itemCount: _bulletins.length,
                        itemBuilder: (context, index) {
                          final b = _bulletins[index];
                          return _carteBulletin(b, brandBlue, textMain);
                        },
                      ),
                    ),
    );
  }

  Widget _etatVide() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72,
          decoration: BoxDecoration(color: const Color(0xFF1E40AF).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.description_outlined, color: Color(0xFF1E40AF), size: 34)),
        const SizedBox(height: 18),
        const Text('Aucun bulletin publié pour l\'instant',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        const Text(
          'Ton bulletin apparaîtra ici dès que l\'administration aura publié la moyenne générale et le résultat du semestre.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
        ),
      ]),
    ),
  );

  Widget _etatErreur() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 32),
        const SizedBox(height: 12),
        const Text('Impossible de charger ton bulletin pour le moment.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () { setState(() { _loading = true; _erreur = false; }); _charger(); },
          child: const Text('Réessayer'),
        ),
      ]),
    ),
  );

  Widget _carteBulletin(_BulletinData b, Color brandBlue, Color textMain) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. EN-TÊTE
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: brandBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.school_rounded, color: brandBlue, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_prenoms $_nom',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textMain, letterSpacing: -0.3)),
                      const SizedBox(height: 3),
                      Text('Filière : $_filiere${_niveau.isNotEmpty ? ' · $_niveau' : ''}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      Text('Année Académique : ${b.anneeAcademique}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
            ),

            // 2. TITRE DU SEMESTRE
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: brandBlue, borderRadius: BorderRadius.circular(30)),
                child: Text(b.semestre.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 20),

            // 3. TABLEAU DES MATIÈRES (notes de modules déjà validées)
            if (b.matieres.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Aucune note de module publiée pour ce semestre.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
              )
            else ...[
              const Row(
                children: [
                  Expanded(flex: 5, child: Text('INTITULÉ DE LA MATIÈRE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)))),
                  Expanded(flex: 2, child: Text('DEVOIRS', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)))),
                  Expanded(flex: 2, child: Text('NOTE/20', textAlign: TextAlign.end, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)))),
                ],
              ),
              const SizedBox(height: 8),
              ...b.matieres.map((mat) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                    child: Row(
                      children: [
                        Expanded(flex: 5, child: Text(mat.nom, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textMain))),
                        Expanded(flex: 2, child: Text('${mat.nbDevoirs}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                        Expanded(
                          flex: 2,
                          child: Text(
                            mat.moyenne.toStringAsFixed(1),
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: mat.moyenne >= 10 ? const Color(0xFF10B981) : Colors.red),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],

            const SizedBox(height: 24),

            // 4. RÉCAPITULATIF
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('MOYENNE', b.moyenneGenerale != null ? '${b.moyenneGenerale!.toStringAsFixed(2)}/20' : '—', brandBlue),
                  _buildStat('RÉSULTAT', b.statutLabel, b.statutColor),
                  if (b.datePublication != null) _buildStat('PUBLIÉ LE', b.datePublication!, const Color(0xFF64748B)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 5. CACHET
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Le Directeur Académique', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    SizedBox(height: 4),
                    Text('Fait à Ouagadougou', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: brandBlue.withValues(alpha: 0.4), width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: brandBlue.withValues(alpha: 0.02),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.verified_user_rounded, color: brandBlue.withValues(alpha: 0.6), size: 24),
                      const SizedBox(height: 2),
                      Text('CERTIFIÉ IST', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: brandBlue.withValues(alpha: 0.7), letterSpacing: 0.5)),
                      Text('SECURE RECORD', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w500, color: brandBlue.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

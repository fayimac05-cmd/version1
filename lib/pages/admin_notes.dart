import 'package:flutter/material.dart';
import '../pages/admin_data.dart';
import '../theme/app_palette.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLES
// ════════════════════════════════════════════════════════════════════════════
class NoteEtudiant {
  final String matricule;
  final String nom;
  final String prenoms;
  double? note1, note2, note3, note4;
  bool publiee;

  NoteEtudiant({
    required this.matricule,
    required this.nom,
    required this.prenoms,
    this.note1, this.note2, this.note3, this.note4,
    this.publiee = false,
  });

  double? get moyenne {
    final n = [note1, note2, note3, note4].whereType<double>().toList();
    if (n.isEmpty) return null;
    return n.reduce((a, b) => a + b) / n.length;
  }

  String get statut {
    final m = moyenne;
    if (m == null) return 'en_attente';
    if (m >= 10) return 'valide';
    if (m >= 5) return 'danger';
    return 'blamable';
  }
}

class FeuillNotes {
  final String id, filiereId, filiere, moduleNom, moduleCode, profNom, dateSoumission;
  final List<NoteEtudiant> etudiants;
  String statut; // brouillon / soumis / valide / publie

  FeuillNotes({
    required this.id, required this.filiereId, required this.filiere,
    required this.moduleNom, required this.moduleCode, required this.profNom,
    required this.etudiants, this.statut = 'brouillon', required this.dateSoumission,
  });
}

List<FeuillNotes> adminFeuillesNotes = [
  FeuillNotes(
    id: 'FN001', filiereId: 'RIT-L2',
    filiere: 'Réseaux Informatiques et Télécom',
    moduleNom: 'Réseaux & Protocoles', moduleCode: 'RES301',
    profNom: 'OUÉDRAOGO Mamadou', statut: 'soumis', dateSoumission: '29/04/2025',
    etudiants: [
      NoteEtudiant(matricule: '24IST-O2/1851', nom: 'KOURAOGO', prenoms: 'Ibrahim',
          note1: 4.5, note2: 12.0, note3: 8.0, note4: 6.0),
      NoteEtudiant(matricule: '24IST-O2/1234', nom: 'TRAORÉ', prenoms: 'Fatimata',
          note1: 14.0, note2: 15.0, note3: 13.0, note4: 16.0),
      NoteEtudiant(matricule: '24IST-O2/1002', nom: 'SAWADOGO', prenoms: 'Aminata',
          note1: 11.0, note2: 9.5, note3: 10.0, note4: 12.0),
    ],
  ),
  FeuillNotes(
    id: 'FN002', filiereId: 'RIT-L2',
    filiere: 'Réseaux Informatiques et Télécom',
    moduleNom: 'Programmation Orientée Objet', moduleCode: 'POO302',
    profNom: 'SAWADOGO Issa', statut: 'brouillon', dateSoumission: '28/04/2025',
    etudiants: [
      NoteEtudiant(matricule: '24IST-O2/1851', nom: 'KOURAOGO', prenoms: 'Ibrahim', note1: 13.0),
      NoteEtudiant(matricule: '24IST-O2/1234', nom: 'TRAORÉ', prenoms: 'Fatimata', note1: 8.2),
      NoteEtudiant(matricule: '24IST-O2/1002', nom: 'SAWADOGO', prenoms: 'Aminata', note1: 15.0),
    ],
  ),
  FeuillNotes(
    id: 'FN003', filiereId: 'MKT-L2', filiere: 'Marketing',
    moduleNom: 'Marketing Stratégique', moduleCode: 'MKS301',
    profNom: 'SOME Clarisse', statut: 'publie', dateSoumission: '25/04/2025',
    etudiants: [
      NoteEtudiant(matricule: '24IST-O2/3010', nom: 'KABORÉ', prenoms: 'Djeneba',
          note1: 11.0, note2: 14.0, note3: 12.0, note4: 13.0, publiee: true),
    ],
  ),
];

// ════════════════════════════════════════════════════════════════════════════
// PAGE ADMIN NOTES
// ════════════════════════════════════════════════════════════════════════════
class AdminNotes extends StatefulWidget {
  const AdminNotes({super.key});
  @override State<AdminNotes> createState() => _AdminNotesState();
}

class _AdminNotesState extends State<AdminNotes> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _filtreStatut = 'tous';

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  List<FeuillNotes> get _filtrees => adminFeuillesNotes
      .where((f) => _filtreStatut == 'tous' || f.statut == _filtreStatut).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text('Notes & Moyennes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppPalette.blue, unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppPalette.blue,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [Tab(text: 'Feuilles reçues'), Tab(text: 'Par filière')],
        ),
      ),
      body: TabBarView(controller: _tabCtrl, children: [_tabFeuilles(), _tabParFiliere()]),
    );
  }

  Widget _tabFeuilles() {
    final liste = _filtrees;
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final entry in {
              'tous': 'Toutes', 'soumis': '🔵 Soumises',
              'brouillon': '⚪ Brouillons', 'publie': '✅ Publiées'
            }.entries) ...[
              GestureDetector(
                onTap: () => setState(() => _filtreStatut = entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _filtreStatut == entry.key ? AppPalette.blue : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(entry.value, style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _filtreStatut == entry.key ? Colors.white : const Color(0xFF64748B))),
                ),
              ),
            ],
          ]),
        ),
      ),
      Container(height: 1, color: const Color(0xFFE2E8F0)),
      Expanded(
        child: liste.isEmpty
            ? const Center(child: Text('Aucune feuille', style: TextStyle(color: Color(0xFF94A3B8))))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: liste.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _carteFeuille(liste[i]),
              ),
      ),
    ]);
  }

  Widget _carteFeuille(FeuillNotes f) {
    Color sc; String sl; Color sbg;
    switch (f.statut) {
      case 'soumis':   sc = AppPalette.blue;          sl = 'Soumise';  sbg = const Color(0xFFEFF6FF); break;
      case 'brouillon':sc = const Color(0xFF64748B);  sl = 'Brouillon';sbg = const Color(0xFFF1F5F9); break;
      case 'publie':   sc = const Color(0xFF0891B2);  sl = 'Publiée'; sbg = const Color(0xFFECFEFF); break;
      default:         sc = const Color(0xFF15803D);  sl = 'Validée'; sbg = const Color(0xFFF0FDF4);
    }
    final nbSaisis = f.etudiants.where((e) => e.moyenne != null).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: f.statut == 'soumis' ? AppPalette.blue.withOpacity(0.3) : const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppPalette.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(f.moduleCode.substring(0, 2),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppPalette.blue))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.moduleNom, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Text(f.profNom, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            Text(f.filiere, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: sbg, borderRadius: BorderRadius.circular(10)),
                child: Text(sl, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sc))),
            const SizedBox(height: 4),
            Text(f.dateSoumission, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          ]),
        ])),
        Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(children: [
            const Icon(Icons.people_outline, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text('${f.etudiants.length} étudiants · $nbSaisis notes saisies',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const Spacer(),
            Text(
              f.etudiants.length - nbSaisis > 0
                  ? '${f.etudiants.length - nbSaisis} manquante(s)' : 'Complet ✓',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                  color: f.etudiants.length - nbSaisis > 0 ? const Color(0xFFD97706) : const Color(0xFF15803D)),
            ),
          ]),
        ),
        Container(height: 1, color: const Color(0xFFF1F5F9)),
        Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => _PageDetailNotes(feuille: f, onSave: () => setState(() {})))),
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text('Voir / Modifier', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppPalette.blue, side: const BorderSide(color: AppPalette.blue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          )),
          if (f.statut == 'soumis') ...[
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(
              onPressed: () => _confirmerPublication(f),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Publier', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0, padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            )),
          ],
        ])),
      ]),
    );
  }

  Widget _tabParFiliere() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: adminFilieres.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final f = adminFilieres[i];
        final etudiants = adminEtudiants.where((e) => e.filiereId == f.id).toList();
        return Container(
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(children: [
            Padding(padding: const EdgeInsets.all(14), child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: f.domaine.contains('Technologies') ? const Color(0xFFEFF6FF) : const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  f.domaine.contains('Technologies') ? Icons.computer_rounded : Icons.business_center_rounded,
                  color: f.domaine.contains('Technologies') ? AppPalette.blue : const Color(0xFF7C3AED), size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.nom, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text('${f.niveau} · ${etudiants.length} étudiants',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ])),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => _PageListeFiliere(filiere: f, etudiants: etudiants))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Liste', style: TextStyle(fontSize: 12)),
              ),
            ])),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(children: f.modules.map((m) {
                final feuille = adminFeuillesNotes
                    .where((fn) => fn.filiereId == f.id && fn.moduleCode == m.code)
                    .firstOrNull;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Row(children: [
                    Expanded(child: Text(m.nom,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    feuille != null ? _badgeStatut(feuille.statut)
                        : const Text('Aucune note', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ]),
                );
              }).toList()),
            ),
          ]),
        );
      },
    );
  }

  Widget _badgeStatut(String s) {
    Color c; String l;
    switch (s) {
      case 'publie':   c = const Color(0xFF0891B2); l = '✅ Publiée'; break;
      case 'soumis':   c = AppPalette.blue;         l = '🔵 Soumise'; break;
      case 'valide':   c = const Color(0xFF15803D); l = '🟢 Validée'; break;
      default:         c = const Color(0xFF64748B); l = '⚪ Brouillon';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(l, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c)),
    );
  }

  void _confirmerPublication(FeuillNotes f) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.send_rounded, color: Color(0xFF15803D)),
          SizedBox(width: 10),
          Text('Publier les notes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          'Publier les notes de "${f.moduleNom}" aux ${f.etudiants.length} étudiants ?\n\nIls recevront une notification.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () {
              setState(() { f.statut = 'publie'; for (final e in f.etudiants) { e.publiee = true; } });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Notes "${f.moduleNom}" publiées ✅'),
                backgroundColor: const Color(0xFF15803D),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: const Text('Publier'),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PAGE DÉTAIL FEUILLE
// ════════════════════════════════════════════════════════════════════════════
class _PageDetailNotes extends StatefulWidget {
  final FeuillNotes feuille;
  final VoidCallback onSave;
  const _PageDetailNotes({required this.feuille, required this.onSave});
  @override State<_PageDetailNotes> createState() => _PageDetailNotesState();
}

class _PageDetailNotesState extends State<_PageDetailNotes> {
  final Map<String, List<TextEditingController>> _ctrls = {};

  @override
  void initState() {
    super.initState();
    for (final e in widget.feuille.etudiants) {
      _ctrls[e.matricule] = [
        TextEditingController(text: e.note1?.toString() ?? ''),
        TextEditingController(text: e.note2?.toString() ?? ''),
        TextEditingController(text: e.note3?.toString() ?? ''),
        TextEditingController(text: e.note4?.toString() ?? ''),
      ];
    }
  }

  @override
  void dispose() {
    for (final l in _ctrls.values) { for (final c in l) { c.dispose(); } }
    super.dispose();
  }

  void _sauvegarder() {
    for (final e in widget.feuille.etudiants) {
      final c = _ctrls[e.matricule]!;
      e.note1 = double.tryParse(c[0].text);
      e.note2 = double.tryParse(c[1].text);
      e.note3 = double.tryParse(c[2].text);
      e.note4 = double.tryParse(c[3].text);
    }
    setState(() {});
    widget.onSave();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Notes sauvegardées.'),
      backgroundColor: Color(0xFF15803D),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.feuille;
    final readOnly = f.statut == 'publie';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppPalette.blue, foregroundColor: Colors.white, elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f.moduleNom, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(f.filiere, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        actions: [
          if (!readOnly)
            TextButton(onPressed: _sauvegarder,
                child: const Text('Sauvegarder',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
      body: Column(children: [
        Container(
          color: AppPalette.blue.withOpacity(0.06), padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Icon(Icons.person_pin_rounded, color: AppPalette.blue, size: 18),
            const SizedBox(width: 8),
            Text('Prof : ${f.profNom}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppPalette.blue)),
            const Spacer(),
            Text('${f.etudiants.length} étudiants',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ]),
        ),
        Container(
          color: AppPalette.blue, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: const Row(children: [
            Expanded(flex: 3, child: Text('Étudiant',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70))),
            Expanded(child: Text('N1', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70))),
            Expanded(child: Text('N2', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70))),
            Expanded(child: Text('N3', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70))),
            Expanded(child: Text('N4', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70))),
            Expanded(child: Text('Moy.', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70))),
          ]),
        ),
        Expanded(child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: f.etudiants.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final e = f.etudiants[i];
            final ctrls = _ctrls[e.matricule]!;
            final moy = e.moyenne;
            final mc = moy == null ? const Color(0xFF94A3B8)
                : moy >= 10 ? const Color(0xFF15803D)
                : moy >= 5 ? const Color(0xFFD97706) : const Color(0xFFDC2626);
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${e.prenoms} ${e.nom}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(e.matricule, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B),
                    fontFamily: 'monospace')),
                const SizedBox(height: 8),
                Row(children: [
                  ...List.generate(4, (j) => Expanded(
                    child: Padding(padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: readOnly
                            ? Center(child: Text(ctrls[j].text.isEmpty ? '—' : ctrls[j].text,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))
                            : TextField(
                                controller: ctrls[j],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                onChanged: (_) => setState(() {
                                  e.note1 = double.tryParse(ctrls[0].text);
                                  e.note2 = double.tryParse(ctrls[1].text);
                                  e.note3 = double.tryParse(ctrls[2].text);
                                  e.note4 = double.tryParse(ctrls[3].text);
                                }),
                                decoration: const InputDecoration(border: InputBorder.none,
                                    hintText: '—', hintStyle: TextStyle(color: Color(0xFFCBD5E1)),
                                    contentPadding: EdgeInsets.zero),
                              ),
                      ),
                    ),
                  )),
                  Expanded(child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: mc.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: mc.withOpacity(0.3)),
                    ),
                    child: Center(child: Text(moy != null ? moy.toStringAsFixed(1) : '—',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: mc))),
                  )),
                ]),
              ]),
            );
          },
        )),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PAGE LISTE FILIÈRE
// ════════════════════════════════════════════════════════════════════════════
class _PageListeFiliere extends StatelessWidget {
  final AdminFiliere filiere;
  final List<AdminEtudiant> etudiants;
  const _PageListeFiliere({required this.filiere, required this.etudiants});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppPalette.blue, foregroundColor: Colors.white, elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(filiere.nom, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          Text('${filiere.niveau} · ${etudiants.length} étudiants',
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
      ),
      body: Column(children: [
        Container(
          color: AppPalette.blue, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: const Row(children: [
            Expanded(flex: 3, child: Text('Étudiant',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70))),
            Expanded(child: Text('N1', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70))),
            Expanded(child: Text('N2', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70))),
            Expanded(child: Text('N3', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70))),
            Expanded(child: Text('N4', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70))),
            Expanded(child: Text('Moy.', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70))),
          ]),
        ),
        Expanded(child: etudiants.isEmpty
            ? const Center(child: Text('Aucun étudiant', style: TextStyle(color: Color(0xFF94A3B8))))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: etudiants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final e = etudiants[i];
                  final noteEtud = adminFeuillesNotes
                      .where((f) => f.filiereId == filiere.id)
                      .expand((f) => f.etudiants)
                      .where((ne) => ne.matricule == e.matricule)
                      .firstOrNull;
                  final moy = noteEtud?.moyenne;
                  final mc = moy == null ? const Color(0xFF94A3B8)
                      : moy >= 10 ? const Color(0xFF15803D)
                      : moy >= 5 ? const Color(0xFFD97706) : const Color(0xFFDC2626);
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Row(children: [
                      Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${e.prenoms} ${e.nom}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        Text(e.matricule, style: const TextStyle(fontSize: 10,
                            color: Color(0xFF64748B), fontFamily: 'monospace')),
                      ])),
                      ...[noteEtud?.note1, noteEtud?.note2, noteEtud?.note3, noteEtud?.note4]
                          .map((n) => Expanded(child: Text(
                            n != null ? n.toStringAsFixed(1) : '—',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ))),
                      Expanded(child: Text(moy != null ? moy.toStringAsFixed(1) : '—',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: mc))),
                    ]),
                  );
                },
              )),
      ]),
    );
  }
}

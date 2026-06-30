import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';

// ── Données mock ───────────────────────────────────────────────────────────

class _Classe {
  final String id, nom, niveau, filiere;
  final int effectif;
  const _Classe({required this.id, required this.nom, required this.niveau, required this.filiere, required this.effectif});
}

class _Etudiant {
  final String matricule, nom, prenoms, classeId;
  const _Etudiant({required this.matricule, required this.nom, required this.prenoms, required this.classeId});
}

class _Cours {
  final String id, titre, matiere, classeId, date;
  const _Cours({required this.id, required this.titre, required this.matiere, required this.classeId, required this.date});
}

class _Note {
  final String matricule;
  double? note;
  _Note({required this.matricule, this.note});
}

final _mockClasses = [
  const _Classe(id: 'c1', nom: 'Licence 2 - RT', niveau: 'Licence 2', filiere: 'Réseaux & Télécommunications', effectif: 32),
  const _Classe(id: 'c2', nom: 'Licence 3 - INFO', niveau: 'Licence 3', filiere: 'Informatique de Gestion', effectif: 28),
  const _Classe(id: 'c3', nom: 'Licence 1 - RT', niveau: 'Licence 1', filiere: 'Réseaux & Télécommunications', effectif: 40),
];

final _mockEtudiants = [
  const _Etudiant(matricule: '24IST-O2/1851', nom: 'KOURAOGO', prenoms: 'Ibrahim', classeId: 'c1'),
  const _Etudiant(matricule: '24IST-O2/1234', nom: 'TRAORÉ', prenoms: 'Fatimata', classeId: 'c1'),
  const _Etudiant(matricule: '24IST-O2/1852', nom: 'SAWADOGO', prenoms: 'Abdoul', classeId: 'c1'),
  const _Etudiant(matricule: '24IST-O2/1853', nom: 'OUÉDRAOGO', prenoms: 'Mariama', classeId: 'c1'),
  const _Etudiant(matricule: '24IST-O2/1854', nom: 'ZONGO', prenoms: 'Luc', classeId: 'c1'),
  const _Etudiant(matricule: '24IST-O3/0001', nom: 'KABORÉ', prenoms: 'Alice', classeId: 'c2'),
  const _Etudiant(matricule: '24IST-O3/0002', nom: 'COMPAORÉ', prenoms: 'Rasmané', classeId: 'c2'),
  const _Etudiant(matricule: '24IST-O3/0003', nom: 'BELEM', prenoms: 'Sandra', classeId: 'c2'),
  const _Etudiant(matricule: '24IST-O1/0010', nom: 'NIKIEMA', prenoms: 'Paul', classeId: 'c3'),
  const _Etudiant(matricule: '24IST-O1/0011', nom: 'SOME', prenoms: 'Awa', classeId: 'c3'),
];

final List<_Cours> _mockCours = [
  const _Cours(id: 'k1', titre: 'Introduction aux Réseaux', matiere: 'Administration Réseau', classeId: 'c1', date: '2025-03-10'),
  const _Cours(id: 'k2', titre: 'Protocoles TCP/IP', matiere: 'Administration Réseau', classeId: 'c1', date: '2025-03-17'),
  const _Cours(id: 'k3', titre: 'Algèbre Relationnelle', matiere: 'Bases de Données', classeId: 'c2', date: '2025-03-12'),
];

// ── Shell principal ────────────────────────────────────────────────────────

class ProfessorShell extends StatefulWidget {
  const ProfessorShell({super.key, required this.profile, required this.onLogout});
  final StudentProfile profile;
  final VoidCallback onLogout;

  @override
  State<ProfessorShell> createState() => _ProfessorShellState();
}

class _ProfessorShellState extends State<ProfessorShell> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _ClassesTab(profile: widget.profile),
      _CoursTab(profile: widget.profile),
      _NotesTab(profile: widget.profile),
      _ProfilTab(profile: widget.profile, onLogout: widget.onLogout),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(key: ValueKey(_currentTab), child: pages[_currentTab]),
      ),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.groups_outlined, Icons.groups_rounded, 'Classes', 0, AppPalette.blue),
              _navItem(Icons.menu_book_outlined, Icons.menu_book_rounded, 'Cours', 1, AppPalette.blue),
              _navItem(Icons.fact_check_outlined, Icons.fact_check_rounded, 'Notes', 2, const Color(0xFF10B981)),
              _navItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil', 3, const Color(0xFF42A5F5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, IconData activeIcon, String label, int index, Color color) {
    final isActive = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48, height: 38,
            decoration: BoxDecoration(
              color: isActive ? color.withValues(alpha: 0.13) : const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isActive ? activeIcon : icon, size: 22,
                color: isActive ? color : const Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? color : const Color(0xFF9CA3AF)),
            child: Text(label),
          ),
        ]),
      ),
    );
  }
}

// ── Header commun ──────────────────────────────────────────────────────────

class _ProfHeader extends StatelessWidget {
  const _ProfHeader({required this.title, required this.subtitle, this.trailing});
  final String title, subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A3D91), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(children: [
        Positioned(top: -30, right: -30,
          child: Container(width: 120, height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07)))),
        Positioned(bottom: -20, right: 60,
          child: Container(width: 70, height: 70,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppPalette.yellow.withValues(alpha: 0.12)))),
        SafeArea(bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75))),
              ])),
              if (trailing != null) trailing!,
            ]),
          )),
      ]),
    );
  }
}

// ── Onglet Classes ─────────────────────────────────────────────────────────

class _ClassesTab extends StatefulWidget {
  const _ClassesTab({required this.profile});
  final StudentProfile profile;

  @override
  State<_ClassesTab> createState() => _ClassesTabState();
}

class _ClassesTabState extends State<_ClassesTab> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _ProfHeader(
        title: 'Mes Classes',
        subtitle: '${_mockClasses.length} classes assignées',
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppPalette.yellow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('${_mockEtudiants.length} étudiants',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF3A2A00))),
        ),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: _mockClasses.length,
          itemBuilder: (_, i) => _ClasseCard(
            classe: _mockClasses[i],
            onTap: () => _showClasseDetail(context, _mockClasses[i]),
          ),
        ),
      ),
    ]);
  }

  void _showClasseDetail(BuildContext context, _Classe classe) {
    final etudiants = _mockEtudiants.where((e) => e.classeId == classe.id).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClasseDetailSheet(classe: classe, etudiants: etudiants),
    );
  }
}

class _ClasseCard extends StatelessWidget {
  const _ClasseCard({required this.classe, required this.onTap});
  final _Classe classe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0A4DA2), Color(0xFF1565C0)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.groups_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(classe.nom, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 3),
            Text(classe.filiere, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            Row(children: [
              _badge('${classe.effectif} étudiants', const Color(0xFF0A4DA2)),
              const SizedBox(width: 8),
              _badge(classe.niveau, AppPalette.yellow, textColor: const Color(0xFF3A2A00)),
            ]),
          ])),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        ]),
      ),
    );
  }

  Widget _badge(String text, Color bg, {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg.withValues(alpha: bg == AppPalette.yellow ? 1 : 0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: bg == AppPalette.yellow ? textColor : bg)),
    );
  }
}

class _ClasseDetailSheet extends StatelessWidget {
  const _ClasseDetailSheet({required this.classe, required this.etudiants});
  final _Classe classe;
  final List<_Etudiant> etudiants;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(classe.nom, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              Text('${etudiants.length} étudiant(s) dans cette classe',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            ])),
          ]),
        ),
        const SizedBox(height: 12),
        const Divider(),
        Expanded(
          child: etudiants.isEmpty
              ? const Center(child: Text('Aucun étudiant trouvé', style: TextStyle(color: Color(0xFF94A3B8))))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: etudiants.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final e = etudiants[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: AppPalette.lightBlue,
                        child: Text(e.prenoms[0], style: const TextStyle(color: AppPalette.blue, fontWeight: FontWeight.w700)),
                      ),
                      title: Text('${e.prenoms} ${e.nom}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(e.matricule, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    );
                  }),
        ),
      ]),
    );
  }
}

// ── Onglet Cours ───────────────────────────────────────────────────────────

class _CoursTab extends StatefulWidget {
  const _CoursTab({required this.profile});
  final StudentProfile profile;

  @override
  State<_CoursTab> createState() => _CoursTabState();
}

class _CoursTabState extends State<_CoursTab> {
  String? _filtreClasse;

  List<_Cours> get _coursFiltres => _filtreClasse == null
      ? _mockCours
      : _mockCours.where((c) => c.classeId == _filtreClasse).toList();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _ProfHeader(
        title: 'Mes Cours',
        subtitle: '${_mockCours.length} supports publiés',
        trailing: GestureDetector(
          onTap: () => _showAjoutCours(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
          ),
        ),
      ),
      // Filtre par classe
      SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          children: [
            _filtreChip('Toutes', null),
            ..._mockClasses.map((c) => _filtreChip(c.nom, c.id)),
          ],
        ),
      ),
      Expanded(
        child: _coursFiltres.isEmpty
            ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.menu_book_outlined, size: 60, color: Color(0xFFCBD5E1)),
                SizedBox(height: 12),
                Text('Aucun cours pour cette classe', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _coursFiltres.length,
                itemBuilder: (_, i) => _CoursCard(cours: _coursFiltres[i],
                    onDelete: () => setState(() => _mockCours.removeWhere((c) => c.id == _coursFiltres[i].id))),
              ),
      ),
    ]);
  }

  Widget _filtreChip(String label, String? classeId) {
    final isActive = _filtreClasse == classeId;
    return GestureDetector(
      onTap: () => setState(() => _filtreClasse = classeId),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppPalette.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppPalette.blue : const Color(0xFFE2E8F0)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF64748B))),
      ),
    );
  }

  void _showAjoutCours(BuildContext context) {
    final titreCtrl = TextEditingController();
    final matiereCtrl = TextEditingController();
    String? classeId = _mockClasses.first.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ajouter un cours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            _input(titreCtrl, 'Titre du cours', Icons.title_rounded),
            const SizedBox(height: 12),
            _input(matiereCtrl, 'Matière', Icons.school_outlined),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: classeId,
              decoration: InputDecoration(
                labelText: 'Classe',
                prefixIcon: const Icon(Icons.groups_outlined, color: AppPalette.blue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: _mockClasses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nom))).toList(),
              onChanged: (v) => setS(() => classeId = v),
            ),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  if (titreCtrl.text.isNotEmpty && matiereCtrl.text.isNotEmpty) {
                    setState(() {
                      _mockCours.add(_Cours(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        titre: titreCtrl.text,
                        matiere: matiereCtrl.text,
                        classeId: classeId!,
                        date: DateTime.now().toIso8601String().split('T')[0],
                      ));
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Publier le cours', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      )),
    );
  }

  Widget _input(TextEditingController c, String hint, IconData icon) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppPalette.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

class _CoursCard extends StatelessWidget {
  const _CoursCard({required this.cours, required this.onDelete});
  final _Cours cours;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final classe = _mockClasses.firstWhere((c) => c.id == cours.classeId,
        orElse: () => const _Classe(id: '', nom: 'Inconnue', niveau: '', filiere: '', effectif: 0));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.menu_book_rounded, color: Color(0xFFD97706), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cours.titre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(cours.matiere, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.groups_outlined, size: 12, color: Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text(classe.nom, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            const SizedBox(width: 12),
            const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text(cours.date, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ]),
        ])),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
          onPressed: onDelete,
        ),
      ]),
    );
  }
}

// ── Onglet Notes ───────────────────────────────────────────────────────────

class _NotesTab extends StatefulWidget {
  const _NotesTab({required this.profile});
  final StudentProfile profile;

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  _Classe? _classe;
  String _matiere = 'Administration Réseau';
  String _type = 'DS';
  final Map<String, double?> _notes = {};
  bool _saved = false;

  static const _matieres = ['Administration Réseau', 'Bases de Données', 'Développement Web', 'Anglais Technique', 'Sécurité Réseau'];
  static const _types = ['DS', 'TP', 'Examen Final', 'Contrôle Continu'];

  List<_Etudiant> get _etudiants => _classe == null ? [] : _mockEtudiants.where((e) => e.classeId == _classe!.id).toList();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _ProfHeader(
        title: 'Saisie des Notes',
        subtitle: _classe == null ? 'Sélectionnez une classe' : '${_etudiants.length} étudiants',
        trailing: _saved
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Enregistré', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              )
            : null,
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Sélecteurs
            _selectCard(),
            const SizedBox(height: 14),
            if (_classe != null) ...[
              if (_etudiants.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Aucun étudiant dans cette classe', style: TextStyle(color: Color(0xFF94A3B8))),
                ))
              else ...[
                ..._etudiants.map((e) => _NoteRow(
                  etudiant: e,
                  note: _notes[e.matricule],
                  onChanged: (v) => setState(() { _notes[e.matricule] = v; _saved = false; }),
                )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Enregistrer les notes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => setState(() => _saved = true),
                  ),
                ),
              ],
            ],
          ]),
        ),
      ),
    ]);
  }

  Widget _selectCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(children: [
        DropdownButtonFormField<_Classe>(
          initialValue: _classe,
          hint: const Text('Sélectionner une classe'),
          decoration: InputDecoration(
            labelText: 'Classe',
            prefixIcon: const Icon(Icons.groups_outlined, color: AppPalette.blue),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: _mockClasses.map((c) => DropdownMenuItem(value: c, child: Text(c.nom))).toList(),
          onChanged: (v) => setState(() { _classe = v; _notes.clear(); _saved = false; }),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _matiere,
          decoration: InputDecoration(
            labelText: 'Matière',
            prefixIcon: const Icon(Icons.school_outlined, color: AppPalette.blue),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: _matieres.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => setState(() => _matiere = v!),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: InputDecoration(
            labelText: 'Type d\'évaluation',
            prefixIcon: const Icon(Icons.fact_check_outlined, color: AppPalette.blue),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _type = v!),
        ),
      ]),
    );
  }
}

class _NoteRow extends StatefulWidget {
  const _NoteRow({required this.etudiant, required this.note, required this.onChanged});
  final _Etudiant etudiant;
  final double? note;
  final ValueChanged<double?> onChanged;

  @override
  State<_NoteRow> createState() => _NoteRowState();
}

class _NoteRowState extends State<_NoteRow> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.note?.toString() ?? '');
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    Color noteColor = const Color(0xFF64748B);
    if (note != null) noteColor = note >= 10 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Row(children: [
        CircleAvatar(radius: 18, backgroundColor: AppPalette.lightBlue,
          child: Text(widget.etudiant.prenoms[0], style: const TextStyle(color: AppPalette.blue, fontWeight: FontWeight.w700, fontSize: 13))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${widget.etudiant.prenoms} ${widget.etudiant.nom}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
          Text(widget.etudiant.matricule, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ])),
        SizedBox(
          width: 70,
          child: TextField(
            controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: noteColor),
            decoration: InputDecoration(
              hintText: '/20',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v);
              widget.onChanged(parsed != null && parsed >= 0 && parsed <= 20 ? parsed : null);
            },
          ),
        ),
      ]),
    );
  }
}

// ── Onglet Profil ──────────────────────────────────────────────────────────

class _ProfilTab extends StatelessWidget {
  const _ProfilTab({required this.profile, required this.onLogout});
  final StudentProfile profile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _ProfHeader(title: 'Mon Profil', subtitle: 'Espace personnel enseignant'),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // Avatar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppPalette.blue, Color(0xFF1565C0)]),
                boxShadow: [BoxShadow(color: AppPalette.blue.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: const CircleAvatar(radius: 48, backgroundColor: Colors.white,
                child: Icon(Icons.school_rounded, size: 50, color: AppPalette.blue)),
            ),
            const SizedBox(height: 14),
            Text('${profile.prenoms} ${profile.nom}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppPalette.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Professeur', style: TextStyle(color: AppPalette.blue, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(height: 24),
            // Infos
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
              ),
              child: Column(children: [
                _profilLigne(Icons.badge_outlined, 'Matricule', profile.matricule),
                const Divider(height: 1, indent: 56),
                _profilLigne(Icons.domain_rounded, 'Département', profile.filiere),
                const Divider(height: 1, indent: 56),
                _profilLigne(Icons.groups_rounded, 'Classes assignées', '${_mockClasses.length} classes'),
                const Divider(height: 1, indent: 56),
                _profilLigne(Icons.menu_book_rounded, 'Cours publiés', '${_mockCours.length} supports'),
              ]),
            ),
            const SizedBox(height: 24),
            // Stats
            Row(children: [
              _statCard('${_mockClasses.length}', 'Classes', Icons.groups_rounded, AppPalette.blue),
              const SizedBox(width: 12),
              _statCard('${_mockCours.length}', 'Cours', Icons.menu_book_rounded, const Color(0xFFD97706)),
              const SizedBox(width: 12),
              _statCard('${_mockEtudiants.length}', 'Étudiants', Icons.people_rounded, const Color(0xFF10B981)),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                label: const Text('Se déconnecter', style: TextStyle(color: Color(0xFFEF4444), fontSize: 15, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _profilLigne(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: AppPalette.lightBlue, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppPalette.blue, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        ])),
      ]),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ]),
      ),
    );
  }
}

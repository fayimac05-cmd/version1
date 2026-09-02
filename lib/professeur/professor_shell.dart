import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../services/api_service.dart';
import '../services/professor_service.dart';
import '../theme/app_palette.dart';
import 'appel_tab.dart';
import 'notes_tab.dart';
import 'programme_screen.dart';
import 'upload_course_screen.dart';

// ── Shell principal ────────────────────────────────────────────────────────

class ProfessorShell extends StatefulWidget {
  const ProfessorShell({
    super.key,
    required this.profile,
    required this.onLogout,
  });
  final StudentProfile profile;
  final VoidCallback onLogout;

  @override
  State<ProfessorShell> createState() => _ProfessorShellState();
}

class _ProfessorShellState extends State<ProfessorShell> {
  int _currentTab = 0;

  // Classe présélectionnée depuis "Mes Classes" pour l'appel ou les notes.
  Map<String, dynamic>? _classePreselectionnee;

  void _ouvrirDepuisClasse(int tab, Map<String, dynamic> classe) {
    setState(() {
      _classePreselectionnee = classe;
      _currentTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _ClassesTab(
        profile: widget.profile,
        onFaireAppel: (c) => _ouvrirDepuisClasse(2, c),
        onSaisirNotes: (c) => _ouvrirDepuisClasse(3, c),
      ),
      _CoursTab(profile: widget.profile),
      AppelTab(initialClasse: _classePreselectionnee),
      NotesTab(initialClasse: _classePreselectionnee),
      _ProfilTab(profile: widget.profile, onLogout: widget.onLogout),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(_currentTab),
          child: pages[_currentTab],
        ),
      ),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                Icons.groups_outlined,
                Icons.groups_rounded,
                'Classes',
                0,
                AppPalette.blue,
              ),
              _navItem(
                Icons.menu_book_outlined,
                Icons.menu_book_rounded,
                'Cours',
                1,
                AppPalette.blue,
              ),
              _navItem(
                Icons.how_to_reg_outlined,
                Icons.how_to_reg_rounded,
                'Appel',
                2,
                const Color(0xFF0EA5E9),
              ),
              _navItem(
                Icons.fact_check_outlined,
                Icons.fact_check_rounded,
                'Notes',
                3,
                const Color(0xFF10B981),
              ),
              _navItem(
                Icons.person_outline_rounded,
                Icons.person_rounded,
                'Profil',
                4,
                const Color(0xFF42A5F5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
    Color color,
  ) {
    final isActive = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() {
        _currentTab = index;
        _classePreselectionnee = null;
      }),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 38,
              decoration: BoxDecoration(
                color: isActive
                    ? color.withValues(alpha: 0.13)
                    : const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                size: 22,
                color: isActive ? color : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? color : const Color(0xFF9CA3AF),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header commun ──────────────────────────────────────────────────────────

class _ProfHeader extends StatelessWidget {
  const _ProfHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });
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
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            right: 60,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.yellow.withValues(alpha: 0.12),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Onglet Classes ─────────────────────────────────────────────────────────

class _ClassesTab extends StatefulWidget {
  const _ClassesTab({
    required this.profile,
    required this.onFaireAppel,
    required this.onSaisirNotes,
  });
  final StudentProfile profile;
  final ValueChanged<Map<String, dynamic>> onFaireAppel;
  final ValueChanged<Map<String, dynamic>> onSaisirNotes;

  @override
  State<_ClassesTab> createState() => _ClassesTabState();
}

class _ClassesTabState extends State<_ClassesTab> {
  List<dynamic> _classes = [];
  bool _loading = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _chargerClasses();
  }

  Future<void> _chargerClasses() async {
    setState(() {
      _loading = true;
      _erreur = null;
    });
    final res = await ProfessorService.getClasses();
    if (!mounted) return;
    setState(() {
      _classes = res['success'] == true ? res['data'] as List<dynamic> : [];
      _erreur = res['success'] == true
          ? null
          : (res['error']?.toString() ?? 'Erreur lors du chargement.');
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfHeader(
          title: 'Mes Classes',
          subtitle: '${_classes.length} classe(s)',
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _erreur != null
              ? _ErrorState(message: _erreur!, onRetry: _chargerClasses)
              : _classes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 60,
                        color: Color(0xFFCBD5E1),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Aucune classe disponible',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _chargerClasses,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: _classes.length,
                    itemBuilder: (_, i) => _ClasseCard(
                      classe: _classes[i],
                      onTap: () => _showClasseDetail(context, _classes[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _showClasseDetail(BuildContext context, dynamic classe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClasseDetailSheet(
        classe: classe,
        onFaireAppel: widget.onFaireAppel,
        onSaisirNotes: widget.onSaisirNotes,
      ),
    );
  }
}

class _ClasseCard extends StatelessWidget {
  const _ClasseCard({required this.classe, required this.onTap});
  final dynamic classe;
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A4DA2), Color(0xFF1565C0)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.groups_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${classe['nom'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${classe['description'] ?? classe['filiere_nom'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _badge(
                        '${classe['niveau'] ?? ''}',
                        AppPalette.yellow,
                        textColor: const Color(0xFF3A2A00),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: bg == AppPalette.yellow ? 1 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: bg == AppPalette.yellow ? textColor : bg,
        ),
      ),
    );
  }
}

class _ClasseDetailSheet extends StatefulWidget {
  const _ClasseDetailSheet({
    required this.classe,
    required this.onFaireAppel,
    required this.onSaisirNotes,
  });
  final dynamic classe;
  final ValueChanged<Map<String, dynamic>> onFaireAppel;
  final ValueChanged<Map<String, dynamic>> onSaisirNotes;

  @override
  State<_ClasseDetailSheet> createState() => _ClasseDetailSheetState();
}

class _ClasseDetailSheetState extends State<_ClasseDetailSheet> {
  List<dynamic> _etudiants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _chargerEtudiants();
  }

  Future<void> _chargerEtudiants() async {
    final res = await ProfessorService.getStudentsByFiliere(
      int.parse('${widget.classe['id']}'),
    );
    if (!mounted) return;
    setState(() {
      _etudiants = res['success'] == true ? res['data'] as List<dynamic> : [];
      _loading = false;
    });
  }

  void _lancerAction(ValueChanged<Map<String, dynamic>> action) {
    Navigator.pop(context);
    action(Map<String, dynamic>.from(widget.classe as Map));
  }

  void _ajouterModule() {
    final nomCtrl = TextEditingController();
    final coefCtrl = TextEditingController(text: '2');
    final vhCtrl = TextEditingController(text: '30');
    bool envoi = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Nouveau module — ${widget.classe['nom']}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomCtrl,
                decoration: InputDecoration(
                  labelText: 'Nom du module',
                  prefixIcon: const Icon(
                    Icons.menu_book_outlined,
                    color: AppPalette.blue,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: coefCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Coefficient',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: vhCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Volume (h)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: envoi
                  ? null
                  : () async {
                      if (nomCtrl.text.trim().isEmpty) return;
                      setDialogState(() => envoi = true);
                      final res = await ApiService.createModule(
                        nom: nomCtrl.text.trim(),
                        coefficient: int.tryParse(coefCtrl.text) ?? 2,
                        volumeHoraire: int.tryParse(vhCtrl.text) ?? 30,
                        filiereId: int.tryParse('${widget.classe['id']}'),
                        filiereNom: '${widget.classe['nom']}',
                      );
                      if (!mounted || !context.mounted || !dialogCtx.mounted) {
                        return;
                      }
                      if (res['success'] == true) {
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Module "${nomCtrl.text.trim()}" ajouté à ${widget.classe['nom']}.',
                            ),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      } else {
                        setDialogState(() => envoi = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              res['error']?.toString() ??
                                  'Erreur lors de l\'ajout du module.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: envoi
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.classe['nom'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  _loading
                      ? 'Chargement des étudiants...'
                      : '${_etudiants.length} étudiant(s) dans cette classe',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                        label: const Text(
                          'Faire l\'appel',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _lancerAction(widget.onFaireAppel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.fact_check_rounded, size: 18),
                        label: const Text(
                          'Saisir les notes',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _lancerAction(widget.onSaisirNotes),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.library_add_outlined, size: 18),
                    label: const Text(
                      'Ajouter un module',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppPalette.blue,
                      side: const BorderSide(color: AppPalette.blue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _ajouterModule,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _etudiants.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun étudiant trouvé',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _etudiants.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final e = _etudiants[i];
                      final prenoms = '${e['prenoms'] ?? ''}';
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppPalette.lightBlue,
                          child: Text(
                            prenoms.isNotEmpty ? prenoms[0] : '?',
                            style: const TextStyle(
                              color: AppPalette.blue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          '$prenoms ${e['nom'] ?? ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${e['matricule'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
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
  List<dynamic> _cours = [];
  bool _loading = true;
  String? _erreur;
  String? _filtreFiliere; // filiere_id sélectionné dans les chips

  @override
  void initState() {
    super.initState();
    _chargerCours();
  }

  Future<void> _chargerCours() async {
    setState(() {
      _loading = true;
      _erreur = null;
    });
    final res = await ProfessorService.getCours();
    if (!mounted) return;
    setState(() {
      _cours = res['success'] == true ? res['data'] as List<dynamic> : [];
      _erreur = res['success'] == true
          ? null
          : (res['error']?.toString() ?? 'Erreur lors du chargement.');
      _loading = false;
    });
  }

  Future<void> _ajouterCours() async {
    final publie = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const UploadCourseScreen()));
    if (publie == true) _chargerCours();
  }

  List<dynamic> get _coursFiltres => _filtreFiliere == null
      ? _cours
      : _cours
            .where((c) => c['filiere_id'].toString() == _filtreFiliere)
            .toList();

  /// Filières distinctes présentes dans les cours publiés (id -> nom).
  Map<String, String> get _filieres {
    final map = <String, String>{};
    for (final c in _cours) {
      final id = c['filiere_id']?.toString();
      if (id != null) map[id] = '${c['filiere_nom'] ?? 'Filière $id'}';
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfHeader(
          title: 'Mes Cours',
          subtitle: '${_cours.length} support(s) publié(s)',
          trailing: GestureDetector(
            onTap: _ajouterCours,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
        if (_filieres.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              children: [
                _filtreChip('Toutes', null),
                ..._filieres.entries.map((e) => _filtreChip(e.value, e.key)),
              ],
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _erreur != null
              ? _ErrorState(message: _erreur!, onRetry: _chargerCours)
              : _coursFiltres.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.menu_book_outlined,
                        size: 60,
                        color: Color(0xFFCBD5E1),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucun cours publié',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Publier un cours'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _ajouterCours,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _chargerCours,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _coursFiltres.length,
                    itemBuilder: (_, i) => _CoursCard(cours: _coursFiltres[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _filtreChip(String label, String? filiereId) {
    final isActive = _filtreFiliere == filiereId;
    return GestureDetector(
      onTap: () => setState(() => _filtreFiliere = filiereId),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppPalette.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppPalette.blue : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _CoursCard extends StatelessWidget {
  const _CoursCard({required this.cours});
  final dynamic cours;

  @override
  Widget build(BuildContext context) {
    final date = (cours['date_creation'] ?? '').toString().split('T').first;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFFD97706),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cours['titre'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${cours['module_nom'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.groups_outlined,
                      size: 12,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${cours['filiere_nom'] ?? ''} · ${cours['niveau'] ?? ''}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── État d'erreur réutilisable ─────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 54,
              color: Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Onglet Profil ──────────────────────────────────────────────────────────

class _ProfilTab extends StatefulWidget {
  const _ProfilTab({required this.profile, required this.onLogout});
  final StudentProfile profile;
  final VoidCallback onLogout;

  @override
  State<_ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<_ProfilTab> {
  StudentProfile get profile => widget.profile;
  int _nbClasses = 0;
  int _nbCours = 0;
  int _nbSessions = 0;

  @override
  void initState() {
    super.initState();
    _chargerStats();
  }

  Future<void> _chargerStats() async {
    final classesRes = await ProfessorService.getClasses();
    final coursRes = await ProfessorService.getCours();
    final sessionsRes = await ProfessorService.getGradeSessions();
    if (!mounted) return;
    setState(() {
      _nbClasses = classesRes['success'] == true
          ? (classesRes['data'] as List).length
          : 0;
      _nbCours = coursRes['success'] == true
          ? (coursRes['data'] as List).length
          : 0;
      _nbSessions = sessionsRes['success'] == true
          ? (sessionsRes['data'] as List).length
          : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfHeader(
          title: 'Mon Profil',
          subtitle: 'Espace personnel enseignant',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppPalette.blue, Color(0xFF1565C0)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.blue.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.school_rounded,
                      size: 50,
                      color: AppPalette.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${profile.prenoms} ${profile.nom}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Professeur',
                    style: TextStyle(
                      color: AppPalette.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Infos
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _profilLigne(
                        Icons.badge_outlined,
                        'Matricule',
                        profile.matricule,
                      ),
                      const Divider(height: 1, indent: 56),
                      _profilLigne(
                        Icons.domain_rounded,
                        'Département',
                        profile.filiere,
                      ),
                      const Divider(height: 1, indent: 56),
                      _profilLigne(
                        Icons.groups_rounded,
                        'Classes',
                        '$_nbClasses classe(s)',
                      ),
                      const Divider(height: 1, indent: 56),
                      _profilLigne(
                        Icons.menu_book_rounded,
                        'Cours publiés',
                        '$_nbCours support(s)',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Stats
                Row(
                  children: [
                    _statCard(
                      '$_nbClasses',
                      'Classes',
                      Icons.groups_rounded,
                      AppPalette.blue,
                    ),
                    const SizedBox(width: 12),
                    _statCard(
                      '$_nbCours',
                      'Cours',
                      Icons.menu_book_rounded,
                      const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 12),
                    _statCard(
                      '$_nbSessions',
                      'Sessions notes',
                      Icons.fact_check_rounded,
                      const Color(0xFF10B981),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Programme hebdomadaire : déclarer et transmettre ses heures libres
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProgrammeScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.edit_calendar_rounded, size: 20),
                    label: const Text(
                      'Mon programme / heures libres',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: widget.onLogout,
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEF4444),
                    ),
                    label: const Text(
                      'Se déconnecter',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFEF4444),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _profilLigne(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppPalette.lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppPalette.blue, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}

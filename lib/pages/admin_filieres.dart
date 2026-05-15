import 'package:flutter/material.dart';
import '../pages/admin_data.dart';
import '../theme/app_palette.dart';

class AdminFilieres extends StatefulWidget {
  const AdminFilieres({super.key});

  @override
  State<AdminFilieres> createState() => _AdminFilieresState();
}

class _AdminFilieresState extends State<AdminFilieres>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _filiereSelectee;

  final List<String> _domaines = ['Sciences & Technologies', 'Sciences de Gestion'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<AdminFiliere> _parDomaine(String domaine) =>
      adminFilieres.where((f) => f.domaine == domaine).toList();

  int _nbEtudiants(String filiereId) =>
      adminEtudiants.where((e) => e.filiereId == filiereId).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Filières & Modules',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppPalette.blue,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppPalette.blue,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Sciences & Technologies'),
            Tab(text: 'Sciences de Gestion'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _domaines.map((d) => _listeFilieres(d)).toList(),
      ),
    );
  }

  Widget _listeFilieres(String domaine) {
    final filieres = _parDomaine(domaine);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filieres.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _carteFiliere(filieres[i]),
    );
  }

  Widget _carteFiliere(AdminFiliere f) {
    final isOpen = _filiereSelectee == f.id;
    final nbEtudiants = _nbEtudiants(f.id);
    final etudiants = adminEtudiants.where((e) => e.filiereId == f.id).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpen ? AppPalette.blue.withOpacity(0.4) : const Color(0xFFE2E8F0),
          width: isOpen ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── En-tête filière ─────────────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() =>
              _filiereSelectee = isOpen ? null : f.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: f.domaine.contains('Technologies')
                      ? const Color(0xFFEFF6FF) : const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  f.domaine.contains('Technologies')
                      ? Icons.computer_rounded : Icons.business_center_rounded,
                  color: f.domaine.contains('Technologies')
                      ? AppPalette.blue : const Color(0xFF7C3AED),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.nom, style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 3),
                  Row(children: [
                    _badge('${f.niveau}', const Color(0xFF0F172A), const Color(0xFFF1F5F9)),
                    const SizedBox(width: 6),
                    _badge('${f.modules.length} modules', AppPalette.blue, const Color(0xFFEFF6FF)),
                    const SizedBox(width: 6),
                    _badge('$nbEtudiants étudiants', const Color(0xFF15803D), const Color(0xFFF0FDF4)),
                  ]),
                ],
              )),
              Icon(
                isOpen ? Icons.expand_less : Icons.expand_more,
                color: const Color(0xFF94A3B8),
              ),
            ]),
          ),
        ),

        // ── Contenu déployé ─────────────────────────────────────────────
        if (isOpen) ...[
          Container(height: 1, color: const Color(0xFFF1F5F9)),

          // Onglets Modules / Étudiants
          DefaultTabController(
            length: 2,
            child: Column(children: [
              const TabBar(
                labelColor: AppPalette.blue,
                unselectedLabelColor: Color(0xFF64748B),
                indicatorColor: AppPalette.blue,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: 'Modules'),
                  Tab(text: 'Étudiants'),
                ],
              ),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              SizedBox(
                height: (f.modules.length * 72.0).clamp(100, 300),
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // ── Tab Modules
                    ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: f.modules.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, j) => _carteModule(f.modules[j]),
                    ),
                    // ── Tab Étudiants
                    etudiants.isEmpty
                        ? const Center(child: Text('Aucun étudiant dans cette filière',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: etudiants.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (_, j) => _ligneEtudiant(etudiants[j]),
                          ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _carteModule(AdminModule m) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppPalette.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text(m.code.substring(0, 2),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                  color: AppPalette.blue))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.nom, style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(m.profNom, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _badge('Coef. ${m.coefficient}', AppPalette.blue, const Color(0xFFEFF6FF)),
          const SizedBox(height: 4),
          Text('${m.volumeHoraire}h',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ]),
      ]),
    );
  }

  Widget _ligneEtudiant(AdminEtudiant e) {
    Color sc; String sl;
    switch (e.statut) {
      case 'suspendu': sc = const Color(0xFFD97706); sl = 'Suspendu'; break;
      case 'renvoyé':  sc = const Color(0xFFDC2626); sl = 'Renvoyé';  break;
      default:         sc = const Color(0xFF15803D); sl = 'Actif';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppPalette.blue.withOpacity(0.1), shape: BoxShape.circle),
          child: Center(child: Text('${e.prenoms[0]}${e.nom[0]}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                  color: AppPalette.blue))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${e.prenoms} ${e.nom}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(e.matricule,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B),
                  fontFamily: 'monospace')),
        ])),
        _badge(sl, sc, sc.withOpacity(0.1)),
      ]),
    );
  }

  Widget _badge(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11,
          fontWeight: FontWeight.bold, color: color)),
    );
  }
}

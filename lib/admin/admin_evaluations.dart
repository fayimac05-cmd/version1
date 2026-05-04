import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_professeurs.dart';
import '../admin/admin_filieres.dart';

class PeriodeEvaluation {
  final String id, filiere, dateDebut, dateFin;
  bool ouverte;
  final Map<String, List<double>> resultats; // professeur -> notes
  PeriodeEvaluation({required this.id, required this.filiere,
      required this.dateDebut, required this.dateFin,
      this.ouverte = false, required this.resultats});
}

final List<PeriodeEvaluation> adminEvaluations = [
  PeriodeEvaluation(
    id: 'EV001', filiere: 'Réseaux Informatiques et Télécom',
    dateDebut: '01/05/2025', dateFin: '10/05/2025', ouverte: true,
    resultats: {
      'OUÉDRAOGO Mamadou': [4.0, 4.5, 3.5, 4.2, 4.8],
      'SAWADOGO Issa': [4.5, 5.0, 4.0, 4.5, 4.2],
    }),
  PeriodeEvaluation(
    id: 'EV002', filiere: 'Électrotechnique',
    dateDebut: '01/05/2025', dateFin: '10/05/2025', ouverte: false,
    resultats: {
      'COMPAORÉ Brahima': [3.5, 4.0, 3.8, 3.2, 4.1],
    }),
  PeriodeEvaluation(
    id: 'EV003', filiere: 'Marketing & Communication',
    dateDebut: '', dateFin: '', ouverte: false, resultats: {}),
];

class AdminEvaluations extends StatefulWidget {
  const AdminEvaluations({super.key});
  @override State<AdminEvaluations> createState() => _AdminEvaluationsState();
}

class _AdminEvaluationsState extends State<AdminEvaluations> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Évaluation des Professeurs', style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E))),
                const Text('Évaluations anonymes par les étudiants',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              ])),
              GestureDetector(
                onTap: () => _ouvrirPeriode(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: AdminTheme.primary,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Ouvrir une période', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                  ])),
              ),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AdminTheme.infoLight,
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.shield_rounded, color: AdminTheme.info, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Les évaluations sont 100% anonymes. Aucun étudiant n\'est identifié.',
                  style: TextStyle(fontSize: 12, color: AdminTheme.info,
                      fontWeight: FontWeight.w600))),
              ])),
          ])),
        Container(height: 1, color: const Color(0xFFE5E7EB)),
        Expanded(child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: adminEvaluations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _cartePeriode(adminEvaluations[i]),
        )),
      ]),
    );
  }

  Widget _cartePeriode(PeriodeEvaluation ev) {
    final hasResultats = ev.resultats.isNotEmpty;

    return Container(
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ev.ouverte
              ? AdminTheme.success.withOpacity(0.3) : const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(
                color: ev.ouverte ? AdminTheme.successLight : const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(ev.ouverte ? Icons.lock_open_rounded : Icons.lock_rounded,
                  color: ev.ouverte ? AdminTheme.success : const Color(0xFF9CA3AF),
                  size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ev.filiere, style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              if (ev.dateDebut.isNotEmpty)
                Text('Du ${ev.dateDebut} au ${ev.dateFin}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ev.ouverte ? AdminTheme.successLight : const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(20)),
              child: Text(ev.ouverte ? '🟢 Ouverte' : '⚫ Fermée',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: ev.ouverte ? AdminTheme.success : const Color(0xFF9CA3AF)))),
          ])),

        // Résultats par prof
        if (hasResultats) ...[
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Résultats (${ev.resultats.values.fold(0, (s, v) => s + v.length)} réponses)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: Color(0xFF374151))),
              const SizedBox(height: 10),
              ...ev.resultats.entries.map((entry) {
                final prof    = entry.key;
                final notes   = entry.value;
                final moyenne = notes.fold(0.0, (s, n) => s + n) / notes.length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Container(width: 34, height: 34,
                      decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: Center(child: Text(prof[0],
                          style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED))))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(prof, style: const TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 4),
                      ClipRRect(borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: moyenne / 5, minHeight: 5,
                          backgroundColor: const Color(0xFFE5E7EB),
                          color: moyenne >= 4 ? AdminTheme.success
                              : moyenne >= 3 ? AdminTheme.warning : AdminTheme.danger)),
                    ])),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Row(children: [
                        ...List.generate(5, (i) => Icon(
                            i < moyenne.floor()
                                ? Icons.star_rounded : Icons.star_border_rounded,
                            color: AdminTheme.accent, size: 12)),
                      ]),
                      Text(moyenne.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w800, color: AdminTheme.accent)),
                    ]),
                  ]));
              }),
            ])),
        ],

        // Actions
        Container(height: 1, color: const Color(0xFFE5E7EB)),
        Padding(padding: const EdgeInsets.all(12),
          child: Row(children: [
            if (ev.ouverte) ...[
              Expanded(child: _btn('🔒 Clôturer', AdminTheme.danger, AdminTheme.dangerLight,
                () { setState(() => ev.ouverte = false);
                  _snack('Période d\'évaluation clôturée.'); })),
              const SizedBox(width: 8),
            ],
            if (hasResultats)
              Expanded(child: _btn('📊 Voir rapport complet',
                  AdminTheme.primary, AdminTheme.primaryLight,
                () => _snack('📊 Rapport en cours de génération...'))),
            if (!ev.ouverte && ev.dateDebut.isEmpty)
              Expanded(child: _btn('🟢 Ouvrir la période',
                  AdminTheme.success, AdminTheme.successLight,
                () => _ouvrirPeriodeFiliere(ev))),
          ])),
      ]));
  }

  void _ouvrirPeriode() {
    final filiere = adminFilieres.isNotEmpty ? adminFilieres.first.nom : '';
    String filiereSelected = filiere;
    final debutCtrl = TextEditingController(text: '01/05/2025');
    final finCtrl   = TextEditingController(text: '10/05/2025');

    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) =>
        Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(children: [
                const Expanded(child: Text('Ouvrir une période d\'évaluation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                IconButton(icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx)),
              ])),
            const Divider(color: Color(0xFFE5E7EB)),
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Filière'),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                    value: filiereSelected, isExpanded: true,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)),
                    items: adminFilieres.map((f) => DropdownMenuItem(
                        value: f.nom, child: Text(f.nom,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setS(() => filiereSelected = v!),
                  ))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    _label('Date de début'),
                    _inputField(debutCtrl, '01/05/2025'),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    _label('Date de fin'),
                    _inputField(finCtrl, '10/05/2025'),
                  ])),
                ]),
              ]))),
            Padding(padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  setState(() => adminEvaluations.add(PeriodeEvaluation(
                    id: 'EV${adminEvaluations.length + 1}',
                    filiere: filiereSelected,
                    dateDebut: debutCtrl.text, dateFin: finCtrl.text,
                    ouverte: true, resultats: {})));
                  Navigator.pop(ctx);
                  _snack('✅ Période ouverte pour $filiereSelected !');
                },
                child: Container(width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: AdminTheme.primary,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('Ouvrir la période',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: Colors.white)))))),
          ]))));
  }

  void _ouvrirPeriodeFiliere(PeriodeEvaluation ev) {
    setState(() {
      ev.ouverte = true;
      if (ev.dateDebut.isEmpty) {
        // Pas possible de modifier final fields, juste changer ouverte
      }
    });
    _snack('✅ Période ouverte pour ${ev.filiere} !');
  }

  Widget _btn(String label, Color fg, Color bg, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
        child: Container(padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8),
              border: Border.all(color: fg.withOpacity(0.3))),
          child: Center(child: Text(label, style: TextStyle(fontSize: 12,
              fontWeight: FontWeight.w700, color: fg)))));

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 5),
    child: Text(t, style: const TextStyle(fontSize: 12,
        fontWeight: FontWeight.w700, color: Color(0xFF374151))));

  Widget _inputField(TextEditingController ctrl, String hint) =>
      Container(decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB))),
        child: TextField(controller: ctrl, style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))));

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: AdminTheme.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
}

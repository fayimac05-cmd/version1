import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_widgets.dart';
import '../models/etudiant_model.dart';
import '../utils/snackbar_helper.dart';

class Parent {
  final String id, nom, prenoms, email, telephone, relation, matriculeEnfant;
  bool credentialsEnvoyes;
  Parent({required this.id, required this.nom, required this.prenoms,
      required this.email, required this.telephone, required this.relation,
      required this.matriculeEnfant, this.credentialsEnvoyes = false});
}

final List<Parent> adminParents = [
  Parent(id: 'PAR001', nom: 'KOURAOGO', prenoms: 'Seydou',
      email: 'seydou.kouraogo@gmail.com', telephone: '65001234',
      relation: 'Père', matriculeEnfant: '24IST-O2/1851',
      credentialsEnvoyes: true),
  Parent(id: 'PAR002', nom: 'TRAORÉ', prenoms: 'Moussa',
      email: 'moussa.traore@gmail.com', telephone: '76000002',
      relation: 'Père', matriculeEnfant: '24IST-O2/1234',
      credentialsEnvoyes: true),
  Parent(id: 'PAR003', nom: 'SAWADOGO', prenoms: 'Mariam',
      email: 'mariam.sawadogo@gmail.com', telephone: '70000003',
      relation: 'Mère', matriculeEnfant: '23IST-O2/0987',
      credentialsEnvoyes: false),
];

class AdminParents extends StatefulWidget {
  const AdminParents({super.key});
  @override State<AdminParents> createState() => _AdminParentsState();
}

class _AdminParentsState extends State<AdminParents> {
  String _query = '';
  final _searchCtrl = TextEditingController();

  List<Parent> get _filtered => adminParents.where((p) {
        final q = _query.toLowerCase();
        return q.isEmpty ||
            p.nom.toLowerCase().contains(q) ||
            p.prenoms.toLowerCase().contains(q) ||
            p.matriculeEnfant.toLowerCase().contains(q);
      }).toList();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Column(children: [
        AdminPageHeader(
          title: 'Parents',
          subtitle: '${adminParents.length} parents enregistrés',
          trailing: AdminAddButton(label: 'Ajouter', onTap: () => _ajouterParent()),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AdminSearchBar(
            controller: _searchCtrl,
            hintText: 'Rechercher un parent...',
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 16),
        adminDivider,
        Expanded(child: _filtered.isEmpty
            ? _vide()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _carteParent(_filtered[i]),
              )),
      ]),
    );
  }

  Widget _carteParent(Parent p) {
    final enfant = adminEtudiants.where((e) => e.matricule == p.matriculeEnfant).firstOrNull;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: AdminTheme.warningLight, shape: BoxShape.circle),
              child: Center(
                  child: Text('${p.prenoms[0]}${p.nom[0]}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.warning)))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p.prenoms} ${p.nom}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            Text('${p.relation} · ${p.telephone}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            Text(p.email, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: p.credentialsEnvoyes ? AdminTheme.successLight : AdminTheme.warningLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(p.credentialsEnvoyes ? '✅ Accès OK' : '⏳ En attente',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: p.credentialsEnvoyes ? AdminTheme.success : AdminTheme.warning)),
          ),
        ]),
        if (enfant != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.school_rounded, color: AdminTheme.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Enfant : ${enfant.prenoms} ${enfant.nom}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AdminTheme.primary)),
                Text('${p.matriculeEnfant} · ${enfant.filiere} · ${enfant.niveau}',
                    style: const TextStyle(fontSize: 11, color: AdminTheme.primaryMid)),
              ])),
            ]),
          ),
        ],
        const SizedBox(height: 10),
        Row(children: [
          if (!p.credentialsEnvoyes) ...[
            Expanded(
                child: _btn('📧 Envoyer accès', AdminTheme.primary, () {
              setState(() => p.credentialsEnvoyes = true);
              _snack('✅ Identifiants envoyés à ${p.email}');
            })),
            const SizedBox(width: 8),
          ],
          Expanded(
              child: _btn('💬 Message', AdminTheme.info, () => _snack('💬 Ouverture conversation avec ${p.prenoms}'))),
        ]),
      ]),
    );
  }

  Widget _btn(String label, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha:0.2)),
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color))),
        ),
      );

  void _ajouterParent() {
    final controllers = {
      'nom': TextEditingController(),
      'prenom': TextEditingController(),
      'email': TextEditingController(),
      'tel': TextEditingController(),
      'mat': TextEditingController(),
    };
    String relation = 'Père';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(children: [
                const Expanded(child: Text('Ajouter un parent', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ]),
            ),
            Expanded(
                child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Nom *'), _input(controllers['nom']!, 'Nom de famille'),
                const SizedBox(height: 12),
                _label('Prénom *'), _input(controllers['prenom']!, 'Prénom'),
                const SizedBox(height: 12),
                _label('Email *'), _input(controllers['email']!, 'Email', type: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _label('Téléphone *'), _input(controllers['tel']!, '70000000', type: TextInputType.phone),
                const SizedBox(height: 12),
                _label('Relation'),
                Row(
                    children: ['Père', 'Mère', 'Tuteur'].map((r) {
                  final active = relation == r;
                  return GestureDetector(
                    onTap: () => setS(() => relation = r),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AdminTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: active ? AdminTheme.primary : const Color(0xFFE5E7EB)),
                      ),
                      child: Text(r, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : const Color(0xFF6B7280))),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 12),
                _label('Matricule de l\'enfant *'), _input(controllers['mat']!, 'Ex: 24IST-O2/1851'),
              ]),
            )),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  final nom = controllers['nom']!.text;
                  final prenom = controllers['prenom']!.text;
                  final mat = controllers['mat']!.text.toUpperCase();
                  if (nom.isEmpty || prenom.isEmpty) return;
                  final enfantExiste = adminEtudiants.any((e) => e.matricule == mat);
                  if (!enfantExiste) {
                    _snack('❌ Erreur : Matricule enfant introuvable', isError: true);
                    return;
                  }
                  setState(() => adminParents.add(Parent(
                        id: 'PAR${adminParents.length + 1}',
                        nom: nom.toUpperCase(),
                        prenoms: prenom,
                        email: controllers['email']!.text,
                        telephone: controllers['tel']!.text,
                        relation: relation,
                        matriculeEnfant: mat,
                      )));
                  for (var c in controllers.values) c.dispose();
                  Navigator.pop(ctx);
                  _snack('✅ Parent ajouté !');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: AdminTheme.primary, borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                    child: Text('Enregistrer', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _vide() => const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.people_outline_rounded, size: 56, color: Color(0xFFD1D5DB)),
          SizedBox(height: 12),
          Text('Aucun parent trouvé', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          SizedBox(height: 4),
          Text('Modifiez votre recherche ou ajoutez un parent.', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
        ]),
      );

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AdminTheme.danger : AdminTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      );

  Widget _input(TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: TextField(controller: ctrl, keyboardType: type,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))));
}

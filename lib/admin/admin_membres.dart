import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';

class Membre {
  final String id, nom, prenoms, email, role;
  final Map<String, bool> droits;
  bool actif;
  final String dateCreation;
  Membre({required this.id, required this.nom, required this.prenoms,
      required this.email, required this.role, required this.droits,
      required this.dateCreation, this.actif = true});
}

final List<Membre> adminMembres = [
  Membre(id: 'M001', nom: 'COMPAORÉ', prenoms: 'Idrissa', email: 'idrissa@ist.bf',
      role: 'Super Admin', dateCreation: '01/09/2020',
      droits: {'etudiants': true, 'notes': true, 'reclamations': true, 'filieres': true,
          'professeurs': true, 'parents': true, 'messages': true, 'annonces': true,
          'stats': true, 'membres': true}),
  Membre(id: 'M002', nom: 'KABORÉ', prenoms: 'Sylvie', email: 'sylvie@ist.bf',
      role: 'Scolarité', dateCreation: '01/01/2022',
      droits: {'etudiants': true, 'notes': true, 'reclamations': true, 'filieres': true,
          'professeurs': false, 'parents': true, 'messages': false, 'annonces': false,
          'stats': true, 'membres': false}),
  Membre(id: 'M003', nom: 'ZONGO', prenoms: 'Marcel', email: 'marcel@ist.bf',
      role: 'Secrétariat', dateCreation: '15/03/2023',
      droits: {'etudiants': false, 'notes': false, 'reclamations': false, 'filieres': false,
          'professeurs': false, 'parents': false, 'messages': true, 'annonces': true,
          'stats': false, 'membres': false}),
];

const _sectionsLabels = {
  'etudiants': '🎓 Étudiants',
  'notes': '📊 Notes',
  'reclamations': '⚠️ Réclamations',
  'filieres': '🏫 Filières',
  'professeurs': '👨‍🏫 Professeurs',
  'parents': '👨‍👩‍👦 Parents',
  'messages': '💬 Messages',
  'annonces': '📢 Annonces',
  'stats': '📈 Statistiques',
  'membres': '🛡️ Membres',
};

class AdminMembres extends StatefulWidget {
  const AdminMembres({super.key});
  @override State<AdminMembres> createState() => _AdminMembresState();
}

class _AdminMembresState extends State<AdminMembres> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(children: [
        Container(color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Membres & Rôles', style: TextStyle(fontSize: 22,
                  fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
              Text('${adminMembres.length} membres · Gérez les accès au panel admin',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            ])),
            GestureDetector(
              onTap: () => _creerMembre(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: AdminTheme.primary,
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text('Nouveau membre', style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),
          ])),
        Container(height: 1, color: const Color(0xFFE5E7EB)),
        Expanded(child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: adminMembres.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _carteMembre(adminMembres[i]),
        )),
      ]),
    );
  }

  Widget _carteMembre(Membre m) {
    final isSuperAdmin = m.role == 'Super Admin';
    final nbDroits = m.droits.values.where((v) => v).length;

    return Container(
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSuperAdmin
              ? AdminTheme.primary.withOpacity(0.3) : const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 48, height: 48,
              decoration: BoxDecoration(
                color: isSuperAdmin ? AdminTheme.primaryLight
                    : const Color(0xFFF5F7FA),
                shape: BoxShape.circle,
                border: Border.all(color: isSuperAdmin
                    ? AdminTheme.primary.withOpacity(0.3) : const Color(0xFFE5E7EB))),
              child: Center(child: Text('${m.prenoms[0]}${m.nom[0]}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                      color: isSuperAdmin ? AdminTheme.primary : const Color(0xFF6B7280))))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${m.prenoms} ${m.nom}', style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              Text(m.email, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              const SizedBox(height: 4),
              Row(children: [
                _roleBadge(m.role),
                const SizedBox(width: 8),
                Text('$nbDroits/${m.droits.length} sections',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              ]),
            ])),
            if (!isSuperAdmin)
              GestureDetector(
                onTap: () => _gererDroits(m),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AdminTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('Droits', style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700, color: AdminTheme.primary)))),
          ])),

        // Droits affichés
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Wrap(spacing: 6, runSpacing: 6,
            children: m.droits.entries.map((e) {
              final label = _sectionsLabels[e.key] ?? e.key;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: e.value ? AdminTheme.successLight : const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: e.value
                      ? AdminTheme.success.withOpacity(0.3) : const Color(0xFFE5E7EB))),
                child: Text(label, style: TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: e.value ? AdminTheme.success : const Color(0xFF9CA3AF))));
            }).toList())),
      ]),
    );
  }

  Widget _roleBadge(String role) {
    final isSA = role == 'Super Admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSA ? AdminTheme.accentLight : AdminTheme.primaryLight,
        borderRadius: BorderRadius.circular(8)),
      child: Text(role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: isSA ? AdminTheme.accent : AdminTheme.primary)));
  }

  void _gererDroits(Membre m) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) =>
        Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Droits — ${m.prenoms} ${m.nom}', style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(m.role, style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280))),
                ])),
                IconButton(icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx)),
              ])),
            const Divider(color: Color(0xFFE5E7EB)),
            Expanded(child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: _sectionsLabels.entries.map((e) =>
                  SwitchListTile(
                    title: Text(e.value, style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                    value: m.droits[e.key] ?? false,
                    activeColor: AdminTheme.primary,
                    onChanged: (v) {
                      setS(() => m.droits[e.key] = v);
                      setState(() {});
                    },
                  )).toList())),
            Padding(padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () { Navigator.pop(ctx); _snack('✅ Droits mis à jour !'); },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: AdminTheme.primary,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('Enregistrer les droits',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: Colors.white)))))),
          ]))));
  }

  void _creerMembre() {
    final nomCtrl    = TextEditingController();
    final prenomCtrl = TextEditingController();
    final emailCtrl  = TextEditingController();
    String role = 'Scolarité';
    final droits = <String, bool>{for (final k in _sectionsLabels.keys) k: false};

    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) =>
        Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(children: [
                const Expanded(child: Text('Nouveau membre admin', style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800))),
                IconButton(icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx)),
              ])),
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Infos
                _label('Nom *'), _input(nomCtrl, 'Nom de famille'),
                const SizedBox(height: 10),
                _label('Prénom *'), _input(prenomCtrl, 'Prénom'),
                const SizedBox(height: 10),
                _label('Email *'), _input(emailCtrl, 'Email', type: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _label('Rôle'),
                Wrap(spacing: 8, runSpacing: 8,
                  children: ['Scolarité', 'Secrétariat', 'BDE Admin', 'Rôle personnalisé']
                      .map((r) {
                    final active = role == r;
                    return GestureDetector(onTap: () => setS(() => role = r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? AdminTheme.primary : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: active ? AdminTheme.primary : const Color(0xFFE5E7EB))),
                        child: Text(r, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: active ? Colors.white : const Color(0xFF6B7280)))));
                  }).toList()),
                const SizedBox(height: 16),
                _label('Sections accessibles'),
                ...droits.entries.map((e) => SwitchListTile(
                  contentPadding: EdgeInsets.zero, dense: true,
                  title: Text(_sectionsLabels[e.key] ?? e.key,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  value: e.value, activeColor: AdminTheme.primary,
                  onChanged: (v) => setS(() => droits[e.key] = v))),
              ]))),
            Padding(padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  if (nomCtrl.text.isEmpty || prenomCtrl.text.isEmpty) return;
                  setState(() => adminMembres.add(Membre(
                    id: 'M${adminMembres.length + 1}',
                    nom: nomCtrl.text.toUpperCase(), prenoms: prenomCtrl.text,
                    email: emailCtrl.text, role: role,
                    droits: Map.from(droits), dateCreation: '01/05/2025',
                  )));
                  Navigator.pop(ctx);
                  _snack('✅ Compte créé ! Identifiants envoyés par email.');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: AdminTheme.primary,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('Créer le compte',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: Colors.white)))))),
          ]))));
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: const TextStyle(fontSize: 13,
        fontWeight: FontWeight.w700, color: Color(0xFF374151))));

  Widget _input(TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text}) =>
      Container(
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: TextField(controller: ctrl, keyboardType: type,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))));

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: AdminTheme.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
}

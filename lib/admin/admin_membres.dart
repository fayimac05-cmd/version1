import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_widgets.dart';
import '../utils/snackbar_helper.dart';

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
// Utilisation de titres simples, les icônes sont gérées dynamiquement si besoin
const _sectionsLabels = {
  'etudiants': 'Étudiants',
  'notes': 'Notes',
  'reclamations': 'Réclamations',
  'filieres': 'Filières',
  'professeurs': 'Professeurs',
  'parents': 'Parents',
  'messages': 'Messages',
  'annonces': 'Annonces',
  'stats': 'Statistiques',
  'membres': 'Membres',
};
IconData _getIconForSection(String key) {
  switch (key) {
    case 'etudiants': return Icons.school_rounded;
    case 'notes': return Icons.bar_chart_rounded;
    case 'reclamations': return Icons.warning_amber_rounded;
    case 'filieres': return Icons.apartment_rounded;
    case 'professeurs': return Icons.person_outline_rounded;
    // ... ajoute les autres ici
    default: return Icons.widgets_rounded;
  }
}

class AdminMembres extends StatefulWidget {
  const AdminMembres({super.key});
  @override State<AdminMembres> createState() => _AdminMembresState();
}

class _AdminMembresState extends State<AdminMembres> {
  // Ajout d'une méthode pour supprimer un membre
  void _supprimerMembre(Membre m) {
    setState(() => adminMembres.remove(m));
    _snack('🗑️ Membre supprimé');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Column(children: [
        AdminPageHeader(
          title: 'Membres & Rôles',
          subtitle: '${adminMembres.length} membres · Gérez les accès au panel admin',
          trailing: AdminAddButton(label: 'Nouveau membre', onTap: () => _creerMembre()),
        ),
        adminDivider,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuperAdmin ? AdminTheme.primary.withValues(alpha:0.3) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: isSuperAdmin ? AdminTheme.primaryLight : const Color(0xFFF5F7FA),
                  child: Text(
                    '${m.prenoms[0]}${m.nom[0]}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSuperAdmin ? AdminTheme.primary : const Color(0xFF6B7280),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${m.prenoms} ${m.nom}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(m.email, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                ),
                // Boutons d'action
                if (!isSuperAdmin) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 20, color: AdminTheme.iconBgAlt),
                    onPressed: () => _gererDroits(m),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                    onPressed: () => _supprimerMembre(m),
                  ),
                ],
              ],
            ),
          ),
          // Droits affichés avec icônes
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: m.droits.entries.map((e) {
                final label = _sectionsLabels[e.key] ?? e.key;
                final icon = _getIconForSection(e.key); // Utilisation de ta fonction
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: e.value ? AdminTheme.successLight : const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: e.value ? AdminTheme.success.withValues(alpha:0.3) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 12, color: e.value ? AdminTheme.success : const Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: e.value ? AdminTheme.success : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  Widget _roleBadge(String role) {
    final isSA = role == 'Super Admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSA ? AdminTheme.iconBgAlt : AdminTheme.iconBg,
        borderRadius: BorderRadius.circular(8)),
      child: Text(role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: isSA ? AdminTheme.iconFgAlt : AdminTheme.iconFg)));
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
                    activeThumbColor: AdminTheme.iconFg,
                    activeTrackColor: AdminTheme.iconBg,
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
                  decoration: BoxDecoration(color: AdminTheme.iconBgAlt,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('Enregistrer les droits',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: AdminTheme.iconFgAlt)))))),
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
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          // ... [Header du Modal] ...
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Nom *'), _input(nomCtrl, 'Nom'),
              const SizedBox(height: 10),
              _label('Prénom *'), _input(prenomCtrl, 'Prénom'),
              const SizedBox(height: 10),
              _label('Email *'), _input(emailCtrl, 'exemple@ist.bf', type: TextInputType.emailAddress),
              
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
                          color: active ? AdminTheme.iconBg : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: active ? AdminTheme.iconBg : const Color(0xFFE5E7EB))),
                        child: Text(r, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: active ? Colors.white : const Color(0xFF6B7280)))));
                  }).toList()),
                const SizedBox(height: 16),
                _label('Sections accessibles'),
                ...droits.entries.map((e) => SwitchListTile(
                  contentPadding: EdgeInsets.zero, dense: true,
                  title: Text(_sectionsLabels[e.key] ?? e.key,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  value: e.value,
                  activeThumbColor: AdminTheme.iconFg,
                  activeTrackColor: AdminTheme.iconBg,
                  onChanged: (v) => setS(() => droits[e.key] = v))),
            ])
          )),
          Padding(padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.iconBgAlt, foregroundColor: AdminTheme.iconFgAlt, minimumSize: const Size(double.infinity, 50)),
              onPressed: () {
                if (nomCtrl.text.isEmpty || !emailCtrl.text.contains('@')) {
                  _snack('⚠️ Veuillez remplir correctement les champs');
                  return;
                }
                setState(() => adminMembres.add(Membre(
                  id: 'M${DateTime.now().millisecondsSinceEpoch}',
                  nom: nomCtrl.text.toUpperCase(), prenoms: prenomCtrl.text,
                  email: emailCtrl.text, role: role,
                  droits: Map.from(droits), dateCreation: DateTime.now().toString().split(' ')[0],
                )));
                Navigator.pop(ctx);
              },
              child: const Text('Créer le compte', style: TextStyle(color: Colors.white)),
            ),
          ),
        ]),
      )),
    );
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

  void _snack(String msg) => showAppSnackBar(context, msg);
}

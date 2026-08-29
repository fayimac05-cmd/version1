import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_widgets.dart';
import '../models/admin_role.dart';
import '../services/api_service.dart';
import '../utils/snackbar_helper.dart';

class Membre {
  final String id, nom, prenoms, email, role;
  final AdminRole adminRole;
  final Map<String, bool> droits;
  bool actif;
  final String dateCreation;

  Membre({
    required this.id,
    required this.nom,
    required this.prenoms,
    required this.email,
    required this.role,
    required this.droits,
    required this.dateCreation,
    this.adminRole = AdminRole.superAdmin,
    this.actif = true,
  });
}

final List<Membre> adminMembres = [
  Membre(
    id: 'M001',
    nom: 'COMPAORÉ',
    prenoms: 'Idrissa',
    email: 'idrissa@ist.bf',
    role: 'Super Admin',
    adminRole: AdminRole.superAdmin,
    dateCreation: '01/09/2020',
    droits: {
      'etudiants': true,
      'notes': true,
      'reclamations': true,
      'filieres': true,
      'professeurs': true,
      'parents': true,
      'messages': true,
      'annonces': true,
      'stats': true,
      'membres': true,
    },
  ),
  Membre(
    id: 'M002',
    nom: 'KABORÉ',
    prenoms: 'Sylvie',
    email: 'sylvie@ist.bf',
    role: 'Scolarité & Pédagogie',
    adminRole: AdminRole.scolarite,
    dateCreation: '01/01/2022',
    droits: {
      'etudiants': true,
      'notes': false,
      'reclamations': true,
      'filieres': true,
      'professeurs': true,
      'parents': true,
      'messages': false,
      'annonces': false,
      'stats': true,
      'membres': false,
    },
  ),
  Membre(
    id: 'M003',
    nom: 'ZONGO',
    prenoms: 'Marcel',
    email: 'marcel@ist.bf',
    role: 'Secrétariat & Inscriptions',
    adminRole: AdminRole.secretariat,
    dateCreation: '15/03/2023',
    droits: {
      'etudiants': true,
      'notes': false,
      'reclamations': true,
      'filieres': false,
      'professeurs': false,
      'parents': true,
      'messages': true,
      'annonces': true,
      'stats': false,
      'membres': false,
    },
  ),
  Membre(
    id: 'M004',
    nom: 'SAWADOGO',
    prenoms: 'Aïcha',
    email: 'aicha@ist.bf',
    role: 'Resp. Examens & Notes',
    adminRole: AdminRole.examens,
    dateCreation: '10/10/2024',
    droits: {
      'etudiants': false,
      'notes': true,
      'reclamations': true,
      'filieres': false,
      'professeurs': false,
      'parents': false,
      'messages': false,
      'annonces': false,
      'stats': true,
      'membres': false,
    },
  ),
];

const _sectionsLabels = {
  'etudiants': 'Étudiants',
  'notes': 'Notes & Examens',
  'reclamations': 'Réclamations',
  'filieres': 'Filières & EDT',
  'professeurs': 'Professeurs',
  'parents': 'Parents',
  'messages': 'Messages',
  'annonces': 'Annonces',
  'stats': 'Statistiques',
  'membres': 'Membres & Rôles',
};

IconData _getIconForSection(String key) {
  switch (key) {
    case 'etudiants':
      return Icons.school_rounded;
    case 'notes':
      return Icons.bar_chart_rounded;
    case 'reclamations':
      return Icons.warning_amber_rounded;
    case 'filieres':
      return Icons.apartment_rounded;
    case 'professeurs':
      return Icons.person_outline_rounded;
    case 'parents':
      return Icons.family_restroom_rounded;
    case 'messages':
      return Icons.forum_outlined;
    case 'annonces':
      return Icons.campaign_outlined;
    case 'stats':
      return Icons.insert_chart_outlined_rounded;
    case 'membres':
      return Icons.shield_outlined;
    default:
      return Icons.widgets_rounded;
  }
}

Map<String, bool> _getDefaultRightsForRole(AdminRole role) {
  switch (role) {
    case AdminRole.superAdmin:
      return {for (final k in _sectionsLabels.keys) k: true};
    case AdminRole.scolarite:
      return {
        'etudiants': true,
        'notes': false,
        'reclamations': true,
        'filieres': true,
        'professeurs': true,
        'parents': true,
        'messages': false,
        'annonces': false,
        'stats': true,
        'membres': false,
      };
    case AdminRole.examens:
      return {
        'etudiants': false,
        'notes': true,
        'reclamations': true,
        'filieres': false,
        'professeurs': false,
        'parents': false,
        'messages': false,
        'annonces': false,
        'stats': true,
        'membres': false,
      };
    case AdminRole.secretariat:
      return {
        'etudiants': true,
        'notes': false,
        'reclamations': true,
        'filieres': false,
        'professeurs': false,
        'parents': true,
        'messages': true,
        'annonces': true,
        'stats': false,
        'membres': false,
      };
    case AdminRole.communication:
      return {
        'etudiants': false,
        'notes': false,
        'reclamations': false,
        'filieres': false,
        'professeurs': false,
        'parents': false,
        'messages': true,
        'annonces': true,
        'stats': false,
        'membres': false,
      };
    case AdminRole.cycleDirecteur:
      return {
        'etudiants': true,
        'notes': true,
        'reclamations': true,
        'filieres': true,
        'professeurs': true,
        'parents': true,
        'messages': true,
        'annonces': true,
        'stats': true,
        'membres': false,
      };
  }
}

class AdminMembres extends StatefulWidget {
  const AdminMembres({super.key});

  @override
  State<AdminMembres> createState() => _AdminMembresState();
}

class _AdminMembresState extends State<AdminMembres> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _chargerMembresDepuisBDD();
  }

  Future<void> _chargerMembresDepuisBDD() async {
    setState(() => _loading = true);
    final res = await ApiService.getMembresAdmin();
    if (res['success'] == true && res['data'] != null) {
      final list = res['data'] as List<dynamic>;
      if (list.isNotEmpty) {
        final bddMembres = list.map((item) {
          final subRoleCode = item['admin_sub_role']?.toString() ?? item['role']?.toString();
          final adminRole = AdminRoleExtension.fromCode(subRoleCode);
          Map<String, bool> droitsMap = {};
          if (item['droits'] is Map) {
            (item['droits'] as Map).forEach((k, v) => droitsMap[k.toString()] = v == true);
          } else {
            droitsMap = _getDefaultRightsForRole(adminRole);
          }

          return Membre(
            id: item['id']?.toString() ?? 'M${DateTime.now().millisecondsSinceEpoch}',
            nom: item['nom']?.toString() ?? '',
            prenoms: item['prenoms']?.toString() ?? '',
            email: item['email']?.toString() ?? '',
            role: adminRole.label,
            adminRole: adminRole,
            droits: droitsMap,
            dateCreation: item['dateCreation']?.toString() ?? '01/01/2026',
            actif: item['actif'] != false,
          );
        }).toList();

        setState(() {
          adminMembres.clear();
          adminMembres.addAll(bddMembres);
        });
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _supprimerMembre(Membre m) async {
    setState(() => adminMembres.remove(m));
    _snack('🗑️ Membre supprimé');
    await ApiService.deleteMembreAdmin(m.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Column(children: [
        AdminPageHeader(
          title: 'Membres & Rôles Administrateurs',
          subtitle: '${adminMembres.length} membres · Subdivisez les accès au panel admin',
          trailing: AdminAddButton(label: 'Nouveau membre', onTap: () => _creerMembre()),
        ),
        adminDivider,
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: adminMembres.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _carteMembre(adminMembres[i]),
          ),
        ),
      ]),
    );
  }

  Widget _carteMembre(Membre m) {
    final isSuperAdmin = m.adminRole == AdminRole.superAdmin;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuperAdmin ? AdminTheme.primary.withValues(alpha: 0.3) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                CircleAvatar(
                  backgroundColor: isSuperAdmin ? AdminTheme.primaryLight : const Color(0xFFF5F7FA),
                  child: Text(
                    '${m.prenoms.isNotEmpty ? m.prenoms[0] : 'A'}${m.nom.isNotEmpty ? m.nom[0] : 'D'}',
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
                      Row(
                        children: [
                          Text('${m.prenoms} ${m.nom}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSuperAdmin ? const Color(0xFFEEF2FF) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              m.adminRole.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSuperAdmin ? const Color(0xFF4F46E5) : const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(m.email, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: m.droits.entries.map((e) {
                final label = _sectionsLabels[e.key] ?? e.key;
                final icon = _getIconForSection(e.key);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: e.value ? AdminTheme.successLight : const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: e.value ? AdminTheme.success.withValues(alpha: 0.3) : const Color(0xFFE5E7EB),
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

  void _gererDroits(Membre m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Droits — ${m.prenoms} ${m.nom}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          Text(m.adminRole.label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFE5E7EB)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: _sectionsLabels.entries
                      .map(
                        (e) => SwitchListTile(
                          title: Text(_sectionsLabels[e.key] ?? e.key,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          value: m.droits[e.key] ?? false,
                          activeThumbColor: AdminTheme.iconFg,
                          activeTrackColor: AdminTheme.iconBg,
                          onChanged: (v) {
                            setS(() => m.droits[e.key] = v);
                            setState(() {});
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx);
                    _snack('✅ Enregistrement en base de données...');
                    await ApiService.updatePermissionsMembre(
                      m.id,
                      permissions: m.droits,
                      role: m.adminRole.code,
                    );
                    _snack('✅ Droits synchronisés avec succès !');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AdminTheme.iconBgAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Enregistrer en base de données',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AdminTheme.iconFgAlt),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _creerMembre() {
    final nomCtrl = TextEditingController();
    final prenomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    AdminRole selectedRole = AdminRole.scolarite;
    Map<String, bool> droits = Map.from(_getDefaultRightsForRole(selectedRole));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Nouveau Membre Administrateur',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFE5E7EB)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Nom *'),
                      _input(nomCtrl, 'Nom'),
                      const SizedBox(height: 10),
                      _label('Prénom *'),
                      _input(prenomCtrl, 'Prénom'),
                      const SizedBox(height: 10),
                      _label('Email *'),
                      _input(emailCtrl, 'exemple@ist.bf', type: TextInputType.emailAddress),
                      const SizedBox(height: 14),
                      _label('Sous-rôle Administrateur'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AdminRole.values.map((r) {
                          final active = selectedRole == r;
                          return GestureDetector(
                            onTap: () => setS(() {
                              selectedRole = r;
                              droits = Map.from(_getDefaultRightsForRole(r));
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: active ? AdminTheme.iconBg : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: active ? AdminTheme.iconBg : const Color(0xFFE5E7EB)),
                              ),
                              child: Text(
                                r.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: active ? Colors.white : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      _label('Sections pré-configurées'),
                      ...droits.entries.map(
                        (e) => SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(_sectionsLabels[e.key] ?? e.key,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          value: e.value,
                          activeThumbColor: AdminTheme.iconFg,
                          activeTrackColor: AdminTheme.iconBg,
                          onChanged: (v) => setS(() => droits[e.key] = v),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.iconBgAlt,
                    foregroundColor: AdminTheme.iconFgAlt,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () async {
                    if (nomCtrl.text.isEmpty || !emailCtrl.text.contains('@')) {
                      _snack('⚠️ Veuillez remplir correctement les champs');
                      return;
                    }

                    final newMembre = Membre(
                      id: 'M${DateTime.now().millisecondsSinceEpoch}',
                      nom: nomCtrl.text.toUpperCase(),
                      prenoms: prenomCtrl.text,
                      email: emailCtrl.text,
                      role: selectedRole.label,
                      adminRole: selectedRole,
                      droits: Map.from(droits),
                      dateCreation: DateTime.now().toString().split(' ')[0],
                    );

                    setState(() => adminMembres.add(newMembre));
                    Navigator.pop(ctx);
                    _snack('⏳ Enregistrement dans Supabase/Base de données...');

                    final res = await ApiService.creerMembreAdmin(
                      nom: nomCtrl.text,
                      prenoms: prenomCtrl.text,
                      email: emailCtrl.text,
                      role: selectedRole.code,
                      permissions: droits,
                    );

                    if (res['success'] == true) {
                      _snack('✅ Administrateur enregistré avec succès en base de données !');
                      _chargerMembresDepuisBDD();
                    } else {
                      _snack('⚠️ ${res['error'] ?? 'Enregistrement local uniquement'}');
                    }
                  },
                  child: const Text('Créer le compte et enregistrer', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
      );

  Widget _input(TextEditingController ctrl, String hint, {TextInputType type = TextInputType.text}) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: type,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      );

  void _snack(String msg) => showAppSnackBar(context, msg);
}


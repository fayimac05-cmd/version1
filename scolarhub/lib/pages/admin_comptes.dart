import 'package:flutter/material.dart';
import '../pages/admin_data.dart';
import '../theme/app_palette.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLE COMPTE
// ════════════════════════════════════════════════════════════════════════════
class Compte {
  final String id;
  final String nom;
  final String prenoms;
  final String telephone;
  String email;
  final String role; // professeur / parent / admin / bde
  String motDePasse;
  final String dateCreation;
  bool actif;
  // Pour prof : modules assignés
  List<String> modules;
  // Pour parent : matricule enfant
  String? matriculeEnfant;

  Compte({
    required this.id,
    required this.nom,
    required this.prenoms,
    required this.telephone,
    required this.email,
    required this.role,
    required this.motDePasse,
    required this.dateCreation,
    this.actif = true,
    this.modules = const [],
    this.matriculeEnfant,
  });
}

// ── Données simulées ──────────────────────────────────────────────────────
List<Compte> adminComptes = [
  Compte(
    id: 'C001',
    nom: 'OUÉDRAOGO', prenoms: 'Mamadou',
    telephone: '70123456', email: 'mamadou.ouedraogo@ist.bf',
    role: 'professeur', motDePasse: 'prof123',
    dateCreation: '01/01/2025',
    modules: ['Réseaux & Protocoles'],
  ),
  Compte(
    id: 'C002',
    nom: 'SAWADOGO', prenoms: 'Issa',
    telephone: '76234567', email: 'issa.sawadogo@ist.bf',
    role: 'professeur', motDePasse: 'prof123',
    dateCreation: '01/01/2025',
    modules: ['Programmation Orientée Objet'],
  ),
  Compte(
    id: 'C003',
    nom: 'KOURAOGO', prenoms: 'Seydou',
    telephone: '65001234', email: 'seydou.kouraogo@gmail.com',
    role: 'parent', motDePasse: 'parent123',
    dateCreation: '15/01/2025',
    matriculeEnfant: '24IST-O2/1851',
  ),
  Compte(
    id: 'C004',
    nom: 'OUÉDRAOGO', prenoms: 'Aïcha',
    telephone: '70000002', email: 'aicha.ouedraogo@ist.bf',
    role: 'bde', motDePasse: 'bde123',
    dateCreation: '01/01/2025',
  ),
];

// ════════════════════════════════════════════════════════════════════════════
// PAGE COMPTES
// ════════════════════════════════════════════════════════════════════════════
class AdminComptes extends StatefulWidget {
  const AdminComptes({super.key});

  @override
  State<AdminComptes> createState() => _AdminComptesState();
}

class _AdminComptesState extends State<AdminComptes>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final List<String> _roles = ['professeur', 'parent', 'admin', 'bde'];
  final List<String> _onglets = ['Professeurs', 'Parents', 'Admins', 'BDE'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<Compte> _parRole(String role) =>
      adminComptes.where((c) => c.role == role).toList();

  Color _roleColor(String role) {
    switch (role) {
      case 'professeur': return const Color(0xFF7C3AED);
      case 'parent':     return const Color(0xFFD97706);
      case 'admin':      return const Color(0xFF15803D);
      case 'bde':        return const Color(0xFF0891B2);
      default:           return AppPalette.blue;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'professeur': return Icons.person_pin_rounded;
      case 'parent':     return Icons.family_restroom_rounded;
      case 'admin':      return Icons.admin_panel_settings_rounded;
      case 'bde':        return Icons.groups_rounded;
      default:           return Icons.person_rounded;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'professeur': return 'Professeur';
      case 'parent':     return 'Parent';
      case 'admin':      return 'Administration';
      case 'bde':        return 'BDE';
      default:           return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Gestion des Comptes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _dialogCreerCompte(context),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Créer', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppPalette.blue,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppPalette.blue,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          isScrollable: true,
          tabs: List.generate(4, (i) {
            final nb = _parRole(_roles[i]).length;
            return Tab(text: '${_onglets[i]} ($nb)');
          }),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _roles.map((r) => _listeComptes(r)).toList(),
      ),
    );
  }

  Widget _listeComptes(String role) {
    final liste = _parRole(role);
    if (liste.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(_roleIcon(role), size: 48, color: const Color(0xFFCBD5E1)),
        const SizedBox(height: 12),
        Text('Aucun compte ${_roleLabel(role)}',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _dialogCreerCompte(context, roleDefaut: role),
          icon: const Icon(Icons.add, size: 18),
          label: Text('Créer un compte ${_roleLabel(role)}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ]));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: liste.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _carteCompte(liste[i]),
    );
  }

  Widget _carteCompte(Compte c) {
    final color = _roleColor(c.role);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        ListTile(
          contentPadding: const EdgeInsets.fromLTRB(14, 10, 10, 0),
          leading: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Center(child: Text(
              '${c.prenoms[0]}${c.nom[0]}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            )),
          ),
          title: Text('${c.prenoms} ${c.nom}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A))),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.phone_outlined, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(c.telephone,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ]),
            Row(children: [
              Icon(Icons.email_outlined, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(c.email, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis),
            ]),
            if (c.role == 'professeur' && c.modules.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(spacing: 6, children: c.modules.map((m) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(m, style: TextStyle(fontSize: 10,
                    fontWeight: FontWeight.bold, color: color)),
              )).toList()),
            ],
            if (c.role == 'parent' && c.matriculeEnfant != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.badge_outlined, size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text('Enfant : ${c.matriculeEnfant}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B),
                        fontFamily: 'monospace')),
              ]),
            ],
          ]),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.actif ? const Color(0xFFF0FDF4) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(c.actif ? 'Actif' : 'Désactivé',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                        color: c.actif ? const Color(0xFF15803D) : const Color(0xFFDC2626))),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _dialogActions(c),
                child: const Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 20),
              ),
            ],
          ),
        ),

        // ── Identifiants de connexion ──────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(14, 4, 14, 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(children: [
            const Icon(Icons.key_outlined, size: 14, color: Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Connexion', style: TextStyle(fontSize: 10,
                  color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
              Text(
                c.role == 'professeur' || c.role == 'parent'
                    ? '${c.nom.toLowerCase()} ${c.prenoms.toLowerCase()} ${c.telephone}'
                    : 'Matricule : ${_getMatricule(c)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B),
                    fontFamily: 'monospace'),
              ),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
              child: Text('MDP: ${c.motDePasse}',
                  style: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.bold, color: AppPalette.blue,
                      fontFamily: 'monospace')),
            ),
          ]),
        ),
      ]),
    );
  }

  String _getMatricule(Compte c) {
    final annee = DateTime.now().year.toString().substring(2);
    switch (c.role) {
      case 'admin': return '${annee}IST-ADM/${c.id}';
      case 'bde':   return '${annee}IST-BDE/${c.id}';
      default:      return c.id;
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────
  void _dialogActions(Compte c) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('${c.prenoms} ${c.nom}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(_roleLabel(c.role),
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_reset, color: AppPalette.blue),
            title: const Text('Réinitialiser le mot de passe',
                style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(context); _dialogResetMdp(c); },
          ),
          if (c.actif)
            ListTile(
              leading: const Icon(Icons.block, color: Color(0xFFD97706)),
              title: const Text('Désactiver le compte',
                  style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                setState(() => c.actif = false);
                _snack('Compte de ${c.prenoms} désactivé.');
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Color(0xFF15803D)),
              title: const Text('Réactiver le compte',
                  style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                setState(() => c.actif = true);
                _snack('Compte de ${c.prenoms} réactivé.');
              },
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
            title: const Text('Supprimer le compte',
                style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(context); _confirmerSuppression(c); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _dialogResetMdp(Compte c) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.lock_reset, color: AppPalette.blue),
          SizedBox(width: 10),
          Text('Nouveau mot de passe',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${c.prenoms} ${c.nom}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: ctrl,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Nouveau mot de passe',
                hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF64748B), size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().length < 4) return;
              setState(() => c.motDePasse = ctrl.text.trim());
              Navigator.pop(context);
              _snack('Mot de passe mis à jour pour ${c.prenoms}.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _confirmerSuppression(Compte c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
          SizedBox(width: 10),
          Text('Supprimer le compte',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Text('Supprimer le compte de ${c.prenoms} ${c.nom} ?',
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () {
              setState(() => adminComptes.remove(c));
              Navigator.pop(context);
              _snack('Compte supprimé.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ── Créer un compte ───────────────────────────────────────────────────
  void _dialogCreerCompte(BuildContext context, {String? roleDefaut}) {
    final nomCtrl    = TextEditingController();
    final prenomCtrl = TextEditingController();
    final telCtrl    = TextEditingController();
    final emailCtrl  = TextEditingController();
    final mdpCtrl    = TextEditingController();
    final enfantCtrl = TextEditingController();
    String roleSelectionne = roleDefaut ?? 'professeur';
    String? moduleSelectionne;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.person_add_rounded, color: AppPalette.blue),
            SizedBox(width: 10),
            Text('Créer un compte', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              // ── Sélecteur de rôle ──────────────────────────────────────
              const Text('Rôle du compte',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                'professeur', 'parent', 'admin', 'bde'
              ].map((r) {
                final active = roleSelectionne == r;
                final color = _roleColor(r);
                return GestureDetector(
                  onTap: () => setS(() => roleSelectionne = r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? color : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: active ? color : Colors.transparent),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_roleIcon(r), size: 14,
                          color: active ? Colors.white : const Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(_roleLabel(r), style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: active ? Colors.white : const Color(0xFF64748B))),
                    ]),
                  ),
                );
              }).toList()),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // ── Champs communs ────────────────────────────────────────
              _champ(nomCtrl, 'Nom de famille', Icons.person_outline),
              const SizedBox(height: 10),
              _champ(prenomCtrl, 'Prénoms', Icons.person_outline),
              const SizedBox(height: 10),
              _champ(telCtrl, 'Téléphone', Icons.phone_outlined,
                  type: TextInputType.phone),
              const SizedBox(height: 10),
              _champ(emailCtrl, 'Email', Icons.email_outlined,
                  type: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _champ(mdpCtrl, 'Mot de passe initial', Icons.lock_outline),

              // ── Champ parent : enfant ─────────────────────────────────
              if (roleSelectionne == 'parent') ...[
                const SizedBox(height: 10),
                _champ(enfantCtrl, 'Matricule de l\'enfant (ex: 24IST-O2/1851)',
                    Icons.badge_outlined),
              ],

              // ── Champ prof : module ───────────────────────────────────
              if (roleSelectionne == 'professeur') ...[
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: moduleSelectionne,
                      hint: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Assigner un module (optionnel)',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      borderRadius: BorderRadius.circular(12),
                      items: adminFilieres
                          .expand((f) => f.modules)
                          .map((m) => DropdownMenuItem(
                                value: m.nom,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(m.nom,
                                      style: const TextStyle(fontSize: 13)),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setS(() => moduleSelectionne = v),
                    ),
                  ),
                ),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B)))),
            ElevatedButton(
              onPressed: () {
                if (nomCtrl.text.isEmpty || prenomCtrl.text.isEmpty ||
                    telCtrl.text.isEmpty || mdpCtrl.text.isEmpty) {
                  _snack('Remplissez tous les champs obligatoires.');
                  return;
                }
                final id = 'C${(adminComptes.length + 1).toString().padLeft(3, '0')}';
                final now = DateTime.now();
                final date =
                    '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
                setState(() {
                  adminComptes.add(Compte(
                    id: id,
                    nom: nomCtrl.text.toUpperCase(),
                    prenoms: prenomCtrl.text,
                    telephone: telCtrl.text,
                    email: emailCtrl.text,
                    role: roleSelectionne,
                    motDePasse: mdpCtrl.text,
                    dateCreation: date,
                    modules: moduleSelectionne != null ? [moduleSelectionne!] : [],
                    matriculeEnfant: roleSelectionne == 'parent' && enfantCtrl.text.isNotEmpty
                        ? enfantCtrl.text.toUpperCase() : null,
                  ));
                  // Sync avec auth_page si prof ou parent
                });
                Navigator.pop(ctx);
                _snack('Compte créé pour ${prenomCtrl.text} ${nomCtrl.text.toUpperCase()}.');
                // Aller sur l'onglet correspondant
                final idx = ['professeur','parent','admin','bde'].indexOf(roleSelectionne);
                if (idx >= 0) _tabCtrl.animateTo(idx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Créer le compte'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _champ(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF15803D),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../admin/admin_theme.dart';
import '../models/admin_role.dart';
import '../services/api_service.dart';
import '../utils/snackbar_helper.dart';

class Membre {
  final String id, nom, prenoms, email, role, domaine;
  final String? tel;
  final AdminRole adminRole;
  final Map<String, bool> droits;
  bool actif;
  final String dateCreation;

  Membre({
    required this.id,
    required this.nom,
    required this.prenoms,
    required this.email,
    this.tel,
    this.domaine = 'Tous',
    required this.role,
    required this.droits,
    required this.dateCreation,
    this.adminRole = AdminRole.superAdmin,
    this.actif = true,
  });
}

/// Liste partagée, remplie depuis la base de données (aucune donnée factice).
final List<Membre> adminMembres = [];

// ── Autorisations (regroupées comme sur la maquette) ─────────────────────────
class _Groupe {
  final String titre;
  final IconData icone;
  final List<String> cles;
  const _Groupe(this.titre, this.icone, this.cles);
}

const List<_Groupe> _groupesDroits = [
  _Groupe('Données académiques', Icons.school_outlined, ['etudiants', 'professeurs', 'filieres', 'parents']),
  _Groupe('Scolarité', Icons.fact_check_outlined, ['notes', 'bulletins', 'reclamations']),
  _Groupe('Communication', Icons.forum_outlined, ['messages', 'annonces', 'publications', 'bde']),
  _Groupe('Administration', Icons.admin_panel_settings_outlined, ['membres', 'stats']),
];

const Map<String, String> _sectionsLabels = {
  'etudiants': 'Étudiants',
  'professeurs': 'Professeurs',
  'filieres': 'Filières & EDT',
  'parents': 'Parents',
  'notes': 'Notes & examens',
  'bulletins': 'Bulletins',
  'reclamations': 'Réclamations',
  'messages': 'Messages',
  'annonces': 'Annonces',
  'publications': 'Publications statiques',
  'bde': 'BDE & Événements',
  'membres': 'Créer des membres',
  'stats': 'Statistiques',
};

IconData _iconeSection(String key) {
  switch (key) {
    case 'etudiants':
      return Icons.school_rounded;
    case 'professeurs':
      return Icons.person_outline_rounded;
    case 'filieres':
      return Icons.apartment_rounded;
    case 'parents':
      return Icons.family_restroom_rounded;
    case 'notes':
      return Icons.bar_chart_rounded;
    case 'bulletins':
      return Icons.description_outlined;
    case 'reclamations':
      return Icons.warning_amber_rounded;
    case 'messages':
      return Icons.forum_outlined;
    case 'annonces':
      return Icons.campaign_outlined;
    case 'publications':
      return Icons.article_outlined;
    case 'bde':
      return Icons.celebration_outlined;
    case 'membres':
      return Icons.group_add_outlined;
    case 'stats':
      return Icons.insert_chart_outlined_rounded;
    default:
      return Icons.widgets_rounded;
  }
}

Map<String, bool> _droitsParDefaut(AdminRole role) {
  final toutes = _sectionsLabels.keys.toList();
  final Set<String> actifs = switch (role) {
    AdminRole.superAdmin => toutes.toSet(),
    AdminRole.scolarite => {'etudiants', 'professeurs', 'filieres', 'parents', 'reclamations', 'stats'},
    AdminRole.examens => {'notes', 'bulletins', 'reclamations', 'stats'},
    AdminRole.secretariat => {'etudiants', 'parents', 'reclamations', 'messages', 'annonces'},
    AdminRole.communication => {'messages', 'annonces', 'publications', 'bde'},
    AdminRole.cycleDirecteur => toutes.where((k) => k != 'membres').toSet(),
    AdminRole.cantiniere => <String>{},
  };
  return {for (final k in toutes) k: actifs.contains(k)};
}

String _roleCourt(AdminRole r) => switch (r) {
      AdminRole.superAdmin => 'Super Admin',
      AdminRole.scolarite => 'Resp. Scolarité',
      AdminRole.examens => 'Resp. Examens',
      AdminRole.secretariat => 'Secrétariat',
      AdminRole.communication => 'Communication',
      AdminRole.cycleDirecteur => 'Dir. de Cycle',
      AdminRole.cantiniere => 'Cantine',
    };

const Color _bordureGris = Color(0xFFE5E7EB);
const Color _bordureChamp = Color(0xFFD1D5DB);
const Color _texteFonce = Color(0xFF1A1A2E);
const Color _texteGris = Color(0xFF6B7280);
const List<String> _domainesParDefaut = ['Sciences & Technologies', 'Sciences de Gestion'];

// ═════════════════════════════════════════════════════════════════════════════
class AdminMembres extends StatefulWidget {
  const AdminMembres({super.key});

  @override
  State<AdminMembres> createState() => _AdminMembresState();
}

class _AdminMembresState extends State<AdminMembres> {
  bool _loading = true;
  String? _erreur;
  List<String> _domaines = [..._domainesParDefaut];

  String _recherche = '';
  String _fDomaine = 'tous';
  String _fRole = 'tous';
  String _fStatut = 'tous';
  int _page = 0;
  static const int _parPage = 8;
  final Set<String> _coches = {};

  bool _panneau = false;
  Membre? _edition;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  void _snack(String msg) {
    if (mounted) showAppSnackBar(context, msg);
  }

  Future<void> _charger({bool silencieux = false}) async {
    if (!silencieux) setState(() { _loading = true; _erreur = null; });
    final res = await ApiService.getMembresAdmin();
    List<String> domaines = _domaines;
    try {
      final rf = await ApiService.getFilieres();
      if (rf['success'] == true) {
        final d = (rf['data'] as List)
            .map((f) => (f['domaine'] ?? '').toString().trim())
            .where((x) => x.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        if (d.isNotEmpty) domaines = d;
      }
    } catch (_) {}
    if (!mounted) return;

    if (res['success'] == true && res['data'] != null) {
      final bdd = (res['data'] as List<dynamic>).map((item) {
        final adminRole = AdminRoleExtension.fromCode(item['admin_sub_role']?.toString() ?? item['role']?.toString());
        final droits = _droitsParDefaut(adminRole);
        if (item['droits'] is Map) {
          (item['droits'] as Map).forEach((k, v) {
            if (v is bool) droits[k.toString()] = v;
          });
        }
        if (adminRole == AdminRole.superAdmin) {
          for (final k in droits.keys.toList()) { droits[k] = true; }
        }
        return Membre(
          id: item['id']?.toString() ?? '',
          nom: item['nom']?.toString() ?? '',
          prenoms: item['prenoms']?.toString() ?? '',
          email: item['email']?.toString() ?? '',
          tel: item['tel']?.toString() ?? item['numero']?.toString(),
          domaine: (item['domaine']?.toString().isNotEmpty ?? false) ? item['domaine'].toString() : 'Tous',
          role: adminRole.label,
          adminRole: adminRole,
          droits: droits,
          dateCreation: item['dateCreation']?.toString() ?? '',
          actif: item['actif'] != false,
        );
      }).toList();
      setState(() {
        adminMembres..clear()..addAll(bdd);
        _domaines = domaines;
        _erreur = null;
        _coches.removeWhere((id) => !adminMembres.any((m) => m.id == id));
        _loading = false;
      });
    } else {
      setState(() {
        _domaines = domaines;
        _erreur = res['error']?.toString() ?? 'Erreur de chargement des membres.';
        _loading = false;
      });
    }
  }

  // ── Filtres ───────────────────────────────────────────────────────────────
  List<Membre> get _filtres {
    final q = _recherche.trim().toLowerCase();
    return adminMembres.where((m) {
      if (_fStatut == 'actif' && !m.actif) return false;
      if (_fStatut == 'suspendu' && m.actif) return false;
      if (_fRole != 'tous' && m.adminRole.code != _fRole) return false;
      if (_fDomaine != 'tous' && m.domaine != _fDomaine && m.domaine != 'Tous') return false;
      if (q.isNotEmpty) {
        final t = '${m.nom} ${m.prenoms} ${m.email} ${m.tel ?? ''} ${m.adminRole.label} ${m.domaine}'.toLowerCase();
        if (!t.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  void _ouvrirPanneau([Membre? m]) => setState(() { _edition = m; _panneau = true; });
  void _fermerPanneau() => setState(() { _panneau = false; _edition = null; });

  Future<void> _changerStatut(List<Membre> ms, bool actif) async {
    int ok = 0;
    try {
      final headers = await ApiService.getHeaders();
      for (final m in ms) {
        final r = await http.patch(
          Uri.parse('${ApiService.baseUrl}/membres/${m.id}/statut'),
          headers: headers,
          body: jsonEncode({'statut': actif ? 'actif' : 'suspendu'}),
        );
        if (r.statusCode == 200) {
          ok++;
          m.actif = actif;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(_coches.clear);
    _snack(ok == ms.length
        ? (actif ? '✅ Membre(s) réactivé(s)' : '⏸️ Membre(s) suspendu(s)')
        : '⚠️ Certaines modifications ont échoué (vous ne pouvez pas modifier votre propre compte)');
  }

  Future<void> _supprimer(Membre m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce membre ?'),
        content: Text('${m.prenoms} ${m.nom} n\'aura plus accès au panel administrateur.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    final res = await ApiService.deleteMembreAdmin(m.id);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() => adminMembres.remove(m));
      _snack('🗑️ Membre supprimé');
    } else {
      _snack('⚠️ ${res['error'] ?? 'Suppression impossible'}');
    }
  }

  /// Création ou modification ; renvoie un message d'erreur, ou null si tout va bien.
  Future<String?> _sauver(Membre? existant, Map<String, dynamic> d) async {
    final AdminRole role = d['role'] as AdminRole;
    final droits = Map<String, bool>.from(d['droits'] as Map);
    if (existant == null) {
      final res = await ApiService.creerMembreAdmin(
        nom: d['nom'] as String,
        prenoms: d['prenoms'] as String,
        email: d['email'] as String,
        tel: d['tel'] as String,
        domaine: d['domaine'] as String,
        role: role.code,
        permissions: droits,
      );
      if (res['success'] != true) return res['error']?.toString() ?? 'Erreur lors de la création.';
    } else {
      try {
        final headers = await ApiService.getHeaders();
        final r = await http.put(
          Uri.parse('${ApiService.baseUrl}/membres/${existant.id}'),
          headers: headers,
          body: jsonEncode({
            'nom': d['nom'],
            'prenoms': d['prenoms'],
            'email': d['email'],
            'tel': d['tel'],
            'domaine': d['domaine'],
            'role': role.code,
            'admin_sub_role': role.code,
            'permissions': droits,
          }),
        );
        if (r.statusCode != 200) {
          String msg = 'Erreur lors de la modification.';
          try { msg = jsonDecode(utf8.decode(r.bodyBytes))['message']?.toString() ?? msg; } catch (_) {}
          return msg;
        }
      } catch (_) {
        return 'Serveur injoignable.';
      }
    }
    await _charger(silencieux: true);
    if (!mounted) return null;
    setState(() { _panneau = false; _edition = null; });
    _snack(existant == null
        ? '✅ Membre créé. Il se connectera avec son nom, prénom et téléphone.'
        : '✅ Membre mis à jour');
    return null;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: LayoutBuilder(builder: (context, c) {
        final largeurPanneau = c.maxWidth < 480 ? c.maxWidth : 460.0;
        return Stack(children: [
          _contenu(),
          if (_panneau) ...[
            Positioned.fill(
              child: GestureDetector(onTap: _fermerPanneau, child: const ColoredBox(color: Color(0x66000000))),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: largeurPanneau,
              child: _PanneauMembre(
                key: ValueKey('panneau-${_edition?.id ?? 'new'}'),
                membre: _edition,
                domaines: _domaines,
                onFermer: _fermerPanneau,
                onEnregistrer: (d) => _sauver(_edition, d),
              ),
            ),
          ],
        ]);
      }),
    );
  }

  Widget _contenu() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_erreur != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_erreur!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _charger, child: const Text('Réessayer')),
        ]),
      );
    }

    final liste = _filtres;
    final nbPages = liste.isEmpty ? 1 : ((liste.length - 1) ~/ _parPage) + 1;
    if (_page >= nbPages) _page = nbPages - 1;
    final debut = _page * _parPage;
    final fin = (debut + _parPage) > liste.length ? liste.length : debut + _parPage;
    final visibles = liste.isEmpty ? <Membre>[] : liste.sublist(debut, fin);

    return RefreshIndicator(
      onRefresh: () => _charger(silencieux: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 10,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('Membres de l\'administration',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _texteFonce)),
                SizedBox(height: 2),
                Text('Gérez les rôles, domaines et autorisations d\'accès.',
                    style: TextStyle(fontSize: 13, color: _texteGris)),
              ]),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => _ouvrirPanneau(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Nouveau membre', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _kpis(),
          const SizedBox(height: 16),
          _barreFiltres(),
          if (_coches.isNotEmpty) ...[const SizedBox(height: 10), _barreSelection()],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _bordureGris),
            ),
            child: Column(children: [
              if (visibles.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('Aucun membre ne correspond.', style: TextStyle(color: Colors.grey, fontSize: 15)),
                )
              else
                LayoutBuilder(builder: (_, c) => c.maxWidth >= 860 ? _tableau(visibles) : _cartes(visibles)),
              const SizedBox(height: 12),
              _pagination(liste.length, debut, fin, nbPages),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── KPI ───────────────────────────────────────────────────────────────────
  Widget _kpis() {
    final actifs = adminMembres.where((m) => m.actif).length;
    final couleurs = [
      [AdminTheme.warning, AdminTheme.warningLight],
      [AdminTheme.success, AdminTheme.successLight],
      [AdminTheme.info, AdminTheme.infoLight],
      [const Color(0xFF7C3AED), const Color(0xFFF3E8FF)],
    ];
    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
      final w = (c.maxWidth - (cols - 1) * 12) / cols;
      Widget k(IconData ic, Color fg, Color bg, String label, String val) => SizedBox(
            width: w,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _bordureGris),
              ),
              child: Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Icon(ic, color: fg, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, style: const TextStyle(fontSize: 12.5, color: _texteGris), overflow: TextOverflow.ellipsis),
                    Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _texteFonce)),
                  ]),
                ),
              ]),
            ),
          );
      final domaines = _domaines.take(4).toList();
      return Wrap(spacing: 12, runSpacing: 12, children: [
        k(Icons.groups_rounded, AdminTheme.primary, AdminTheme.primaryLight, 'Membres actifs', '$actifs'),
        for (int i = 0; i < domaines.length; i++)
          k(Icons.school_rounded, couleurs[i % couleurs.length][0], couleurs[i % couleurs.length][1], domaines[i],
              '${adminMembres.where((m) => m.domaine == domaines[i]).length}'),
      ]);
    });
  }

  // ── Filtres ───────────────────────────────────────────────────────────────
  Widget _liste_(String label, String value, List<String> vals, List<String> labels, ValueChanged<String?> on) {
    return SizedBox(
      width: 190,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _bordureGris)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _bordureGris)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: vals.contains(value) ? value : vals.first,
            isDense: true,
            isExpanded: true,
            style: const TextStyle(fontSize: 13, color: _texteFonce),
            items: [for (int i = 0; i < vals.length; i++) DropdownMenuItem(value: vals[i], child: Text(labels[i], overflow: TextOverflow.ellipsis))],
            onChanged: on,
          ),
        ),
      ),
    );
  }

  Widget _barreFiltres() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _bordureGris),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            height: 44,
            child: TextField(
              onChanged: (v) => setState(() { _recherche = v; _page = 0; }),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher un membre…',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _bordureGris)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _bordureGris)),
              ),
            ),
          ),
          _liste_('Domaine', _fDomaine, ['tous', ..._domaines], ['Tous les domaines', ..._domaines],
              (v) => setState(() { _fDomaine = v ?? 'tous'; _page = 0; })),
          _liste_('Rôle', _fRole, ['tous', ...AdminRole.values.map((r) => r.code)],
              ['Tous les rôles', ...AdminRole.values.map((r) => r.label)],
              (v) => setState(() { _fRole = v ?? 'tous'; _page = 0; })),
          _liste_('Statut', _fStatut, ['tous', 'actif', 'suspendu'], ['Tous les statuts', 'Actif', 'Suspendu'],
              (v) => setState(() { _fStatut = v ?? 'tous'; _page = 0; })),
        ],
      ),
    );
  }

  Widget _barreSelection() {
    final ms = adminMembres.where((m) => _coches.contains(m.id) && m.adminRole != AdminRole.superAdmin).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
      child: Wrap(spacing: 10, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text('${_coches.length} sélectionné(s)',
            style: const TextStyle(fontWeight: FontWeight.w700, color: _texteFonce, fontSize: 13)),
        TextButton.icon(
          onPressed: ms.isEmpty ? null : () => _changerStatut(ms, true),
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Réactiver'),
        ),
        TextButton.icon(
          onPressed: ms.isEmpty ? null : () => _changerStatut(ms, false),
          icon: const Icon(Icons.pause_circle_outline, size: 18),
          label: const Text('Suspendre'),
        ),
        TextButton(onPressed: () => setState(_coches.clear), child: const Text('Annuler')),
      ]),
    );
  }

  // ── Tableau (écran large) ─────────────────────────────────────────────────
  Widget _tableau(List<Membre> lignes) {
    final toutes = lignes.every((m) => _coches.contains(m.id));
    Widget th(String t, {int flex = 1, double? w}) {
      final child = Text(t, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _texteFonce));
      return w != null ? SizedBox(width: w, child: child) : Expanded(flex: flex, child: child);
    }

    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: toutes,
              onChanged: (v) => setState(() {
                for (final m in lignes) {
                  v == true ? _coches.add(m.id) : _coches.remove(m.id);
                }
              }),
            ),
          ),
          th('Membre', flex: 26),
          th('Contact', flex: 24),
          th('Domaine(s)', flex: 18),
          th('Rôle', flex: 14),
          th('Statut', flex: 10),
          th('Actions', w: 100),
        ]),
      ),
      for (final m in lignes) _ligneTableau(m),
    ]);
  }

  Widget _ligneTableau(Membre m) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(children: [
        SizedBox(
          width: 40,
          child: Checkbox(
            value: _coches.contains(m.id),
            onChanged: (v) => setState(() { v == true ? _coches.add(m.id) : _coches.remove(m.id); }),
          ),
        ),
        Expanded(
          flex: 26,
          child: InkWell(
            onTap: () => _ouvrirPanneau(m),
            child: Row(children: [
              _avatar(m, 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${m.prenoms} ${m.nom}'.toUpperCase(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _texteFonce), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  _chipRole(m),
                ]),
              ),
            ]),
          ),
        ),
        Expanded(flex: 24, child: _contact(m)),
        Expanded(flex: 18, child: Align(alignment: Alignment.centerLeft, child: _badgeDomaine(m.domaine))),
        Expanded(flex: 14, child: Align(alignment: Alignment.centerLeft, child: _badgeRoleCourt(m))),
        Expanded(flex: 10, child: Align(alignment: Alignment.centerLeft, child: _badgeStatut(m.actif))),
        SizedBox(width: 100, child: _actions(m)),
      ]),
    );
  }

  // ── Cartes (écran étroit) ─────────────────────────────────────────────────
  Widget _cartes(List<Membre> lignes) {
    return Column(children: [
      for (final m in lignes)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _bordureGris),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Checkbox(
                value: _coches.contains(m.id),
                onChanged: (v) => setState(() { v == true ? _coches.add(m.id) : _coches.remove(m.id); }),
              ),
              _avatar(m, 42),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _ouvrirPanneau(m),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${m.prenoms} ${m.nom}'.toUpperCase(),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _texteFonce), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    _chipRole(m),
                  ]),
                ),
              ),
              _badgeStatut(m.actif),
            ]),
            const SizedBox(height: 8),
            _contact(m),
            const SizedBox(height: 8),
            Row(children: [
              _badgeDomaine(m.domaine),
              const Spacer(),
              _actions(m),
            ]),
          ]),
        ),
    ]);
  }

  Widget _avatar(Membre m, double t) {
    final sup = m.adminRole == AdminRole.superAdmin;
    final ini = '${m.prenoms.isNotEmpty ? m.prenoms[0] : ''}${m.nom.isNotEmpty ? m.nom[0] : ''}'.toUpperCase();
    return CircleAvatar(
      radius: t / 2,
      backgroundColor: sup ? AdminTheme.primary : const Color(0xFF1E40AF),
      child: Text(ini, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: t * 0.34)),
    );
  }

  Widget _chipRole(Membre m) {
    final sup = m.adminRole == AdminRole.superAdmin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: sup ? const Color(0xFFEEF2FF) : AdminTheme.primaryLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(m.adminRole.label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: sup ? const Color(0xFF4F46E5) : AdminTheme.primary),
          overflow: TextOverflow.ellipsis),
    );
  }

  Widget _contact(Membre m) {
    final tel = m.tel ?? '';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.mail_outline, size: 13, color: _texteGris),
        const SizedBox(width: 5),
        Flexible(child: Text(m.email, style: const TextStyle(fontSize: 12, color: _texteGris), overflow: TextOverflow.ellipsis)),
      ]),
      if (tel.isNotEmpty)
        Row(children: [
          const Icon(Icons.phone, size: 13, color: _texteGris),
          const SizedBox(width: 5),
          Flexible(child: Text(tel, style: const TextStyle(fontSize: 12, color: _texteGris), overflow: TextOverflow.ellipsis)),
        ]),
    ]);
  }

  Widget _badgeDomaine(String d) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.apartment_outlined, size: 13, color: AdminTheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(d == 'Tous' ? 'Tous les domaines' : d,
                style: const TextStyle(fontSize: 11, color: AdminTheme.primary, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );

  Widget _badgeRoleCourt(Membre m) {
    final sup = m.adminRole == AdminRole.superAdmin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: sup ? AdminTheme.warningLight : AdminTheme.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(_roleCourt(m.adminRole),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sup ? AdminTheme.warning : AdminTheme.primary),
          overflow: TextOverflow.ellipsis),
    );
  }

  Widget _badgeStatut(bool actif) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: actif ? AdminTheme.successLight : AdminTheme.warningLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.circle, size: 8, color: actif ? AdminTheme.success : AdminTheme.warning),
          const SizedBox(width: 5),
          Text(actif ? 'Actif' : 'Suspendu',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: actif ? AdminTheme.success : AdminTheme.warning)),
        ]),
      );

  Widget _actions(Membre m) {
    final sup = m.adminRole == AdminRole.superAdmin;
    Widget carre(Widget child) => Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _bordureGris),
          ),
          child: child,
        );
    return Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
      Tooltip(
        message: 'Modifier',
        child: InkWell(
          onTap: () => _ouvrirPanneau(m),
          borderRadius: BorderRadius.circular(8),
          child: carre(const Icon(Icons.edit_outlined, size: 18, color: AdminTheme.primary)),
        ),
      ),
      if (!sup)
        PopupMenuButton<String>(
          tooltip: 'Plus',
          onSelected: (v) {
            if (v == 'statut') _changerStatut([m], !m.actif);
            if (v == 'suppr') _supprimer(m);
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'statut', child: Text(m.actif ? 'Suspendre' : 'Réactiver')),
            const PopupMenuItem(value: 'suppr', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
          ],
          child: carre(const Icon(Icons.more_vert, size: 18, color: _texteFonce)),
        ),
    ]);
  }

  Widget _pagination(int total, int debut, int fin, int nbPages) {
    Widget bouton(String t, int p, {bool actif = false}) => GestureDetector(
          onTap: () => setState(() => _page = p),
          child: Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(left: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: actif ? AdminTheme.primary : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: actif ? AdminTheme.primary : _bordureGris),
            ),
            child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: actif ? Colors.white : const Color(0xFF374151))),
          ),
        );
    int d = _page - 2 < 0 ? 0 : _page - 2;
    int f = d + 4 >= nbPages ? nbPages - 1 : d + 4;
    d = f - 4 < 0 ? 0 : f - 4;
    return Row(children: [
      Expanded(
        child: Text(
          total == 0 ? 'Aucun résultat' : 'Affichage de ${debut + 1} à $fin sur $total membre${total > 1 ? 's' : ''}',
          style: const TextStyle(fontSize: 12, color: _texteGris),
        ),
      ),
      if (_page > 0) bouton('‹', _page - 1),
      for (int p = d; p <= f; p++) bouton('${p + 1}', p, actif: p == _page),
      if (_page < nbPages - 1) bouton('›', _page + 1),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  PANNEAU LATÉRAL « Nouveau membre » / « Modifier le membre »
// ═════════════════════════════════════════════════════════════════════════════
class _PanneauMembre extends StatefulWidget {
  final Membre? membre;
  final List<String> domaines;
  final VoidCallback onFermer;
  final Future<String?> Function(Map<String, dynamic>) onEnregistrer;

  const _PanneauMembre({
    super.key,
    required this.membre,
    required this.domaines,
    required this.onFermer,
    required this.onEnregistrer,
  });

  @override
  State<_PanneauMembre> createState() => _PanneauMembreState();
}

class _PanneauMembreState extends State<_PanneauMembre> {
  final _nomCtrl = TextEditingController();
  final _prenomsCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  late String _domaine;
  late AdminRole _role;
  late Map<String, bool> _droits;
  bool _saving = false;
  String? _erreur;

  bool get _edition => widget.membre != null;

  @override
  void initState() {
    super.initState();
    final m = widget.membre;
    if (m != null) {
      _nomCtrl.text = m.nom;
      _prenomsCtrl.text = m.prenoms;
      _emailCtrl.text = m.email;
      _telCtrl.text = m.tel ?? '';
      _domaine = m.domaine;
      _role = m.adminRole;
      _droits = Map<String, bool>.from(m.droits);
    } else {
      _domaine = 'Tous';
      _role = AdminRole.scolarite;
      _droits = _droitsParDefaut(_role);
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomsCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _soumettre() async {
    final nom = _nomCtrl.text.trim();
    final prenoms = _prenomsCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final tel = _telCtrl.text.trim();
    if (nom.isEmpty || prenoms.isEmpty || tel.isEmpty || !email.contains('@')) {
      setState(() => _erreur = 'Nom, prénom(s), email valide et téléphone sont obligatoires.');
      return;
    }
    setState(() { _saving = true; _erreur = null; });
    final err = await widget.onEnregistrer({
      'nom': nom.toUpperCase(),
      'prenoms': prenoms,
      'email': email,
      'tel': tel,
      'domaine': _domaine,
      'role': _role,
      'droits': _droits,
    });
    if (!mounted) return;
    if (err != null) setState(() { _saving = false; _erreur = err; });
  }

  // ── Widgets de base ───────────────────────────────────────────────────────
  Widget _carte({required IconData icone, required String titre, required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _bordureGris),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icone, size: 18, color: AdminTheme.primary),
            const SizedBox(width: 8),
            Text(titre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _texteFonce)),
          ]),
          const SizedBox(height: 12),
          child,
        ]),
      );

  Widget _champ(String label, TextEditingController c, String hint, {TextInputType? type}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(
            text: label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
            children: const [TextSpan(text: ' *', style: TextStyle(color: Color(0xFFDC2626)))],
          )),
          const SizedBox(height: 6),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: _bordureChamp)),
            child: TextField(
              controller: c,
              keyboardType: type,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );

  Widget _deuxColonnes(Widget a, Widget b) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: a), const SizedBox(width: 10), Expanded(child: b)],
      );

  Widget _puce(String t, bool actif, VoidCallback on) => GestureDetector(
        onTap: on,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: actif ? AdminTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: actif ? AdminTheme.primary : _bordureGris),
          ),
          child: Text(t,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: actif ? Colors.white : const Color(0xFF374151))),
        ),
      );

  Widget _groupeDroits(_Groupe g) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _bordureGris),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(g.icone, size: 16, color: _texteFonce),
            const SizedBox(width: 6),
            Text(g.titre, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _texteFonce)),
          ]),
          for (final k in g.cles)
            SizedBox(
              height: 40,
              child: Row(children: [
                Icon(_iconeSection(k), size: 16, color: _texteGris),
                const SizedBox(width: 8),
                Expanded(child: Text(_sectionsLabels[k] ?? k, style: const TextStyle(fontSize: 13, color: _texteFonce))),
                Switch(
                  value: _droits[k] ?? false,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AdminTheme.primary,
                  onChanged: (v) => setState(() => _droits[k] = v),
                ),
              ]),
            ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      elevation: 12,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
          color: Colors.white,
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AdminTheme.primary, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.badge_outlined, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_edition ? 'Modifier le membre' : 'Nouveau membre',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _texteFonce)),
                const Text('Renseignez les informations du membre et ses autorisations.',
                    style: TextStyle(fontSize: 12, color: _texteGris)),
              ]),
            ),
            IconButton(onPressed: _saving ? null : widget.onFermer, icon: const Icon(Icons.close)),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _carte(
                icone: Icons.person_outline,
                titre: 'Informations du membre',
                child: Column(children: [
                  _deuxColonnes(
                    _champ('Nom', _nomCtrl, 'Ex. KABORE'),
                    _champ('Prénom(s)', _prenomsCtrl, 'Ex. Issa'),
                  ),
                  const SizedBox(height: 12),
                  _deuxColonnes(
                    _champ('Adresse e-mail', _emailCtrl, 'Ex. nom@domaine.com', type: TextInputType.emailAddress),
                    _champ('Téléphone', _telCtrl, 'Ex. 70 12 34 56', type: TextInputType.phone),
                  ),
                  if (!_edition) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Pas de mot de passe à saisir : le membre se connecte avec son nom, son prénom et son téléphone, puis choisit son mot de passe.',
                      style: TextStyle(fontSize: 11.5, color: _texteGris),
                    ),
                  ],
                ]),
              ),
              _carte(
                icone: Icons.shield_outlined,
                titre: 'Domaine d\'attribution académique',
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final d in ['Tous', ...widget.domaines]) _puce(d, _domaine == d, () => setState(() => _domaine = d)),
                ]),
              ),
              _carte(
                icone: Icons.admin_panel_settings_outlined,
                titre: 'Sous-rôle administrateur',
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final r in AdminRole.values)
                    _puce(r.label, _role == r, () => setState(() {
                          _role = r;
                          _droits = _droitsParDefaut(r);
                        })),
                ]),
              ),
              _carte(
                icone: Icons.lock_outline,
                titre: 'Autorisations',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
                    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.info_outline, size: 16, color: AdminTheme.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Le domaine d\'attribution sélectionné limite l\'accès aux données académiques selon les filières et niveaux concernés.',
                          style: TextStyle(fontSize: 11.5, color: AdminTheme.primary),
                        ),
                      ),
                    ]),
                  ),
                  for (final g in _groupesDroits) _groupeDroits(g),
                ]),
              ),
              if (_erreur != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(_erreur!, style: const TextStyle(fontSize: 12.5, color: Color(0xFFB91C1C))),
                ),
            ]),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(children: [
            OutlinedButton(
              onPressed: _saving ? null : widget.onFermer,
              style: OutlinedButton.styleFrom(minimumSize: const Size(110, 46)),
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _soumettre,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_saving ? 'Enregistrement…' : (_edition ? 'Enregistrer' : 'Créer le membre'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
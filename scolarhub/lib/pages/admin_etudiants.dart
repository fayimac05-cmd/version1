import 'package:flutter/material.dart';
import '../pages/admin_data.dart';
import '../theme/app_palette.dart';

class AdminEtudiants extends StatefulWidget {
  const AdminEtudiants({super.key});

  @override
  State<AdminEtudiants> createState() => _AdminEtudiantsState();
}

class _AdminEtudiantsState extends State<AdminEtudiants> {
  final _searchCtrl = TextEditingController();
  String _filtre = 'tous'; // tous / actif / suspendu / renvoyé
  String _recherche = '';

  List<AdminEtudiant> get _etudiantsFiltres {
    return adminEtudiants.where((e) {
      final matchStatut = _filtre == 'tous' || e.statut == _filtre;
      final q = _recherche.toLowerCase();
      final matchRecherche = q.isEmpty ||
          e.nom.toLowerCase().contains(q) ||
          e.prenoms.toLowerCase().contains(q) ||
          e.matricule.toLowerCase().contains(q) ||
          e.filiere.toLowerCase().contains(q);
      return matchStatut && matchRecherche;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Générer prochain matricule ─────────────────────────────────────────
  String _genererMatricule() {
    final annee = DateTime.now().year.toString().substring(2);
    final existants = adminEtudiants
        .where((e) => e.matricule.startsWith('${annee}IST-O2/'))
        .map((e) {
          final parts = e.matricule.split('/');
          return int.tryParse(parts.last) ?? 0;
        })
        .toList();
    existants.sort();
    final prochain = (existants.isEmpty ? 1000 : existants.last + 1);
    return '${annee}IST-O2/$prochain';
  }

  @override
  Widget build(BuildContext context) {
    final liste = _etudiantsFiltres;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Étudiants',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _dialogAjouterEtudiant(context),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Ajouter', style: TextStyle(fontSize: 13)),
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
      ),
      body: Column(children: [
        // ── Barre de recherche ────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _recherche = v),
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Rechercher par nom, matricule, filière...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        // ── Filtres statut ────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filtreChip('tous', 'Tous (${adminEtudiants.length})'),
              const SizedBox(width: 8),
              _filtreChip('actif', '✅ Actifs'),
              const SizedBox(width: 8),
              _filtreChip('suspendu', '⚠️ Suspendus'),
              const SizedBox(width: 8),
              _filtreChip('renvoyé', '🚫 Renvoyés'),
            ]),
          ),
        ),

        Container(height: 1, color: const Color(0xFFE2E8F0)),

        // ── Liste ─────────────────────────────────────────────────────────
        Expanded(
          child: liste.isEmpty
              ? const Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.search_off, size: 48, color: Color(0xFFCBD5E1)),
                    SizedBox(height: 12),
                    Text('Aucun étudiant trouvé',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15)),
                  ]),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: liste.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _carteEtudiant(liste[i]),
                ),
        ),
      ]),
    );
  }

  Widget _filtreChip(String val, String label) {
    final active = _filtre == val;
    return GestureDetector(
      onTap: () => setState(() => _filtre = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppPalette.blue : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: active ? Colors.white : const Color(0xFF64748B),
        )),
      ),
    );
  }

  Widget _carteEtudiant(AdminEtudiant e) {
    Color statutColor; String statutLabel; Color statutBg;
    switch (e.statut) {
      case 'suspendu':
        statutColor = const Color(0xFFD97706); statutLabel = 'Suspendu';
        statutBg = const Color(0xFFFEF3C7); break;
      case 'renvoyé':
        statutColor = const Color(0xFFDC2626); statutLabel = 'Renvoyé';
        statutBg = const Color(0xFFFEE2E2); break;
      default:
        statutColor = const Color(0xFF15803D); statutLabel = 'Actif';
        statutBg = const Color(0xFFF0FDF4);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        leading: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: AppPalette.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(
            '${e.prenoms[0]}${e.nom[0]}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                color: AppPalette.blue),
          )),
        ),
        title: Text('${e.prenoms} ${e.nom}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(e.matricule,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B),
                    fontFamily: 'monospace')),
            const SizedBox(height: 2),
            Text(e.filiere,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statutBg, borderRadius: BorderRadius.circular(10)),
              child: Text(statutLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                      color: statutColor)),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _dialogActions(e),
              child: const Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialog actions sur un étudiant ────────────────────────────────────
  void _dialogActions(AdminEtudiant e) {
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
          Text('${e.prenoms} ${e.nom}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(e.matricule,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          const Divider(height: 1),
          _actionTile(Icons.info_outline, 'Voir le profil', AppPalette.blue, () {
            Navigator.pop(context);
            _dialogProfil(e);
          }),
          if (e.statut == 'actif')
            _actionTile(Icons.person_off_outlined, 'Suspendre', const Color(0xFFD97706), () {
              Navigator.pop(context);
              _changerStatut(e, 'suspendu');
            }),
          if (e.statut == 'suspendu')
            _actionTile(Icons.person_outline, 'Réactiver', const Color(0xFF15803D), () {
              Navigator.pop(context);
              _changerStatut(e, 'actif');
            }),
          if (e.statut != 'renvoyé')
            _actionTile(Icons.block_outlined, 'Renvoyer', const Color(0xFFDC2626), () {
              Navigator.pop(context);
              _confirmerRenvoi(e);
            }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  void _changerStatut(AdminEtudiant e, String nouveauStatut) {
    setState(() => e.statut = nouveauStatut);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${e.prenoms} ${e.nom} → $nouveauStatut'),
      backgroundColor: const Color(0xFF15803D),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _confirmerRenvoi(AdminEtudiant e) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
          SizedBox(width: 10),
          Text('Confirmer le renvoi', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          'Voulez-vous renvoyer ${e.prenoms} ${e.nom} (${e.matricule}) ?\n\nCette action retirera l\'étudiant de son groupe filière. Son matricule ne sera jamais réutilisé.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _changerStatut(e, 'renvoyé');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Confirmer le renvoi'),
          ),
        ],
      ),
    );
  }

  void _dialogProfil(AdminEtudiant e) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppPalette.blue.withOpacity(0.1), shape: BoxShape.circle),
            child: Center(child: Text('${e.prenoms[0]}${e.nom[0]}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    color: AppPalette.blue))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${e.prenoms} ${e.nom}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(e.matricule, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ])),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoLigne(Icons.school_outlined, 'Filière', e.filiere),
            _infoLigne(Icons.layers_outlined, 'Niveau', e.niveau),
            _infoLigne(Icons.category_outlined, 'Domaine', e.domaine),
            _infoLigne(Icons.email_outlined, 'Email', e.email),
            _infoLigne(Icons.phone_outlined, 'Téléphone', e.telephone),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _infoLigne(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A))),
        ]),
      ]),
    );
  }

  // ── Dialog ajouter un étudiant ────────────────────────────────────────
  void _dialogAjouterEtudiant(BuildContext context) {
    final nomCtrl     = TextEditingController();
    final prenomCtrl  = TextEditingController();
    final emailCtrl   = TextEditingController();
    final telCtrl     = TextEditingController();
    String? filiereSelectee;
    final newMatricule = _genererMatricule();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.person_add_rounded, color: AppPalette.blue),
            SizedBox(width: 10),
            Text('Nouvel étudiant', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Matricule auto-généré
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppPalette.blue.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.badge_outlined, color: AppPalette.blue, size: 18),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Matricule généré automatiquement',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    Text(newMatricule, style: const TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold, color: AppPalette.blue,
                        fontFamily: 'monospace')),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
              _champForm(nomCtrl, 'Nom de famille', Icons.person_outline),
              const SizedBox(height: 12),
              _champForm(prenomCtrl, 'Prénoms', Icons.person_outline),
              const SizedBox(height: 12),
              _champForm(emailCtrl, 'Adresse email', Icons.email_outlined,
                  type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _champForm(telCtrl, 'Téléphone', Icons.phone_outlined,
                  type: TextInputType.phone),
              const SizedBox(height: 12),
              // Sélecteur filière
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: filiereSelectee,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Choisir une filière',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    borderRadius: BorderRadius.circular(12),
                    items: adminFilieres.map((f) => DropdownMenuItem(
                      value: f.id,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(f.nom, style: const TextStyle(fontSize: 14)),
                      ),
                    )).toList(),
                    onChanged: (v) => setS(() => filiereSelectee = v),
                  ),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                if (nomCtrl.text.isEmpty || prenomCtrl.text.isEmpty || filiereSelectee == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Remplissez nom, prénom et filière.'),
                    backgroundColor: Color(0xFFDC2626),
                  ));
                  return;
                }
                final filiere = adminFilieres.firstWhere((f) => f.id == filiereSelectee);
                setState(() {
                  adminEtudiants.add(AdminEtudiant(
                    matricule: newMatricule,
                    nom: nomCtrl.text.toUpperCase(),
                    prenoms: prenomCtrl.text,
                    email: emailCtrl.text,
                    telephone: telCtrl.text,
                    filiereId: filiere.id,
                    filiere: filiere.nom,
                    domaine: filiere.domaine,
                    niveau: filiere.niveau,
                  ));
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${prenomCtrl.text} ajouté · $newMatricule'),
                  backgroundColor: const Color(0xFF15803D),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _champForm(TextEditingController ctrl, String hint, IconData icon,
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
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_filieres.dart';

class Professeur {
  final String id, nom, prenoms, email, telephone, specialite, typeContrat, dateArrivee;
  bool actif;
  double noteEvaluation;
  Professeur({required this.id, required this.nom, required this.prenoms,
      required this.email, required this.telephone, required this.specialite,
      required this.typeContrat, required this.dateArrivee,
      this.actif = true, this.noteEvaluation = 0.0});
}

final List<Professeur> adminProfesseurs = [
  Professeur(id: 'P001', nom: 'OUÉDRAOGO', prenoms: 'Mamadou',
      email: 'mamadou.ouedraogo@ist.bf', telephone: '70123456',
      specialite: 'Réseaux & Systèmes', typeContrat: 'Permanent',
      dateArrivee: '01/09/2020', noteEvaluation: 4.2),
  Professeur(id: 'P002', nom: 'SAWADOGO', prenoms: 'Issa',
      email: 'issa.sawadogo@ist.bf', telephone: '76234567',
      specialite: 'Développement Web', typeContrat: 'Permanent',
      dateArrivee: '01/09/2021', noteEvaluation: 4.5),
  Professeur(id: 'P003', nom: 'COMPAORÉ', prenoms: 'Brahima',
      email: 'brahima.compaore@ist.bf', telephone: '65345678',
      specialite: 'Électrotechnique', typeContrat: 'Vacataire',
      dateArrivee: '15/01/2022', noteEvaluation: 3.8),
  Professeur(id: 'P004', nom: 'TRAORÉ', prenoms: 'Alassane',
      email: 'alassane.traore@ist.bf', telephone: '70456789',
      specialite: 'Cybersécurité', typeContrat: 'Permanent',
      dateArrivee: '01/09/2019', noteEvaluation: 4.7),
  Professeur(id: 'P005', nom: 'OUÉDRAOGO', prenoms: 'Aïcha',
      email: 'aicha.ouedraogo@ist.bf', telephone: '76567890',
      specialite: 'Marketing Digital', typeContrat: 'Vacataire',
      dateArrivee: '01/02/2023', noteEvaluation: 4.0),
];

class AdminProfesseurs extends StatefulWidget {
  const AdminProfesseurs({super.key});
  @override State<AdminProfesseurs> createState() => _AdminProfesseursState();
}

class _AdminProfesseursState extends State<AdminProfesseurs> {
  String _query  = '';
  String _filtre = 'tous';
  final _searchCtrl = TextEditingController();

  List<Professeur> get _filtered => adminProfesseurs.where((p) {
    final q = _query.toLowerCase();
    final matchQ = q.isEmpty || p.nom.toLowerCase().contains(q) ||
        p.prenoms.toLowerCase().contains(q) ||
        p.specialite.toLowerCase().contains(q);
    final matchF = _filtre == 'tous' ||
        (_filtre == 'permanent' && p.typeContrat == 'Permanent') ||
        (_filtre == 'vacataire' && p.typeContrat == 'Vacataire');
    return matchQ && matchF;
  }).toList();

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
                const Text('Professeurs', style: TextStyle(fontSize: 22,
                    fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                Text('${adminProfesseurs.length} professeurs enregistrés',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              ])),
              GestureDetector(
                onTap: () => _ajouterProfesseur(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AdminTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(
                        color: AdminTheme.primary.withOpacity(0.3),
                        blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text('Ajouter', style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un professeur...',
                    hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Color(0xFF9CA3AF), size: 16),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10)),
                ),
              )),
              const SizedBox(width: 10),
              _chip('Tous', 'tous'),
              const SizedBox(width: 6),
              _chip('Permanents', 'permanent'),
              const SizedBox(width: 6),
              _chip('Vacataires', 'vacataire'),
            ]),
          ]),
        ),
        Container(height: 1, color: const Color(0xFFE5E7EB)),
        Expanded(child: _filtered.isEmpty
            ? _vide()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _carteProf(_filtered[i]),
              )),
      ]),
    );
  }

  Widget _chip(String label, String value) {
    final active = _filtre == value;
    return GestureDetector(
      onTap: () => setState(() => _filtre = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AdminTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? AdminTheme.primary : const Color(0xFFE5E7EB)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF6B7280))),
      ),
    );
  }

  Widget _carteProf(Professeur p) {
    final modules = adminFilieres.expand((f) => f.modules)
        .where((m) => m.professeur.contains(p.nom)).toList();
    return GestureDetector(
      onTap: () => _ouvrirFiche(p),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(width: 52, height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text('${p.prenoms[0]}${p.nom[0]}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: Color(0xFF7C3AED))))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('${p.prenoms} ${p.nom}',
                  style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)))),
              _contratBadge(p.typeContrat),
            ]),
            const SizedBox(height: 4),
            Text(p.specialite,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.phone_rounded, size: 12, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text(p.telephone,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              const SizedBox(width: 12),
              const Icon(Icons.book_rounded, size: 12, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text('${modules.length} module(s)',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ]),
            if (p.noteEvaluation > 0) ...[
              const SizedBox(height: 6),
              Row(children: [
                ...List.generate(5, (i) => Icon(
                    i < p.noteEvaluation.floor()
                        ? Icons.star_rounded : Icons.star_border_rounded,
                    color: AdminTheme.accent, size: 14)),
                const SizedBox(width: 4),
                Text(p.noteEvaluation.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w700, color: AdminTheme.accent)),
              ]),
            ],
          ])),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
        ]),
      ),
    );
  }

  Widget _contratBadge(String type) {
    final isPerm = type == 'Permanent';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPerm ? AdminTheme.primaryLight : AdminTheme.warningLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(type, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: isPerm ? AdminTheme.primary : AdminTheme.warning)),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // FORMULAIRE AJOUT PROFESSEUR
  // ════════════════════════════════════════════════════════════════════════
  void _ajouterProfesseur() {
    final nomCtrl       = TextEditingController();
    final prenomCtrl    = TextEditingController();
    final emailCtrl     = TextEditingController();
    final telCtrl       = TextEditingController();
    final specCtrl      = TextEditingController();
    final dateCtrl      = TextEditingController();
    String contrat      = 'Permanent';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(children: [
                const Expanded(child: Text('Ajouter un professeur',
                    style: TextStyle(fontSize: 17,
                        fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)))),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ]),
            ),
            const Divider(color: Color(0xFFE5E7EB)),
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Identité
                _sectionHeader('Informations personnelles'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _fieldCol('Nom *', nomCtrl, 'Ex: OUÉDRAOGO')),
                  const SizedBox(width: 12),
                  Expanded(child: _fieldCol('Prénom *', prenomCtrl, 'Ex: Mamadou')),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _fieldCol('Email *', emailCtrl, 'email@ist.bf',
                      type: TextInputType.emailAddress)),
                  const SizedBox(width: 12),
                  Expanded(child: _fieldCol('Téléphone *', telCtrl, '70000000',
                      type: TextInputType.phone)),
                ]),
                const SizedBox(height: 16),

                // Académique
                _sectionHeader('Informations académiques'),
                const SizedBox(height: 12),
                _label('Spécialité *'),
                _inputField(specCtrl, 'Ex: Réseaux & Systèmes, Développement Web...'),
                const SizedBox(height: 10),
                _label('Date d\'arrivée'),
                _inputField(dateCtrl, 'Ex: 01/09/2024'),
                const SizedBox(height: 12),
                _label('Type de contrat'),
                Row(children: ['Permanent', 'Vacataire', 'Invité'].map((c) {
                  final active = contrat == c;
                  return GestureDetector(
                    onTap: () => setS(() => contrat = c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AdminTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: active
                            ? AdminTheme.primary : const Color(0xFFE5E7EB)),
                      ),
                      child: Text(c, style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : const Color(0xFF6B7280))),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminTheme.infoLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline_rounded, color: AdminTheme.info, size: 16),
                    SizedBox(width: 8),
                    Expanded(child: Text(
                      'Un email avec les identifiants de connexion sera envoyé automatiquement.',
                      style: TextStyle(fontSize: 12, color: AdminTheme.info,
                          fontWeight: FontWeight.w600))),
                  ]),
                ),
              ]),
            )),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  if (nomCtrl.text.isEmpty || prenomCtrl.text.isEmpty ||
                      emailCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Nom, prénom et email requis.'),
                      backgroundColor: AdminTheme.danger,
                      behavior: SnackBarBehavior.floating));
                    return;
                  }
                  setState(() => adminProfesseurs.add(Professeur(
                    id: 'P${adminProfesseurs.length + 1}',
                    nom: nomCtrl.text.toUpperCase(),
                    prenoms: prenomCtrl.text,
                    email: emailCtrl.text,
                    telephone: telCtrl.text,
                    specialite: specCtrl.text.isEmpty
                        ? 'Non définie' : specCtrl.text,
                    typeContrat: contrat,
                    dateArrivee: dateCtrl.text.isEmpty
                        ? '01/05/2025' : dateCtrl.text,
                  )));
                  Navigator.pop(ctx);
                  _snack('✅ ${prenomCtrl.text} ${nomCtrl.text} ajouté(e) ! '
                      'Identifiants envoyés par email.');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AdminTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(
                        color: AdminTheme.primary.withOpacity(0.3),
                        blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Center(child: Text('✅ Enregistrer le professeur',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: Colors.white))),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // FICHE PROFESSEUR
  // ════════════════════════════════════════════════════════════════════════
  void _ouvrirFiche(Professeur p) {
    final modules = adminFilieres.expand((f) => f.modules)
        .where((m) => m.professeur.contains(p.nom)).toList();
    final filieres = adminFilieres
        .where((f) => f.modules.any((m) => m.professeur.contains(p.nom)))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2))),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(width: 56, height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text('${p.prenoms[0]}${p.nom[0]}',
                    style: const TextStyle(fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED))))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${p.prenoms} ${p.nom}', style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E))),
                  Text(p.specialite, style: const TextStyle(
                      fontSize: 13, color: Color(0xFF6B7280))),
                  Text('${p.typeContrat} · Depuis ${p.dateArrivee}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF))),
                ])),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _section('Coordonnées', [
                _infoRow(Icons.email_rounded, p.email),
                _infoRow(Icons.phone_rounded, p.telephone),
              ]),
              const SizedBox(height: 12),
              _section('Charge académique', [
                if (modules.isEmpty)
                  const Text('Aucun module assigné.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)))
                else
                  ...modules.map((m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Container(width: 6, height: 6,
                          decoration: BoxDecoration(
                              color: AdminTheme.primary,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(m.nom, style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E)))),
                      Text('Coef ${m.coefficient}', style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                    ]),
                  )),
              ]),
              if (filieres.isNotEmpty) ...[
                const SizedBox(height: 12),
                _section('Filières enseignées', [
                  ...filieres.map((f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      const Icon(Icons.school_rounded, size: 14,
                          color: Color(0xFF6B7280)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${f.nom} — ${f.niveau}',
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF1A1A2E)))),
                    ]),
                  )),
                ]),
              ],
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _section(String titre, List<Widget> children) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titre, style: const TextStyle(fontSize: 13,
          fontWeight: FontWeight.w700, color: Color(0xFF374151))),
      const SizedBox(height: 8),
      ...children,
    ]),
  );

  Widget _infoRow(IconData icon, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
      const SizedBox(width: 8),
      Expanded(child: Text(val, style: const TextStyle(
          fontSize: 13, color: Color(0xFF4B5563)))),
    ]),
  );

  Widget _sectionHeader(String titre) => Container(
    padding: const EdgeInsets.only(bottom: 6),
    decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
    child: Text(titre, style: const TextStyle(fontSize: 14,
        fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))));

  Widget _fieldCol(String label, TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        _inputField(ctrl, hint, type: type),
      ]);

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(t, style: const TextStyle(fontSize: 12,
        fontWeight: FontWeight.w700, color: Color(0xFF374151))));

  Widget _inputField(TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text}) =>
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: type,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10)),
        ),
      );

  Widget _vide() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 72, height: 72,
      decoration: BoxDecoration(color: const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(18)),
      child: const Icon(Icons.person_pin_outlined,
          color: Color(0xFF7C3AED), size: 36)),
    const SizedBox(height: 16),
    const Text('Aucun professeur trouvé', style: TextStyle(fontSize: 17,
        fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
  ]));

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: AdminTheme.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
}

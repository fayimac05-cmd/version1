import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_widgets.dart';
import '../models/etudiant_model.dart';
import '../services/parents_service.dart';

class Parent {
  final String id, nom, prenoms, email, telephone, relation, matriculeEnfant;
  bool credentialsEnvoyes;
  Parent({required this.id, required this.nom, required this.prenoms,
      required this.email, required this.telephone, required this.relation,
      required this.matriculeEnfant, this.credentialsEnvoyes = false});
}

final List<Parent> adminParents = [];

class AdminParents extends StatefulWidget {
  const AdminParents({super.key});
  @override State<AdminParents> createState() => _AdminParentsState();
}

class _AdminParentsState extends State<AdminParents> {
  String _query = '';
  final _searchCtrl = TextEditingController();
  List<Parent> _parents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _chargerParents();
  }

  Future<void> _chargerParents() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ParentsService.getAllParents();
      if (!mounted) return;
      setState(() { _parents = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Impossible de charger les parents.'; _loading = false; });
    }
  }

  List<Parent> get _filtered => _parents.where((p) {
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
          subtitle: '${_parents.length} parents enregistrés',
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
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFD1D5DB)),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _chargerParents,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Réessayer'),
        ),
      ]));
    }
    if (_filtered.isEmpty) return _vide();
    return RefreshIndicator(
      onRefresh: _chargerParents,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _carteParent(_filtered[i]),
      ),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: AdminTheme.warningLight, shape: BoxShape.circle),
              child: Center(
                  child: Text(
                      '${p.prenoms.isNotEmpty ? p.prenoms[0] : "?"}${p.nom.isNotEmpty ? p.nom[0] : "?"}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.warning)))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p.prenoms} ${p.nom}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            Text('${p.relation} · ${p.telephone}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            if (p.email.isNotEmpty) Text(p.email, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
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
        if (p.matriculeEnfant.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.school_rounded, color: AdminTheme.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  enfant != null
                    ? 'Enfant : ${enfant.prenoms} ${enfant.nom}'
                    : 'Enfant : ${p.matriculeEnfant}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AdminTheme.primary)),
                Text(
                  enfant != null
                    ? '${p.matriculeEnfant} · ${enfant.filiere} · ${enfant.niveau}'
                    : p.matriculeEnfant,
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
              _snack('✅ Identifiants envoyés à ${p.email.isNotEmpty ? p.email : p.telephone}');
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
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color))),
        ),
      );

  void _ajouterParent() {
    final nomCtrl = TextEditingController();
    final prenomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final matCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FormulaireParent(
        nomCtrl: nomCtrl,
        prenomCtrl: prenomCtrl,
        emailCtrl: emailCtrl,
        telCtrl: telCtrl,
        matCtrl: matCtrl,
        onSave: (relation) async {
          final result = await ParentsService.createParent(
            nom: nomCtrl.text.trim(),
            prenoms: prenomCtrl.text.trim(),
            email: emailCtrl.text.trim(),
            telephone: telCtrl.text.trim(),
            relation: relation,
            matriculeEnfant: matCtrl.text.trim().toUpperCase(),
          );
          if (result['success'] == true) {
            if (ctx.mounted) Navigator.pop(ctx);
            await Future.delayed(const Duration(milliseconds: 200));
            if (mounted) _snack('✅ Parent ajouté avec succès !');
            if (mounted) _chargerParents();
            return true;
          } else {
            if (mounted) _snack('❌ ${result['error'] ?? 'Erreur lors de la création'}', isError: true);
            return false;
          }
        },
      ),
    ).then((_) {
      nomCtrl.dispose();
      prenomCtrl.dispose();
      emailCtrl.dispose();
      telCtrl.dispose();
      matCtrl.dispose();
    });
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AdminTheme.danger : AdminTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }
}

// ── Formulaire parent ────────────────────────────────────────────────────────

class _FormulaireParent extends StatefulWidget {
  final TextEditingController nomCtrl, prenomCtrl, emailCtrl, telCtrl, matCtrl;
  final Future<bool> Function(String relation) onSave;

  const _FormulaireParent({
    required this.nomCtrl,
    required this.prenomCtrl,
    required this.emailCtrl,
    required this.telCtrl,
    required this.matCtrl,
    required this.onSave,
  });

  @override
  State<_FormulaireParent> createState() => _FormulaireParentState();
}

class _FormulaireParentState extends State<_FormulaireParent> {
  String _relation = 'Père';
  bool _saving = false;

  Future<void> _submit() async {
    final nom = widget.nomCtrl.text.trim();
    final prenom = widget.prenomCtrl.text.trim();
    final tel = widget.telCtrl.text.trim();
    final mat = widget.matCtrl.text.trim().toUpperCase();

    if (nom.isEmpty || prenom.isEmpty) {
      _showError('Nom et Prénom sont obligatoires');
      return;
    }
    if (tel.isEmpty) {
      _showError('Le numéro de téléphone est obligatoire');
      return;
    }
    if (mat.isEmpty) {
      _showError('Le matricule de l\'enfant est obligatoire');
      return;
    }

    setState(() => _saving = true);
    await widget.onSave(_relation);
    if (mounted) setState(() => _saving = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AdminTheme.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
            IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Nom *'), _input(widget.nomCtrl, 'Nom de famille (ex: LANKOANDE)'),
              const SizedBox(height: 12),
              _label('Prénom *'), _input(widget.prenomCtrl, 'Prénom (ex: Pascal)'),
              const SizedBox(height: 12),
              _label('Email (optionnel)'), _input(widget.emailCtrl, 'adresse@email.com', type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _label('Numéro de téléphone *'), _input(widget.telCtrl, 'Ex: 77181229', type: TextInputType.phone),
              const SizedBox(height: 12),
              _label('Relation'),
              Row(
                  children: ['Père', 'Mère', 'Tuteur'].map((r) {
                final active = _relation == r;
                return GestureDetector(
                  onTap: () => setState(() => _relation = r),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AdminTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: active ? AdminTheme.primary : const Color(0xFFE5E7EB)),
                    ),
                    child: Text(r, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: active ? Colors.white : const Color(0xFF6B7280))),
                  ),
                );
              }).toList()),
              const SizedBox(height: 12),
              _label('Matricule de l\'enfant *'), _input(widget.matCtrl, 'Ex: 24IST-O2/1851'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF0284C7)),
                    SizedBox(width: 10),
                    Expanded(child: Text(
                      'Le mot de passe sera créé directement par le parent lors de sa première connexion (via son Nom, Prénom et Numéro de téléphone).',
                      style: TextStyle(fontSize: 12, color: Color(0xFF0369A1), height: 1.3),
                    )),
                  ],
                ),
              ),
            ]),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 8),
          child: GestureDetector(
            onTap: _saving ? null : _submit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _saving ? AdminTheme.primary.withValues(alpha: 0.5) : AdminTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Enregistrer', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      );

  Widget _input(TextEditingController ctrl, String hint, {TextInputType type = TextInputType.text}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 4),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      );
}

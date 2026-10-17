import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_widgets.dart';
import '../services/parents_service.dart';

class AdminParents extends StatefulWidget {
  const AdminParents({super.key});
  @override
  State<AdminParents> createState() => _AdminParentsState();
}

class _AdminParentsState extends State<AdminParents> {
  String _query = '';
  final _searchCtrl = TextEditingController();
  List<Parent> _parents = [];
  List<EnfantSansTuteurLie> _sansTuteurLie = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resultat = await ParentsService.getAllParents();
      if (!mounted) return;
      setState(() {
        _parents = resultat.parents;
        _sansTuteurLie = resultat.enfantsSansTuteurLie;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les parents.';
        _loading = false;
      });
    }
  }

  List<Parent> get _filtered => _parents.where((p) {
        final q = _query.toLowerCase();
        if (q.isEmpty) return true;
        if (p.nom.toLowerCase().contains(q) || p.prenoms.toLowerCase().contains(q)) return true;
        return p.enfants.any((e) => e.matricule.toLowerCase().contains(q) || e.nom.toLowerCase().contains(q));
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
          subtitle: '${_parents.length} tuteur(s) lié(s) · ${_sansTuteurLie.length} en attente de rattachement',
          trailing: AdminAddButton(label: 'Lier un tuteur', onTap: () => _ouvrirFormulaire()),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AdminSearchBar(
            controller: _searchCtrl,
            hintText: 'Rechercher un parent ou un enfant...',
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
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _charger,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ]),
      );
    }
    if (_filtered.isEmpty && _sansTuteurLie.isEmpty) return _vide();

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_sansTuteurLie.isNotEmpty) ...[
            _sectionTitre('En attente de rattachement', AdminTheme.warning),
            const SizedBox(height: 8),
            ..._sansTuteurLie.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _carteSansLien(e),
                )),
            const SizedBox(height: 20),
          ],
          if (_filtered.isNotEmpty) ...[
            _sectionTitre('Tuteurs liés', AdminTheme.primary),
            const SizedBox(height: 8),
            ..._filtered.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _carteParent(p),
                )),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitre(String texte, Color color) => Row(children: [
        Container(width: 4, height: 16, color: color),
        const SizedBox(width: 8),
        Text(texte, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF374151))),
      ]);

  // ── Carte : étudiant en attente de rattachement ─────────────────────────
  Widget _carteSansLien(EnfantSansTuteurLie e) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AdminTheme.warningLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AdminTheme.warning.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.hourglass_top_rounded, color: AdminTheme.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${e.prenoms} ${e.nom}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              Text('${e.matricule} · Tuteur renseigné : ${e.nomParent} (${e.telParent})',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ]),
          ),
          TextButton(
            onPressed: () => _ouvrirFormulaire(prefill: e),
            child: const Text('Lier maintenant', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
      );

  // ── Carte : parent déjà lié ──────────────────────────────────────────────
  Widget _carteParent(Parent p) => Container(
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.warning),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${p.prenoms} ${p.nom}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                Text(p.tel, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                if (p.email.isNotEmpty) Text(p.email, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: p.compteActif ? AdminTheme.successLight : AdminTheme.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                p.compteActif ? '✅ Compte activé' : '⏳ En attente de connexion',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: p.compteActif ? AdminTheme.success : AdminTheme.warning,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ...p.enfants.map((enfant) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.school_rounded, color: AdminTheme.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${enfant.prenoms} ${enfant.nom}  ·  ${enfant.relation}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AdminTheme.primary)),
                        Text('${enfant.matricule} · ${enfant.filiere} · ${enfant.niveau}',
                            style: const TextStyle(fontSize: 11, color: AdminTheme.primaryMid)),
                      ]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.link_off_rounded, size: 18, color: AdminTheme.danger),
                      tooltip: 'Retirer ce lien',
                      onPressed: () => _confirmerRetraitLien(enfant),
                    ),
                  ]),
                ),
              )),
        ]),
      );

  void _confirmerRetraitLien(EnfantLie enfant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Retirer ce lien ?'),
        content: Text('${enfant.prenoms} ${enfant.nom} ne sera plus rattaché à ce tuteur. Le compte parent lui-même n\'est pas supprimé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.danger, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await ParentsService.supprimerLien(enfant.etudiantId);
              if (result['success'] == true) {
                _snack('Lien retiré.');
                _charger();
              } else {
                _snack(result['error'] ?? 'Erreur lors du retrait.', isError: true);
              }
            },
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }

  Widget _vide() => const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.people_outline_rounded, size: 56, color: Color(0xFFD1D5DB)),
          SizedBox(height: 12),
          Text('Aucun parent trouvé', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          SizedBox(height: 4),
          Text('Modifiez votre recherche ou liez un tuteur.', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
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

  // ── Formulaire de rattachement (création ou lien d'un tuteur) ───────────
  void _ouvrirFormulaire({EnfantSansTuteurLie? prefill}) {
    final nomCtrl = TextEditingController(text: prefill?.nomParent.split(' ').first ?? '');
    final prenomCtrl = TextEditingController(text: prefill != null && prefill.nomParent.split(' ').length > 1
        ? prefill.nomParent.split(' ').sublist(1).join(' ')
        : '');
    final emailCtrl = TextEditingController(text: prefill?.emailParent ?? '');
    final telCtrl = TextEditingController(text: prefill?.telParent ?? '');
    final matCtrl = TextEditingController(text: prefill?.matricule ?? '');

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
        matriculeVerrouille: prefill != null,
        onSave: (relation, {bool remplacerExistant = false}) async {
          final result = await ParentsService.createParent(
            nom: nomCtrl.text.trim(),
            prenoms: prenomCtrl.text.trim(),
            email: emailCtrl.text.trim(),
            telephone: telCtrl.text.trim(),
            relation: relation,
            matriculeEnfant: matCtrl.text.trim().toUpperCase(),
            remplacerExistant: remplacerExistant,
          );
          if (result['success'] == true) {
            if (ctx.mounted) Navigator.pop(ctx);
            await Future.delayed(const Duration(milliseconds: 200));
            if (mounted) _snack('Tuteur lié avec succès.');
            if (mounted) _charger();
            return {'success': true};
          }
          return {'success': false, 'conflict': result['conflict'] == true, 'error': result['error']};
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
}

// ── Formulaire tuteur ──────────────────────────────────────────────────────

class _FormulaireParent extends StatefulWidget {
  final TextEditingController nomCtrl, prenomCtrl, emailCtrl, telCtrl, matCtrl;
  final bool matriculeVerrouille;
  final Future<Map<String, dynamic>> Function(String relation, {bool remplacerExistant}) onSave;

  const _FormulaireParent({
    required this.nomCtrl,
    required this.prenomCtrl,
    required this.emailCtrl,
    required this.telCtrl,
    required this.matCtrl,
    required this.onSave,
    this.matriculeVerrouille = false,
  });

  @override
  State<_FormulaireParent> createState() => _FormulaireParentState();
}

class _FormulaireParentState extends State<_FormulaireParent> {
  String _relation = 'Tuteur';
  bool _saving = false;

  Future<void> _submit({bool remplacerExistant = false}) async {
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
    final result = await widget.onSave(_relation, remplacerExistant: remplacerExistant);
    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] != true) {
      if (result['conflict'] == true && !remplacerExistant) {
        _confirmerRemplacement(result['error'] ?? 'Cet enfant a déjà un tuteur principal.');
      } else {
        _showError(result['error'] ?? 'Erreur lors de l\'enregistrement.');
      }
    }
  }

  void _confirmerRemplacement(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tuteur déjà assigné'),
        content: Text('$message\n\nVoulez-vous le remplacer par ce nouveau tuteur ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.danger, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _submit(remplacerExistant: true);
            },
            child: const Text('Remplacer'),
          ),
        ],
      ),
    );
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
            const Expanded(child: Text('Lier un tuteur', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
            IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Nom *'),
              _input(widget.nomCtrl, 'Nom de famille (ex: LANKOANDE)'),
              const SizedBox(height: 12),
              _label('Prénom *'),
              _input(widget.prenomCtrl, 'Prénom (ex: Pascal)'),
              const SizedBox(height: 12),
              _label('Email (optionnel)'),
              _input(widget.emailCtrl, 'adresse@email.com', type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _label('Numéro de téléphone *'),
              _input(widget.telCtrl, 'Ex: 77181229', type: TextInputType.phone),
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
                      child: Text(r,
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : const Color(0xFF6B7280))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              _label('Matricule de l\'enfant *'),
              _input(widget.matCtrl, 'Ex: 24IST-O2/1851', enabled: !widget.matriculeVerrouille),
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
                    Expanded(
                      child: Text(
                        'Le mot de passe est créé par le tuteur lui-même lors de sa première connexion (Nom, Prénom et Numéro de téléphone) — l\'administration n\'en définit aucun.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF0369A1), height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 8),
          child: GestureDetector(
            onTap: _saving ? null : () => _submit(),
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

  Widget _input(TextEditingController ctrl, String hint, {TextInputType type = TextInputType.text, bool enabled = true}) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: type,
          enabled: enabled,
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
import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import 'splash_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key, required this.profile, required this.onLogout});

  final StudentProfile profile;
  final VoidCallback onLogout;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {

  // ── Données modifiables ───────────────────────────────────────────────
  String _email        = '';
  String _telephone    = '';
  String _ville        = 'Ouagadougou, Burkina Faso';
  String _dateNaiss    = '';
  String _interets     = '';
  String _bio          = '';
  String _facebook     = '';
  String _whatsapp     = '';
  String _linkedin     = '';

  // ── Confidentialité ───────────────────────────────────────────────────
  bool _emailVisible   = true;
  bool _telVisible     = true;

  @override
  void initState() {
    super.initState();
    _email     = widget.profile.email.isNotEmpty
        ? widget.profile.email
        : '${widget.profile.prenoms.toLowerCase()}.${widget.profile.nom.toLowerCase()}@ist.bf';
    _telephone = widget.profile.telephone;
  }

  String get _initiales =>
      '${widget.profile.prenoms.isNotEmpty ? widget.profile.prenoms[0] : ''}'
      '${widget.profile.nom.isNotEmpty ? widget.profile.nom[0] : ''}'.toUpperCase();

  // ── Dialog d'édition ──────────────────────────────────────────────────
  void _editer({
    required String titre,
    required String valeur,
    required String hint,
    int maxLength = 200,
    int maxLines  = 1,
    required void Function(String) onSave,
  }) {
    final ctrl = TextEditingController(text: valeur);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Handle
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),

            Text('Modifier — $titre',
                style: const TextStyle(fontSize: 18,
                    fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0))),
              child: TextField(
                controller: ctrl,
                maxLength: maxLength,
                maxLines: maxLines,
                autofocus: true,
                style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: const TextStyle(
                      color: Color(0xFF64748B), fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Annuler',
                    style: TextStyle(fontSize: 15, color: Color(0xFF64748B))),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () {
                  onSave(ctrl.text.trim());
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Enregistrer',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              )),
            ]),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(children: [

          // ══════════════════════════════════════════════════════════
          // PHOTO DE COUVERTURE
          // ══════════════════════════════════════════════════════════
          Stack(clipBehavior: Clip.none, children: [

            // Couverture gradient bleu + jaune
            GestureDetector(
              onTap: () => _snackbar('Photo de couverture — Upload disponible en production'),
              child: Container(
                height: 190,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0A4DA2),
                      Color(0xFF1565C0),
                      Color(0xFF0D47A1),
                    ],
                  ),
                ),
                child: Stack(children: [
                  // Cercles décoratifs
                  Positioned(top: -30, right: -30,
                      child: Container(width: 140, height: 140,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                              color: AppPalette.yellow.withOpacity(0.15)))),
                  Positioned(bottom: -20, left: 60,
                      child: Container(width: 100, height: 100,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.06)))),
                  // Bouton modifier couverture
                  Positioned(bottom: 12, right: 12, child: GestureDetector(
                    onTap: () => _snackbar('Photo de couverture — Upload disponible en production'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(20)),
                      child: const Row(children: [
                        Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text('Modifier', style: TextStyle(color: Colors.white,
                            fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  )),
                ]),
              ),
            ),

            // Photo de profil ronde
            Positioned(bottom: -52, left: 20,
              child: Stack(children: [
                Container(
                  width: 104, height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: AppPalette.yellow,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15),
                        blurRadius: 12)],
                  ),
                  child: Center(child: Text(_initiales,
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                          color: AppPalette.blue))),
                ),
                Positioned(bottom: 3, right: 3, child: GestureDetector(
                  onTap: () => _snackbar('Photo de profil — Upload disponible en production'),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: AppPalette.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 16),
                  ),
                )),
              ]),
            ),
          ]),

          // Espace photo
          const SizedBox(height: 62),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Nom + rôle ────────────────────────────────────────
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${widget.profile.prenoms} ${widget.profile.nom}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A), letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text(widget.profile.matricule,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppPalette.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppPalette.blue.withOpacity(0.3)),
                  ),
                  child: Text(_roleLabel, style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold, color: AppPalette.blue)),
                ),
              ]),

              const SizedBox(height: 16),

              // ── Filière + domaine (non modifiable) ────────────────
              if (widget.profile.filiere.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppPalette.softYellow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppPalette.yellow.withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.school_outlined, color: AppPalette.blue, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.profile.filiere,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A))),
                      if (widget.profile.domaine.isNotEmpty)
                        Text(widget.profile.domaine,
                            style: const TextStyle(fontSize: 12, color: AppPalette.blue,
                                fontWeight: FontWeight.w600)),
                    ])),
                    const Icon(Icons.lock_outline, color: Color(0xFF94A3B8), size: 14),
                  ]),
                ),
                const SizedBox(height: 20),
              ],

              // ── Biographie ────────────────────────────────────────
              _sectionCard(
                titre: 'Biographie',
                icon: Icons.edit_outlined,
                couleur: AppPalette.blue,
                enfants: [
                  GestureDetector(
                    onTap: () => _editer(
                      titre: 'Biographie',
                      valeur: _bio,
                      hint: 'Parlez de vous...',
                      maxLength: 300,
                      maxLines: 4,
                      onSave: (v) => setState(() => _bio = v),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Text(
                        _bio.isEmpty
                            ? 'Appuyez pour ajouter une biographie...'
                            : _bio,
                        style: TextStyle(fontSize: 15, height: 1.6,
                          color: _bio.isEmpty
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF0F172A),
                          fontStyle: _bio.isEmpty
                              ? FontStyle.italic : FontStyle.normal,
                        ),
                      )),
                      const SizedBox(width: 8),
                      const Icon(Icons.edit, size: 16, color: Color(0xFF64748B)),
                    ]),
                  ),
                  if (_bio.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('${_bio.length}/300 caractères',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // ── Informations modifiables ───────────────────────────
              _sectionCard(
                titre: 'Informations personnelles',
                icon: Icons.person_outline,
                couleur: AppPalette.blue,
                enfants: [

                  // Email
                  _ligneModifiable(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    valeur: _emailVisible ? _email : '••••••@•••.••',
                    hint: 'Ajouter',
                    trailing: Switch(
                      value: _emailVisible,
                      activeColor: AppPalette.blue,
                      onChanged: (v) => setState(() => _emailVisible = v),
                    ),
                    onTap: () => _editer(
                      titre: 'Email',
                      valeur: _email,
                      hint: 'votre@email.com',
                      onSave: (v) => setState(() => _email = v),
                    ),
                  ),
                  _div(),

                  // Téléphone
                  _ligneModifiable(
                    icon: Icons.phone_outlined,
                    label: 'Téléphone',
                    valeur: _telVisible ? (_telephone.isNotEmpty ? _telephone : '') : '••• •• •• ••',
                    hint: 'Ajouter',
                    trailing: Switch(
                      value: _telVisible,
                      activeColor: AppPalette.blue,
                      onChanged: (v) => setState(() => _telVisible = v),
                    ),
                    onTap: () => _editer(
                      titre: 'Téléphone',
                      valeur: _telephone,
                      hint: '+226 XX XX XX XX',
                      onSave: (v) => setState(() => _telephone = v),
                    ),
                  ),
                  _div(),

                  // Ville
                  _ligneModifiable(
                    icon: Icons.location_on_outlined,
                    label: 'Ville / Localité',
                    valeur: _ville,
                    hint: 'Ajouter',
                    onTap: () => _editer(
                      titre: 'Ville',
                      valeur: _ville,
                      hint: 'Ex: Ouagadougou, Burkina Faso',
                      onSave: (v) => setState(() => _ville = v),
                    ),
                  ),
                  _div(),

                  // Date de naissance
                  _ligneModifiable(
                    icon: Icons.cake_outlined,
                    label: 'Date de naissance',
                    valeur: _dateNaiss,
                    hint: 'Optionnel',
                    onTap: () => _editer(
                      titre: 'Date de naissance',
                      valeur: _dateNaiss,
                      hint: 'JJ/MM/AAAA',
                      onSave: (v) => setState(() => _dateNaiss = v),
                    ),
                  ),
                  _div(),

                  // Centres d'intérêt
                  _ligneModifiable(
                    icon: Icons.interests_outlined,
                    label: 'Centres d\'intérêt',
                    valeur: _interets,
                    hint: 'Optionnel',
                    onTap: () => _editer(
                      titre: 'Centres d\'intérêt',
                      valeur: _interets,
                      hint: 'Ex: Programmation, Musique, Football...',
                      maxLines: 2,
                      onSave: (v) => setState(() => _interets = v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Informations académiques (non modifiables) ─────────
              _sectionCard(
                titre: 'Informations académiques',
                icon: Icons.school_outlined,
                couleur: AppPalette.blue,
                badge: '🔒 Géré par l\'admin',
                enfants: [
                  _ligneFixe(Icons.badge_outlined, 'Matricule',
                      widget.profile.matricule),
                  _div(),
                  _ligneFixe(Icons.menu_book_outlined, 'Filière',
                      widget.profile.filiere.isNotEmpty
                          ? widget.profile.filiere : 'Non renseignée'),
                  _div(),
                  _ligneFixe(Icons.apartment_outlined, 'Établissement',
                      'Institut Supérieur de Technologies'),
                ],
              ),

              const SizedBox(height: 16),

              // ── Réseaux sociaux ────────────────────────────────────
              _sectionCard(
                titre: 'Réseaux sociaux',
                icon: Icons.link,
                couleur: const Color(0xFF0891B2),
                badge: 'Optionnel',
                enfants: [
                  _ligneModifiable(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    valeur: _facebook,
                    hint: 'Ajouter',
                    iconColor: const Color(0xFF1877F2),
                    onTap: () => _editer(
                      titre: 'Facebook',
                      valeur: _facebook,
                      hint: 'facebook.com/votre-profil',
                      onSave: (v) => setState(() => _facebook = v),
                    ),
                  ),
                  _div(),
                  _ligneModifiable(
                    icon: Icons.chat_outlined,
                    label: 'WhatsApp',
                    valeur: _whatsapp,
                    hint: 'Ajouter',
                    iconColor: const Color(0xFF25D366),
                    onTap: () => _editer(
                      titre: 'WhatsApp',
                      valeur: _whatsapp,
                      hint: '+226 XX XX XX XX',
                      onSave: (v) => setState(() => _whatsapp = v),
                    ),
                  ),
                  _div(),
                  _ligneModifiable(
                    icon: Icons.work_outline,
                    label: 'LinkedIn',
                    valeur: _linkedin,
                    hint: 'Ajouter',
                    iconColor: const Color(0xFF0A66C2),
                    onTap: () => _editer(
                      titre: 'LinkedIn',
                      valeur: _linkedin,
                      hint: 'linkedin.com/in/votre-profil',
                      onSave: (v) => setState(() => _linkedin = v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Confidentialité ────────────────────────────────────
              _sectionCard(
                titre: 'Confidentialité',
                icon: Icons.privacy_tip_outlined,
                couleur: const Color(0xFF7C3AED),
                enfants: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(children: [
                      _confidRow('Profil visible par tous les membres', true, null),
                      const SizedBox(height: 10),
                      _confidRow('Email visible', _emailVisible,
                          (v) => setState(() => _emailVisible = v)),
                      const SizedBox(height: 10),
                      _confidRow('Téléphone visible', _telVisible,
                          (v) => setState(() => _telVisible = v)),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.info_outline, color: Color(0xFF15803D), size: 16),
                      SizedBox(width: 8),
                      Expanded(child: Text(
                        'Les parents et professeurs voient uniquement le profil de base (nom, filière, matricule).',
                        style: TextStyle(fontSize: 13, color: Color(0xFF15803D), height: 1.4),
                      )),
                    ]),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Bouton déconnexion ─────────────────────────────────
              SizedBox(
                width: double.infinity, height: 54,
                child: OutlinedButton.icon(
                  onPressed: _confirmerDeconnexion,
                  icon: const Icon(Icons.logout, color: Color(0xFFC62828)),
                  label: const Text('Se déconnecter',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                          color: Color(0xFFC62828))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF9A9A), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ]),
          ),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // WIDGETS HELPERS
  // ════════════════════════════════════════════════════════════════════════

  String get _roleLabel {
    switch (widget.profile.role) {
      case 'etudiant':   return 'Étudiant';
      case 'professeur': return 'Professeur';
      case 'admin':      return 'Administration';
      case 'bde':        return 'Bureau des Étudiants';
      case 'parent':     return 'Parent';
      default:           return 'Étudiant';
    }
  }

  Widget _sectionCard({
    required String titre,
    required IconData icon,
    required Color couleur,
    required List<Widget> enfants,
    String? badge,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(color: couleur.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: couleur, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Text(titre, style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Text(badge, style: const TextStyle(fontSize: 11,
                    color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              ),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: enfants),
        ),
      ]),
    );
  }

  Widget _ligneModifiable({
    required IconData icon,
    required String label,
    required String valeur,
    required VoidCallback onTap,
    String? hint,
    Color? iconColor,
    Widget? trailing,
  }) {
    final c      = iconColor ?? AppPalette.blue;
    final empty  = valeur.isEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: c.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: c, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12,
              color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(
            empty ? (hint ?? 'Appuyez pour modifier') : valeur,
            style: TextStyle(fontSize: 15,
              color: empty ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
              fontStyle: empty ? FontStyle.italic : FontStyle.normal,
              fontWeight: empty ? FontWeight.normal : FontWeight.w500,
            ),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
        ])),
        trailing ?? const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 20),
      ]),
    );
  }

  Widget _ligneFixe(IconData icon, String label, String valeur) {
    return Row(children: [
      Container(width: 40, height: 40,
        decoration: BoxDecoration(color: AppPalette.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppPalette.blue, size: 20)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12,
            color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(valeur, style: const TextStyle(fontSize: 15,
            color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
      ])),
      const Icon(Icons.lock_outline, color: Color(0xFF94A3B8), size: 16),
    ]);
  }

  Widget _div() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 10),
    child: Divider(height: 1, color: Color(0xFFE2E8F0)),
  );

  Widget _confidRow(String label, bool value, void Function(bool)? onChanged) {
    return Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14,
          color: Color(0xFF0F172A)))),
      onChanged != null
          ? Switch(value: value, activeColor: AppPalette.blue, onChanged: onChanged)
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Public', style: TextStyle(fontSize: 12,
                  color: Color(0xFF15803D), fontWeight: FontWeight.w600))),
    ]);
  }

  void _snackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppPalette.blue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _confirmerDeconnexion() {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Se déconnecter',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A))),
      content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler',
              style: TextStyle(fontSize: 15, color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Retour au splash et suppression de toute la pile
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SplashScreen()),
              (_) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC62828),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: const Text('Se déconnecter',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }
}

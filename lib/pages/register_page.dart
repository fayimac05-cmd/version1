import 'package:flutter/material.dart';
import '../config/etablissement_config.dart';
import '../theme/app_palette.dart';
import '../services/api_service.dart';
import '../models/student_profile.dart';
import 'login_page.dart';
import 'student_shell.dart';
import 'splash_screen.dart';

/// Inscription TEMPORAIRE des anciens étudiants (déjà inscrits les années
/// précédentes). Trois étapes : informations → récapitulatif → mot de passe.
/// Elle sera fermée par l'établissement (Super Admin) une fois tous les
/// anciens inscrits ; ensuite seule l'administration crée les étudiants.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const _niveaux = ['Licence 1', 'Licence 2', 'Licence 3', 'Master 1', 'Master 2'];

  final _codeCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _prenomsCtrl = TextEditingController();
  final _matriculeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _nomPersonneCtrl = TextEditingController();
  final _telPersonneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  List<String> _filieres = [];
  String? _filiereSelectionnee;
  String _niveauSelectionne = _niveaux.first;
  bool _chargementFilieres = true;
  String? _erreurFilieres;

  int _etape = 0; // 0 infos · 1 récapitulatif · 2 mot de passe · 3 demande envoyée
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  bool _verifCode = false;
  String? _error;
  String _messageFinal = '';

  EtablissementConfig get _etab => EtablissementConfig.instance;
  bool get _etabConnu => _etab.code.isNotEmpty && _etab.nom.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _etab.charger().then((_) {
      if (!mounted) return;
      setState(() {});
      if (_etabConnu) _chargerFilieres();
    });
  }

  Future<void> _chargerFilieres() async {
    setState(() { _chargementFilieres = true; _erreurFilieres = null; });
    final result = await ApiService.getFilieresPubliques();
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'] as List<dynamic>;
      _filieres = data.map((f) => (f['nom'] ?? '').toString()).where((n) => n.isNotEmpty).toList();
      if (_filieres.isEmpty) {
        _erreurFilieres = "Aucune filière n'est encore configurée. Contactez l'administration.";
      } else if (_filiereSelectionnee == null || !_filieres.contains(_filiereSelectionnee)) {
        _filiereSelectionnee = _filieres.first;
      }
    } else {
      _erreurFilieres = result['error']?.toString() ?? 'Impossible de charger les filières.';
    }
    setState(() => _chargementFilieres = false);
  }

  // Saisie du code quand l'app n'en a pas encore mémorisé un.
  Future<void> _verifierCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = "Saisissez le code de votre établissement.");
      return;
    }
    setState(() { _verifCode = true; _error = null; });
    final res = await ApiService.getEtablissementParCode(code);
    if (!mounted) return;
    if (res['success'] != true) {
      setState(() { _verifCode = false; _error = res['error']?.toString() ?? "Code d'établissement inconnu."; });
      return;
    }
    final e = Map<String, dynamic>.from(res['etablissement'] as Map);
    await _etab.appliquerEtablissement(
      id: e['id'] is int ? e['id'] as int : int.tryParse('${e['id']}'),
      nom: (e['nom'] ?? '').toString(),
      sigle: (e['sigle'] ?? '').toString(),
      ville: (e['ville'] ?? '').toString(),
      campus: (e['campus'] ?? '').toString(),
      code: code.toUpperCase(),
      modeleMatricule: (e['modele_matricule'] ?? '').toString(),
      inscriptionOuverte: e['inscription_ouverte'] == true,
      logoUrl: (e['logo_url'] ?? '').toString(),
    );
    if (!mounted) return;
    setState(() => _verifCode = false);
    _chargerFilieres();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nomCtrl.dispose();
    _prenomsCtrl.dispose();
    _matriculeCtrl.dispose();
    _emailCtrl.dispose();
    _telephoneCtrl.dispose();
    _nomPersonneCtrl.dispose();
    _telPersonneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // ── Étape 0 → 1 : contrôle des informations ──────────────────────────────
  void _versRecap() {
    final email = _emailCtrl.text.trim();
    if (!_etabConnu) {
      setState(() => _error = "Saisissez d'abord le code de votre établissement.");
      return;
    }
    if (_nomCtrl.text.trim().isEmpty ||
        _prenomsCtrl.text.trim().isEmpty ||
        _matriculeCtrl.text.trim().isEmpty ||
        email.isEmpty ||
        _telephoneCtrl.text.trim().isEmpty ||
        _filiereSelectionnee == null) {
      setState(() => _error = 'Veuillez remplir tous les champs obligatoires.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = "L'adresse e-mail n'est pas valide.");
      return;
    }
    setState(() { _error = null; _etape = 1; });
  }

  // ── Étape 2 : envoi ──────────────────────────────────────────────────────
  Future<void> _envoyer() async {
    final pass = _passCtrl.text;
    if (pass.isEmpty || _confirmPassCtrl.text.isEmpty) {
      setState(() => _error = 'Saisissez et confirmez votre mot de passe.');
      return;
    }
    if (pass != _confirmPassCtrl.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }
    if (pass.length < 4) {
      setState(() => _error = 'Le mot de passe doit contenir au moins 4 caractères.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final nom = _nomCtrl.text.trim();
    final prenoms = _prenomsCtrl.text.trim();
    final matricule = _matriculeCtrl.text.trim().toUpperCase();
    final email = _emailCtrl.text.trim();
    final telephone = _telephoneCtrl.text.trim();

    final result = await ApiService.register(
      nom: nom,
      prenoms: prenoms,
      email: email,
      telephone: telephone,
      motDePasse: pass,
      matricule: matricule,
      filiere: _filiereSelectionnee!,
      niveau: _niveauSelectionne,
      nomPersonne: _nomPersonneCtrl.text.trim(),
      telPersonne: _telPersonneCtrl.text.trim(),
    );
    if (!mounted) return;

    if (result['success'] != true) {
      setState(() {
        _loading = false;
        _error = result['error']?.toString() ?? "Erreur lors de l'inscription.";
      });
      return;
    }

    if (result['pending'] == true) {
      setState(() {
        _loading = false;
        _etape = 3;
        _messageFinal = result['message']?.toString() ??
            "Votre demande est enregistrée. Vous pourrez vous connecter dès qu'elle sera validée par l'administration.";
      });
      return;
    }

    // Validation automatique désactivée par l'établissement : connexion directe.
    final u = Map<String, dynamic>.from((result['user'] as Map?) ?? {});
    final profile = StudentProfile(
      nom: u['nom'] ?? nom.toUpperCase(),
      prenoms: u['prenoms'] ?? prenoms,
      matricule: u['matricule'] ?? matricule,
      email: u['email'] ?? email,
      telephone: u['telephone'] ?? telephone,
      filiere: u['filiere'] ?? _filiereSelectionnee ?? '',
      motDePasse: '',
      domaine: u['domaine'] ?? '',
      niveau: u['niveau'] ?? _niveauSelectionne,
      role: u['role'] ?? 'etudiant',
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => StudentShell(
          profile: profile,
          onLogout: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
          ),
        ),
      ),
      (route) => false,
    );
  }

  void _retour() {
    if (_etape == 1 || _etape == 2) {
      setState(() { _etape -= 1; _error = null; });
    } else {
      Navigator.of(context).pop();
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.white,
      body: Stack(
        children: [
          Positioned(
            top: -40, left: -60,
            child: Container(
              width: 220, height: 220,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0A4DA2)),
            ),
          ),
          Positioned(
            top: -20, right: -30,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1565C0).withValues(alpha: 0.6),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      if (_etape != 3)
                        IconButton(
                          onPressed: _retour,
                          icon: const Icon(Icons.arrow_back_ios_new, color: AppPalette.white),
                        )
                      else
                        const SizedBox(height: 48),
                      const SizedBox(height: 24),
                      if (_etape == 0) ..._buildInfos(),
                      if (_etape == 1) ..._buildRecap(),
                      if (_etape == 2) ..._buildMotDePasse(),
                      if (_etape == 3) ..._buildFin(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Étape 0 ──────────────────────────────────────────────────────────────
  List<Widget> _buildInfos() {
    final modele = _etab.modeleMatricule;
    return [
      const Text("S'inscrire",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppPalette.black)),
      const SizedBox(height: 8),
      const Text('Réservé aux étudiants déjà inscrits les années précédentes',
          style: TextStyle(fontSize: 14, color: AppPalette.grey)),
      const SizedBox(height: 28),

      // Établissement
      if (_etabConnu)
        _carteEtablissement()
      else ...[
        _buildLabel("Code de l'établissement *"),
        const SizedBox(height: 8),
        _buildTextField(controller: _codeCtrl, hint: 'Ex : IST2026', icon: Icons.vpn_key_outlined, caps: true),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity, height: 46,
          child: OutlinedButton(
            onPressed: _verifCode ? null : _verifierCode,
            child: _verifCode
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("Vérifier l'établissement"),
          ),
        ),
      ],
      const SizedBox(height: 22),

      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildLabel('Nom *'),
          const SizedBox(height: 8),
          _buildTextField(controller: _nomCtrl, hint: 'OUÉDRAOGO', icon: Icons.person_outline, caps: true),
        ])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildLabel('Prénom(s) *'),
          const SizedBox(height: 8),
          _buildTextField(controller: _prenomsCtrl, hint: 'Fatou', icon: Icons.person_outline),
        ])),
      ]),
      const SizedBox(height: 18),

      _buildLabel('Matricule *'),
      const SizedBox(height: 8),
      _buildTextField(
        controller: _matriculeCtrl,
        hint: modele.isNotEmpty ? 'Modèle : $modele' : 'Votre matricule',
        icon: Icons.badge_outlined,
        caps: true,
      ),
      const SizedBox(height: 18),

      if (_etabConnu) ...[
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildLabel('Filière *'),
            const SizedBox(height: 8),
            if (_chargementFilieres)
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator())
            else if (_erreurFilieres != null)
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_erreurFilieres!, style: TextStyle(color: Colors.red.shade700, fontSize: 12.5)),
                TextButton(onPressed: _chargerFilieres, child: const Text('Réessayer')),
              ])
            else
              _buildMenuField(
                value: _filiereSelectionnee,
                items: _filieres,
                icon: Icons.school_outlined,
                onChanged: (v) => setState(() => _filiereSelectionnee = v),
              ),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildLabel('Niveau *'),
            const SizedBox(height: 8),
            _buildMenuField(
              value: _niveauSelectionne,
              items: _niveaux,
              icon: Icons.stairs_outlined,
              onChanged: (v) => setState(() => _niveauSelectionne = v ?? _niveauSelectionne),
            ),
          ])),
        ]),
        const SizedBox(height: 18),
      ],

      _buildLabel('Email *'),
      const SizedBox(height: 8),
      _buildTextField(
        controller: _emailCtrl, hint: 'votre.email@exemple.com',
        icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 18),

      _buildLabel('Numéro de téléphone *'),
      const SizedBox(height: 8),
      _buildTextField(
        controller: _telephoneCtrl, hint: '70 00 00 00',
        icon: Icons.phone_outlined, keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 22),

      _buildLabel('Personne à prévenir en cas de besoin (facultatif)'),
      const SizedBox(height: 8),
      _buildTextField(controller: _nomPersonneCtrl, hint: 'Nom et prénom', icon: Icons.person_add_alt_outlined),
      const SizedBox(height: 10),
      _buildTextField(
        controller: _telPersonneCtrl, hint: 'Téléphone de cette personne',
        icon: Icons.phone_in_talk_outlined, keyboardType: TextInputType.phone,
      ),

      ..._blocErreur(),
      const SizedBox(height: 28),
      _boutonPrincipal('Continuer', _versRecap),
      const SizedBox(height: 24),
      _lienConnexion(),
    ];
  }

  // ── Étape 1 : récapitulatif ──────────────────────────────────────────────
  List<Widget> _buildRecap() {
    final lieu = [_etab.ville, if (_etab.campus.isNotEmpty) _etab.campus].where((x) => x.isNotEmpty).join(' · ');
    Widget ligne(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 130, child: Text(k, style: const TextStyle(fontSize: 13, color: AppPalette.grey))),
            Expanded(child: Text(v.isEmpty ? '—' : v,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppPalette.black))),
          ]),
        );
    return [
      const Text('Récapitulatif',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppPalette.black)),
      const SizedBox(height: 8),
      const Text('Vérifiez vos informations avant de continuer',
          style: TextStyle(fontSize: 14, color: AppPalette.grey)),
      const SizedBox(height: 24),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppPalette.lightGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.borderGrey),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ligne('Établissement', _etab.nom),
          ligne('Ville', lieu),
          const Divider(),
          ligne('Matricule', _matriculeCtrl.text.trim().toUpperCase()),
          ligne('Nom', _nomCtrl.text.trim().toUpperCase()),
          ligne('Prénom(s)', _prenomsCtrl.text.trim()),
          ligne('Filière', _filiereSelectionnee ?? ''),
          ligne('Niveau', _niveauSelectionne),
          ligne('Email', _emailCtrl.text.trim()),
          ligne('Téléphone', _telephoneCtrl.text.trim()),
          if (_nomPersonneCtrl.text.trim().isNotEmpty || _telPersonneCtrl.text.trim().isNotEmpty) ...[
            const Divider(),
            ligne('À prévenir', _nomPersonneCtrl.text.trim()),
            ligne('Tél. à prévenir', _telPersonneCtrl.text.trim()),
          ],
        ]),
      ),
      const SizedBox(height: 14),
      Text("Ce n'est pas votre établissement ? Revenez à l'écran d'accueil pour changer de code.",
          style: TextStyle(fontSize: 12.5, color: Colors.grey[600], height: 1.4)),
      ..._blocErreur(),
      const SizedBox(height: 24),
      _boutonPrincipal('Valider et choisir mon mot de passe', () => setState(() { _etape = 2; _error = null; })),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity, height: 48,
        child: TextButton(onPressed: _retour, child: const Text('Modifier mes informations')),
      ),
    ];
  }

  // ── Étape 2 : mot de passe ───────────────────────────────────────────────
  List<Widget> _buildMotDePasse() => [
        const Text('Mot de passe',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppPalette.black)),
        const SizedBox(height: 8),
        const Text('Choisissez le mot de passe de votre compte',
            style: TextStyle(fontSize: 14, color: AppPalette.grey)),
        const SizedBox(height: 28),
        _buildLabel('Mot de passe *'),
        const SizedBox(height: 8),
        _buildPasswordField(
          controller: _passCtrl, obscure: _obscure1,
          onToggle: () => setState(() => _obscure1 = !_obscure1),
          hint: 'Créez un mot de passe',
        ),
        const SizedBox(height: 18),
        _buildLabel('Confirmer le mot de passe *'),
        const SizedBox(height: 8),
        _buildPasswordField(
          controller: _confirmPassCtrl, obscure: _obscure2,
          onToggle: () => setState(() => _obscure2 = !_obscure2),
          hint: 'Confirmez votre mot de passe',
        ),
        ..._blocErreur(),
        const SizedBox(height: 28),
        _boutonPrincipal("Envoyer ma demande d'inscription", _envoyer, chargement: _loading),
      ];

  // ── Étape 3 : demande envoyée ────────────────────────────────────────────
  List<Widget> _buildFin() => [
        Center(
          child: Container(
            width: 84, height: 84,
            decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, color: Colors.green.shade600, size: 48),
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text('Demande envoyée',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppPalette.black)),
        ),
        const SizedBox(height: 12),
        Text(_messageFinal,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, color: Colors.grey[700], height: 1.5)),
        const SizedBox(height: 32),
        _boutonPrincipal('Retour à la connexion', () {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
        }),
      ];

  // ── Morceaux communs ─────────────────────────────────────────────────────
  Widget _carteEtablissement() {
    final lieu = [_etab.ville, if (_etab.campus.isNotEmpty) _etab.campus].where((x) => x.isNotEmpty).join(' · ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.lightBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.blue.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.apartment_rounded, color: AppPalette.blue, size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_etab.nom,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppPalette.blue)),
            if (lieu.isNotEmpty)
              Text(lieu, style: const TextStyle(fontSize: 12.5, color: AppPalette.grey)),
          ]),
        ),
      ]),
    );
  }

  List<Widget> _blocErreur() {
    if (_error == null) return const [];
    return [
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
        ]),
      ),
    ];
  }

  Widget _boutonPrincipal(String texte, VoidCallback onTap, {bool chargement = false}) => SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: chargement ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppPalette.blue,
            foregroundColor: AppPalette.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 0,
          ),
          child: chargement
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Flexible(
                    child: Text(texte,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward, size: 20),
                ]),
        ),
      );

  Widget _lienConnexion() => Center(
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Déjà inscrit ? ', style: TextStyle(color: AppPalette.grey, fontSize: 14)),
          GestureDetector(
            onTap: () => Navigator.of(context)
                .pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage())),
            child: const Text('Se connecter',
                style: TextStyle(color: AppPalette.blue, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ]),
      );

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppPalette.black),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool caps = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.lightGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.borderGrey),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: caps ? TextCapitalization.characters : TextCapitalization.none,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppPalette.grey, fontSize: 14),
          prefixIcon: Icon(icon, color: AppPalette.blue, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // Menu déroulant (PopupMenuButton : plus fiable que DropdownButton sur Flutter Web).
  Widget _buildMenuField({
    required String? value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (_) => items.map((e) => PopupMenuItem<String>(value: e, child: Text(e))).toList(),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppPalette.lightGrey,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppPalette.borderGrey),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Icon(icon, color: AppPalette.blue, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value ?? 'Choisir',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: AppPalette.black)),
          ),
          const Icon(Icons.keyboard_arrow_down, color: AppPalette.grey),
        ]),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.lightGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.borderGrey),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppPalette.grey, fontSize: 14),
          prefixIcon: const Icon(Icons.lock_outline, color: AppPalette.blue, size: 22),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppPalette.grey, size: 22,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
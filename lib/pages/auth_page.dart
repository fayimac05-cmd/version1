import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../pages/student_shell.dart';
import '../pages/splash_screen.dart';
import '../theme/app_palette.dart';
import 'choose_school_page.dart';

// ════════════════════════════════════════════════════════════════════════════
// BASE DE DONNÉES SIMULÉE
// ════════════════════════════════════════════════════════════════════════════
final Map<String, Map<String, dynamic>> _dbEtudiants = {
  '24IST-O2/1851': {
    'nom': 'KOURAOGO', 'prenoms': 'Ibrahim',
    'filiere': 'Réseaux Informatiques et Télécom',
    'domaine': 'Sciences & Technologies',
    'niveau': 'Licence 2', 'role': 'etudiant',
    'premiereFois': false, 'motDePasse': '1851',
  },
  '24IST-O2/1234': {
    'nom': 'TRAORÉ', 'prenoms': 'Fatimata',
    'filiere': 'Licence Informatique',
    'domaine': 'Sciences & Technologies',
    'niveau': 'Licence 2', 'role': 'etudiant',
    'premiereFois': true, 'motDePasse': '',
  },
  '23IST-O2/0987': {
    'nom': 'SAWADOGO', 'prenoms': 'Moussa',
    'filiere': 'Gestion Comptable et Financière',
    'domaine': 'Sciences de Gestion',
    'niveau': 'Licence 3', 'role': 'etudiant',
    'premiereFois': false, 'motDePasse': '0987',
  },
  '24IST-ADM/001': {
    'nom': 'COMPAORÉ', 'prenoms': 'Idrissa',
    'filiere': 'Direction Pédagogique', 'domaine': '',
    'role': 'admin', 'premiereFois': false, 'motDePasse': 'admin123',
  },
  '24IST-BDE/001': {
    'nom': 'OUÉDRAOGO', 'prenoms': 'Aïcha',
    'filiere': 'Bureau des Étudiants', 'domaine': '',
    'role': 'bde', 'premiereFois': false, 'motDePasse': 'bde123',
  },
};

final Map<String, Map<String, dynamic>> _dbProfs = {
  'ouedraogo mamadou 70123456': {
    'nom': 'OUÉDRAOGO', 'prenoms': 'Mamadou',
    'filiere': 'Algorithmes & Réseaux', 'domaine': '',
    'role': 'professeur', 'premiereFois': false, 'motDePasse': 'prof123',
  },
};

final Map<String, Map<String, dynamic>> _dbParents = {
  'kouraogo seydou 65001234': {
    'nom': 'KOURAOGO', 'prenoms': 'Seydou',
    'filiere': 'Parent d\'élève', 'domaine': '',
    'role': 'parent', 'premiereFois': false, 'motDePasse': 'parent123',
  },
};

enum _Etape { saisie, motDePasse, premiereFois }

// ════════════════════════════════════════════════════════════════════════════
// PAGE AUTH
// ════════════════════════════════════════════════════════════════════════════
class AuthPage extends StatefulWidget {
  final Etablissement etablissement;
  const AuthPage({super.key, required this.etablissement});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  int    _tab   = 0;
  _Etape _etape = _Etape.saisie;

  final _matriculeCtrl = TextEditingController();
  final _nomCtrl       = TextEditingController();
  final _prenomCtrl    = TextEditingController();
  final _numeroCtrl    = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _newPassCtrl   = TextEditingController();
  final _confPassCtrl  = TextEditingController();

  bool    _obscure  = true;
  bool    _obscure2 = true;
  bool    _obscure3 = true;
  bool    _loading  = false;
  String? _error;

  Map<String, dynamic>? _userTrouve;
  String?               _cleTrouvee;

  @override
  void dispose() {
    for (final c in [_matriculeCtrl, _nomCtrl, _prenomCtrl, _numeroCtrl,
        _passCtrl, _emailCtrl, _newPassCtrl, _confPassCtrl]) c.dispose();
    super.dispose();
  }

  // ── Navigation vers le dashboard ─────────────────────────────────────
  void _goToDashboard(StudentProfile profile) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => StudentShell(
          profile: profile,
          onLogout: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SplashScreen()),
              (_) => false,
            );
          },
        ),
      ),
      (_) => false,
    );
  }

  // ── Vérifier identité ────────────────────────────────────────────────
  void _verifier() async {
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 900));

    if (_tab == 0) {
      final mat = _matriculeCtrl.text.trim().toUpperCase();
      if (mat.isEmpty) { _setError('Veuillez saisir votre matricule.'); return; }
      final user = _dbEtudiants[mat];
      if (user == null) {
        _setError('Matricule non reconnu dans ${widget.etablissement.abreviation}.\nContactez l\'administration.');
        return;
      }
      setState(() { _userTrouve = user; _cleTrouvee = mat; _loading = false; });
    } else {
      final nom    = _nomCtrl.text.trim().toLowerCase();
      final prenom = _prenomCtrl.text.trim().toLowerCase();
      final num    = _numeroCtrl.text.trim();
      if (nom.isEmpty || prenom.isEmpty || num.isEmpty) {
        _setError('Veuillez remplir tous les champs.'); return;
      }
      final key  = '$nom $prenom $num';
      final user = _dbProfs[key] ?? _dbParents[key];
      if (user == null) {
        _setError('Aucun compte trouvé.\nVérifiez l\'orthographe ou votre numéro.');
        return;
      }
      setState(() {
        _userTrouve  = user;
        _cleTrouvee  = '${user['role'].toString().toUpperCase()}-$num';
        _loading     = false;
      });
    }

    await Future.delayed(const Duration(milliseconds: 200));
    setState(() => _etape = _userTrouve!['premiereFois'] == true
        ? _Etape.premiereFois
        : _Etape.motDePasse);
  }

  // ── Connexion avec MDP ───────────────────────────────────────────────
  void _connecter() async {
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 800));
    if (_passCtrl.text.isEmpty) { _setError('Veuillez saisir votre mot de passe.'); return; }
    if (_passCtrl.text != _userTrouve!['motDePasse']) {
      _setError('Mot de passe incorrect.'); return;
    }
    setState(() => _loading = false);
    _goToDashboard(_buildProfile(_passCtrl.text));
  }

  // ── Créer compte (1ère fois) ─────────────────────────────────────────
  void _creerCompte() async {
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 800));
    if (_emailCtrl.text.isEmpty || _newPassCtrl.text.isEmpty || _confPassCtrl.text.isEmpty) {
      _setError('Veuillez remplir tous les champs.'); return;
    }
    if (!_emailCtrl.text.contains('@')) { _setError('Email invalide.'); return; }
    if (_newPassCtrl.text.length < 4) { _setError('Mot de passe : minimum 4 caractères.'); return; }
    if (_newPassCtrl.text != _confPassCtrl.text) { _setError('Les mots de passe ne correspondent pas.'); return; }
    setState(() => _loading = false);
    _goToDashboard(_buildProfile(_newPassCtrl.text));
  }

  StudentProfile _buildProfile(String mdp) {
    final u = _userTrouve!;
    return StudentProfile(
      nom: u['nom'], prenoms: u['prenoms'],
      matricule: _cleTrouvee!,
      email: _emailCtrl.text,
      telephone: '',
      filiere: u['filiere'],
      motDePasse: mdp,
      domaine: u['domaine'] ?? '',
      role: u['role'] ?? 'etudiant',
    );
  }

  // ── Accès démo IBRAHIM ────────────────────────────────────────────────
  void _demoBrahim() {
    _goToDashboard(const StudentProfile(
      nom: 'KOURAOGO', prenoms: 'Ibrahim',
      matricule: '24IST-O2/1851',
      email: 'ibrahim.kouraogo@ist.bf',
      telephone: '',
      filiere: 'Réseaux Informatiques et Télécom',
      motDePasse: '1851',
      domaine: 'Sciences & Technologies',
      role: 'etudiant',
    ));
  }

  void _setError(String msg) =>
      setState(() { _error = msg; _loading = false; });

  void _recommencer() => setState(() {
    _etape = _Etape.saisie; _userTrouve = null; _error = null;
    for (final c in [_matriculeCtrl, _nomCtrl, _prenomCtrl, _numeroCtrl,
        _passCtrl, _emailCtrl, _newPassCtrl, _confPassCtrl]) c.clear();
  });

  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildEtape(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEtape() {
    switch (_etape) {
      case _Etape.saisie:        return _buildSaisie();
      case _Etape.motDePasse:    return _buildMotDePasse();
      case _Etape.premiereFois:  return _buildPremiereFois();
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // ÉTAPE 1 — SAISIE
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildSaisie() {
    final e = widget.etablissement;
    return Column(key: const ValueKey('saisie'),
      crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Header retour + école
      Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(width: 42, height: 42,
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Icon(Icons.arrow_back_ios_new,
                size: 16, color: Color(0xFF0F172A))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ScolarHub', style: TextStyle(fontSize: 20,
              fontWeight: FontWeight.bold, color: AppPalette.blue)),
          Text(e.campus.isNotEmpty ? '${e.nom} · ${e.campus}' : e.nom,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              overflow: TextOverflow.ellipsis),
        ])),
      ]),

      const SizedBox(height: 28),

      // Logo + badge école
      Center(child: Column(children: [
        Stack(alignment: Alignment.bottomRight, children: [
          Container(width: 80, height: 80,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppPalette.blue),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 44)),
          Container(width: 28, height: 28,
            decoration: BoxDecoration(color: AppPalette.yellow, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2)),
            child: Center(child: Text(e.abreviation.substring(0, 1),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                    color: AppPalette.black)))),
        ]),
        const SizedBox(height: 14),
        const Text('Connexion', style: TextStyle(fontSize: 26,
            fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.4)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: AppPalette.lightBlue,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppPalette.blue.withOpacity(0.2))),
          child: Text(
            e.campus.isNotEmpty ? '${e.abreviation} · ${e.campus}' : e.nom,
            style: const TextStyle(fontSize: 13, color: AppPalette.blue,
                fontWeight: FontWeight.w700),
          ),
        ),
      ])),

      const SizedBox(height: 28),

      // Switch onglets
      Container(
        decoration: BoxDecoration(color: AppPalette.lightBlue,
            borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(4),
        child: Row(children: [
          _tabBtn(0, 'Matricule',    Icons.badge_outlined),
          _tabBtn(1, 'Nom & Prénom', Icons.person_outline),
        ]),
      ),
      const SizedBox(height: 8),
      Text(_tab == 0 ? 'Pour : Étudiant, Administration, BDE'
                     : 'Pour : Professeur, Parent',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),

      const SizedBox(height: 20),

      // Champs
      if (_tab == 0) ...[
        _lbl('Matricule ${e.abreviation}'),
        _champ(_matriculeCtrl,
            e.abreviation == 'IST' ? 'Ex: 24IST-O2/1851' : 'Votre matricule',
            Icons.badge_outlined, TextInputType.text),
      ] else ...[
        _lbl('Nom de famille'),
        _champ(_nomCtrl, 'Ex: OUÉDRAOGO', Icons.person_outline, TextInputType.name),
        const SizedBox(height: 14),
        _lbl('Prénom'),
        _champ(_prenomCtrl, 'Ex: Mamadou', Icons.person_outline, TextInputType.name),
        const SizedBox(height: 14),
        _lbl('Numéro de téléphone'),
        _champ(_numeroCtrl, 'Ex: 70123456', Icons.phone_outlined, TextInputType.phone),
      ],

      if (_error != null) ...[const SizedBox(height: 14), _erreur(_error!)],
      const SizedBox(height: 20),

      SizedBox(width: double.infinity, height: 54,
        child: ElevatedButton(
          onPressed: _loading ? null : _verifier,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE2E8F0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0),
          child: _loading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Text('VÉRIFIER', style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ),

      const SizedBox(height: 28),

      Row(children: [
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('ou', style: TextStyle(fontSize: 13, color: Colors.grey.shade400))),
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
      ]),

      const SizedBox(height: 20),

      // Accès démo
      if (e.abreviation == 'IST') ...[
        SizedBox(width: double.infinity, height: 54,
          child: OutlinedButton.icon(
            onPressed: _demoBrahim,
            icon: const Text('⚡', style: TextStyle(fontSize: 20)),
            label: const Text('Accès Démo — Ibrahim KOURAOGO',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppPalette.blue,
              side: const BorderSide(color: AppPalette.blue, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(child: Text('24IST-O2/1851 · IST Campus Ouaga 2000',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B),
                fontStyle: FontStyle.italic))),
        const SizedBox(height: 24),
      ] else const SizedBox(height: 8),

      // Boutons de redirection ajoutés
      SizedBox(width: double.infinity, height: 54,
        child: OutlinedButton(
          onPressed: () {
            // TODO: Action de redirection 1
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppPalette.blue,
            side: const BorderSide(color: AppPalette.blue, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('BGE',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, height: 54,
        child: OutlinedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CoursesTab()
              )
            )
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppPalette.blue,
            side: const BorderSide(color: AppPalette.blue, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Redirection 2',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(height: 24),

      if (_tab == 0) _infoMatricule(e),
    ]);
  }

  // ════════════════════════════════════════════════════════════════════════
  // ÉTAPE 2A — MOT DE PASSE
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildMotDePasse() => Column(key: const ValueKey('mdp'),
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    _boutonRetour(_recommencer),
    const SizedBox(height: 24),
    _carteUser(_userTrouve!),
    const SizedBox(height: 28),
    const Text('Saisissez votre mot de passe', style: TextStyle(fontSize: 22,
        fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.3)),
    const SizedBox(height: 8),
    const Text('Entrez votre mot de passe pour accéder à votre espace.',
        style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5)),
    const SizedBox(height: 24),
    _lbl('Mot de passe'),
    _champPass(_passCtrl, 'Votre mot de passe', _obscure,
        () => setState(() => _obscure = !_obscure)),
    Align(alignment: Alignment.centerRight,
        child: TextButton(onPressed: _motDePasseOublie,
            child: const Text('Mot de passe oublié ?',
                style: TextStyle(color: AppPalette.blue, fontSize: 13)))),
    if (_error != null) ...[const SizedBox(height: 8), _erreur(_error!)],
    const SizedBox(height: 20),
    SizedBox(width: double.infinity, height: 54,
      child: ElevatedButton(
        onPressed: _loading ? null : _connecter,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0),
        child: _loading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Text('SE CONNECTER', style: TextStyle(fontSize: 16,
                fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    ),
    const SizedBox(height: 16),
    Center(child: TextButton(onPressed: _recommencer,
        child: const Text('Ce n\'est pas moi',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13)))),
  ]);

  // ════════════════════════════════════════════════════════════════════════
  // ÉTAPE 2B — PREMIÈRE CONNEXION
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildPremiereFois() => Column(key: const ValueKey('premier'),
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    _boutonRetour(_recommencer),
    const SizedBox(height: 24),
    _carteUser(_userTrouve!),
    const SizedBox(height: 28),
    const Text('Créez votre compte', style: TextStyle(fontSize: 22,
        fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.3)),
    const SizedBox(height: 8),
    const Text('Première connexion — Définissez votre email et mot de passe.',
        style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5)),
    const SizedBox(height: 24),
    _lbl('Adresse email'),
    _champ(_emailCtrl, 'votre@email.com', Icons.email_outlined, TextInputType.emailAddress),
    const SizedBox(height: 18),
    _lbl('Choisissez un mot de passe'),
    _champPass(_newPassCtrl, 'Minimum 4 caractères', _obscure2,
        () => setState(() => _obscure2 = !_obscure2)),
    const SizedBox(height: 18),
    _lbl('Confirmer le mot de passe'),
    _champPass(_confPassCtrl, 'Répétez votre mot de passe', _obscure3,
        () => setState(() => _obscure3 = !_obscure3)),
    if (_error != null) ...[const SizedBox(height: 14), _erreur(_error!)],
    const SizedBox(height: 24),
    SizedBox(width: double.infinity, height: 54,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _creerCompte,
        icon: _loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Icon(Icons.check_circle_outline, size: 22),
        label: Text(_loading ? 'Création...' : 'CRÉER MON COMPTE',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF15803D), foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0),
      ),
    ),
    const SizedBox(height: 16),
    Center(child: TextButton(onPressed: _recommencer,
        child: const Text('Ce n\'est pas moi',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13)))),
  ]);

  // ════════════════════════════════════════════════════════════════════════
  // WIDGETS PARTAGÉS
  // ════════════════════════════════════════════════════════════════════════

  Widget _carteUser(Map<String, dynamic> u) {
    final role = u['role'] as String;
    final domaine = (u['domaine'] ?? '') as String;
    Color rc; String rl;
    switch (role) {
      case 'etudiant':   rc = AppPalette.blue;         rl = 'Étudiant'; break;
      case 'professeur': rc = const Color(0xFF7C3AED); rl = 'Professeur'; break;
      case 'admin':      rc = const Color(0xFF15803D); rl = 'Administration'; break;
      case 'bde':        rc = const Color(0xFF0891B2); rl = 'Bureau des Étudiants'; break;
      case 'parent':     rc = const Color(0xFFD97706); rl = 'Parent'; break;
      default:           rc = AppPalette.blue;         rl = role;
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [rc, rc.withOpacity(0.78)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: rc.withOpacity(0.3),
            blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Row(children: [
        Container(width: 58, height: 58,
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2)),
          child: Center(child: Text(
            '${u['prenoms'].toString()[0]}${u['nom'].toString()[0]}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                color: Colors.white)))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${u['prenoms']} ${u['nom']}', style: const TextStyle(fontSize: 18,
              fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.2)),
          const SizedBox(height: 4),
          Text(_cleTrouvee ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 5),
          Text(u['filiere'], style: const TextStyle(fontSize: 13,
              color: Colors.white, fontWeight: FontWeight.w500)),
          if (domaine.isNotEmpty) ...[
            const SizedBox(height: 5),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(domaine, style: const TextStyle(fontSize: 11,
                  color: Colors.white, fontWeight: FontWeight.w700))),
          ],
          const SizedBox(height: 8),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(rl, style: const TextStyle(fontSize: 12,
                  color: Colors.white, fontWeight: FontWeight.w600))),
            if (u['premiereFois'] == true) ...[
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('1ère connexion', style: TextStyle(fontSize: 11,
                    color: Colors.white, fontWeight: FontWeight.w600))),
            ],
          ]),
        ])),
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
      ]),
    );
  }

  Widget _boutonRetour(VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 42, height: 42,
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: const Icon(Icons.arrow_back_ios_new,
          size: 16, color: Color(0xFF0F172A))),
  );

  Widget _tabBtn(int index, String label, IconData icon) {
    final active = _tab == index;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() {
        _tab = index; _error = null;
        _matriculeCtrl.clear(); _nomCtrl.clear();
        _prenomCtrl.clear(); _numeroCtrl.clear();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 4, offset: const Offset(0, 1))] : []),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16,
              color: active ? AppPalette.blue : const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: active ? AppPalette.blue : const Color(0xFF64748B))),
        ]),
      ),
    ));
  }

  Widget _lbl(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(fontSize: 15,
        fontWeight: FontWeight.w700, color: Color(0xFF0F172A))));

  Widget _champ(TextEditingController ctrl, String hint,
      IconData ico, TextInputType type) =>
      Container(
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
                blurRadius: 6, offset: const Offset(0, 2))]),
        child: TextField(controller: ctrl, keyboardType: type,
          onChanged: (_) => setState(() => _error = null),
          style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
            prefixIcon: Icon(ico, color: const Color(0xFF64748B), size: 22),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      );

  Widget _champPass(TextEditingController ctrl, String hint,
      bool obscure, VoidCallback toggle) =>
      Container(
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
                blurRadius: 6, offset: const Offset(0, 2))]),
        child: TextField(controller: ctrl, obscureText: obscure,
          onChanged: (_) => setState(() => _error = null),
          style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
            prefixIcon: const Icon(Icons.lock_outline,
                color: Color(0xFF64748B), size: 22),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
                  color: const Color(0xFF64748B), size: 22),
              onPressed: toggle,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      );

  Widget _erreur(String msg) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF9A9A))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: const TextStyle(fontSize: 14,
          color: Color(0xFFC62828), height: 1.4))),
    ]),
  );

  Widget _infoMatricule(Etablissement e) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppPalette.lightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.blue.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.info_outline, color: AppPalette.blue, size: 16),
        const SizedBox(width: 8),
        Text('Format du matricule ${e.abreviation}', style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.bold, color: AppPalette.blue)),
      ]),
      const SizedBox(height: 10),
      if (e.abreviation == 'IST') ...[
        _fmtLigne('24',   'Année d\'entrée (2024)'),
        _fmtLigne('IST',  'Institut Supérieur de Technologies'),
        _fmtLigne('-O2/', 'Campus Ouaga 2000'),
        _fmtLigne('1851', 'Numéro d\'étudiant'),
        const SizedBox(height: 6),
        const Text('Exemple : 24IST-O2/1851', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.bold, color: AppPalette.blue)),
      ] else
        Text('Consultez votre carte d\'étudiant ${e.abreviation}.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
    ]),
  );

  Widget _fmtLigne(String code, String desc) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: AppPalette.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6)),
        child: Text(code, style: const TextStyle(fontSize: 12,
            fontWeight: FontWeight.bold, color: AppPalette.blue,
            fontFamily: 'monospace'))),
      const SizedBox(width: 10),
      Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
    ]),
  );

  void _motDePasseOublie() {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [
        Icon(Icons.lock_reset, color: AppPalette.blue),
        SizedBox(width: 10),
        Text('Mot de passe oublié', style: TextStyle(fontSize: 17,
            fontWeight: FontWeight.bold)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Un lien sera envoyé à votre adresse email.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5)),
        const SizedBox(height: 16),
        Container(decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0))),
          child: const TextField(style: TextStyle(fontSize: 15),
            decoration: InputDecoration(hintText: 'votre@email.com',
                hintStyle: TextStyle(color: Color(0xFF64748B)),
                prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF64748B), size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14))),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF64748B)))),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Lien envoyé ! Vérifiez votre email.'),
              backgroundColor: Color(0xFF15803D),
            ));
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppPalette.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0),
          child: const Text('Envoyer'),
        ),
      ],
    ));
  }
}

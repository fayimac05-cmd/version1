import 'package:flutter/material.dart';
import '../app/scolar_hub_app.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/supabase_service.dart';
import 'student_shell.dart';
import 'splash_screen.dart';
import 'register_page.dart';
import 'first_connection_page.dart';
import 'forgot_password_page.dart';
import '../professeur/professor_shell.dart';
import 'parent_shell.dart';
import '../admin/admin_shell.dart';
import 'bureau_des_etudiants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _matriculeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  // Mock database for local auth
  static final Map<String, Map<String, dynamic>> _dbEtudiants = {
    '24IST-O2/1851': {
      'nom': 'KOURAOGO',
      'prenoms': 'Ibrahim',
      'filiere': 'Réseaux Informatiques et Télécom',
      'domaine': 'Sciences & Technologies',
      'niveau': 'Licence 2',
      'role': 'etudiant',
      'motDePasse': '1851',
    },
    '24IST-O2/1234': {
      'nom': 'TRAORÉ',
      'prenoms': 'Fatimata',
      'filiere': 'Licence Informatique',
      'domaine': 'Sciences & Technologies',
      'niveau': 'Licence 2',
      'role': 'etudiant',
      'motDePasse': 'password',
    },
    '23IST-O2/0987': {
      'nom': 'SAWADOGO',
      'prenoms': 'Moussa',
      'filiere': 'Gestion Comptable et Financière',
      'domaine': 'Sciences de Gestion',
      'niveau': 'Licence 3',
      'role': 'etudiant',
      'motDePasse': '0987',
    },
    '24IST-ADM/001': {
      'nom': 'COMPAORÉ',
      'prenoms': 'Idrissa',
      'filiere': 'Direction Pédagogique',
      'domaine': '',
      'role': 'admin',
      'motDePasse': 'admin123',
    },
    '24IST-BDE/001': {
      'nom': 'OUÉDRAOGO',
      'prenoms': 'Aïcha',
      'filiere': 'Bureau des Étudiants',
      'domaine': '',
      'role': 'bde',
      'motDePasse': 'bde123',
    },
    '24IST-PROF/001': {
      'nom': 'KABORÉ',
      'prenoms': 'Serge',
      'filiere': 'Réseaux et Télécommunications',
      'domaine': 'Sciences & Technologies',
      'niveau': '',
      'role': 'professeur',
      'motDePasse': 'prof123',
    },
    '24IST-PROF/002': {
      'nom': 'TRAORÉ',
      'prenoms': 'Aminata',
      'filiere': 'Informatique & Gestion',
      'domaine': 'Sciences & Technologies',
      'niveau': '',
      'role': 'professeur',
      'motDePasse': 'prof456',
    },
    '24IST-PAR/001': {
      'nom': 'KOURAOGO',
      'prenoms': 'Seydou',
      'filiere': '',
      'domaine': '',
      'role': 'parent',
      'motDePasse': 'parent123',
    },
  };

  // Comptes de démonstration pour les boutons d'accès rapide
  static const List<Map<String, String>> _accesRapide = [
    {'label': 'Admin', 'matricule': '24IST-ADM/001', 'motDePasse': 'admin123'},
    {'label': 'Prof', 'matricule': '24IST-PROF/001', 'motDePasse': 'prof123'},
    {'label': 'Parent', 'matricule': '24IST-PAR/001', 'motDePasse': 'parent123'},
    {'label': 'Étudiant', 'matricule': '24IST-O2/1851', 'motDePasse': '1851'},
  ];

  void _connexionRapide(Map<String, String> compte) {
    _matriculeCtrl.text = compte['matricule']!;
    _passCtrl.text = compte['motDePasse']!;
    _login();
  }

  @override
  void dispose() {
    _matriculeCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final mat = _matriculeCtrl.text.trim().toUpperCase();
    final pass = _passCtrl.text.trim();

    // Le matricule est toujours obligatoire
    if (mat.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Veuillez saisir votre matricule.';
      });
      return;
    }

    // 1. Essayer la connexion directe via Supabase
    try {
      final supabaseRes = await SupabaseService().loginEtudiant(
        matricule: mat,
        motDePasse: pass.isEmpty ? null : pass,
      );

      // Première connexion détectée par Supabase
      if (supabaseRes['success'] == true && supabaseRes['isFirstConnection'] == true) {
        final u = supabaseRes['user'] as Map<String, dynamic>? ?? {};
        if (!mounted) return;
        setState(() => _loading = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FirstConnectionPage(
              matricule: u['matricule']?.toString() ?? mat,
              nom: u['nom']?.toString() ?? '',
              prenoms: u['prenoms']?.toString() ?? '',
              filiereId: u['filiere_id']?.toString() ?? '',
              filiere: u['filiere']?.toString() ?? '',
              niveau: u['niveau']?.toString() ?? '',
            ),
          ),
        );
        return;
      }

      if (supabaseRes['success'] == true && supabaseRes['user'] != null) {
        final u = supabaseRes['user'];
        final profile = StudentProfile(
          nom: u['nom'] ?? '',
          prenoms: u['prenoms'] ?? '',
          matricule: u['matricule'] ?? mat,
          email: u['email'] ?? '',
          telephone: u['telephone'] ?? '',
          filiere: u['filiere'] ?? '',
          motDePasse: '',
          domaine: u['domaine'] ?? '',
          niveau: u['niveau'] ?? '',
          role: u['role'] ?? 'etudiant',
        );
        _goToDashboard(profile);
        return;
      }
    } catch (_) {}

    // 2. Essayer via le backend Node.js (ApiService)
    final result = await ApiService.login(matricule: mat, motDePasse: pass);

    // Première connexion détectée par le backend
    if (result['premiereFois'] == true && result['student'] != null) {
      final u = result['student'] as Map<String, dynamic>? ?? {};
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FirstConnectionPage(
            matricule: u['matricule']?.toString() ?? mat,
            nom: u['nom']?.toString() ?? '',
            prenoms: u['prenoms']?.toString() ?? '',
            filiereId: u['filiere_id']?.toString() ?? '',
            filiere: u['filiere']?.toString() ?? '',
            niveau: u['niveau']?.toString() ?? '',
          ),
        ),
      );
      return;
    }

    if (result['success'] == true && result['user'] != null) {
      final u = result['user'];
      final profile = StudentProfile(
        nom: u['nom'] ?? '',
        prenoms: u['prenoms'] ?? '',
        matricule: u['matricule'] ?? mat,
        email: u['email'] ?? '',
        telephone: u['telephone'] ?? '',
        filiere: u['filiere'] ?? '',
        motDePasse: '',
        domaine: u['domaine'] ?? '',
        niveau: u['niveau'] ?? '',
        role: u['role'] ?? 'etudiant',
      );
      _goToDashboard(profile);
      return;
    }

    // Si le backend a répondu mais a rejeté la connexion
    if (result['offline'] != true) {
      setState(() {
        _loading = false;
        _error = result['error']?.toString() ?? 'Identifiants incorrects.';
      });
      return;
    }

    // Fallback to local mock DB (backend injoignable uniquement)
    final user = _dbEtudiants[mat];
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Matricule introuvable.';
      });
      return;
    }

    if (user['motDePasse'] != pass) {
      setState(() {
        _loading = false;
        _error = 'Mot de passe incorrect.';
      });
      return;
    }

    final profile = StudentProfile(
      nom: user['nom'] ?? '',
      prenoms: user['prenoms'] ?? '',
      matricule: mat,
      email: '',
      telephone: '',
      filiere: user['filiere'] ?? '',
      motDePasse: '',
      domaine: user['domaine'] ?? '',
      niveau: user['niveau'] ?? '',
      role: user['role'] ?? 'etudiant',
    );
    _goToDashboard(profile);
  }

  void _goToDashboard(StudentProfile profile) {
    SocketService().connect(profile.matricule);

    // Utilise le navigateur global : le context de cette page n'existe plus
    // au moment où l'utilisateur se déconnecte depuis son tableau de bord.
    void logout() {
      ApiService.clearToken();
      ScolarHubApp.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (_) => false,
      );
    }

    final Widget destination;
    switch (profile.role) {
      case 'admin':
        destination = AdminShell(profile: profile, onLogout: logout);
        break;
      case 'bde':
        destination = const BureauDesEtudiantsScreen();
        break;
      case 'professeur':
        destination = ProfessorShell(profile: profile, onLogout: logout);
        break;
      case 'parent':
        destination = ParentShell(
          nomEnfant: '${profile.prenoms} ${profile.nom}',
          onLogout: logout,
        );
        break;
      default:
        destination = StudentShell(profile: profile, onLogout: logout);
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.white,
      body: Stack(
        children: [
          // Grande bulle bleue haut-gauche
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A3D91), Color(0xFF1565C0)],
                ),
              ),
            ),
          ),
          // Bulle bleue haut-droit
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1565C0).withValues(alpha: 0.55),
              ),
            ),
          ),
          // Petite bulle jaune
          Positioned(
            top: 85,
            right: 85,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppPalette.yellow),
            ),
          ),
          // Bulle bleue claire bas-gauche
          Positioned(
            bottom: 180,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.blue.withValues(alpha: 0.06)),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Back button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: AppPalette.white),
                  ),

                  const SizedBox(height: 40),

                  // Logo + Title
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppPalette.yellow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.school_rounded,
                            color: AppPalette.blue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'ScolarHub',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Bon retour !',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Connectez-vous avec votre matricule',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 28),

                  // Accès rapide (démo)
                  Text(
                    'Accès rapide (démo)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _accesRapide
                        .map((compte) => _buildAccesRapideChip(compte))
                        .toList(),
                  ),

                  const SizedBox(height: 28),

                  // Matricule field
                  _buildLabel('Matricule'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _matriculeCtrl,
                    hint: 'Ex: 24IST-O2/1851',
                    icon: Icons.badge_outlined,
                  ),

                  const SizedBox(height: 20),

                  // Password field
                  Row(
                    children: [
                      _buildLabel('Mot de passe'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          'Optionnel à la 1ère connexion',
                          style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildPasswordField(),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade400, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_error!,
                                style: TextStyle(
                                    color: Colors.red.shade700, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                        );
                      },
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(
                          color: AppPalette.blue,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.blue,
                        foregroundColor: AppPalette.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Se connecter',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Register link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Pas encore inscrit ? ",
                            style:
                                TextStyle(color: AppPalette.grey, fontSize: 14)),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (_) => const RegisterPage()),
                            );
                          },
                          child: const Text("S'inscrire",
                              style: TextStyle(
                                  color: AppPalette.blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccesRapideChip(Map<String, String> compte) {
    const icones = {
      'Admin': Icons.admin_panel_settings_outlined,
      'Prof': Icons.school_outlined,
      'Parent': Icons.family_restroom_outlined,
      'Étudiant': Icons.person_outline,
    };
    return GestureDetector(
      onTap: _loading ? null : () => _connexionRapide(compte),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppPalette.lightBlue,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppPalette.blue.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icones[compte['label']], size: 16, color: AppPalette.blue),
            const SizedBox(width: 6),
            Text(
              compte['label']!,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppPalette.black,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.lightGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.borderGrey),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppPalette.grey, fontSize: 14),
          prefixIcon: Icon(icon, color: AppPalette.blue, size: 22),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.lightGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.borderGrey),
      ),
      child: TextField(
        controller: _passCtrl,
        obscureText: _obscure,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Entrez votre mot de passe',
          hintStyle: const TextStyle(color: AppPalette.grey, fontSize: 14),
          prefixIcon:
              const Icon(Icons.lock_outline, color: AppPalette.blue, size: 22),
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppPalette.grey,
              size: 22,
            ),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

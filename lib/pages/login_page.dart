import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'student_shell.dart';
import 'splash_screen.dart';
import 'register_page.dart';
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
  };

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

    if (mat.isEmpty || pass.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Veuillez remplir tous les champs.';
      });
      return;
    }

    // Try backend first
    final result = await ApiService.login(matricule: mat, motDePasse: pass);

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

    // Fallback to local mock DB
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

    void logout() => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (_) => false,
        );

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
          // Blue decorative header
          Positioned(
            top: -40,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0A4DA2),
              ),
            ),
          ),
          Positioned(
            top: -20,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1565C0).withValues(alpha: 0.6),
              ),
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

                  // Title
                  const Text(
                    'Se connecter',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connectez-vous avec votre matricule',
                    style: TextStyle(fontSize: 14, color: AppPalette.grey),
                  ),

                  const SizedBox(height: 40),

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
                  _buildLabel('Mot de passe'),
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
                      onPressed: () {},
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

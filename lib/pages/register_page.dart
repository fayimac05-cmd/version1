import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import '../services/api_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nomCtrl = TextEditingController();
  final _prenomsCtrl = TextEditingController();
  final _matriculeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomsCtrl.dispose();
    _matriculeCtrl.dispose();
    _emailCtrl.dispose();
    _telephoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _register() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final nom = _nomCtrl.text.trim();
    final prenoms = _prenomsCtrl.text.trim();
    final matricule = _matriculeCtrl.text.trim().toUpperCase();
    final email = _emailCtrl.text.trim();
    final telephone = _telephoneCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    if (nom.isEmpty ||
        prenoms.isEmpty ||
        matricule.isEmpty ||
        email.isEmpty ||
        pass.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Veuillez remplir tous les champs obligatoires.';
      });
      return;
    }

    if (pass != confirmPass) {
      setState(() {
        _loading = false;
        _error = 'Les mots de passe ne correspondent pas.';
      });
      return;
    }

    if (pass.length < 4) {
      setState(() {
        _loading = false;
        _error = 'Le mot de passe doit contenir au moins 4 caractères.';
      });
      return;
    }

    // Try backend registration
    final result = await ApiService.inscrireEtudiant({
      'nom': nom,
      'prenoms': prenoms,
      'matricule': matricule,
      'email': email,
      'telephone': telephone,
      'motDePasse': pass,
    });

    if (result['success'] == true) {
      setState(() {
        _loading = false;
        _success = 'Inscription réussie ! Vous pouvez maintenant vous connecter.';
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } else {
      setState(() {
        _loading = false;
        _error = result['error'] ?? 'Erreur lors de l\'inscription.';
      });
    }
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

                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    "S'inscrire",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Créez votre compte étudiant',
                    style: TextStyle(fontSize: 14, color: AppPalette.grey),
                  ),

                  const SizedBox(height: 32),

                  // Name fields in row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Nom *'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _nomCtrl,
                              hint: 'OUÉDRAOGO',
                              icon: Icons.person_outline,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Prénom(s) *'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _prenomsCtrl,
                              hint: 'Fatou',
                              icon: Icons.person_outline,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Matricule
                  _buildLabel('Matricule *'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _matriculeCtrl,
                    hint: 'Ex: 24IST-O2/1851',
                    icon: Icons.badge_outlined,
                  ),

                  const SizedBox(height: 18),

                  // Email
                  _buildLabel('Email *'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _emailCtrl,
                    hint: 'votre.email@ist.bf',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 18),

                  // Phone
                  _buildLabel('Téléphone'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _telephoneCtrl,
                    hint: '70 00 00 00',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 18),

                  // Password
                  _buildLabel('Mot de passe *'),
                  const SizedBox(height: 8),
                  _buildPasswordField(
                    controller: _passCtrl,
                    obscure: _obscure1,
                    onToggle: () => setState(() => _obscure1 = !_obscure1),
                    hint: 'Créez un mot de passe',
                  ),

                  const SizedBox(height: 18),

                  // Confirm password
                  _buildLabel('Confirmer le mot de passe *'),
                  const SizedBox(height: 8),
                  _buildPasswordField(
                    controller: _confirmPassCtrl,
                    obscure: _obscure2,
                    onToggle: () => setState(() => _obscure2 = !_obscure2),
                    hint: 'Confirmez votre mot de passe',
                  ),

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

                  if (_success != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.green.shade600, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_success!,
                                style: TextStyle(
                                    color: Colors.green.shade700, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
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
                                Text("S'inscrire",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Login link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Déjà inscrit ? ',
                            style:
                                TextStyle(color: AppPalette.grey, fontSize: 14)),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (_) => const LoginPage()),
                            );
                          },
                          child: const Text('Se connecter',
                              style: TextStyle(
                                  color: AppPalette.blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
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
    TextInputType keyboardType = TextInputType.text,
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
          prefixIcon:
              const Icon(Icons.lock_outline, color: AppPalette.blue, size: 22),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
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

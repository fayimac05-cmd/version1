import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import '../models/student_profile.dart';
import '../services/supabase_service.dart';
import '../services/api_service.dart';
import '../app/scolar_hub_app.dart';
import 'student_shell.dart';
import 'splash_screen.dart';

class FirstConnectionPage extends StatefulWidget {
  const FirstConnectionPage({
    super.key,
    required this.matricule,
    required this.nom,
    required this.prenoms,
    this.filiereId = '',
    this.filiere = '',
    this.niveau = '',
  });

  final String matricule;
  final String nom;
  final String prenoms;
  final String filiereId;
  final String filiere;
  final String niveau;

  @override
  State<FirstConnectionPage> createState() => _FirstConnectionPageState();
}

class _FirstConnectionPageState extends State<FirstConnectionPage> {
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _finaliser() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Veuillez remplir tous les champs obligatoires.';
      });
      return;
    }

    if (!email.contains('@')) {
      setState(() {
        _loading = false;
        _error = 'Veuillez saisir une adresse email valide.';
      });
      return;
    }

    if (pass != confirm) {
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

    // 1. Essayer via Supabase
    try {
      final res = await SupabaseService().finaliserPremiereConnexion(
        matricule: widget.matricule,
        email: email,
        telephone: phone,
        motDePasse: pass,
      );
      if (res['success'] == true) {
        final u = res['user'] as Map<String, dynamic>? ?? {};
        _goToDashboard(u, email, phone);
        return;
      }
    } catch (_) {}

    // 2. Fallback via le backend Node.js
    try {
      final res = await ApiService.finaliserInscription(
        matricule: widget.matricule,
        email: email,
        telephone: phone,
        password: pass,
      );
      if (res['success'] == true) {
        final u = res['user'] as Map<String, dynamic>? ?? {};
        _goToDashboard(u, email, phone);
        return;
      }
      setState(() {
        _loading = false;
        _error = res['error']?.toString() ?? "Erreur lors de l'activation du compte.";
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Erreur de connexion : $e';
      });
    }
  }

  void _goToDashboard(Map<String, dynamic> u, String email, String phone) {
    final profile = StudentProfile(
      nom: u['nom']?.toString() ?? widget.nom,
      prenoms: u['prenoms']?.toString() ?? widget.prenoms,
      matricule: u['matricule']?.toString() ?? widget.matricule,
      email: u['email']?.toString() ?? email,
      telephone: u['telephone']?.toString() ?? phone,
      filiere: u['filiere']?.toString() ?? widget.filiere,
      motDePasse: '',
      domaine: u['domaine']?.toString() ?? '',
      niveau: u['niveau']?.toString() ?? widget.niveau,
      role: u['role']?.toString() ?? 'etudiant',
    );

    void logout() {
      ApiService.clearToken();
      ScolarHubApp.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (_) => false,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => StudentShell(profile: profile, onLogout: logout),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.white,
      body: Stack(
        children: [
          // Bulle décorative haut-gauche
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
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
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1565C0).withValues(alpha: 0.5),
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
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppPalette.white),
                  ),
                  const SizedBox(height: 30),

                  // Logo + Nom app
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppPalette.yellow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.school_rounded, color: AppPalette.blue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'ScolarHub',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Première connexion',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppPalette.black),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Complétez votre profil pour activer votre compte.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 24),

                  // Carte étudiant pré-remplie
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppPalette.lightBlue,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppPalette.blue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppPalette.blue,
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.prenoms} ${widget.nom}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15, color: AppPalette.black),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.matricule,
                                style: const TextStyle(fontSize: 13, color: AppPalette.blue, fontWeight: FontWeight.w600),
                              ),
                              if (widget.filiere.isNotEmpty)
                                Text(
                                  widget.filiere,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 14, color: Colors.green.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'Vérifié',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Email
                  _buildLabel('Email *'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _emailCtrl,
                    hint: 'votre@email.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 18),

                  // Téléphone
                  _buildLabel('Téléphone (optionnel)'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _phoneCtrl,
                    hint: '+226 XX XX XX XX',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 18),

                  // Mot de passe
                  _buildLabel('Nouveau mot de passe *'),
                  const SizedBox(height: 8),
                  _buildPasswordField(
                    controller: _passCtrl,
                    hint: 'Choisissez un mot de passe',
                    obscure: _obscure1,
                    onToggle: () => setState(() => _obscure1 = !_obscure1),
                  ),

                  const SizedBox(height: 18),

                  // Confirmer mot de passe
                  _buildLabel('Confirmer le mot de passe *'),
                  const SizedBox(height: 8),
                  _buildPasswordField(
                    controller: _confirmPassCtrl,
                    hint: 'Répétez votre mot de passe',
                    obscure: _obscure2,
                    onToggle: () => setState(() => _obscure2 = !_obscure2),
                  ),

                  // Message erreur
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
                          Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_error!,
                                style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Bouton activer
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _finaliser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, size: 20),
                                SizedBox(width: 10),
                                Text('Activer mon compte',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              ],
                            ),
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
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppPalette.black),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
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
              color: AppPalette.grey,
              size: 22,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

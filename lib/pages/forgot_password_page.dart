import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  int _step = 1;
  bool _loading = false;
  String? _error;
  String? _success;

  final _identifiantCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _identifiantCtrl.dispose();
    _codeCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _requestResetCode() async {
    final identifiant = _identifiantCtrl.text.trim();
    if (identifiant.isEmpty) {
      setState(() => _error = 'Veuillez saisir votre matricule ou adresse email.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final res = await ApiService.forgotPassword(identifiant: identifiant);

    if (!mounted) return;

    if (res['success'] == true) {
      final devCode = res['code']?.toString();
      if (devCode != null && devCode.isNotEmpty) {
        _codeCtrl.text = devCode;
      }
      setState(() {
        _loading = false;
        _step = 2;
        _success = devCode != null && devCode.isNotEmpty
            ? '${res['message']}\n(Mode Dev : Code $devCode)'
            : res['message'];
      });
    } else {
      setState(() {
        _loading = false;
        _error = res['error'];
      });
    }
  }

  void _resetPassword() async {
    final identifiant = _identifiantCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final pass = _newPasswordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;

    if (code.isEmpty || pass.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs.');
      return;
    }

    if (pass != confirm) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }

    if (pass.length < 4) {
      setState(() => _error = 'Le mot de passe doit contenir au moins 4 caractères.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final res = await ApiService.resetPassword(
      identifiant: identifiant,
      code: code,
      newPassword: pass,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _loading = false;
        _success = res['message'];
      });
      // Retour à la page de login après succès
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      setState(() {
        _loading = false;
        _error = res['error'];
      });
    }
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
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: AppPalette.blue, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppPalette.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Mot de passe oublié',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppPalette.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _step == 1
                  ? 'Entrez votre matricule ou adresse email pour recevoir un code de réinitialisation.'
                  : 'Entrez le code reçu et votre nouveau mot de passe.',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            if (_step == 1) ...[
              _buildLabel('Identifiant (Matricule ou Email)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _identifiantCtrl,
                hint: 'Ex: 24IST-O2/1851 ou email@ist.bf',
                icon: Icons.person_outline,
              ),
            ] else ...[
              _buildLabel('Code de réinitialisation (6 chiffres)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _codeCtrl,
                hint: 'Ex: 123456',
                icon: Icons.vpn_key_outlined,
              ),
              const SizedBox(height: 20),
              _buildLabel('Nouveau mot de passe'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _newPasswordCtrl,
                hint: 'Minimum 4 caractères',
                icon: Icons.lock_outline,
                isPassword: true,
                obscure: _obscurePass,
                onToggleObscure: () => setState(() => _obscurePass = !_obscurePass),
              ),
              const SizedBox(height: 20),
              _buildLabel('Confirmer le mot de passe'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _confirmPasswordCtrl,
                hint: 'Minimum 4 caractères',
                icon: Icons.lock_outline,
                isPassword: true,
                obscure: _obscureConfirm,
                onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ],

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
                      child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
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
                    Icon(Icons.check_circle_outline, color: Colors.green.shade400, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_success!, style: TextStyle(color: Colors.green.shade700, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : (_step == 1 ? _requestResetCode : _resetPassword),
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _step == 1 ? 'Recevoir le code' : 'Réinitialiser le mot de passe',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

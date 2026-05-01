import 'package:flutter/material.dart';

import '../models/student_profile.dart';
import '../theme/app_palette.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.onRegister,
    required this.onLogin,
    required this.hasRegisteredStudent,
  });

  final void Function(StudentProfile profile) onRegister;
  final void Function(String matricule, String email, String motDePasse)
  onLogin;
  final bool hasRegisteredStudent;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  static const List<String> _filieres = [
    'Reseau Informatique et Telecom',
    'Electronique et Informatique Industrielle',
    'Electrotechnique Maintenance Industrielle',
    'Analyse Biomedicale et Maintenance Biomedicale et Hospitaliere',
  ];

  final _registerFormKey = GlobalKey<FormState>();
  final _loginFormKey = GlobalKey<FormState>();

  final _nomController = TextEditingController();
  final _prenomsController = TextEditingController();
  final _matriculeRegisterController = TextEditingController();
  final _emailRegisterController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _motDePasseRegisterController = TextEditingController();

  final _matriculeLoginController = TextEditingController();
  final _emailLoginController = TextEditingController();
  final _motDePasseLoginController = TextEditingController();

  int _selectedIndex = 0;
  String? _selectedFiliere;
  bool _obscureRegisterPassword = true;
  bool _obscureLoginPassword = true;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomsController.dispose();
    _matriculeRegisterController.dispose();
    _emailRegisterController.dispose();
    _telephoneController.dispose();
    _motDePasseRegisterController.dispose();
    _matriculeLoginController.dispose();
    _emailLoginController.dispose();
    _motDePasseLoginController.dispose();
    super.dispose();
  }

  void _submitRegistration() {
    if (_registerFormKey.currentState?.validate() != true) {
      return;
    }
    widget.onRegister(
      StudentProfile(
        nom: _nomController.text.trim(),
        prenoms: _prenomsController.text.trim(),
        matricule: _matriculeRegisterController.text.trim(),
        email: _emailRegisterController.text.trim(),
        telephone: _telephoneController.text.trim(),
        filiere: _selectedFiliere!,
        motDePasse: _motDePasseRegisterController.text.trim(),
      ),
    );
  }

  void _submitLogin() {
    if (_loginFormKey.currentState?.validate() != true) {
      return;
    }
    widget.onLogin(
      _matriculeLoginController.text.trim(),
      _emailLoginController.text.trim(),
      _motDePasseLoginController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 36),
                color: AppPalette.blue,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: AppPalette.yellow.withValues(
                        alpha: 0.25,
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        size: 34,
                        color: AppPalette.yellow,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'ScolarHub',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppPalette.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Plateforme academique centralisee',
                      style: TextStyle(color: AppPalette.white),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -14),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppPalette.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.blue.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'INSCRIPTION / CONNEXION',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('S\'inscrire')),
                          ButtonSegment(value: 1, label: Text('Se connecter')),
                        ],
                        selected: {_selectedIndex},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _selectedIndex = selection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        child: _selectedIndex == 0
                            ? KeyedSubtree(
                                key: const ValueKey('register'),
                                child: _buildRegisterForm(),
                              )
                            : KeyedSubtree(
                                key: const ValueKey('login'),
                                child: _buildLoginForm(),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      key: _registerFormKey,
      child: Column(
        children: [
          _buildField(_nomController, 'Nom'),
          _buildField(_prenomsController, 'Prenoms'),
          _buildField(_matriculeRegisterController, 'Matricule'),
          _buildField(_emailRegisterController, 'Mail', isEmail: true),
          _buildField(
            _telephoneController,
            'Numero de telephone',
            isPhone: true,
          ),
          _buildField(
            _motDePasseRegisterController,
            'Mot de passe',
            isPassword: true,
            obscureText: _obscureRegisterPassword,
            onTogglePassword: () {
              setState(() {
                _obscureRegisterPassword = !_obscureRegisterPassword;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedFiliere,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Filiere',
                filled: true,
                fillColor: AppPalette.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppPalette.lightBlue,
                    width: 1.4,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppPalette.blue,
                    width: 1.5,
                  ),
                ),
              ),
              items: _filieres
                  .map(
                    (filiere) => DropdownMenuItem<String>(
                      value: filiere,
                      child: Text(filiere),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFiliere = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Choisissez votre filiere';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.blue,
                foregroundColor: AppPalette.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _submitRegistration,
              child: const Text('Creer mon compte'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      key: _loginFormKey,
      child: Column(
        children: [
          _buildField(_matriculeLoginController, 'Matricule'),
          _buildField(_emailLoginController, 'Mail', isEmail: true),
          _buildField(
            _motDePasseLoginController,
            'Mot de passe',
            isPassword: true,
            obscureText: _obscureLoginPassword,
            onTogglePassword: () {
              setState(() {
                _obscureLoginPassword = !_obscureLoginPassword;
              });
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.blue,
                foregroundColor: AppPalette.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                if (!widget.hasRegisteredStudent) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Inscrivez-vous d\'abord pour creer un compte.',
                      ),
                    ),
                  );
                  return;
                }
                _submitLogin();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Connexion en cours... verifiez vos identifiants si rien ne se passe.',
                    ),
                  ),
                );
              },
              child: const Text('Connexion'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool isEmail = false,
    bool isPhone = false,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: isEmail
            ? TextInputType.emailAddress
            : isPhone
            ? TextInputType.phone
            : TextInputType.text,
        obscureText: isPassword ? obscureText : false,
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) {
            return 'Ce champ est obligatoire';
          }
          if (isEmail && !text.contains('@')) {
            return 'Mail invalide';
          }
          if (isPhone && text.length < 8) {
            return 'Numero invalide';
          }
          if (isPassword && text.length < 4) {
            return 'Mot de passe trop court (min 4)';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                )
              : null,
          filled: true,
          fillColor: AppPalette.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppPalette.lightBlue,
              width: 1.4,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppPalette.blue, width: 1.5),
          ),
        ),
      ),
    );
  }
}

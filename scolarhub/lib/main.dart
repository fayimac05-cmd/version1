import 'dart:async';

import 'package:flutter/material.dart';

class AppPalette {
  static const blue = Color(0xFF0A4DA2);
  static const yellow = Color(0xFFF8C400);
  static const softYellow = Color(0xFFFFF5CC);
  static const lightBlue = Color(0xFFEAF2FF);
  static const white = Colors.white;
  static const black = Color(0xFF121212);
}

void main() {
  runApp(const ScolarHubApp());
}

class ScolarHubApp extends StatefulWidget {
  const ScolarHubApp({super.key});

  @override
  State<ScolarHubApp> createState() => _ScolarHubAppState();
}

class _ScolarHubAppState extends State<ScolarHubApp> {
  StudentProfile? _registeredProfile;
  StudentProfile? _activeProfile;

  void _registerStudent(StudentProfile profile) {
    setState(() {
      _registeredProfile = profile;
      _activeProfile = profile;
    });
  }

  void _loginStudent(String matricule, String email, String motDePasse) {
    final saved = _registeredProfile;
    if (saved == null) {
      return;
    }
    if (saved.matricule == matricule &&
        saved.email.toLowerCase() == email.toLowerCase() &&
        saved.motDePasse == motDePasse) {
      setState(() {
        _activeProfile = saved;
      });
    }
  }

  void _logout() {
    setState(() {
      _activeProfile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ScolarHub',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: AppPalette.blue,
          secondary: AppPalette.yellow,
          surface: AppPalette.white,
          onPrimary: AppPalette.white,
          onSecondary: AppPalette.black,
          onSurface: AppPalette.black,
        ),
        scaffoldBackgroundColor: AppPalette.white,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: AppPalette.black,
          displayColor: AppPalette.black,
        ),
        cardTheme: CardThemeData(
          color: AppPalette.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        useMaterial3: true,
      ),
      home: _activeProfile == null
          ? AuthPage(
              onRegister: _registerStudent,
              onLogin: _loginStudent,
              hasRegisteredStudent: _registeredProfile != null,
            )
          : StudentShell(profile: _activeProfile!, onLogout: _logout),
    );
  }
}

class StudentProfile {
  const StudentProfile({
    required this.nom,
    required this.prenoms,
    required this.matricule,
    required this.email,
    required this.telephone,
    required this.filiere,
    required this.motDePasse,
  });

  final String nom;
  final String prenoms;
  final String matricule;
  final String email;
  final String telephone;
  final String filiere;
  final String motDePasse;
}

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

class StudentShell extends StatefulWidget {
  const StudentShell({
    super.key,
    required this.profile,
    required this.onLogout,
  });

  final StudentProfile profile;
  final VoidCallback onLogout;

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(profile: widget.profile),
      const CoursesTab(),
      const NotesTab(),
      const PlanningTab(),
      ProfileTab(profile: widget.profile, onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(
            key: ValueKey(_currentTab),
            child: pages[_currentTab],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppPalette.white,
        indicatorColor: AppPalette.yellow.withValues(alpha: 0.45),
        selectedIndex: _currentTab,
        onDestinationSelected: (index) {
          setState(() {
            _currentTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Cours',
          ),
          NavigationDestination(
            icon: Icon(Icons.grading_outlined),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Planning',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenue ${profile.prenoms}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Institut Superieur des Technologies - Espace etudiant'),
          const SizedBox(height: 16),
          const InfoTicker(),
          const SizedBox(height: 16),
          const WeeklyProgramQuickWidget(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppPalette.blue, Color(0xFF0E6CD3)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resume rapide',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppPalette.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Consultez vos programmes, vos notes et vos ressources depuis un seul espace.',
                    style: TextStyle(color: AppPalette.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoTicker extends StatefulWidget {
  const InfoTicker({super.key});

  @override
  State<InfoTicker> createState() => _InfoTickerState();
}

class WeeklyProgramQuickWidget extends StatelessWidget {
  const WeeklyProgramQuickWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final percent = _academicYearProgress();
    final percentLabel = (percent * 100).toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.lightBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppPalette.blue, width: 1.6),
                backgroundColor: AppPalette.softYellow,
                foregroundColor: AppPalette.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProgramImagePage()),
                );
              },
              icon: const Icon(Icons.calendar_view_week_outlined),
              label: const Text(
                'Mon programme',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Progression annee academique: $percentLabel%',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppPalette.blue,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: percent,
              backgroundColor: AppPalette.lightBlue,
              color: AppPalette.yellow,
            ),
          ),
        ],
      ),
    );
  }

  double _academicYearProgress() {
    final now = DateTime.now();
    final start = DateTime(2025, 9, 15);
    final end = DateTime(2026, 7, 31);
    if (now.isBefore(start)) {
      return 0;
    }
    if (now.isAfter(end)) {
      return 1;
    }
    final total = end.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds;
    return elapsed / total;
  }
}

class ProgramImagePage extends StatelessWidget {
  const ProgramImagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppPalette.blue,
        foregroundColor: AppPalette.white,
        title: const Text('Mon programme'),
      ),
      body: Container(
        color: AppPalette.white,
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/programme_semaine.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTickerState extends State<InfoTicker> {
  final _controller = PageController(viewportFraction: 0.92);
  final _messages = const [
    'Inscriptions pedagogiques ouvertes jusqu\'au 10 septembre.',
    'Conference sur l\'innovation numerique vendredi a 14h.',
    'La bibliotheque est ouverte de 8h a 20h du lundi au samedi.',
    'Bourses d\'excellence: depots des dossiers avant le 30 juin.',
  ];
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_controller.hasClients) {
        return;
      }
      _currentPage = (_currentPage + 1) % _messages.length;
      _controller.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: PageView.builder(
        controller: _controller,
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: Card(
              color: index.isEven ? AppPalette.yellow : const Color(0xFFFFE082),
              elevation: 2,
              shadowColor: AppPalette.blue.withValues(alpha: 0.25),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.campaign_outlined, color: AppPalette.blue),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_messages[index])),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SimpleInfoTab extends StatelessWidget {
  const SimpleInfoTab({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppPalette.blue,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppPalette.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          color: AppPalette.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un cours...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppPalette.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppPalette.lightBlue),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppPalette.blue),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final stripeColor = index.isEven
                  ? AppPalette.blue
                  : AppPalette.yellow;
              return Container(
                decoration: BoxDecoration(
                  color: AppPalette.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.blue.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 98,
                      decoration: BoxDecoration(
                        color: stripeColor,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(16),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'INFO10${index + 1}',
                                  style: TextStyle(
                                    color: stripeColor == AppPalette.yellow
                                        ? AppPalette.black
                                        : AppPalette.blue,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppPalette.softYellow,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'S${(index % 2) + 3}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              items[index],
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 19,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Prof. Marie Sawadogo',
                                  style: TextStyle(color: Colors.black54),
                                ),
                                Text(
                                  '5 cr.',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CoursesTab extends StatelessWidget {
  const CoursesTab({super.key});

  static const _courses = [
    'Algorithmique & Structures de Donnees',
    'Bases de Donnees',
    'Programmation Orientee Objet',
    'Reseaux Informatiques',
    'Mathematiques Discretes',
    'Anglais Technique',
  ];

  @override
  Widget build(BuildContext context) {
    return const SimpleInfoTab(
      title: 'Cours',
      icon: Icons.menu_book_outlined,
      items: _courses,
    );
  }
}

class NotesTab extends StatelessWidget {
  const NotesTab({super.key});

  @override
  Widget build(BuildContext context) {
    const notes = [
      _NoteItem(
        code: 'INFO101',
        matiere: 'Algorithmique',
        cc: '14.00',
        tp: '15.00',
        exam: '16.00',
        moyenne: '15.10',
      ),
      _NoteItem(
        code: 'INFO102',
        matiere: 'Bases de Donnees',
        cc: '12.00',
        tp: '13.00',
        exam: '14.00',
        moyenne: '13.10',
      ),
      _NoteItem(
        code: 'MATH201',
        matiere: 'Maths Discretes',
        cc: '11.00',
        tp: '—',
        exam: '13.00',
        moyenne: '12.20',
      ),
      _NoteItem(
        code: 'ANG101',
        matiere: 'Anglais Technique',
        cc: '16.00',
        tp: '—',
        exam: '17.00',
        moyenne: '16.60',
      ),
    ];

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppPalette.blue,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
          child: Column(
            children: [
              Text(
                'Notes',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppPalette.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Moyenne generale',
                style: TextStyle(color: AppPalette.white),
              ),
              const SizedBox(height: 6),
              const Text(
                '14.25 / 20',
                style: TextStyle(
                  color: AppPalette.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                '2024-2025',
                style: TextStyle(color: AppPalette.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 6, bottom: 10),
                child: Text(
                  'SEMESTRE 3',
                  style: TextStyle(
                    color: Colors.black54,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...notes.map((note) => _noteCard(note)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _noteCard(_NoteItem note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppPalette.blue.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                note.code,
                style: const TextStyle(
                  color: AppPalette.blue,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.softYellow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Valide',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          Text(
            note.matiere,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 34),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _scoreBox('CC', note.cc),
              _scoreBox('TP', note.tp),
              _scoreBox('Exam', note.exam),
              _scoreBox('Moy.', note.moyenne, highlighted: true),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Semestre 3', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _scoreBox(String title, String value, {bool highlighted = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: highlighted ? AppPalette.softYellow : const Color(0xFFF4F6FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: highlighted ? AppPalette.blue : AppPalette.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlanningTab extends StatelessWidget {
  const PlanningTab({super.key});

  @override
  Widget build(BuildContext context) {
    const events = [
      _EventItem(
        titre: 'Rentree academique 2024-2025',
        date: '15 septembre 2024',
        description: 'Debut de l annee academique 2024-2025.',
      ),
      _EventItem(
        titre: 'Debut des examens S3',
        date: '4 novembre 2024 -> 15 novembre 2024',
        description: 'Examens de fin du semestre 3.',
      ),
      _EventItem(
        titre: 'Deliberations S3',
        date: '25 novembre 2024',
        description: 'Publication des resultats du semestre 3.',
      ),
      _EventItem(
        titre: 'Vacances',
        date: '23 decembre 2024 -> 5 janvier 2025',
        description: 'Vacances academiques.',
      ),
      _EventItem(
        titre: 'Reprise des cours S4',
        date: '6 janvier 2025',
        description: 'Debut du semestre 4.',
      ),
    ];

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppPalette.blue,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
          child: Text(
            'Calendrier',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppPalette.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          color: AppPalette.blue,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: const Row(
            children: [
              Icon(Icons.event_outlined, color: AppPalette.yellow),
              SizedBox(width: 10),
              Text(
                'Calendrier Academique 2024-2025',
                style: TextStyle(
                  color: AppPalette.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final borderColor = index.isEven
                  ? AppPalette.blue
                  : AppPalette.yellow;
              return Container(
                decoration: BoxDecoration(
                  color: AppPalette.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.blue.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 96,
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(16),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    events[index].titre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppPalette.softYellow,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Academique',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              events[index].date,
                              style: const TextStyle(
                                color: AppPalette.blue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              events[index].description,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NoteItem {
  const _NoteItem({
    required this.code,
    required this.matiere,
    required this.cc,
    required this.tp,
    required this.exam,
    required this.moyenne,
  });

  final String code;
  final String matiere;
  final String cc;
  final String tp;
  final String exam;
  final String moyenne;
}

class _EventItem {
  const _EventItem({
    required this.titre,
    required this.date,
    required this.description,
  });

  final String titre;
  final String date;
  final String description;
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.profile, required this.onLogout});

  final StudentProfile profile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: const BoxDecoration(color: AppPalette.blue),
            child: Column(
              children: [
                Text(
                  'Profil',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppPalette.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppPalette.yellow,
                  child: Text(
                    _initials(profile),
                    style: const TextStyle(
                      color: AppPalette.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${profile.prenoms} ${profile.nom}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppPalette.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.yellow.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Etudiant(e)',
                    style: TextStyle(
                      color: AppPalette.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profile.filiere,
                  style: TextStyle(color: AppPalette.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.softYellow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(value: '4', label: 'Matieres'),
                      _StatItem(value: '4', label: 'Validees'),
                      _StatItem(value: '14.25', label: 'Moyenne'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppPalette.lightBlue),
                    borderRadius: BorderRadius.circular(18),
                    color: AppPalette.white,
                  ),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'INFORMATIONS PERSONNELLES',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      _profileTile(
                        Icons.person_outline,
                        'Nom complet',
                        '${profile.prenoms} ${profile.nom}',
                      ),
                      _profileTile(
                        Icons.badge_outlined,
                        'Identifiant',
                        profile.matricule,
                      ),
                      _profileTile(Icons.mail_outline, 'Email', profile.email),
                      _profileTile(
                        Icons.phone_outlined,
                        'Telephone',
                        profile.telephone,
                      ),
                      _profileTile(
                        Icons.school_outlined,
                        'Filiere',
                        profile.filiere,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onLogout,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.blue,
                      foregroundColor: AppPalette.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Se deconnecter'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(StudentProfile student) {
    final first = student.prenoms.isNotEmpty ? student.prenoms[0] : '';
    final second = student.nom.isNotEmpty ? student.nom[0] : '';
    return '$first$second'.toUpperCase();
  }

  Widget _profileTile(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppPalette.lightBlue)),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: AppPalette.lightBlue,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(icon, color: AppPalette.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppPalette.blue,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppPalette.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

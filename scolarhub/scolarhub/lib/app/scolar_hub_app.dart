import 'package:flutter/material.dart';

import '../models/student_profile.dart';
import '../pages/auth_page.dart';
import '../pages/student_shell.dart';
import '../theme/app_palette.dart';

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

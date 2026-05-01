import 'package:flutter/material.dart';
import 'models/student_profile.dart';
import 'pages/splash_screen.dart';
import 'pages/student_shell.dart';
import 'theme/app_palette.dart';

void main() {
  runApp(const ScolarHubApp());
}

class ScolarHubApp extends StatelessWidget {
  const ScolarHubApp({super.key});

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
      // On part toujours du splash — la navigation se fait par pushReplacement
      home: const SplashScreen(),
    );
  }
}

// ── Helper global pour aller au dashboard depuis n'importe quelle page ──────
void goToDashboard(BuildContext context, StudentProfile profile) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => StudentShell(
        profile: profile,
        onLogout: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (_) => false,
        ),
      ),
    ),
    (_) => false, // supprime toutes les pages précédentes
  );
}

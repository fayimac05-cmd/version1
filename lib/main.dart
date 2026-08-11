import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/scolar_hub_app.dart';
import 'models/student_profile.dart';
import 'pages/splash_screen.dart';
import 'pages/student_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Charger les variables d'environnement
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️  Impossible de charger .env : $e');
  }

  final supabaseUrl =
      dotenv.env['SUPABASE_URL'] ?? 'https://rsrmztmgyjoqjozhfgho.supabase.co';
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ??
      'sb_publishable_KD3tFiM13fv0wsNyIe3erA_K9OB54YO';

  // 2. Initialiser Supabase (sécurisé)
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseKey,
    );
    debugPrint('✅ Supabase initialisé : $supabaseUrl');
  } catch (e) {
    debugPrint('❌ Erreur Supabase init : $e');
  }

  // 3. Lancer l'application
  runApp(const ScolarHubApp());
}

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
    (_) => false,
  );
}

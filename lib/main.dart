import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/scolar_hub_app.dart';
import 'models/student_profile.dart';
import 'pages/splash_screen.dart';
import 'pages/student_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final chrono = Stopwatch()..start();

  // ⚡ L'écran d'accueil (vidéo + logo) n'a pas besoin de Supabase : on
  // l'affiche IMMÉDIATEMENT et on initialise le reste en arrière-plan.
  // Supabase n'est utilisé qu'après la connexion, bien plus tard.
  runApp(const ScolarHubApp());
  debugPrint('⏱ Première image lancée après ${chrono.elapsedMilliseconds} ms');

  await _initialiserServices(chrono);
}

Future<void> _initialiserServices(Stopwatch chrono) async {
  // 1. Charger les variables d'environnement
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️  Impossible de charger .env : $e');
  }

  // Lecture protégée : si le .env n'a pas pu être chargé (ex. hébergement web
  // qui ne publie pas les fichiers commençant par un point), dotenv.env
  // déclenche une erreur. On retombe alors sur les valeurs par défaut.
  String? lireEnv(String cle) {
    try {
      return dotenv.env[cle];
    } catch (_) {
      return null;
    }
  }

  final supabaseUrl =
      lireEnv('SUPABASE_URL') ?? 'https://rsrmztmgyjoqjozhfgho.supabase.co';
  final supabaseKey = lireEnv('SUPABASE_ANON_KEY') ??
      'sb_publishable_KD3tFiM13fv0wsNyIe3erA_K9OB54YO';

  // 2. Initialiser Supabase (sécurisé)
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseKey,
    );
    debugPrint('✅ Supabase initialisé en ${chrono.elapsedMilliseconds} ms : $supabaseUrl');
  } catch (e) {
    debugPrint('❌ Erreur Supabase init : $e');
  }
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
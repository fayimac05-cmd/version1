import 'package:flutter/material.dart';

import 'app/scolar_hub_app.dart';
import 'models/student_profile.dart';
import 'pages/splash_screen.dart';
import 'pages/student_shell.dart';

void main() {
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

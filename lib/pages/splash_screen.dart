import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import 'login_page.dart';
import 'register_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _goLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _goRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.white,
      body: Stack(
        children: [
          // Decorative blue shapes at top
          Positioned(
            top: -60,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0A4DA2),
              ),
            ),
          ),
          Positioned(
            top: -30,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1565C0).withValues(alpha: 0.7),
              ),
            ),
          ),
          // Small blue dot decoration
          Positioned(
            top: 60,
            right: 100,
            child: _dotGrid(),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // Logo
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppPalette.yellow,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: AppPalette.blue, size: 28),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Title
                    const Text(
                      'College\nManagement',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.black,
                        height: 1.2,
                      ),
                    ),
                    const Text(
                      'System',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.yellow,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Votre plateforme tout-en-un\npour la gestion académique',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),

                    const Spacer(),

                    // Illustration area
                    Center(
                      child: SizedBox(
                        height: 200,
                        child: _buildIllustration(),
                      ),
                    ),

                    const Spacer(),

                    // "Se connecter" button (filled)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _goLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.blue,
                          foregroundColor: AppPalette.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Se connecter',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            SizedBox(width: 12),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // "S'inscrire" button (outlined)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _goRegister,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppPalette.blue,
                          side: const BorderSide(
                              color: AppPalette.blue, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("S'inscrire",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            SizedBox(width: 12),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Version
                    const Center(
                      child: Text(
                        'Version 1.0.0',
                        style: TextStyle(fontSize: 12, color: AppPalette.grey),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dotGrid() {
    return SizedBox(
      width: 40,
      height: 40,
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          9,
          (_) => Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.blue.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background circle
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppPalette.lightBlue.withValues(alpha: 0.5),
          ),
        ),
        // Icon representation of the illustration
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.computer_rounded,
                size: 64, color: AppPalette.blue.withValues(alpha: 0.8)),
            const SizedBox(height: 8),
            Icon(Icons.person_outline_rounded,
                size: 48, color: AppPalette.midBlue.withValues(alpha: 0.7)),
          ],
        ),
        // Decorative checkmark
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF4CAF50),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}

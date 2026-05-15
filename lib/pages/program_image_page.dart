import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

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

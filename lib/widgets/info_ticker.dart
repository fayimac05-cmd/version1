import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class InfoTicker extends StatefulWidget {
  const InfoTicker({super.key});

  @override
  State<InfoTicker> createState() => _InfoTickerState();
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

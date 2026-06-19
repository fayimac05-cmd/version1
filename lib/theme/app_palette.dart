import 'package:flutter/material.dart';

class AppPalette {
  // Primary blues
  static const blue = Color(0xFF0A4DA2);
  static const darkBlue = Color(0xFF041A4D);
  static const midBlue = Color(0xFF1565C0);
  static const lightBlue = Color(0xFFEAF2FF);
  static const bgBlue = Color(0xFFE8F0FE);

  // Accent yellow/gold
  static const yellow = Color(0xFFF8C400);
  static const softYellow = Color(0xFFFFF5CC);

  // Neutrals
  static const white = Colors.white;
  static const black = Color(0xFF121212);
  static const grey = Color(0xFF64748B);
  static const lightGrey = Color(0xFFF1F5F9);
  static const borderGrey = Color(0xFFE2E8F0);

  // Gradients
  static const blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A4DA2), Color(0xFF1565C0)],
  );

  static const headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A4DA2), Color(0xFF1976D2)],
  );
}

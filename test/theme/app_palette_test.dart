import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scolarhub/theme/app_palette.dart';

void main() {
  group('AppPalette color constants', () {
    test('blue has correct hex value', () {
      expect(AppPalette.blue, const Color(0xFF0A4DA2));
    });

    test('yellow has correct hex value', () {
      expect(AppPalette.yellow, const Color(0xFFF8C400));
    });

    test('softYellow has correct hex value', () {
      expect(AppPalette.softYellow, const Color(0xFFFFF5CC));
    });

    test('lightBlue has correct hex value', () {
      expect(AppPalette.lightBlue, const Color(0xFFEAF2FF));
    });

    test('white is Colors.white', () {
      expect(AppPalette.white, Colors.white);
    });

    test('black has correct hex value', () {
      expect(AppPalette.black, const Color(0xFF121212));
    });
  });

  group('AppPalette color properties', () {
    test('blue is fully opaque', () {
      expect(AppPalette.blue.a, 1.0);
    });

    test('yellow is fully opaque', () {
      expect(AppPalette.yellow.a, 1.0);
    });

    test('all colors are non-transparent', () {
      final colors = [
        AppPalette.blue,
        AppPalette.yellow,
        AppPalette.softYellow,
        AppPalette.lightBlue,
        AppPalette.white,
        AppPalette.black,
      ];
      for (final color in colors) {
        expect(color.a, greaterThan(0.0));
      }
    });

    test('black is not pure black (custom dark)', () {
      expect(AppPalette.black, isNot(equals(Colors.black)));
    });
  });
}

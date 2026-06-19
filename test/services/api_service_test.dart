import 'package:flutter_test/flutter_test.dart';
import 'package:scolarhub/services/api_service.dart';

void main() {
  group('ApiService.login error handling', () {
    test('returns error map when server is unreachable (matricule)', () async {
      final result = await ApiService.login(
        matricule: 'MAT001',
        motDePasse: 'password123',
      );

      expect(result['success'], isFalse);
      expect(result['error'], isA<String>());
      expect(result['error'], contains('injoignable'));
    });

    test('returns error map when server is unreachable (nom/tel)', () async {
      final result = await ApiService.login(
        nom: 'Ouedraogo',
        tel: '70000001',
        motDePasse: 'password123',
      );

      expect(result['success'], isFalse);
      expect(result['error'], isA<String>());
    });
  });

  group('ApiService.setupPassword error handling', () {
    test('returns false when server is unreachable', () async {
      final result = await ApiService.setupPassword(
        userId: 'user_123',
        email: 'test@ist.bf',
        motDePasse: 'newpass',
      );

      expect(result, isFalse);
    });
  });

  group('ApiService.getEtudiants error handling', () {
    test('returns empty list when server is unreachable', () async {
      final result = await ApiService.getEtudiants();
      expect(result, isEmpty);
    });
  });

  group('ApiService.inscrireEtudiant error handling', () {
    test('returns error map when server is unreachable', () async {
      final result = await ApiService.inscrireEtudiant({
        'nom': 'Test',
        'prenoms': 'User',
        'matricule': 'T001',
      });

      expect(result['success'], isFalse);
      expect(result['error'], isA<String>());
    });
  });

  group('ApiService.getMe error handling', () {
    test('returns null when server is unreachable', () async {
      final result = await ApiService.getMe();
      expect(result, isNull);
    });
  });

  group('ApiService constants', () {
    test('baseUrl is defined and contains /api', () {
      expect(ApiService.baseUrl, isNotEmpty);
      expect(ApiService.baseUrl, contains('/api'));
    });

    test('baseUrl starts with http', () {
      expect(ApiService.baseUrl, startsWith('http'));
    });
  });
}

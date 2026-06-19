import 'package:flutter_test/flutter_test.dart';
import 'package:scolarhub/services/auth_service.dart';

void main() {
  group('AuthService.login error handling', () {
    test('returns error when server is unreachable (matricule login)', () async {
      final result = await AuthService.login(
        matricule: 'MAT001',
        motDePasse: 'password123',
      );

      expect(result['success'], isFalse);
      expect(result['error'], isA<String>());
      expect(result['error'], contains('injoignable'));
    });

    test('returns error when server is unreachable (nom/tel login)', () async {
      final result = await AuthService.login(
        nom: 'Ouedraogo',
        tel: '70000001',
        motDePasse: 'password123',
      );

      expect(result['success'], isFalse);
      expect(result['error'], isA<String>());
    });
  });

  group('AuthService.setupPassword error handling', () {
    test('returns false when server is unreachable', () async {
      final result = await AuthService.setupPassword(
        userId: 'user_123',
        email: 'test@ist.bf',
        motDePasse: 'newpass',
      );

      expect(result, isFalse);
    });
  });

  group('AuthService.getMe error handling', () {
    test('returns null when server is unreachable', () async {
      final result = await AuthService.getMe();
      expect(result, isNull);
    });
  });

  group('AuthService constants', () {
    test('baseUrl is defined', () {
      expect(AuthService.baseUrl, isNotEmpty);
      expect(AuthService.baseUrl, contains('/api'));
    });
  });
}

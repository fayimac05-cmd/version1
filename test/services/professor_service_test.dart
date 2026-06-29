import 'package:flutter_test/flutter_test.dart';
import 'package:scolarhub/services/professor_service.dart';

void main() {
  group('ProfessorService.getProfile fallback', () {
    test('returns map with success or error key', () async {
      final result = await ProfessorService.getProfile();
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success') || result.containsKey('data'), isTrue);
    });
  });

  group('ProfessorService.updateProfile error handling', () {
    test('returns a map response when server is unreachable', () async {
      final result = await ProfessorService.updateProfile({
        'email': 'new@ist.bf',
        'tel': '70111111',
      });
      expect(result, isA<Map<String, dynamic>>());
    });
  });

  group('ProfessorService.getClasses fallback', () {
    test('returns a map with success key', () async {
      final result = await ProfessorService.getClasses();
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
    });
  });

  group('ProfessorService.getModules fallback', () {
    test('returns a map with success key', () async {
      final result = await ProfessorService.getModules();
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
    });
  });

  group('ProfessorService.getAssignedClasses fallback', () {
    test('returns a map with success key', () async {
      final result = await ProfessorService.getAssignedClasses();
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
    });
  });

  group('ProfessorService.getStudentsByFiliere error handling', () {
    test('returns a map when server is unreachable', () async {
      final result = await ProfessorService.getStudentsByFiliere(1);
      expect(result, isA<Map<String, dynamic>>());
    });
  });

  group('ProfessorService.getCours fallback', () {
    test('returns a map with success key', () async {
      final result = await ProfessorService.getCours();
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
    });
  });

  group('ProfessorService.getGradeSessions fallback', () {
    test('returns a map with success key', () async {
      final result = await ProfessorService.getGradeSessions();
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
    });
  });

  group('ProfessorService.createGradeSession error handling', () {
    test('returns a map with success key', () async {
      final result = await ProfessorService.createGradeSession({
        'module_id': 1,
        'filiere_id': 1,
      });
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
    });
  });

  group('ProfessorService.markSessionSent error handling', () {
    test('returns a bool when server is unreachable', () async {
      final result = await ProfessorService.markSessionSent('1');
      expect(result, isA<bool>());
    });
  });

  group('ProfessorService constants', () {
    test('baseUrl is accessible and non-empty', () {
      expect(ProfessorService.baseUrl, isNotEmpty);
      expect(ProfessorService.baseUrl, contains('/api'));
    });
  });
}

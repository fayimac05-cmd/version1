import 'package:flutter_test/flutter_test.dart';
import 'package:scolarhub/services/professor_service.dart';

void main() {
  group('ProfessorService.getProfile fallback', () {
    test('returns mock profile when server is unreachable', () async {
      final result = await ProfessorService.getProfile();

      expect(result, isNotNull);
      expect(result!['prenoms'], isA<String>());
      expect(result['email'], isA<String>());
      expect(result['departement'], isA<String>());
      expect(result['specialite'], isA<String>());
    });

    test('mock profile has expected fields', () async {
      final result = await ProfessorService.getProfile();

      expect(result, isNotNull);
      expect(result!.containsKey('prenoms'), isTrue);
      expect(result.containsKey('email'), isTrue);
      expect(result.containsKey('tel'), isTrue);
      expect(result.containsKey('departement'), isTrue);
      expect(result.containsKey('specialite'), isTrue);
    });
  });

  group('ProfessorService.updateProfile error handling', () {
    test('returns false when server is unreachable', () async {
      final result = await ProfessorService.updateProfile({
        'email': 'new@ist.bf',
        'tel': '70111111',
      });

      expect(result, isFalse);
    });
  });

  group('ProfessorService.getClasses fallback', () {
    test('returns mock classes when server is unreachable', () async {
      final result = await ProfessorService.getClasses();

      expect(result, isNotEmpty);
      expect(result.length, greaterThanOrEqualTo(1));
    });

    test('mock classes have expected structure', () async {
      final result = await ProfessorService.getClasses();

      for (final cls in result) {
        expect(cls['id'], isA<int>());
        expect(cls['nom'], isA<String>());
        expect(cls['niveau'], isA<String>());
      }
    });
  });

  group('ProfessorService.getModules fallback', () {
    test('returns mock modules when server is unreachable', () async {
      final result = await ProfessorService.getModules();

      expect(result, isNotEmpty);
    });

    test('mock modules have expected structure', () async {
      final result = await ProfessorService.getModules();

      for (final mod in result) {
        expect(mod['id'], isA<int>());
        expect(mod['nom'], isA<String>());
      }
    });
  });

  group('ProfessorService.getAssignedClasses fallback', () {
    test('returns mock classes when server is unreachable', () async {
      final result = await ProfessorService.getAssignedClasses();

      expect(result, isNotEmpty);
    });
  });

  group('ProfessorService.getStudentsByFiliere error handling', () {
    test('returns empty list when server is unreachable', () async {
      final result = await ProfessorService.getStudentsByFiliere(1);

      expect(result, isEmpty);
    });
  });

  group('ProfessorService.getCours fallback', () {
    test('returns mock courses when server is unreachable', () async {
      final result = await ProfessorService.getCours();

      expect(result, isNotEmpty);
    });

    test('mock courses have expected structure', () async {
      final result = await ProfessorService.getCours();

      for (final cours in result) {
        expect(cours['id'], isA<int>());
        expect(cours['titre'], isA<String>());
        expect(cours['description'], isA<String>());
      }
    });
  });

  group('ProfessorService.getGradeSessions fallback', () {
    test('returns mock sessions when server is unreachable', () async {
      final result = await ProfessorService.getGradeSessions();

      expect(result, isNotEmpty);
    });

    test('mock sessions have expected structure', () async {
      final result = await ProfessorService.getGradeSessions();

      for (final session in result) {
        expect(session['id'], isA<int>());
        expect(session['module_nom'], isA<String>());
        expect(session['filiere_nom'], isA<String>());
        expect(session['is_sent'], isA<bool>());
        expect(session['date_session'], isA<String>());
      }
    });
  });

  group('ProfessorService.createGradeSession error handling', () {
    test('returns mock success when server is unreachable', () async {
      final result = await ProfessorService.createGradeSession({
        'module_id': 1,
        'filiere_id': 1,
      });

      // The service returns mock success on error
      expect(result['success'], isTrue);
      expect(result['session_id'], 999);
    });
  });

  group('ProfessorService.markSessionSent error handling', () {
    test('returns false when server is unreachable', () async {
      final result = await ProfessorService.markSessionSent('1');

      expect(result, isFalse);
    });
  });

  group('ProfessorService constants', () {
    test('baseUrl is accessible and non-empty', () {
      expect(ProfessorService.baseUrl, isNotEmpty);
      expect(ProfessorService.baseUrl, contains('/api'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:scolarhub/models/class_model.dart';
import 'package:scolarhub/models/student_profile.dart';

void main() {
  group('ClassModel construction', () {
    test('creates with required fields and default isActive=true', () {
      const model = ClassModel(
        id: 'CLS001',
        name: 'Licence 2 Informatique',
        level: 'L2',
        students: [],
      );

      expect(model.id, 'CLS001');
      expect(model.name, 'Licence 2 Informatique');
      expect(model.level, 'L2');
      expect(model.students, isEmpty);
      expect(model.isActive, isTrue);
    });

    test('creates with isActive=false', () {
      const model = ClassModel(
        id: 'CLS002',
        name: 'Master 1 Cyber',
        level: 'M1',
        students: [],
        isActive: false,
      );

      expect(model.isActive, isFalse);
    });

    test('creates with a list of students', () {
      const students = [
        StudentProfile(
          nom: 'Ouedraogo',
          prenoms: 'Issa',
          matricule: 'MAT001',
          email: 'issa@ist.bf',
          telephone: '70000001',
          filiere: 'Informatique',
          motDePasse: 'pass123',
        ),
        StudentProfile(
          nom: 'Traore',
          prenoms: 'Fatou',
          matricule: 'MAT002',
          email: 'fatou@ist.bf',
          telephone: '70000002',
          filiere: 'Informatique',
          motDePasse: 'pass456',
        ),
      ];

      const model = ClassModel(
        id: 'CLS003',
        name: 'Licence 3 Info',
        level: 'L3',
        students: students,
      );

      expect(model.students.length, 2);
      expect(model.students[0].nom, 'Ouedraogo');
      expect(model.students[1].nom, 'Traore');
    });

    test('students list maintains order', () {
      const students = [
        StudentProfile(
          nom: 'Zongo',
          prenoms: 'A',
          matricule: 'M1',
          email: 'a@ist.bf',
          telephone: '1',
          filiere: 'Info',
          motDePasse: 'p',
        ),
        StudentProfile(
          nom: 'Alpha',
          prenoms: 'B',
          matricule: 'M2',
          email: 'b@ist.bf',
          telephone: '2',
          filiere: 'Info',
          motDePasse: 'p',
        ),
        StudentProfile(
          nom: 'Moyen',
          prenoms: 'C',
          matricule: 'M3',
          email: 'c@ist.bf',
          telephone: '3',
          filiere: 'Info',
          motDePasse: 'p',
        ),
      ];

      const model = ClassModel(
        id: 'CLS004',
        name: 'Test Class',
        level: 'L1',
        students: students,
      );

      expect(model.students[0].nom, 'Zongo');
      expect(model.students[1].nom, 'Alpha');
      expect(model.students[2].nom, 'Moyen');
    });

    test('empty class has zero students', () {
      const model = ClassModel(
        id: 'EMPTY',
        name: 'Empty Class',
        level: 'L1',
        students: [],
      );

      expect(model.students, isEmpty);
      expect(model.students.length, 0);
    });
  });
}

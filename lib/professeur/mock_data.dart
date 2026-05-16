import 'dart:math';

import '../models/class_model.dart';
import '../models/student_profile.dart';

final List<ClassModel> mockClasses = _generateMockClasses();

List<ClassModel> _generateMockClasses() {
  final random = Random(42); // Seeded for consistent results

  final firstNames = [
    'Alice', 'Thomas', 'Laura', 'Kevin', 'Marie', 'Jean', 'Sophie', 'Paul',
    'Luc', 'Emma', 'Hugo', 'Julie', 'Antoine', 'Sarah', 'Nicolas', 'Camille',
    'Maxime', 'Chloe', 'Alexandre', 'Lea', 'Julien', 'Manon', 'Romain', 'Celine',
    'Arthur', 'Mathilde', 'Bastien', 'Elodie', 'Florian', 'Marine'
  ];

  final lastNames = [
    'Dubois', 'Roux', 'Vincent', 'Lefebvre', 'Dupont', 'Martin', 'Durand',
    'Moreau', 'Leroy', 'Simon', 'Laurent', 'Michel', 'Garcia', 'David',
    'Bertrand', 'Roussel', 'Girard', 'Andre', 'Mercier', 'Blanc', 'Guerin',
    'Boyer', 'Garnier', 'Chevalier', 'Francois', 'Legrand', 'Gauthier'
  ];

  final classDefinitions = [
    {'name': 'Licence 1 Informatique', 'level': 'L1'},
    {'name': 'Licence 2 Réseaux & Télécom', 'level': 'L2'},
    {'name': 'Licence 3 Développement Web', 'level': 'L3'},
    {'name': 'Master 1 CyberSécurité', 'level': 'M1'},
    {'name': 'Master 2 IA & Data Science', 'level': 'M2'},
    {'name': 'Prépa Ingénieur', 'level': 'Année 1'},
    {'name': 'Licence Pro E-commerce', 'level': 'L3'},
  ];

  return classDefinitions.asMap().entries.map((entry) {
    final classIndex = entry.key;
    final classDef = entry.value;
    
    // Generate between 22 and 28 students per class
    final studentCount = 22 + random.nextInt(7);
    
    final students = List.generate(studentCount, (studentIndex) {
      final firstName = firstNames[random.nextInt(firstNames.length)];
      final lastName = lastNames[random.nextInt(lastNames.length)];
      final matricule = 'MAT${2024000 + classIndex * 100 + studentIndex}';
      
      return StudentProfile(
        nom: lastName,
        prenoms: firstName,
        matricule: matricule,
        email: '${firstName.toLowerCase()}.${lastName.toLowerCase()}@scholarhub.edu',
        telephone: '0${600000000 + random.nextInt(99999999)}',
        filiere: classDef['name']!,
        motDePasse: '',
      );
    });

    // Sort students alphabetically
    students.sort((a, b) => a.nom.compareTo(b.nom));

    return ClassModel(
      id: 'class_$classIndex',
      name: classDef['name']!,
      level: classDef['level']!,
      students: students,
      isActive: true,
    );
  }).toList();
}

class AttendanceSession {
  final String id;
  final String classId;
  final String className;
  final DateTime date;
  final int presentCount;
  final int totalCount;

  AttendanceSession({
    required this.id,
    required this.classId,
    required this.className,
    required this.date,
    required this.presentCount,
    required this.totalCount,
  });
}

class StudentGrade {
  final String matricule;
  final String name;
  final double? note1;
  final double? note2;

  StudentGrade({
    required this.matricule,
    required this.name,
    this.note1,
    this.note2,
  });
}

class GradeSession {
  final String id;
  final String classId;
  final String className;
  final DateTime date;
  final String moduleName;
  final double coefficient;
  final List<StudentGrade> grades;
  bool isSent;

  GradeSession({
    required this.id,
    required this.classId,
    required this.className,
    required this.date,
    required this.moduleName,
    this.coefficient = 1.0,
    required this.grades,
    this.isSent = false,
  });
}

class GlobalStore {
  static final List<AttendanceSession> attendanceHistory = [];
  static final List<GradeSession> gradeSessions = [];
}

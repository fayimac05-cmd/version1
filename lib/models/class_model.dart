import 'student_profile.dart';

class ClassModel {
  const ClassModel({
    required this.id,
    required this.name,
    required this.level,
    required this.students,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String level;
  final List<StudentProfile> students;
  final bool isActive;
}

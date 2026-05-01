import 'package:flutter/material.dart';

import '../widgets/simple_info_tab.dart';

class CoursesTab extends StatelessWidget {
  const CoursesTab({super.key});

  static const _courses = [
    'Algorithmique & Structures de Donnees',
    'Bases de Donnees',
    'Programmation Orientee Objet',
    'Reseaux Informatiques',
    'Mathematiques Discretes',
    'Anglais Technique',
  ];

  @override
  Widget build(BuildContext context) {
    return const SimpleInfoTab(
      title: 'Cours',
      icon: Icons.menu_book_outlined,
      items: _courses,
    );
  }
}

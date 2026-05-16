import 'package:flutter/material.dart';

import '../models/class_model.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import 'confirm_screens.dart';
import 'mock_data.dart';

class ClassDetailScreen extends StatefulWidget {
  const ClassDetailScreen({super.key, required this.classData});

  final ClassModel classData;

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  // Mock state for attendance (true = present)
  late Map<String, bool> _attendance;
  
  // Mock state for grades
  late Map<String, TextEditingController> _grade1Controllers;
  late Map<String, TextEditingController> _grade2Controllers;
  final TextEditingController _moduleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _attendance = {
      for (var student in widget.classData.students) student.matricule: true
    };
    _grade1Controllers = {
      for (var student in widget.classData.students)
        student.matricule: TextEditingController()
    };
    _grade2Controllers = {
      for (var student in widget.classData.students)
        student.matricule: TextEditingController()
    };
  }

  @override
  void dispose() {
    for (var controller in _grade1Controllers.values) {
      controller.dispose();
    }
    for (var controller in _grade2Controllers.values) {
      controller.dispose();
    }
    _moduleController.dispose();
    super.dispose();
  }

  void _submitAttendance() {
    final presentList = widget.classData.students
        .where((s) => _attendance[s.matricule] == true)
        .toList();
    final absentList = widget.classData.students
        .where((s) => _attendance[s.matricule] == false)
        .toList();

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: AttendanceConfirmScreen(
            className: widget.classData.name,
            presentList: presentList,
            absentList: absentList,
            onConfirm: () {
              GlobalStore.attendanceHistory.add(
                AttendanceSession(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  classId: widget.classData.id,
                  className: widget.classData.name,
                  date: DateTime.now(),
                  presentCount: presentList.length,
                  totalCount: widget.classData.students.length,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _submitGrades() {
    if (_moduleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez entrer le nom du module.'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    List<StudentGrade> grades = widget.classData.students.map((student) {
      final n1 = double.tryParse(_grade1Controllers[student.matricule]!.text.replaceAll(',', '.'));
      final n2 = double.tryParse(_grade2Controllers[student.matricule]!.text.replaceAll(',', '.'));
      return StudentGrade(
        matricule: student.matricule,
        name: '${student.prenoms} ${student.nom}',
        note1: n1,
        note2: n2,
      );
    }).toList();

    final session = GradeSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      classId: widget.classData.id,
      className: widget.classData.name,
      date: DateTime.now(),
      moduleName: _moduleController.text.trim(),
      grades: grades,
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: GradeConfirmScreen(
            session: session,
            onConfirm: () {
              GlobalStore.gradeSessions.add(session);
            },
          ),
        ),
      ),
    );
  }

  void _showAttendanceHistory() {
    final history = GlobalStore.attendanceHistory
        .where((h) => h.classId == widget.classData.id)
        .toList();
        
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Historique des appels',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (history.isEmpty)
                const Center(child: Text('Aucun appel enregistré.'))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final session = history[index];
                      return ListTile(
                        leading: const Icon(Icons.history, color: AppPalette.blue),
                        title: Text('${session.date.day}/${session.date.month}/${session.date.year} à ${session.date.hour}h${session.date.minute.toString().padLeft(2, '0')}'),
                        subtitle: Text('${session.presentCount} présents sur ${session.totalCount}'),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 220.0,
                pinned: true,
                backgroundColor: AppPalette.white,
                foregroundColor: AppPalette.black,
                elevation: innerBoxIsScrolled ? 4 : 0,
                shadowColor: Colors.black.withOpacity(0.3),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFEAF2FF), Color(0xFFF8FAFC)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),
                          Hero(
                            tag: 'class_icon_${widget.classData.id}',
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEAF2FF), Color(0xFFD3E4FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppPalette.blue.withOpacity(0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.school_rounded, color: AppPalette.blue, size: 34),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Hero(
                            tag: 'class_title_${widget.classData.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                widget.classData.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.classData.level} • ${widget.classData.students.length} étudiants',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                bottom: const TabBar(
                  labelColor: AppPalette.blue,
                  unselectedLabelColor: Color(0xFF64748B),
                  indicatorColor: AppPalette.blue,
                  indicatorWeight: 3,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(icon: Icon(Icons.fact_check_rounded), text: 'Présences'),
                    Tab(icon: Icon(Icons.edit_note_rounded), text: 'Notes'),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildAttendanceTab(),
              _buildGradesTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, right: 16, left: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _showAttendanceHistory,
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('Historique'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppPalette.blue,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                itemCount: widget.classData.students.length,
                itemBuilder: (context, index) {
                  final student = widget.classData.students[index];
                  final isPresent = _attendance[student.matricule] ?? true;
                  return _AnimatedListItem(
                    index: index,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppPalette.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: isPresent 
                              ? AppPalette.lightBlue 
                              : const Color(0xFFFEE2E2),
                            child: Text(
                              student.nom[0],
                              style: TextStyle(
                                color: isPresent ? AppPalette.blue : const Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              '${student.prenoms} ${student.nom}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Switch(
                            value: isPresent,
                            activeColor: AppPalette.blue,
                            inactiveTrackColor: const Color(0xFFE2E8F0),
                            inactiveThumbColor: const Color(0xFF94A3B8),
                            onChanged: (val) {
                              setState(() {
                                _attendance[student.matricule] = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: _FloatingActionButton(
            label: 'Valider l\'appel',
            icon: Icons.check_circle_rounded,
            onPressed: _submitAttendance,
          ),
        ),
      ],
    );
  }

  Widget _buildGradesTab() {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _moduleController,
                decoration: InputDecoration(
                  labelText: 'Nom du module (ex: Réseaux, Programmation)',
                  prefixIcon: const Icon(Icons.menu_book_rounded),
                  filled: true,
                  fillColor: AppPalette.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                itemCount: widget.classData.students.length,
                itemBuilder: (context, index) {
                  final student = widget.classData.students[index];
                  return _AnimatedListItem(
                    index: index,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppPalette.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppPalette.lightBlue,
                                child: Text(
                                  student.nom[0],
                                  style: const TextStyle(
                                    color: AppPalette.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  '${student.prenoms} ${student.nom}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _grade1Controllers[student.matricule],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    color: AppPalette.blue,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Note 1',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppPalette.blue, width: 2)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _grade2Controllers[student.matricule],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    color: AppPalette.blue,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Note 2',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppPalette.blue, width: 2)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: _FloatingActionButton(
            label: 'Enregistrer les notes',
            icon: Icons.save_rounded,
            onPressed: _submitGrades,
          ),
        ),
      ],
    );
  }
}

class _AnimatedListItem extends StatelessWidget {
  const _AnimatedListItem({required this.child, required this.index});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Interval(
        (index * 0.05).clamp(0.0, 1.0),
        1.0,
        curve: Curves.easeOutQuart,
      ),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _FloatingActionButton extends StatelessWidget {
  const _FloatingActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppPalette.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 22),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppPalette.blue,
            foregroundColor: AppPalette.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

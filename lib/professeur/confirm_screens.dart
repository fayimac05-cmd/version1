import 'package:flutter/material.dart';

import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import 'mock_data.dart';

// ─────────────────────────────────────────
// Page de confirmation d'appel
// ─────────────────────────────────────────
class AttendanceConfirmScreen extends StatelessWidget {
  const AttendanceConfirmScreen({
    super.key,
    required this.className,
    required this.presentList,
    required this.absentList,
    required this.onConfirm,
  });

  final String className;
  final List<StudentProfile> presentList;
  final List<StudentProfile> absentList;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Confirmer l\'appel', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppPalette.white,
        foregroundColor: AppPalette.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEAF2FF), Color(0xFFD3E4FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.fact_check_rounded, color: AppPalette.blue, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          className,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StatChip(label: '${presentList.length} présents', color: const Color(0xFF15803D), bg: const Color(0xFFDCFCE7)),
                            const SizedBox(width: 12),
                            _StatChip(label: '${absentList.length} absents', color: const Color(0xFFDC2626), bg: const Color(0xFFFEE2E2)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Présents
                  if (presentList.isNotEmpty) ...[
                    _SectionTitle(icon: Icons.check_circle_rounded, label: 'Présents (${presentList.length})', color: const Color(0xFF15803D)),
                    const SizedBox(height: 10),
                    ...presentList.asMap().entries.map((e) => _ConfirmStudentTile(
                      name: '${e.value.prenoms} ${e.value.nom}',
                      index: e.key,
                      isPresent: true,
                    )),
                  ],

                  const SizedBox(height: 16),

                  // Absents
                  if (absentList.isNotEmpty) ...[
                    _SectionTitle(icon: Icons.cancel_rounded, label: 'Absents (${absentList.length})', color: const Color(0xFFDC2626)),
                    const SizedBox(height: 10),
                    ...absentList.asMap().entries.map((e) => _ConfirmStudentTile(
                      name: '${e.value.prenoms} ${e.value.nom}',
                      index: e.key,
                      isPresent: false,
                    )),
                  ],
                ],
              ),
            ),
          ),
          // Bouton confirmer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppPalette.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded, size: 22),
                label: const Text('Confirmer l\'appel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.blue,
                  foregroundColor: AppPalette.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () {
                  onConfirm();
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 400),
                      pageBuilder: (context, animation, _) => FadeTransition(
                        opacity: animation,
                        child: const _SuccessScreen(
                          title: 'Appel enregistré !',
                          subtitle: 'La liste de présence a été sauvegardée avec succès dans l\'historique.',
                          icon: Icons.how_to_reg_rounded,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Page de confirmation des notes
// ─────────────────────────────────────────
class GradeConfirmScreen extends StatefulWidget {
  const GradeConfirmScreen({super.key, required this.session, required this.onConfirm});

  final GradeSession session;
  final VoidCallback onConfirm;

  @override
  State<GradeConfirmScreen> createState() => _GradeConfirmScreenState();
}

class _GradeConfirmScreenState extends State<GradeConfirmScreen> {
  late List<StudentGrade> _editableGrades;
  late List<TextEditingController> _note1Controllers;
  late List<TextEditingController> _note2Controllers;

  @override
  void initState() {
    super.initState();
    _editableGrades = List.from(widget.session.grades);
    _note1Controllers = _editableGrades
        .map((g) => TextEditingController(text: g.note1?.toString() ?? ''))
        .toList();
    _note2Controllers = _editableGrades
        .map((g) => TextEditingController(text: g.note2?.toString() ?? ''))
        .toList();
  }

  @override
  void dispose() {
    for (var c in _note1Controllers) { c.dispose(); }
    for (var c in _note2Controllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Vérifier les notes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppPalette.white,
        foregroundColor: AppPalette.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEAF2FF), Color(0xFFD3E4FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.edit_note_rounded, color: AppPalette.blue, size: 36),
                        const SizedBox(height: 10),
                        Text(widget.session.className, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Module : ${widget.session.moduleName}', style: const TextStyle(color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Text('${_editableGrades.length} étudiants — modifiable avant envoi', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...List.generate(_editableGrades.length, (i) {
                    final grade = _editableGrades[i];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Interval((i * 0.04).clamp(0.0, 1.0), 1.0, curve: Curves.easeOut),
                      builder: (context, val, child) => Opacity(
                        opacity: val,
                        child: Transform.translate(offset: Offset(0, 20 * (1 - val)), child: child),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppPalette.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppPalette.lightBlue,
                                  child: Text(grade.name[0], style: const TextStyle(color: AppPalette.blue, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(grade.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _note1Controllers[i],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppPalette.blue),
                                    decoration: InputDecoration(
                                      labelText: 'Note 1',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppPalette.blue, width: 2)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _note2Controllers[i],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppPalette.blue),
                                    decoration: InputDecoration(
                                      labelText: 'Note 2',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppPalette.blue, width: 2)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          // Bouton confirmer et envoyer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppPalette.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send_rounded, size: 22),
                label: const Text('Confirmer et enregistrer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.blue,
                  foregroundColor: AppPalette.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () {
                  // Apply any edited grades before saving
                  for (int i = 0; i < _editableGrades.length; i++) {
                    widget.session.grades[i] = StudentGrade(
                      matricule: _editableGrades[i].matricule,
                      name: _editableGrades[i].name,
                      note1: double.tryParse(_note1Controllers[i].text.replaceAll(',', '.')),
                      note2: double.tryParse(_note2Controllers[i].text.replaceAll(',', '.')),
                    );
                  }
                  widget.onConfirm();
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 400),
                      pageBuilder: (context, animation, _) => FadeTransition(
                        opacity: animation,
                        child: const _SuccessScreen(
                          title: 'Notes enregistrées !',
                          subtitle: 'Vos notes ont été enregistrées et sont disponibles dans l\'onglet "Notes en attente" pour envoi à l\'administration.',
                          icon: Icons.task_alt_rounded,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Page de succès animée
// ─────────────────────────────────────────
class _SuccessScreen extends StatefulWidget {
  const _SuccessScreen({required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  State<_SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<_SuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 52),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          // Pop back to class detail
                          int count = 0;
                          Navigator.of(context).popUntil((_) => count++ >= 2);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Retour à la classe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Widgets helpers
// ─────────────────────────────────────────
class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.color, required this.bg});

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
      ],
    );
  }
}

class _ConfirmStudentTile extends StatelessWidget {
  const _ConfirmStudentTile({required this.name, required this.index, required this.isPresent});

  final String name;
  final int index;
  final bool isPresent;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Interval((index * 0.04).clamp(0.0, 1.0), 1.0, curve: Curves.easeOut),
      builder: (context, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(offset: Offset(0, 20 * (1 - val)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isPresent ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isPresent ? const Color(0xFF15803D) : const Color(0xFFDC2626),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

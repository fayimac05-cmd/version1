import 'package:flutter/material.dart';
import '../services/professor_service.dart';
import '../theme/app_palette.dart';

class GradeSessionScreen extends StatefulWidget {
  const GradeSessionScreen({super.key});

  @override
  State<GradeSessionScreen> createState() => _GradeSessionScreenState();
}

class _GradeSessionScreenState extends State<GradeSessionScreen> {
  List<dynamic> _classes = [];
  List<dynamic> _modules = [];
  List<dynamic> _students = [];
  bool _isLoading = true;
  bool _isSaving = false;

  String? _selectedClassId;
  String? _selectedClassName;
  String? _selectedNiveau;
  String? _selectedModuleId;

  // matricule -> note string
  final Map<String, String> _notes = {};

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final classes = await ProfessorService.getClasses();
    final modules = await ProfessorService.getModules();
    setState(() {
      _classes = classes;
      _modules = modules;
      _isLoading = false;
    });
  }

  Future<void> _fetchStudents() async {
    if (_selectedClassId == null) return;
    setState(() {
      _isLoading = true;
      _students = [];
      _notes.clear();
    });
    final students = await ProfessorService.getStudentsByFiliere(int.parse(_selectedClassId!));
    setState(() {
      _students = students;
      _isLoading = false;
    });
  }

  Future<void> _saveSession() async {
    if (_selectedClassId == null || _selectedModuleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner classe et module.')));
      return;
    }

    setState(() => _isSaving = true);

    final notesData = _students.map((s) {
      return {
        'matricule': s['matricule'],
        'valeur': double.tryParse(_notes[s['matricule']] ?? '') ?? 0.0,
      };
    }).toList();

    final res = await ProfessorService.createGradeSession({
      'filiere_id': int.parse(_selectedClassId!),
      'filiere_nom': _selectedClassName,
      'niveau': _selectedNiveau,
      'module_id': int.parse(_selectedModuleId!),
      'notes': notesData,
    });

    setState(() => _isSaving = false);

    if (res['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session de notes créée avec succès !')));
      Navigator.of(context).pop(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'] ?? 'Erreur lors de la sauvegarde.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle Session de Notes')),
      body: _isLoading && _classes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Classe / Filière', border: OutlineInputBorder()),
                        items: _classes.map<DropdownMenuItem<String>>((c) {
                          return DropdownMenuItem<String>(
                            value: c['id'].toString(),
                            child: Text('${c['nom']} - ${c['niveau']}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          final c = _classes.firstWhere((x) => x['id'].toString() == val);
                          setState(() {
                            _selectedClassId = val;
                            _selectedClassName = c['nom'];
                            _selectedNiveau = c['niveau'];
                          });
                          _fetchStudents();
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Module', border: OutlineInputBorder()),
                        items: _modules.map<DropdownMenuItem<String>>((m) {
                          return DropdownMenuItem<String>(
                            value: m['id'].toString(),
                            child: Text(m['nom']),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedModuleId = val),
                      ),
                    ],
                  ),
                ),
                if (_isLoading) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
                if (!_isLoading && _students.isNotEmpty)
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _students.length,
                      separatorBuilder: (c, i) => const Divider(),
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final matricule = student['matricule'];
                        return Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${student['prenoms']} ${student['nom']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(matricule, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  hintText: '/20',
                                ),
                                onChanged: (val) => _notes[matricule] = val,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                if (!_isLoading && _students.isEmpty && _selectedClassId != null)
                  const Expanded(child: Center(child: Text('Aucun étudiant trouvé dans cette classe.'))),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveSession,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppPalette.blue,
              foregroundColor: Colors.white,
            ),
            child: _isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Enregistrer les notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

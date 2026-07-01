import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/professor_service.dart';
import '../theme/app_palette.dart';

class UploadCourseScreen extends StatefulWidget {
  const UploadCourseScreen({super.key});

  @override
  State<UploadCourseScreen> createState() => _UploadCourseScreenState();
}

class _UploadCourseScreenState extends State<UploadCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _title;
  String? _description;
  String? _selectedFiliereId;
  String? _selectedFiliereNom;
  String? _selectedModuleId;
  String? _filePath;

  List<dynamic> _filieres = [];
  List<dynamic> _modules = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final filieresResult = await ProfessorService.getClasses();
    final modulesResult = await ProfessorService.getModules();
    setState(() {
      _filieres = filieresResult['success'] == true ? (filieresResult['data'] as List<dynamic>) : [];
      _modules = modulesResult['success'] == true ? (modulesResult['data'] as List<dynamic>) : [];
      _isLoading = false;
    });
    if (mounted) {
      if (filieresResult['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(filieresResult['error'] ?? 'Erreur chargement filières'), backgroundColor: Colors.red),
        );
      }
      if (modulesResult['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(modulesResult['error'] ?? 'Erreur chargement modules'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      setState(() => _filePath = result.files.first.path);
    }
  }

  Future<void> _upload() async {
    if (!(_formKey.currentState?.validate() ?? false) || _filePath == null) return;
    _formKey.currentState?.save();
    setState(() => _isLoading = true);
    final response = await ProfessorService.uploadCours(
      titre: _title!,
      description: _description!,
      filiereId: _selectedFiliereId!,
      filiereNom: _selectedFiliereNom!,
      niveau: '', // you can extend to choose level if needed
      moduleId: _selectedModuleId!,
      filePath: _filePath!,
    );
    setState(() => _isLoading = false);
    if (mounted) {
      final success = response['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Cours téléchargé avec succès' : 'Échec du téléchargement'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
      if (success) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Téléverser un cours'),
        backgroundColor: AppPalette.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Titre du cours'),
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                      onSaved: (v) => _title = v,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                      onSaved: (v) => _description = v,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Filière'),
                      items: _filieres
                          .map<DropdownMenuItem<String>>((f) => DropdownMenuItem<String>(
                                value: f['id'].toString(),
                                child: Text(f['nom']),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedFiliereId = val;
                          final filiere = _filieres.firstWhere((f) => f['id'].toString() == val);
                          _selectedFiliereNom = filiere['nom'];
                        });
                      },
                      validator: (v) => v == null ? 'Sélectionnez une filière' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Module'),
                      items: _modules
                          .map<DropdownMenuItem<String>>((m) => DropdownMenuItem<String>(
                                value: m['id'].toString(),
                                child: Text(m['nom']),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedModuleId = val),
                      validator: (v) => v == null ? 'Sélectionnez un module' : null,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: Text(_filePath == null ? 'Choisir un fichier' : 'Fichier sélectionné'),
                      onPressed: _pickFile,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppPalette.blue),
                      onPressed: _upload,
                      child: const Text('Uploader le cours'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

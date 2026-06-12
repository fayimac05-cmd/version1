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
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<dynamic> _classes = [];
  List<dynamic> _modules = [];
  bool _isLoading = true;
  bool _isUploading = false;

  String? _selectedClassId;
  String? _selectedClassName;
  String? _selectedNiveau;
  String? _selectedModuleId;
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final classes = await ProfessorService.getClasses();
    final modules = await ProfessorService.getModules();
    setState(() {
      _classes = classes;
      _modules = modules;
      _isLoading = false;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
    );
    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez choisir une classe')));
      return;
    }
    if (_selectedModuleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez choisir un module')));
      return;
    }
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez choisir un fichier')));
      return;
    }

    setState(() => _isUploading = true);

    final res = await ProfessorService.uploadCours(
      titre: _titreCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      filiereId: _selectedClassId!,
      filiereNom: _selectedClassName!,
      niveau: _selectedNiveau!,
      moduleId: _selectedModuleId!,
      filePath: _selectedFile!.path!,
    );

    setState(() => _isUploading = false);

    if (res['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cours uploadé avec succès')));
      Navigator.of(context).pop(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'] ?? 'Erreur')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publier un cours')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titreCtrl,
                      decoration: const InputDecoration(labelText: 'Titre du cours', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(labelText: 'Description (optionnel)', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
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
                      },
                      validator: (v) => v == null ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Module', border: OutlineInputBorder()),
                      items: _modules.map<DropdownMenuItem<String>>((m) {
                        return DropdownMenuItem<String>(
                          value: m['id'].toString(),
                          child: Text(m['nom']),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedModuleId = val),
                      validator: (v) => v == null ? 'Requis' : null,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_selectedFile != null ? _selectedFile!.name : 'Sélectionner un fichier (PDF, PPT...)'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isUploading ? null : _upload,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppPalette.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Publier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

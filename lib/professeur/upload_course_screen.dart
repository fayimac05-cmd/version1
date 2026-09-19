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

  // ✅ NOUVEAU — le module doit être limité à ceux réellement affectés à ce
  // professeur POUR la filière + niveau choisis dans le premier dropdown.
  // Auparavant le dropdown Module utilisait _modules brut (tous niveaux
  // confondus), ce qui pouvait afficher/planter avec des doublons (même
  // module affecté à deux niveaux différents => même valeur en double).
  List<dynamic> get _modulesFiltres {
    if (_selectedClassId == null || _selectedNiveau == null) return const [];
    return _modules.where((m) =>
        m['filiere_id']?.toString() == _selectedClassId &&
        m['niveau']?.toString() == _selectedNiveau).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final classesResult = await ProfessorService.getClasses();
    final modulesResult = await ProfessorService.getModules();
    setState(() {
      _classes = classesResult['success'] == true ? (classesResult['data'] as List<dynamic>) : [];
      _modules = modulesResult['success'] == true ? (modulesResult['data'] as List<dynamic>) : [];
      _isLoading = false;
    });
    if (mounted) {
      if (classesResult['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(classesResult['error'] ?? 'Erreur chargement classes'), backgroundColor: Colors.red),
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
      withData: true, // important pour le web : charge les bytes en mémoire
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

    final fileBytes = (_selectedFile!.bytes ?? <int>[]) as List<int>;
    if (fileBytes.isEmpty) {
      setState(() => _isUploading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de lire le fichier. Réessayez.'), backgroundColor: Colors.red));
      return;
    }

    final res = await ProfessorService.uploadCours(
      titre: _titreCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      filiereId: _selectedClassId!,
      filiereNom: _selectedClassName!,
      niveau: _selectedNiveau!,
      moduleId: _selectedModuleId!,
      fileBytes: fileBytes,
      fileName: _selectedFile!.name,
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
                          value: '${c['id']}_${c['niveau']}',
                          child: Text('${c['nom']} - ${c['niveau']}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        final c = _classes.firstWhere((x) => '${x['id']}_${x['niveau']}' == val);
                        setState(() {
                          _selectedClassId = c['id'].toString();
                          _selectedClassName = c['nom'];
                          _selectedNiveau = c['niveau'];
                          // Le module valable dépend de la filière+niveau ;
                          // on réinitialise pour éviter une valeur devenue
                          // invalide (voir _modulesFiltres).
                          _selectedModuleId = null;
                        });
                      },
                      validator: (v) => v == null ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey('module_${_selectedClassId}_$_selectedNiveau'),
                      decoration: InputDecoration(
                        labelText: 'Module',
                        border: const OutlineInputBorder(),
                        helperText: _selectedClassId == null
                            ? 'Choisissez d\'abord une filière'
                            : (_modulesFiltres.isEmpty ? 'Aucun module affecté pour ce niveau' : null),
                      ),
                      items: _modulesFiltres.map<DropdownMenuItem<String>>((m) {
                        return DropdownMenuItem<String>(
                          value: m['id'].toString(),
                          child: Text(m['nom']),
                        );
                      }).toList(),
                      onChanged: _modulesFiltres.isEmpty ? null : (val) => setState(() => _selectedModuleId = val),
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
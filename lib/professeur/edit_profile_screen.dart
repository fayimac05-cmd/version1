import 'package:flutter/material.dart';
import '../services/professor_service.dart';
import '../theme/app_palette.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentProfile;
  const EditProfileScreen({super.key, required this.currentProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomCtrl;
  late TextEditingController _prenomsCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _telCtrl;
  late TextEditingController _specialiteCtrl;
  late TextEditingController _departementCtrl;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.currentProfile['nom'] ?? '');
    _prenomsCtrl = TextEditingController(text: widget.currentProfile['prenoms'] ?? '');
    _emailCtrl = TextEditingController(text: widget.currentProfile['email'] ?? '');
    _telCtrl = TextEditingController(text: widget.currentProfile['tel'] ?? '');
    _specialiteCtrl = TextEditingController(text: widget.currentProfile['specialite'] ?? '');
    _departementCtrl = TextEditingController(text: widget.currentProfile['departement'] ?? '');
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    
    final success = await ProfessorService.updateProfile({
      'nom': _nomCtrl.text.trim(),
      'prenoms': _prenomsCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'tel': _telCtrl.text.trim(),
      'specialite': _specialiteCtrl.text.trim(),
      'departement': _departementCtrl.text.trim(),
    });
    
    setState(() => _isSaving = false);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil mis à jour')));
      Navigator.of(context).pop(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la mise à jour')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prenomsCtrl,
                decoration: const InputDecoration(labelText: 'Prénoms', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telCtrl,
                decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specialiteCtrl,
                decoration: const InputDecoration(labelText: 'Spécialité', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departementCtrl,
                decoration: const InputDecoration(labelText: 'Département', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppPalette.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Sauvegarder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

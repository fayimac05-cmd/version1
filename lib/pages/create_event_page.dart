import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../theme/app_palette.dart';
import '../models/event.dart';
import '../services/api_service.dart';
class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _capaciteController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  XFile? _selectedImage;
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _selectedImage = picked);
    }
  }

  static const primaryBlue = AppPalette.blue;
  static const textDark = Color(0xFF0F172A);
  static const textLight = Color(0xFF64748B);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nouvel Événement',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Affiche de l\'événement'),
              const SizedBox(height: 16),
              _buildPhotoPicker(),
              const SizedBox(height: 32),
              _buildSectionTitle('Informations Générales'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Nom de l\'événement',
                hint: 'Ex: Soirée de Gala',
                icon: Icons.event,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _locationController,
                label: 'Lieu',
                hint: 'Ex: Amphi A ou Salle Polyvalente',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Date et Heure'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerCard(
                      label: 'Date',
                      value: _selectedDate == null 
                          ? 'Choisir' 
                          : DateFormat('dd MMM yyyy').format(_selectedDate!),
                      icon: Icons.calendar_today_outlined,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPickerCard(
                      label: 'Heure',
                      value: _selectedTime == null 
                          ? 'Choisir' 
                          : _selectedTime!.format(context),
                      icon: Icons.access_time,
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Billetterie'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _priceController,
                label: 'Prix du ticket',
                hint: '0 pour gratuit',
                icon: Icons.confirmation_number_outlined,
                keyboardType: TextInputType.number,
                suffix: const Text('FCFA', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue)),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _capaciteController,
                label: 'Nombre de places',
                hint: '0 pour illimité',
                icon: Icons.group_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Créer l\'événement',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir la date de l\'événement.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final time = _selectedTime ?? TimeOfDay.now();
    final dateDebut = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      time.hour,
      time.minute,
    );

    final result = await ApiService.createEvenement({
      'titre': _nameController.text.trim(),
      'lieu': _locationController.text.trim(),
      'dateDebut': dateDebut.toIso8601String(),
      'prix': double.tryParse(_priceController.text) ?? 0,
      'capacite': int.tryParse(_capaciteController.text) ?? 0,
    });

    if (!mounted) return;

    if (result['success'] != true) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Erreur lors de la création de l\'événement.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final data = result['data'] as Map<String, dynamic>;
    String? afficheUrl;

    if (_selectedImage != null) {
      final bytes = await _selectedImage!.readAsBytes();
      final uploadResult = await ApiService.uploadEvenementAffiche(
        data['id'].toString(),
        bytes,
        _selectedImage!.name,
      );
      if (uploadResult['success'] == true) {
        afficheUrl = uploadResult['url'] as String?;
      }
    }

    if (!mounted) return;

    final newEvent = EventModel(
      id: data['id'].toString(),
      name: data['titre'] ?? _nameController.text.trim(),
      location: data['lieu'] ?? _locationController.text.trim(),
      date: dateDebut,
      time: time,
      price: double.tryParse(_priceController.text) ?? 0,
      image: _selectedImage,
      imageUrl: afficheUrl,
      status: EventModel.statutLabel(data['statut']),
      capacite: int.tryParse(_capaciteController.text) ?? 0,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Événement créé avec succès !')),
    );
    Navigator.pop(context, newEvent);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: primaryBlue,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textLight),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textDark),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 14, color: textLight.withValues(alpha:0.5)),
              prefixIcon: Icon(icon, color: primaryBlue, size: 20),
              suffixIcon: suffix != null ? Padding(
                padding: const EdgeInsets.all(16),
                child: suffix,
              ) : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Ce champ est requis' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPickerCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textLight),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: primaryBlue, size: 20),
                const SizedBox(width: 12),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryBlue.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: _selectedImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  kIsWeb
                      ? Image.network(
                          _selectedImage!.path,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(_selectedImage!.path),
                          fit: BoxFit.cover,
                        ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => setState(() => _selectedImage = null),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_a_photo_outlined, color: primaryBlue, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ajouter une affiche / photo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Formats supportés : JPG, PNG',
                    style: TextStyle(
                      fontSize: 12,
                      color: textLight,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

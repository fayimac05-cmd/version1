import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_palette.dart';
import '../models/event.dart';
import '../services/api_service.dart';

/// Fiche d'inscription à un événement : l'étudiant remplit ses
/// informations et l'inscription est enregistrée côté serveur.
class EventRegistrationPage extends StatefulWidget {
  final EventModel event;
  const EventRegistrationPage({super.key, required this.event});

  @override
  State<EventRegistrationPage> createState() => _EventRegistrationPageState();
}

class _EventRegistrationPageState extends State<EventRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomsController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _matriculeController = TextEditingController();
  bool _isSubmitting = false;

  static const primaryBlue = AppPalette.blue;
  static const textDark = Color(0xFF0F172A);
  static const textLight = Color(0xFF64748B);

  @override
  void dispose() {
    _nomController.dispose();
    _prenomsController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _matriculeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final result = await ApiService.inscrireEvenement(widget.event.id, {
      'nom': _nomController.text.trim(),
      'prenoms': _prenomsController.text.trim(),
      'email': _emailController.text.trim(),
      'telephone': _telephoneController.text.trim(),
      'matricule': _matriculeController.text.trim(),
    });

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscription enregistrée avec succès !')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Erreur lors de l\'inscription.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
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
          'Fiche d\'inscription',
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
              _buildEventSummary(event),
              const SizedBox(height: 32),
              _buildSectionTitle('Vos informations'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nomController,
                label: 'Nom',
                hint: 'Ex: OUÉDRAOGO',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _prenomsController,
                label: 'Prénom(s)',
                hint: 'Ex: Aïcha',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _matriculeController,
                label: 'Matricule',
                hint: 'Ex: IST-2024-0154',
                icon: Icons.numbers_outlined,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Ex: aicha@exemple.com',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _telephoneController,
                label: 'Téléphone',
                hint: 'Ex: 70 00 00 00',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                required: false,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          event.price > 0
                              ? 'S\'inscrire · ${event.price.toStringAsFixed(0)} FCFA'
                              : 'S\'inscrire gratuitement',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildEventSummary(EventModel event) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(Icons.calendar_today_outlined,
              DateFormat('dd MMM yyyy').format(event.date)),
          const SizedBox(height: 8),
          _buildSummaryRow(Icons.access_time, event.time.format(context)),
          const SizedBox(height: 8),
          _buildSummaryRow(Icons.location_on_outlined,
              event.location.isEmpty ? 'Lieu à confirmer' : event.location),
          const SizedBox(height: 8),
          _buildSummaryRow(
            Icons.confirmation_number_outlined,
            event.price > 0 ? '${event.price.toStringAsFixed(0)} FCFA' : 'Gratuit',
          ),
          if (event.capacite > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(Icons.group_outlined,
                '${event.inscrits} / ${event.capacite} inscrits'),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryBlue),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 13, color: textLight)),
      ],
    );
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
    bool required = true,
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
                color: Colors.black.withValues(alpha: 0.02),
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
              hintStyle: TextStyle(fontSize: 14, color: textLight.withValues(alpha: 0.5)),
              prefixIcon: Icon(icon, color: primaryBlue, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: required
                ? (value) => value == null || value.trim().isEmpty ? 'Ce champ est requis' : null
                : null,
          ),
        ),
      ],
    );
  }
}

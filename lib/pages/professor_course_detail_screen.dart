import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class ProfessorCourseDetailScreen extends StatefulWidget {
  final String courseName;
  final String className;

  const ProfessorCourseDetailScreen({
    super.key,
    required this.courseName,
    required this.className,
  });

  @override
  State<ProfessorCourseDetailScreen> createState() => _ProfessorCourseDetailScreenState();
}

class _ProfessorCourseDetailScreenState extends State<ProfessorCourseDetailScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
  final List<Map<String, String>> _uploadedFiles = [
    {
      'title': 'Chapitre 1 : Introduction aux Réseaux',
      'desc': 'Support de cours complet sur les architectures et le modèle OSI.',
      'file': 'OSI_Introduction.pdf',
      'date': '12 Mai 2026',
    },
    {
      'title': 'Chapitre 2 : Commutation et Routage',
      'desc': 'Protocole IP, routage statique et dynamique.',
      'file': 'IP_Routing_V2.pdf',
      'date': '14 Mai 2026',
    },
  ];

  void _publishFile() {
    if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir le titre et la description.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _uploadedFiles.insert(0, {
        'title': _titleCtrl.text,
        'desc': _descCtrl.text,
        'file': '${_titleCtrl.text.replaceAll(' ', '_')}.pdf',
        'date': 'Aujourd\'hui',
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support de cours publié avec succès !'),
        backgroundColor: Color(0xFF15803D),
      ),
    );

    _titleCtrl.clear();
    _descCtrl.clear();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppPalette.blue,
        foregroundColor: Colors.white,
        title: Text(
          widget.courseName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPalette.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppPalette.blue.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.className,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppPalette.blue, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Gestion des supports de cours',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Publiez et organisez le matériel pédagogique destiné à vos étudiants.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Section
            const Text(
              'Ajouter un nouveau support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.title, color: AppPalette.blue),
                      labelText: 'Titre du support',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.description_outlined, color: AppPalette.blue),
                      labelText: 'Description ou consigne',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppPalette.lightBlue,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppPalette.blue.withValues(alpha: 0.18)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.attach_file_rounded, color: AppPalette.blue),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Support_Cours_Reseau.pdf (Simulé)',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppPalette.blue, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _publishFile,
                      icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
                      label: const Text('Publier pour la classe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Files List Section
            const Text(
              'Supports de cours publiés',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            _uploadedFiles.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('Aucun fichier publié pour le moment.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _uploadedFiles.length,
                    itemBuilder: (_, i) {
                      final item = _uploadedFiles[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppPalette.softYellow,
                              child: Icon(Icons.picture_as_pdf, color: AppPalette.blue),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title']!,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['desc']!,
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        item['file']!,
                                        style: const TextStyle(color: AppPalette.blue, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('•', style: TextStyle(color: Colors.grey)),
                                      const SizedBox(width: 8),
                                      Text(
                                        item['date']!,
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _uploadedFiles.removeAt(i);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Support de cours supprimé.')),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

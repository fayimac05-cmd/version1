import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class CourseDetailScreen extends StatelessWidget {
  final String courseName;
  final String professorName;
  final String progress;
  
  const CourseDetailScreen({
    super.key,
    this.courseName = "Programmation Flutter",
    this.professorName = "Dr. Dupont",
    this.progress = "75%",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.white,
      appBar: AppBar(
        backgroundColor: AppPalette.blue,
        elevation: 0,
        title: Text(
          "Détail du Cours",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du cours
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppPalette.lightBlue,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.blue.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.person, color: AppPalette.yellow, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        professorName,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppPalette.black.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Progression",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        progress,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppPalette.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.75,
                    backgroundColor: Colors.white,
                    color: AppPalette.yellow,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Contenu du cours
            const Text(
              "Contenu du Cours",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppPalette.black,
              ),
            ),
            const SizedBox(height: 15),
            _buildChapterItem("Chapitre 1 : Introduction à Flutter", true),
            _buildChapterItem("Chapitre 2 : Widgets de base", true),
            _buildChapterItem("Chapitre 3 : Gestion d'état", false),
            _buildChapterItem("Chapitre 4 : Animations", false),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterItem(String title, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCompleted ? AppPalette.softYellow : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.lock_outline,
              color: isCompleted ? AppPalette.yellow : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                color: isCompleted ? AppPalette.black : Colors.grey.shade600,
              ),
            ),
          ),
          Icon(Icons.play_circle_fill, color: AppPalette.blue.withOpacity(0.8)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class BulletinScreen extends StatelessWidget {
  final String studentName;
  final String semester;

  const BulletinScreen({
    super.key,
    this.studentName = "Fatimata Diallo",
    this.semester = "Semestre 1 - 2026",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.white,
      appBar: AppBar(
        backgroundColor: AppPalette.blue,
        elevation: 0,
        title: const Text(
          "Bulletin de Notes",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de l'étudiant
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppPalette.lightBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppPalette.blue,
                    child: Text(
                      studentName.substring(0, 1),
                      style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppPalette.blue),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          semester,
                          style: TextStyle(color: AppPalette.black.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Moyenne Générale
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.blue.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                  border: Border.all(color: AppPalette.yellow, width: 4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "14.5",
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppPalette.blue),
                    ),
                    Text(
                      "/ 20",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Moyenne G.",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Liste des matières
            const Text(
              "Détail des Matières",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildSubjectItem("Mathématiques Appliquées", 16.0, "Très bien"),
            _buildSubjectItem("Développement Mobile", 18.5, "Excellent"),
            _buildSubjectItem("Bases de données", 12.0, "Assez bien"),
            _buildSubjectItem("Anglais technique", 14.0, "Bien"),
            _buildSubjectItem("Réseaux informatiques", 9.5, "Insuffisant", isAlert: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectItem(String subject, double grade, String appreciation, {bool isAlert = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isAlert ? Colors.red.shade100 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  appreciation,
                  style: TextStyle(
                    fontSize: 12,
                    color: isAlert ? Colors.red : Colors.grey.shade600,
                    fontWeight: isAlert ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: isAlert ? Colors.red.withOpacity(0.1) : AppPalette.softYellow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              grade.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isAlert ? Colors.red : AppPalette.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

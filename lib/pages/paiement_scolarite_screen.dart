import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class PaiementScolariteScreen extends StatelessWidget {
  const PaiementScolariteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.white,
      appBar: AppBar(
        backgroundColor: AppPalette.blue,
        elevation: 0,
        title: const Text(
          "Paiement de Scolarité",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
            // Carte Solde
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppPalette.blue, Color(0xFF1E60B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.blue.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Reste à Payer",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      Icon(Icons.account_balance_wallet, color: AppPalette.yellow.withOpacity(0.8)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "450,000 FCFA",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: 0.4,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    color: AppPalette.yellow,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "40% payé sur 1,125,000 FCFA (Total)",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Bouton de paiement
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.yellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Effectuer un paiement",
                  style: TextStyle(
                    color: AppPalette.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              "Historique des Paiements",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Historique
            _buildTransactionItem("Tranche 1", "15 Sept 2025", "300,000 FCFA", true),
            _buildTransactionItem("Tranche 2", "05 Nov 2025", "150,000 FCFA", true),
            _buildTransactionItem("Tranche 3", "En attente", "225,000 FCFA", false),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(String title, String date, String amount, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check_circle : Icons.pending,
              color: isCompleted ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  date,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppPalette.blue,
            ),
          ),
        ],
      ),
    );
  }
}

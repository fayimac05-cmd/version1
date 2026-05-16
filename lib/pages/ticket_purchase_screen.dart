import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class TicketPurchaseScreen extends StatefulWidget {
  const TicketPurchaseScreen({super.key});

  @override
  State<TicketPurchaseScreen> createState() => _TicketPurchaseScreenState();
}

class _TicketPurchaseScreenState extends State<TicketPurchaseScreen> {
  int quantity = 1;
  final int ticketPrice = 5000; // FCFA

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.white,
      appBar: AppBar(
        backgroundColor: AppPalette.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppPalette.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Achat de Billet",
          style: TextStyle(color: AppPalette.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte Event
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppPalette.lightBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppPalette.blue,
                      borderRadius: BorderRadius.circular(15),
                      image: const DecorationImage(
                        image: NetworkImage("https://picsum.photos/200"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Gala de Fin d'Année",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.blue,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                            const SizedBox(width: 5),
                            const Text("15 Déc. 2026", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Sélection Quantité
            const Text(
              "Nombre de billets",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildQuantityBtn(Icons.remove, () {
                  if (quantity > 1) setState(() => quantity--);
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    quantity.toString(),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildQuantityBtn(Icons.add, () {
                  if (quantity < 10) setState(() => quantity++);
                }),
              ],
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total à payer",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  "${quantity * ticketPrice} FCFA",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),

            // Bouton Confirmer
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Action de paiement
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Paiement initié avec succès')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  shadowColor: AppPalette.blue.withOpacity(0.5),
                ),
                child: const Text(
                  "Procéder au paiement",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppPalette.softYellow,
          shape: BoxShape.circle,
          border: Border.all(color: AppPalette.yellow, width: 2),
        ),
        child: Icon(icon, color: AppPalette.blue),
      ),
    );
  }
}

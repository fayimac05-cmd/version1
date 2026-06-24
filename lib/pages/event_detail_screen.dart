import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class EventDetailScreen extends StatelessWidget {
  final Map<String, dynamic> event;
  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final color = event['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: color, foregroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Détail de l\'événement',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.2)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Text(event['type'],
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(height: 16),

          Text(event['titre'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A), letterSpacing: -0.4, height: 1.2)),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppPalette.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                  blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(children: [
              _infoRow(Icons.calendar_today, 'Date', event['date'], color),
              const Padding(padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: Color(0xFFE2E8F0))),
              _infoRow(Icons.location_on_outlined, 'Lieu', event['lieu'], color),
            ]),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppPalette.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Description',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              Text(event['detail'],
                  style: const TextStyle(fontSize: 15, color: Color(0xFF64748B),
                      height: 1.65)),
            ]),
          ),

          if (event['ticket'] == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
              ),
              child: Row(children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.confirmation_number_outlined,
                      color: Color(0xFFD97706), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Ticket requis',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706))),
                  const SizedBox(height: 4),
                  Text('Prix : ${event['prix']} — Paiement via Orange Money',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B),
                          height: 1.4)),
                ])),
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Paiement Orange Money — ${event['prix']}'),
                    backgroundColor: const Color(0xFFFF6B00),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                icon: const Icon(Icons.payment, size: 22),
                label: Text('Acheter un ticket — ${event['prix']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                        letterSpacing: 0.2)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(children: [
      Container(width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22)),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B),
            fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A))),
      ]),
    ]);
  }
}

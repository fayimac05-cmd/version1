import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';

/// Fiche "Menu du jour" de la cantine — extraite de home_tab.dart pour être
/// réutilisable ailleurs (ex. clic sur une notification "Menu publié").
/// Anciennement classe privée `_CantineSheet` interne à home_tab.dart.
class CantineSheet extends StatefulWidget {
  const CantineSheet();

  @override
  State<CantineSheet> createState() => CantineSheetState();
}

class CantineSheetState extends State<CantineSheet> {
  bool _loading = true;
  List<Map<String, dynamic>> _repasPublies = [];

  static const _labels = {
    'petit_dejeuner': ('☀️', 'Petit déjeuner'),
    'dejeuner': ('🍽️', 'Déjeuner'),
    'diner': ('🌙', 'Dîner'),
  };

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final result = await ApiService.getCantineAujourdhui();
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        _repasPublies = List<Map<String, dynamic>>.from(result['data'] as List);
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppPalette.blueGradient,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Menu du jour',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Menu de la cantine',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Ouvert',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : _repasPublies.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.no_meals_outlined, size: 40, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              const Text(
                                "Le menu du jour n'a pas encore été publié.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: _repasPublies.map((r) {
                              final repas = r['repas']?.toString() ?? '';
                              final label = _labels[repas] ?? ('🍴', repas);
                              final plats = (r['plats'] as List<dynamic>? ?? [])
                                  .map((p) => [
                                        p['nom']?.toString() ?? '',
                                        '${p['prix'] ?? ''} FCFA',
                                      ])
                                  .toList();
                              return _mealSection(label.$1, label.$2, plats);
                            }).toList(),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealSection(
    String emoji,
    String title,
    List<List<String>> dishes,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppPalette.lightBlue,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppPalette.lightBlue,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...dishes.map(
            (dish) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dish[0],
                    style: const TextStyle(
                      color: Color(0xFF555F6F),
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.softYellow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      dish[1],
                      style: const TextStyle(
                        color: Color(0xFF4A3000),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

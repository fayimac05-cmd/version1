import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class SimpleInfoTab extends StatelessWidget {
  const SimpleInfoTab({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppPalette.blue,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppPalette.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          color: AppPalette.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un cours...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppPalette.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppPalette.lightBlue),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppPalette.blue),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final stripeColor = index.isEven
                  ? AppPalette.blue
                  : AppPalette.yellow;
              return Container(
                decoration: BoxDecoration(
                  color: AppPalette.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.blue.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 98,
                      decoration: BoxDecoration(
                        color: stripeColor,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(16),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'INFO10${index + 1}',
                                  style: TextStyle(
                                    color: stripeColor == AppPalette.yellow
                                        ? AppPalette.black
                                        : AppPalette.blue,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppPalette.softYellow,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'S${(index % 2) + 3}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              items[index],
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 19,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Prof. Marie Sawadogo',
                                  style: TextStyle(color: Colors.black54),
                                ),
                                Text(
                                  '5 cr.',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

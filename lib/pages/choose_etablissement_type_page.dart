import 'package:flutter/material.dart';
import '../config/etablissement_config.dart';
import '../theme/app_palette.dart';

// ════════════════════════════════════════════════════════════════════════════
// CHOIX DU TYPE D'ÉTABLISSEMENT (onboarding / paramètres)
// L'app s'adapte ensuite automatiquement : sections visibles, menus,
// options (cantine, bus, BDE…) et vocabulaire.
// ════════════════════════════════════════════════════════════════════════════
class ChooseEtablissementTypePage extends StatefulWidget {
  const ChooseEtablissementTypePage({super.key, this.onDone});

  /// Appelé après validation (sinon simple pop).
  final VoidCallback? onDone;

  @override
  State<ChooseEtablissementTypePage> createState() =>
      _ChooseEtablissementTypePageState();
}

class _ChooseEtablissementTypePageState
    extends State<ChooseEtablissementTypePage> {
  TypeEtablissement _selected = EtablissementConfig.instance.type;
  bool _saving = false;

  Future<void> _valider() async {
    setState(() => _saving = true);
    await EtablissementConfig.instance.appliquerType(_selected);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'ScolarHub configuré pour : ${_selected.label}. '
            'L\'interface s\'adapte automatiquement.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      Navigator.pop(context, _selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (Navigator.canPop(context))
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Color(0xFF334155), size: 20),
                          ),
                        ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: AppPalette.blue),
                        child: const Icon(Icons.school_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text('ScolarHub',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppPalette.blue,
                              letterSpacing: -0.3)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text('Quel type d\'établissement\nêtes-vous ?',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          height: 1.25,
                          letterSpacing: -0.4)),
                  const SizedBox(height: 8),
                  const Text(
                      'ScolarHub adapte les menus, les sections et le vocabulaire à votre établissement.',
                      style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.5)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: TypeEtablissement.values.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _typeCard(TypeEtablissement.values[i]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _valider,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                      'Continuer en tant que ${_selected.label}',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded,
                                    size: 20),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeCard(TypeEtablissement type) {
    final selected = _selected == type;
    return GestureDetector(
      onTap: () => setState(() => _selected = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppPalette.lightBlue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppPalette.blue : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? AppPalette.blue : AppPalette.lightBlue,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(type.icon,
                  color: selected ? Colors.white : AppPalette.blue,
                  size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.label,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppPalette.blue
                              : const Color(0xFF0F172A))),
                  const SizedBox(height: 3),
                  Text(type.description,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          height: 1.35)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppPalette.blue, size: 24),
          ],
        ),
      ),
    );
  }
}

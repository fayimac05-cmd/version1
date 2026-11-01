import 'package:flutter/material.dart';

/// Une entrée de navigation (admin ou professeur) pour l'affichage téléphone.
class NavEntry {
  const NavEntry({
    required this.index,
    required this.label,
    required this.icon,
    required this.iconActive,
    this.group = '',
    this.badge = 0,
  });
  final int index;
  final String label;
  final IconData icon;
  final IconData iconActive;
  final String group;
  final int badge;
}

/// Barre du bas pour téléphone : quelques onglets favoris + un bouton « Plus »
/// qui ouvre la liste complète (voir [showMenuPlusSheet]).
class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({
    super.key,
    required this.favoris,
    required this.autres,
    required this.currentIndex,
    required this.onSelect,
    required this.onPlus,
    this.accent = const Color(0xFF0B1E4D),
  });

  final List<NavEntry> favoris;
  final List<NavEntry> autres;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onPlus;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final plusActif = autres.any((e) => e.index == currentIndex);
    final badgePlus = autres.fold<int>(0, (s, e) => s + e.badge);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, -4))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
          child: Row(
            children: [
              for (final e in favoris)
                Expanded(
                  child: _item(
                    icon: e.index == currentIndex ? e.iconActive : e.icon,
                    label: e.label,
                    actif: e.index == currentIndex,
                    badge: e.badge,
                    onTap: () => onSelect(e.index),
                  ),
                ),
              if (autres.isNotEmpty)
                Expanded(
                  child: _item(
                    icon: Icons.apps_rounded,
                    label: 'Plus',
                    actif: plusActif,
                    badge: badgePlus,
                    onTap: onPlus,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String label,
    required bool actif,
    required int badge,
    required VoidCallback onTap,
  }) {
    final couleur = actif ? accent : const Color(0xFF94A3B8);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 32,
            decoration: BoxDecoration(
              color: actif ? accent.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Badge(
                isLabelVisible: badge > 0,
                label: Text(badge > 99 ? '99+' : '$badge', style: const TextStyle(fontSize: 9)),
                child: Icon(icon, size: 22, color: couleur),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: actif ? FontWeight.w700 : FontWeight.w500, color: couleur),
          ),
        ],
      ),
    );
  }
}

/// Page « Plus » : tous les onglets accessibles, rangés par thème, avec
/// recherche. [onSelect] reçoit l'index choisi (la feuille se ferme avant).
Future<void> showMenuPlusSheet(
  BuildContext context, {
  required List<NavEntry> entries,
  required int currentIndex,
  required ValueChanged<int> onSelect,
  String titre = 'Tous les onglets',
  Color accent = const Color(0xFF0B1E4D),
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scroll) => _PlusSheet(
        scroll: scroll,
        entries: entries,
        currentIndex: currentIndex,
        titre: titre,
        accent: accent,
        onSelect: (i) {
          Navigator.of(ctx).pop();
          onSelect(i);
        },
      ),
    ),
  );
}

class _PlusSheet extends StatefulWidget {
  const _PlusSheet({
    required this.scroll,
    required this.entries,
    required this.currentIndex,
    required this.titre,
    required this.accent,
    required this.onSelect,
  });
  final ScrollController scroll;
  final List<NavEntry> entries;
  final int currentIndex;
  final String titre;
  final Color accent;
  final ValueChanged<int> onSelect;

  @override
  State<_PlusSheet> createState() => _PlusSheetState();
}

class _PlusSheetState extends State<_PlusSheet> {
  String _q = '';

  String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('ç', 'c');

  @override
  Widget build(BuildContext context) {
    final q = _norm(_q.trim());
    final filtrees = widget.entries.where((e) => q.isEmpty || _norm(e.label).contains(q)).toList();
    final groupes = <String>[];
    for (final e in filtrees) {
      if (!groupes.contains(e.group)) groupes.add(e.group);
    }
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(children: [
              Expanded(child: Text(widget.titre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
            ]),
          ),
          if (widget.entries.length > 6)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: 'Rechercher un onglet…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
            ),
          Expanded(
            child: filtrees.isEmpty
                ? const Center(child: Text('Aucun onglet trouvé.', style: TextStyle(color: Color(0xFF64748B))))
                : LayoutBuilder(builder: (context, box) {
                    const colonnes = 3;
                    const marge = 16.0;
                    const gap = 10.0;
                    final w = (box.maxWidth - marge * 2 - gap * (colonnes - 1)) / colonnes;
                    return ListView(
                      controller: widget.scroll,
                      padding: const EdgeInsets.fromLTRB(marge, 4, marge, 24),
                      children: [
                        for (final g in groupes) ...[
                          if (g.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                              child: Text(g, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Color(0xFF64748B))),
                            ),
                          Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final e in filtrees.where((x) => x.group == g))
                                SizedBox(width: w, child: _tuile(e)),
                            ],
                          ),
                        ],
                      ],
                    );
                  }),
          ),
        ],
      ),
    );
  }

  Widget _tuile(NavEntry e) {
    final actif = e.index == widget.currentIndex;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => widget.onSelect(e.index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: actif ? widget.accent.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: actif ? widget.accent : const Color(0xFFE2E8F0), width: actif ? 1.5 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: e.badge > 0,
              label: Text(e.badge > 99 ? '99+' : '${e.badge}', style: const TextStyle(fontSize: 9)),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: actif ? widget.accent : widget.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(actif ? e.iconActive : e.icon, size: 24, color: actif ? Colors.white : widget.accent),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              e.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, height: 1.2, fontWeight: actif ? FontWeight.w800 : FontWeight.w600, color: const Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
    );
  }
}

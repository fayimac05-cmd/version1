import 'package:flutter/material.dart';
import 'admin_theme.dart';

/// Standard page header used across all admin pages.
class AdminPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final double bottomPadding;

  const AdminPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.bottomPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminTheme.surface,
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPadding),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AdminTheme.textPrimary,
              )),
              Text(subtitle, style: const TextStyle(
                fontSize: 13,
                color: AdminTheme.textSecondary,
              )),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// Standard "add" button used in admin page headers.
class AdminAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AdminAddButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AdminTheme.iconBgAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.add_rounded, color: AdminTheme.iconFgAlt, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          )),
        ]),
      ),
    );
  }
}

/// Standard search bar used across admin pages.
class AdminSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const AdminSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
      height: 40,
      decoration: BoxDecoration(
        color: AdminTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminTheme.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 13, color: AdminTheme.textMuted),
          prefixIcon: const Icon(Icons.search_rounded,
            color: AdminTheme.textMuted, size: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    ));
  }
}

/// Standard 1px divider between admin page sections.
const Widget adminDivider = Divider(height: 1, thickness: 1, color: AdminTheme.border);

/// Standard KPI / status chip used in admin page headers.
class AdminKpiChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  const AdminKpiChip({
    super.key,
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: foreground.withValues(alpha:0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: foreground, size: 14),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        )),
      ]),
    );
  }
}

/// Standard filter chip used in admin pages.
class AdminFilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const AdminFilterChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AdminTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AdminTheme.primary : AdminTheme.border,
          ),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? Colors.white : AdminTheme.textSecondary,
        )),
      ),
    );
  }
}

/// Boîte d'icône standardisée — deux variantes :
/// - [alt] = false : fond bleu mid (#1565C0) + icône blanche
/// - [alt] = true  : fond bleu (#0A4DA2) + icône jaune (#F8C400)
class AdminIconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final double radius;
  final bool alt;

  const AdminIconBox({
    super.key,
    required this.icon,
    this.size = 40,
    this.iconSize = 20,
    this.radius = 10,
    this.alt = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: alt ? AdminTheme.iconBgAlt : AdminTheme.iconBg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon,
        color: alt ? AdminTheme.iconFgAlt : AdminTheme.iconFg,
        size: iconSize,
      ),
    );
  }
}

/// Standard empty-state placeholder for admin pages.
class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const AdminEmptyState({
    super.key,
    this.icon = Icons.search_off_rounded,
    this.message = 'Aucun résultat trouvé.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 48, color: AdminTheme.iconBg),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(
          fontSize: 14,
          color: AdminTheme.textSecondary,
        )),
      ]),
    );
  }
}

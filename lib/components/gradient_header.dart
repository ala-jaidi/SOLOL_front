import 'package:flutter/material.dart';
import 'package:lidarmesure/theme.dart';

/// A reusable, modern gradient header used across pages.
/// Provides optional back button, leading widget (e.g., logo), title, subtitle and trailing actions.
class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? leading;
  final Widget? trailing;

  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.onBack,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.1),
            cs.tertiary.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBack)
            IconButton(
              icon: Icon(Icons.arrow_back, color: cs.onSurface),
              onPressed: onBack,
            ),
          if (showBack) const SizedBox(width: 8),
          if (leading != null) leading!,
          if (leading != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium?.bold),
                if (subtitle != null)
                  Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium?.withColor(cs.onSurfaceVariant)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

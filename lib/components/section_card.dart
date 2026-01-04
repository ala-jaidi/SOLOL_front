import 'package:flutter/material.dart';
import 'package:lidarmesure/theme.dart';

/// A modern, minimal card used to group related content and form fields.
class SectionCard extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final List<Widget> children;

  const SectionCard({super.key, this.title, this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  if (icon != null)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 16, color: cs.primary),
                    ),
                  if (icon != null) const SizedBox(width: 8),
                  Text(title!, style: Theme.of(context).textTheme.titleLarge?.semiBold),
                ],
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}

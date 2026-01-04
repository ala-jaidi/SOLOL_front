import 'package:flutter/material.dart';
import 'package:lidarmesure/theme.dart';
import 'package:lidarmesure/components/modern_button.dart';

/// A prominent primary CTA for starting a new scan.
/// Uses a high-contrast gradient and large, full-width pill button.
class ScanCTA extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  const ScanCTA({super.key, this.label = 'Nouveau Scan', this.onPressed, this.icon = Icons.radar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.9),
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 28),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: ModernButton(
              label: label,
              onPressed: onPressed,
              leadingIcon: Icons.play_arrow,
              variant: ModernButtonVariant.primary,
              size: ModernButtonSize.large,
              expand: true,
            ),
          ),
        ],
      ),
    );
  }
}

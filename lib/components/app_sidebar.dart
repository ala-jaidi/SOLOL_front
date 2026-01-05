import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lidarmesure/theme.dart';
import 'package:lidarmesure/state/app_settings.dart';
import 'package:lidarmesure/supabase/supabase_config.dart';
import 'package:lidarmesure/l10n/app_localizations.dart';

class AppSideBar extends StatelessWidget {
  const AppSideBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settings = context.watch<AppSettings>();
    final l10n = AppLocalizations.of(context);

    return Drawer(
      width: MediaQuery.of(context).size.width.clamp(280, 360),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        children: [
          // Glassy background
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.xl),
                bottomLeft: Radius.circular(AppRadius.xl),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.surfaceContainerHighest.withValues(alpha: 0.7),
                        cs.surface.withValues(alpha: 0.6),
                      ],
                    ),
                    // Match the ClipRRect above to prevent web border painting crashes
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.xl),
                      bottomLeft: Radius.circular(AppRadius.xl),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Safe 1px separator instead of non-uniform border (prevents CanvasKit crash)
          Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 1, color: cs.outline.withValues(alpha: 0.12))),
          // Content
          SafeArea(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [cs.primary, cs.tertiary.withValues(alpha: 0.9)]),
                        ),
                        child: Icon(Icons.analytics_outlined, color: cs.onPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.appName, style: Theme.of(context).textTheme.titleLarge?.semiBold),
                            Text(l10n.professionalSpace, style: Theme.of(context).textTheme.labelSmall?.withColor(cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: cs.onSurface),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ).animate().fadeIn().moveY(begin: -8, end: 0),
                  SizedBox(height: AppSpacing.lg),
                  // Use push so back button works when coming from the sidebar
                  _NavItem(icon: Icons.document_scanner_outlined, label: l10n.scanner, onTap: () => context.push('/scan')),
                  _NavItem(icon: Icons.history, label: l10n.history, onTap: () => context.push('/history')),
                  _NavItem(icon: Icons.medical_information_outlined, label: l10n.podiatristProfile, onTap: () => context.push('/profile')),
                  _NavItem(icon: Icons.notifications_none_rounded, label: l10n.notifications, onTap: () => context.push('/notifications')),
                  _NavItem(icon: Icons.help_outline_rounded, label: l10n.help, onTap: () => context.push('/help')),
                  // Removed redundant entries: Accueil, Patients, Assistant IA
                  SizedBox(height: AppSpacing.lg),
                  Divider(color: cs.outline.withValues(alpha: 0.12), height: 1),
                  SizedBox(height: AppSpacing.lg),
                  Text(l10n.preferences, style: Theme.of(context).textTheme.titleMedium?.semiBold),
                  SizedBox(height: AppSpacing.md),
                  // Theme toggle
                  Container(
                    padding: AppSpacing.paddingSm,
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.dark_mode_outlined, color: cs.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(child: Text(l10n.appearance, style: Theme.of(context).textTheme.bodyMedium)),
                        _SegmentedTwo(
                          left: l10n.light,
                          right: l10n.dark,
                          valueRight: settings.isDark,
                          onChanged: (isRight) => settings.setThemeMode(isRight ? ThemeMode.dark : ThemeMode.light),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  // Language
                  Container(
                    padding: AppSpacing.paddingSm,
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.language_rounded, color: cs.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(child: Text(l10n.language, style: Theme.of(context).textTheme.bodyMedium)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _LangChip(
                              label: 'Français',
                              selected: settings.locale?.languageCode == 'fr',
                              onTap: () => settings.setLocale(const Locale('fr')),
                            ),
                            _LangChip(
                              label: 'English',
                              selected: settings.locale?.languageCode == 'en',
                              onTap: () => settings.setLocale(const Locale('en')),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Logout
                  GestureDetector(
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('${l10n.logout} ?'),
                          content: Text(l10n.logoutConfirm),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
                            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.logout)),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        try {
                          await SupabaseConfig.auth.signOut();
                          if (context.mounted) context.go('/login');
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $e'), backgroundColor: cs.error),
                            );
                          }
                        }
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: cs.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: cs.error.withValues(alpha: 0.22)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: cs.error),
                          const SizedBox(width: 8),
                          Text(l10n.logout, style: Theme.of(context).textTheme.labelLarge?.semiBold.withColor(cs.error)),
                        ],
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).maybePop();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.onSurface),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).moveX(begin: 12, end: 0);
  }
}

class _SegmentedTwo extends StatelessWidget {
  final String left;
  final String right;
  final bool valueRight;
  final ValueChanged<bool> onChanged;
  const _SegmentedTwo({required this.left, required this.right, required this.valueRight, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segBtn(context, left, !valueRight, () => onChanged(false)),
          _segBtn(context, right, valueRight, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _segBtn(BuildContext context, String label, bool selected, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.withColor(selected ? cs.onPrimary : cs.onSurface),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? cs.primary : cs.surface,
          border: Border.all(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate_rounded, size: 16, color: selected ? cs.onPrimary : cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.labelMedium?.withColor(selected ? cs.onPrimary : cs.onSurface)),
          ],
        ),
      ),
    );
  }
}

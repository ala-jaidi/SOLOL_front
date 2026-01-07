import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/notification_center.dart';
import '../theme.dart';
import 'package:lidarmesure/l10n/app_localizations.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nc = context.watch<NotificationCenter>();
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: cs.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0A1A1F),
                    const Color(0xFF0D2428),
                    cs.surface,
                  ]
                : [
                    cs.primary.withValues(alpha: 0.08),
                    cs.surface,
                  ],
            stops: isDark ? const [0.0, 0.15, 0.4] : const [0.0, 0.25],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _goBack(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.1)
                              : cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface, size: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.notificationsTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.read<NotificationCenter>().markAllRead(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.1)
                              : cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.done_all_rounded, color: cs.primary, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: nc.items.isEmpty
                    ? _emptyState(context)
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: nc.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final n = nc.items[index];
                          return Dismissible(
                            key: ValueKey(n.id),
                            background: Container(
                              decoration: BoxDecoration(
                                color: cs.error,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.centerLeft,
                              child: Icon(Icons.delete_outline, color: cs.onError),
                            ),
                            secondaryBackground: Container(
                              decoration: BoxDecoration(
                                color: cs.error,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.centerRight,
                              child: Icon(Icons.delete_outline, color: cs.onError),
                            ),
                            onDismissed: (_) {
                              context.read<NotificationCenter>().markRead(n.id, true);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : cs.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark 
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : cs.outline.withValues(alpha: 0.15),
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(n.read ? Icons.notifications_none_rounded : Icons.notifications_active_rounded, color: n.read ? cs.onSurfaceVariant : cs.primary),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(child: Text(n.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface))),
                                            Text(_formatTime(n.createdAt), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(n.body, style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            TextButton.icon(
                                              onPressed: () => context.read<NotificationCenter>().markRead(n.id, !n.read),
                                              icon: Icon(n.read ? Icons.mark_email_unread : Icons.mark_email_read, size: 18),
                                              label: Text(n.read ? (l10n.isFrench ? 'Marquer non lu' : 'Mark unread') : (l10n.isFrench ? 'Marquer comme lu' : 'Mark as read')),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.08),
              border: Border.all(color: cs.primary.withValues(alpha: 0.24)),
            ),
            child: Icon(Icons.notifications_none_rounded, color: cs.primary, size: 28),
          ),
          SizedBox(height: AppSpacing.md),
          Text(AppLocalizations.of(context).noNotifications, style: context.textStyles.titleMedium?.semiBold),
          SizedBox(height: 4),
          Text(AppLocalizations.of(context).isFrench ? 'Vous verrez ici les alertes importantes' : 'Important alerts will appear here', style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/notification_center.dart';
import '../theme.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nc = context.watch<NotificationCenter>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all_rounded, color: cs.primary),
            tooltip: 'Tout marquer comme lu',
            onPressed: () => context.read<NotificationCenter>().markAllRead(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: const SizedBox(),
            ),
          ),
          Padding(
            padding: AppSpacing.paddingLg,
            child: nc.items.isEmpty
                ? _emptyState(context)
                : ListView.separated(
                    itemCount: nc.items.length,
                    separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final n = nc.items[index];
                      return Dismissible(
                        key: ValueKey(n.id),
                        background: Container(
                          decoration: BoxDecoration(
                            color: cs.error,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerLeft,
                          child: Icon(Icons.delete_outline, color: cs.onError),
                        ),
                        secondaryBackground: Container(
                          decoration: BoxDecoration(
                            color: cs.error,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerRight,
                          child: Icon(Icons.delete_outline, color: cs.onError),
                        ),
                        onDismissed: (_) {
                          // Simplest: mark as read and keep in list; or remove entirely.
                          context.read<NotificationCenter>().markRead(n.id, true);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
                          ),
                          padding: AppSpacing.paddingMd,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(n.read ? Icons.notifications_none_rounded : Icons.notifications_active_rounded, color: n.read ? cs.onSurfaceVariant : cs.primary),
                              SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(n.title, style: context.textStyles.titleSmall?.semiBold)),
                                        Text(_formatTime(n.createdAt), style: context.textStyles.labelSmall?.withColor(cs.onSurfaceVariant)),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(n.body, style: context.textStyles.bodyMedium),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => context.read<NotificationCenter>().markRead(n.id, !n.read),
                                          icon: Icon(n.read ? Icons.mark_email_unread : Icons.mark_email_read, size: 18),
                                          label: Text(n.read ? 'Marquer non lu' : 'Marquer comme lu'),
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
          Text('Aucune notification', style: context.textStyles.titleMedium?.semiBold),
          SizedBox(height: 4),
          Text('Vous verrez ici les alertes importantes', style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'à l’instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
}

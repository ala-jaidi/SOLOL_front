import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aide'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ), 
      body: Stack(
        children: [
          Positioned.fill(child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: const SizedBox())),
          ListView(
            padding: AppSpacing.paddingLg,
            children: [
              _card(context, Icons.help_outline_rounded, 'Comment effectuer un scan ?',
                  'Allez dans Scanner > suivez les instructions, maintenez l’appareil stable et assurez une bonne luminosité.'),
              SizedBox(height: AppSpacing.md),
              _card(context, Icons.picture_as_pdf_outlined, 'Exporter un rapport PDF',
                  'Depuis la page Résultats, appuyez sur Partager > Exporter PDF pour envoyer par email ou enregistrer.'),
              SizedBox(height: AppSpacing.md),
              _card(context, Icons.notifications_none_rounded, 'Notifications',
                  'Les alertes liées aux rapports et actions apparaissent sur la page Notifications.'),
              SizedBox(height: AppSpacing.md),
              _card(context, Icons.lock_outline_rounded, 'Connexion & Sécurité',
                  'Aucun backend n’est connecté. Utilisez le panneau Firebase ou Supabase dans Dreamflow pour activer l’authentification.'),
              SizedBox(height: AppSpacing.lg),
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Besoin d’aide ?', style: context.textStyles.titleMedium?.semiBold),
                    SizedBox(height: 6),
                    Text('Contactez le support ou consultez la documentation.'),
                    SizedBox(height: 12),
                    Wrap(spacing: 8, children: [
                      OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.email_outlined), label: const Text('Email support')),
                      FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.menu_book_outlined), label: const Text('Documentation')),
                    ])
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, IconData icon, String title, String body) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.titleSmall?.semiBold),
                SizedBox(height: 6),
                Text(body, style: context.textStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

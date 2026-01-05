import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import 'package:lidarmesure/l10n/app_localizations.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).helpTitle),
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
              _card(context, Icons.help_outline_rounded, 
                  AppLocalizations.of(context).isFrench ? 'Comment effectuer un scan ?' : 'How to perform a scan?',
                  AppLocalizations.of(context).isFrench ? 'Allez dans Scanner > suivez les instructions, maintenez l\'appareil stable et assurez une bonne luminosite.' : 'Go to Scanner > follow instructions, hold device steady and ensure good lighting.'),
              SizedBox(height: AppSpacing.md),
              _card(context, Icons.picture_as_pdf_outlined, 
                  AppLocalizations.of(context).isFrench ? 'Exporter un rapport PDF' : 'Export PDF report',
                  AppLocalizations.of(context).isFrench ? 'Depuis la page Resultats, appuyez sur Partager > Exporter PDF pour envoyer par email ou enregistrer.' : 'From Results page, tap Share > Export PDF to send by email or save.'),
              SizedBox(height: AppSpacing.md),
              _card(context, Icons.notifications_none_rounded, 
                  AppLocalizations.of(context).isFrench ? 'Notifications' : 'Notifications',
                  AppLocalizations.of(context).isFrench ? 'Les alertes liees aux rapports et actions apparaissent sur la page Notifications.' : 'Alerts related to reports and actions appear on the Notifications page.'),
              SizedBox(height: AppSpacing.md),
              _card(context, Icons.lock_outline_rounded, 
                  AppLocalizations.of(context).isFrench ? 'Connexion & Securite' : 'Login & Security',
                  AppLocalizations.of(context).isFrench ? 'Aucun backend n\'est connecte. Utilisez le panneau Firebase ou Supabase dans Dreamflow pour activer l\'authentification.' : 'No backend connected. Use Firebase or Supabase panel in Dreamflow to enable authentication.'),
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
                    Text(AppLocalizations.of(context).isFrench ? 'Besoin d\'aide ?' : 'Need help?', style: context.textStyles.titleMedium?.semiBold),
                    SizedBox(height: 6),
                    Text(AppLocalizations.of(context).isFrench ? 'Contactez le support ou consultez la documentation.' : 'Contact support or check the documentation.'),
                    SizedBox(height: 12),
                    Wrap(spacing: 8, children: [
                      OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.email_outlined), label: Text(AppLocalizations.of(context).isFrench ? 'Email support' : 'Email support')),
                      FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.menu_book_outlined), label: Text(AppLocalizations.of(context).isFrench ? 'Documentation' : 'Documentation')),
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

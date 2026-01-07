import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import 'package:lidarmesure/l10n/app_localizations.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

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
                    Text(
                      l10n.helpTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _card(context, Icons.help_outline_rounded, 
                        l10n.isFrench ? 'Comment effectuer un scan ?' : 'How to perform a scan?',
                        l10n.isFrench ? 'Allez dans Scanner > suivez les instructions, maintenez l\'appareil stable et assurez une bonne luminosite.' : 'Go to Scanner > follow instructions, hold device steady and ensure good lighting.'),
                    const SizedBox(height: 12),
                    _card(context, Icons.picture_as_pdf_outlined, 
                        l10n.isFrench ? 'Exporter un rapport PDF' : 'Export PDF report',
                        l10n.isFrench ? 'Depuis la page Resultats, appuyez sur Partager > Exporter PDF pour envoyer par email ou enregistrer.' : 'From Results page, tap Share > Export PDF to send by email or save.'),
                    const SizedBox(height: 12),
                    _card(context, Icons.notifications_none_rounded, 
                        l10n.isFrench ? 'Notifications' : 'Notifications',
                        l10n.isFrench ? 'Les alertes liees aux rapports et actions apparaissent sur la page Notifications.' : 'Alerts related to reports and actions appear on the Notifications page.'),
                    const SizedBox(height: 12),
                    _card(context, Icons.lock_outline_rounded, 
                        l10n.isFrench ? 'Connexion & Securite' : 'Login & Security',
                        l10n.isFrench ? 'Aucun backend n\'est connecte. Utilisez le panneau Firebase ou Supabase dans Dreamflow pour activer l\'authentification.' : 'No backend connected. Use Firebase or Supabase panel in Dreamflow to enable authentication.'),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.isFrench ? 'Besoin d\'aide ?' : 'Need help?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.isFrench ? 'Contactez le support ou consultez la documentation.' : 'Contact support or check the documentation.',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, children: [
                            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.email_outlined), label: Text(l10n.isFrench ? 'Email support' : 'Email support')),
                            FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.menu_book_outlined), label: Text(l10n.isFrench ? 'Documentation' : 'Documentation')),
                          ])
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, IconData icon, String title, String body) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

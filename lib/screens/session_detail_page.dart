import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lidarmesure/theme.dart';
import 'package:lidarmesure/models/session.dart';
import 'package:lidarmesure/models/user.dart';
import 'package:lidarmesure/services/session_service.dart';
import 'package:lidarmesure/services/patient_service.dart';
import 'package:lidarmesure/services/pdf_report_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lidarmesure/components/gradient_header.dart';
import 'package:lidarmesure/l10n/app_localizations.dart';

class SessionDetailPage extends StatefulWidget {
  final String sessionId;
  const SessionDetailPage({super.key, required this.sessionId});

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  final SessionService _sessionService = SessionService();
  final PatientService _patientService = PatientService();
  Session? _session;
  Patient? _patient;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await _sessionService.getSessionById(widget.sessionId);
    Patient? p;
    if (s != null) {
      p = await _patientService.getPatientById(s.patientId);
    }
    setState(() {
      _session = s;
      _patient = p;
      _loading = false;
    });
  }

  Color _getStatusColor(SessionStatus status, BuildContext context) {
    switch (status) {
      case SessionStatus.pending:
        return Theme.of(context).colorScheme.tertiary;
      case SessionStatus.completed:
        return Theme.of(context).colorScheme.secondary;
      case SessionStatus.cancelled:
        return Theme.of(context).colorScheme.error;
    }
  }

  String _getStatusLabelEn(SessionStatus status) {
    switch (status) {
      case SessionStatus.pending:
        return 'Pending';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_session == null) {
      return _NotFound(onBack: () => context.pop());
    }

    final s = _session!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GradientHeader(title: AppLocalizations.of(context).sessionDetails, subtitle: AppLocalizations.of(context).measurements, showBack: true, onBack: () => context.pop()),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSpacing.paddingLg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient summary
                      if (_patient != null)
                        Container(
                          padding: AppSpacing.paddingMd,
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: cs.primary,
                                child: Icon(Icons.person, color: cs.onPrimary),
                              ),
                              SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_patient!.fullName, style: context.textStyles.titleMedium?.semiBold),
                                    SizedBox(height: 2),
                                    Text(AppLocalizations.of(context).isFrench ? 'Age ${_patient!.age} - Pointure ${_patient!.pointure}' : 'Age ${_patient!.age} - Size ${_patient!.pointure}', style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push('/patient/${_patient!.id}'),
                                child: Text(AppLocalizations.of(context).isFrench ? 'Voir profil' : 'View profile'),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(),
                      SizedBox(height: AppSpacing.lg),

                      // Status & meta
                      Container(
                        padding: AppSpacing.paddingMd,
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.insights_outlined, color: cs.primary),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context).isFrench ? 'Informations' : 'Information', style: context.textStyles.titleMedium?.semiBold),
                              ],
                            ),
                            SizedBox(height: AppSpacing.md),
                            _InfoRow(icon: Icons.schedule_rounded, label: 'Date', value: s.formattedDate),
                            Divider(height: AppSpacing.lg),
                            _InfoRow(icon: Icons.verified_outlined, label: AppLocalizations.of(context).isFrench ? 'Statut' : 'Status', value: AppLocalizations.of(context).isFrench ? s.statusLabel : _getStatusLabelEn(s.status)),
                            Divider(height: AppSpacing.lg),
                            _InfoRow(icon: Icons.shield_outlined, label: AppLocalizations.of(context).isFrench ? 'Valide' : 'Valid', value: s.valid ? (AppLocalizations.of(context).isFrench ? 'Oui' : 'Yes') : (AppLocalizations.of(context).isFrench ? 'Non' : 'No')),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms),

                      SizedBox(height: AppSpacing.lg),

                      // Metrics
                      Container(
                        padding: AppSpacing.paddingMd,
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.straighten, color: cs.primary),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context).measurements, style: context.textStyles.titleMedium?.semiBold),
                              ],
                            ),
                            SizedBox(height: AppSpacing.md),
                            if (s.footMetrics.isEmpty)
                              Text(AppLocalizations.of(context).isFrench ? 'Aucune mesure disponible' : 'No measurements available', style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant))
                            else
                              Column(
                                children: s.footMetrics.map((m) => Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: AppSpacing.paddingSm,
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.straighten, color: cs.onSurface),
                                      SizedBox(width: AppSpacing.sm),
                                      Expanded(child: Text('${m.side.name.toUpperCase()} • L: ${m.longueur.toStringAsFixed(1)} cm • l: ${m.largeur.toStringAsFixed(1)} cm', style: context.textStyles.bodyMedium)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: cs.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text('${(m.confidence * 100).toStringAsFixed(0)}%', style: context.textStyles.labelSmall?.withColor(cs.primary)),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms),

                      SizedBox(height: AppSpacing.lg),

                      // Scan Images
                      Container(
                        padding: AppSpacing.paddingMd,
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.image_outlined, color: cs.primary),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context).isFrench ? 'Captures LiDAR' : 'LiDAR Captures', style: context.textStyles.titleMedium?.semiBold),
                              ],
                            ),
                            SizedBox(height: AppSpacing.md),
                            if (s.footScan == null)
                              Text(AppLocalizations.of(context).isFrench ? 'Aucune image scannee' : 'No scanned images', style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant))
                            else
                              Row(
                                children: [
                                  Expanded(
                                    child: AspectRatio(
                                      aspectRatio: 16 / 10,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: cs.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(AppRadius.md),
                                        ),
                                        child: s.footScan!.topView != null && s.footScan!.topView!.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(AppRadius.md),
                                                child: Image.network(s.footScan!.topView!, fit: BoxFit.cover),
                                              )
                                            : Center(child: Icon(Icons.image, color: cs.onSurfaceVariant)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: AspectRatio(
                                      aspectRatio: 16 / 10,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: cs.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(AppRadius.md),
                                        ),
                                        child: s.footScan!.sideView != null && s.footScan!.sideView!.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(AppRadius.md),
                                                child: Image.network(s.footScan!.sideView!, fit: BoxFit.cover),
                                              )
                                            : Center(child: Icon(Icons.image, color: cs.onSurfaceVariant)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms),

                      SizedBox(height: AppSpacing.lg),

                      // Export PDF buttons
                      if (_patient != null)
                        Container(
                          padding: AppSpacing.paddingMd,
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.picture_as_pdf_outlined, color: cs.primary),
                                  const SizedBox(width: 8),
                                  Text(AppLocalizations.of(context).isFrench ? 'Exporter le rapport' : 'Export Report', style: context.textStyles.titleMedium?.semiBold),
                                ],
                              ),
                              SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _printPdf(context),
                                      icon: const Icon(Icons.print_outlined),
                                      label: Text(AppLocalizations.of(context).isFrench ? 'Imprimer' : 'Print'),
                                    ),
                                  ),
                                  SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () => _sharePdf(context),
                                      icon: const Icon(Icons.share_outlined),
                                      label: Text(AppLocalizations.of(context).isFrench ? 'Partager PDF' : 'Share PDF'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 400.ms),

                      SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printPdf(BuildContext context) async {
    if (_session == null || _patient == null) return;
    
    final isFrench = AppLocalizations.of(context).isFrench;
    
    try {
      await PdfReportService.printReport(
        session: _session!,
        patient: _patient!,
        isFrench: isFrench,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFrench ? 'Erreur lors de l\'impression: $e' : 'Print error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    if (_session == null || _patient == null) return;
    
    final isFrench = AppLocalizations.of(context).isFrench;
    
    try {
      await PdfReportService.sharePdf(
        session: _session!,
        patient: _patient!,
        isFrench: isFrench,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFrench ? 'Erreur lors du partage: $e' : 'Share error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant))),
        Text(value, style: context.textStyles.bodyMedium?.semiBold),
      ],
    );
  }
}

// Old header widget removed in favor of GradientHeader

class _NotFound extends StatelessWidget {
  final VoidCallback onBack;
  const _NotFound({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 72, color: cs.error),
              SizedBox(height: AppSpacing.md),
              Text(AppLocalizations.of(context).isFrench ? 'Session introuvable' : 'Session not found', style: context.textStyles.titleLarge?.semiBold),
              SizedBox(height: AppSpacing.sm),
              Text(AppLocalizations.of(context).isFrench ? 'La session demandee n\'existe pas ou a ete supprimee.' : 'The requested session does not exist or has been deleted.', textAlign: TextAlign.center, style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant)),
              SizedBox(height: AppSpacing.lg),
              FilledButton.icon(onPressed: onBack, icon: const Icon(Icons.arrow_back), label: Text(AppLocalizations.of(context).back)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lidarmesure/theme.dart';
import 'package:lidarmesure/models/session.dart';
import 'package:lidarmesure/models/user.dart';
import 'package:lidarmesure/services/session_service.dart';
import 'package:lidarmesure/services/patient_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lidarmesure/components/gradient_header.dart';

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
            GradientHeader(title: 'Détail de la session', subtitle: 'Analyse et mesures', showBack: true, onBack: () => context.pop()),
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
                                    Text('Age ${_patient!.age} • Pointure ${_patient!.pointure}', style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push('/patient/${_patient!.id}'),
                                child: const Text('Voir profil'),
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
                                Text('Informations', style: context.textStyles.titleMedium?.semiBold),
                              ],
                            ),
                            SizedBox(height: AppSpacing.md),
                            _InfoRow(icon: Icons.schedule_rounded, label: 'Date', value: s.formattedDate),
                            Divider(height: AppSpacing.lg),
                            _InfoRow(icon: Icons.verified_outlined, label: 'Statut', value: s.statusLabel),
                            Divider(height: AppSpacing.lg),
                            _InfoRow(icon: Icons.shield_outlined, label: 'Validé', value: s.valid ? 'Oui' : 'Non'),
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
                                Text('Mesures', style: context.textStyles.titleMedium?.semiBold),
                              ],
                            ),
                            SizedBox(height: AppSpacing.md),
                            if (s.footMetrics.isEmpty)
                              Text('Aucune mesure disponible', style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant))
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
                                Text('Captures LiDAR', style: context.textStyles.titleMedium?.semiBold),
                              ],
                            ),
                            SizedBox(height: AppSpacing.md),
                            if (s.footScan == null)
                              Text('Aucune image scannée', style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant))
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
              Text('Session introuvable', style: context.textStyles.titleLarge?.semiBold),
              SizedBox(height: AppSpacing.sm),
              Text('La session demandée n\'existe pas ou a été supprimée.', textAlign: TextAlign.center, style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant)),
              SizedBox(height: AppSpacing.lg),
              FilledButton.icon(onPressed: onBack, icon: const Icon(Icons.arrow_back), label: const Text('Retour')),
            ],
          ),
        ),
      ),
    );
  }
}

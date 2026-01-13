import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:lidarmesure/theme.dart';
import 'package:lidarmesure/models/session.dart';
import 'package:lidarmesure/models/user.dart';
import 'package:lidarmesure/models/medical_questionnaire.dart';
import 'package:lidarmesure/services/session_service.dart';
import 'package:lidarmesure/services/patient_service.dart';
import 'package:lidarmesure/services/pdf_report_service.dart';
import 'package:lidarmesure/components/medical_questionnaire_form.dart';
import 'package:lidarmesure/components/podology_ai_chat.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  bool _isEditingQuestionnaire = false;
  List<MedicalQuestionnaire> _editableQuestionnaires = [];

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
      _editableQuestionnaires = List.from(s?.questionnaires ?? []);
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

  String _getStatusLabelFr(SessionStatus status) {
    switch (status) {
      case SessionStatus.pending:
        return 'En attente';
      case SessionStatus.completed:
        return 'Terminée';
      case SessionStatus.cancelled:
        return 'Annulée';
    }
  }

  Future<void> _saveQuestionnaire() async {
    if (_session == null) return;
    
    try {
      final updatedSession = _session!.copyWith(
        questionnaires: _editableQuestionnaires,
        updatedAt: DateTime.now(),
      );
      
      await _sessionService.updateSession(updatedSession);
      
      setState(() {
        _session = updatedSession;
        _isEditingQuestionnaire = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).isFrench 
                ? 'Questionnaire sauvegardé' 
                : 'Questionnaire saved'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde questionnaire: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildHeader(BuildContext context, Session session) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(session.status, context);
    final statusLabel = l10n.isFrench ? _getStatusLabelFr(session.status) : _getStatusLabelEn(session.status);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          // Back button - consistent style
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
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
          const SizedBox(width: 12),
          // Title & status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sessionDetails,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // PDF Export button - consistent style
          GestureDetector(
            onTap: () => _exportPdf(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.1)
                    : cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.picture_as_pdf_rounded, color: cs.primary, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          // Delete button
          GestureDetector(
            onTap: () => _showDeleteSessionDialog(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.delete_outline_rounded, color: cs.error, size: 18),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Future<void> _exportPdf(BuildContext context) async {
    if (_session == null || _patient == null) return;
    final l10n = AppLocalizations.of(context);
    try {
      final pdfBytes = await PdfReportService.generateSessionReport(
        session: _session!,
        patient: _patient!,
        isFrench: l10n.isFrench,
      );
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.isFrench ? 'PDF généré' : 'PDF generated')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.isFrench ? 'Erreur export: $e' : 'Export error: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteSessionDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A2A2F) : cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_forever_rounded, color: cs.error, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.isFrench ? 'Supprimer la session' : 'Delete Session',
                style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.isFrench 
              ? 'Êtes-vous sûr de vouloir supprimer cette session et toutes ses mesures ? Cette action est irréversible.'
              : 'Are you sure you want to delete this session and all its measurements? This action cannot be undone.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.isFrench ? 'Annuler' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: Text(l10n.isFrench ? 'Supprimer' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _sessionService.deleteSession(_session!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.isFrench ? 'Session supprimée' : 'Session deleted'),
              backgroundColor: cs.primary,
            ),
          );
          // Retourner à la page du patient avec refresh
          if (_patient != null) {
            context.go('/patient/${_patient!.id}');
          } else if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.isFrench ? 'Erreur: $e' : 'Error: $e'),
              backgroundColor: cs.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_session == null) {
      return _NotFound(onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      });
    }

    final s = _session!;
    final cs = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton: _patient != null
          ? _buildAIAssistantFAB(context, s, cs, isDark)
          : null,
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
              _buildHeader(context, s),
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
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _patient!.fullName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppLocalizations.of(context).isFrench 
                                          ? 'Age ${_patient!.age} - Pointure ${_patient!.pointure}' 
                                          : 'Age ${_patient!.age} - Size ${_patient!.pointure}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push('/patient/${_patient!.id}'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context).isFrench ? 'Voir' : 'View',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: cs.primary,
                                    ),
                                  ),
                                ),
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

                      // Scan Images - Afficher les images debug (output) en priorité
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
                                Icon(Icons.auto_awesome, color: cs.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context).isFrench 
                                        ? 'Résultats d\'analyse' 
                                        : 'Analysis Results', 
                                    style: context.textStyles.titleMedium?.semiBold,
                                  ),
                                ),
                                if (s.footScan?.topViewDebug != null || s.footScan?.sideViewDebug != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: cs.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, size: 14, color: cs.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          'SAM',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: cs.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.md),
                            if (s.footScan == null)
                              Text(AppLocalizations.of(context).isFrench ? 'Aucune image scannée' : 'No scanned images', style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant))
                            else
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildScanImage(
                                          context,
                                          cs,
                                          imageUrl: s.footScan!.topViewDebug ?? s.footScan!.topView,
                                          label: AppLocalizations.of(context).isFrench ? 'Vue dessus' : 'Top view',
                                          isDebug: s.footScan!.topViewDebug != null,
                                        ),
                                      ),
                                      SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: _buildScanImage(
                                          context,
                                          cs,
                                          imageUrl: s.footScan!.sideViewDebug ?? s.footScan!.sideView,
                                          label: AppLocalizations.of(context).isFrench ? 'Vue profil' : 'Side view',
                                          isDebug: s.footScan!.sideViewDebug != null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms),

                      SizedBox(height: AppSpacing.lg),

                      // AI Analysis Section
                      if (_patient != null)
                        _buildAIAnalysisCard(context, s, cs, isDark),

                      if (_patient != null) SizedBox(height: AppSpacing.lg),

                      // Medical Questionnaire Section
                      Container(
                        padding: AppSpacing.paddingMd,
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: _isEditingQuestionnaire 
                                ? cs.primary.withValues(alpha: 0.5) 
                                : cs.outline.withValues(alpha: 0.2),
                            width: _isEditingQuestionnaire ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header avec boutons édition
                            Row(
                              children: [
                                Icon(Icons.medical_information_outlined, color: cs.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context).isFrench 
                                        ? 'Questionnaire Médical' 
                                        : 'Medical Questionnaire',
                                    style: context.textStyles.titleMedium?.semiBold,
                                  ),
                                ),
                                if (_isEditingQuestionnaire) ...[
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _editableQuestionnaires = List.from(s.questionnaires);
                                        _isEditingQuestionnaire = false;
                                      });
                                    },
                                    child: Text(AppLocalizations.of(context).isFrench ? 'Annuler' : 'Cancel'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: _saveQuestionnaire,
                                    icon: const Icon(Icons.save_outlined, size: 18),
                                    label: Text(AppLocalizations.of(context).isFrench ? 'Sauvegarder' : 'Save'),
                                  ),
                                ] else
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _editableQuestionnaires = List.from(s.questionnaires);
                                        _isEditingQuestionnaire = true;
                                      });
                                    },
                                    icon: Icon(Icons.edit_outlined, color: cs.primary),
                                    tooltip: AppLocalizations.of(context).isFrench ? 'Modifier' : 'Edit',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Formulaire
                            MedicalQuestionnaireForm(
                              questionnaires: _isEditingQuestionnaire 
                                  ? _editableQuestionnaires 
                                  : s.questionnaires,
                              onChanged: (updated) {
                                setState(() {
                                  _editableQuestionnaires = updated;
                                });
                              },
                              readOnly: !_isEditingQuestionnaire,
                            ),
                            
                            if (s.questionnaires.isNotEmpty && !_isEditingQuestionnaire) ...[
                              const SizedBox(height: 16),
                              MedicalConditionsSummary(questionnaires: s.questionnaires),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(delay: 350.ms),

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
      ),
    );
  }

  Widget _buildAIAnalysisCard(BuildContext context, Session session, ColorScheme cs, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final hasMetrics = session.footMetrics.isNotEmpty;
    final hasImages = session.footScan != null;
    
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  cs.primary.withOpacity(0.15),
                  cs.primary.withOpacity(0.05),
                ]
              : [
                  cs.primary.withOpacity(0.08),
                  cs.primary.withOpacity(0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.isFrench ? 'Assistant IA Podologique' : 'Podology AI Assistant',
                      style: context.textStyles.titleMedium?.semiBold,
                    ),
                    Text(
                      l10n.isFrench 
                          ? 'Analyse clinique intelligente' 
                          : 'Intelligent clinical analysis',
                      style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: cs.secondary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Gemini',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          
          // Status chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                icon: Icons.straighten,
                label: l10n.isFrench ? 'Métriques' : 'Metrics',
                isActive: hasMetrics,
                cs: cs,
              ),
              _StatusChip(
                icon: Icons.image_outlined,
                label: l10n.isFrench ? 'Images' : 'Images',
                isActive: hasImages,
                cs: cs,
              ),
              _StatusChip(
                icon: Icons.person_outline,
                label: l10n.isFrench ? 'Profil patient' : 'Patient profile',
                isActive: true,
                cs: cs,
              ),
            ],
          ),
          
          SizedBox(height: AppSpacing.md),
          
          // Description
          Text(
            l10n.isFrench
                ? 'L\'assistant IA peut analyser les images du scan, identifier les anomalies (Hallux Valgus, Pronation, etc.) et recommander des semelles adaptées.'
                : 'The AI assistant can analyze scan images, identify anomalies (Hallux Valgus, Pronation, etc.) and recommend suitable insoles.',
            style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant),
          ),
          
          SizedBox(height: AppSpacing.md),
          
          // Action button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openAIChat(context, session),
              icon: const Icon(Icons.chat_rounded, size: 18),
              label: Text(
                l10n.isFrench ? 'Démarrer l\'analyse IA' : 'Start AI Analysis',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1);
  }

  Widget _buildAIAssistantFAB(BuildContext context, Session session, ColorScheme cs, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _openAIChat(context, session),
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        icon: const Icon(Icons.psychology_rounded, color: Colors.white),
        label: Text(
          AppLocalizations.of(context).isFrench ? 'Assistant IA' : 'AI Assistant',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: 500.ms)
      .slideY(begin: 0.3)
      .then()
      .shimmer(duration: 2000.ms, delay: 1000.ms);
  }

  void _openAIChat(BuildContext context, Session session) {
    if (_patient == null) return;
    
    PodologyAIChat.show(
      context,
      patient: _patient!,
      session: session,
      topViewUrl: session.footScan?.topView,
      sideViewUrl: session.footScan?.sideView,
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

  Widget _buildScanImage(
    BuildContext context,
    ColorScheme cs, {
    required String imageUrl,
    required String label,
    required bool isDebug,
  }) {
    final hasImage = imageUrl.isNotEmpty;
    final isNetworkImage = imageUrl.startsWith('http');
    final isLocalFile = imageUrl.startsWith('/') && !imageUrl.startsWith('http');
    
    Widget buildImageWidget() {
      if (!hasImage) {
        return Center(child: Icon(Icons.image, color: cs.onSurfaceVariant));
      }
      
      if (isNetworkImage) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, color: cs.onSurfaceVariant),
                const SizedBox(height: 4),
                Text('Image non disponible', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        );
      }
      
      if (isLocalFile) {
        final file = File(imageUrl);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => Center(
              child: Icon(Icons.broken_image, color: cs.onSurfaceVariant),
            ),
          );
        } else {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_off, color: cs.onSurfaceVariant),
                const SizedBox(height: 4),
                Text('Fichier local', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
              ],
            ),
          );
        }
      }
      
      return Center(child: Icon(Icons.image, color: cs.onSurfaceVariant));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: isDebug 
                  ? Border.all(color: cs.primary.withValues(alpha: 0.3), width: 2)
                  : null,
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(isDebug ? AppRadius.md - 2 : AppRadius.md),
                  child: buildImageWidget(),
                ),
                
                // Badge SAM si image debug
                if (isDebug)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          const Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final ColorScheme cs;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive 
            ? cs.secondary.withOpacity(0.12)
            : cs.outline.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive 
              ? cs.secondary.withOpacity(0.3)
              : cs.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : icon,
            size: 14,
            color: isActive ? cs.secondary : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? cs.secondary : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lidarmesure/theme.dart';
import 'package:lidarmesure/services/patient_service.dart';
import 'package:lidarmesure/services/session_service.dart';
import 'package:lidarmesure/models/user.dart';
import 'package:lidarmesure/models/session.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io show File; // for FileImage on mobile
import 'package:flutter/foundation.dart';
import 'package:lidarmesure/l10n/app_localizations.dart';

class PatientDetailPage extends StatefulWidget {
  final String patientId;

  const PatientDetailPage({super.key, required this.patientId});

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  final PatientService _patientService = PatientService();
  final SessionService _sessionService = SessionService();
  Patient? _patient;
  List<Session> _sessions = [];
  bool _isLoading = true;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _patient = await _patientService.getPatientById(widget.patientId);
    _sessions = await _sessionService.getSessionsByPatientId(widget.patientId);
    _sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() => _isLoading = false);
  }

  Future<bool> _confirmDeleteSession(BuildContext context, Session session) async {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.isFrench 
              ? 'Êtes-vous sûr de vouloir supprimer cette session ?'
              : 'Are you sure you want to delete this session?',
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
    ) ?? false;
  }

  Future<void> _deleteSession(Session session) async {
    final l10n = AppLocalizations.of(context);
    try {
      await _sessionService.deleteSession(session.id);
      setState(() {
        _sessions.removeWhere((s) => s.id == session.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.isFrench ? 'Session supprimée' : 'Session deleted'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.isFrench ? 'Erreur: $e' : 'Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_patient == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
              SizedBox(height: AppSpacing.lg),
              Text(AppLocalizations.of(context).noPatientFound, style: context.textStyles.titleLarge?.semiBold),
              SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
                icon: const Icon(Icons.arrow_back),
                label: Text(AppLocalizations.of(context).back),
              ),
            ],
          ),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPatientInfo(context),
                      SizedBox(height: AppSpacing.xl),
                      _buildSessionsSection(context),
                      SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/scan');
          // Recharger les données au retour pour afficher la nouvelle session
          if (mounted) _loadData();
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
        label: Text(AppLocalizations.of(context).newScan, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
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
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(AppLocalizations.of(context).isFrench ? 'Profil Patient' : 'Patient Profile', style: context.textStyles.headlineMedium?.bold),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
            onPressed: () => context.push('/patient/${widget.patientId}/edit'),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            onPressed: () => _showDeletePatientDialog(context),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildPatientInfo(BuildContext context) {
    return Padding(
      padding: AppSpacing.horizontalLg,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: _showAvatarActions,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: _buildAvatarImage(context),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_rounded, size: 18, color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
              if (_isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ).animate().scale(delay: 200.ms, duration: 400.ms),
          SizedBox(height: AppSpacing.md),
          Text(_patient!.fullName, style: context.textStyles.headlineMedium?.bold).animate().fadeIn(delay: 300.ms),
          SizedBox(height: AppSpacing.xs),
          Text('${_patient!.age} ${AppLocalizations.of(context).isFrench ? 'ans' : 'yrs'} • ${_patient!.sexeLabel(isFrench: AppLocalizations.of(context).isFrench)}', 
            style: context.textStyles.bodyLarge?.withColor(Theme.of(context).colorScheme.onSurfaceVariant)).animate().fadeIn(delay: 400.ms),
          SizedBox(height: AppSpacing.lg),
          Builder(
            builder: (context) {
              final cs = Theme.of(context).colorScheme;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.06)
                      : cs.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.1)
                        : cs.outline.withValues(alpha: 0.15),
                  ),
                ),
            child: Column(
              children: [
                // _InfoRow(icon: Icons.email_outlined, label: 'Email', value: _patient!.email),
                // Divider(height: AppSpacing.lg),
                _InfoRow(icon: Icons.phone_outlined, label: AppLocalizations.of(context).phone, value: _patient!.telephone),
                Divider(height: AppSpacing.lg),
                _InfoRow(icon: Icons.location_on_outlined, label: AppLocalizations.of(context).address, value: _patient!.adresse),
                Divider(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(child: _InfoRow(icon: Icons.straighten, label: AppLocalizations.of(context).shoeSize, value: _patient!.pointure)),
                    Container(width: 1, height: 40, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                    Expanded(child: _InfoRow(icon: Icons.monitor_weight_outlined, label: AppLocalizations.of(context).weight, value: '${_patient!.poids} kg')),
                  ],
                ),
              ],
            ),
              );
            },
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildSessionsSection(BuildContext context) {
    return Padding(
      padding: AppSpacing.horizontalLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('${AppLocalizations.of(context).isFrench ? "Sessions" : "Sessions"} (${_sessions.length})', style: context.textStyles.titleLarge?.semiBold)),
              OutlinedButton.icon(
                onPressed: () => context.push('/add-session?patientId=${widget.patientId}'),
                icon: const Icon(Icons.add_circle_outline),
                label: Text(AppLocalizations.of(context).isFrench ? 'Nouvelle session' : 'New session'),
              ),
              const SizedBox(width: 8),
              if (_sessions.isNotEmpty)
                TextButton(
                  onPressed: () => context.push('/history'),
                  child: Text(AppLocalizations.of(context).seeAll, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          if (_sessions.isEmpty)
            Center(
              child: Padding(
                padding: AppSpacing.paddingXl,
                child: Column(
                  children: [
                    Icon(Icons.history, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    SizedBox(height: AppSpacing.md),
                    Text(AppLocalizations.of(context).noSessions, style: context.textStyles.bodyMedium?.withColor(Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sessions.length,
              separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final session = _sessions[index];
                return _SwipeableSessionCard(
                  session: session,
                  onTap: () => context.push('/session/${session.id}'),
                  onDelete: () => _deleteSession(session),
                  confirmDelete: () => _confirmDeleteSession(context, session),
                ).animate().fadeIn(delay: (100 * index).ms);
              },
            ),
        ],
      ),
    );
  }
  Widget _buildAvatarImage(BuildContext context) {
    final avatarUrl = _patient!.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('http')) {
        return ClipOval(
          child: Image.network(
            avatarUrl,
            fit: BoxFit.cover,
            width: 120,
            height: 120,
            errorBuilder: (_, __, ___) => _buildInitialsAvatar(context),
          ),
        );
      }
      if (avatarUrl.startsWith('file://') && !kIsWeb) {
        try {
          final filePath = avatarUrl.replaceFirst('file://', '');
          return ClipOval(
            child: Image(
              image: FileImage(io.File(filePath)),
              fit: BoxFit.cover,
              width: 120,
              height: 120,
            ),
          );
        } catch (_) {
          return _buildInitialsAvatar(context);
        }
      }
    }
    return _buildInitialsAvatar(context);
  }

  Widget _buildInitialsAvatar(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${_patient!.prenom[0]}${_patient!.nom[0]}'.toUpperCase(),
          style: context.textStyles.displaySmall?.bold.withColor(Colors.white),
        ),
      ),
    );
  }

  void _showAvatarActions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.photo_camera_outlined, color: Theme.of(context).colorScheme.primary),
                  title: Text(AppLocalizations.of(context).isFrench ? 'Prendre une photo' : 'Take a photo'),
                  onTap: () => _pickAndUpload(ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_outlined, color: Theme.of(context).colorScheme.primary),
                  title: Text(AppLocalizations.of(context).isFrench ? 'Choisir depuis la galerie' : 'Choose from gallery'),
                  onTap: () => _pickAndUpload(ImageSource.gallery),
                ),
                if (_patient!.avatarUrl != null)
                  ListTile(
                    leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                    title: Text(AppLocalizations.of(context).isFrench ? 'Supprimer la photo' : 'Delete photo'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      final updated = _patient!.copyWith(avatarUrl: null);
                      await _patientService.updatePatient(updated);
                      setState(() => _patient = updated);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    Navigator.of(context).pop();
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (file == null) return;

      setState(() => _isUploading = true);

      final bytes = await file.readAsBytes();
      final fileName = file.name.isNotEmpty ? file.name : 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final url = await _patientService.uploadAvatar(
        patientId: _patient!.id,
        fileBytes: bytes,
        fileName: fileName,
      );
      
      if (url != null && url.isNotEmpty) {
        await _patientService.setAvatarUrl(patientId: _patient!.id, avatarUrl: url);
        final updated = _patient!.copyWith(avatarUrl: url);
        setState(() => _patient = updated);
      }
    } catch (e) {
      debugPrint('Avatar pick/upload error: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _showDeletePatientDialog(BuildContext context) async {
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
                l10n.isFrench ? 'Supprimer le patient' : 'Delete Patient',
                style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.isFrench 
              ? 'Êtes-vous sûr de vouloir supprimer ce patient et toutes ses données ? Cette action est irréversible.'
              : 'Are you sure you want to delete this patient and all their data? This action cannot be undone.',
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
        await _patientService.deletePatient(_patient!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.isFrench ? 'Patient supprimé' : 'Patient deleted'),
              backgroundColor: cs.primary,
            ),
          );
          context.go('/patients');
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
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.textStyles.bodySmall?.withColor(Theme.of(context).colorScheme.onSurfaceVariant)),
              Text(value, style: context.textStyles.bodyMedium?.medium, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;

  const _SessionCard({
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: AppSpacing.paddingSm,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getStatusColor(session.status, context).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(Icons.analytics_outlined, color: _getStatusColor(session.status, context), size: 20),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.formattedDate, style: context.textStyles.bodyMedium?.medium),
                  Text(session.statusLabel, style: context.textStyles.bodySmall?.withColor(Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
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
}

class _SwipeableSessionCard extends StatefulWidget {
  final Session session;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Future<bool> Function() confirmDelete;

  const _SwipeableSessionCard({
    required this.session,
    required this.onTap,
    required this.onDelete,
    required this.confirmDelete,
  });

  @override
  State<_SwipeableSessionCard> createState() => _SwipeableSessionCardState();
}

class _SwipeableSessionCardState extends State<_SwipeableSessionCard> {
  double _dragExtent = 0;
  bool _isDeleting = false;
  static const double _deleteThreshold = 80;

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
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragExtent = (_dragExtent + details.delta.dx).clamp(-120.0, 0.0);
        });
      },
      onHorizontalDragEnd: (details) async {
        if (_dragExtent.abs() > _deleteThreshold) {
          final confirmed = await widget.confirmDelete();
          if (confirmed) {
            setState(() => _isDeleting = true);
            widget.onDelete();
          } else {
            setState(() => _dragExtent = 0);
          }
        } else {
          setState(() => _dragExtent = 0);
        }
      },
      onTap: _dragExtent == 0 ? widget.onTap : () => setState(() => _dragExtent = 0),
      child: Stack(
        children: [
          // Delete background
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: cs.error,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, color: Colors.white, size: 22),
                  const SizedBox(height: 2),
                  Text(
                    l10n.isFrench ? 'Supprimer' : 'Delete',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          // Card content
          AnimatedContainer(
            duration: _dragExtent == 0 ? const Duration(milliseconds: 200) : Duration.zero,
            transform: Matrix4.translationValues(_dragExtent, 0, 0),
            child: Container(
              padding: AppSpacing.paddingSm,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getStatusColor(widget.session.status, context).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(Icons.analytics_outlined, color: _getStatusColor(widget.session.status, context), size: 20),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.session.formattedDate, style: context.textStyles.bodyMedium?.medium),
                        Text(widget.session.statusLabel, style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

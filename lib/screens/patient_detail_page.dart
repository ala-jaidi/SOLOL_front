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
              Text('Patient non trouvé', style: context.textStyles.titleLarge?.semiBold),
              SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/scan');
          // Recharger les données au retour pour afficher la nouvelle session
          if (mounted) _loadData();
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
        label: Text('Nouveau Scan', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingLg,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => context.pop(),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text('Profil Patient', style: context.textStyles.headlineMedium?.bold),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
            onPressed: () {},
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
          Text('${_patient!.age} ans • ${_patient!.sexe}', 
            style: context.textStyles.bodyLarge?.withColor(Theme.of(context).colorScheme.onSurfaceVariant)).animate().fadeIn(delay: 400.ms),
          SizedBox(height: AppSpacing.lg),
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                _InfoRow(icon: Icons.email_outlined, label: 'Email', value: _patient!.email),
                Divider(height: AppSpacing.lg),
                _InfoRow(icon: Icons.phone_outlined, label: 'Téléphone', value: _patient!.telephone),
                Divider(height: AppSpacing.lg),
                _InfoRow(icon: Icons.location_on_outlined, label: 'Adresse', value: _patient!.adresse),
                Divider(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(child: _InfoRow(icon: Icons.straighten, label: 'Pointure', value: _patient!.pointure)),
                    Container(width: 1, height: 40, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                    Expanded(child: _InfoRow(icon: Icons.monitor_weight_outlined, label: 'Poids', value: '${_patient!.poids} kg')),
                  ],
                ),
              ],
            ),
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
              Expanded(child: Text('Sessions (${_sessions.length})', style: context.textStyles.titleLarge?.semiBold)),
              OutlinedButton.icon(
                onPressed: () => context.push('/add-session?patientId=${widget.patientId}'),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Nouvelle session'),
              ),
              const SizedBox(width: 8),
              if (_sessions.isNotEmpty)
                TextButton(
                  onPressed: () => context.push('/history'),
                  child: Text('Voir tout', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
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
                    Text('Aucune session', style: context.textStyles.bodyMedium?.withColor(Theme.of(context).colorScheme.onSurfaceVariant)),
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
                return _SessionCard(
                  session: session,
                  onTap: () => context.push('/session/${session.id}'),
                ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.2);
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
                  title: const Text('Prendre une photo'),
                  onTap: () => _pickAndUpload(ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_outlined, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Choisir depuis la galerie'),
                  onTap: () => _pickAndUpload(ImageSource.gallery),
                ),
                if (_patient!.avatarUrl != null)
                  ListTile(
                    leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                    title: const Text('Supprimer la photo'),
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
      case SessionStatus.enCours:
        return Theme.of(context).colorScheme.tertiary;
      case SessionStatus.termine:
        return Theme.of(context).colorScheme.secondary;
      case SessionStatus.annule:
        return Theme.of(context).colorScheme.error;
    }
  }
}

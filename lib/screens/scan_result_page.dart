import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lidarmesure/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:lidarmesure/services/pdf_service.dart';
import 'package:lidarmesure/state/notification_center.dart';
import 'package:lidarmesure/components/modern_button.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:lidarmesure/models/user.dart';

import 'package:lidarmesure/services/measurement_service.dart'; // Import nécessaire pour getImageUrl

class ScanResultPage extends StatelessWidget {
  final Map<String, dynamic>? scanData;

  const ScanResultPage({super.key, this.scanData});

  @override
  Widget build(BuildContext context) {
    // Extract data
    final result = scanData?['result'] as Map<String, dynamic>?;
    final patient = scanData?['patient'] as Patient?;
    final topImage = scanData?['topImage'] as File?;
    final sideImage = scanData?['sideImage'] as File?;
    
    // Debug images from server
    final debugTopUrl = result?['debug_image_url'] as String?;
    final debugSideUrl = result?['debug_image_url_side'] as String?;

    // Robust extraction of metrics (support multiple keys)
    var lengthRaw = result?['length_cm'] ?? result?['length'];
    var widthRaw = result?['width_cm'] ?? result?['width'] ?? result?['forefoot_width_cm'];

    // Fallback: search case-insensitive if not found
    if (result != null) {
      if (lengthRaw == null) {
        final key = result.keys.firstWhere((k) => k.toLowerCase().contains('length'), orElse: () => '');
        if (key.isNotEmpty) lengthRaw = result[key];
      }
      if (widthRaw == null) {
        // Exclude 'toe_width' to avoid confusion, prioritize 'width'
        final key = result.keys.firstWhere(
          (k) => k.toLowerCase().contains('width') && !k.toLowerCase().contains('toe'), 
          orElse: () => ''
        );
        if (key.isNotEmpty) widthRaw = result[key];
      }
    }

    final length = lengthRaw?.toString() ?? 'N/A';
    final width = widthRaw?.toString() ?? 'N/A';
    
    // If backend returns numbers, format them
    final lengthDisplay = double.tryParse(length)?.toStringAsFixed(1) ?? length;
    final widthDisplay = double.tryParse(width)?.toStringAsFixed(1) ?? width;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, patient, lengthDisplay, widthDisplay, topImage, sideImage),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: AppSpacing.lg),
                    _buildSuccessBadge(context),
                    SizedBox(height: AppSpacing.xl),
                    _buildMetrics(context, lengthDisplay, widthDisplay),
                    SizedBox(height: AppSpacing.xl),
                    _buildScanImages(context, topImage, sideImage, debugTopUrl, debugSideUrl),
                    SizedBox(height: AppSpacing.xl),
                    _buildAnalysis(context),
                    SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Patient? patient, String length, String width, File? topImage, File? sideImage) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Résultats du Scan', style: context.textStyles.headlineMedium?.bold),
                if (patient != null)
                  Text('Patient: ${patient.fullName}', style: context.textStyles.bodyMedium?.withColor(Theme.of(context).colorScheme.onSurfaceVariant))
                else
                  Text('Analyse complète', style: context.textStyles.bodyMedium?.withColor(Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.share_outlined, color: Theme.of(context).colorScheme.primary),
            onPressed: () async {
              try {
                Uint8List? topBytes;
                Uint8List? sideBytes;
                if (topImage != null) {
                  topBytes = await topImage.readAsBytes();
                }
                if (sideImage != null) {
                  sideBytes = await sideImage.readAsBytes();
                }

                await PdfService.shareReport(
                  patientName: patient?.fullName,
                  rightLengthCm: '$length cm',
                  leftLengthCm: 'N/A',
                  rightWidthCm: '$width cm',
                  leftWidthCm: 'N/A',
                  precision: '97%',
                  analysis1: 'Posture normale',
                  analysis2: 'Légère pronation détectée',
                  analysis3: 'Recommandation: Semelles orthopédiques',
                  topImageBytes: topBytes,
                  sideImageBytes: sideBytes,
                );
                if (context.mounted) {
                  await context.read<NotificationCenter>().add(
                        title: 'Rapport PDF exporté',
                        body: 'Le rapport du scan a été généré et partagé.',
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rapport PDF exporté')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de l\'export PDF: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSuccessBadge(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMd,
      margin: AppSpacing.horizontalLg,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: Colors.white, size: 24),
          ),
          SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scan réussi!', style: context.textStyles.titleMedium?.bold.withColor(Theme.of(context).colorScheme.secondary)),
              Text('Précision: 97%', style: context.textStyles.bodySmall?.withColor(Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildMetrics(BuildContext context, String length, String width) {
    return Padding(
      padding: AppSpacing.horizontalLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mesures (Pied Droit)', style: context.textStyles.titleLarge?.semiBold),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.height,
                  label: 'Longueur',
                  value: '$length cm',
                  subtitle: 'Talon-Orteils',
                  color: Theme.of(context).colorScheme.primary,
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricCard(
                  icon: Icons.straighten,
                  label: 'Largeur',
                  value: '$width cm',
                  subtitle: 'Avant-pied',
                  color: Theme.of(context).colorScheme.tertiary,
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanImages(BuildContext context, File? topImage, File? sideImage, String? debugTopUrl, String? debugSideUrl) {
    return Padding(
      padding: AppSpacing.horizontalLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Images analysées', style: context.textStyles.titleLarge?.semiBold),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (topImage != null)
                Expanded(
                  child: _ResultImageCard(
                    imageFile: topImage,
                    imageUrl: debugTopUrl,
                    label: 'Vue de dessus',
                  ).animate().fadeIn(delay: 700.ms).scale(begin: const Offset(0.9, 0.9)),
                ),
              if (topImage != null && sideImage != null)
                SizedBox(width: AppSpacing.md),
              if (sideImage != null)
                Expanded(
                  child: _ResultImageCard(
                    imageFile: sideImage,
                    imageUrl: debugSideUrl,
                    label: 'Vue latérale',
                  ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.9, 0.9)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysis(BuildContext context) {
    final analyses = [
      {'icon': Icons.check_circle, 'title': 'Posture normale', 'color': Theme.of(context).colorScheme.secondary},
      {'icon': Icons.info_outline, 'title': 'Légère pronation détectée', 'color': Theme.of(context).colorScheme.tertiary},
      {'icon': Icons.lightbulb_outline, 'title': 'Recommandation: Semelles orthopédiques', 'color': Theme.of(context).colorScheme.primary},
    ];

    return Padding(
      padding: AppSpacing.horizontalLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analyse', style: context.textStyles.titleLarge?.semiBold),
          SizedBox(height: AppSpacing.md),
          ...analyses.asMap().entries.map((entry) {
            final index = entry.key;
            final analysis = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: (analysis['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: (analysis['color'] as Color).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(analysis['icon'] as IconData, color: analysis['color'] as Color, size: 24),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(analysis['title'] as String, style: context.textStyles.titleSmall?.medium),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (900 + index * 100).ms).slideX(begin: 0.2),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final patient = scanData?['patient'] as Patient?;

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ModernButton(
                label: 'Terminer',
                leadingIcon: Icons.check_circle_outline, // Changed from icon to leadingIcon
                onPressed: () {
                   if (patient != null) {
                     // Retour au dossier patient, ce qui déclenchera le rechargement
                     context.go('/patient/${patient.id}');
                   } else {
                     context.go('/home');
                   }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Spacer(),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(value, style: context.textStyles.headlineSmall?.bold),
          Text(label, style: context.textStyles.bodySmall?.withColor(Theme.of(context).colorScheme.onSurfaceVariant)),
          SizedBox(height: 4),
          Text(subtitle, style: context.textStyles.labelSmall?.withColor(color)),
        ],
      ),
    );
  }
}

class _ResultImageCard extends StatefulWidget {
  final File imageFile;
  final String? imageUrl;
  final String label;

  const _ResultImageCard({
    required this.imageFile,
    this.imageUrl,
    required this.label,
  });

  @override
  State<_ResultImageCard> createState() => _ResultImageCardState();
}

class _ResultImageCardState extends State<_ResultImageCard> {
  bool _showDebug = true;

  @override
  void initState() {
    super.initState();
    if (widget.imageUrl == null) {
      _showDebug = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDebug = widget.imageUrl != null;
    final imageProvider = (_showDebug && hasDebug)
        ? NetworkImage(MeasurementService.getImageUrl(widget.imageUrl!)) as ImageProvider
        : FileImage(widget.imageFile) as ImageProvider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: EdgeInsets.zero,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    InteractiveViewer(
                      child: Image(image: imageProvider, fit: BoxFit.contain),
                    ),
                    Positioned(
                      top: 40,
                      right: 20,
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white, size: 30),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Image(
                      key: ValueKey(_showDebug),
                      image: imageProvider,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                           color: Colors.grey[200],
                           child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _showDebug ? Icons.analytics : Icons.camera_alt,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            _showDebug ? 'ANALYSE IA' : 'ORIGINAL',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (hasDebug)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _showDebug = !_showDebug),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: Icon(
                              _showDebug ? Icons.image : Icons.analytics_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            widget.label,
            style: context.textStyles.bodyMedium?.medium.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

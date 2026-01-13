import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lidarmesure/theme.dart';
import 'package:lidarmesure/services/patient_service.dart';
import 'package:lidarmesure/services/measurement_service.dart';
import 'package:lidarmesure/services/session_service.dart';
import 'package:lidarmesure/models/user.dart';
import 'package:lidarmesure/models/session.dart';
import 'package:lidarmesure/models/foot_metrics.dart';
import 'package:lidarmesure/models/foot_scan.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:lidarmesure/components/gradient_header.dart';
import 'package:lidarmesure/components/modern_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:lidarmesure/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:lidarmesure/state/notification_center.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final PatientService _patientService = PatientService();
  final MeasurementService _measurementService = MeasurementService();
  final SessionService _sessionService = SessionService();
  final ImagePicker _picker = ImagePicker();
  
  Patient? _selectedPatient;
  FootSide _selectedSide = FootSide.droite;
  bool _isScanning = false;
  
  String get _sideParam => _selectedSide == FootSide.droite ? 'right' : 'left';
  
  File? _topImage;
  File? _sideImage;

  Future<void> _selectPatient() async {
    final patients = await _patientService.getAllPatients();
    if (!mounted) return;
    
    final selected = await showModalBottomSheet<Patient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PatientSelectorSheet(patients: patients),
    );
    
    if (selected != null) {
      if (!mounted) return;
      setState(() => _selectedPatient = selected);
    }
  }

  Future<void> _takePhoto(bool isTop) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (photo != null) {
        final imageFile = File(photo.path);
        setState(() {
          if (isTop) {
            _topImage = imageFile;
            // Ne pas lancer l'analyse ici - on attend d'avoir les deux images
            // pour utiliser l'endpoint hybride /measure
          } else {
            _sideImage = imageFile;
            // Ne pas lancer l'analyse ici - on attend d'avoir les deux images
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.read(context).isFrench ? 'Erreur camera: $e' : 'Camera error: $e')),
      );
    }
  }

  Future<void> _finishAndShowResults() async {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.read(context).isFrench ? 'Veuillez selectionner un patient' : 'Please select a patient')),
      );
      return;
    }
    if (_topImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.read(context).isFrench ? 'La photo de dessus est requise' : 'Top view photo is required')),
      );
      return;
    }
    if (_sideImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.read(context).isFrench ? 'La photo de profil est requise' : 'Side view photo is required')),
      );
      return;
    }

    setState(() {
      _isScanning = true;
    });

    // Notification: Analyse en cours
    final notificationCenter = context.read<NotificationCenter>();
    final l10n = AppLocalizations.read(context);
    await notificationCenter.add(
      title: l10n.isFrench ? 'Analyse en cours' : 'Analysis in progress',
      body: l10n.isFrench 
          ? 'Les photos de ${_selectedPatient!.fullName} sont en cours d\'analyse...'
          : 'Photos of ${_selectedPatient!.fullName} are being analyzed...',
    );

    try {
      // Utiliser l'endpoint hybride /measure qui envoie les deux images en une seule requête
      // Compatible avec le backend python_test_solol
      debugPrint('🚀 Envoi des deux images vers /measure (foot_side: $_sideParam)');
      
      final finalResult = await _measurementService.analyzeHybrid(
        topView: _topImage!,
        sideView: _sideImage!,
        footSide: _sideParam,
      );

      debugPrint('📦 Résultat hybride: $finalResult');

      // Sauvegarde automatique de la session
      if (_selectedPatient != null) {
        try {
          final now = DateTime.now();
          final sessionId = const Uuid().v4();
          
          // Recherche robuste des clés
          final lenVal = finalResult['length_cm'] ?? finalResult['length'];
          final widVal = finalResult['width_cm'] ?? finalResult['width'] ?? finalResult['forefoot_width_cm'];
          
          final metrics = FootMetrics(
            id: const Uuid().v4(),
            side: _selectedSide,
            longueur: (lenVal as num?)?.toDouble() ?? 0.0,
            largeur: (widVal as num?)?.toDouble() ?? 0.0,
            confidence: 0.95,
            createdAt: now,
            updatedAt: now,
          );

          // Utiliser les URLs de debug du serveur (images analysées par l'IA)
          final topDebugUrl = finalResult['top_debug_image_url'] as String?;
          final sideDebugUrl = finalResult['side_debug_image_url'] as String?;
          
          final scan = FootScan(
            topView: topDebugUrl != null 
                ? MeasurementService.getImageUrl(topDebugUrl) 
                : _topImage!.path,
            sideView: sideDebugUrl != null 
                ? MeasurementService.getImageUrl(sideDebugUrl) 
                : (_sideImage?.path ?? ''),
            angle: AngleType.top,
            createdAt: now,
            updatedAt: now,
          );

          final session = Session(
            id: sessionId,
            patientId: _selectedPatient!.id,
            createdAt: now,
            status: SessionStatus.completed,
            valid: true,
            footMetrics: [metrics],
            footScan: scan,
            updatedAt: now,
          );

          await _sessionService.addSession(session);
          debugPrint('✅ Session sauvegardée avec succès: $sessionId');
          
          // Notification: Résultats prêts
          await notificationCenter.add(
            title: l10n.isFrench ? 'Résultats prêts' : 'Results ready',
            body: l10n.isFrench 
                ? 'L\'analyse de ${_selectedPatient!.fullName} est terminée. Longueur: ${metrics.formattedLongueur}, Largeur: ${metrics.formattedLargeur}'
                : 'Analysis of ${_selectedPatient!.fullName} is complete. Length: ${metrics.formattedLongueur}, Width: ${metrics.formattedLargeur}',
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.isFrench ? 'Resultats sauvegardes avec succes' : 'Results saved successfully'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          debugPrint('❌ Erreur sauvegarde session: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.read(context).isFrench ? 'Attention: Erreur de sauvegarde ($e)' : 'Warning: Save error ($e)'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          // On continue quand même vers les résultats pour ne pas bloquer l'utilisateur
        }
      }

      // Analyse terminée
      
      if (!mounted) return;
      
      context.push('/scan-result', extra: {
        'result': finalResult,
        'patient': _selectedPatient,
        'topImage': _topImage,
        'sideImage': _sideImage,
      });

    } catch (e) {
      String errorMessage = 'Erreur d\'analyse: $e';
      if (e.toString().contains('SocketException') || e.toString().contains('Network is unreachable')) {
        errorMessage = 'Erreur réseau: Impossible de joindre le serveur.\n'
            'Vérifiez l\'adresse IP et assurez-vous que le serveur Python est lancé.';
      } else if (e.toString().contains('ClientException')) {
         errorMessage = 'Erreur de connexion: Vérifiez que l\'adresse IP est correcte.';
      }

      // Notification: Erreur d'analyse
      await notificationCenter.add(
        title: l10n.isFrench ? 'Erreur d\'analyse' : 'Analysis error',
        body: l10n.isFrench 
            ? 'L\'analyse de ${_selectedPatient!.fullName} a échoué. Veuillez réessayer.'
            : 'Analysis of ${_selectedPatient!.fullName} failed. Please try again.',
      );

      debugPrint('❌ Erreur dans _finishAndShowResults: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    children: [
                      const SizedBox(height: 20),
                      _buildPatientSelector(context),
                      const SizedBox(height: 20),
                      _buildSideSelector(context),
                      const SizedBox(height: 24),
                      _buildScanArea(context),
                      const SizedBox(height: 24),
                      _buildInstructions(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              _buildBottomActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Back button
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
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.newScan,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  l10n.scanTitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Scan icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildPatientSelector(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _isScanning ? null : _selectPatient,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.08)
                : cs.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _selectedPatient != null 
                  ? cs.primary.withValues(alpha: 0.5)
                  : isDark 
                      ? Colors.white.withValues(alpha: 0.1)
                      : cs.primary.withValues(alpha: 0.2),
              width: _selectedPatient != null ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _selectedPatient != null 
                        ? [cs.primary, cs.primary.withValues(alpha: 0.7)]
                        : [cs.onSurfaceVariant.withValues(alpha: 0.3), cs.onSurfaceVariant.withValues(alpha: 0.2)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _selectedPatient == null ? Icons.person_add_rounded : Icons.person_rounded, 
                  color: Colors.white, 
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedPatient == null 
                          ? (l10n.isFrench ? 'Sélectionner un patient' : 'Select a patient')
                          : _selectedPatient!.fullName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_selectedPatient != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedPatient!.age} ${l10n.isFrench ? 'ans' : 'years'} • ${l10n.isFrench ? 'Pointure' : 'Size'} ${_selectedPatient!.pointure}', 
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ] else
                      Text(
                        l10n.isFrench ? 'Appuyez pour choisir' : 'Tap to choose',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              // Arrow
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_right_rounded, color: cs.primary, size: 20),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildScanArea(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.camera_alt_rounded, color: cs.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.isFrench ? 'Captures requises' : 'Required captures',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Two views side by side
          Row(
            children: [
              // Vue de dessus (Obligatoire)
              Expanded(
                child: _buildModernImageCard(
                  context,
                  l10n.isFrench ? 'Vue dessus' : 'Top view',
                  l10n.isFrench ? 'Obligatoire' : 'Required',
                  Icons.vertical_align_top_rounded,
                  _topImage,
                  () => _takePhoto(true),
                  isRequired: true,
                  isAnalyzing: false,
                  analysisFuture: null,
                ),
              ),
              const SizedBox(width: 12),
              // Vue de profil (Obligatoire)
              Expanded(
                child: _buildModernImageCard(
                  context,
                  l10n.isFrench ? 'Vue profil' : 'Side view',
                  l10n.isFrench ? 'Obligatoire' : 'Required',
                  Icons.swap_horiz_rounded,
                  _sideImage,
                  () => _takePhoto(false),
                  isRequired: true,
                  isAnalyzing: false,
                  analysisFuture: null,
                ),
              ),
            ],
          ),
          
          // Status indicators
          if (_topImage != null || _sideImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.05)
                      : cs.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.1)
                        : cs.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    _buildStatusIndicator(
                      context,
                      l10n.isFrench ? 'Dessus' : 'Top',
                      _topImage != null,
                      null,
                    ),
                    const SizedBox(width: 16),
                    Container(width: 1, height: 24, color: cs.outline.withValues(alpha: 0.2)),
                    const SizedBox(width: 16),
                    _buildStatusIndicator(
                      context,
                      l10n.isFrench ? 'Profil' : 'Side',
                      _sideImage != null,
                      null,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
  
  Widget _buildModernImageCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    File? image,
    VoidCallback onTap, {
    bool isRequired = false,
    bool isAnalyzing = false,
    Future<Map<String, dynamic>>? analysisFuture,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: _isScanning ? null : onTap,
      child: AspectRatio(
        aspectRatio: 0.85,
        child: Container(
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.06)
                : cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: image != null 
                  ? cs.primary.withValues(alpha: 0.5)
                  : isDark 
                      ? Colors.white.withValues(alpha: 0.1)
                      : cs.outline.withValues(alpha: 0.2),
              width: image != null ? 2 : 1,
            ),
            boxShadow: image != null ? [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(image, fit: BoxFit.cover),
                      // Overlay gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                      // Edit button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.edit_rounded, color: cs.primary, size: 16),
                        ),
                      ),
                      // Title at bottom
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, size: 28, color: cs.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isRequired 
                            ? cs.error.withValues(alpha: 0.1)
                            : cs.onSurfaceVariant.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isRequired ? cs.error : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(Icons.add_a_photo_rounded, size: 20, color: cs.onSurfaceVariant),
                  ],
                ),
        ),
      ),
    );
  }
  
  Widget _buildStatusIndicator(BuildContext context, String label, bool hasImage, Future<Map<String, dynamic>>? future) {
    final cs = Theme.of(context).colorScheme;
    
    return Expanded(
      child: Row(
        children: [
          if (!hasImage)
            Icon(Icons.radio_button_unchecked, size: 18, color: cs.onSurfaceVariant)
          else if (future != null)
            FutureBuilder(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                  );
                }
                return Icon(Icons.check_circle_rounded, size: 18, color: Colors.green);
              },
            )
          else
            Icon(Icons.check_circle_rounded, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: hasImage ? cs.onSurface : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(BuildContext context, String title, File? image, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _isScanning ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(image, fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    )
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 48, color: cs.primary),
                  SizedBox(height: AppSpacing.sm),
                  Text(title, style: context.textStyles.titleMedium?.semiBold),
                  Text(AppLocalizations.of(context).isFrench ? 'Appuyer pour scanner' : 'Tap to scan', style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant)),
                ],
              ),
      ),
    );
  }

  Widget _buildInstructions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final instructions = l10n.isFrench ? [
      {'icon': Icons.phone_iphone, 'title': 'Position', 'desc': 'Maintenez votre telephone a 30cm du pied'},
      {'icon': Icons.lightbulb_outline, 'title': 'Eclairage', 'desc': 'Assurez-vous d\'avoir un bon eclairage'},
      {'icon': Icons.accessibility_new, 'title': 'Calibration', 'desc': 'Placez un marqueur ArUco ou une carte'},
    ] : [
      {'icon': Icons.phone_iphone, 'title': 'Position', 'desc': 'Hold your phone 30cm from the foot'},
      {'icon': Icons.lightbulb_outline, 'title': 'Lighting', 'desc': 'Ensure good lighting'},
      {'icon': Icons.accessibility_new, 'title': 'Calibration', 'desc': 'Place an ArUco marker or card'},
    ];

    return Padding(
      padding: AppSpacing.horizontalLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.isFrench ? 'Instructions' : 'Instructions', style: context.textStyles.titleLarge?.semiBold),
          SizedBox(height: AppSpacing.md),
          ...instructions.asMap().entries.map((entry) {
            final index = entry.key;
            final inst = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: _InstructionCard(
                icon: inst['icon'] as IconData,
                title: inst['title'] as String,
                description: inst['desc'] as String,
              ).animate().fadeIn(delay: (400 + index * 100).ms).slideX(begin: 0.2),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSideSelector(BuildContext context) {
    return Padding(
      padding: AppSpacing.horizontalLg,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(child: _buildSideOption(context, FootSide.gauche, AppLocalizations.of(context).leftFoot)),
            Expanded(child: _buildSideOption(context, FootSide.droite, AppLocalizations.of(context).rightFoot)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }

  Widget _buildSideOption(BuildContext context, FootSide side, String label) {
    final isSelected = _selectedSide == side;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _isScanning ? null : () => setState(() => _selectedSide = side),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: isSelected ? [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: context.textStyles.titleSmall?.copyWith(
            color: isSelected ? Colors.white : cs.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    if (_topImage == null) return SizedBox.shrink();

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
        child: ModernButton(
          label: _isScanning ? 'Finalisation...' : 'Voir les résultats',
          onPressed: _isScanning ? null : _finishAndShowResults,
          leadingIcon: _isScanning ? Icons.sync : Icons.check_circle_outline,
          variant: ModernButtonVariant.primary,
          size: ModernButtonSize.large,
          expand: true,
          loading: _isScanning,
        ),
      ),
    ).animate().slideY(begin: 1.0, duration: 300.ms);
  }
}

class _InstructionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InstructionCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMd,
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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.titleSmall?.semiBold),
                Text(description, style: context.textStyles.bodySmall?.withColor(Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientSelectorSheet extends StatelessWidget {
  final List<Patient> patients;

  const _PatientSelectorSheet({required this.patients});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: AppSpacing.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Padding(
            padding: AppSpacing.horizontalLg,
            child: Text('Sélectionner un patient', style: context.textStyles.titleLarge?.bold),
          ),
          SizedBox(height: AppSpacing.md),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: AppSpacing.paddingLg,
              itemCount: patients.length,
              separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final patient = patients[index];
                return InkWell(
                  onTap: () => context.pop(patient),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Center(
                            child: Text(
                              '${patient.prenom[0]}${patient.nom[0]}'.toUpperCase(),
                              style: context.textStyles.titleMedium?.bold.withColor(Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(patient.fullName, style: context.textStyles.titleSmall?.semiBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('${patient.age} ans • Pointure ${patient.pointure}', 
                                style: context.textStyles.bodySmall?.withColor(Theme.of(context).colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

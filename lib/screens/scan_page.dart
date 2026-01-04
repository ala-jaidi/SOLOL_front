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
  
  // Futures pour suivre l'analyse en arrière-plan
  Future<Map<String, dynamic>>? _topAnalysisFuture;
  Future<Map<String, dynamic>>? _sideAnalysisFuture;

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
            // Lancer l'analyse TOP en arrière-plan
            _topAnalysisFuture = _measurementService.analyzeTopView(image: _topImage!, footSide: _sideParam);
          } else {
            _sideImage = imageFile;
            // Lancer l'analyse SIDE en SÉQUENTIEL (après TOP) pour la performance
            // On attend que le TOP soit fini avant de lancer le SIDE
            _sideAnalysisFuture = (() async {
              if (_topAnalysisFuture != null) {
                try {
                  await _topAnalysisFuture;
                } catch (e) {
                  debugPrint('Erreur TOP ignorée pour lancer SIDE: $e');
                }
              }
              return _measurementService.analyzeSideView(image: imageFile, footSide: _sideParam);
            })();
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur caméra: $e')),
      );
    }
  }

  Future<void> _finishAndShowResults() async {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un patient')),
      );
      return;
    }
    if (_topImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La photo de dessus est requise')),
      );
      return;
    }

    setState(() {
      _isScanning = true;
    });

    try {
      // Attendre la fin des analyses en cours
      Map<String, dynamic> finalResult = {};
      
      // Récupérer résultat TOP
      final topFuture = _topAnalysisFuture;
      if (topFuture != null) {
         final topRes = await topFuture;
         debugPrint('🔍 Résultat TOP brut: $topRes');
         finalResult.addAll(topRes);
      } else {
        // Fallback si jamais le future n'a pas été lancé (ne devrait pas arriver)
        final topRes = await _measurementService.analyzeTopView(image: _topImage!, footSide: _sideParam);
        debugPrint('🔍 Résultat TOP brut (fallback): $topRes');
        finalResult.addAll(topRes);
      }

      // Récupérer résultat SIDE (si existe)
      if (_sideImage != null) {
        Map<String, dynamic> sideRes;
        final sideFuture = _sideAnalysisFuture;
        
        if (sideFuture != null) {
           sideRes = await sideFuture;
        } else {
           sideRes = await _measurementService.analyzeSideView(image: _sideImage!, footSide: _sideParam);
        }
        debugPrint('🔍 Résultat SIDE brut: $sideRes');

        // PROTECTION : Gérer l'image de debug du SIDE pour ne pas écraser celle du TOP
        if (sideRes.containsKey('debug_image_url')) {
          finalResult['debug_image_url_side'] = sideRes['debug_image_url'];
          // IMPORTANT : On retire la clé originale pour éviter d'écraser l'image du TOP dans finalResult
          sideRes.remove('debug_image_url');
        }

        // Ajouter le reste des données du SIDE
        finalResult.addAll(sideRes);
      }

      debugPrint('📦 Résultat final combiné: $finalResult');

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

          final scan = FootScan(
            topView: _topImage!.path,
            sideView: _sideImage?.path ?? '',
            angle: AngleType.top,
            createdAt: now,
            updatedAt: now,
          );

          final session = Session(
            id: sessionId,
            patientId: _selectedPatient!.id,
            createdAt: now,
            status: SessionStatus.termine,
            valid: true,
            footMetrics: [metrics],
            footScan: scan,
            updatedAt: now,
          );

          await _sessionService.addSession(session);
          debugPrint('✅ Session sauvegardée avec succès: $sessionId');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Résultats sauvegardés avec succès'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          debugPrint('❌ Erreur sauvegarde session: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Attention: Erreur de sauvegarde ($e)'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          // On continue quand même vers les résultats pour ne pas bloquer l'utilisateur
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: AppSpacing.lg),
                    _buildPatientSelector(context),
                    SizedBox(height: AppSpacing.lg),
                    _buildSideSelector(context),
                    SizedBox(height: AppSpacing.xl),
                    _buildScanArea(context),
                    SizedBox(height: AppSpacing.xl),
                    _buildInstructions(context),
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

  Widget _buildHeader(BuildContext context) {
    return GradientHeader(
      title: 'Nouveau Scan',
      subtitle: 'Scanner 3D LiDAR',
      showBack: true,
      onBack: () => context.pop(),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildPatientSelector(BuildContext context) {
    return Padding(
      padding: AppSpacing.horizontalLg,
      child: InkWell(
        onTap: _isScanning ? null : _selectPatient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(_selectedPatient == null ? Icons.person_add : Icons.person, color: Colors.white, size: 28),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedPatient == null ? 'Sélectionner un patient' : _selectedPatient!.fullName,
                      style: context.textStyles.titleMedium?.semiBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_selectedPatient != null) ...[
                      SizedBox(height: AppSpacing.xs),
                      Text('${_selectedPatient!.age} ans • Pointure ${_selectedPatient!.pointure}', 
                        style: context.textStyles.bodySmall?.withColor(Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
    );
  }

  Widget _buildScanArea(BuildContext context) {
    return Padding(
      padding: AppSpacing.horizontalLg,
      child: Column(
        children: [
          // Étape 1 : Vue de dessus (Obligatoire)
          _buildImageCard(
            context, 
            'Vue de dessus (Obligatoire)', 
            _topImage, 
            () => _takePhoto(true)
          ),
          
          // Indicateur de statut pour TOP
          if (_topAnalysisFuture != null && _topImage != null)
             FutureBuilder(
               future: _topAnalysisFuture,
               builder: (context, snapshot) {
                 if (snapshot.connectionState == ConnectionState.waiting) {
                   return Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                         SizedBox(width: 8),
                         Text('Analyse en cours...', style: TextStyle(color: Colors.orange, fontSize: 12)),
                       ],
                     ),
                   );
                 } else if (snapshot.hasError) {
                   return Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Text('Erreur analyse: ${snapshot.error}', style: TextStyle(color: Colors.red, fontSize: 12)),
                   );
                 }
                 return Padding(
                   padding: const EdgeInsets.only(top: 8.0),
                   child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 8),
                        Text('Analyse terminée', style: TextStyle(color: Colors.green, fontSize: 12)),
                      ]
                   ),
                 );
               }
             ),

          SizedBox(height: AppSpacing.md),
          
          // Étape 2 : Vue de profil (Apparaît seulement après Top)
          if (_topImage != null) ...[
             _buildImageCard(
               context, 
               'Vue de profil (Optionnel)', 
               _sideImage, 
               () => _takePhoto(false)
             ).animate().fadeIn().slideY(begin: 0.2),
             
              // Indicateur de statut pour SIDE
              if (_sideAnalysisFuture != null && _sideImage != null)
                FutureBuilder(
                  future: _sideAnalysisFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('Analyse profil en cours...', style: TextStyle(color: Colors.orange, fontSize: 12)),
                      );
                    }
                    return SizedBox.shrink();
                  }
                ),
          ],
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
                  Text('Appuyer pour scanner', style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant)),
                ],
              ),
      ),
    );
  }

  Widget _buildInstructions(BuildContext context) {
    final instructions = [
      {'icon': Icons.phone_iphone, 'title': 'Position', 'desc': 'Maintenez votre téléphone à 30cm du pied'},
      {'icon': Icons.lightbulb_outline, 'title': 'Éclairage', 'desc': 'Assurez-vous d\'avoir un bon éclairage'},
      {'icon': Icons.accessibility_new, 'title': 'Calibration', 'desc': 'Placez un marqueur ArUco ou une carte'},
    ];

    return Padding(
      padding: AppSpacing.horizontalLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Instructions', style: context.textStyles.titleLarge?.semiBold),
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
            Expanded(child: _buildSideOption(context, FootSide.gauche, 'Pied Gauche')),
            Expanded(child: _buildSideOption(context, FootSide.droite, 'Pied Droit')),
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

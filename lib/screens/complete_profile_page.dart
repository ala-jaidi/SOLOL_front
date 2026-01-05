import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lidarmesure/components/modern_button.dart';
import 'package:lidarmesure/supabase/supabase_config.dart';
import 'package:lidarmesure/l10n/app_localizations.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _organisationController = TextEditingController();
  final _specialiteController = TextEditingController();
  final _telephoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return;

    try {
      final data = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          // Ne pas pre-remplir le nom s'il vient de l'email (contient @)
          final nom = data['nom'] as String? ?? '';
          final email = data['email'] as String? ?? '';
          final emailPrefix = email.split('@').first;
          
          // Si le nom est identique au prefix de l'email, le laisser vide
          _nomController.text = (nom == emailPrefix) ? '' : nom;
          _prenomController.text = data['prenom'] ?? '';
          _organisationController.text = data['organisation'] ?? '';
          _specialiteController.text = data['specialite'] ?? '';
          _telephoneController.text = data['telephone'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _organisationController.dispose();
    _specialiteController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = SupabaseConfig.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecte');

      await SupabaseConfig.client.from('users').update({
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'organisation': _organisationController.text.trim(),
        'specialite': _specialiteController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.read(context).profileCompleted),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppLocalizations.of(context).completeProfile,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context).completeProfileSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Nom & Prenom
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _prenomController,
                              decoration: const InputDecoration(
                                labelText: 'Prenom',
                                hintText: 'Jean',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return AppLocalizations.of(context).required;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _nomController,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context).lastName,
                                hintText: 'Dupont',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return AppLocalizations.of(context).required;
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Organisation
                      TextFormField(
                        controller: _organisationController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).isFrench ? 'Organisation / Cabinet' : 'Organization / Clinic',
                          hintText: AppLocalizations.of(context).isFrench ? 'Cabinet de Podologie Paris' : 'Paris Podiatry Clinic',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context).required;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Specialite
                      TextFormField(
                        controller: _specialiteController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).isFrench ? 'Specialite' : 'Specialty',
                          hintText: AppLocalizations.of(context).isFrench ? 'Podologue' : 'Podiatrist',
                          prefixIcon: Icon(Icons.medical_services_outlined),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context).required;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Telephone
                      TextFormField(
                        controller: _telephoneController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).phone,
                          hintText: '06 12 34 56 78',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleSubmit(),
                      ),
                      const SizedBox(height: 32),
                      
                      ModernButton(
                        label: AppLocalizations.of(context).isFrench ? 'Terminer' : 'Finish',
                        onPressed: _isLoading ? null : _handleSubmit,
                        loading: _isLoading,
                        expand: true,
                        leadingIcon: Icons.check_circle_outline,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go('/home'),
                        child: Text(
                          AppLocalizations.of(context).isFrench ? 'Passer cette etape' : 'Skip this step',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/podiatrist_profile.dart';
import '../theme.dart';
import 'package:lidarmesure/l10n/app_localizations.dart';

class PodiatristProfilePage extends StatefulWidget {
  const PodiatristProfilePage({super.key});

  @override
  State<PodiatristProfilePage> createState() => _PodiatristProfilePageState();
}

class _PodiatristProfilePageState extends State<PodiatristProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _clinic;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    final p = context.read<PodiatristProfileState>();
    _name = TextEditingController(text: p.fullName);
    _clinic = TextEditingController(text: p.clinic);
    _email = TextEditingController(text: p.email);
    _phone = TextEditingController(text: p.phone);
    _bio = TextEditingController(text: p.bio);
  }

  @override
  void dispose() {
    _name.dispose();
    _clinic.dispose();
    _email.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profile = context.watch<PodiatristProfileState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).podiatristProfile),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14), child: const SizedBox()),
          ),
          SingleChildScrollView(
            padding: AppSpacing.paddingLg,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [cs.primary, cs.tertiary.withValues(alpha: 0.9)]),
                    ),
                    child: Icon(Icons.person_rounded, color: cs.onPrimary, size: 42),
                  ),
                  SizedBox(height: AppSpacing.lg),

                  _glassField(context, label: AppLocalizations.of(context).isFrench ? 'Nom complet' : 'Full name', controller: _name, icon: Icons.badge_rounded, validator: _required),
                  SizedBox(height: AppSpacing.md),
                  _glassField(context, label: AppLocalizations.of(context).isFrench ? 'Cabinet / Clinique' : 'Clinic', controller: _clinic, icon: Icons.local_hospital_outlined),
                  SizedBox(height: AppSpacing.md),
                  _glassField(context, label: AppLocalizations.of(context).email, controller: _email, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  SizedBox(height: AppSpacing.md),
                  _glassField(context, label: AppLocalizations.of(context).phone, controller: _phone, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                  SizedBox(height: AppSpacing.md),
                  _glassField(context, label: 'Bio', controller: _bio, icon: Icons.info_outline, maxLines: 4),

                  SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _name.text = '';
                            _clinic.text = '';
                            _email.text = '';
                            _phone.text = '';
                            _bio.text = '';
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(AppLocalizations.of(context).isFrench ? 'Reinitialiser' : 'Reset'),
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;
                            await context.read<PodiatristProfileState>().update(
                                  fullName: _name.text.trim(),
                                  clinic: _clinic.text.trim(),
                                  email: _email.text.trim(),
                                  phone: _phone.text.trim(),
                                  bio: _bio.text.trim(),
                                );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context).isFrench ? 'Profil enregistre' : 'Profile saved'), backgroundColor: cs.primary),
                              );
                            }
                          },
                          icon: const Icon(Icons.save_rounded),
                          label: Text(AppLocalizations.of(context).isFrench ? 'Enregistrer' : 'Save'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xl),

                  if (profile.fullName.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(AppLocalizations.of(context).isFrench ? 'Apercu' : 'Preview', style: context.textStyles.titleMedium?.semiBold),
                    ),
                    SizedBox(height: AppSpacing.md),
                    _previewCard(context, profile),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  Widget _glassField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: maxLines == 1 ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              minLines: 1,
              maxLines: maxLines,
              validator: validator,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewCard(BuildContext context, PodiatristProfileState p) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.fullName, style: context.textStyles.titleLarge?.semiBold),
          if (p.clinic.isNotEmpty) Text(p.clinic, style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant)),
          SizedBox(height: AppSpacing.sm),
          if (p.email.isNotEmpty) _kv(context, Icons.email_outlined, p.email),
          if (p.phone.isNotEmpty) _kv(context, Icons.phone_outlined, p.phone),
          if (p.bio.isNotEmpty) Padding(padding: EdgeInsets.only(top: AppSpacing.sm), child: Text(p.bio)),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ]),
    );
  }
}

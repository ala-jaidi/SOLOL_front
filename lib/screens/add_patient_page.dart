import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lidarmesure/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lidarmesure/models/user.dart';
import 'package:lidarmesure/components/section_card.dart';
import 'package:lidarmesure/components/gradient_header.dart';
import 'package:lidarmesure/services/patient_service.dart';

class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = PatientService();

  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _pointureCtrl = TextEditingController();
  final _tailleCtrl = TextEditingController();
  final _poidsCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  DateTime? _dateNaissance;
  String _sexe = 'Homme';
  bool _submitting = false;

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _telephoneCtrl.dispose();
    _adresseCtrl.dispose();
    _pointureCtrl.dispose();
    _tailleCtrl.dispose();
    _poidsCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
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
                padding: AppSpacing.paddingLg,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionCard(
                        title: 'Informations personnelles',
                        icon: Icons.person_outline,
                        children: [
                          _twoCols(
                            context,
                            _input(context, controller: _prenomCtrl, label: 'Prénom', icon: Icons.badge_outlined, validator: (v) => v == null || v.trim().isEmpty ? 'Prénom requis' : null),
                            _input(context, controller: _nomCtrl, label: 'Nom', icon: Icons.badge_outlined, validator: (v) => v == null || v.trim().isEmpty ? 'Nom requis' : null),
                          ),
                          _input(context, controller: _telephoneCtrl, label: 'Téléphone', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, validator: (v) => v == null || v.trim().isEmpty ? 'Téléphone requis' : null),
                          // _twoCols(
                          //   context,
                          //   _input(context, controller: _emailCtrl, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (v) => v != null && v.contains('@') ? null : 'Email invalide'),
                          //   _input(context, controller: _telephoneCtrl, label: 'Téléphone', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, validator: (v) => v == null || v.trim().isEmpty ? 'Téléphone requis' : null),
                          // ),
                          _twoCols(context, _datePickerField(context), _dropdownField(context)),
                          _input(context, controller: _adresseCtrl, label: 'Adresse', icon: Icons.location_on_outlined, maxLines: 2, validator: (v) => v == null || v.trim().isEmpty ? 'Adresse requise' : null),
                        ],
                      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.08),
                      SectionCard(
                        title: 'Mesures',
                        icon: Icons.straighten,
                        children: [
                          _twoCols(
                            context,
                            _input(context, controller: _pointureCtrl, label: 'Pointure', icon: Icons.straighten, keyboardType: TextInputType.number, validator: _reqNum),
                            _input(context, controller: _ageCtrl, label: 'Âge', icon: Icons.cake_outlined, keyboardType: TextInputType.number, validator: _reqNum),
                          ),
                          _twoCols(
                            context,
                            _input(context, controller: _tailleCtrl, label: 'Taille (cm)', icon: Icons.height, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _reqNum),
                            _input(context, controller: _poidsCtrl, label: 'Poids (kg)', icon: Icons.monitor_weight_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _reqNum),
                          ),
                        ],
                      ).animate().fadeIn(duration: 250.ms, delay: 100.ms).slideY(begin: 0.08),
                      SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _submitting ? null : _submit,
                              icon: _submitting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.check_circle_outline),
                              label: const Text('Enregistrer le patient'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.lg),
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

  Widget _buildHeader(BuildContext context) {
    return GradientHeader(
      title: 'Nouveau Patient',
      subtitle: 'Créer un dossier patient',
      showBack: true,
      onBack: () => context.pop(),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: context.textStyles.titleLarge?.semiBold),
      );

  String? _reqNum(String? v) {
    if (v == null || v.trim().isEmpty) return 'Champ requis';
    final num? parsed = num.tryParse(v.replaceAll(',', '.'));
    return parsed == null ? 'Valeur invalide' : null;
  }

  Widget _input(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }

  Widget _dropdownField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Sexe',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          filled: true,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _sexe,
            items: const [
              DropdownMenuItem(value: 'Homme', child: Text('Homme')),
              DropdownMenuItem(value: 'Femme', child: Text('Femme')),
              DropdownMenuItem(value: 'Autre', child: Text('Autre')),
            ],
            onChanged: (v) => setState(() => _sexe = v ?? 'Homme'),
          ),
        ),
      ),
    );
  }

  Widget _datePickerField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date de naissance',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            filled: true,
            prefixIcon: Icon(Icons.event, color: Theme.of(context).colorScheme.primary),
          ),
          child: Text(
            _dateNaissance == null
                ? 'Choisir une date'
                : '${_dateNaissance!.day.toString().padLeft(2, '0')}/${_dateNaissance!.month.toString().padLeft(2, '0')}/${_dateNaissance!.year}',
            style: context.textStyles.bodyMedium,
          ),
        ),
      ),
    );
  }

  Widget _twoCols(BuildContext context, Widget left, Widget right) {
    return Row(
      children: [
        Expanded(child: left),
        SizedBox(width: AppSpacing.md),
        Expanded(child: right),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 30, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: now,
      initialDate: _dateNaissance ?? initial,
    );
    if (picked != null) setState(() => _dateNaissance = picked);
  }

  Future<void> _submit() async {
    if (_dateNaissance == null) {
      _showSnack('Veuillez sélectionner la date de naissance', isError: true);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final createdAt = DateTime.now();
      final int sexeInt = _sexe == 'Homme' ? 0 : (_sexe == 'Femme' ? 1 : 2);
      final patient = Patient(
        id: '',
        nom: _nomCtrl.text.trim(),
        // email: _emailCtrl.text.trim(),
        organisation: 'Cabinet', // Default value
        specialite: 'Patient',   // Default value
        prenom: _prenomCtrl.text.trim(),
        pointure: _pointureCtrl.text.trim(),
        sexe: sexeInt,
        dateNaissance: _dateNaissance!,
        taille: double.parse(_tailleCtrl.text.replaceAll(',', '.')),
        poids: double.parse(_poidsCtrl.text.replaceAll(',', '.')),
        telephone: _telephoneCtrl.text.trim(),
        age: int.parse(_ageCtrl.text.trim()),
        adresse: _adresseCtrl.text.trim(),
        createdAt: createdAt,
        updatedAt: createdAt,
      );

      final created = await _service.addPatient(patient);
      if (!mounted) return;
      _showSnack('Patient créé avec succès');
      context.go('/patient/${created.id}');
    } catch (e) {
      debugPrint('Add patient error: $e');
      if (!mounted) return;
      _showSnack('Échec de création: $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

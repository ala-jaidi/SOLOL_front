import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lidarmesure/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lidarmesure/models/user.dart';
import 'package:lidarmesure/services/patient_service.dart';
import 'package:lidarmesure/l10n/app_localizations.dart';

class EditPatientPage extends StatefulWidget {
  final String patientId;
  const EditPatientPage({super.key, required this.patientId});

  @override
  State<EditPatientPage> createState() => _EditPatientPageState();
}

class _EditPatientPageState extends State<EditPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = PatientService();

  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _pointureCtrl = TextEditingController();
  final _tailleCtrl = TextEditingController();
  final _poidsCtrl = TextEditingController();
  DateTime? _dateNaissance;
  int? _calculatedAge;
  String _sexe = 'Homme';
  bool _submitting = false;
  bool _loading = true;
  Patient? _patient;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    final patient = await _service.getPatientById(widget.patientId);
    if (patient != null && mounted) {
      setState(() {
        _patient = patient;
        _prenomCtrl.text = patient.prenom;
        _nomCtrl.text = patient.nom;
        _telephoneCtrl.text = patient.telephone;
        _adresseCtrl.text = patient.adresse;
        _pointureCtrl.text = patient.pointure;
        _tailleCtrl.text = patient.taille.toString();
        _poidsCtrl.text = patient.poids.toString();
        _dateNaissance = patient.dateNaissance;
        _calculatedAge = patient.age;
        _sexe = patient.sexe == 0 ? 'Homme' : (patient.sexe == 1 ? 'Femme' : 'Autre');
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _telephoneCtrl.dispose();
    _adresseCtrl.dispose();
    _pointureCtrl.dispose();
    _tailleCtrl.dispose();
    _poidsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    
    if (_loading) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_patient == null) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: cs.error),
              const SizedBox(height: 16),
              Text(l10n.noPatientFound),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _goBack(context),
                child: Text(l10n.back),
              ),
            ],
          ),
        ),
      );
    }
    
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
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _goBack(context),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.isFrench ? 'Modifier Patient' : 'Edit Patient',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            _patient!.fullName,
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionCard(
                          context,
                          title: l10n.isFrench ? 'Informations personnelles' : 'Personal Information',
                          icon: Icons.person_outline,
                          children: [
                            _twoCols(
                              context,
                              _input(context, controller: _prenomCtrl, label: l10n.isFrench ? 'Prénom' : 'First Name', icon: Icons.badge_outlined, validator: (v) => v == null || v.trim().isEmpty ? (l10n.isFrench ? 'Prénom requis' : 'First name required') : null),
                              _input(context, controller: _nomCtrl, label: l10n.isFrench ? 'Nom' : 'Last Name', icon: Icons.badge_outlined, validator: (v) => v == null || v.trim().isEmpty ? (l10n.isFrench ? 'Nom requis' : 'Last name required') : null),
                            ),
                            _input(context, controller: _telephoneCtrl, label: l10n.phone, icon: Icons.phone_outlined, keyboardType: TextInputType.phone, validator: (v) => v == null || v.trim().isEmpty ? (l10n.isFrench ? 'Téléphone requis' : 'Phone required') : null),
                            _twoCols(context, _datePickerField(context), _dropdownField(context)),
                            _input(context, controller: _adresseCtrl, label: l10n.address, icon: Icons.location_on_outlined, maxLines: 2, validator: (v) => v == null || v.trim().isEmpty ? (l10n.isFrench ? 'Adresse requise' : 'Address required') : null),
                          ],
                        ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.08),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          context,
                          title: l10n.isFrench ? 'Mesures' : 'Measurements',
                          icon: Icons.straighten,
                          children: [
                            _twoCols(
                              context,
                              _input(context, controller: _pointureCtrl, label: l10n.shoeSize, icon: Icons.straighten, keyboardType: TextInputType.number, validator: _reqNum),
                              _ageDisplayField(context),
                            ),
                            _twoCols(
                              context,
                              _input(context, controller: _tailleCtrl, label: l10n.isFrench ? 'Taille (cm)' : 'Height (cm)', icon: Icons.height, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _reqNum),
                              _input(context, controller: _poidsCtrl, label: l10n.weight, icon: Icons.monitor_weight_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _reqNum),
                            ),
                          ],
                        ).animate().fadeIn(duration: 250.ms, delay: 100.ms).slideY(begin: 0.08),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _submitting ? null : _submit,
                                icon: _submitting
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.check_circle_outline),
                                label: Text(l10n.isFrench ? 'Enregistrer les modifications' : 'Save Changes'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
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

  Widget _buildSectionCard(BuildContext context, {required String title, required IconData icon, required List<Widget> children}) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: cs.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _ageDisplayField(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.isFrench ? 'Age (auto)' : 'Age (auto)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          filled: true,
          prefixIcon: Icon(Icons.cake_outlined, color: cs.primary),
        ),
        child: Text(
          _calculatedAge != null ? '$_calculatedAge ${l10n.isFrench ? "ans" : "yrs"}' : (l10n.isFrench ? 'Sélectionnez la date' : 'Select date'),
          style: TextStyle(
            color: _calculatedAge != null ? cs.onSurface : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  String? _reqNum(String? v) {
    if (v == null || v.trim().isEmpty) return AppLocalizations.of(context).isFrench ? 'Champ requis' : 'Required';
    final num? parsed = num.tryParse(v.replaceAll(',', '.'));
    return parsed == null ? (AppLocalizations.of(context).isFrench ? 'Valeur invalide' : 'Invalid value') : null;
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
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.isFrench ? 'Sexe' : 'Gender',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          filled: true,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _sexe,
            items: [
              DropdownMenuItem(value: 'Homme', child: Text(l10n.isFrench ? 'Homme' : 'Male')),
              DropdownMenuItem(value: 'Femme', child: Text(l10n.isFrench ? 'Femme' : 'Female')),
              DropdownMenuItem(value: 'Autre', child: Text(l10n.isFrench ? 'Autre' : 'Other')),
            ],
            onChanged: (v) => setState(() => _sexe = v ?? 'Homme'),
          ),
        ),
      ),
    );
  }

  Widget _datePickerField(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.isFrench ? 'Date de naissance' : 'Date of Birth',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            filled: true,
            prefixIcon: Icon(Icons.event, color: cs.primary),
          ),
          child: Text(
            _dateNaissance == null
                ? (l10n.isFrench ? 'Choisir une date' : 'Choose date')
                : '${_dateNaissance!.day.toString().padLeft(2, '0')}/${_dateNaissance!.month.toString().padLeft(2, '0')}/${_dateNaissance!.year}',
            style: TextStyle(color: cs.onSurface),
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
    final initial = _dateNaissance ?? DateTime(now.year - 30, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: now,
      initialDate: initial,
    );
    if (picked != null) {
      setState(() {
        _dateNaissance = picked;
        _calculatedAge = _calculateAge(picked);
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_dateNaissance == null) {
      _showSnack(l10n.isFrench ? 'Veuillez sélectionner la date de naissance' : 'Please select date of birth', isError: true);
      return;
    }
    if (_calculatedAge == null) {
      _showSnack(l10n.isFrench ? 'Age non calculé' : 'Age not calculated', isError: true);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final int sexeInt = _sexe == 'Homme' ? 0 : (_sexe == 'Femme' ? 1 : 2);
      final updatedPatient = Patient(
        id: _patient!.id,
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        pointure: _pointureCtrl.text.trim(),
        sexe: sexeInt,
        dateNaissance: _dateNaissance!,
        taille: double.parse(_tailleCtrl.text.replaceAll(',', '.')),
        poids: double.parse(_poidsCtrl.text.replaceAll(',', '.')),
        telephone: _telephoneCtrl.text.trim(),
        age: _calculatedAge!,
        adresse: _adresseCtrl.text.trim(),
        createdAt: _patient!.createdAt,
        updatedAt: DateTime.now(),
        avatarUrl: _patient!.avatarUrl,
      );

      await _service.updatePatient(updatedPatient);
      if (!mounted) return;
      _showSnack(l10n.isFrench ? 'Patient mis à jour avec succès' : 'Patient updated successfully');
      context.go('/patient/${_patient!.id}');
    } catch (e) {
      debugPrint('Update patient error: $e');
      if (!mounted) return;
      _showSnack(l10n.isFrench ? 'Échec de la mise à jour: $e' : 'Update failed: $e', isError: true);
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lidarmesure/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lidarmesure/models/user.dart';
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
  DateTime? _dateNaissance;
  int? _calculatedAge;
  String _sexe = 'Homme';
  bool _submitting = false;

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
                            'Nouveau Patient',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            'Creer un dossier patient',
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
                          title: 'Informations personnelles',
                          icon: Icons.person_outline,
                          children: [
                            _twoCols(
                              context,
                              _input(context, controller: _prenomCtrl, label: 'Prenom', icon: Icons.badge_outlined, validator: (v) => v == null || v.trim().isEmpty ? 'Prenom requis' : null),
                              _input(context, controller: _nomCtrl, label: 'Nom', icon: Icons.badge_outlined, validator: (v) => v == null || v.trim().isEmpty ? 'Nom requis' : null),
                            ),
                            _input(context, controller: _telephoneCtrl, label: 'Telephone', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, validator: (v) => v == null || v.trim().isEmpty ? 'Telephone requis' : null),
                            _twoCols(context, _datePickerField(context), _dropdownField(context)),
                            _input(context, controller: _adresseCtrl, label: 'Adresse', icon: Icons.location_on_outlined, maxLines: 2, validator: (v) => v == null || v.trim().isEmpty ? 'Adresse requise' : null),
                          ],
                        ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.08),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          context,
                          title: 'Mesures',
                          icon: Icons.straighten,
                          children: [
                            _twoCols(
                              context,
                              _input(context, controller: _pointureCtrl, label: 'Pointure', icon: Icons.straighten, keyboardType: TextInputType.number, validator: _reqNum),
                              _ageDisplayField(context),
                            ),
                            _twoCols(
                              context,
                              _input(context, controller: _tailleCtrl, label: 'Taille (cm)', icon: Icons.height, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _reqNum),
                              _input(context, controller: _poidsCtrl, label: 'Poids (kg)', icon: Icons.monitor_weight_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _reqNum),
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
                                label: const Text('Enregistrer le patient'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Age (auto)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          filled: true,
          prefixIcon: Icon(Icons.cake_outlined, color: cs.primary),
        ),
        child: Text(
          _calculatedAge != null ? '$_calculatedAge ans' : 'Selectionnez la date',
          style: TextStyle(
            color: _calculatedAge != null ? cs.onSurface : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

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
    final cs = Theme.of(context).colorScheme;
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
            prefixIcon: Icon(Icons.event, color: cs.primary),
          ),
          child: Text(
            _dateNaissance == null
                ? 'Choisir une date'
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
    final initial = DateTime(now.year - 30, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: now,
      initialDate: _dateNaissance ?? initial,
    );
    if (picked != null) {
      setState(() {
        _dateNaissance = picked;
        _calculatedAge = _calculateAge(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (_dateNaissance == null) {
      _showSnack('Veuillez selectionner la date de naissance', isError: true);
      return;
    }
    if (_calculatedAge == null) {
      _showSnack('Age non calcule', isError: true);
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
        prenom: _prenomCtrl.text.trim(),
        pointure: _pointureCtrl.text.trim(),
        sexe: sexeInt,
        dateNaissance: _dateNaissance!,
        taille: double.parse(_tailleCtrl.text.replaceAll(',', '.')),
        poids: double.parse(_poidsCtrl.text.replaceAll(',', '.')),
        telephone: _telephoneCtrl.text.trim(),
        age: _calculatedAge!,
        adresse: _adresseCtrl.text.trim(),
        createdAt: createdAt,
        updatedAt: createdAt,
      );

      final created = await _service.addPatient(patient);
      if (!mounted) return;
      _showSnack('Patient cree avec succes');
      // Retourner à la liste des patients avec refresh
      context.go('/patients');
    } catch (e) {
      debugPrint('Add patient error: $e');
      if (!mounted) return;
      _showSnack('Echec de creation: $e', isError: true);
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

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lidarmesure/components/section_card.dart';
import 'package:lidarmesure/components/gradient_header.dart';
import 'package:lidarmesure/models/session.dart';
import 'package:lidarmesure/models/user.dart';
import 'package:lidarmesure/services/patient_service.dart';
import 'package:lidarmesure/services/session_service.dart';
import 'package:lidarmesure/theme.dart';
import 'package:lidarmesure/l10n/app_localizations.dart';

class AddSessionPage extends StatefulWidget {
  final String? preselectedPatientId;
  const AddSessionPage({super.key, this.preselectedPatientId});

  @override
  State<AddSessionPage> createState() => _AddSessionPageState();
}

class _AddSessionPageState extends State<AddSessionPage> {
  final _formKey = GlobalKey<FormState>();
  final _patientService = PatientService();
  final _sessionService = SessionService();

  List<Patient> _patients = [];
  Patient? _selectedPatient;
  SessionStatus _status = SessionStatus.pending;
  bool _valid = true;
  DateTime _date = DateTime.now();
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final patients = await _patientService.getAllPatients();
      Patient? selected;
      if (widget.preselectedPatientId != null) {
        try {
          selected = patients.firstWhere((p) => p.id == widget.preselectedPatientId);
        } catch (_) {
          selected = null;
        }
      }
      setState(() {
        _patients = patients;
        _selectedPatient = selected;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Load patients error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                        title: AppLocalizations.of(context).sessionInfo,
                        icon: Icons.analytics_outlined,
                        children: [
                          _patientSelector(context),
                          const SizedBox(height: 12),
                          _statusSelector(context),
                          const SizedBox(height: 12),
                          _datePicker(context),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Switch(
                                value: _valid,
                                onChanged: (v) => setState(() => _valid = v),
                              ),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context).isFrench ? 'Valider la session' : 'Validate session', style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ],
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _submitting ? null : _submit,
                              icon: _submitting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(AppLocalizations.of(context).isFrench ? 'Creer la session' : 'Create session'),
                            ),
                          ),
                        ],
                      ),
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
    final l10n = AppLocalizations.of(context);
    return GradientHeader(
      title: l10n.isFrench ? 'Nouvelle Session' : 'New Session',
      subtitle: l10n.sessionInfo,
      showBack: true,
      onBack: () => context.pop(),
    );
  }

  Widget _patientSelector(BuildContext context) {
    if (_selectedPatient != null) {
      return InputDecorator(
        decoration: InputDecoration(labelText: AppLocalizations.of(context).isFrench ? 'Patient' : 'Patient'),
        child: Row(
          children: [
            Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(_selectedPatient!.fullName, style: Theme.of(context).textTheme.bodyLarge?.medium)),
            TextButton(
              onPressed: () => setState(() => _selectedPatient = null),
              child: Text(AppLocalizations.of(context).isFrench ? 'Changer' : 'Change'),
            ),
          ],
        ),
      );
    }
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: AppLocalizations.of(context).isFrench ? 'Patient' : 'Patient', prefixIcon: Icon(Icons.person_outline)),
      items: _patients
          .map((p) => DropdownMenuItem<String>(
                value: p.id,
                child: Text(p.fullName),
              ))
          .toList(),
      validator: (v) => v == null || v.isEmpty ? (AppLocalizations.of(context).isFrench ? 'Selectionnez un patient' : 'Select a patient') : null,
      onChanged: (id) => setState(() => _selectedPatient = _patients.firstWhere((p) => p.id == id)),
    );
  }

  Widget _statusSelector(BuildContext context) {
    return DropdownButtonFormField<SessionStatus>(
      decoration: InputDecoration(labelText: AppLocalizations.of(context).isFrench ? 'Statut' : 'Status', prefixIcon: Icon(Icons.flag_outlined)),
      value: _status,
      items: SessionStatus.values
          .map((s) => DropdownMenuItem<SessionStatus>(
                value: s,
                child: Text(_statusLabel(s)),
              ))
          .toList(),
      onChanged: (v) => setState(() => _status = v ?? SessionStatus.pending),
    );
  }

  Widget _datePicker(BuildContext context) {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context).isFrench ? 'Date de session' : 'Session date',
          prefixIcon: Icon(Icons.event),
        ),
        child: Text('${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}'),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).isFrench ? 'Selectionnez un patient' : 'Select a patient'), backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final now = DateTime.now();
      final session = Session(
        id: '',
        patientId: _selectedPatient!.id,
        createdAt: DateTime(_date.year, _date.month, _date.day, now.hour, now.minute),
        status: _status,
        valid: _valid,
        footMetrics: const [],
        questionnaires: const [],
        footScan: null,
        updatedAt: now,
      );

      final createdId = await _sessionService.addSession(session);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).isFrench ? 'Session creee' : 'Session created'), backgroundColor: Theme.of(context).colorScheme.primary),
      );
      context.go('/session/$createdId');
    } catch (e) {
      debugPrint('Add session error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).isFrench ? 'Echec: $e' : 'Failed: $e'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _statusLabel(SessionStatus s) {
    switch (s) {
      case SessionStatus.pending:
        return AppLocalizations.of(context).statusPending;
      case SessionStatus.completed:
        return AppLocalizations.of(context).statusCompleted;
      case SessionStatus.cancelled:
        return AppLocalizations.of(context).statusCancelled;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lidarmesure/models/medical_questionnaire.dart';
import 'package:lidarmesure/theme.dart';
import 'package:lidarmesure/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

/// Widget pour afficher et gérer le questionnaire médical
class MedicalQuestionnaireForm extends StatefulWidget {
  final List<MedicalQuestionnaire> questionnaires;
  final ValueChanged<List<MedicalQuestionnaire>> onChanged;
  final bool readOnly;

  const MedicalQuestionnaireForm({
    super.key,
    required this.questionnaires,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  State<MedicalQuestionnaireForm> createState() => _MedicalQuestionnaireFormState();
}

class _MedicalQuestionnaireFormState extends State<MedicalQuestionnaireForm> {
  late List<MedicalQuestionnaire> _questionnaires;

  @override
  void initState() {
    super.initState();
    _questionnaires = List.from(widget.questionnaires);
  }

  @override
  void didUpdateWidget(MedicalQuestionnaireForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questionnaires != widget.questionnaires) {
      _questionnaires = List.from(widget.questionnaires);
    }
  }

  void _addQuestion() {
    final now = DateTime.now();
    final newQ = MedicalQuestionnaire(
      id: const Uuid().v4(),
      cleDeLaQuestion: '',
      condition: null,
      reponse: '',
      createdAt: now,
      updatedAt: now,
    );
    setState(() {
      _questionnaires.add(newQ);
    });
    widget.onChanged(_questionnaires);
  }

  void _updateQuestion(int index, MedicalQuestionnaire updated) {
    setState(() {
      _questionnaires[index] = updated;
    });
    widget.onChanged(_questionnaires);
  }

  void _removeQuestion(int index) {
    setState(() {
      _questionnaires.removeAt(index);
    });
    widget.onChanged(_questionnaires);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.medical_information_outlined, size: 16, color: cs.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.isFrench ? 'Questionnaire Médical' : 'Medical Questionnaire',
                style: Theme.of(context).textTheme.titleLarge?.semiBold,
              ),
            ),
            if (!widget.readOnly)
              TextButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: Text(l10n.isFrench ? 'Ajouter' : 'Add'),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Description
        if (!widget.readOnly && _questionnaires.isEmpty)
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: cs.onSurfaceVariant, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.isFrench
                        ? 'Ajoutez des questions pour évaluer les conditions podologiques du patient.'
                        : 'Add questions to evaluate the patient\'s podiatric conditions.',
                    style: Theme.of(context).textTheme.bodyMedium?.withColor(cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),

        // Questions list
        ..._questionnaires.asMap().entries.map((entry) {
          final index = entry.key;
          final q = entry.value;
          return _QuestionCard(
            key: ValueKey(q.id),
            questionnaire: q,
            index: index,
            readOnly: widget.readOnly,
            onUpdate: (updated) => _updateQuestion(index, updated),
            onRemove: () => _removeQuestion(index),
          ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.05);
        }),

        // Empty state for read-only
        if (widget.readOnly && _questionnaires.isEmpty)
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(Icons.assignment_outlined, color: cs.onSurfaceVariant),
                const SizedBox(width: 12),
                Text(
                  l10n.isFrench ? 'Aucun questionnaire rempli' : 'No questionnaire filled',
                  style: Theme.of(context).textTheme.bodyMedium?.withColor(cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final MedicalQuestionnaire questionnaire;
  final int index;
  final bool readOnly;
  final ValueChanged<MedicalQuestionnaire> onUpdate;
  final VoidCallback onRemove;

  const _QuestionCard({
    super.key,
    required this.questionnaire,
    required this.index,
    required this.readOnly,
    required this.onUpdate,
    required this.onRemove,
  });

  String _getConditionLabel(FootCondition condition, bool isFrench) {
    switch (condition) {
      case FootCondition.halluxvalgus:
        return isFrench ? 'Hallux Valgus' : 'Hallux Valgus';
      case FootCondition.pronation:
        return isFrench ? 'Pronation' : 'Pronation';
      case FootCondition.supination:
        return isFrench ? 'Supination' : 'Supination';
      case FootCondition.plantarfasciitis:
        return isFrench ? 'Fasciite Plantaire' : 'Plantar Fasciitis';
    }
  }

  IconData _getConditionIcon(FootCondition? condition) {
    if (condition == null) return Icons.help_outline;
    switch (condition) {
      case FootCondition.halluxvalgus:
        return Icons.accessibility_new;
      case FootCondition.pronation:
        return Icons.turn_left;
      case FootCondition.supination:
        return Icons.turn_right;
      case FootCondition.plantarfasciitis:
        return Icons.healing;
    }
  }

  Color _getConditionColor(FootCondition? condition, ColorScheme cs, Brightness brightness) {
    if (condition == null) return cs.onSurfaceVariant;
    switch (condition) {
      case FootCondition.halluxvalgus:
        return cs.error;
      case FootCondition.pronation:
        return cs.tertiary;
      case FootCondition.supination:
        return cs.secondary;
      case FootCondition.plantarfasciitis:
        // Orange adaptatif pour light/dark mode
        return brightness == Brightness.dark 
            ? const Color(0xFFFFB800) // Plus lumineux en dark
            : const Color(0xFFE68600); // Plus foncé en light
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final l10n = AppLocalizations.of(context);
    final conditionColor = _getConditionColor(questionnaire.condition, cs, brightness);

    if (readOnly) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Condition badge
            if (questionnaire.condition != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: conditionColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getConditionIcon(questionnaire.condition), size: 14, color: conditionColor),
                    const SizedBox(width: 6),
                    Text(
                      _getConditionLabel(questionnaire.condition!, l10n.isFrench),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: conditionColor,
                      ),
                    ),
                  ],
                ),
              ),
            if (questionnaire.condition != null) const SizedBox(height: 12),
            
            // Question
            Text(
              questionnaire.cleDeLaQuestion.isNotEmpty 
                  ? questionnaire.cleDeLaQuestion 
                  : (l10n.isFrench ? 'Question non définie' : 'Question not defined'),
              style: Theme.of(context).textTheme.bodyMedium?.semiBold,
            ),
            const SizedBox(height: 8),
            
            // Response
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                questionnaire.reponse.isNotEmpty 
                    ? questionnaire.reponse 
                    : (l10n.isFrench ? 'Aucune réponse' : 'No response'),
                style: Theme.of(context).textTheme.bodyMedium?.withColor(
                  questionnaire.reponse.isNotEmpty ? cs.onSurface : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Editable mode
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with number and delete
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.isFrench ? 'Question ${index + 1}' : 'Question ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall?.semiBold,
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(Icons.delete_outline, color: cs.error, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: cs.error.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Condition selector
          DropdownButtonFormField<FootCondition?>(
            decoration: InputDecoration(
              labelText: l10n.isFrench ? 'Condition podologique' : 'Foot Condition',
              prefixIcon: Icon(_getConditionIcon(questionnaire.condition), color: conditionColor),
            ),
            value: questionnaire.condition,
            items: [
              DropdownMenuItem<FootCondition?>(
                value: null,
                child: Text(l10n.isFrench ? 'Sélectionner une condition' : 'Select a condition'),
              ),
              ...FootCondition.values.map((c) => DropdownMenuItem<FootCondition?>(
                value: c,
                child: Row(
                  children: [
                    Icon(_getConditionIcon(c), size: 18, color: _getConditionColor(c, cs, brightness)),
                    const SizedBox(width: 8),
                    Text(_getConditionLabel(c, l10n.isFrench)),
                  ],
                ),
              )),
            ],
            onChanged: (v) => onUpdate(questionnaire.copyWith(condition: v)),
          ),
          const SizedBox(height: 16),

          // Question input
          TextFormField(
            initialValue: questionnaire.cleDeLaQuestion,
            decoration: InputDecoration(
              labelText: l10n.isFrench ? 'Question' : 'Question',
              hintText: l10n.isFrench 
                  ? 'Ex: Ressentez-vous des douleurs au talon ?' 
                  : 'Ex: Do you feel pain in the heel?',
              prefixIcon: const Icon(Icons.help_outline),
            ),
            maxLines: 2,
            onChanged: (v) => onUpdate(questionnaire.copyWith(
              cleDeLaQuestion: v,
              updatedAt: DateTime.now(),
            )),
          ),
          const SizedBox(height: 16),

          // Response input
          TextFormField(
            initialValue: questionnaire.reponse,
            decoration: InputDecoration(
              labelText: l10n.isFrench ? 'Réponse du patient' : 'Patient Response',
              hintText: l10n.isFrench 
                  ? 'Notez la réponse du patient...' 
                  : 'Note the patient\'s response...',
              prefixIcon: const Icon(Icons.chat_bubble_outline),
            ),
            maxLines: 3,
            onChanged: (v) => onUpdate(questionnaire.copyWith(
              reponse: v,
              updatedAt: DateTime.now(),
            )),
          ),
        ],
      ),
    );
  }
}

/// Widget compact pour afficher un résumé des conditions détectées
class MedicalConditionsSummary extends StatelessWidget {
  final List<MedicalQuestionnaire> questionnaires;

  const MedicalConditionsSummary({super.key, required this.questionnaires});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    // Grouper par condition
    final conditionCounts = <FootCondition, int>{};
    for (final q in questionnaires) {
      if (q.condition != null) {
        conditionCounts[q.condition!] = (conditionCounts[q.condition!] ?? 0) + 1;
      }
    }

    if (conditionCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services_outlined, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                l10n.isFrench ? 'Conditions détectées' : 'Detected Conditions',
                style: Theme.of(context).textTheme.labelMedium?.semiBold,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: conditionCounts.entries.map((entry) {
              return _ConditionChip(condition: entry.key, count: entry.value);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  final FootCondition condition;
  final int count;

  const _ConditionChip({required this.condition, required this.count});

  Color _getColor(ColorScheme cs, Brightness brightness) {
    switch (condition) {
      case FootCondition.halluxvalgus:
        return cs.error;
      case FootCondition.pronation:
        return cs.tertiary;
      case FootCondition.supination:
        return cs.secondary;
      case FootCondition.plantarfasciitis:
        return brightness == Brightness.dark 
            ? const Color(0xFFFFB800) 
            : const Color(0xFFE68600);
    }
  }

  String _getLabel(bool isFrench) {
    switch (condition) {
      case FootCondition.halluxvalgus:
        return 'Hallux Valgus';
      case FootCondition.pronation:
        return 'Pronation';
      case FootCondition.supination:
        return 'Supination';
      case FootCondition.plantarfasciitis:
        return isFrench ? 'Fasciite' : 'Fasciitis';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final l10n = AppLocalizations.of(context);
    final color = _getColor(cs, brightness);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getLabel(l10n.isFrench),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (count > 1) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum FootCondition {
  halluxvalgus,
  pronation,
  supination,
  plantarfasciitis
}

class MedicalQuestionnaire {
  final String id;
  final String cleDeLaQuestion;
  final FootCondition? condition;
  final String reponse;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicalQuestionnaire({
    required this.id,
    required this.cleDeLaQuestion,
    this.condition,
    required this.reponse,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'cleDeLaQuestion': cleDeLaQuestion,
    'condition': condition?.name,
    'reponse': reponse,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory MedicalQuestionnaire.fromJson(Map<String, dynamic> json) => MedicalQuestionnaire(
    id: json['id'] as String,
    cleDeLaQuestion: (json['cleDeLaQuestion'] ?? json['question']) as String,
    condition: json['condition'] != null 
        ? FootCondition.values.firstWhere((e) => e.name == json['condition'])
        : null,
    reponse: json['reponse'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  MedicalQuestionnaire copyWith({
    String? id,
    String? cleDeLaQuestion,
    FootCondition? condition,
    String? reponse,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MedicalQuestionnaire(
    id: id ?? this.id,
    cleDeLaQuestion: cleDeLaQuestion ?? this.cleDeLaQuestion,
    condition: condition ?? this.condition,
    reponse: reponse ?? this.reponse,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  String get conditionLabel {
    if (condition == null) return 'N/A';
    switch (condition!) {
      case FootCondition.halluxvalgus:
        return 'Hallux Valgus';
      case FootCondition.pronation:
        return 'Pronation';
      case FootCondition.supination:
        return 'Supination';
      case FootCondition.plantarfasciitis:
        return 'Fasciite Plantaire';
    }
  }
}

enum FootSide { droite, gauche }

class FootMetrics {
  final String id;
  final FootSide side;
  final double longueur;
  final double largeur;
  final double confidence;
  final DateTime createdAt;
  final DateTime updatedAt;

  FootMetrics({
    required this.id,
    required this.side,
    required this.longueur,
    required this.largeur,
    required this.confidence,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'side': side.name,
    'longueur': longueur,
    'largeur': largeur,
    'confidence': confidence,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory FootMetrics.fromJson(Map<String, dynamic> json) => FootMetrics(
    id: json['id'] as String,
    side: FootSide.values.firstWhere((e) => e.name == json['side']),
    longueur: (json['longueur'] as num).toDouble(),
    largeur: (json['largeur'] as num).toDouble(),
    confidence: (json['confidence'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  FootMetrics copyWith({
    String? id,
    FootSide? side,
    double? longueur,
    double? largeur,
    double? confidence,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FootMetrics(
    id: id ?? this.id,
    side: side ?? this.side,
    longueur: longueur ?? this.longueur,
    largeur: largeur ?? this.largeur,
    confidence: confidence ?? this.confidence,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  String get sideLabel => side == FootSide.droite ? 'Pied Droit' : 'Pied Gauche';
  String get formattedLongueur => '${longueur.toStringAsFixed(1)} cm';
  String get formattedLargeur => '${largeur.toStringAsFixed(1)} cm';
  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(0)}%';
}

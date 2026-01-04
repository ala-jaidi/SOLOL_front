enum AngleType { top, side }

class FootScan {
  final String topView;
  final String sideView;
  final AngleType angle;
  final DateTime createdAt;
  final DateTime updatedAt;

  FootScan({
    required this.topView,
    required this.sideView,
    required this.angle,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'topView': topView,
    'sideView': sideView,
    'angle': angle.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory FootScan.fromJson(Map<String, dynamic> json) => FootScan(
    topView: json['topView'] as String,
    sideView: json['sideView'] as String,
    angle: AngleType.values.firstWhere((e) => e.name == json['angle']),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  FootScan copyWith({
    String? topView,
    String? sideView,
    AngleType? angle,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FootScan(
    topView: topView ?? this.topView,
    sideView: sideView ?? this.sideView,
    angle: angle ?? this.angle,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

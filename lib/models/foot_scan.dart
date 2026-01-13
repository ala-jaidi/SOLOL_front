enum AngleType { top, side }

class FootScan {
  final String topView;
  final String sideView;
  final String? topViewDebug;
  final String? sideViewDebug;
  final AngleType angle;
  final DateTime createdAt;
  final DateTime updatedAt;

  FootScan({
    required this.topView,
    required this.sideView,
    this.topViewDebug,
    this.sideViewDebug,
    required this.angle,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'topView': topView,
    'sideView': sideView,
    if (topViewDebug != null) 'topViewDebug': topViewDebug,
    if (sideViewDebug != null) 'sideViewDebug': sideViewDebug,
    'angle': angle.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory FootScan.fromJson(Map<String, dynamic> json) => FootScan(
    topView: (json['topView'] ?? json['top_view'] ?? '') as String,
    sideView: (json['sideView'] ?? json['side_view'] ?? '') as String,
    topViewDebug: json['topViewDebug'] ?? json['top_view_debug'] as String?,
    sideViewDebug: json['sideViewDebug'] ?? json['side_view_debug'] as String?,
    angle: AngleType.values.firstWhere(
      (e) => e.name == json['angle'],
      orElse: () => AngleType.top,
    ),
    createdAt: DateTime.parse((json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()) as String),
    updatedAt: DateTime.parse((json['updatedAt'] ?? json['updated_at'] ?? DateTime.now().toIso8601String()) as String),
  );

  FootScan copyWith({
    String? topView,
    String? sideView,
    String? topViewDebug,
    String? sideViewDebug,
    AngleType? angle,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FootScan(
    topView: topView ?? this.topView,
    sideView: sideView ?? this.sideView,
    topViewDebug: topViewDebug ?? this.topViewDebug,
    sideViewDebug: sideViewDebug ?? this.sideViewDebug,
    angle: angle ?? this.angle,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

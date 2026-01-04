import 'package:lidarmesure/models/foot_metrics.dart';
import 'package:lidarmesure/models/foot_scan.dart';
import 'package:lidarmesure/models/medical_questionnaire.dart';
import 'package:intl/intl.dart';

enum SessionStatus { pending, completed, cancelled }

class Session {
  final String id;
  final String patientId;
  final String? professionnelId; // Made optional for backward compatibility or if not always set
  final DateTime createdAt;
  final SessionStatus status;
  final bool valid;
  final List<FootMetrics> footMetrics;
  final FootScan? footScan;
  final List<MedicalQuestionnaire> questionnaires;
  final DateTime updatedAt;

  Session({
    required this.id,
    required this.patientId,
    this.professionnelId,
    required this.createdAt,
    required this.status,
    required this.valid,
    this.footMetrics = const [],
    this.footScan,
    this.questionnaires = const [],
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    if (professionnelId != null) 'professionnelId': professionnelId,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'valid': valid,
    'footMetrics': footMetrics.map((e) => e.toJson()).toList(),
    'footScan': footScan?.toJson(),
    'questionnaires': questionnaires.map((e) => e.toJson()).toList(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    id: json['id'] as String,
    patientId: json['patientId'] as String,
    professionnelId: json['professionnelId'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    status: SessionStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => _mapLegacyStatus(json['status']),
    ),
    valid: json['valid'] as bool,
    footMetrics: (json['footMetrics'] as List?)
        ?.map((e) => FootMetrics.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    footScan: json['footScan'] != null 
        ? FootScan.fromJson(json['footScan'] as Map<String, dynamic>)
        : null,
    questionnaires: (json['questionnaires'] as List?)
        ?.map((e) => MedicalQuestionnaire.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  static SessionStatus _mapLegacyStatus(String? status) {
    switch (status) {
      case 'enCours': return SessionStatus.pending;
      case 'termine': return SessionStatus.completed;
      case 'annule': return SessionStatus.cancelled;
      default: return SessionStatus.pending;
    }
  }

  Session copyWith({
    String? id,
    String? patientId,
    String? professionnelId,
    DateTime? createdAt,
    SessionStatus? status,
    bool? valid,
    List<FootMetrics>? footMetrics,
    FootScan? footScan,
    List<MedicalQuestionnaire>? questionnaires,
    DateTime? updatedAt,
  }) => Session(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    professionnelId: professionnelId ?? this.professionnelId,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    valid: valid ?? this.valid,
    footMetrics: footMetrics ?? this.footMetrics,
    footScan: footScan ?? this.footScan,
    questionnaires: questionnaires ?? this.questionnaires,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  String get formattedDate => DateFormat('dd MMM yyyy à HH:mm', 'fr_FR').format(createdAt);
  String get statusLabel {
    switch (status) {
      case SessionStatus.pending:
        return 'En cours';
      case SessionStatus.completed:
        return 'Terminé';
      case SessionStatus.cancelled:
        return 'Annulé';
    }
  }
}

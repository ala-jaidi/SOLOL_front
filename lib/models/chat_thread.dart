import 'package:uuid/uuid.dart';

/// Represents a persisted chat thread stored in Supabase (public.chat_threads)
class ChatThread {
  final String id;
  final String userId;
  final String providerSessionId; // session id for the external provider (Antopic)
  final String? title;
  final String templateKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatThread({
    String? id,
    required this.userId,
    required this.providerSessionId,
    this.title,
    required this.templateKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ChatThread.fromMap(Map<String, dynamic> map) => ChatThread(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        providerSessionId: map['provider_session_id'] as String,
        title: map['title'] as String?,
        templateKey: (map['template_key'] as String?) ?? 'podology_default',
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toInsertMap() => {
        'id': id,
        'user_id': userId,
        'provider_session_id': providerSessionId,
        'title': title,
        'template_key': templateKey,
      };
}

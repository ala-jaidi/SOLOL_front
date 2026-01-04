import 'package:uuid/uuid.dart';

enum ChatDeliveryStatus { pending, sent, error }

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime createdAt;
  final ChatDeliveryStatus status;

  ChatMessage({
    String? id,
    required this.content,
    required this.isUser,
    DateTime? createdAt,
    this.status = ChatDeliveryStatus.pending,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? createdAt,
    ChatDeliveryStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

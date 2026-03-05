enum MessageRole { user, assistant, system }

extension MessageRoleX on MessageRole {
  String get value {
    switch (this) {
      case MessageRole.user:
        return 'user';
      case MessageRole.assistant:
        return 'assistant';
      case MessageRole.system:
        return 'system';
    }
  }

  static MessageRole fromString(String value) {
    switch (value) {
      case 'assistant':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
      case 'user':
      default:
        return MessageRole.user;
    }
  }
}

class Message {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final bool isPending;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.isPending = false,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        role: MessageRoleX.fromString(json['role'] as String? ?? 'user'),
        content: json['content'] as String,
        isPending: json['is_pending'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        'role': role.value,
        'content': content,
        'is_pending': isPending,
      };

  Message copyWith({
    String? content,
    bool? isPending,
  }) =>
      Message(
        id: id,
        conversationId: conversationId,
        role: role,
        content: content ?? this.content,
        isPending: isPending ?? this.isPending,
        createdAt: createdAt,
      );
}

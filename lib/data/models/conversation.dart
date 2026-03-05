enum ConversationType { onboarding, chat, call }

enum ConversationStatus { active, completed, abandoned }

extension ConversationTypeX on ConversationType {
  String get value {
    switch (this) {
      case ConversationType.onboarding:
        return 'onboarding';
      case ConversationType.chat:
        return 'chat';
      case ConversationType.call:
        return 'call';
    }
  }

  static ConversationType fromString(String value) {
    switch (value) {
      case 'onboarding':
        return ConversationType.onboarding;
      case 'call':
        return ConversationType.call;
      case 'chat':
      default:
        return ConversationType.chat;
    }
  }
}

extension ConversationStatusX on ConversationStatus {
  String get value {
    switch (this) {
      case ConversationStatus.active:
        return 'active';
      case ConversationStatus.completed:
        return 'completed';
      case ConversationStatus.abandoned:
        return 'abandoned';
    }
  }

  static ConversationStatus fromString(String value) {
    switch (value) {
      case 'completed':
        return ConversationStatus.completed;
      case 'abandoned':
        return ConversationStatus.abandoned;
      case 'active':
      default:
        return ConversationStatus.active;
    }
  }
}

class Conversation {
  final String id;
  final String userId;
  final String? companionId;
  final ConversationType type;
  final ConversationStatus status;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.userId,
    this.companionId,
    this.type = ConversationType.chat,
    this.status = ConversationStatus.active,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        companionId: json['companion_id'] as String?,
        type: ConversationTypeX.fromString(json['type'] as String? ?? 'chat'),
        status: ConversationStatusX.fromString(
            json['status'] as String? ?? 'active'),
        metadata:
            (json['metadata'] as Map<String, dynamic>?) ?? const {},
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'companion_id': companionId,
        'type': type.value,
        'status': status.value,
        'metadata': metadata,
      };

  Conversation copyWith({
    String? companionId,
    ConversationType? type,
    ConversationStatus? status,
    Map<String, dynamic>? metadata,
  }) =>
      Conversation(
        id: id,
        userId: userId,
        companionId: companionId ?? this.companionId,
        type: type ?? this.type,
        status: status ?? this.status,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}

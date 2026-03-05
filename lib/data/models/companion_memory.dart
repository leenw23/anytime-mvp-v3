enum MemoryType {
  onboardingSummary,
  userInfo,
  episode,
  preference,
  relationship,
}

extension MemoryTypeX on MemoryType {
  String get value {
    switch (this) {
      case MemoryType.onboardingSummary:
        return 'onboarding_summary';
      case MemoryType.userInfo:
        return 'user_info';
      case MemoryType.episode:
        return 'episode';
      case MemoryType.preference:
        return 'preference';
      case MemoryType.relationship:
        return 'relationship';
    }
  }

  static MemoryType fromString(String value) {
    switch (value) {
      case 'onboarding_summary':
        return MemoryType.onboardingSummary;
      case 'user_info':
        return MemoryType.userInfo;
      case 'episode':
        return MemoryType.episode;
      case 'preference':
        return MemoryType.preference;
      case 'relationship':
        return MemoryType.relationship;
      default:
        return MemoryType.userInfo;
    }
  }
}

class CompanionMemory {
  final String id;
  final String companionId;
  final MemoryType type;
  final String? title;
  final String content;
  final int importance;
  final String? sourceConversationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CompanionMemory({
    required this.id,
    required this.companionId,
    required this.type,
    this.title,
    required this.content,
    this.importance = 5,
    this.sourceConversationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompanionMemory.fromJson(Map<String, dynamic> json) =>
      CompanionMemory(
        id: json['id'] as String,
        companionId: json['companion_id'] as String,
        type: MemoryTypeX.fromString(json['type'] as String? ?? 'user_info'),
        title: json['title'] as String?,
        content: json['content'] as String,
        importance: json['importance'] as int? ?? 5,
        sourceConversationId: json['source_conversation_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'companion_id': companionId,
        'type': type.value,
        'title': title,
        'content': content,
        'importance': importance,
        'source_conversation_id': sourceConversationId,
      };
}

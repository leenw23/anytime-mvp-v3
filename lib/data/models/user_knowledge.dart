class UserKnowledge {
  final String id;
  final String companionId;

  /// basic_info, preferences, emotions, life_events, relationships, habits
  final String category;
  final String key;
  final String value;
  final double confidence;
  final String? sourceConversationId;
  final DateTime learnedAt;
  final DateTime updatedAt;

  const UserKnowledge({
    required this.id,
    required this.companionId,
    required this.category,
    required this.key,
    required this.value,
    this.confidence = 1.0,
    this.sourceConversationId,
    required this.learnedAt,
    required this.updatedAt,
  });

  factory UserKnowledge.fromJson(Map<String, dynamic> json) => UserKnowledge(
        id: json['id'] as String,
        companionId: json['companion_id'] as String,
        category: json['category'] as String,
        key: json['key'] as String,
        value: json['value'] as String,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
        sourceConversationId: json['source_conversation_id'] as String?,
        learnedAt: DateTime.parse(json['learned_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'companion_id': companionId,
        'category': category,
        'key': key,
        'value': value,
        'confidence': confidence,
        'source_conversation_id': sourceConversationId,
        'learned_at': learnedAt.toIso8601String(),
      };
}

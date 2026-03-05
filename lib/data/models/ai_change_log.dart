class AiChangeLog {
  final String id;
  final String companionId;

  /// personality_shift, new_like, removed_like, new_dislike, removed_dislike,
  /// identity_update, mood_change
  final String changeType;
  final String? fieldChanged;
  final String? oldValue;
  final String? newValue;
  final String? reason;

  /// conversation, routine, self_reflection
  final String triggeredBy;
  final String? sourceConversationId;
  final DateTime createdAt;

  const AiChangeLog({
    required this.id,
    required this.companionId,
    required this.changeType,
    this.fieldChanged,
    this.oldValue,
    this.newValue,
    this.reason,
    required this.triggeredBy,
    this.sourceConversationId,
    required this.createdAt,
  });

  factory AiChangeLog.fromJson(Map<String, dynamic> json) => AiChangeLog(
        id: json['id'] as String,
        companionId: json['companion_id'] as String,
        changeType: json['change_type'] as String,
        fieldChanged: json['field_changed'] as String?,
        oldValue: json['old_value'] as String?,
        newValue: json['new_value'] as String?,
        reason: json['reason'] as String?,
        triggeredBy: json['triggered_by'] as String,
        sourceConversationId: json['source_conversation_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'companion_id': companionId,
        'change_type': changeType,
        'field_changed': fieldChanged,
        'old_value': oldValue,
        'new_value': newValue,
        'reason': reason,
        'triggered_by': triggeredBy,
        'source_conversation_id': sourceConversationId,
      };
}

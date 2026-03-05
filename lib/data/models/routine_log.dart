class RoutineLog {
  final String id;
  final String companionId;

  /// send_message, share_discovery, share_thought, self_update, user_update, silent
  final String action;
  final Map<String, dynamic> actionDetail;
  final String? contextSummary;
  final String triggeredBy;
  final DateTime createdAt;

  const RoutineLog({
    required this.id,
    required this.companionId,
    required this.action,
    this.actionDetail = const {},
    this.contextSummary,
    required this.triggeredBy,
    required this.createdAt,
  });

  factory RoutineLog.fromJson(Map<String, dynamic> json) => RoutineLog(
        id: json['id'] as String,
        companionId: json['companion_id'] as String,
        action: json['action'] as String,
        actionDetail:
            (json['action_detail'] as Map<String, dynamic>?) ?? const {},
        contextSummary: json['context_summary'] as String?,
        triggeredBy: json['triggered_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'companion_id': companionId,
        'action': action,
        'action_detail': actionDetail,
        'context_summary': contextSummary,
        'triggered_by': triggeredBy,
      };
}

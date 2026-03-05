import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';

class RoutineResult {
  final String action;
  final String? reason;
  final String? messageId;
  final String? conversationId;
  final String? content;
  final String? backdatedAt;

  RoutineResult({
    required this.action,
    this.reason,
    this.messageId,
    this.conversationId,
    this.content,
    this.backdatedAt,
  });

  factory RoutineResult.fromJson(Map<String, dynamic> json) => RoutineResult(
        action: json['action'] as String? ?? 'silent',
        reason: json['reason'] as String?,
        messageId: json['message_id'] as String?,
        conversationId: json['conversation_id'] as String?,
        content: json['content'] as String?,
        backdatedAt: json['backdated_at'] as String?,
      );

  bool get hasMessage =>
      ['send_message', 'share_discovery', 'share_thought'].contains(action);
}

class RoutineService {
  Future<RoutineResult?> checkAndRun({
    required String accessToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(SupabaseConfig.routineFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({}),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return RoutineResult.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}

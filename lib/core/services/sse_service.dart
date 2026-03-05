// ignore_for_file: use_null_aware_elements
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// SSE event from the chat Edge Function
class SseEvent {
  final String type; // 'token', 'done', 'error'
  final String? content;
  final String? messageId;
  final String? conversationId;
  final String? errorMessage;

  SseEvent({
    required this.type,
    this.content,
    this.messageId,
    this.conversationId,
    this.errorMessage,
  });

  factory SseEvent.fromJson(Map<String, dynamic> json) {
    return SseEvent(
      type: json['type'] as String,
      content: json['content'] as String?,
      messageId: json['message_id'] as String?,
      conversationId: json['conversation_id'] as String?,
      errorMessage: json['message'] as String?,
    );
  }
}

class SseService {
  /// Send a message and receive streaming SSE response.
  /// Returns a Stream of [SseEvent]s.
  Stream<SseEvent> sendMessage({
    required String functionUrl,
    required String accessToken,
    required String message,
    String? conversationId,
  }) {
    return sendMessageWithMode(
      functionUrl: functionUrl,
      accessToken: accessToken,
      message: message,
      conversationId: conversationId,
    );
  }

  /// Send a message with optional mode (for onboarding).
  Stream<SseEvent> sendMessageWithMode({
    required String functionUrl,
    required String accessToken,
    required String message,
    String? conversationId,
    String? mode,
    int? turnCount,
  }) async* {
    final client = http.Client();

    try {
      final request = http.Request('POST', Uri.parse(functionUrl));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      });
      request.body = jsonEncode({
        'message': message,
        if (conversationId != null) 'conversation_id': conversationId,
        if (mode != null) 'mode': mode,
        if (turnCount != null) 'turn_count': turnCount,
      });

      final response = await client.send(request);

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw Exception('HTTP ${response.statusCode}: $body');
      }

      // Parse SSE stream
      String buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;

        // SSE events are separated by double newlines
        while (buffer.contains('\n\n')) {
          final eventEnd = buffer.indexOf('\n\n');
          final eventStr = buffer.substring(0, eventEnd);
          buffer = buffer.substring(eventEnd + 2);

          // Parse "data: {...}" lines
          for (final line in eventStr.split('\n')) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              try {
                final json = jsonDecode(data) as Map<String, dynamic>;
                yield SseEvent.fromJson(json);
              } catch (_) {
                // Skip unparseable lines
              }
            }
          }
        }
      }
    } finally {
      client.close();
    }
  }
}

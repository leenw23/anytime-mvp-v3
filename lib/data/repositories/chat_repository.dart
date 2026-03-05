import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class ChatRepository {
  final SupabaseClient _client;

  ChatRepository(this._client);

  /// Get or create active conversation for user
  Future<Conversation> getOrCreateConversation(String userId) async {
    final response = await _client
        .from('conversations')
        .select()
        .eq('user_id', userId)
        .eq('type', 'chat')
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response != null) {
      return Conversation.fromJson(response);
    }

    // Create new conversation
    final companion = await getCompanion(userId);
    final newConv = await _client
        .from('conversations')
        .insert({
          'user_id': userId,
          'companion_id': companion?.id,
          'type': 'chat',
          'status': 'active',
        })
        .select()
        .single();

    return Conversation.fromJson(newConv);
  }

  /// Get companion for user
  Future<Companion?> getCompanion(String userId) async {
    final response = await _client
        .from('companions')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return response != null ? Companion.fromJson(response) : null;
  }

  /// Get messages for conversation (newest last)
  Future<List<Message>> getMessages(String conversationId,
      {int limit = 50}) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .limit(limit);

    return (response as List).map((j) => Message.fromJson(j)).toList();
  }
}

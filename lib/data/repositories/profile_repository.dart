import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class ProfileRepository {
  final SupabaseClient _client;
  ProfileRepository(this._client);

  Future<Companion?> getCompanion(String userId) async {
    final response = await _client
        .from('companions')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return response != null ? Companion.fromJson(response) : null;
  }

  Future<List<UserKnowledge>> getUserKnowledge(String companionId) async {
    final response = await _client
        .from('user_knowledge')
        .select()
        .eq('companion_id', companionId)
        .order('updated_at', ascending: false);
    return (response as List).map((j) => UserKnowledge.fromJson(j)).toList();
  }

  Future<List<AiChangeLog>> getChangeLog(String companionId,
      {int limit = 20}) async {
    final response = await _client
        .from('ai_change_log')
        .select()
        .eq('companion_id', companionId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List).map((j) => AiChangeLog.fromJson(j)).toList();
  }

  Future<void> updateCompanionAvatar(
      String companionId, String emoji) async {
    await _client
        .from('companions')
        .update({'avatar_emoji': emoji}).eq('id', companionId);
  }

  Future<void> completeOnboarding(String userId) async {
    await _client
        .from('profiles')
        .update({'onboarding_completed': true}).eq('id', userId);
  }
}

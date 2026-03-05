import 'package:supabase_flutter/supabase_flutter.dart';

/// Unified history item for the timeline
class HistoryItem {
  final String id;
  final String type; // 'message', 'insight', 'milestone', 'calendar'
  final String icon; // emoji
  final String typeLabel; // '선톡', '발견', '마일스톤', '일정'
  final String content;
  final String? preview;
  final DateTime createdAt;
  final bool isHighlight;

  const HistoryItem({
    required this.id,
    required this.type,
    required this.icon,
    required this.typeLabel,
    required this.content,
    this.preview,
    required this.createdAt,
    this.isHighlight = false,
  });
}

class HistoryRepository {
  final SupabaseClient _client;

  HistoryRepository(this._client);

  /// Fetch all history items for companion, sorted by date desc
  Future<List<HistoryItem>> getHistory(String companionId,
      {int limit = 50}) async {
    final items = <HistoryItem>[];

    // 1. Routine messages
    final routineLogs = await _client
        .from('routine_logs')
        .select()
        .eq('companion_id', companionId)
        .inFilter('action', ['send_message', 'share_discovery', 'share_thought'])
        .order('created_at', ascending: false)
        .limit(limit);

    for (final log in (routineLogs as List)) {
      final action = log['action'] as String;
      final detail =
          log['action_detail'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final createdAt = DateTime.parse(log['created_at'] as String);
      items.add(HistoryItem(
        id: log['id'] as String,
        type: 'message',
        icon: action == 'share_discovery'
            ? '💡'
            : action == 'share_thought'
                ? '💭'
                : '💬',
        typeLabel: action == 'share_discovery'
            ? '발견'
            : action == 'share_thought'
                ? '생각'
                : '선톡',
        content: detail['content'] as String? ??
            log['context_summary'] as String? ??
            '',
        createdAt: createdAt,
        isHighlight: createdAt
            .isAfter(DateTime.now().subtract(const Duration(hours: 24))),
      ));
    }

    // 2. AI change log (insights)
    final changeLogs = await _client
        .from('ai_change_log')
        .select()
        .eq('companion_id', companionId)
        .order('created_at', ascending: false)
        .limit(limit);

    for (final log in (changeLogs as List)) {
      final newVal = log['new_value'];
      final reason = log['reason'];
      items.add(HistoryItem(
        id: log['id'] as String,
        type: 'insight',
        icon: '💡',
        typeLabel: '발견',
        content:
            '${log['field_changed'] ?? log['change_type']}: ${newVal ?? ''}',
        preview: reason != null ? '→ $reason' : null,
        createdAt: DateTime.parse(log['created_at'] as String),
      ));
    }

    // 3. Milestones
    final milestones = await _client
        .from('milestones')
        .select()
        .eq('companion_id', companionId)
        .order('created_at', ascending: false)
        .limit(limit);

    for (final m in (milestones as List)) {
      final title = m['title'];
      final description = m['description'];
      items.add(HistoryItem(
        id: m['id'] as String,
        type: 'milestone',
        icon: '⭐',
        typeLabel: '마일스톤',
        content: title as String? ?? description as String? ?? '',
        preview: description != null && title != null ? '→ $description' : null,
        createdAt: DateTime.parse(m['created_at'] as String),
      ));
    }

    // Sort all by date desc
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(limit).toList();
  }
}

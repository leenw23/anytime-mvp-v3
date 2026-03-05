import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/config/supabase_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/routine_service.dart';
import '../../core/services/sse_service.dart';
import '../../data/models/message.dart';
import '../../data/repositories/chat_repository.dart';
import 'auth_provider.dart';
import 'sse_provider.dart';
import 'tv_state_provider.dart';

// Repository provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ChatRepository(client);
});

// Chat state
class ChatState {
  final List<Message> messages;
  final String? conversationId;
  final bool isLoading;
  final String? streamingContent; // accumulated AI response during streaming
  final String? error;

  const ChatState({
    this.messages = const [],
    this.conversationId,
    this.isLoading = false,
    this.streamingContent,
    this.error,
  });

  ChatState copyWith({
    List<Message>? messages,
    String? conversationId,
    bool? isLoading,
    String? streamingContent,
    String? error,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        conversationId: conversationId ?? this.conversationId,
        isLoading: isLoading ?? this.isLoading,
        streamingContent: streamingContent,
        error: error,
      );
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repo;
  final SseService _sseService;
  final AuthService _authService;
  final Ref _ref;
  StreamSubscription<SseEvent>? _streamSub;

  ChatNotifier(this._repo, this._sseService, this._authService, this._ref)
      : super(const ChatState());

  /// Initialize: ensure auth + load conversation + messages
  Future<void> initialize() async {
    try {
      state = state.copyWith(isLoading: true);

      // Ensure authenticated
      await _authService.signInAnonymously();
      final userId = _authService.userId;
      if (userId == null) throw Exception('Not authenticated');

      // Get or create conversation
      final conv = await _repo.getOrCreateConversation(userId);

      // Load existing messages
      final messages = await _repo.getMessages(conv.id);

      state = state.copyWith(
        messages: messages,
        conversationId: conv.id,
        isLoading: false,
      );

      // Check routine (fire and forget — reloads messages if companion sent something)
      _checkRoutine();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _checkRoutine() async {
    final token = _authService.accessToken;
    if (token == null) return;

    final routineService = RoutineService();
    final result = await routineService.checkAndRun(accessToken: token);

    if (result != null && result.hasMessage && result.content != null) {
      // Reload messages to include the pending routine message
      if (state.conversationId != null) {
        final messages = await _repo.getMessages(state.conversationId!);
        state = state.copyWith(messages: messages);
      }
    }
  }

  /// Send user message and stream AI response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final accessToken = _authService.accessToken;
    if (accessToken == null) return;

    // Add user message optimistically
    final userMsg = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: state.conversationId ?? '',
      role: MessageRole.user,
      content: content,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      streamingContent: '',
    );

    // Set TV to thinking
    _ref.read(tvStateProvider.notifier).state = TvState.thinking;

    // Cancel any existing stream
    await _streamSub?.cancel();

    // Start SSE stream
    final stream = _sseService.sendMessage(
      functionUrl: SupabaseConfig.chatFunctionUrl,
      accessToken: accessToken,
      message: content,
      conversationId: state.conversationId,
    );

    String accumulated = '';

    _streamSub = stream.listen(
      (event) {
        switch (event.type) {
          case 'token':
            accumulated += event.content ?? '';
            // Set TV to speaking on first token
            _ref.read(tvStateProvider.notifier).state = TvState.speaking;
            state = state.copyWith(streamingContent: accumulated);
            break;
          case 'done':
            // Replace streaming content with final message
            final aiMsg = Message(
              id: event.messageId ??
                  'ai_${DateTime.now().millisecondsSinceEpoch}',
              conversationId:
                  event.conversationId ?? state.conversationId ?? '',
              role: MessageRole.assistant,
              content: accumulated,
              createdAt: DateTime.now(),
            );
            final newConvId = event.conversationId ?? state.conversationId;
            state = state.copyWith(
              messages: [...state.messages, aiMsg],
              conversationId: newConvId,
              streamingContent: null,
            );
            // Back to idle
            _ref.read(tvStateProvider.notifier).state = TvState.idle;
            // Fire-and-forget: extract profile from conversation
            _extractProfile(newConvId);
            break;
          case 'error':
            state = state.copyWith(
              streamingContent: null,
              error: event.errorMessage,
            );
            _ref.read(tvStateProvider.notifier).state = TvState.idle;
            break;
        }
      },
      onError: (e) {
        state = state.copyWith(streamingContent: null, error: e.toString());
        _ref.read(tvStateProvider.notifier).state = TvState.idle;
      },
    );
  }

  /// Call extract-profile Edge Function after each AI response
  Future<void> _extractProfile(String? conversationId) async {
    if (conversationId == null) return;
    final token = _authService.accessToken;
    if (token == null) return;
    try {
      await http.post(
        Uri.parse(SupabaseConfig.extractProfileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'conversation_id': conversationId}),
      );
    } catch (_) {
      // Silent — extraction is best-effort
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  final sse = ref.watch(sseServiceProvider);
  final auth = ref.watch(authServiceProvider);
  return ChatNotifier(repo, sse, auth, ref);
});

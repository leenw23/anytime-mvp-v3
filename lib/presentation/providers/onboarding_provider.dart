import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/config/supabase_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sse_service.dart';
import '../../data/models/message.dart';
import 'auth_provider.dart';
import 'sse_provider.dart';
import 'tv_state_provider.dart';

const int onboardingTotalTurns = 10;

class OnboardingState {
  final List<Message> messages;
  final String? conversationId;
  final bool isLoading;
  final String? streamingContent;
  final String? error;
  final int turnCount; // User turns (1-15)
  final bool isCompleted;
  final bool isProfileGenerating;

  const OnboardingState({
    this.messages = const [],
    this.conversationId,
    this.isLoading = false,
    this.streamingContent,
    this.error,
    this.turnCount = 0,
    this.isCompleted = false,
    this.isProfileGenerating = false,
  });

  OnboardingState copyWith({
    List<Message>? messages,
    String? conversationId,
    bool? isLoading,
    String? streamingContent,
    String? error,
    int? turnCount,
    bool? isCompleted,
    bool? isProfileGenerating,
  }) =>
      OnboardingState(
        messages: messages ?? this.messages,
        conversationId: conversationId ?? this.conversationId,
        isLoading: isLoading ?? this.isLoading,
        streamingContent: streamingContent,
        error: error,
        turnCount: turnCount ?? this.turnCount,
        isCompleted: isCompleted ?? this.isCompleted,
        isProfileGenerating: isProfileGenerating ?? this.isProfileGenerating,
      );
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final SseService _sseService;
  final AuthService _authService;
  final Ref _ref;
  StreamSubscription<SseEvent>? _streamSub;

  OnboardingNotifier(this._sseService, this._authService, this._ref)
      : super(const OnboardingState());

  /// Initialize onboarding - auth already established by RootScreen
  Future<void> initialize() async {
    // Auth already established by RootScreen
    state = state.copyWith(isLoading: false);
  }

  /// Send user message in onboarding mode
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    if (state.isCompleted) return;

    final accessToken = _authService.accessToken;
    if (accessToken == null) return;

    final newTurnCount = state.turnCount + 1;

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
      turnCount: newTurnCount,
    );

    // Set TV to thinking
    _ref.read(tvStateProvider.notifier).state = TvState.thinking;

    // Cancel any existing stream
    await _streamSub?.cancel();

    // Start SSE stream with onboarding mode
    final stream = _sseService.sendMessageWithMode(
      functionUrl: SupabaseConfig.chatFunctionUrl,
      accessToken: accessToken,
      message: content,
      conversationId: state.conversationId,
      mode: 'onboarding',
      turnCount: newTurnCount,
    );

    String accumulated = '';

    _streamSub = stream.listen(
      (event) {
        switch (event.type) {
          case 'token':
            accumulated += event.content ?? '';
            _ref.read(tvStateProvider.notifier).state = TvState.speaking;
            state = state.copyWith(streamingContent: accumulated);
            break;
          case 'done':
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
            final completed = newTurnCount >= onboardingTotalTurns;

            state = state.copyWith(
              messages: [...state.messages, aiMsg],
              conversationId: newConvId,
              streamingContent: null,
              isCompleted: completed,
            );
            _ref.read(tvStateProvider.notifier).state = TvState.idle;

            // If completed, trigger profile generation
            if (completed) {
              _generateInitialProfile(newConvId);
            }
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

  /// Generate initial profile from onboarding conversation
  Future<void> _generateInitialProfile(String? conversationId) async {
    if (conversationId == null) return;
    final token = _authService.accessToken;
    if (token == null) return;

    state = state.copyWith(isProfileGenerating: true);

    try {
      // Call extract-profile which will analyze the onboarding conversation
      await http.post(
        Uri.parse(SupabaseConfig.extractProfileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'conversation_id': conversationId,
          'is_onboarding': true,
        }),
      );
    } catch (_) {
      // Silent failure — profile extraction is best-effort
    } finally {
      state = state.copyWith(isProfileGenerating: false);
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final sse = ref.watch(sseServiceProvider);
  final auth = ref.watch(authServiceProvider);
  return OnboardingNotifier(sse, auth, ref);
});

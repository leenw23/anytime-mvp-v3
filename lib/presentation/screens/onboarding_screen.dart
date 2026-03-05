import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/theme.dart';
import '../../data/models/message.dart';
import '../providers/onboarding_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_list.dart';
import '../widgets/tv_widget.dart';
import 'home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppSpacing.normal,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(String content) {
    ref.read(onboardingProvider.notifier).sendMessage(content);
    _scrollToBottom();
  }

  void _showCompletionModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OnboardingCompleteModal(
        onContinue: () {
          Navigator.of(context).pop();
          _navigateToHome();
        },
      ),
    );
  }

  Future<void> _navigateToHome() async {
    // Mark onboarding as complete
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final repo = ref.read(profileRepositoryProvider);
      await repo.completeOnboarding(userId);
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);

    // Show modal when completed
    ref.listen<OnboardingState>(onboardingProvider, (prev, next) {
      if (prev?.isCompleted != true && next.isCompleted) {
        _showCompletionModal();
      }
    });

    // Combine real messages with streaming message
    final displayMessages = [
      ...onboardingState.messages,
      if (onboardingState.streamingContent != null &&
          onboardingState.streamingContent!.isNotEmpty)
        Message(
          id: 'streaming',
          conversationId: '',
          role: MessageRole.assistant,
          content: onboardingState.streamingContent!,
          createdAt: DateTime.now(),
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Turn indicator
            _buildTurnIndicator(onboardingState.turnCount),
            const SizedBox(height: 4),
            const TvWidget(),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: displayMessages.isEmpty
                  ? _buildWelcomeHint()
                  : MessageList(
                      messages: displayMessages,
                      scrollController: _scrollController,
                    ),
            ),
            ChatInput(
              onSend: _handleSend,
              enabled: !onboardingState.isCompleted,
              hintText: onboardingState.turnCount == 0
                  ? '인사해보세요...'
                  : '메시지를 입력하세요',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTurnIndicator(int turnCount) {
    final remaining = onboardingTotalTurns - turnCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.tvBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              turnCount == 0
                  ? '첫 만남'
                  : remaining > 0
                      ? '$remaining턴 남음'
                      : '마무리 중...',
              style: AppTypography.caption.copyWith(
                color: AppColors.textDim,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '👋',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '새로운 친구가 기다리고 있어요',
              style: AppTypography.body.copyWith(
                color: AppColors.textDim,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '먼저 인사해보세요',
              style: AppTypography.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingCompleteModal extends ConsumerWidget {
  final VoidCallback onContinue;

  const _OnboardingCompleteModal({required this.onContinue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGenerating = ref.watch(
      onboardingProvider.select((s) => s.isProfileGenerating),
    );

    return Dialog(
      backgroundColor: AppColors.tvBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎉',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              '첫 만남 완료!',
              style: AppTypography.h2,
            ),
            const SizedBox(height: 8),
            Text(
              isGenerating
                  ? '프로필을 만들고 있어요...'
                  : '서로에 대해 조금 알게 됐어요.\n프로필을 확인해보세요.',
              style: AppTypography.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: isGenerating
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('프로필 보기'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

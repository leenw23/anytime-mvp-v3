import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../data/models/message.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_list.dart';
import '../widgets/tv_widget.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize chat after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).initialize();
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
    ref.read(chatProvider.notifier).sendMessage(content);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // Combine real messages with streaming message
    final displayMessages = [
      ...chatState.messages,
      if (chatState.streamingContent != null &&
          chatState.streamingContent!.isNotEmpty)
        Message(
          id: 'streaming',
          conversationId: '',
          role: MessageRole.assistant,
          content: chatState.streamingContent!,
          createdAt: DateTime.now(),
        ),
    ];

    return Column(
      children: [
        const SizedBox(height: 12),
        const TvWidget(),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: MessageList(
            messages: displayMessages,
            scrollController: _scrollController,
          ),
        ),
        ChatInput(
          onSend: _handleSend,
        ),
      ],
    );
  }
}

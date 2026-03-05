import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../data/models/message.dart';
import 'message_bubble.dart';
// import 'date_time_bar.dart'; // TODO: uncomment when date_time_bar.dart is available

class MessageList extends StatelessWidget {
  final List<Message> messages;
  final ScrollController scrollController;

  const MessageList({
    super.key,
    required this.messages,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return MessageItem(message: message);
      },
    );
  }
}

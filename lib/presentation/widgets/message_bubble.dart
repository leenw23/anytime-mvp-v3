import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../data/models/message.dart';

class MessageItem extends StatelessWidget {
  final Message message;

  const MessageItem({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message.content,
        style: isUser ? AppTypography.userMessage : AppTypography.message,
      ),
    );
  }
}

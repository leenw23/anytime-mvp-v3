import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSend;
  final bool enabled;
  final String? hintText;

  const ChatInput({
    super.key,
    required this.onSend,
    this.enabled = true,
    this.hintText,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    widget.onSend(trimmed);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
        vertical: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '>',
            style: AppTypography.input.copyWith(
              color: AppColors.textDim,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              style: AppTypography.input,
              decoration: InputDecoration(
                hintText: widget.hintText ?? '...',
                hintStyle: AppTypography.inputHint,
                border: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border, width: 1),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border, width: 1),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border, width: 1),
                ),
                disabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border, width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                isDense: true,
              ),
              cursorColor: AppColors.textDim,
              onSubmitted: _handleSubmit,
              textInputAction: TextInputAction.send,
            ),
          ),
        ],
      ),
    );
  }
}

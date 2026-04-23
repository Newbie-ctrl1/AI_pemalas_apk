import 'package:flutter/material.dart';

import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isUser ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0);
    final textColor = isUser ? Colors.white : const Color(0xFF0F172A);
    final captionColor = isUser ? Colors.white70 : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            message.text,
            style: TextStyle(color: textColor, fontSize: 15),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            _formatTime(message.createdAt),
            style: TextStyle(fontSize: 11, color: captionColor),
          ),
        ),
      ],
    );
  }
}

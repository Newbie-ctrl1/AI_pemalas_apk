class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  final String text;
  final bool isUser;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json, {required bool isUser}) {
    return ChatMessage(
      text: (isUser ? json['prompt'] : json['response'])?.toString() ?? '',
      isUser: isUser,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

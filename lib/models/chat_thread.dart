class ChatThread {
  ChatThread({
    required this.id,
    required this.title,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final DateTime updatedAt;

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: (json['title']?.toString() ?? 'Chat Baru').trim(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

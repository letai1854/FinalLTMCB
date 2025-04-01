class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String? image;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.image,
  });
}

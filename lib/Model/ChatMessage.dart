class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String? image;
  final String?
      audio; // This will now be either a file path or base64 depending on implementation
  final bool isAudioPath; // Flag to indicate if audio is a file path

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.image,
    this.audio,
    this.isAudioPath = false, // Default to base64 for backward compatibility
  });

  // Helper method to determine if this is an audio message
  bool get isAudioMessage => audio != null && audio!.isNotEmpty;

  // Helper method to determine if this is an image message
  bool get isImageMessage => image != null && image!.isNotEmpty;
}

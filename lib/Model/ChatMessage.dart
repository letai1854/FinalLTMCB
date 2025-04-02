import 'package:finalltmcb/Widget/FilePickerUtil.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String? image;
  final String? audio;
  final bool isAudioPath;
  final FileMessage? file; // Add file message support

  const ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.image,
    this.audio,
    this.isAudioPath = false,
    this.file,
  });

  // Helper method to determine if this is an audio message
  bool get isAudioMessage => audio != null && audio!.isNotEmpty;

  // Helper method to determine if this is an image message
  bool get isImageMessage => image != null && image!.isNotEmpty;

  // Helper method to determine if this is a file message
  bool get isFileMessage => file != null;
}

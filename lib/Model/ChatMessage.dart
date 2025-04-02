import 'dart:typed_data';

import 'package:finalltmcb/Widget/FilePickerUtil.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String? image;
  final String? audio;
  final bool isAudioPath;
  final FileMessage? file;
  final String? video; // Added for video messages
  final String? mimeType;
  final Uint8List? videoBytes;
  final bool isVideoLoading; // Flag for video loading state

  // --- Audio Specific Fields (Commented out - for future use) ---
  // final int? audioDuration; // Duration in milliseconds
  // final List<double>? audioWaveform; // For waveform visualization

  const ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.image,
    this.audio,
    this.isAudioPath = false,
    this.file,
    this.video,
    this.mimeType = null,
    this.videoBytes = null,
    this.isVideoLoading = false,
  });

  // Helper method to determine if this is an audio message
  bool get isAudioMessage => audio != null && audio!.isNotEmpty;

  // Helper method to determine if this is an image message
  bool get isImageMessage => image != null && image!.isNotEmpty;

  // Helper method to determine if this is a file message
  bool get isFileMessage => file != null;

  // Helper method to determine if this is a video message
  bool get isVideoMessage => video != null && video!.isNotEmpty;
}
